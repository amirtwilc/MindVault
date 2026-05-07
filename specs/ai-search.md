# AI Search System

> Read this when working on `ai_search_service.dart`, `ai_search_provider.dart`, `ai_search_screen.dart`, `ai_constants.dart`, or the `supabase/functions/ai-search/` edge function.

## How it works

1. User types a query in `AiSearchScreen` (with optional voice via `speech_to_text`)
2. `AiSearchNotifier.search()` calls `AiSearchService.search()`
3. Service checks the **local AI cache** (`AiCacheTable`); if a cached response exists (within 24h TTL), returns it immediately with `fromCache: true`
4. If not cached, checks the **local rate limiter** (`RateLimiter`); aborts with `AiRateLimitedEvent` if the minute or daily limit is hit
5. **Relevance filter** (`_filterRelevant`): scores each non-private note by keyword match (title x3, body x1), takes top 15. If lexical scoring finds nothing, it falls back to the most recently updated non-private notes so multilingual or semantic queries can still reach the AI.
6. Sends query + filtered/fallback notes to the **Supabase edge function** `ai-search` (calls Gemini 2.5 Flash)
7. Edge function also enforces **server-side daily quota** (see `tier-system.md`)
8. Response is parsed for `Sources: Title1, Title2` line, cached, and returned

## Key files

| File | Role |
|------|------|
| `lib/services/ai_search_service.dart` | Core service: cache, rate limit, relevance filter, backend call |
| `lib/presentation/providers/ai_search_provider.dart` | State notifier + `aiSearchServiceProvider` (injects tier daily limit) |
| `lib/presentation/screens/home/ai_search_screen.dart` | Search UI + voice input |
| `lib/core/constants/ai_constants.dart` | `maxRequestsPerMinute=14`, `cacheTtl=24h` |
| `supabase/functions/ai-search/index.ts` | Deno edge function: auth -> quota check -> Gemini call -> increment usage |

## Deploying the edge function

```bash
# Install Supabase CLI if not already: https://supabase.com/docs/guides/cli
npx supabase functions deploy ai-search --project-ref <your-project-ref>
# Set the AI API key as a secret (currently backed by Gemini):
npx supabase secrets set AI_API_KEY=<your-key> --project-ref <your-project-ref>
```

The function reads `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `SUPABASE_SERVICE_ROLE_KEY`
from the runtime automatically. The service-role key is used to write server-side error
logs to `error_logs` when the AI API call fails.
