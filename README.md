# MindVault

A privacy-first notes system built with Flutter, combining offline-first storage, end-to-end encryption, and AI-powered search—without relying on constant connectivity.

---

## Highlights

- **Local-first architecture**  
  All data is written to a local Drift database first, enabling instant UI updates and full offline functionality. Remote sync is asynchronous and resilient.

- **End-to-end encryption by design**  
  Notes are encrypted on-device using AES-256-GCM. The backend stores only ciphertext, and encryption keys never leave the user’s device.

- **Cross-device sync with conflict resolution**  
  An outbox-based sync engine ensures eventual consistency across devices, using last-write-wins reconciliation and realtime updates.

- **AI-powered semantic search (cost-aware)**  
  A constrained retrieval pipeline selects relevant notes locally and queries an LLM via a Supabase Edge Function, enforcing quotas and grounding responses in user data.

- **Unified search experience**  
  Instant keyword search and AI search are combined into a single interface, allowing users to start with fast local results and escalate to semantic queries when needed.

- **Multi-surface interaction (App + Home Widget)**  
  Notes can be viewed, created, and searched directly from a home-screen widget, powered by a secure metadata projection of the local database.

---

## System Overview

MindVault is built as a **privacy-first, local-first system** where all core operations originate on the device and synchronize outward.

At a high level, the system consists of four cooperating layers:

UI (App + Widget)  
↓  
Local Core (Drift database + Encryption)  
↓  
Sync Engine (Outbox + Reconciliation)  
↓  
Supabase Backend (Auth + Storage + Realtime + Edge Functions)  
↓  
External AI (Gemini via Edge Function)  

### Key principles
* Local database is the single source of truth
* Sync is asynchronous and resilient
* Backend is a replica, not a dependency
* AI operates on filtered, user-scoped context
* Sensitive data remains encrypted outside the device

--- 

## Architecture

### End-to-end encryption

All note content is encrypted on-device before storage or transmission.

* AES-256-GCM is used for note encryption
* A random data encryption key (DEK) is generated per user
* The DEK is wrapped using a key derived from the user’s PIN (PBKDF2)
* Only the wrapped key is stored remotely

Flow:

Plaintext → Encrypt (AES) → Store locally → Sync ciphertext

* Decryption happens only on-device
* Backend never sees plaintext or keys

--- 

### Local-first sync

**Local-first architecture** is enforced, where the local SQLite database (Drift) is the single source of truth.

Supabase acts as a **replicated remote store**, used for cross-device synchronization rather than direct state management.

This design ensures:
- instant UI responsiveness
- full offline functionality
- deterministic synchronization when connectivity resumes

Write flow:

User action  
  → local write (instant UI)  
  → attempt remote sync  
      → success: reconcile  
      → failure: queue in outbox  

Reconnect flow:

Connectivity restored  
  → replay queued operations  
  → fetch latest snapshot  
  → reconcile local state 

* Uses outbox pattern
* Conflict resolution: last-write-wins (updated_at)
* Ensures no data loss during offline usage


---

### AI search

AI search is implemented as a constrained retrieval pipeline, which means responses are anchored in retrieved context, minimizng hallucinations and ensuring high fidelity to source documents.

Flow:

Query  
  → local cache check  
  → local ranking (top K notes)  
  → Edge Function (auth + quota)  
  → Gemini API   
  → response + sources  

Key design choices:

* Only top relevant notes are sent (not full dataset)
* The LLM never sees raw database access — only a filtered subset
* LLM is grounded to user notes only
* Server enforces quota and authentication
* Responses include cited Sources
* Caching responses to reduce repeated call

### Unified search

Search is implemented as a two-layer system:

#### 1. Local search (default)
* Instant results (FTS5)
* Deterministic scoring
#### 2. AI search (on demand)
* Triggered explicitly by user
* Semantic reasoning over notes

Users interact with a single search interface, the system adapts automatically.

### Home widget

The Home Widget acts as a **lightweight interaction surface over the local-first system**, enabling fast note operations without opening the main application.

It is designed as a **restricted projection layer** of the core database, not an independent data source.

---

#### Capabilities

* View recent/pinned notes
* Create/edit/delete notes
* Search notes (keyword + AI search)

#### Security model


* Only metadata (id, title, category) is exposed
* No access to encryption keys
* No direct decryption

---

## Usage Limits & Quotas

AI features are cost-bound and enforced via tier limits.

---

### Available tiers

| Limit | Free | Pro |
|---|---:|---:|
| AI searches / day | 5 | 50 |
| Notes | 100 | 1000 |
| Categories | 10 | 50 |
| Characters / note | 5,000 | 20,000 |


### Enforcement model

* **Client-side**: prevents unnecessary calls
* **Server-side**: authoritative (Edge Function)

Both must stay in sync.

### Upgrading a user

User tier is stored in the `profiles` table.

To upgrade a user:

```sql
UPDATE profiles
SET tier = 'pro'
WHERE id = (
  SELECT id FROM auth.users WHERE email = 'user@example.com'
);
```

---

## Build & run

MindVault runs on a Flutter client backed by Supabase for authentication, encrypted storage, and server-side AI processing via Edge Functions.

This means a working setup requires both a local Flutter environment and a configured Supabase project.

---

### Install prerequisites
- Flutter 3.32+
  https://docs.flutter.dev/get-started/install
- Node.js (for CLI)
  https://nodejs.org/

---

### Install Supabase CLI

```bash
npm install -g supabase
```
```bash
supabase --version
```
```bash
supabase login
```

### Create backend (Supabase)

Create a new Supabase project and run [`supabase/schema.sql`](supabase/schema.sql)
in the SQL editor. See [`schema.md`](schema.md) for what it does and why.

---

### Configure Google OAuth

For Google Sign-In through Supabase Auth, create two OAuth clients:

- A **Web Client** (used by Supabase backend)
- An **Android Client** (used by the Flutter app)

---

#### Create OAuth credentials in Google Cloud

Go to:
https://console.cloud.google.com/apis/credentials

Enable:
- Google Identity Services (if not enabled)

---

#### Create OAuth Client 1: Web Application

This is used by Supabase.

- Application type: **Web application**
- Add redirect URI: https://<your-supabase-project-ref>.supabase.co/auth/v1/callback

Copy:
- Client ID
- Client Secret

---

#### Add to Supabase

Go to:
Supabase Dashboard → Authentication → Providers → Google

Paste:
- Web Client ID
- Web Client Secret

---

#### Create OAuth Client 2: Android

This is used by the Flutter app.

- Application type: **Android**
- Package name: com.mindvault.app
- SHA-1 fingerprint:

Generate it using:

```bash
cd mindvault/android && ./gradlew signingReport
```
Copy SHA1 from the debug variant.

---

### Enable AI Search (Edge Function)

MindVault uses a Supabase Edge Function to securely execute AI-powered semantic queries over encrypted note metadata.
Gemini free tier API was used. Create an API key here https://aistudio.google.com/

Set your Gemini API key:
```bash
npx supabase secrets set GEMINI_API_KEY=<your_key> \
  --project-ref <your-supabase-project-ref>
```

Deploy the function:
```bash
npx supabase functions deploy ai-search \
  --project-ref <your-supabase-project-ref>
```

---

### Configure client

Update `mindvault/lib/core/constants/supabase_constants.dart` with:

- Supabase URL
- Anon key (Supabase -> Settings -> API Keys -> )
- Google Web Client ID

The anon key is safe to expose in client applications. Security is enforced through Row Level Security (RLS), not by hiding the key.

---

### Development

```bash
cd mindvault
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

### Test

```bash
cd mindvault && flutter test
```

Tests are structured to mirror lib/ and use fake implementations instead of mocks for Supabase dependencies to better reflect real runtime behavior.

### Build a release APK

```bash
cd mindvault
flutter build apk --release
cp build/app/outputs/flutter-apk/app-release.apk ../mindvault-latest.apk
```
---

## Repository layout

```
.
├── mindvault/                 Flutter project (run all flutter commands here)
│   ├── lib/
│   │   ├── core/              constants, theme, utilities
│   │   ├── data/              Drift schema, models, datasources, repositories
│   │   ├── domain/            freezed entities + abstract repos
│   │   ├── presentation/      providers, router, screens, widgets
│   │   └── services/          encryption, biometric, sync, widget data, AI
│   ├── android/               Android host: home widget, transparent activity
│   ├── test/                  unit + widget tests
│   └── pubspec.yaml
├── supabase/
│   ├── schema.sql             one-shot DB bootstrap (idempotent)
│   ├── config.toml            Supabase CLI config
│   └── functions/ai-search/   Deno edge function for Gemini calls
├── schema.md                  Annotated walk-through of schema.sql + setup
├── CLAUDE.md                  Working notes for AI assistants
└── .github/workflows/         CI: tag → build APK → GitHub release
```

`*.g.dart` and `*.freezed.dart` files are generated and should not be
edited by hand — regenerate them with `dart run build_runner build`.

---

## What's Next

MindVault already provides what I consider the foundations of a modern notes app:  
privacy-first storage, offline reliability, and intelligent search.

But this is only the beginning of the broader vision.

As the name **MindVault** suggests, the goal is not simply to store notes - it is to become a trusted extension of the user’s memory: 
a secure personal knowledge space that can preserve information, organize it intelligently, and surface it exactly when needed.

How that vision should evolve is still being explored, but the direction is clear:  
to move from *note-taking* toward a more capable **personal knowledge companion**.

### Other Planned improvements

- **First-time onboarding guide**  
  An interactive introduction to key features such as encryption, sync, AI search, and the home widget.

- **Richer note types**  
  Support for structured content such as:
  - checklists
  - reminders and alerts
  - templates for recurring note formats

- **Smarter knowledge retrieval**  
  Continued improvements to AI search, ranking, and contextual understanding.

- **Expanded platform support**  
  iOS support and broader cross-device experiences.


## Technical Deep-Dives

### Achieving Local-first architecture

MindVault is built around a local-first sync model, designed to make note operations feel instantaneous while maintaining reliable cross-device consistency.

#### Instant local writes, resilient remote sync

Every note or category mutation (**create, update, or delete**) is committed immediately to the local **Drift (SQLite)** database. Because the UI is driven by **Riverpod stream providers**, changes appear instantly without waiting for network round-trips.

Remote persistence to **Supabase** happens asynchronously in the background. If a request fails (for example, due to connectivity loss), the operation is not discarded—instead, it is written to a PendingOpsTable, which acts as a durable **outbox queue**. This ensures the local database remains authoritative, allowing users to continue working seamlessly even while offline.

#### Automatic reconnection and queued operation replay

MindVault continuously monitors connectivity through a `StreamProvider<bool>` built on `connectivity_plus`. When the device transitions from **offline to online**, `HomeShell` automatically triggers synchronization by replaying all queued category and note operations.

The same flush process also runs when the app returns to the foreground (`didChangeAppLifecycleState(resumed)`), ensuring pending changes are pushed as soon as possible. Operations are replayed **oldest-first**, preserving intent and maintaining deterministic sync behavior.

#### Conflict resolution with last-write-wins guarantees

To prevent stale offline updates from overwriting newer changes made on another device, MindVault applies a **last-write-wins** strategy based on the `updated_at` timestamp.

Before replaying a queued `update_note` operation, the sync engine fetches the current remote version of the note. If the remote copy has a newer timestamp, the local pending update is silently discarded, and the newer remote state is pulled during the next full reconciliation. This guarantees that the most recent successful edit always wins.

#### Realtime multi-device synchronization

For active sessions, `NoteRepositoryImpl.startSync()` opens a **Supabase Realtime Postgres Changes** channel filtered by `user_id`.

Incoming `INSERT` and `UPDATE` events are decrypted and merged directly into the local database, while `DELETE` events remove notes locally. This keeps multiple devices synchronized in near real time, typically within sub-second latency.

On application startup, MindVault also performs a full synchronization (`_syncAllNotes()`) to reconcile any drift between local and remote state before realtime updates begin.

#### Safe deletion reconciliation

Deletion handling includes additional safeguards to support offline workflows.

During full sync, MindVault compares the complete remote note ID set against the local database. Any local note missing remotely is removed, **unless** it has a pending `create_note` operation, which indicates the note was created offline and has not yet been uploaded.

Offline deletions are queued as `delete_note` operations and replayed once connectivity returns. After the remote delete succeeds, the note is deleted locally again to guard against race conditions where delayed realtime events could otherwise restore a stale record.

Together, these mechanisms provide a sync experience that is fast, offline-capable, and eventually consistent, allowing MindVault to behave like a local app while seamlessly keeping data synchronized across devices.

---

## Author

Developed by Amir Twil-Cohen
