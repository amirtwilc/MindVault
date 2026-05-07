# How AI Search Works in MindVault

AI search lets you ask natural-language questions about your notes and get a real answer — not just a list of matching notes. For example, instead of searching "dentist", you can ask *"What did I decide about my dental appointment?"* and get a direct response with the source notes linked below it.

---

## The Big Picture

When you search, MindVault does several things in order to save API costs, respect limits, and avoid leaking private notes:

```
User types query
      ↓
Check local cache (same query in last 24h? Return instantly)
      ↓
Check rate limits (too many requests? Show a wait message)
      ↓
Filter your notes by relevance (score by keyword match; max 15 notes)
      ↓
Send query + relevant notes → Supabase Edge Function → Gemini 2.5 Flash
      ↓
Parse response, save to cache, show answer + source chips
```

---

## Step-by-step walkthrough

### 1. Cache check

Before doing anything expensive, the app hashes your query (SHA-256) and looks it up in a local SQLite table (`AiCacheTable`). If you asked the same question in the last 24 hours, it returns the saved answer immediately — marked with a small clock icon that says "from cache."

```dart
// ai_search_service.dart:155
final cacheKey = _hashQuery(normalized.toLowerCase());
final cached = await _db.getCachedResponse(cacheKey);
if (cached != null) {
  yield AiDoneEvent(...fromCache: true);
  return;
}
```

**Example:** You search *"what are my goals for this year?"* at 9am. At 2pm you search it again — the app returns the same answer in milliseconds without touching the network.

---

### 2. Rate limit check

Two limits protect against runaway API usage:

| Limit | Value | Why |
|---|---|---|
| Per-minute | 14 requests | Gemini free tier cap is 15 RPM |
| Per-day | 5 (free) / more (pro) | Tier-based quota |

These are tracked in `SharedPreferences` on the device (the minute window) and in Supabase's `ai_usage` table (the day window). If either is hit, you see a countdown timer instead of a result.

The server independently enforces the daily cap too — so a user can't bypass the client limit by calling the edge function directly.

---

### 3. Relevance filter

Your notes are stored encrypted, so the app can't use the database's full-text search index for AI (it only indexes ciphertext). Instead, it does an in-memory keyword scan of your already-decrypted notes:

```dart
// ai_search_service.dart:244
for (final word in words) {
  if (titleLow.contains(word)) score += 3;  // title match is worth more
  if (bodyLow.contains(word)) score += 1;
}
```

- Private notes are always excluded.
- Top 15 scoring notes are picked.
- **Fallback:** If zero notes score (e.g. a vague or multilingual query), the 15 most recently updated notes are used anyway, so the AI still has something to work with.

Each note body is capped at 600 characters, and the total context sent to Gemini is capped at 8,000 characters.

**Example:** You have 200 notes. You search *"dentist appointment"*. Notes with "dentist" in the title get +3 each; notes with "dentist" in the body get +1. The top 15 are sent to Gemini.

---

### 4. Edge function call (Supabase → Gemini)

The filtered notes and your query are sent to a Deno edge function deployed on Supabase. It:

1. **Authenticates** you via the JWT in the request header.
2. **Checks the server-side daily quota** against the `ai_usage` table.
3. **Builds a prompt** that looks like this:

```
Notes:
---
Title: Dentist appointment
Reschedule to March 15, confirmed with receptionist.
---
Title: Health to-dos
...

Question: What did I decide about my dental appointment?
```

4. **Calls Gemini 2.5 Flash** with this prompt and a system instruction that says: answer only from the notes, be concise, cite your sources.
5. If Gemini is over its own quota (429), it automatically tries `gemini-2.5-flash-lite`, then `gemini-3-flash-preview`, then `gemini-2.0-flash-lite` — in that order.
6. **Increments `ai_usage`** only on success.

---

### 5. Parsing the response

Gemini is instructed to end every response with:

```
Sources: Note Title A, Note Title B
```

The app splits on that last line to separate the answer text from the citations:

```dart
// ai_search_service.dart:283
if (lastLine.startsWith('Sources: ')) {
  final answer = lines.sublist(0, lastIdx).join('\n').trimRight();
  final titles = lastLine.substring('Sources: '.length).split(',')...
}
```

The cited titles are then matched back to note IDs so tapping a source chip opens that note directly.

---

### 6. What you see

| State | UI |
|---|---|
| Idle | Suggestion chips ("What are my goals for Q2?", etc.) |
| Loading | Spinner + "Thinking..." |
| Success | Answer text + source chips (tap to open note) |
| From cache | Clock icon + "from cache" label |
| Rate limited | Hourglass + countdown to reset |
| Error | Error message + Retry button |

---

## Key limits at a glance

| Constant | Value | Location |
|---|---|---|
| Max notes sent to AI | 15 | `AiConstants.ftsTopK` |
| Max chars per note body | 600 | `AiConstants.noteBodyMaxChars` |
| Total context budget | 8,000 chars | `AiConstants.tokenBudget` |
| Cache TTL | 24 hours | `AiConstants.cacheTtl` |
| Rate limit (per minute) | 14 requests | `AiConstants.maxRequestsPerMinute` |
| Daily limit (free tier) | 5 | `TierLimits.free()` |
| Gemini output tokens | 512 | Edge function `generationConfig` |

---

## Privacy notes

- **Private notes are never sent to AI.** The filter skips any note marked as private before building the context.
- **AI history is cleared on account switch.** If a different user signs into the same device, the local AI history is wiped to prevent cross-account leakage (`aiHistoryIsolationProvider`).
- Notes are decrypted locally before the keyword filter runs — the raw text is only held in memory, never written back to disk in plaintext.
