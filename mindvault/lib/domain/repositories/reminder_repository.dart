import '../entities/note_reminder.dart';

abstract interface class ReminderRepository {
  Stream<NoteReminder?> watchReminderForNote(String noteId);
  Future<NoteReminder?> getReminderForNote(String noteId);
  Future<List<NoteReminder>> getActiveReminders();
  Future<NoteReminder> setReminder(String noteId, DateTime remindAtUtc);
  Future<void> removeReminder(String noteId);
  Future<void> syncPendingOps();
  Future<void> syncAllReminders();
  Future<void> cleanupExpiredReminders(DateTime now);
}
