import '../entities/note.dart';
import '../entities/checklist_item.dart';

abstract interface class NoteRepository {
  Stream<List<Note>> watchNotesByCategory(String categoryId);
  Stream<List<Note>> watchAllNotes();
  Future<Note?> getNoteById(String id);
  Future<Note> createNote({
    required String categoryId,
    required String title,
    required String body,
    required bool isPrivate,
    NoteType noteType = NoteType.text,
  });
  Future<Note> updateNote({
    required String id,
    String? title,
    String? body,
    bool? isPrivate,
    String? categoryId,
    NoteType? noteType,
  });
  Future<void> deleteNote(String id);
  Future<List<Note>> searchNotes(String query);
  Future<void> markNoteOpened(String id);
  Future<void> syncPendingOps();
  Future<void> setNotePinned({required String id, required bool isPinned});
  Future<void> reorderPinnedNotes(List<String> orderedIds);
  Stream<List<ChecklistItem>> watchChecklistItems(String noteId);
  Future<List<ChecklistItem>> getChecklistItems(String noteId);
  Future<void> convertNoteType({
    required String noteId,
    required NoteType noteType,
  });
  Future<List<ChecklistItem>> replaceChecklistItems({
    required String noteId,
    required List<String> texts,
    List<bool>? completionStates,
    List<String?>? rowIds,
  });
  Future<void> toggleChecklistItem({
    required String id,
    required bool isCompleted,
  });
  Future<void> reorderChecklistItems({
    required String noteId,
    required List<String> orderedIds,
  });
  Future<void> deleteCompletedChecklistItems(String noteId);
}
