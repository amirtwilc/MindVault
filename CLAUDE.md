# MindVault — Claude Code Instructions

Flutter Android notes app with AI-powered search, end-to-end encryption, and offline support. Source lives in `mindvault/` (the Flutter project root).

**Stack:** Flutter (Android) · Supabase (Auth/Postgres/Realtime) · Gemini (semantic search) · Drift + FTS5 (local cache) · Riverpod · go_router · AES-256-GCM + PBKDF2.

---

## Critical Workflow — NO EXCEPTIONS

After **every** code change, before reporting the task complete:

1. **Run all tests** — `cd mindvault && flutter test`. All must pass.
2. **Build & copy the APK**:
   ```
   cd mindvault && flutter build apk --release --dart-define-from-file=dart-define.json
   cp mindvault/build/app/outputs/flutter-apk/app-release.apk mindvault-latest.apk
   ```
   `dart-define.json` is gitignored (copy from `dart-define.json.example`).

   **Signing:** the release keystore is `mindvault/android/app/mindvault-release.jks` (gitignored). `key.properties` references it as `storeFile=mindvault-release.jks`, which Gradle resolves relative to the `app/` module directory — correct as-is. Do not change this path.

   **Do not use `flutter run` for device testing.** It installs a debug-signed APK; installing a release APK afterwards will fail with a signing conflict, requiring a full uninstall. If `flutter run` was used and the user must switch back to a release build, they must uninstall the app first.

The user installs `mindvault-latest.apk` from the repo root on a real device. Skipping either step blocks them from testing.

**Tests:** every new feature must include tests in `mindvault/test/` (mirrors `lib/`). See `test/helpers/fake_secure_storage.dart` for the fake pattern.

---

## How to navigate this codebase

Use this file to identify which files you need, then `Read` them directly. Avoid broad Explore agents — they reproduce file trees and waste session budget. Targeted `Read` + `Grep` is almost always sufficient.

### Top-level layout

```
lib/
  core/{constants,theme,utils}
  data/
    local/database/  # Drift DB + FTS5 (app_database.dart)
    models/          # Drift table definitions
    remote/supabase/ # auth, notes, categories, user_keys datasources
    repositories/    # implementations of domain interfaces
  domain/{entities,repositories,usecases}
  presentation/
    providers/       # Riverpod
    router/          # go_router with auth + encryption guards
    screens/{auth,home,splash,widget}
    widgets/
  services/          # encryption, biometric, connectivity, sync, widget_data
```

**Generated files** (never edit): `*.g.dart`, `*.freezed.dart`. Regenerate via:
```
cd mindvault && dart run build_runner build --delete-conflicting-outputs
```

### Key files

| File | Purpose |
|------|---------|
| `supabase/schema.sql` | Full DB schema with RLS |
| `lib/core/constants/supabase_constants.dart` | URL + anonKey |
| `lib/services/encryption_service.dart` | AES-256-GCM + PBKDF2 |
| `lib/data/local/database/app_database.dart` | Drift DB + FTS5 |
| `lib/presentation/router/app_router.dart` | go_router guards; `HomeShell` lifecycle observer |

### Subsystem specs (read only when relevant)

These docs are loaded on demand — do not read them unless the task touches that subsystem.

| When you're touching... | Read |
|-------------------------|------|
| Repos, sync, pending ops, Realtime, offline behavior, or any new synced entity | `specs/sync-architecture.md` |
| Android home widget, `TransparentActivity`, widget XMLs, `widget_data_service.dart` | `specs/home-widget.md` |
| `ai_search_*`, `ai_constants.dart`, or the `ai-search` edge function | `specs/ai-search.md` |
| `tier_*`, settings screen tier UI, edge-function quota | `specs/tier-system.md` |

The `specs/` directory also contains feature specs (e.g. `pin-note-spec.md`, `search-section-spec.md`) — read these when working on the named feature.
