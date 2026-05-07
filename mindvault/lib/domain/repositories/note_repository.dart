import '../entities/note.dart';

abstract interface class NoteRepository {
  Stream<List<Note>> watchNotesByCategory(String categoryId);
  Stream<List<Note>> watchAllNotes();
  Future<Note?> getNoteById(String id);
  Future<Note> createNote({
    required String categoryId,
    required String title,
    required String body,
    required bool isPrivate,
  });
  Future<Note> updateNote({
    required String id,
    String? title,
    String? body,
    bool? isPrivate,
    String? categoryId,
  });
  Future<void> deleteNote(String id);
  Future<List<Note>> searchNotes(String query);
  Future<void> markNoteOpened(String id);
  Future<void> syncPendingOps();
  Future<void> setNotePinned({required String id, required bool isPinned});
  Future<void> reorderPinnedNotes(List<String> orderedIds);
}
