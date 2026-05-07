import 'dart:convert';
import 'package:flutter/foundation.dart' hide Category;
import 'package:home_widget/home_widget.dart';
import '../core/utils/note_preview.dart';
import '../domain/entities/category.dart';
import '../domain/entities/note.dart';

class WidgetDataService {
  static const String _androidWidgetName = 'HomeWidgetProvider';
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
    };
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
    final sorted = [...allNotes]
      ..sort((a, b) {
        if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
        if (a.isPinned && b.isPinned) {
          return (a.pinOrder ?? 0).compareTo(b.pinOrder ?? 0);
        }
        return _noteKey(b).compareTo(_noteKey(a));
      });

    final notes = sorted
        .take(_maxNotes)
        .map((n) => _noteEntry(n, categories))
        .toList();

    final recentCategoryId =
        sorted.isNotEmpty ? sorted.first.categoryId : '';

    return {
      'notes': notes,
      'recent_category_id': recentCategoryId,
      'last_updated': DateTime.now().toUtc().toIso8601String(),
    };
  }

  Future<void> updateWidget({
    required List<Category> categories,
    required List<Note> allNotes,
  }) async {
    try {
      final payload = buildPayload(categories: categories, allNotes: allNotes);
      await HomeWidget.saveWidgetData<String>('widget_data', jsonEncode(payload));
      await HomeWidget.updateWidget(androidName: _androidWidgetName);
    } catch (e, st) {
      debugPrint('[WidgetDataService] updateWidget failed: $e\n$st');
    }
  }

  Future<void> clearWidget() async {
    try {
      await HomeWidget.saveWidgetData<String>('widget_data', '{}');
      await HomeWidget.updateWidget(androidName: _androidWidgetName);
    } catch (e, st) {
      debugPrint('[WidgetDataService] clearWidget failed: $e\n$st');
    }
  }

  /// Patches the stored widget JSON with a freshly created note without
  /// needing to re-read / re-decrypt all notes from Drift. The new note goes
  /// to position 0 (just created → most recently touched).
  static Map<String, dynamic> applyNewNote(
    Map<String, dynamic> current,
    Note note,
    List<Category> categories,
  ) {
    final data = Map<String, dynamic>.from(current);
    final entry = _noteEntry(note, categories);

    final notes = ((data['notes'] as List?) ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .where((e) => e['id'] != note.id)
        .toList();
    final pinnedCount = notes.where((e) => e['is_pinned'] == true).length;
    notes.insert(pinnedCount, entry);
    if (notes.length > _maxNotes) notes.removeRange(_maxNotes, notes.length);

    return {
      ...data,
      'notes': notes,
      'recent_category_id': note.categoryId,
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
      await HomeWidget.saveWidgetData<String>('widget_data', jsonEncode(updated));
      await HomeWidget.updateWidget(androidName: _androidWidgetName);
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
        if (notes.length > _maxNotes) notes.removeRange(_maxNotes, notes.length);
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
      await HomeWidget.saveWidgetData<String>('widget_data', jsonEncode(updated));
      await HomeWidget.updateWidget(androidName: _androidWidgetName);
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
      final notes = ((current['notes'] as List?) ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .map((e) => e['id'] == note.id ? updatedEntry : e)
          .toList();

      final updated = {
        ...current,
        'notes': notes,
        'last_updated': DateTime.now().toUtc().toIso8601String(),
      };

      await HomeWidget.saveWidgetData<String>('widget_data', jsonEncode(updated));
      await HomeWidget.updateWidget(androidName: _androidWidgetName);
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
      await HomeWidget.saveWidgetData<String>('widget_data', jsonEncode(updated));
      await HomeWidget.updateWidget(androidName: _androidWidgetName);
    } catch (e, st) {
      debugPrint('[WidgetDataService] patchWithUpsertedNote failed: $e\n$st');
    }
  }

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
    if (idx >= 0) {
      notes[idx] = entry;
    } else {
      final pinnedCount = notes.where((e) => e['is_pinned'] == true).length;
      notes.insert(note.isPinned ? 0 : pinnedCount, entry);
      if (notes.length > _maxNotes) notes.removeRange(_maxNotes, notes.length);
    }

    return {
      ...current,
      'notes': notes,
      'last_updated': DateTime.now().toUtc().toIso8601String(),
    };
  }

  /// Removes a deleted note from the widget list immediately.
  Future<void> patchNoteRemoved({required String noteId}) async {
    try {
      final raw = await HomeWidget.getWidgetData<String>('widget_data') ?? '{}';
      final current = (jsonDecode(raw) as Map?)?.cast<String, dynamic>() ?? {};

      final notes = ((current['notes'] as List?) ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .where((e) => e['id'] != noteId)
          .toList();

      final updated = {
        ...current,
        'notes': notes,
        'last_updated': DateTime.now().toUtc().toIso8601String(),
      };

      await HomeWidget.saveWidgetData<String>('widget_data', jsonEncode(updated));
      await HomeWidget.updateWidget(androidName: _androidWidgetName);
    } catch (e, st) {
      debugPrint('[WidgetDataService] patchNoteRemoved failed: $e\n$st');
    }
  }
}
