// MindVault - Jots organizer edge function.
//
// Authenticates the caller, atomically consumes the per-tier daily Jots AI
// quota from `tier_limits`, and asks Gemini for strict JSON suggestions.
//
// Deploy:
//   supabase functions deploy organize-jots --project-ref <ref>
//   supabase secrets set AI_API_KEY=<key> --project-ref <ref>

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const adminClient = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);

const AI_MODELS = [
  "gemini-2.5-flash",
  "gemini-2.5-flash-lite",
  "gemini-3-flash-preview",
  "gemini-2.0-flash-lite",
];
const AI_BASE_URL =
  "https://generativelanguage.googleapis.com/v1beta/models";

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

type JotInput = {
  id: string;
  text: string;
  created_at?: string;
};

type CategoryInput = {
  id: string;
  name: string;
};

type NoteInput = {
  id: string;
  title: string;
  category_id: string;
  category_name?: string;
  note_type?: string;
  updated_at?: string;
  last_opened_at?: string;
};

type OrganizeRequest = {
  locale?: string;
  now?: string;
  jots?: JotInput[];
  categories?: CategoryInput[];
  notes?: NoteInput[];
};

type UsageReservation = {
  allowed: boolean;
  organize_count: number;
  daily_limit: number;
  tier: string;
};

type PromptAliases = {
  jots: Array<[string, string, string?]>;
  categories: Array<[string, string]>;
  notes: Array<[string, string, string, string]>;
  jotAliases: Map<string, string>;
  categoryAliases: Map<string, string>;
  noteAliases: Map<string, string>;
  jotIdsByAlias: Map<string, string>;
  categoryIdsByAlias: Map<string, string>;
  noteIdsByAlias: Map<string, string>;
  noteTypesByAlias: Map<string, string>;
};

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS, "Content-Type": "application/json" },
  });
}

async function logError(
  userId: string,
  message: string,
  context: Record<string, unknown>,
): Promise<void> {
  try {
    await adminClient.from("error_logs").insert({
      user_id: userId,
      source: "edge_organize_jots",
      message,
      context,
    });
  } catch {
    // Observability must not affect the response path.
  }
}

async function consumeUsage(
  userId: string,
  usageDate: string,
): Promise<UsageReservation> {
  const { data, error } = await adminClient.rpc("consume_jot_ai_usage", {
    p_user_id: userId,
    p_usage_date: usageDate,
  });
  if (error) throw error;
  const row = Array.isArray(data) ? data[0] : data;
  return {
    allowed: row?.allowed === true,
    organize_count: Number(row?.organize_count ?? 0),
    daily_limit: Number(row?.daily_limit ?? 1),
    tier: typeof row?.tier === "string" ? row.tier : "free",
  };
}

async function refundUsage(userId: string, usageDate: string): Promise<void> {
  try {
    await adminClient.rpc("refund_jot_ai_usage", {
      p_user_id: userId,
      p_usage_date: usageDate,
    });
  } catch {
    // Quota refund is best-effort after upstream model failures.
  }
}

function stringValue(value: unknown): string | undefined {
  return typeof value === "string" ? value : undefined;
}

function cleanInput(body: unknown): OrganizeRequest {
  if (!body || typeof body !== "object") return {};
  const raw = body as Record<string, unknown>;

  const jots = Array.isArray(raw.jots)
    ? raw.jots
      .map((item): JotInput | null => {
        if (!item || typeof item !== "object") return null;
        const map = item as Record<string, unknown>;
        const id = stringValue(map.id);
        const text = stringValue(map.text);
        if (!id || !text) return null;
        return {
          id,
          text: text.slice(0, 100),
          created_at: stringValue(map.created_at),
        };
      })
      .filter((item): item is JotInput => item !== null)
      .slice(0, 30)
    : [];

  const categories = Array.isArray(raw.categories)
    ? raw.categories
      .map((item): CategoryInput | null => {
        if (!item || typeof item !== "object") return null;
        const map = item as Record<string, unknown>;
        const id = stringValue(map.id);
        const name = stringValue(map.name);
        if (!id || !name) return null;
        return { id, name: name.slice(0, 80) };
      })
      .filter((item): item is CategoryInput => item !== null)
    : [];

  const notes = Array.isArray(raw.notes)
    ? raw.notes
      .map((item): NoteInput | null => {
        if (!item || typeof item !== "object") return null;
        const map = item as Record<string, unknown>;
        const id = stringValue(map.id);
        const title = stringValue(map.title);
        const categoryId = stringValue(map.category_id);
        if (!id || !title || !categoryId) return null;
        return {
          id,
          title: title.slice(0, 120),
          category_id: categoryId,
          category_name: stringValue(map.category_name)?.slice(0, 80),
          note_type: stringValue(map.note_type),
          updated_at: stringValue(map.updated_at),
          last_opened_at: stringValue(map.last_opened_at),
        };
      })
      .filter((item): item is NoteInput => item !== null)
      .slice(0, 80)
    : [];

  return {
    locale: stringValue(raw.locale),
    now: stringValue(raw.now),
    jots,
    categories,
    notes,
  };
}

function buildPromptAliases(
  input: Required<Pick<OrganizeRequest, "jots" | "categories" | "notes">>,
): PromptAliases {
  const categoryAliases = new Map<string, string>();
  const categoryIdsByAlias = new Map<string, string>();
  const categories: Array<[string, string]> = [];
  input.categories.forEach((category, index) => {
    const alias = `c${index + 1}`;
    categoryAliases.set(category.id, alias);
    categoryIdsByAlias.set(alias, category.id);
    categories.push([alias, category.name]);
  });

  const jotAliases = new Map<string, string>();
  const jotIdsByAlias = new Map<string, string>();
  const jots: Array<[string, string, string?]> = [];
  input.jots.forEach((jot, index) => {
    const alias = `j${index + 1}`;
    jotAliases.set(jot.id, alias);
    jotIdsByAlias.set(alias, jot.id);
    jots.push(jot.created_at ? [alias, jot.text, jot.created_at] : [
      alias,
      jot.text,
    ]);
  });

  const noteAliases = new Map<string, string>();
  const noteIdsByAlias = new Map<string, string>();
  const noteTypesByAlias = new Map<string, string>();
  const notes: Array<[string, string, string, string]> = [];
  input.notes.forEach((note, index) => {
    const categoryAlias = categoryAliases.get(note.category_id);
    if (!categoryAlias) return;
    const alias = `n${index + 1}`;
    const noteType = note.note_type === "checklist" ? "checklist" : "text";
    noteAliases.set(note.id, alias);
    noteIdsByAlias.set(alias, note.id);
    noteTypesByAlias.set(alias, noteType);
    notes.push([alias, note.title, categoryAlias, noteType]);
  });

  return {
    jots,
    categories,
    notes,
    jotAliases,
    categoryAliases,
    noteAliases,
    jotIdsByAlias,
    categoryIdsByAlias,
    noteIdsByAlias,
    noteTypesByAlias,
  };
}

function buildPrompt(input: {
  locale: string;
  now: string;
  aliases: PromptAliases;
}): string {
  return [
    "Organize short unhandled thoughts for a private notes app. Return JSON only.",
    "Suggest only when confidence>=0.55; otherwise omit the jot. Never invent aliases.",
    "Actions: create=create note, add=add to note, reminder=standalone reminder.",
    "For create use c and nt(text/checklist); if unsure use the first category. For add use n. For alerts use ISO r with timezone; create/add may also include r.",
    "Use pr=true for sensitive/private notes such as passwords, codes, secrets, IDs, account/security details, or medical/financial info.",
    "Facts/info like codes -> create text note, usually pr=true. Dated tasks/calls -> reminder; if date has no time use 09:00. Undated ideas/tasks -> create note.",
    "Use locale+now for relative/ambiguous dates. Match meaning across languages.",
    "Use u to clean filler while preserving intent, <=100 chars, do not translate proper nouns unnecessarily. Example: I want to see The Matrix -> The Matrix.",
    "Keep titles short. Notes are ordered by recent/open relevance.",
    "Output compact JSON: {\"s\":[{\"j\":\"j1\",\"a\":\"create|add|reminder\",\"p\":0.85,\"t\":\"title\",\"c\":\"c1\",\"n\":\"n1\",\"nt\":\"text|checklist\",\"pr\":false,\"r\":\"ISO\",\"u\":\"cleaned text\"}]}",
    `locale=${input.locale};now=${input.now}`,
    `J=${JSON.stringify(input.aliases.jots)}`,
    `C=${JSON.stringify(input.aliases.categories)}`,
    `N=${JSON.stringify(input.aliases.notes)}`,
  ].join("\n");
}

const responseSchema = {
  type: "OBJECT",
  properties: {
    s: {
      type: "ARRAY",
      items: {
        type: "OBJECT",
        properties: {
          j: { type: "STRING" },
          a: { type: "STRING", enum: ["create", "add", "reminder"] },
          p: { type: "NUMBER" },
          t: { type: "STRING" },
          c: { type: "STRING" },
          n: { type: "STRING" },
          nt: { type: "STRING", enum: ["text", "checklist"] },
          pr: { type: "BOOLEAN" },
          r: { type: "STRING" },
          u: { type: "STRING" },
        },
        required: ["j", "a", "p"],
      },
    },
  },
  required: ["s"],
};

function extractObject(text: string): Record<string, unknown> {
  try {
    return JSON.parse(text) as Record<string, unknown>;
  } catch {
    const start = text.indexOf("{");
    const end = text.lastIndexOf("}");
    if (start < 0 || end <= start) return {};
    try {
      return JSON.parse(text.slice(start, end + 1)) as Record<string, unknown>;
    } catch {
      return {};
    }
  }
}

function extractAiText(value: unknown): string {
  const root = value as {
    candidates?: Array<{
      content?: {
        parts?: Array<{ text?: string }>;
      };
    }>;
  };
  return root.candidates?.[0]?.content?.parts?.[0]?.text ?? "";
}

function normalizeSuggestions(
  value: unknown,
  validJotIds: Set<string>,
  validCategoryIds: Set<string>,
  validCategoryNames: Set<string>,
  validNoteIds: Set<string>,
): Array<Record<string, unknown>> {
  if (!value || typeof value !== "object") return [];
  const raw = (value as Record<string, unknown>).suggestions;
  if (!Array.isArray(raw)) return [];

  const allowedActions = new Set(["create_note", "add_to_note", "reminder"]);
  const suggestions: Array<Record<string, unknown>> = [];
  const seenJots = new Set<string>();

  for (const item of raw) {
    if (!item || typeof item !== "object") continue;
    const map = item as Record<string, unknown>;
    const jotId = stringValue(map.jot_id);
    const action = stringValue(map.action);
    const confidence = typeof map.confidence === "number"
      ? map.confidence
      : Number(map.confidence ?? 0);

    if (!jotId || seenJots.has(jotId) || !validJotIds.has(jotId)) continue;
    if (!action || !allowedActions.has(action)) continue;
    if (!Number.isFinite(confidence) || confidence < 0.55) continue;

    const categoryId = stringValue(map.category_id);
    const categoryName = stringValue(map.category_name);
    const noteId = stringValue(map.note_id);
    const noteType = stringValue(map.note_type);
    const reminderAt = stringValue(map.reminder_at);
    const updatedText = stringValue(map.updated_text)?.trim();

    if (categoryId && !validCategoryIds.has(categoryId)) continue;
    if (!categoryId && categoryName &&
      !validCategoryNames.has(categoryName.toLowerCase())) continue;
    if (noteId && !validNoteIds.has(noteId)) continue;
    if (action === "add_to_note" && !noteId) continue;
    if (action === "reminder" && !reminderAt) continue;
    if (noteType && noteType !== "text" && noteType !== "checklist") continue;
    if (updatedText !== undefined &&
      (updatedText.length === 0 || updatedText.length > 100)) continue;

    seenJots.add(jotId);
    suggestions.push({
      jot_id: jotId,
      action,
      confidence,
      ...(stringValue(map.title) ? { title: stringValue(map.title) } : {}),
      ...(categoryId ? { category_id: categoryId } : {}),
      ...(categoryName ? { category_name: categoryName } : {}),
      ...(noteId ? { note_id: noteId } : {}),
      ...(noteType ? { note_type: noteType } : {}),
      ...(typeof map.is_private === "boolean"
        ? { is_private: map.is_private }
        : {}),
      ...(reminderAt ? { reminder_at: reminderAt } : {}),
      ...(updatedText ? { updated_text: updatedText } : {}),
      ...(stringValue(map.reason) ? { reason: stringValue(map.reason) } : {}),
    });
  }

  return suggestions;
}

function normalizeCompactSuggestions(
  value: unknown,
  aliases: PromptAliases,
): Array<Record<string, unknown>> {
  if (!value || typeof value !== "object") return [];
  const root = value as Record<string, unknown>;
  const raw = Array.isArray(root.s) ? root.s : root.suggestions;
  if (!Array.isArray(raw)) return [];

  const actionMap = new Map([
    ["create", "create_note"],
    ["add", "add_to_note"],
    ["reminder", "reminder"],
    ["create_note", "create_note"],
    ["add_to_note", "add_to_note"],
  ]);
  const firstCategoryId = aliases.categories.length > 0
    ? aliases.categoryIdsByAlias.get(aliases.categories[0][0])
    : undefined;
  const suggestions: Array<Record<string, unknown>> = [];
  const seenJots = new Set<string>();

  for (const item of raw) {
    if (!item || typeof item !== "object") continue;
    const map = item as Record<string, unknown>;
    const jotAlias = stringValue(map.j) ?? stringValue(map.jot_id);
    const compactAction = stringValue(map.a) ?? stringValue(map.action);
    const action = compactAction ? actionMap.get(compactAction) : undefined;
    const rawConfidence = map.p ?? map.confidence;
    const confidence = typeof rawConfidence === "number"
      ? rawConfidence
      : Number(rawConfidence ?? 0);

    const jotId = jotAlias ? aliases.jotIdsByAlias.get(jotAlias) : undefined;
    if (!jotId || seenJots.has(jotId)) continue;
    if (!action || !Number.isFinite(confidence) || confidence < 0.55) continue;

    const categoryAlias = stringValue(map.c) ?? stringValue(map.category_id);
    const noteAlias = stringValue(map.n) ?? stringValue(map.note_id);
    const noteType = stringValue(map.nt) ?? stringValue(map.note_type);
    const reminderAt = stringValue(map.r) ?? stringValue(map.reminder_at);
    const updatedText =
      (stringValue(map.u) ?? stringValue(map.updated_text))?.trim();
    const isPrivate = typeof map.pr === "boolean"
      ? map.pr
      : typeof map.is_private === "boolean"
      ? map.is_private
      : undefined;
    const categoryId = categoryAlias
      ? aliases.categoryIdsByAlias.get(categoryAlias)
      : undefined;
    const noteId = noteAlias ? aliases.noteIdsByAlias.get(noteAlias) : undefined;

    if (categoryAlias && !categoryId) continue;
    if (noteAlias && !noteId) continue;
    if (action === "add_to_note" && !noteId) continue;
    const resolvedCategoryId = categoryId ??
      (action === "create_note" ? firstCategoryId : undefined);
    if (action === "create_note" && !resolvedCategoryId) continue;
    if (action === "reminder" && !reminderAt) continue;
    if (noteType && noteType !== "text" && noteType !== "checklist") continue;
    if (updatedText !== undefined &&
      (updatedText.length === 0 || updatedText.length > 100)) continue;

    seenJots.add(jotId);
    suggestions.push({
      jot_id: jotId,
      action,
      confidence,
      ...((stringValue(map.t) ?? stringValue(map.title))
        ? { title: stringValue(map.t) ?? stringValue(map.title) }
        : {}),
      ...(resolvedCategoryId ? { category_id: resolvedCategoryId } : {}),
      ...(noteId ? { note_id: noteId } : {}),
      ...(noteType ? { note_type: noteType } : {}),
      ...(typeof isPrivate === "boolean" ? { is_private: isPrivate } : {}),
      ...(reminderAt ? { reminder_at: reminderAt } : {}),
      ...(updatedText ? { updated_text: updatedText } : {}),
    });
  }

  return suggestions;
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

  let input: OrganizeRequest;
  try {
    input = cleanInput(await req.json());
  } catch {
    return json({ error: "Invalid JSON body" }, 400);
  }

  if (!input.jots || input.jots.length === 0) {
    return json({ error: "No jots supplied" }, 400);
  }

  const aiKey = Deno.env.get("AI_API_KEY");
  if (!aiKey) return json({ error: "AI not configured on server" }, 503);

  const today = new Date().toISOString().slice(0, 10);
  let usage: UsageReservation;
  try {
    usage = await consumeUsage(user.id, today);
  } catch (e) {
    const message = `Usage check failed: ${(e as Error).message}`;
    await logError(user.id, message, {});
    return json({ error: message }, 500);
  }

  if (!usage.allowed) {
    return json({ error: "quota_exceeded" }, 429);
  }
  const tier = usage.tier;

  const aliases = buildPromptAliases({
    jots: input.jots,
    categories: input.categories ?? [],
    notes: input.notes ?? [],
  });
  const prompt = buildPrompt({
    locale: input.locale ?? "en-US",
    now: input.now ?? new Date().toISOString(),
    aliases,
  });
  const request = {
    system_instruction: {
      parts: [{
        text:
          "You are a cautious personal knowledge organizer. Return valid JSON only.",
      }],
    },
    contents: [{ role: "user", parts: [{ text: prompt }] }],
    generationConfig: {
      maxOutputTokens: 1536,
      temperature: 0.1,
      responseMimeType: "application/json",
      responseSchema,
    },
  };
  const requestBody = JSON.stringify(request);

  let usedModel = "";
  let lastError = "";
  const skippedModels: string[] = [];
  let aiText = "";
  let aiResponse: unknown = null;

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
        await logError(user.id, `Model quota exceeded: ${model}`, {
          model_skipped: model,
          reason: "quota_exceeded",
          tier,
        });
        continue;
      }

      aiResponse = await res.json().catch(() => ({}));
      if (!res.ok) {
        lastError = (aiResponse as { error?: { message?: string } }).error
          ?.message ?? res.statusText;
        await logError(user.id, `AI error: ${lastError}`, {
          model,
          http_status: res.status,
          tier,
        });
        break;
      }

      aiText = extractAiText(aiResponse);
      if (!aiText) {
        lastError = "Empty response from AI";
        await logError(user.id, lastError, { model, tier });
        break;
      }

      usedModel = model;
      break;
    }
  } catch (e) {
    const message = `AI request failed: ${(e as Error).message}`;
    await logError(user.id, message, {
      error_type: (e as Error).constructor?.name ?? "unknown",
      tier,
    });
    await refundUsage(user.id, today);
    return json({ error: message }, 502);
  }

  if (!usedModel) {
    if (skippedModels.length === AI_MODELS.length) {
      await logError(user.id, "All models quota exceeded", {
        models_tried: AI_MODELS,
        tier,
      });
      await refundUsage(user.id, today);
      return json({ error: "all_models_quota_exceeded" }, 503);
    }
    await refundUsage(user.id, today);
    return json({
      error: lastError ? `AI error: ${lastError}` : "AI request failed",
    }, 502);
  }

  const parsed = extractObject(aiText);
  const suggestions = normalizeCompactSuggestions(parsed, aliases);

  return json({
    run_id: crypto.randomUUID(),
    suggestions,
  });
});
