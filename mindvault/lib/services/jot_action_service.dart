import '../domain/entities/jot.dart';
import '../domain/entities/note.dart';
import '../domain/entities/note_reminder.dart';
import '../domain/repositories/jot_repository.dart';
import '../domain/repositories/note_repository.dart';
import '../domain/repositories/reminder_repository.dart';

class JotActionRequest {
  final bool deleteThought;
  final bool createNote;
  final bool addToNote;
  final bool createAlert;
  final String? newNoteTitle;
  final String? newNoteCategoryId;
  final NoteType newNoteType;
  final bool newNoteLocked;
  final String? existingNoteId;
  final DateTime? reminderAt;
  final String? updatedText;
  final bool cancelJotReminder;

  const JotActionRequest({
    this.deleteThought = false,
    this.createNote = false,
    this.addToNote = false,
    this.createAlert = false,
    this.newNoteTitle,
    this.newNoteCategoryId,
    this.newNoteType = NoteType.text,
    this.newNoteLocked = false,
    this.existingNoteId,
    this.reminderAt,
    this.updatedText,
    this.cancelJotReminder = false,
  });

  factory JotActionRequest.fromSuggestion({
    required JotAiSuggestion suggestion,
    required String fallbackCategoryId,
  }) {
    final wantsReminder = suggestion.reminderAt != null;
    return switch (suggestion.action) {
      JotSuggestedAction.createNote => JotActionRequest(
          createNote: true,
          createAlert: wantsReminder,
          newNoteTitle: suggestion.title,
          newNoteCategoryId: suggestion.categoryId ?? fallbackCategoryId,
          newNoteType: NoteType.fromStorage(suggestion.noteType ?? 'text'),
          newNoteLocked: suggestion.isPrivate ?? false,
          reminderAt: suggestion.reminderAt,
          updatedText: suggestion.updatedText,
        ),
      JotSuggestedAction.addToNote => JotActionRequest(
          addToNote: true,
          createAlert: wantsReminder,
          existingNoteId: suggestion.noteId,
          reminderAt: suggestion.reminderAt,
          updatedText: suggestion.updatedText,
        ),
      JotSuggestedAction.reminder => JotActionRequest(
          createAlert: true,
          reminderAt: suggestion.reminderAt,
          updatedText: suggestion.updatedText,
        ),
    };
  }
}

class JotActionResult {
  final Note? note;
  final NoteReminder? noteReminder;
  final Jot? jotReminder;
  final bool deleted;
  final bool handled;
  final bool updated;
  final bool cancelJotReminder;

  const JotActionResult({
    this.note,
    this.noteReminder,
    this.jotReminder,
    this.deleted = false,
    this.handled = false,
    this.updated = false,
    this.cancelJotReminder = false,
  });
}

class JotActionService {
  final JotRepository _jotRepository;
  final NoteRepository _noteRepository;
  final ReminderRepository _reminderRepository;

  const JotActionService({
    required JotRepository jotRepository,
    required NoteRepository noteRepository,
    required ReminderRepository reminderRepository,
  })  : _jotRepository = jotRepository,
        _noteRepository = noteRepository,
        _reminderRepository = reminderRepository;

  Future<JotActionResult> apply({
    required Jot jot,
    required JotActionRequest request,
  }) async {
    if (request.deleteThought) {
      await _jotRepository.deleteJot(jot.id);
      return const JotActionResult(deleted: true, cancelJotReminder: true);
    }

    final updatedText = _normalizedUpdatedText(jot, request.updatedText);
    final actionText = updatedText ?? jot.text;

    Note? targetNote;
    if (request.createNote) {
      final categoryId = request.newNoteCategoryId;
      if (categoryId == null || categoryId.isEmpty) {
        throw StateError('Create-note jot action requires a category.');
      }
      targetNote = await _noteRepository.createNote(
        categoryId: categoryId,
        title: request.newNoteTitle?.trim() ?? '',
        body: actionText,
        isPrivate: request.newNoteLocked,
        noteType: request.newNoteType,
      );
      if (request.newNoteType == NoteType.checklist) {
        await _noteRepository.replaceChecklistItems(
          noteId: targetNote.id,
          texts: [actionText],
        );
      }
    } else if (request.addToNote) {
      final noteId = request.existingNoteId;
      if (noteId == null || noteId.isEmpty) {
        throw StateError('Add-to-note jot action requires a note.');
      }
      final existing = await _noteRepository.getNoteById(noteId);
      if (existing == null) {
        throw StateError('Selected note no longer exists.');
      }
      targetNote = await _appendToNote(existing, actionText);
    }

    NoteReminder? noteReminder;
    Jot? jotReminder;
    var canceledJotReminder = false;
    if (request.createAlert && request.reminderAt != null) {
      if (targetNote != null) {
        noteReminder = await _reminderRepository.setReminder(
          targetNote.id,
          request.reminderAt!.toUtc(),
        );
        if (jot.reminderAt != null) {
          await _jotRepository.clearReminder(jot.id);
          canceledJotReminder = true;
        }
      } else {
        jotReminder = await _jotRepository.updateJot(
          id: jot.id,
          text: updatedText,
          reminderAt: request.reminderAt!.toUtc(),
        );
      }
    } else if (request.cancelJotReminder) {
      await _jotRepository.clearReminder(jot.id);
      canceledJotReminder = true;
    }

    if (updatedText != null && jotReminder == null) {
      jotReminder = await _jotRepository.updateJot(
        id: jot.id,
        text: updatedText,
      );
    }

    final shouldHandle = targetNote != null;
    if (shouldHandle) {
      if (jot.reminderAt != null && !canceledJotReminder) {
        await _jotRepository.clearReminder(jot.id);
        canceledJotReminder = true;
      }
      await _jotRepository.markHandled(jot.id);
    }

    return JotActionResult(
      note: targetNote,
      noteReminder: noteReminder,
      jotReminder: jotReminder,
      handled: shouldHandle,
      updated: updatedText != null,
      cancelJotReminder: request.deleteThought || canceledJotReminder,
    );
  }

  String? _normalizedUpdatedText(Jot jot, String? text) {
    final trimmed = text?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed == jot.text.trim() ? null : trimmed;
  }

  Future<Note> _appendToNote(Note note, String text) async {
    if (note.noteType == NoteType.checklist) {
      final existing = await _noteRepository.getChecklistItems(note.id);
      final nextTexts = [
        ...existing.map((item) => item.text),
        text,
      ];
      final nextStates = [
        ...existing.map((item) => item.isCompleted),
        false,
      ];
      final nextIds = [
        ...existing.map((item) => item.id),
        null,
      ];
      await _noteRepository.replaceChecklistItems(
        noteId: note.id,
        texts: nextTexts,
        completionStates: nextStates,
        rowIds: nextIds,
      );
      final updated = await _noteRepository.getNoteById(note.id);
      return updated ?? note;
    }

    final trimmed = text.trim();
    final nextBody =
        note.body.trim().isEmpty ? trimmed : '${note.body.trim()}\n$trimmed';
    return _noteRepository.updateNote(id: note.id, body: nextBody);
  }
}
