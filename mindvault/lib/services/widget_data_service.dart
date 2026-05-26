import 'dart:convert';
import 'package:flutter/foundation.dart' hide Category;
import 'package:home_widget/home_widget.dart';
import '../core/utils/note_preview.dart';
import '../domain/entities/category.dart';
import '../domain/entities/note.dart';

class WidgetDataService {
  static const String _androidWidgetName = 'HomeWidgetProvider';
  static const String _categoriesWidgetName = 'CategoriesWidgetProvider';
  static const int _maxNotes = 20;

  static Map<String, dynamic> _noteEntry(Note n, List<Category> categories) {
    final cat = categories.where((c) => c.id == n.categoryId).firstOrNull;
    return {
      'id': n.id,
      'title': NotePreview.displayTitle(n.title, n.body),
      'is_private': n.isPrivate,
      'is_pinned': n.isPinned,
      'category_id': n.categoryId,
      'category_name': cat?.name ?? '',
      'category_color': cat?.color,
    };
  }

  static List<Map<String, dynamic>> _categoryEntries(
    List<Category> categories,
    List<Note> allNotes,
  ) {
    final counts = <String, int>{};
    for (final n in allNotes) {
      counts[n.categoryId] = (counts[n.categoryId] ?? 0) + 1;
    }
    return categories
        .map((c) => {
              'id': c.id,
              'name': c.name,
              'color': c.color,
              'note_count': counts[c.id] ?? 0,
            })
        .toList();
  }

  /// Sort key: max(lastOpenedAt, createdAt) — "most recently touched".
  static DateTime _noteKey(Note n) {
    final opened = n.lastOpenedAt;
    if (opened != null && opened.isAfter(n.createdAt)) return opened;
    return n.createdAt;
  }

  static Map<String, dynamic> buildPayload({
    required List<Category> categories,
    required List<Note> allNotes,
  }) {
    final sorted = [...allNotes]..sort((a, b) {
        if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
        if (a.isPinned && b.isPinned) {
          return (a.pinOrder ?? 0).compareTo(b.pinOrder ?? 0);
        }
        return _noteKey(b).compareTo(_noteKey(a));
      });

    final notes =
        sorted.take(_maxNotes).map((n) => _noteEntry(n, categories)).toList();

    return {
      'notes': notes,
      'categories': _categoryEntries(categories, allNotes),
      'last_updated': DateTime.now().toUtc().toIso8601String(),
    };
  }

  /// Broadcasts the update to both the notes widget and the categories
  /// widget. `home_widget`'s `updateWidget` only signals one provider per
  /// call, so we trigger each by name.
  Future<void> _broadcastUpdate() async {
    await HomeWidget.updateWidget(androidName: _androidWidgetName);
    await HomeWidget.updateWidget(androidName: _categoriesWidgetName);
  }

  Future<void> updateWidget({
    required List<Category> categories,
    required List<Note> allNotes,
  }) async {
    try {
      final payload = buildPayload(categories: categories, allNotes: allNotes);
      await HomeWidget.saveWidgetData<String>(
          'widget_data', jsonEncode(payload));
      await _broadcastUpdate();
    } catch (e, st) {
      debugPrint('[WidgetDataService] updateWidget failed: $e\n$st');
    }
  }

  Future<void> clearWidget() async {
    try {
      await HomeWidget.saveWidgetData<String>('widget_data', '{}');
      await _broadcastUpdate();
    } catch (e, st) {
      debugPrint('[WidgetDataService] clearWidget failed: $e\n$st');
    }
  }

  /// Adjusts `note_count` for a single category id in an in-memory copy of
  /// the `categories` array. Returns a new list with the delta applied; if
  /// `categoryId` doesn't appear, the list is returned unchanged.
  static List<Map<String, dynamic>> _adjustCategoryCount(
    List<dynamic>? categoriesJson,
    String categoryId,
    int delta,
  ) {
    if (categoriesJson == null) return const [];
    return categoriesJson
        .map((e) => Map<String, dynamic>.from(e as Map))
        .map((e) {
      if (e['id'] != categoryId) return e;
      final count = (e['note_count'] as int? ?? 0) + delta;
      return {...e, 'note_count': count < 0 ? 0 : count};
    }).toList();
  }

  /// Patches the stored widget JSON with a freshly created note without
  /// needing to re-read / re-decrypt all notes from Drift. Inserted at the top
  /// of the unpinned section. The contract is "brand-new id" — the only
  /// caller is [patchWithNewNote], invoked right after `repo.createNote` mints
  /// a fresh UUID. Callers updating an existing note should use
  /// [applyUpsertNote], which adjusts category counts symmetrically when the
  /// note moves between categories.
  static Map<String, dynamic> applyNewNote(
    Map<String, dynamic> current,
    Note note,
    List<Category> categories,
  ) {
    final data = Map<String, dynamic>.from(current);
    final entry = _noteEntry(note, categories);

    final notes = ((data['notes'] as List?) ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    final pinnedCount = notes.where((e) => e['is_pinned'] == true).length;
    notes.insert(pinnedCount, entry);
    if (notes.length > _maxNotes) notes.removeRange(_maxNotes, notes.length);

    final cats = _adjustCategoryCount(
      data['categories'] as List?,
      note.categoryId,
      1,
    );

    return {
      ...data,
      'notes': notes,
      if (cats.isNotEmpty) 'categories': cats,
      'last_updated': DateTime.now().toUtc().toIso8601String(),
    };
  }

  Future<void> patchWithNewNote({
    required Note note,
    required List<Category> categories,
  }) async {
    try {
      final raw = await HomeWidget.getWidgetData<String>('widget_data') ?? '{}';
      final current = (jsonDecode(raw) as Map?)?.cast<String, dynamic>() ?? {};
      final updated = applyNewNote(current, note, categories);
      await HomeWidget.saveWidgetData<String>(
          'widget_data', jsonEncode(updated));
      await _broadcastUpdate();
    } catch (e, st) {
      debugPrint('[WidgetDataService] patchWithNewNote failed: $e\n$st');
    }
  }

  /// Updates a note's entry after it is opened from the widget.
  /// Pinned notes are updated in place (order is governed by pinOrder, not recency).
  /// Unpinned notes are promoted to the top of the unpinned section.
  static Map<String, dynamic> applyNoteOpened(
    Map<String, dynamic> current,
    Note note,
    List<Category> categories,
  ) {
    final entry = _noteEntry(note, categories);
    final notes = ((current['notes'] as List?) ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    if (note.isPinned) {
      final idx = notes.indexWhere((e) => e['id'] == note.id);
      if (idx >= 0) {
        notes[idx] = entry;
      } else {
        // Pinned note not yet in list — insert in pin-order position.
        final insertAt = notes.where((e) => e['is_pinned'] == true).length;
        notes.insert(insertAt, entry);
        if (notes.length > _maxNotes)
          notes.removeRange(_maxNotes, notes.length);
      }
    } else {
      notes.removeWhere((e) => e['id'] == note.id);
      final pinnedCount = notes.where((e) => e['is_pinned'] == true).length;
      notes.insert(pinnedCount, entry);
      if (notes.length > _maxNotes) notes.removeRange(_maxNotes, notes.length);
    }

    return {
      ...current,
      'notes': notes,
      'last_updated': DateTime.now().toUtc().toIso8601String(),
    };
  }

  Future<void> patchNoteOpened({
    required Note note,
    required List<Category> categories,
  }) async {
    try {
      final raw = await HomeWidget.getWidgetData<String>('widget_data') ?? '{}';
      final current = (jsonDecode(raw) as Map?)?.cast<String, dynamic>() ?? {};
      final updated = applyNoteOpened(current, note, categories);
      await HomeWidget.saveWidgetData<String>(
          'widget_data', jsonEncode(updated));
      await _broadcastUpdate();
    } catch (e, st) {
      debugPrint('[WidgetDataService] patchNoteOpened failed: $e\n$st');
    }
  }

  /// Updates an existing note entry in the list after an edit from the widget.
  Future<void> patchWithUpdatedNote({
    required Note note,
    required List<Category> categories,
  }) async {
    try {
      final raw = await HomeWidget.getWidgetData<String>('widget_data') ?? '{}';
      final current = (jsonDecode(raw) as Map?)?.cast<String, dynamic>() ?? {};

      final updatedEntry = _noteEntry(note, categories);
      final existingNotes = ((current['notes'] as List?) ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      final oldEntry =
          existingNotes.where((e) => e['id'] == note.id).firstOrNull;
      final notes = existingNotes
          .map((e) => e['id'] == note.id ? updatedEntry : e)
          .toList();

      // Adjust category counts if the note moved between categories.
      var cats = current['categories'] as List?;
      if (oldEntry != null && oldEntry['category_id'] != note.categoryId) {
        cats =
            _adjustCategoryCount(cats, oldEntry['category_id'] as String, -1);
        cats = _adjustCategoryCount(cats, note.categoryId, 1);
      }

      final updated = {
        ...current,
        'notes': notes,
        if (cats != null) 'categories': cats,
        'last_updated': DateTime.now().toUtc().toIso8601String(),
      };

      await HomeWidget.saveWidgetData<String>(
          'widget_data', jsonEncode(updated));
      await _broadcastUpdate();
    } catch (e, st) {
      debugPrint('[WidgetDataService] patchWithUpdatedNote failed: $e\n$st');
    }
  }

  /// Upserts a note into the widget list. If the note already exists, its
  /// entry is updated in place (preserving order). If not, it is inserted
  /// at the top. Used after an edit from the main app — the widget engine
  /// can't see writes to the main app's Riverpod streams, so the editor
  /// pushes the change here directly so the widget reflects the latest
  /// state (e.g. a note flipped from private to public) immediately.
  Future<void> patchWithUpsertedNote({
    required Note note,
    required List<Category> categories,
  }) async {
    try {
      final raw = await HomeWidget.getWidgetData<String>('widget_data') ?? '{}';
      final current = (jsonDecode(raw) as Map?)?.cast<String, dynamic>() ?? {};
      final updated = applyUpsertNote(current, note, categories);
      await HomeWidget.saveWidgetData<String>(
          'widget_data', jsonEncode(updated));
      await _broadcastUpdate();
    } catch (e, st) {
      debugPrint('[WidgetDataService] patchWithUpsertedNote failed: $e\n$st');
    }
  }

  /// In-place upsert of a note entry against the cached widget JSON.
  ///
  /// Drift counts may briefly disagree with the cached `note_count` here:
  /// when the upserted note was already in the top-20 we apply a symmetric
  /// +1/-1 across the source/destination categories, but when it wasn't
  /// (e.g. an offline edit on a different device, or a note outside the
  /// window) the delta is unknowable and counts are left alone. This is
  /// fine in practice because `widgetSyncProvider` watches `allNotesProvider`
  /// + `categoriesProvider` and re-runs `buildPayload` whenever either
  /// emits, so any drift is corrected the next time the app is foregrounded.
  /// (Background staleness — between app sessions while another device
  /// edits — is a fundamental Android home-widget limitation; no Dart code
  /// runs to refresh the cache until the user opens the app.)
  static Map<String, dynamic> applyUpsertNote(
    Map<String, dynamic> current,
    Note note,
    List<Category> categories,
  ) {
    final entry = _noteEntry(note, categories);
    final notes = ((current['notes'] as List?) ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    final idx = notes.indexWhere((e) => e['id'] == note.id);
    final oldCategoryId =
        idx >= 0 ? notes[idx]['category_id'] as String? : null;
    if (idx >= 0) {
      notes[idx] = entry;
    } else {
      final pinnedCount = notes.where((e) => e['is_pinned'] == true).length;
      notes.insert(note.isPinned ? 0 : pinnedCount, entry);
      if (notes.length > _maxNotes) notes.removeRange(_maxNotes, notes.length);
    }

    var cats = current['categories'] as List?;
    if (oldCategoryId != null && oldCategoryId != note.categoryId) {
      cats = _adjustCategoryCount(cats, oldCategoryId, -1);
      cats = _adjustCategoryCount(cats, note.categoryId, 1);
    }

    return {
      ...current,
      'notes': notes,
      if (cats != null) 'categories': cats,
      'last_updated': DateTime.now().toUtc().toIso8601String(),
    };
  }

  /// Removes a deleted note from the widget list immediately.
  Future<void> patchNoteRemoved({required String noteId}) async {
    try {
      final raw = await HomeWidget.getWidgetData<String>('widget_data') ?? '{}';
      final current = (jsonDecode(raw) as Map?)?.cast<String, dynamic>() ?? {};

      final existingNotes = ((current['notes'] as List?) ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      final removed = existingNotes.where((e) => e['id'] == noteId).firstOrNull;
      final notes = existingNotes.where((e) => e['id'] != noteId).toList();

      var cats = current['categories'] as List?;
      if (removed != null) {
        final cid = removed['category_id'] as String?;
        if (cid != null) cats = _adjustCategoryCount(cats, cid, -1);
      }

      final updated = {
        ...current,
        'notes': notes,
        if (cats != null) 'categories': cats,
        'last_updated': DateTime.now().toUtc().toIso8601String(),
      };

      await HomeWidget.saveWidgetData<String>(
          'widget_data', jsonEncode(updated));
      await _broadcastUpdate();
    } catch (e, st) {
      debugPrint('[WidgetDataService] patchNoteRemoved failed: $e\n$st');
    }
  }
}
