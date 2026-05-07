# Home Widget System

> Read this when working on the Android home widget — anything in `android/app/src/main/kotlin/com/mindvault/app/`, widget XMLs, `widget_data_service.dart`, `widget_sync_provider.dart`, or `lib/presentation/screens/widget/`.

## Overview

The Android home widget displays two note lists ("Recently Used" and "Recently Created") and supports quick note creation and viewing from the home screen. It runs outside the main app process boundary, so several constraints apply.

## Key files

| File | Role |
|------|------|
| `android/app/src/main/kotlin/com/mindvault/app/HomeWidgetProvider.kt` | `AppWidgetProvider` — builds `RemoteViews`, wires `ListView` adapter + click intents |
| `android/app/src/main/kotlin/com/mindvault/app/NoteWidgetService.kt` | `RemoteViewsService` + private `RemoteViewsFactory` — feeds the scrollable `ListView` |
| `android/app/src/main/kotlin/com/mindvault/app/TransparentActivity.kt` | Transparent `FlutterActivity` launched by widget taps |
| `android/app/src/main/res/layout/mindvault_widget.xml` | Widget layout — root `match_parent`, notes in `ListView` |
| `android/app/src/main/res/layout/widget_note_item.xml` | Row layout for individual note items in the widget `ListView` |
| `android/app/src/main/res/layout/widget_section_header.xml` | Row layout for "RECENTLY USED / RECENTLY CREATED" section headers |
| `android/app/src/main/res/xml/mindvault_widget_info.xml` | Widget metadata — default 4×3 cells, min 3×3, resizable |
| `lib/services/widget_data_service.dart` | Builds/patches widget JSON, calls `HomeWidget.updateWidget` |
| `lib/presentation/providers/widget_sync_provider.dart` | Watches `allNotesProvider` + `categoriesProvider`, triggers `updateWidget` |
| `lib/presentation/screens/widget/widget_compose_screen.dart` | Floating "New Note" dialog (transparent background) |
| `lib/presentation/screens/widget/widget_note_view_screen.dart` | Floating note viewer/editor dialog (transparent background) |

## Deep link scheme

All widget taps route through `TransparentActivity` via `mindvault://widget/...`:

| Action | Deep link |
|--------|-----------|
| New note (+ button) | `mindvault://widget/new-note?categoryId=<id>` |
| View/edit note (row tap) | `mindvault://widget/view-note?id=<noteId>` |
| Open app (title tap) | Explicit `MainActivity` intent — no deep link |

Routes `/new-note` and `/view-note` are declared in `app_router.dart` outside the `ShellRoute` (no bottom nav needed).

## TransparentActivity constraints

`TransparentActivity` launches its own Flutter engine. It **skips the splash screen**, so:
- The AES key is never loaded automatically — each widget screen must call `_ensureKeyLoaded()` in `initState`.
- `noteRepositoryProvider` returns `null` until the AES key is set. **Do not read it immediately after setting the key** — Riverpod recomputes it asynchronously. Instead, watch it in `build()` and trigger data loading once it becomes non-null (use a `_loadStarted` flag to fire only once).

## Widget data format

`WidgetDataService` writes a JSON blob to shared preferences via the `home_widget` plugin:

```json
{
  "most_recently_used": [{ "id": "...", "title": "...", "category_id": "...", "category_name": "..." }],
  "most_recent":        [{ "id": "...", "title": "...", "category_id": "...", "category_name": "..." }],
  "recent_category_id": "...",
  "last_updated": "2025-01-01T00:00:00.000Z"
}
```

Note bodies are **not** stored here — they are encrypted and can only be read by the Flutter engine with the AES key loaded. The view screen loads the body via `repo.getNoteById(id)` at runtime.

## RemoteViews layout constraints

Widget layouts run in a restricted sandbox. Only these view classes are allowed in widget XMLs: `FrameLayout`, `LinearLayout`, `RelativeLayout`, `GridLayout`, `TextView`, `ImageView`, `Button`, `ImageButton`, `ProgressBar`, `Chronometer`, `AnalogClock`, `ListView`, `GridView`, `StackView`, `ViewFlipper`, `AdapterViewFlipper`. **`ScrollView` is NOT supported** — using it causes an immediate `widget load error` on placement. For scrollable content, use `ListView` backed by a `RemoteViewsService` + `RemoteViewsFactory`.

`RemoteViewsService.RemoteViewsFactory` interface — key points:
- Method is `getViewAt(position: Int)`, **not** `getView`
- There is **no** `getItemViewType` — view types are inferred from the layout resource IDs returned by `getViewAt`
- `getViewTypeCount()` must return the number of distinct layout IDs you use
- Use `setOnClickFillInIntent` on item views + `setPendingIntentTemplate` on the `ListView` for per-row click handling

## Cross-engine sync

`TransparentActivity` and `MainActivity` run separate Flutter engines against the same Drift SQLite file. Drift stream watchers in the main engine do **not** automatically detect writes made by the widget engine. Fix: `HomeShell` implements `WidgetsBindingObserver` and on `AppLifecycleState.resumed` calls `ref.invalidate` on `allNotesProvider`, `notesByCategoryProvider`, and `categoriesProvider`, then runs `syncPendingOps`.

## PendingIntent request codes

`HomeWidgetProvider.kt` uses fixed request codes to avoid `PendingIntent` collisions:
- `0` — open app (title tap)
- `1` — new note (+ button)
- `10–14` — MRU note rows 1–5
- `20–24` — MR note rows 1–5
