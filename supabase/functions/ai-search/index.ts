// MindVault — AI search edge function.
//
// Authenticates the caller, checks the per-tier daily quota (read from the
// `tier_limits` table — single source of truth), forwards the request to the
// configured AI model, increments usage on success.
//
// Deploy:
//   supabase functions deploy ai-search --project-ref <ref>
//   supabase secrets set AI_API_KEY=<key> --project-ref <ref>

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// Service-role client for reads that bypass RLS (tier_limits, error_logs writes).
// Module-scope instantiation is safe: the client is stateless (no auth session),
// so warm instance reuse by the Deno runtime doesn't leak state between requests.
const adminClient = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);

// Ordered fallback list — first model is tried first; on quota exhaustion (429)
// the next model is tried automatically. 
// To check available models: curl "https://generativelanguage.googleapis.com/v1beta/models?key=<YOUR_API_KEY>" | grep -A1 "\"name\""
const AI_MODELS = [
  "gemini-2.5-flash",
  "gemini-2.5-flash-lite",
  "gemini-3-flash-preview",
  "gemini-2.0-flash-lite",
];
const AI_BASE_URL =
  "https://generativelanguage.googleapis.com/v1beta/models";

const SYSTEM_PROMPT =
  "You are a personal knowledge assistant. " +
  "Answer ONLY using the provided notes. " +
  "If the answer is not in the notes, say so clearly. " +
  "Answer in the same language as the user question when possible. " +
  "Be concise and direct. " +
  "After your answer, on its own line, write exactly: " +
  '"Sources: Title1, Title2" listing only note titles you actually used. ' +
  "Omit the Sources line entirely if you used no notes.";

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS, "Content-Type": "application/json" },
  });
}

function buildPrompt(
  query: string,
  notes: Array<{ title: string; body: string }>,
): string {
  const lines: string[] = ["Notes:"];
  for (const note of notes) {
    lines.push("---");
    lines.push(`Title: ${note.title}`);
    if (note.body.trim()) lines.push(note.body);
  }
  lines.push("---", "", `Question: ${query}`);
  return lines.join("\n");
}

async function logError(
  adminClient: ReturnType<typeof createClient>,
  userId: string,
  message: string,
  context: Record<string, unknown>,
): Promise<void> {
  try {
    await adminClient.from("error_logs").insert({
      user_id: userId,
      source: "edge_ai_search",
      message,
      context,
    });
  } catch {
    // Swallow — observability must not affect the response path.
  }
}

type UsageReservation = {
  allowed: boolean;
  query_count: number;
  daily_limit: number;
  tier: string;
};

async function consumeUsage(
  userId: string,
  usageDate: string,
): Promise<UsageReservation> {
  const { data, error } = await adminClient.rpc("consume_ai_search_usage", {
    p_user_id: userId,
    p_usage_date: usageDate,
  });
  if (error) throw error;
  const row = Array.isArray(data) ? data[0] : data;
  return {
    allowed: row?.allowed === true,
    query_count: Number(row?.query_count ?? 0),
    daily_limit: Number(row?.daily_limit ?? 5),
    tier: typeof row?.tier === "string" ? row.tier : "free",
  };
}

async function refundUsage(userId: string, usageDate: string): Promise<void> {
  try {
    await adminClient.rpc("refund_ai_search_usage", {
      p_user_id: userId,
      p_usage_date: usageDate,
    });
  } catch {
    // Quota refund is best-effort after upstream model failures.
  }
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: CORS });
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) return json({ error: "Unauthorized" }, 401);

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: authHeader } } },
  );

  const { data: { user }, error: authError } = await supabase.auth.getUser();
  if (authError || !user) return json({ error: "Unauthorized" }, 401);

  let query: string;
  let notes: Array<{ title: string; body: string }>;
  try {
    ({ query, notes } = await req.json());
  } catch {
    return json({ error: "Invalid JSON body" }, 400);
  }

  if (!query || !Array.isArray(notes)) {
    return json({ error: "Missing query or notes" }, 400);
  }

  const aiKey = Deno.env.get("AI_API_KEY");
  if (!aiKey) return json({ error: "AI not configured on server" }, 503);

  const today = new Date().toISOString().slice(0, 10);
  let usage: UsageReservation;
  try {
    usage = await consumeUsage(user.id, today);
  } catch (e) {
    const message = `Usage check failed: ${(e as Error).message}`;
    await logError(adminClient, user.id, message, {});
    return json({ error: message }, 500);
  }

  if (!usage.allowed) {
    return json({ error: "quota_exceeded" }, 429);
  }
  const tier = usage.tier;

  let answer = "";
  let lastError = "";
  let usedModel = "";
  const skippedModels: string[] = [];
  const prompt = buildPrompt(query, notes);
  const requestBody = JSON.stringify({
    system_instruction: { parts: [{ text: SYSTEM_PROMPT }] },
    contents: [{ role: "user", parts: [{ text: prompt }] }],
    generationConfig: { maxOutputTokens: 512, temperature: 0.2 },
  });

  try {
    for (const model of AI_MODELS) {
      const res = await fetch(
        `${AI_BASE_URL}/${model}:generateContent?key=${aiKey}`,
        {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: requestBody,
        },
      );

      if (res.status === 429) {
        skippedModels.push(model);
        await logError(adminClient, user.id, `Model quota exceeded: ${model}`, {
          model_skipped: model,
          reason: "quota_exceeded",
          tier,
        });
        continue;
      }

      if (!res.ok) {
        const err = await res.json().catch(() => ({}));
        lastError = (err as { error?: { message?: string } }).error?.message ??
          res.statusText;
        await logError(adminClient, user.id, `AI error: ${lastError}`, {
          model,
          http_status: res.status,
          tier,
        });
        break;
      }

      const data = await res.json();
      answer = data?.candidates?.[0]?.content?.parts?.[0]?.text ?? "";
      if (!answer) {
        lastError = "Empty response from AI";
        await logError(adminClient, user.id, lastError, { model, tier });
        break;
      }

      usedModel = model;
      if (skippedModels.length > 0) {
        await logError(
          adminClient,
          user.id,
          `Fallback succeeded on model: ${model}`,
          { models_skipped: skippedModels, model_used: model, tier },
        );
      }
      break;
    }
  } catch (e) {
    const errMsg = `AI request failed: ${(e as Error).message}`;
    await logError(adminClient, user.id, errMsg, {
      error_type: (e as Error).constructor?.name ?? "unknown",
      tier,
    });
    await refundUsage(user.id, today);
    return json({ error: errMsg }, 502);
  }

  if (!usedModel) {
    // Two failure modes reaching here:
    // (a) every model returned 429 → skippedModels is full → 503
    // (b) a non-429 error (4xx/5xx) broke the loop early → lastError is set → 502
    if (skippedModels.length === AI_MODELS.length) {
      await logError(
        adminClient,
        user.id,
        "All models quota exceeded",
        { models_tried: AI_MODELS, tier },
      );
      await refundUsage(user.id, today);
      return json({ error: "all_models_quota_exceeded" }, 503);
    }
    await refundUsage(user.id, today);
    return json({ error: lastError ? `AI error: ${lastError}` : "AI request failed" }, 502);
  }

  return json({ answer });
});
