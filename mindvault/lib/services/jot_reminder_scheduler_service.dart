import 'package:flutter/services.dart';

import '../domain/entities/jot.dart';

class JotReminderSchedulerService {
  static const _channel = MethodChannel('mindvault/reminders');
  static const _digestHourDefine = 'SPARK_DIGEST_HOUR';
  static const _digestMinuteDefine = 'SPARK_DIGEST_MINUTE';

  int get digestHour =>
      _readIntDefine(_digestHourDefine, defaultValue: 21).clamp(0, 23).toInt();

  int get digestMinute =>
      _readIntDefine(_digestMinuteDefine, defaultValue: 0).clamp(0, 59).toInt();

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

  Future<void> scheduleDailyDigest({
    required String title,
    required String body,
  }) async {
    final now = DateTime.now();
    final fireAt = nextDailyDigestAt(
      now,
      hour: digestHour,
      minute: digestMinute,
    );
    await _channel.invokeMethod<void>('scheduleSparkDigest', {
      'title': title,
      'body': body,
      'fireAtMillis': fireAt.toUtc().millisecondsSinceEpoch,
      'hour': digestHour,
      'minute': digestMinute,
    });
  }

  Future<void> cancelDailyDigest() async {
    await _channel.invokeMethod<void>('cancelSparkDigest');
  }
}

DateTime nextDailyDigestAt(
  DateTime now, {
  required int hour,
  required int minute,
}) {
  final clampedHour = hour.clamp(0, 23).toInt();
  final clampedMinute = minute.clamp(0, 59).toInt();
  var next = DateTime(
    now.year,
    now.month,
    now.day,
    clampedHour,
    clampedMinute,
  );
  if (!next.isAfter(now)) {
    next = next.add(const Duration(days: 1));
  }
  return next;
}

int _readIntDefine(String name, {required int defaultValue}) {
  const values = {
    JotReminderSchedulerService._digestHourDefine:
        String.fromEnvironment(JotReminderSchedulerService._digestHourDefine),
    JotReminderSchedulerService._digestMinuteDefine:
        String.fromEnvironment(JotReminderSchedulerService._digestMinuteDefine),
  };
  return int.tryParse(values[name] ?? '') ?? defaultValue;
}
