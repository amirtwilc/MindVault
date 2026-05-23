-- ============================================================
-- MindVault — Supabase schema
-- Run this script once in your Supabase project's SQL editor to
-- bootstrap the database. Idempotent: safe to re-run.
-- ============================================================

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ── tier_limits ─────────────────────────────────────────────
-- Single source of truth for per-tier quota values.
-- The Flutter client and the ai-search edge function both read
-- from this table so there is no duplication. Add a new row to
-- introduce a new tier; update an existing row to change limits.
CREATE TABLE IF NOT EXISTS tier_limits (
  tier                TEXT PRIMARY KEY,
  max_notes           INT  NOT NULL,
  max_categories      INT  NOT NULL,
  max_chars_per_note  INT  NOT NULL,
  ai_searches_per_day INT  NOT NULL
);

ALTER TABLE tier_limits ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can read tier limits" ON tier_limits;
CREATE POLICY "Anyone can read tier limits" ON tier_limits
  FOR SELECT USING (true);

-- Seed default tiers. ON CONFLICT DO NOTHING so re-running the script
-- never overwrites manual adjustments made in the dashboard.
INSERT INTO tier_limits (tier, max_notes, max_categories, max_chars_per_note, ai_searches_per_day) VALUES
  ('free', 100,  10,  5000,  5),
  ('pro',  1000, 50, 20000, 50)
ON CONFLICT (tier) DO NOTHING;

-- ── profiles ────────────────────────────────────────────────
-- One row per auth user. `tier` references tier_limits.tier.
CREATE TABLE IF NOT EXISTS profiles (
  id          UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  tier        TEXT NOT NULL DEFAULT 'free' REFERENCES tier_limits(tier),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Idempotent upgrade: add FK on existing installs that predate this constraint.
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE constraint_name = 'profiles_tier_fkey'
      AND table_name = 'profiles'
  ) THEN
    ALTER TABLE profiles ADD CONSTRAINT profiles_tier_fkey
      FOREIGN KEY (tier) REFERENCES tier_limits(tier);
  END IF;
END $$;

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users read own profile" ON profiles;
CREATE POLICY "Users read own profile" ON profiles
  FOR SELECT USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users insert own profile" ON profiles;
CREATE POLICY "Users insert own profile" ON profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

-- ── categories ──────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS categories (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  name         TEXT NOT NULL,
  sort_order   INTEGER NOT NULL DEFAULT 0,
  color        TEXT,
  last_used_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (user_id, name)
);

ALTER TABLE categories ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users manage own categories" ON categories;
CREATE POLICY "Users manage own categories" ON categories
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- ── notes ───────────────────────────────────────────────────
-- title and body are AES-256-GCM ciphertext (Base64). The server
-- stores only ciphertext; the AES key never leaves the device.
CREATE TABLE IF NOT EXISTS notes (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  category_id  UUID NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
  title        TEXT NOT NULL,
  body         TEXT NOT NULL DEFAULT '',
  is_private   BOOLEAN NOT NULL DEFAULT FALSE,
  last_used_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  note_type    TEXT NOT NULL DEFAULT 'text' CHECK (note_type IN ('text', 'checklist')),
  is_pinned    BOOLEAN NOT NULL DEFAULT FALSE,
  pinned_at    TIMESTAMPTZ,
  pin_order    INTEGER
);

ALTER TABLE notes ADD COLUMN IF NOT EXISTS note_type TEXT NOT NULL DEFAULT 'text';

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE table_name = 'notes' AND constraint_name = 'notes_note_type_check'
  ) THEN
    ALTER TABLE notes ADD CONSTRAINT notes_note_type_check
      CHECK (note_type IN ('text', 'checklist'));
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_notes_user_updated
  ON notes (user_id, updated_at DESC);

CREATE INDEX IF NOT EXISTS idx_notes_user_pin
  ON notes (user_id, is_pinned DESC, pin_order ASC NULLS LAST, updated_at DESC);

ALTER TABLE notes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users manage own notes" ON notes;
CREATE POLICY "Users manage own notes" ON notes
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Note reminders are metadata used to schedule local device notifications.
-- Reminder title/body are not stored here; devices resolve note content locally
-- when scheduling and when opening a fired notification.
CREATE TABLE IF NOT EXISTS note_reminders (
  note_id    UUID PRIMARY KEY REFERENCES notes(id) ON DELETE CASCADE,
  user_id    UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  remind_at  TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_note_reminders_user_time
  ON note_reminders (user_id, remind_at);

ALTER TABLE note_reminders ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users manage own note reminders" ON note_reminders;
CREATE POLICY "Users manage own note reminders" ON note_reminders
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Checklist item text is AES-256-GCM ciphertext (Base64), matching notes.body.
CREATE TABLE IF NOT EXISTS checklist_items (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  note_id      UUID NOT NULL REFERENCES notes(id) ON DELETE CASCADE,
  user_id      UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  text         TEXT NOT NULL,
  is_completed BOOLEAN NOT NULL DEFAULT FALSE,
  sort_order   INTEGER NOT NULL DEFAULT 0,
  completed_at TIMESTAMPTZ,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_checklist_items_note_order
  ON checklist_items (note_id, is_completed ASC, sort_order ASC, created_at ASC);

CREATE INDEX IF NOT EXISTS idx_checklist_items_user_updated
  ON checklist_items (user_id, updated_at DESC);

ALTER TABLE checklist_items ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users manage own checklist items" ON checklist_items;
CREATE POLICY "Users manage own checklist items" ON checklist_items
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- ── user_keys ───────────────────────────────────────────────
-- Stores the wrapped AES note-encryption key per user, so users
-- can recover encrypted notes after reinstall by entering their PIN.
-- The PIN itself never leaves the device.
CREATE TABLE IF NOT EXISTS user_keys (
  user_id     UUID PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
  wrapped_key TEXT NOT NULL,
  salt        TEXT NOT NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE user_keys ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users manage own keys" ON user_keys;
CREATE POLICY "Users manage own keys" ON user_keys
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- ── ai_usage ────────────────────────────────────────────────
-- One row per user per day. Written exclusively by the ai-search edge
-- function via upsert on (user_id, usage_date). The composite primary
-- key acts as the unique constraint for the upsert's ON CONFLICT clause.
--
-- Migration guard: if the old schema (tokens_used / queried_at columns)
-- exists from a previous run, drop it so the correct schema can be created.
DO $$ BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'ai_usage' AND column_name = 'tokens_used'
  ) THEN
    DROP TABLE IF EXISTS ai_usage CASCADE;
  END IF;
END $$;

CREATE TABLE IF NOT EXISTS ai_usage (
  user_id     UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  usage_date  DATE NOT NULL DEFAULT CURRENT_DATE,
  query_count INTEGER NOT NULL DEFAULT 0,
  PRIMARY KEY (user_id, usage_date)
);

ALTER TABLE ai_usage ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users manage own ai_usage" ON ai_usage;
CREATE POLICY "Users manage own ai_usage" ON ai_usage
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- ── error_logs ──────────────────────────────────────────────
-- Best-effort client-side error reporting. The app fires writes
-- here from a fire-and-forget logger when something throws (most
-- importantly the AI search backend call). Failures to write are
-- swallowed by the client — there is no point logging the logger.
-- Stored fields are intentionally minimal so nothing user-private
-- (note titles, bodies, queries) leaks into observability.
CREATE TABLE IF NOT EXISTS error_logs (
  id           UUID  PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      UUID  REFERENCES profiles(id) ON DELETE CASCADE,
  occurred_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  source       TEXT,
  message      TEXT  NOT NULL,
  context      JSONB   -- structured metadata (e.g. http_status); never user-private content
);
-- Idempotent upgrade: adds context to existing installs that predate this column
-- (the CREATE TABLE above handles fresh installs; IF NOT EXISTS makes it a no-op there).
ALTER TABLE error_logs ADD COLUMN IF NOT EXISTS context JSONB;

CREATE INDEX IF NOT EXISTS idx_error_logs_user_time
  ON error_logs (user_id, occurred_at DESC);

ALTER TABLE error_logs ENABLE ROW LEVEL SECURITY;

-- Users may only insert rows for themselves; reads are admin-only
-- (no SELECT policy, so RLS denies them by default).
DROP POLICY IF EXISTS "Users insert own error logs" ON error_logs;
CREATE POLICY "Users insert own error logs" ON error_logs
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- ── analytics_events ────────────────────────────────────────
-- Fire-and-forget behavioural event log written by the Flutter app.
-- Tracks structural events only (session_started, note_created, etc.) —
-- never note content (which is E2EE client-side anyway).
-- RLS: authenticated users may INSERT their own events; no SELECT policy
-- so regular users cannot read any rows. Service role (Supabase Studio)
-- reads all rows for aggregation queries.
CREATE TABLE IF NOT EXISTS analytics_events (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  event_type  TEXT        NOT NULL,
  metadata    JSONB,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_analytics_events_type_time
  ON analytics_events (event_type, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_analytics_events_user_time
  ON analytics_events (user_id, created_at DESC);

ALTER TABLE analytics_events ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users insert own analytics events" ON analytics_events;
CREATE POLICY "Users insert own analytics events" ON analytics_events
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- ── Analytics views (query from Supabase Studio with service role) ──
-- Run: SELECT * FROM v_analytics_summary;

CREATE OR REPLACE VIEW v_analytics_summary AS
SELECT
  (SELECT COUNT(*) FROM profiles)                                                                         AS total_users,
  (SELECT COUNT(*) FROM profiles WHERE tier = 'pro')                                                     AS pro_users,
  (SELECT COUNT(*) FROM profiles WHERE created_at::date = CURRENT_DATE)                                  AS signups_today,
  (SELECT COUNT(*) FROM profiles WHERE created_at >= NOW() - INTERVAL '7 days')                          AS signups_7d,
  (SELECT COUNT(*) FROM profiles WHERE created_at >= NOW() - INTERVAL '30 days')                         AS signups_30d,
  (SELECT COUNT(*) FROM ai_usage WHERE usage_date = CURRENT_DATE)                                        AS ai_queries_today,
  (SELECT COUNT(*) FROM ai_usage WHERE usage_date >= CURRENT_DATE - INTERVAL '7 days')                  AS ai_queries_7d,
  (SELECT COUNT(DISTINCT user_id) FROM analytics_events WHERE created_at::date = CURRENT_DATE)           AS dau_today,
  (SELECT COUNT(*) FROM analytics_events WHERE event_type = 'note_created' AND created_at::date = CURRENT_DATE) AS notes_created_today,
  (SELECT COUNT(*) FROM analytics_events WHERE event_type = 'note_created' AND created_at >= NOW() - INTERVAL '7 days') AS notes_created_7d,
  (SELECT COUNT(*) FROM error_logs WHERE occurred_at::date = CURRENT_DATE)                               AS errors_today;

-- Signups per day (last 30 days), broken down by tier
CREATE OR REPLACE VIEW v_analytics_signups_daily AS
  SELECT created_at::date AS date, tier, COUNT(*) AS new_users
  FROM profiles
  WHERE created_at >= NOW() - INTERVAL '30 days'
  GROUP BY date, tier
  ORDER BY date DESC;

-- AI query volume per day (last 30 days)
CREATE OR REPLACE VIEW v_analytics_ai_daily AS
  SELECT usage_date, COUNT(*) AS total_queries, COUNT(DISTINCT user_id) AS active_ai_users
  FROM ai_usage
  WHERE usage_date >= CURRENT_DATE - INTERVAL '30 days'
  GROUP BY usage_date
  ORDER BY usage_date DESC;

-- Daily active users (last 30 days)
CREATE OR REPLACE VIEW v_analytics_dau AS
  SELECT created_at::date AS date, COUNT(DISTINCT user_id) AS dau
  FROM analytics_events
  WHERE created_at >= NOW() - INTERVAL '30 days'
  GROUP BY date
  ORDER BY date DESC;

-- Event breakdown per day (last 30 days)
CREATE OR REPLACE VIEW v_analytics_events_daily AS
  SELECT created_at::date AS date, event_type, COUNT(*) AS count
  FROM analytics_events
  WHERE created_at >= NOW() - INTERVAL '30 days'
  GROUP BY date, event_type
  ORDER BY date DESC, event_type;

-- ── Auto-provision profile + default category on signup ─────
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id) VALUES (NEW.id)
    ON CONFLICT (id) DO NOTHING;
  INSERT INTO public.categories (user_id, name, sort_order)
    VALUES (NEW.id, 'General', 0)
    ON CONFLICT DO NOTHING;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE handle_new_user();

-- ── Realtime ────────────────────────────────────────────────
-- The Flutter app subscribes to notes + categories changes to
-- keep multiple devices in sync.
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'notes'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE notes;
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'categories'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE categories;
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'checklist_items'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE checklist_items;
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'note_reminders'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE note_reminders;
  END IF;
END $$;
