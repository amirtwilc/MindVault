# Supabase schema

This file is the walkthrough of [`supabase/schema.sql`](supabase/schema.sql).
The SQL file is the source of truth — run it once in the SQL editor of a
fresh Supabase project to bootstrap everything the Flutter app needs. The
script is idempotent (every `CREATE` uses `IF NOT EXISTS` and every policy
is dropped + re-created), so you can re-run it after edits.

> Tier limits live in code, **not** in the database. They are declared in
> `mindvault/lib/domain/entities/tier_limits.dart` (client) and the
> `TIER_LIMITS` map at the top of `supabase/functions/ai-search/index.ts`
> (server). Keep them in sync.

---

## How to apply

### Option A — Supabase dashboard

1. Open your project → SQL editor → **New query**.
2. Paste the contents of [`supabase/schema.sql`](supabase/schema.sql).
3. **Run**. You'll see a row count for each statement.

### Option B — Supabase CLI

```bash
cd supabase
supabase db push        # if you've linked the project
# or
supabase db execute --file schema.sql
```

### Realtime gotcha

The script ends with:

```sql
ALTER PUBLICATION supabase_realtime ADD TABLE notes;
ALTER PUBLICATION supabase_realtime ADD TABLE categories;
```

If a table is already in the publication, the statement errors and stops
the script. Either drop it from the publication first, or wrap the two
`ALTER PUBLICATION` lines in a `DO $$ BEGIN … EXCEPTION WHEN duplicate_object …`
block. (The current script keeps it explicit so first-time installs see
exactly what's happening.)

---

## What the script creates

### `profiles` — one row per auth user

```sql
CREATE TABLE profiles (
  id          UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  tier        TEXT NOT NULL DEFAULT 'free' CHECK (tier IN ('free', 'pro')),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

- `id` is the same UUID as `auth.users.id` — every other table foreign
  keys to `profiles(id)`, so deleting a user cascades cleanly.
- `tier` drives quota enforcement. Mirror values: `free`, `pro`.
- RLS: a user can only `SELECT` / `INSERT` their own row.

### `categories`

```sql
CREATE TABLE categories (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  name         TEXT NOT NULL,
  sort_order   INTEGER NOT NULL DEFAULT 0,
  color        TEXT,
  last_used_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (user_id, name)
);
```

- `UNIQUE (user_id, name)` prevents duplicate category names. The
  Flutter "General" failsafe relies on this — see
  `categories_provider.dart::_createGeneralCategory`.
- `color` is a hex string like `#FF5722` (nullable; UI falls back to
  blue-grey).
- RLS: full CRUD as long as `auth.uid() = user_id`.

### `notes`

```sql
CREATE TABLE notes (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  category_id  UUID NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
  title        TEXT NOT NULL,                 -- AES-256-GCM ciphertext (Base64)
  body         TEXT NOT NULL DEFAULT '',      -- AES-256-GCM ciphertext (Base64)
  is_private   BOOLEAN NOT NULL DEFAULT FALSE,
  last_used_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_notes_user_updated ON notes (user_id, updated_at DESC);
```

- `title` and `body` are **always** ciphertext on the server. The
  encryption key is held only on user devices.
- `updated_at` drives last-write-wins conflict resolution. The Flutter
  client sets it on every write; Supabase upserts use it.
- The composite index makes the "all notes for this user, newest
  first" query (the home screen) cheap.
- RLS: full CRUD where `auth.uid() = user_id`.
- Local-only state (`last_opened_at`) lives in Drift, never on the
  server — it's UX bookkeeping, not data.

### `user_keys` — wrapped AES note key

```sql
CREATE TABLE user_keys (
  user_id     UUID PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
  wrapped_key TEXT NOT NULL,
  salt        TEXT NOT NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

- `wrapped_key` = Base64( IV ‖ AES-GCM(wrappingKey, aesNoteKey) )
  where `wrappingKey = PBKDF2(pin, salt, 100000, 32)`.
- The PIN itself never leaves the device. Without it, this row is
  useless ciphertext.
- This table is what makes "reinstall + sign back in" recoverable: the
  client downloads `wrapped_key + salt`, prompts for the PIN, derives
  the wrapping key, and unwraps the AES note key locally.
- RLS: full CRUD where `auth.uid() = user_id`.

### `ai_usage` — daily AI search counts

```sql
CREATE TABLE ai_usage (
  user_id     UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  usage_date  DATE NOT NULL DEFAULT CURRENT_DATE,
  query_count INTEGER NOT NULL DEFAULT 0,
  PRIMARY KEY (user_id, usage_date)
);
```

- Read + incremented exclusively by the `ai-search` edge function. The
  composite primary key naturally rate-limits to one row per user per
  day; old rows can be pruned with a cron job if desired.
- RLS: full CRUD where `auth.uid() = user_id`. The edge function runs
  with the caller's JWT so RLS still applies.

### `error_logs` — client error reporting

```sql
CREATE TABLE error_logs (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      UUID REFERENCES profiles(id) ON DELETE CASCADE,
  occurred_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  source       TEXT,
  message      TEXT NOT NULL
);
CREATE INDEX idx_error_logs_user_time
  ON error_logs (user_id, occurred_at DESC);
```

- Written by `lib/services/error_log_service.dart` from `catch` blocks
  in services that talk to remote APIs (most importantly the AI search
  backend). Calls are fire-and-forget — if there is no network, no
  auth, or the insert itself errors, the failure is swallowed (there
  is no point logging the logger).
- `source` is a short tag identifying where the error came from
  (e.g. `ai_search`). `message` is the exception's `toString()`.
  No note titles, bodies, or query text are stored — only the error
  signature, so observability cannot leak user content.
- RLS: `INSERT` is allowed for the calling user. There is **no**
  `SELECT` policy, so the table is admin-only — read it via the
  Supabase dashboard with the service role.

### Auto-provision trigger

```sql
CREATE FUNCTION handle_new_user()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  INSERT INTO profiles (id) VALUES (NEW.id) ON CONFLICT DO NOTHING;
  INSERT INTO categories (user_id, name, sort_order)
    VALUES (NEW.id, 'General', 0)
    ON CONFLICT DO NOTHING;
  RETURN NEW;
END;
$$;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE handle_new_user();
```

- Runs as `SECURITY DEFINER` so it can `INSERT` into `profiles` /
  `categories` without falling foul of RLS during sign-up.
- `pin_setup_screen.dart::_ensureProfile()` re-inserts the profile
  row defensively for users who pre-date this trigger or whose insert
  somehow didn't land — a unique-violation (`23505`) is swallowed.

### Realtime publication

```sql
ALTER PUBLICATION supabase_realtime ADD TABLE notes;
ALTER PUBLICATION supabase_realtime ADD TABLE categories;
```

The Flutter client subscribes via `supabase_notes_datasource.dart` and
`supabase_categories_datasource.dart`, filtered by `user_id`. Every
INSERT/UPDATE/DELETE is mirrored into the local Drift cache.

---

## Edge function setup

`supabase/functions/ai-search/index.ts` is a Deno function deployed
separately:

```bash
npx supabase secrets set GEMINI_API_KEY=<your_key> \
  --project-ref <your_project_ref>
npx supabase functions deploy ai-search \
  --project-ref <your_project_ref>
```

The function reads `SUPABASE_URL` and `SUPABASE_ANON_KEY` automatically
from the runtime, plus the `GEMINI_API_KEY` secret. It re-uses the
caller's JWT so the `profiles` and `ai_usage` reads/writes are
RLS-checked.

---

## Manual maintenance

Upgrade a user to pro:

```sql
UPDATE profiles SET tier = 'pro'
WHERE id = (SELECT id FROM auth.users WHERE email = 'user@example.com');
```

Reset today's AI quota for a user (during testing):

```sql
DELETE FROM ai_usage WHERE user_id = '<uuid>' AND usage_date = CURRENT_DATE;
```

Wipe a user (cascades through every table thanks to the FK chain):

```sql
DELETE FROM auth.users WHERE id = '<uuid>';
```
