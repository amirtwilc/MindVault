# MindVault

MindVault is a privacy-first Android app for capturing, organizing, and recalling the pieces of thought that usually get lost between note apps, reminders, and memory.

It started as a notes app, but the product direction evolved into something more personal: an extension of the user's mind. The core object is no longer "a note" as a static document. It is a **Memory**: a thought, plan, fact, list, reminder, or reference that should be easy to store now and easy to retrieve later.

Built with Flutter, Supabase, Drift, Riverpod, Android widgets, AES-256-GCM encryption, and Gemini-powered AI features.

---

## Product Thinking

Most personal knowledge tools expect users to stop, classify, title, and structure an idea before saving it. That is often the exact moment the idea disappears.

MindVault is designed around a different flow:

1. Capture thoughts with as little friction as possible.
2. Keep them available offline and private by default.
3. Let users organize when they have time.
4. Use AI only where it meaningfully reduces cognitive load.
5. Make recall feel closer to asking your own memory than searching a database.

This shaped both the user-facing language and the architecture:

- **Archive** is the user's long-term memory library.
- **Memories** are saved thoughts, references, records, and plans.
- **Clusters** group related memories without making the app feel like a file cabinet.
- **Recall** combines fast local search with AI-assisted semantic answers.
- **Sparks** hold quick thoughts that are not ready to become full memories yet.

---

## Highlights

- **Local-first by design**
  Every change is written to the local Drift database first. The UI stays instant, the app works offline, and sync catches up later.

- **End-to-end encrypted storage**
  Memory content is encrypted on-device with AES-256-GCM. Supabase stores ciphertext, and the key material needed to decrypt content never leaves the device.

- **Resilient cross-device sync**
  Supabase Auth, Postgres, Realtime, and an outbox-based sync engine keep devices eventually consistent while preserving offline edits.

- **AI Recall with bounded context**
  AI search does not receive the whole database. MindVault ranks relevant local memories first, sends only a filtered subset through a Supabase Edge Function, enforces quotas, and returns grounded answers with sources.

- **Sparks for low-friction capture**
  Sparks are quick thoughts saved without forcing the user to choose a cluster, title, or final destination. Later, the user can turn them into a memory, append them to an existing memory, set a reminder, delete them, or ask AI to suggest the best action.

- **Records, Plans, and Reminders**
  Memories can be plain text **Records** or checklist-based **Plans**. Reminders can be attached to memories or sparks and are scheduled locally on Android while remaining synced as user intent.

- **Home-screen widgets**
  The app exposes fast capture, browse, and search flows from Android widgets using a restricted projection of local data.

---

## Core Experience

### Archive

Archive is the long-term library: the place where durable memories live. A memory can be a recipe, a personal detail, a project idea, a task list, or anything the user does not want to rely on biological memory to keep.

Memories support:

- optional titles
- clusters
- pinning and ordering
- private/locked content
- text records
- checklist plans
- reminders

### Sparks

Sparks are for the moment before organization.

A spark might be:

- "Watch that movie Daniel mentioned"
- "Jack likes strawberries"
- "Ask dentist about night guard"
- "Potential project: encrypted family archive"

The point is not to make the user decide where the thought belongs while they are trying to save it. Sparks can be handled later manually or through the AI organizer.

For each spark, the user can:

- create a new memory
- add it to an existing memory
- create a reminder
- update the text before saving it elsewhere
- delete it

The AI organizer is intentionally conservative. It receives only unhandled sparks, cluster names, and bounded non-private memory titles. It can suggest actions, memory types, clusters, target memories, rewritten text, and reminder times, but the user stays in control by reviewing or accepting suggestions.

### Recall

Recall is a unified search surface:

- Local keyword search uses SQLite FTS5 for instant deterministic results.
- AI Recall is triggered on demand when the user needs semantic reasoning.

The AI path is designed to be useful without being reckless. It filters locally, limits context, authenticates through Supabase, checks daily quota, calls Gemini from an Edge Function, and stores a compact searchable history.

### Widgets

MindVault includes Android home-screen widgets for fast interaction outside the full app. Widgets can create and open memories, launch spark capture, and expose useful recent content without holding encryption keys.

---

## System Overview

MindVault is built as a local-first, privacy-first system where the device is the primary source of truth and the backend is a sync partner.

```text
Flutter UI + Android Widgets
        |
Riverpod state + go_router
        |
Drift SQLite + FTS5 + encryption services
        |
Outbox sync + reconciliation
        |
Supabase Auth/Postgres/Realtime/Edge Functions
        |
Gemini API for bounded AI workflows
```

Key principles:

- Local data drives the UI.
- Remote sync is asynchronous.
- Backend reads are scoped by RLS and user identity.
- Sensitive content is encrypted before leaving the device.
- AI is given the smallest useful context, not raw database access.
- Native Android scheduling handles reminders that must fire while the app is closed.

---

## Architecture

### End-to-End Encryption

MindVault encrypts memory content on-device before local persistence or remote sync.

- AES-256-GCM encrypts memory and plan content.
- A random data encryption key is generated per user.
- The data key is wrapped using a key derived from the user's PIN with PBKDF2.
- Supabase stores encrypted content and wrapped keys, not plaintext.

```text
Plaintext -> encrypt on device -> store locally -> sync ciphertext
```

Decryption happens only after the user unlocks the app locally.

### Local-First Sync

The local Drift database is the source of truth. User actions commit locally first, then remote persistence happens in the background.

```text
User action
  -> local write
  -> instant UI update
  -> remote sync attempt
      -> success: reconcile
      -> failure: queue durable pending operation
```

When connectivity returns, MindVault replays pending operations, fetches remote changes, and reconciles by `updated_at` using last-write-wins semantics. Supabase Realtime keeps active devices updated without making the app depend on constant connectivity.

### Sparks AI Organizer

Sparks AI applies the same privacy and quota posture as Recall, but the goal is different: it helps convert unstructured thoughts into useful next actions.

```text
Unhandled sparks
  -> local context selection
  -> bounded cluster names + non-private memory titles
  -> Supabase Edge Function
  -> quota check
  -> Gemini
  -> validated suggestions
  -> user review or accept all
```

Design choices that matter:

- Only the oldest unprocessed sparks are sent, capped per request.
- Private memory titles and memory bodies are excluded.
- Long internal IDs are replaced with short request-local aliases to reduce token usage.
- Invalid, unsupported, or low-confidence AI suggestions are dropped.
- Spark reminders use separate native scheduling so memory reminder reconciliation cannot cancel them accidentally.

### Reminders

Reminder records sync across devices as part of the local-first data model, but alarm scheduling is device-local. This keeps user intent consistent while respecting Android's notification and exact-alarm behavior.

MindVault also handles:

- notification permission prompts
- app-closed reminder delivery through native Android receivers
- boot/package-replaced rescheduling
- reminder deep links back into the correct memory or spark
- cleanup of expired reminders so the UI does not show stale active alerts

### Home Widget Security

Widgets are treated as a restricted projection layer over the local database, not as an independent source of truth.

- Widgets can show selected metadata and launch app flows.
- They do not hold encryption keys.
- Main-app lifecycle hooks refresh providers after widget-side writes.
- Widget writes still flow through local storage and sync reconciliation.

---

## AI Boundaries

AI features are useful only if they respect the user's trust.

MindVault's AI design follows a few constraints:

- The model never receives direct database access.
- Requests are authenticated and quota-checked server-side.
- Recall receives only locally selected relevant memories.
- Sparks AI receives only what it needs for organization suggestions.
- Responses are validated before being applied to app state.
- The user remains the final decision-maker for organization actions.

---

## Usage Limits

AI and storage limits are tier-based and stored in Supabase as the single source of truth.

| Limit | Free | Pro |
|---|---:|---:|
| AI Recall searches / day | 5 | 50 |
| Sparks AI organizes / day | 1 | 5 |
| Memories | 100 | 1000 |
| Clusters | 10 | 50 |
| Characters / memory | 5,000 | 20,000 |

The client uses these limits to avoid unnecessary calls. Edge Functions enforce them authoritatively.

---

## Tech Stack

- **Client:** Flutter, Dart, Riverpod, go_router
- **Local storage:** Drift, SQLite, FTS5
- **Backend:** Supabase Auth, Postgres, RLS, Realtime, Edge Functions
- **AI:** Gemini through Supabase Edge Functions
- **Security:** AES-256-GCM, PBKDF2, Android secure storage
- **Android:** native widgets, transparent activity flows, alarms, notification receivers
- **Testing:** Flutter unit/widget tests with fakes for platform and service boundaries

---

## Repository Layout

```text
.
|-- mindvault/                    Flutter project root
|   |-- lib/
|   |   |-- core/                 constants, theme, utilities
|   |   |-- data/                 Drift schema, models, datasources, repositories
|   |   |-- domain/               entities, repository contracts, use cases
|   |   |-- presentation/         providers, router, screens, widgets
|   |   |-- services/             encryption, sync, reminders, widget data, AI
|   |   `-- l10n/                 generated localization surface
|   |-- android/                  Android host, widgets, receivers
|   |-- test/                     unit and widget tests
|   `-- pubspec.yaml
|-- supabase/
|   |-- schema.sql                database schema, RLS, RPCs, compatibility views
|   |-- config.toml
|   `-- functions/
|       |-- ai-search/            AI Recall Edge Function
|       `-- organize-jots/        Sparks organizer Edge Function
|-- specs/                        feature and architecture notes
|-- schema.md                     annotated schema walkthrough
`-- README.md
```

Generated files such as `*.g.dart` and `*.freezed.dart` should not be edited by hand.

---

## Setup

MindVault requires a Flutter Android environment and a Supabase project.

### Prerequisites

- Flutter 3.32+
- Node.js
- Supabase CLI

```bash
npm install -g supabase
supabase login
```

### Backend

Create a Supabase project, then run [`supabase/schema.sql`](supabase/schema.sql) in the SQL editor. The schema creates the core tables, RLS policies, tier limits, sync RPCs, usage tracking, and compatibility views for renamed entities.

### Google OAuth

Google Sign-In through Supabase Auth uses two OAuth clients:

- Web client for Supabase
- Android client for the Flutter app

For the Android SHA-1 fingerprint:

```bash
cd mindvault/android
./gradlew signingReport
```

Add the web client credentials in Supabase under Authentication -> Providers -> Google.

### AI Functions

Create a Gemini API key in Google AI Studio, then configure Supabase secrets:

```bash
npx supabase secrets set GEMINI_API_KEY=<your_key> \
  --project-ref <your-supabase-project-ref>
```

Deploy the Edge Functions:

```bash
npx supabase functions deploy ai-search --project-ref <your-supabase-project-ref>
npx supabase functions deploy organize-jots --project-ref <your-supabase-project-ref>
```

### Client Configuration

Update `mindvault/lib/core/constants/supabase_constants.dart` with:

- Supabase URL
- Supabase anon key
- Google web client ID

The anon key is safe to ship in the client. Authorization is enforced by Supabase Auth and Row Level Security.

Create `mindvault/dart-define.json` from `mindvault/dart-define.json.example` for release builds.

---

## Development

```bash
cd mindvault
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter test
```

For local debug development:

```bash
cd mindvault
flutter run
```

For physical-device release testing, install the release APK instead of switching between `flutter run` and release installs. Android treats debug and release signing identities differently.

### Build Release APK

From the repository root:

```bash
cd mindvault
flutter build apk --release --dart-define-from-file=dart-define.json
cd ..
cp mindvault/build/app/outputs/flutter-apk/app-release.apk mindvault-latest.apk
```

The release keystore is intentionally gitignored. `mindvault/android/key.properties` expects the keystore at `mindvault/android/app/mindvault-release.jks`.

---

## Testing

Run:

```bash
cd mindvault
flutter test
```

Tests mirror the structure of `lib/` and use fakes for service boundaries where possible. This keeps tests close to production behavior without requiring live Supabase or Android platform services for every case.

---

## What This Project Demonstrates

MindVault is intentionally more than a CRUD notes app. It demonstrates:

- product reframing from generic note-taking to personal memory assistance
- local-first architecture with durable offline writes
- encrypted sync across devices
- careful AI integration with bounded context and quota control
- native Android work beyond standard Flutter screens
- pragmatic conflict resolution and realtime reconciliation
- testable service boundaries around storage, sync, reminders, and AI
- migration thinking as the vocabulary changed from notes/categories to memories/clusters/sparks

The hard part was not adding AI. The hard part was deciding where AI should not be trusted, where the device should remain authoritative, and how to keep quick capture fast without sacrificing privacy.

---

## Planned Improvements

- Continue improving AI Recall ranking and source grounding.
- Refine Sparks AI prompts and validation for more precise organization suggestions.
- Expand platform support beyond Android.
- Deepen multilingual polish for the mind-extension vocabulary.

---

## Author

Developed by Amir Twil-Cohen.
