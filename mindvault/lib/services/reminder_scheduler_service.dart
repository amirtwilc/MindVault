import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/entities/note.dart';
import '../domain/entities/note_reminder.dart';
import 'reminder_title.dart';

class ReminderPermissionResult {
  final bool notificationsAllowed;
  final bool exactAlarmsAllowed;

  const ReminderPermissionResult({
    required this.notificationsAllowed,
    required this.exactAlarmsAllowed,
  });

  bool get canSchedule => notificationsAllowed;
}

class ReminderSchedulerService {
  static const _channel = MethodChannel('mindvault/reminders');
  static const _initialPromptKey = 'reminders.initial_notification_prompt_done';
  static const _backgroundPromptKey =
      'reminders.background_permission_prompt_done';

  final SharedPreferences? _prefs;

  ReminderSchedulerService([this._prefs]);

  Future<ReminderPermissionResult> ensureInitialNotificationPromptOnce() async {
    final prefs = _prefs;
    if (prefs == null) return checkPermissions();
    if (prefs.getBool(_initialPromptKey) == true) {
      return checkPermissions();
    }
    prefs.setBool(_initialPromptKey, true);
    return requestPermissions(requestExactAlarm: true);
  }

  Future<ReminderPermissionResult> ensureSchedulingPermissionsForUserAction() {
    return requestPermissions(requestExactAlarm: true);
  }

  Future<bool> shouldPromptBackgroundPermission() async {
    final prefs = _prefs;
    if (prefs == null) return false;
    return prefs.getBool(_backgroundPromptKey) != true;
  }

  Future<void> markBackgroundPermissionPromptDone() async {
    await _prefs?.setBool(_backgroundPromptKey, true);
  }

  Future<bool> openBackgroundPermissionSettings() async {
    return await _channel.invokeMethod<bool>(
          'openBackgroundPermissionSettings',
        ) ??
        false;
  }

  Future<ReminderPermissionResult> checkPermissions() async {
    final result = await _channel.invokeMapMethod<String, Object?>(
          'checkPermissions',
        ) ??
        const {};
    return _resultFromMap(result);
  }

  Future<ReminderPermissionResult> requestPermissions({
    required bool requestExactAlarm,
  }) async {
    final result = await _channel.invokeMapMethod<String, Object?>(
          'requestPermissions',
          {'requestExactAlarm': requestExactAlarm},
        ) ??
        const {};
    return _resultFromMap(result);
  }

  Future<void> schedule({
    required NoteReminder reminder,
    required Note note,
    required String untitledFallback,
    required String notificationBody,
  }) async {
    await _channel.invokeMethod<void>('schedule', {
      'noteId': reminder.noteId,
      'title': reminderNotificationTitle(note, untitledFallback),
      'body': notificationBody,
      'remindAtMillis': reminder.remindAt.toUtc().millisecondsSinceEpoch,
      'version': reminder.updatedAt.toUtc().toIso8601String(),
    });
  }

  Future<void> cancel(String noteId) async {
    await _channel.invokeMethod<void>('cancel', {'noteId': noteId});
  }

  Future<void> reconcileAll({
    required Iterable<NoteReminder> reminders,
    required Future<Note?> Function(String noteId) loadNote,
    required String untitledFallback,
    required String notificationBody,
  }) async {
    final activeIds = <String>{};
    for (final reminder in reminders) {
      final note = await loadNote(reminder.noteId);
      if (note == null) {
        await cancel(reminder.noteId);
        continue;
      }
      activeIds.add(reminder.noteId);
      await schedule(
        reminder: reminder,
        note: note,
        untitledFallback: untitledFallback,
        notificationBody: notificationBody,
      );
    }
    await _channel.invokeMethod<void>(
      'cancelExcept',
      {'noteIds': activeIds.toList()},
    );
  }

  ReminderPermissionResult _resultFromMap(Map<String, Object?> result) {
    return ReminderPermissionResult(
      notificationsAllowed: result['notificationsAllowed'] == true,
      exactAlarmsAllowed: result['exactAlarmsAllowed'] == true,
    );
  }
}
