-- ============================================================
-- MindVault — Supabase schema
-- Run this script once in your Supabase project's SQL editor to
-- bootstrap the database. Idempotent: safe to re-run.
-- ============================================================

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- One-time vocabulary migration for existing installs. The new app uses
-- memories/clusters/sparks/plan_items table names, while compatibility views
-- later in this file keep older REST clients mostly functional during rollout.
DO $$ BEGIN
  IF to_regclass('public.clusters') IS NULL AND to_regclass('public.categories') IS NOT NULL THEN
    ALTER TABLE public.categories RENAME TO clusters;
  END IF;
  IF to_regclass('public.memories') IS NULL AND to_regclass('public.notes') IS NOT NULL THEN
    ALTER TABLE public.notes RENAME TO memories;
  END IF;
  IF to_regclass('public.memory_reminders') IS NULL AND to_regclass('public.note_reminders') IS NOT NULL THEN
    ALTER TABLE public.note_reminders RENAME TO memory_reminders;
  END IF;
  IF to_regclass('public.sparks') IS NULL AND to_regclass('public.jots') IS NOT NULL THEN
    ALTER TABLE public.jots RENAME TO sparks;
  END IF;
  IF to_regclass('public.plan_items') IS NULL AND to_regclass('public.checklist_items') IS NOT NULL THEN
    ALTER TABLE public.checklist_items RENAME TO plan_items;
  END IF;
  IF to_regclass('public.spark_ai_usage') IS NULL AND to_regclass('public.jot_ai_usage') IS NOT NULL THEN
    ALTER TABLE public.jot_ai_usage RENAME TO spark_ai_usage;
  END IF;
END $$;



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
  ai_searches_per_day INT  NOT NULL,
  jot_ai_organizes_per_day INT NOT NULL DEFAULT 1
);

ALTER TABLE tier_limits
  ADD COLUMN IF NOT EXISTS jot_ai_organizes_per_day INT NOT NULL DEFAULT 1;

ALTER TABLE tier_limits ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can read tier limits" ON tier_limits;
CREATE POLICY "Anyone can read tier limits" ON tier_limits
  FOR SELECT USING (true);

-- Seed default tiers. ON CONFLICT DO NOTHING so re-running the script
-- never overwrites manual adjustments made in the dashboard.
INSERT INTO tier_limits (tier, max_notes, max_categories, max_chars_per_note, ai_searches_per_day, jot_ai_organizes_per_day) VALUES
  ('free', 100,  10,  5000,  5, 1),
  ('pro',  1000, 50, 20000, 50, 5)
ON CONFLICT (tier) DO NOTHING;

UPDATE tier_limits
SET jot_ai_organizes_per_day = 1
WHERE tier = 'free' AND jot_ai_organizes_per_day IS NULL;

UPDATE tier_limits
SET jot_ai_organizes_per_day = 5
WHERE tier = 'pro' AND jot_ai_organizes_per_day = 1;

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

-- ── clusters ──────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS clusters (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  name         TEXT NOT NULL,
  sort_order   INTEGER NOT NULL DEFAULT 0,
  color        TEXT,
  last_used_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (user_id, name)
);

ALTER TABLE clusters ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT now();

ALTER TABLE clusters ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users manage own clusters" ON clusters;
CREATE POLICY "Users manage own clusters" ON clusters
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- ── memories ───────────────────────────────────────────────────
-- title and body are AES-256-GCM ciphertext (Base64). The server
-- stores only ciphertext; the AES key never leaves the device.
CREATE TABLE IF NOT EXISTS memories (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  category_id  UUID NOT NULL REFERENCES clusters(id) ON DELETE CASCADE,
  title        TEXT NOT NULL,
  body         TEXT NOT NULL DEFAULT '',
  is_private   BOOLEAN NOT NULL DEFAULT FALSE,
  last_used_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  note_type    TEXT NOT NULL DEFAULT 'record' CHECK (note_type IN ('record', 'plan', 'text', 'checklist')),
  is_pinned    BOOLEAN NOT NULL DEFAULT FALSE,
  pinned_at    TIMESTAMPTZ,
  pin_order    INTEGER
);

ALTER TABLE memories ADD COLUMN IF NOT EXISTS note_type TEXT NOT NULL DEFAULT 'record';

ALTER TABLE memories DROP CONSTRAINT IF EXISTS notes_note_type_check;
ALTER TABLE memories DROP CONSTRAINT IF EXISTS memories_note_type_check;
ALTER TABLE memories ADD CONSTRAINT memories_note_type_check
  CHECK (note_type IN ('record', 'plan', 'text', 'checklist'));

CREATE INDEX IF NOT EXISTS idx_memories_user_updated
  ON memories (user_id, updated_at DESC);

CREATE INDEX IF NOT EXISTS idx_memories_user_pin
  ON memories (user_id, is_pinned DESC, pin_order ASC NULLS LAST, updated_at DESC);

ALTER TABLE memories ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users manage own memories" ON memories;
CREATE POLICY "Users manage own memories" ON memories
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Note reminders are metadata used to schedule local device notifications.
-- Reminder title/body are not stored here; devices resolve note content locally
-- when scheduling and when opening a fired notification.
CREATE TABLE IF NOT EXISTS memory_reminders (
  note_id    UUID PRIMARY KEY REFERENCES memories(id) ON DELETE CASCADE,
  user_id    UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  remind_at  TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_memory_reminders_user_time
  ON memory_reminders (user_id, remind_at);

ALTER TABLE memory_reminders ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users manage own note reminders" ON memory_reminders;
CREATE POLICY "Users manage own note reminders" ON memory_reminders
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- ── sparks ────────────────────────────────────────────────────
-- Short unhandled thoughts. `text` and `ai_suggestion_json` are
-- AES-256-GCM ciphertext (Base64); the server stores only ciphertext.
CREATE TABLE IF NOT EXISTS sparks (
  id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id              UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  text                 TEXT NOT NULL,
  created_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
  handled_at           TIMESTAMPTZ,
  ai_processed_at      TIMESTAMPTZ,
  ai_suggestion_json   TEXT,
  ai_suggestion_run_id UUID,
  reminder_at          TIMESTAMPTZ
);

ALTER TABLE sparks
  ADD COLUMN IF NOT EXISTS handled_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS ai_processed_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS ai_suggestion_json TEXT,
  ADD COLUMN IF NOT EXISTS ai_suggestion_run_id UUID,
  ADD COLUMN IF NOT EXISTS reminder_at TIMESTAMPTZ;

CREATE INDEX IF NOT EXISTS idx_sparks_user_unhandled_created
  ON sparks (user_id, handled_at, created_at ASC);

CREATE INDEX IF NOT EXISTS idx_sparks_user_reminder
  ON sparks (user_id, reminder_at)
  WHERE reminder_at IS NOT NULL AND handled_at IS NULL;

ALTER TABLE sparks ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users manage own sparks" ON sparks;
CREATE POLICY "Users manage own sparks" ON sparks
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Checklist item text is AES-256-GCM ciphertext (Base64), matching memories.body.
CREATE TABLE IF NOT EXISTS plan_items (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  note_id      UUID NOT NULL REFERENCES memories(id) ON DELETE CASCADE,
  user_id      UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  text         TEXT NOT NULL,
  is_completed BOOLEAN NOT NULL DEFAULT FALSE,
  sort_order   INTEGER NOT NULL DEFAULT 0,
  completed_at TIMESTAMPTZ,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_plan_items_note_order
  ON plan_items (note_id, is_completed ASC, sort_order ASC, created_at ASC);

CREATE INDEX IF NOT EXISTS idx_plan_items_user_updated
  ON plan_items (user_id, updated_at DESC);

ALTER TABLE plan_items ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users manage own checklist items" ON plan_items;
CREATE POLICY "Users manage own checklist items" ON plan_items
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- ── user_keys ───────────────────────────────────────────────
-- Stores the wrapped AES note-encryption key per user, so users
-- can recover encrypted memories after reinstall by entering their PIN.
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

CREATE OR REPLACE FUNCTION public.consume_ai_search_usage(
  p_user_id UUID,
  p_usage_date DATE DEFAULT CURRENT_DATE
)
RETURNS TABLE (
  allowed BOOLEAN,
  query_count INTEGER,
  daily_limit INTEGER,
  tier TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_tier TEXT;
  v_limit INTEGER;
  v_count INTEGER;
  v_allowed BOOLEAN := false;
BEGIN
  SELECT p.tier, tl.ai_searches_per_day
    INTO v_tier, v_limit
  FROM profiles p
  LEFT JOIN tier_limits tl ON tl.tier = p.tier
  WHERE p.id = p_user_id;

  v_tier := COALESCE(v_tier, 'free');
  v_limit := COALESCE(v_limit, 5);

  IF v_limit <= 0 THEN
    RETURN QUERY SELECT false, 0, v_limit, v_tier;
    RETURN;
  END IF;

  INSERT INTO ai_usage (user_id, usage_date, query_count)
  VALUES (p_user_id, p_usage_date, 1)
  ON CONFLICT (user_id, usage_date) DO UPDATE
    SET query_count = ai_usage.query_count + 1
    WHERE ai_usage.query_count < v_limit
  RETURNING ai_usage.query_count INTO v_count;

  IF FOUND THEN
    v_allowed := true;
  ELSE
    SELECT au.query_count INTO v_count
    FROM ai_usage au
    WHERE au.user_id = p_user_id AND au.usage_date = p_usage_date;
  END IF;

  RETURN QUERY SELECT v_allowed, COALESCE(v_count, 0), v_limit, v_tier;
END;
$$;

CREATE OR REPLACE FUNCTION public.refund_ai_search_usage(
  p_user_id UUID,
  p_usage_date DATE DEFAULT CURRENT_DATE
)
RETURNS VOID
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  UPDATE ai_usage
  SET query_count = GREATEST(query_count - 1, 0)
  WHERE user_id = p_user_id
    AND usage_date = p_usage_date
    AND query_count > 0;
$$;

REVOKE ALL ON FUNCTION public.consume_ai_search_usage(UUID, DATE) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.refund_ai_search_usage(UUID, DATE) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.consume_ai_search_usage(UUID, DATE) TO service_role;
GRANT EXECUTE ON FUNCTION public.refund_ai_search_usage(UUID, DATE) TO service_role;

-- ── spark_ai_usage ────────────────────────────────────────────
-- One row per user per day. Consumed atomically by the organize-sparks edge
-- function and refunded if the upstream model request fails.
CREATE TABLE IF NOT EXISTS spark_ai_usage (
  user_id        UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  usage_date     DATE NOT NULL DEFAULT CURRENT_DATE,
  organize_count INTEGER NOT NULL DEFAULT 0,
  PRIMARY KEY (user_id, usage_date)
);

ALTER TABLE spark_ai_usage ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users manage own spark_ai_usage" ON spark_ai_usage;
DROP POLICY IF EXISTS "Users read own spark_ai_usage" ON spark_ai_usage;
CREATE POLICY "Users read own spark_ai_usage" ON spark_ai_usage
  FOR SELECT USING (auth.uid() = user_id);

CREATE OR REPLACE FUNCTION public.consume_spark_ai_usage(
  p_user_id UUID,
  p_usage_date DATE DEFAULT CURRENT_DATE
)
RETURNS TABLE (
  allowed BOOLEAN,
  organize_count INTEGER,
  daily_limit INTEGER,
  tier TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_tier TEXT;
  v_limit INTEGER;
  v_count INTEGER;
  v_allowed BOOLEAN := false;
BEGIN
  SELECT p.tier, tl.jot_ai_organizes_per_day
    INTO v_tier, v_limit
  FROM profiles p
  LEFT JOIN tier_limits tl ON tl.tier = p.tier
  WHERE p.id = p_user_id;

  v_tier := COALESCE(v_tier, 'free');
  v_limit := COALESCE(v_limit, 1);

  IF v_limit <= 0 THEN
    RETURN QUERY SELECT false, 0, v_limit, v_tier;
    RETURN;
  END IF;

  INSERT INTO spark_ai_usage (user_id, usage_date, organize_count)
  VALUES (p_user_id, p_usage_date, 1)
  ON CONFLICT (user_id, usage_date) DO UPDATE
    SET organize_count = spark_ai_usage.organize_count + 1
    WHERE spark_ai_usage.organize_count < v_limit
  RETURNING spark_ai_usage.organize_count INTO v_count;

  IF FOUND THEN
    v_allowed := true;
  ELSE
    SELECT jau.organize_count INTO v_count
    FROM spark_ai_usage jau
    WHERE jau.user_id = p_user_id AND jau.usage_date = p_usage_date;
  END IF;

  RETURN QUERY SELECT v_allowed, COALESCE(v_count, 0), v_limit, v_tier;
END;
$$;

CREATE OR REPLACE FUNCTION public.refund_spark_ai_usage(
  p_user_id UUID,
  p_usage_date DATE DEFAULT CURRENT_DATE
)
RETURNS VOID
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  UPDATE spark_ai_usage
  SET organize_count = GREATEST(organize_count - 1, 0)
  WHERE user_id = p_user_id
    AND usage_date = p_usage_date
    AND organize_count > 0;
$$;

-- Compatibility wrappers for the currently deployed organize-jots edge
-- function and any old clients during the rename rollout.
CREATE OR REPLACE FUNCTION public.consume_jot_ai_usage(
  p_user_id UUID,
  p_usage_date DATE DEFAULT CURRENT_DATE
)
RETURNS TABLE (
  allowed BOOLEAN,
  organize_count INTEGER,
  daily_limit INTEGER,
  tier TEXT
)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT * FROM public.consume_spark_ai_usage(p_user_id, p_usage_date);
$$;

CREATE OR REPLACE FUNCTION public.refund_jot_ai_usage(
  p_user_id UUID,
  p_usage_date DATE DEFAULT CURRENT_DATE
)
RETURNS VOID
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT public.refund_spark_ai_usage(p_user_id, p_usage_date);
$$;

REVOKE ALL ON FUNCTION public.consume_spark_ai_usage(UUID, DATE) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.refund_spark_ai_usage(UUID, DATE) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.consume_jot_ai_usage(UUID, DATE) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.refund_jot_ai_usage(UUID, DATE) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.consume_spark_ai_usage(UUID, DATE) TO service_role;
GRANT EXECUTE ON FUNCTION public.refund_spark_ai_usage(UUID, DATE) TO service_role;
GRANT EXECUTE ON FUNCTION public.consume_jot_ai_usage(UUID, DATE) TO service_role;
GRANT EXECUTE ON FUNCTION public.refund_jot_ai_usage(UUID, DATE) TO service_role;

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
-- Tracks structural events only (session_started, memory_created, etc.) —
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
  (SELECT COUNT(*) FROM spark_ai_usage WHERE usage_date = CURRENT_DATE)                                    AS jot_ai_users_today,
  (SELECT COALESCE(SUM(organize_count), 0) FROM spark_ai_usage WHERE usage_date = CURRENT_DATE)            AS jot_ai_organizes_today,
  (SELECT COUNT(DISTINCT user_id) FROM analytics_events WHERE created_at::date = CURRENT_DATE)           AS dau_today,
  (SELECT COUNT(*) FROM analytics_events WHERE event_type = 'memory_created' AND created_at::date = CURRENT_DATE) AS memories_created_today,
  (SELECT COUNT(*) FROM analytics_events WHERE event_type = 'memory_created' AND created_at >= NOW() - INTERVAL '7 days') AS memories_created_7d,
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
  INSERT INTO public.clusters (user_id, name, sort_order)
    VALUES (NEW.id, 'General', 0)
    ON CONFLICT DO NOTHING;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE handle_new_user();

-- Backfill profiles for users that existed before this trigger/schema version
-- was installed. Without this, FK checks on clusters/memories can reject
-- app writes for existing users while local offline writes still appear to work.
INSERT INTO public.profiles (id)
SELECT id FROM auth.users
ON CONFLICT (id) DO NOTHING;

-- ── Conflict-safe synced writes ──────────────────────────────
-- Client clocks already drive the local-first conflict model. These RPCs make
-- the server enforce the same last-write-wins rule atomically so delayed older
-- writes cannot overwrite newer rows.

CREATE OR REPLACE FUNCTION public.upsert_cluster_lww(
  p_id UUID,
  p_name TEXT,
  p_sort_order INTEGER,
  p_color TEXT,
  p_last_used_at TIMESTAMPTZ,
  p_created_at TIMESTAMPTZ,
  p_updated_at TIMESTAMPTZ
)
RETURNS SETOF public.clusters
LANGUAGE sql
SECURITY INVOKER
SET search_path = public
AS $$
  INSERT INTO public.clusters (
    id, user_id, name, sort_order, color, last_used_at, created_at, updated_at
  )
  VALUES (
    p_id, auth.uid(), p_name, p_sort_order, p_color, p_last_used_at, p_created_at, p_updated_at
  )
  ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    sort_order = EXCLUDED.sort_order,
    color = EXCLUDED.color,
    last_used_at = EXCLUDED.last_used_at,
    created_at = EXCLUDED.created_at,
    updated_at = EXCLUDED.updated_at
  WHERE clusters.user_id = auth.uid()
    AND clusters.updated_at <= EXCLUDED.updated_at
  RETURNING *;
$$;

CREATE OR REPLACE FUNCTION public.upsert_memory_lww(
  p_id UUID,
  p_category_id UUID,
  p_title TEXT,
  p_body TEXT,
  p_is_private BOOLEAN,
  p_last_used_at TIMESTAMPTZ,
  p_created_at TIMESTAMPTZ,
  p_updated_at TIMESTAMPTZ,
  p_note_type TEXT,
  p_is_pinned BOOLEAN,
  p_pinned_at TIMESTAMPTZ,
  p_pin_order INTEGER
)
RETURNS SETOF public.memories
LANGUAGE sql
SECURITY INVOKER
SET search_path = public
AS $$
  INSERT INTO public.memories (
    id, user_id, category_id, title, body, is_private, last_used_at, created_at,
    updated_at, note_type, is_pinned, pinned_at, pin_order
  )
  VALUES (
    p_id, auth.uid(), p_category_id, p_title, p_body, p_is_private,
    p_last_used_at, p_created_at, p_updated_at, p_note_type, p_is_pinned,
    p_pinned_at, p_pin_order
  )
  ON CONFLICT (id) DO UPDATE SET
    category_id = EXCLUDED.category_id,
    title = EXCLUDED.title,
    body = EXCLUDED.body,
    is_private = EXCLUDED.is_private,
    last_used_at = EXCLUDED.last_used_at,
    created_at = EXCLUDED.created_at,
    updated_at = EXCLUDED.updated_at,
    note_type = EXCLUDED.note_type,
    is_pinned = EXCLUDED.is_pinned,
    pinned_at = EXCLUDED.pinned_at,
    pin_order = EXCLUDED.pin_order
  WHERE memories.user_id = auth.uid()
    AND memories.updated_at <= EXCLUDED.updated_at
  RETURNING *;
$$;

CREATE OR REPLACE FUNCTION public.upsert_spark_lww(
  p_id UUID,
  p_text TEXT,
  p_created_at TIMESTAMPTZ,
  p_updated_at TIMESTAMPTZ,
  p_handled_at TIMESTAMPTZ,
  p_ai_processed_at TIMESTAMPTZ,
  p_ai_suggestion_json TEXT,
  p_ai_suggestion_run_id UUID,
  p_reminder_at TIMESTAMPTZ
)
RETURNS SETOF public.sparks
LANGUAGE sql
SECURITY INVOKER
SET search_path = public
AS $$
  INSERT INTO public.sparks (
    id, user_id, text, created_at, updated_at, handled_at, ai_processed_at,
    ai_suggestion_json, ai_suggestion_run_id, reminder_at
  )
  VALUES (
    p_id, auth.uid(), p_text, p_created_at, p_updated_at, p_handled_at,
    p_ai_processed_at, p_ai_suggestion_json, p_ai_suggestion_run_id,
    p_reminder_at
  )
  ON CONFLICT (id) DO UPDATE SET
    text = EXCLUDED.text,
    created_at = EXCLUDED.created_at,
    updated_at = EXCLUDED.updated_at,
    handled_at = EXCLUDED.handled_at,
    ai_processed_at = EXCLUDED.ai_processed_at,
    ai_suggestion_json = EXCLUDED.ai_suggestion_json,
    ai_suggestion_run_id = EXCLUDED.ai_suggestion_run_id,
    reminder_at = EXCLUDED.reminder_at
  WHERE sparks.user_id = auth.uid()
    AND sparks.updated_at <= EXCLUDED.updated_at
  RETURNING *;
$$;

CREATE OR REPLACE FUNCTION public.upsert_plan_item_lww(
  p_id UUID,
  p_note_id UUID,
  p_text TEXT,
  p_is_completed BOOLEAN,
  p_sort_order INTEGER,
  p_completed_at TIMESTAMPTZ,
  p_created_at TIMESTAMPTZ,
  p_updated_at TIMESTAMPTZ
)
RETURNS SETOF public.plan_items
LANGUAGE sql
SECURITY INVOKER
SET search_path = public
AS $$
  INSERT INTO public.plan_items (
    id, note_id, user_id, text, is_completed, sort_order, completed_at,
    created_at, updated_at
  )
  VALUES (
    p_id, p_note_id, auth.uid(), p_text, p_is_completed, p_sort_order,
    p_completed_at, p_created_at, p_updated_at
  )
  ON CONFLICT (id) DO UPDATE SET
    note_id = EXCLUDED.note_id,
    text = EXCLUDED.text,
    is_completed = EXCLUDED.is_completed,
    sort_order = EXCLUDED.sort_order,
    completed_at = EXCLUDED.completed_at,
    created_at = EXCLUDED.created_at,
    updated_at = EXCLUDED.updated_at
  WHERE plan_items.user_id = auth.uid()
    AND plan_items.updated_at <= EXCLUDED.updated_at
  RETURNING *;
$$;

CREATE OR REPLACE FUNCTION public.upsert_memory_reminder_lww(
  p_note_id UUID,
  p_remind_at TIMESTAMPTZ,
  p_created_at TIMESTAMPTZ,
  p_updated_at TIMESTAMPTZ,
  p_deleted_at TIMESTAMPTZ
)
RETURNS SETOF public.memory_reminders
LANGUAGE sql
SECURITY INVOKER
SET search_path = public
AS $$
  INSERT INTO public.memory_reminders (
    note_id, user_id, remind_at, created_at, updated_at, deleted_at
  )
  VALUES (
    p_note_id, auth.uid(), p_remind_at, p_created_at, p_updated_at, p_deleted_at
  )
  ON CONFLICT (note_id) DO UPDATE SET
    remind_at = EXCLUDED.remind_at,
    created_at = EXCLUDED.created_at,
    updated_at = EXCLUDED.updated_at,
    deleted_at = EXCLUDED.deleted_at
  WHERE memory_reminders.user_id = auth.uid()
    AND memory_reminders.updated_at <= EXCLUDED.updated_at
  RETURNING *;
$$;

CREATE OR REPLACE FUNCTION public.wipe_user_content_for_fresh_start()
RETURNS VOID
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID := auth.uid();
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'wipe_user_content_for_fresh_start requires auth';
  END IF;

  DELETE FROM public.plan_items WHERE user_id = v_user_id;
  DELETE FROM public.memory_reminders WHERE user_id = v_user_id;
  DELETE FROM public.memories WHERE user_id = v_user_id;
  DELETE FROM public.sparks WHERE user_id = v_user_id;
  DELETE FROM public.clusters WHERE user_id = v_user_id;
  DELETE FROM public.ai_usage WHERE user_id = v_user_id;
  DELETE FROM public.spark_ai_usage WHERE user_id = v_user_id;
  DELETE FROM public.user_keys WHERE user_id = v_user_id;

  INSERT INTO public.clusters (user_id, name, sort_order, last_used_at, created_at, updated_at)
  VALUES (v_user_id, 'General', 0, now(), now(), now())
  ON CONFLICT DO NOTHING;
END;
$$;

REVOKE ALL ON FUNCTION public.upsert_cluster_lww(UUID, TEXT, INTEGER, TEXT, TIMESTAMPTZ, TIMESTAMPTZ, TIMESTAMPTZ) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.upsert_memory_lww(UUID, UUID, TEXT, TEXT, BOOLEAN, TIMESTAMPTZ, TIMESTAMPTZ, TIMESTAMPTZ, TEXT, BOOLEAN, TIMESTAMPTZ, INTEGER) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.upsert_spark_lww(UUID, TEXT, TIMESTAMPTZ, TIMESTAMPTZ, TIMESTAMPTZ, TIMESTAMPTZ, TEXT, UUID, TIMESTAMPTZ) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.upsert_plan_item_lww(UUID, UUID, TEXT, BOOLEAN, INTEGER, TIMESTAMPTZ, TIMESTAMPTZ, TIMESTAMPTZ) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.upsert_memory_reminder_lww(UUID, TIMESTAMPTZ, TIMESTAMPTZ, TIMESTAMPTZ, TIMESTAMPTZ) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.wipe_user_content_for_fresh_start() FROM PUBLIC;

GRANT EXECUTE ON FUNCTION public.upsert_cluster_lww(UUID, TEXT, INTEGER, TEXT, TIMESTAMPTZ, TIMESTAMPTZ, TIMESTAMPTZ) TO authenticated;
GRANT EXECUTE ON FUNCTION public.upsert_memory_lww(UUID, UUID, TEXT, TEXT, BOOLEAN, TIMESTAMPTZ, TIMESTAMPTZ, TIMESTAMPTZ, TEXT, BOOLEAN, TIMESTAMPTZ, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION public.upsert_spark_lww(UUID, TEXT, TIMESTAMPTZ, TIMESTAMPTZ, TIMESTAMPTZ, TIMESTAMPTZ, TEXT, UUID, TIMESTAMPTZ) TO authenticated;
GRANT EXECUTE ON FUNCTION public.upsert_plan_item_lww(UUID, UUID, TEXT, BOOLEAN, INTEGER, TIMESTAMPTZ, TIMESTAMPTZ, TIMESTAMPTZ) TO authenticated;
GRANT EXECUTE ON FUNCTION public.upsert_memory_reminder_lww(UUID, TIMESTAMPTZ, TIMESTAMPTZ, TIMESTAMPTZ, TIMESTAMPTZ) TO authenticated;
GRANT EXECUTE ON FUNCTION public.wipe_user_content_for_fresh_start() TO authenticated;

-- ── Realtime ────────────────────────────────────────────────
-- The Flutter app subscribes to memories + clusters changes to
-- keep multiple devices in sync.
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'memories'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE memories;
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'clusters'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE clusters;
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'plan_items'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE plan_items;
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'memory_reminders'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE memory_reminders;
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'sparks'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE sparks;
  END IF;
END $$;
-- Temporary REST compatibility for old app versions. Realtime subscriptions
-- should move to the new tables; these views mainly protect short rollout gaps.
CREATE OR REPLACE VIEW categories WITH (security_invoker = true) AS
  SELECT * FROM clusters;
CREATE OR REPLACE VIEW notes WITH (security_invoker = true) AS
  SELECT * FROM memories;
CREATE OR REPLACE VIEW note_reminders WITH (security_invoker = true) AS
  SELECT * FROM memory_reminders;
CREATE OR REPLACE VIEW jots WITH (security_invoker = true) AS
  SELECT * FROM sparks;
CREATE OR REPLACE VIEW checklist_items WITH (security_invoker = true) AS
  SELECT * FROM plan_items;
CREATE OR REPLACE VIEW jot_ai_usage WITH (security_invoker = true) AS
  SELECT * FROM spark_ai_usage;

-- Ask PostgREST/Supabase API to reload relation metadata after renames/views.
NOTIFY pgrst, 'reload schema';
