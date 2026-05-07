# Tier System

> Read this when working on `tier_limits.dart`, `tier_provider.dart`, `supabase_user_profile_datasource.dart`, the settings screen tier UI, or the `ai-search` edge function quota logic.

## Overview

All users start on the **free tier**. You (admin) manually upgrade users to **pro** by running SQL in the Supabase dashboard. No payment flow exists yet — this is the groundwork only.

## Supabase tables

These are part of the schema (run once in the Supabase SQL editor):

```sql
-- user_profiles: stores tier per user
CREATE TABLE IF NOT EXISTS user_profiles (
  user_id uuid PRIMARY KEY REFERENCES auth.users ON DELETE CASCADE,
  tier text NOT NULL DEFAULT 'free',
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT valid_tier CHECK (tier IN ('free', 'pro'))
);
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users read their own profile"
  ON user_profiles FOR SELECT USING (auth.uid() = user_id);

-- Auto-create a free profile on first sign-in
CREATE OR REPLACE FUNCTION create_user_profile()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  INSERT INTO user_profiles (user_id) VALUES (NEW.id)
  ON CONFLICT (user_id) DO NOTHING;
  RETURN NEW;
END;
$$;
CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION create_user_profile();

-- ai_usage: daily AI search counts per user
CREATE TABLE IF NOT EXISTS ai_usage (
  user_id uuid NOT NULL REFERENCES auth.users ON DELETE CASCADE,
  usage_date date NOT NULL DEFAULT CURRENT_DATE,
  query_count int NOT NULL DEFAULT 0,
  PRIMARY KEY (user_id, usage_date)
);
ALTER TABLE ai_usage ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users manage their own AI usage"
  ON ai_usage FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);
```

## Upgrading a user to Pro (admin only)

In the Supabase SQL editor:
```sql
UPDATE user_profiles SET tier = 'pro'
WHERE user_id = (SELECT id FROM auth.users WHERE email = 'user@example.com');
```

To upgrade yourself for testing:
```sql
UPDATE user_profiles SET tier = 'pro' WHERE user_id = auth.uid();
```

## Tier limits

Stored in the `tier_limits` Supabase table — the single source of truth.
**To change limits for all users, update the table row in the Supabase dashboard:**

```sql
UPDATE tier_limits SET ai_searches_per_day = 10 WHERE tier = 'free';
```

The Flutter client reads limits via `SupabaseUserProfileDatasource.fetchTierLimits()`.
The edge function reads them directly from the table. No code changes or redeployment
needed when adjusting limits.

`TierLimits.free()` and `TierLimits.pro()` in `lib/domain/entities/tier_limits.dart`
are **offline fallbacks only** and do not need to match the live table values.

Default values (seeded on schema creation):

| Limit | Free | Pro |
|-------|------|-----|
| AI searches/day | 5 | 50 |
| Max notes | 100 | 1000 |
| Max categories | 10 | 50 |
| Max chars/note | 5000 | 20000 |

## Enforcement

- **Client-side (local rate limiter)**: `AiSearchService` checks `RateLimiter.getDayUsage()` against `tier.aiSearchesPerDay` before calling the edge function. Also enforces minute rate limit (14 RPM hard cap).
- **Server-side (edge function)**: `ai-search/index.ts` reads `user_profiles` and `ai_usage` for today's count, returns `quota_exceeded` (429) if over limit, then increments on success.
- **Notes limit**: checked in `NotesListScreen` FAB before navigating to editor.
- **Categories limit**: checked in `HomeScreen` FAB before showing create dialog.
- **Chars per note**: soft warning shown in `NoteEditorScreen` when body > 80% of limit; counter turns red when over limit.

## Key files

| File | Role |
|------|------|
| `lib/domain/entities/tier_limits.dart` | `TierLimits.free()`, `TierLimits.pro()`, `tierLimitsFromName()` |
| `lib/presentation/providers/tier_provider.dart` | `tierProvider` (fetches from Supabase), `aiSearchesTodayProvider` |
| `lib/data/remote/supabase/supabase_user_profile_datasource.dart` | `fetchTier(userId)` — reads `user_profiles` table |
| `lib/presentation/screens/home/settings_screen.dart` | Tier badge, usage bars, upgrade CTA |
| `supabase/functions/ai-search/index.ts` | Server-side quota: `TIER_LIMITS` constant at top of file |
