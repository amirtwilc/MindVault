import '../entities/jot.dart';

abstract interface class JotRepository {
  void startSync();
  void stopSync();
  Stream<List<Jot>> watchUnhandledJots({JotSortOrder sortOrder});
  Future<List<Jot>> getUnhandledJots({JotSortOrder sortOrder});
  Future<Jot?> getJotById(String id);
  Future<Jot> createJot({required String text});
  Future<Jot?> updateJot({
    required String id,
    String? text,
    DateTime? handledAt,
    DateTime? aiProcessedAt,
    String? aiSuggestionJson,
    String? aiSuggestionRunId,
    DateTime? reminderAt,
  });
  Future<Jot?> clearReminder(String id);
  Future<void> markHandled(String id);
  Future<void> deleteJot(String id);
  Future<void> deleteJots(List<String> ids);
  Future<void> syncPendingOps();
}
