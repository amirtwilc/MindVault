# Sync Architecture — Local-First with Eventual Consistency

> Read this when working on `note_repository_impl.dart`, `app_database.dart`, `sync_service.dart`, `connectivity_service.dart`, or adding a new entity that syncs to Supabase.

## Core principle

The **local Drift SQLite database is the single source of truth**. The UI always reads from and writes to local storage first. Supabase is treated as a remote replica that converges to the same state eventually — never as a blocker for user actions.

This means:
- The app is fully usable offline.
- All reads are instant (no network latency on the critical path).
- Writes succeed locally even with no connection and are pushed to Supabase when connectivity returns.
- Multiple devices converge to the same state without data loss.

## How a write works

```
User action
    │
    ▼
1. Write to local Drift DB  ←── always succeeds, UI updates immediately
    │
    ▼
2. Attempt remote write to Supabase
    ├── success → upsert confirmed remote data back into local DB (reconcile)
    │             delete any pending op for this record
    └── failure → write a PendingOp row to local DB (op_type + record_id)
                  return the local version to the UI — user sees no error
```

The `PendingOpsTable` (`lib/data/local/database/app_database.dart`) acts as an outbox. Each row represents one unsynced mutation: `create_note`, `update_note`, or `delete_note`.

## How offline ops are replayed (pending ops sync)

`NoteRepositoryImpl.syncPendingOps()` is called when connectivity is restored (`ConnectivityService` triggers this via the provider layer). It:

1. Reads all rows from `PendingOpsTable` ordered by `created_at` (oldest first — preserves causal order).
2. For each op:
   - `delete_note` → calls remote delete, then re-deletes locally (Realtime may have re-inserted the note on reconnect).
   - `create_note` / `update_note` → reads the current local row, encrypts fields, calls `upsertNote` on Supabase (idempotent).
3. Deletes the `PendingOp` row on success. A single op failure does **not** abort the loop — remaining ops are still attempted.
4. After the loop, calls `_syncAllNotes()` to pull the final authoritative state from Supabase and reconcile.

## How multi-device conflicts are resolved

Every note carries an `updated_at` timestamp (UTC, set by the writing device). The resolution strategy is **last-write-wins on `updated_at`**:

- All remote writes use Supabase `upsert` (INSERT … ON CONFLICT DO UPDATE), so a later `updated_at` always wins at the database level.
- Realtime pushes the winning version to all connected devices, which `upsertNote` into their local DB.
- On reconnect, `_syncAllNotes()` fetches the full remote snapshot and bulk-upserts it locally, overwriting any stale local rows.

## How deletions are handled across devices

Deletion is the hardest case because a deleted record leaves no row to carry a timestamp.

- **Online delete**: remote row is deleted → Supabase Realtime broadcasts a `DELETE` event → all subscribed devices call `_local.deleteNote(id)`.
- **Offline delete**: a `delete_note` pending op is stored locally with the note's id. The local row is deleted immediately. On reconnect, `syncPendingOps` calls the remote delete, then re-deletes locally (in case Realtime pushed the row back during reconnect).
- **Deletion reconciliation on reconnect** (`_syncAllNotes`): fetches the full remote id set, then deletes any local note whose id is absent from Supabase — **but only if there is no `create_note` pending op for that id** (which would indicate a note created offline that hasn't reached Supabase yet).

## Realtime subscription

`SyncService` opens Supabase Realtime channels (one for notes, one for categories) filtered by `user_id`. Each `PostgresChangeEvent` (INSERT/UPDATE/DELETE) is immediately applied to the local DB via `upsertNote` / `deleteNote`. This keeps all active devices in sync with sub-second latency while connected.

## Key files for this pattern

| File | Role |
|------|------|
| `lib/data/local/database/app_database.dart` | `PendingOpsTable` outbox; `upsertNote`, `upsertNotes`, `getPendingOps`, `deletePendingOp` |
| `lib/data/repositories/note_repository_impl.dart` | Write-local-first logic, `syncPendingOps`, `_syncAllNotes` |
| `lib/data/remote/supabase/supabase_notes_datasource.dart` | Supabase calls + Realtime subscription |
| `lib/services/sync_service.dart` | Starts/stops Realtime channels |
| `lib/services/connectivity_service.dart` | Detects network transitions, triggers pending-op flush |

## Rules for new features that touch data

- All new entity types must follow the same pattern: write local first, attempt remote, queue a pending op on failure.
- Every new op type must be handled in `syncPendingOps` (or its equivalent for that repository).
- Never read from Supabase on the hot path — always read from Drift.
- Upserts must be idempotent so replaying a pending op twice is safe.
- New repositories must expose a `syncPendingOps()` method and hook it into the connectivity restoration flow.
