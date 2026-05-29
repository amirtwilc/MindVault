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
  local_now?: string;
  time_zone_offset_minutes?: number;
  time_zone_name?: string;
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
  noteIdsByTitle: Map<string, string>;
  noteCategoryAliasesByAlias: Map<string, string>;
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

function numberValue(value: unknown): number | undefined {
  if (typeof value === "number" && Number.isFinite(value)) return value;
  if (typeof value !== "string" || value.trim().length === 0) return undefined;
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : undefined;
}

function normalizeNoteType(value: unknown): string | undefined {
  const raw = stringValue(value);
  if (raw === "record" || raw === "text") return "record";
  if (raw === "plan" || raw === "checklist") return "plan";
  return undefined;
}

function normalizeLocalReminderAt(value: unknown): string | undefined {
  const raw = stringValue(value)?.trim();
  if (!raw) return undefined;

  const dateTime = raw.match(
    /^(\d{4}-\d{2}-\d{2})[T ](\d{1,2}):(\d{2})(?::(\d{2})(?:\.\d+)?)?(?:Z|[+-]\d{2}:?\d{2})?$/,
  );
  if (dateTime) {
    const hour = dateTime[2].padStart(2, "0");
    const second = dateTime[4] ?? "00";
    return `${dateTime[1]}T${hour}:${dateTime[3]}:${second}`;
  }

  const dateOnly = raw.match(/^(\d{4}-\d{2}-\d{2})$/);
  if (dateOnly) return `${dateOnly[1]}T09:00:00`;

  return undefined;
}

function parseLocalDateTime(value: string): Date | undefined {
  const match = value.match(
    /^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2})(?::(\d{2}))?$/,
  );
  if (!match) return undefined;
  return new Date(Date.UTC(
    Number(match[1]),
    Number(match[2]) - 1,
    Number(match[3]),
    Number(match[4]),
    Number(match[5]),
    Number(match[6] ?? 0),
  ));
}

function formatLocalDateTime(date: Date, timeSource: Date): string {
  const year = date.getUTCFullYear();
  const month = String(date.getUTCMonth() + 1).padStart(2, "0");
  const day = String(date.getUTCDate()).padStart(2, "0");
  const hour = String(timeSource.getUTCHours()).padStart(2, "0");
  const minute = String(timeSource.getUTCMinutes()).padStart(2, "0");
  return `${year}-${month}-${day}T${hour}:${minute}`;
}

function hasExplicitDate(text: string): boolean {
  return /\b\d{4}-\d{2}-\d{2}\b/.test(text) ||
    /\b\d{1,2}[./-]\d{1,2}(?:[./-]\d{2,4})?\b/.test(text) ||
    /\b(jan|feb|mar|apr|may|jun|jul|aug|sep|sept|oct|nov|dec)[a-z]*\b/i
      .test(text);
}

function escapeRegExp(value: string): string {
  return value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

function hasWeekdayCandidate(text: string, candidate: string): boolean {
  const normalized = candidate.trim().toLowerCase();
  if (normalized.length < 2) return false;
  if (/^[a-z]+$/i.test(normalized)) {
    return new RegExp(`\\b${escapeRegExp(normalized)}\\b`, "i").test(text);
  }
  return text.includes(normalized);
}

function weekdayFromText(text: string, locale: string): number | undefined {
  const normalizedText = text.toLowerCase();
  const candidates: Array<[string, number]> = [
    ["sunday", 0],
    ["sun", 0],
    ["monday", 1],
    ["mon", 1],
    ["tuesday", 2],
    ["tue", 2],
    ["tues", 2],
    ["wednesday", 3],
    ["wed", 3],
    ["thursday", 4],
    ["thu", 4],
    ["thur", 4],
    ["thurs", 4],
    ["friday", 5],
    ["fri", 5],
    ["saturday", 6],
    ["sat", 6],
  ];

  for (let day = 0; day < 7; day++) {
    const date = new Date(Date.UTC(2023, 0, 1 + day));
    for (const width of ["long", "short"] as const) {
      const name = new Intl.DateTimeFormat(locale, { weekday: width })
        .format(date);
      candidates.push([name, day]);
    }
  }

  candidates.sort((a, b) => b[0].length - a[0].length);
  return candidates.find(([candidate]) =>
    hasWeekdayCandidate(normalizedText, candidate)
  )?.[1];
}

function correctWeekdayReminderAt(input: {
  reminderAt: string;
  jotText?: string;
  localNow: string;
  locale: string;
}): string {
  if (!input.jotText || hasExplicitDate(input.jotText)) {
    return input.reminderAt;
  }
  const targetDay = weekdayFromText(input.jotText, input.locale);
  if (targetDay === undefined) return input.reminderAt;

  const reminderDate = parseLocalDateTime(input.reminderAt);
  const localNowDate = parseLocalDateTime(
    normalizeLocalReminderAt(input.localNow) ?? input.localNow,
  );
  if (!reminderDate || !localNowDate) return input.reminderAt;

  let delta = (targetDay - localNowDate.getUTCDay() + 7) % 7;
  if (delta === 0 && /\bnext\b/i.test(input.jotText)) delta = 7;
  const correctedDate = new Date(localNowDate);
  correctedDate.setUTCDate(localNowDate.getUTCDate() + delta);
  return formatLocalDateTime(correctedDate, reminderDate);
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
    local_now: stringValue(raw.local_now),
    time_zone_offset_minutes: numberValue(raw.time_zone_offset_minutes),
    time_zone_name: stringValue(raw.time_zone_name),
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
  const noteIdsByTitle = new Map<string, string>();
  const ambiguousNoteTitles = new Set<string>();
  const noteCategoryAliasesByAlias = new Map<string, string>();
  const noteTypesByAlias = new Map<string, string>();
  const notes: Array<[string, string, string, string]> = [];
  input.notes.forEach((note, index) => {
    const categoryAlias = categoryAliases.get(note.category_id);
    if (!categoryAlias) return;
    const alias = `n${index + 1}`;
    const noteType = normalizeNoteType(note.note_type) ?? "record";
    noteAliases.set(note.id, alias);
    noteIdsByAlias.set(alias, note.id);
    const normalizedTitle = note.title.trim().toLowerCase();
    if (normalizedTitle && !ambiguousNoteTitles.has(normalizedTitle)) {
      if (noteIdsByTitle.has(normalizedTitle)) {
        noteIdsByTitle.delete(normalizedTitle);
        ambiguousNoteTitles.add(normalizedTitle);
      } else {
        noteIdsByTitle.set(normalizedTitle, note.id);
      }
    }
    noteCategoryAliasesByAlias.set(alias, categoryAlias);
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
    noteIdsByTitle,
    noteCategoryAliasesByAlias,
    noteTypesByAlias,
  };
}

function resolveNoteId(value: string | undefined, aliases: PromptAliases) {
  if (!value) return undefined;
  return aliases.noteIdsByAlias.get(value) ??
    (aliases.noteAliases.has(value) ? value : undefined) ??
    aliases.noteIdsByTitle.get(value.trim().toLowerCase());
}

function buildPrompt(input: {
  locale: string;
  now: string;
  localNow?: string;
  timeZoneOffsetMinutes?: number;
  timeZoneName?: string;
  aliases: PromptAliases;
}): string {
  return [
    "Organize MindVault jots into useful note actions. Return one minified JSON object only.",
    "Use only supplied aliases/data; no outside knowledge, invented facts, dates, people, or context. Preserve intent. Omit weak guesses.",
    "Input: J=[j,text,created_at?], C=[c,name], N=[n,title,c,nt]. Use aliases (j1,c1,n1), never names or real ids.",
    "Always output all keys {j,a,p,t,c,n,nt,pr,r,u}; use \"\" for unused string keys. a=create|add|reminder. create uses t,c,nt,pr,u; add uses c,n,u; create/add may also set r. reminder uses r,u and creates no note.",
    "Choose: if useful only when surfaced later, use reminder; if it has lasting reference/list/project value, use create/add; add r only if it also needs an alert. Single dated/deadline tasks are usually reminder, not a note. add if N has exact/near title match or strong semantic match; never by category alone. unsure add/create=>create. create c defaults to first C.",
    "nt by intent, not keywords: plan only for user action/list intent (need/want to buy/watch/read/play X, shopping, tasks); record for facts/preferences/reference (Beth likes to read sci-fi books).",
    "For plan notes, t names the reusable list/project; u is the single item. Strip command words when clear: 'I need to buy milk'->'Milk'.",
    "u: final text to insert/display; same language; <=100 chars. Replace today/tomorrow/yesterday with local date. Never add facts/tags/explanations.",
    "t: short reusable topic/collection title <=60 chars; same language as thought unless mixed/proper noun; avoid full-thought titles.",
    "pr=true for passwords, codes, secrets, credentials, tokens, or clearly sensitive/private content; otherwise pr=false.",
    "r: set when an alert should be scheduled. Resolve from locale+local_now; compute weekdays exactly; if date has no time use 09:00; if date/time unresolved omit. r is local YYYY-MM-DDTHH:mm, no Z/UTC/offset.",
    "JSON shape: {\"s\":[{\"j\":\"j1\",\"a\":\"create\",\"p\":0.85,\"t\":\"title\",\"c\":\"c1\",\"n\":\"\",\"nt\":\"plan\",\"pr\":false,\"r\":\"\",\"u\":\"text\"}]}",
    `locale=${input.locale};now=${input.now}`,
    `local_now=${input.localNow ?? input.now};timezone_offset_minutes=${input.timeZoneOffsetMinutes ?? 0};timezone_name=${input.timeZoneName ?? ""}`,
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
          j: { type: "STRING", maxLength: 12 },
          a: { type: "STRING", enum: ["create", "add", "reminder"] },
          p: { type: "NUMBER" },
          t: { type: "STRING", maxLength: 60 },
          c: { type: "STRING", maxLength: 12 },
          n: { type: "STRING", maxLength: 120 },
          nt: { type: "STRING", enum: ["record", "plan"] },
          pr: { type: "BOOLEAN" },
          r: { type: "STRING", maxLength: 19 },
          u: { type: "STRING", maxLength: 100 },
        },
        required: ["j", "a", "p", "t", "c", "n", "nt", "pr", "r", "u"],
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

function aiErrorMessage(value: unknown, fallback: string): string {
  return (value as { error?: { message?: string } }).error?.message ??
    fallback;
}

function isRetryableModelError(status: number, message: string): boolean {
  const normalized = message.toLowerCase();
  return status === 429 ||
    normalized.includes("currently experiencing high demand") ||
    normalized.includes("spikes in demand");
}

function thinkingBudgetForModel(model: string): number | undefined {
  if (model.startsWith("gemini-2.0")) return undefined;
  return 512;
}

function buildAiRequest(prompt: string, model: string): Record<string, unknown> {
  const thinkingBudget = thinkingBudgetForModel(model);
  return {
    system_instruction: {
      parts: [{
        text:
          "You are a cautious personal knowledge organizer. Return valid JSON only.",
      }],
    },
    contents: [{ role: "user", parts: [{ text: prompt }] }],
    generationConfig: {
      maxOutputTokens: 1024,
      temperature: 0.1,
      ...(thinkingBudget
        ? { thinkingConfig: { thinkingBudget } }
        : {}),
      responseMimeType: "application/json",
      responseSchema,
    },
  };
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
    const reminderAt = normalizeLocalReminderAt(map.reminder_at);
    const updatedText = stringValue(map.updated_text)?.trim();

    if (categoryId && !validCategoryIds.has(categoryId)) continue;
    if (!categoryId && categoryName &&
      !validCategoryNames.has(categoryName.toLowerCase())) continue;
    if (noteId && !validNoteIds.has(noteId)) continue;
    if (action === "add_to_note" && !noteId) continue;
    if (action === "reminder" && !reminderAt) continue;
    const normalizedNoteType = normalizeNoteType(noteType);
    if (noteType && !normalizedNoteType) continue;
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
      ...(action === "create_note" && normalizedNoteType
        ? { note_type: normalizedNoteType }
        : {}),
      ...(action === "create_note" && typeof map.is_private === "boolean"
        ? { is_private: map.is_private }
        : {}),
      ...(reminderAt ? { reminder_at: reminderAt } : {}),
      ...(updatedText ? { updated_text: updatedText } : {}),
    });
  }

  return suggestions;
}

function normalizeCompactSuggestions(
  value: unknown,
  aliases: PromptAliases,
  options: { locale: string; localNow: string },
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
  const jotTextsByAlias = new Map(
    aliases.jots.map(([alias, text]) => [alias, text]),
  );
  const suggestions: Array<Record<string, unknown>> = [];
  const seenJots = new Set<string>();

  for (const item of raw) {
    if (!item || typeof item !== "object") continue;
    const map = item as Record<string, unknown>;
    const jotAlias = stringValue(map.j) ?? stringValue(map.jot_id);
    const compactAction = stringValue(map.a) ?? stringValue(map.action);
    let action = compactAction ? actionMap.get(compactAction) : undefined;
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
    let reminderAt = normalizeLocalReminderAt(map.r ?? map.reminder_at);
    const updatedText =
      (stringValue(map.u) ?? stringValue(map.updated_text))?.trim();
    const title = stringValue(map.t) ?? stringValue(map.title);
    const jotText = jotAlias ? jotTextsByAlias.get(jotAlias) : undefined;
    const isPrivate = typeof map.pr === "boolean"
      ? map.pr
      : typeof map.is_private === "boolean"
      ? map.is_private
      : undefined;
    let noteId = resolveNoteId(noteAlias, aliases);
    if (action === "create_note" && !noteId && title) {
      const existingNoteId = resolveNoteId(title, aliases);
      if (existingNoteId) {
        action = "add_to_note";
        noteId = existingNoteId;
      }
    }
    const resolvedNoteAlias = noteId
      ? aliases.noteAliases.get(noteId)
      : undefined;
    const noteCategoryAlias = resolvedNoteAlias
      ? aliases.noteCategoryAliasesByAlias.get(resolvedNoteAlias)
      : undefined;
    const resolvedCategoryAlias = action === "add_to_note" && noteCategoryAlias
      ? noteCategoryAlias
      : categoryAlias;
    const categoryId = resolvedCategoryAlias
      ? aliases.categoryIdsByAlias.get(resolvedCategoryAlias)
      : undefined;

    if (categoryAlias && !aliases.categoryIdsByAlias.has(categoryAlias)) {
      continue;
    }
    if (noteAlias && !noteId) continue;
    if (action === "add_to_note" && noteAlias && categoryAlias &&
      noteCategoryAlias &&
      categoryAlias !== noteCategoryAlias) continue;
    if (action === "add_to_note" && !noteId) continue;
    const resolvedCategoryId = categoryId ??
      (action === "create_note" ? firstCategoryId : undefined);
    if (action === "create_note" && !resolvedCategoryId) continue;
    if (action === "reminder" && !reminderAt) continue;
    if (reminderAt) {
      reminderAt = correctWeekdayReminderAt({
        reminderAt,
        jotText,
        localNow: options.localNow,
        locale: options.locale,
      });
    }
    const normalizedNoteType = normalizeNoteType(noteType);
    if (noteType && !normalizedNoteType) continue;
    if (updatedText !== undefined &&
      (updatedText.length === 0 || updatedText.length > 100)) continue;

    seenJots.add(jotId);
    suggestions.push({
      jot_id: jotId,
      action,
      confidence,
      ...(action === "create_note" && title ? { title } : {}),
      ...(resolvedCategoryId ? { category_id: resolvedCategoryId } : {}),
      ...(noteId ? { note_id: noteId } : {}),
      ...(action === "create_note" && normalizedNoteType
        ? { note_type: normalizedNoteType }
        : {}),
      ...(action === "create_note" && typeof isPrivate === "boolean"
        ? { is_private: isPrivate }
        : {}),
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
    localNow: input.local_now,
    timeZoneOffsetMinutes: input.time_zone_offset_minutes,
    timeZoneName: input.time_zone_name,
    aliases,
  });
  let usedModel = "";
  let lastError = "";
  const skippedModels: string[] = [];
  const temporarilyUnavailableModels: string[] = [];
  let aiText = "";
  let aiResponse: unknown = null;
  let request: Record<string, unknown> | null = null;

  try {
    for (const model of AI_MODELS) {
      request = buildAiRequest(prompt, model);
      const res = await fetch(
        `${AI_BASE_URL}/${model}:generateContent?key=${aiKey}`,
        {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(request),
        },
      );

      aiResponse = await res.json().catch(() => ({}));
      if (res.status === 429) {
        lastError = aiErrorMessage(aiResponse, res.statusText);
        skippedModels.push(model);
        await logError(user.id, `Model quota exceeded: ${model}`, {
          model_skipped: model,
          reason: "quota_exceeded",
          message: lastError,
          tier,
        });
        continue;
      }

      if (!res.ok) {
        lastError = aiErrorMessage(aiResponse, res.statusText);
        if (isRetryableModelError(res.status, lastError)) {
          skippedModels.push(model);
          temporarilyUnavailableModels.push(model);
          await logError(user.id, `Retryable model error: ${model}`, {
            model_skipped: model,
            reason: "retryable_model_error",
            http_status: res.status,
            message: lastError,
            tier,
          });
          continue;
        }
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
      if (temporarilyUnavailableModels.length > 0) {
        await logError(user.id, "All models temporarily unavailable", {
          models_tried: AI_MODELS,
          temporarily_unavailable_models: temporarilyUnavailableModels,
          last_error: lastError,
          tier,
        });
        await refundUsage(user.id, today);
        return json({ error: "all_models_temporarily_unavailable" }, 503);
      }
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
  const suggestions = normalizeCompactSuggestions(parsed, aliases, {
    locale: input.locale ?? "en-US",
    localNow: input.local_now ?? input.now ?? new Date().toISOString(),
  });

  return json({
    run_id: crypto.randomUUID(),
    suggestions,
    ai_debug: {
      model: usedModel,
      skipped_models: skippedModels,
      temporarily_unavailable_models: temporarilyUnavailableModels,
      request,
      raw_response: aiResponse,
      raw_text: aiText,
      parsed,
    },
  });
});
