import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/reminder_repository_impl.dart';
import '../../data/local/database/note_mappers.dart';
import '../../domain/entities/note_reminder.dart';
import '../../domain/repositories/reminder_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/app_localizations_de.dart';
import '../../l10n/app_localizations_en.dart';
import '../../l10n/app_localizations_es.dart';
import '../../l10n/app_localizations_fr.dart';
import '../../l10n/app_localizations_he.dart';
import '../../l10n/app_localizations_hi.dart';
import '../../services/reminder_scheduler_service.dart';
import 'auth_provider.dart';
import 'database_provider.dart';
import 'error_log_provider.dart';
import 'locale_provider.dart';
import 'notes_provider.dart';
import 'shared_preferences_provider.dart';

final reminderSchedulerProvider = Provider<ReminderSchedulerService>((ref) {
  return ReminderSchedulerService(ref.watch(sharedPreferencesProvider));
});

final reminderRepositoryProvider = Provider<ReminderRepository?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  final repo = ReminderRepositoryImpl(
    remote: ref.watch(notesDatasourceProvider),
    local: ref.watch(appDatabaseProvider),
    userId: user.id,
    errorLogger: ref.read(errorLoggerProvider),
  );
  repo.startSync();
  ref.onDispose(repo.stopSync);
  return repo;
});

final reminderForNoteProvider =
    StreamProvider.family<NoteReminder?, String>((ref, noteId) {
  final repo = ref.watch(reminderRepositoryProvider);
  if (repo == null) return const Stream.empty();
  return repo.watchReminderForNote(noteId);
});

final activeRemindersProvider = StreamProvider<List<NoteReminder>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();
  ref.watch(allNotesProvider);
  final db = ref.watch(appDatabaseProvider);
  return db.watchAllReminders(user.id).map((rows) {
    final now = DateTime.now().toUtc();
    return rows.map(rowToReminder).where((r) => r.isActiveAt(now)).toList();
  });
});

final reminderStartupProvider = FutureProvider<void>((ref) async {
  final scheduler = ref.read(reminderSchedulerProvider);
  final repo = ref.watch(reminderRepositoryProvider);
  final noteRepo = ref.watch(noteRepositoryProvider);
  final locale = ref.watch(localeProvider);
  if (repo == null || noteRepo == null) return;
  await scheduler.ensureInitialNotificationPromptOnce();
  await repo.cleanupExpiredReminders(DateTime.now().toUtc());
  await noteRepo.syncPendingOps();
  await repo.syncPendingOps();
  final reminders = await repo.getActiveReminders();
  await scheduler.reconcileAll(
    reminders: reminders,
    loadNote: noteRepo.getNoteById,
    untitledFallback: '(untitled)',
    notificationBody: reminderStringsFor(locale).reminderNotificationBody,
  );
});

AppStrings reminderStringsFor(Locale? locale) {
  final languageCode =
      locale?.languageCode ?? PlatformDispatcher.instance.locale.languageCode;
  switch (languageCode) {
    case 'de':
      return AppStringsDe();
    case 'es':
      return AppStringsEs();
    case 'fr':
      return AppStringsFr();
    case 'he':
      return AppStringsHe();
    case 'hi':
      return AppStringsHi();
    default:
      return AppStringsEn();
  }
}
