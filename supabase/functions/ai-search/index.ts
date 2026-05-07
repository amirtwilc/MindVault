// MindVault — AI search edge function.
//
// Authenticates the caller, checks the per-tier daily quota, forwards the
// request to Gemini, increments usage on success. The Flutter client also
// applies a local rate-limiter — this server-side check is the authoritative
// quota enforcement.
//
// Deploy:
//   supabase functions deploy ai-search --project-ref <ref>
//   supabase secrets   set    GEMINI_API_KEY=<key> --project-ref <ref>

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const GEMINI_URL =
  "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent";

const SYSTEM_PROMPT =
  "You are a personal knowledge assistant. " +
  "Answer ONLY using the provided notes. " +
  "If the answer is not in the notes, say so clearly. " +
  "Answer in the same language as the user question when possible. " +
  "Be concise and direct. " +
  "After your answer, on its own line, write exactly: " +
  '"Sources: Title1, Title2" listing only note titles you actually used. ' +
  "Omit the Sources line entirely if you used no notes.";

// Mirror of TierLimits.free()/.pro() in lib/domain/entities/tier_limits.dart.
// Update both sides together.
const TIER_LIMITS: Record<string, number> = {
  free: 5,
  pro: 50,
};

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

  const today = new Date().toISOString().slice(0, 10);

  const [profileRes, usageRes] = await Promise.all([
    supabase.from("profiles").select("tier").eq("id", user.id).maybeSingle(),
    supabase
      .from("ai_usage")
      .select("query_count")
      .eq("user_id", user.id)
      .eq("usage_date", today)
      .maybeSingle(),
  ]);

  const tier = (profileRes.data?.tier as string) ?? "free";
  const dailyLimit = TIER_LIMITS[tier] ?? TIER_LIMITS["free"];
  const usedToday = (usageRes.data?.query_count as number) ?? 0;

  if (usedToday >= dailyLimit) {
    return json({ error: "quota_exceeded" }, 429);
  }

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

  const geminiKey = Deno.env.get("GEMINI_API_KEY");
  if (!geminiKey) return json({ error: "AI not configured on server" }, 503);

  let answer: string;
  try {
    const prompt = buildPrompt(query, notes);
    const res = await fetch(`${GEMINI_URL}?key=${geminiKey}`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        system_instruction: { parts: [{ text: SYSTEM_PROMPT }] },
        contents: [{ role: "user", parts: [{ text: prompt }] }],
        generationConfig: { maxOutputTokens: 512, temperature: 0.2 },
      }),
    });

    if (!res.ok) {
      const err = await res.json().catch(() => ({}));
      const msg = (err as { error?: { message?: string } }).error?.message ??
        res.statusText;
      return json({ error: `Gemini error: ${msg}` }, 502);
    }

    const data = await res.json();
    answer = data?.candidates?.[0]?.content?.parts?.[0]?.text ?? "";
    if (!answer) return json({ error: "Empty response from Gemini" }, 502);
  } catch (e) {
    return json({ error: `AI request failed: ${(e as Error).message}` }, 502);
  }

  await supabase.from("ai_usage").upsert(
    { user_id: user.id, usage_date: today, query_count: usedToday + 1 },
    { onConflict: "user_id,usage_date" },
  );

  return json({ answer });
});
