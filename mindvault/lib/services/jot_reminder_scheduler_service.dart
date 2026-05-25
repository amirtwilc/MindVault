import 'package:flutter/services.dart';

import '../domain/entities/jot.dart';

class JotReminderSchedulerService {
  static const _channel = MethodChannel('mindvault/reminders');

  Future<void> schedule({
    required Jot jot,
    required String notificationBody,
  }) async {
    final reminderAt = jot.reminderAt;
    if (reminderAt == null) return;
    await _channel.invokeMethod<void>('scheduleJot', {
      'jotId': jot.id,
      'title': jot.text,
      'body': notificationBody,
      'remindAtMillis': reminderAt.toUtc().millisecondsSinceEpoch,
      'version': jot.updatedAt.toUtc().toIso8601String(),
    });
  }

  Future<void> cancel(String jotId) async {
    await _channel.invokeMethod<void>('cancelJot', {'jotId': jotId});
  }

  Future<void> cancelExcept(Iterable<String> jotIds) async {
    await _channel.invokeMethod<void>(
      'cancelJotsExcept',
      {'jotIds': jotIds.toList()},
    );
  }
}
