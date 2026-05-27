import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindvault/services/jot_reminder_scheduler_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('mindvault/reminders');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('nextDailyDigestAt returns today when the configured time is future',
      () {
    final now = DateTime(2026, 5, 27, 20, 30);

    final next = nextDailyDigestAt(now, hour: 21, minute: 0);

    expect(next, DateTime(2026, 5, 27, 21));
  });

  test('nextDailyDigestAt returns tomorrow when the configured time has passed',
      () {
    final now = DateTime(2026, 5, 27, 21, 1);

    final next = nextDailyDigestAt(now, hour: 21, minute: 0);

    expect(next, DateTime(2026, 5, 28, 21));
  });

  test('scheduleDailyDigest calls native scheduler with title and body',
      () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return null;
    });

    await JotReminderSchedulerService().scheduleDailyDigest(
      title: 'MindVault Sparks',
      body: 'You have thoughts waiting to be organized.',
    );

    expect(calls, hasLength(1));
    expect(calls.single.method, 'scheduleSparkDigest');
    final args = calls.single.arguments as Map;
    expect(args['title'], 'MindVault Sparks');
    expect(args['body'], 'You have thoughts waiting to be organized.');
    expect(args['fireAtMillis'], isA<int>());
    expect(args['hour'], isA<int>());
    expect(args['minute'], isA<int>());
  });

  test('cancelDailyDigest calls native cancel method', () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return null;
    });

    await JotReminderSchedulerService().cancelDailyDigest();

    expect(calls, hasLength(1));
    expect(calls.single.method, 'cancelSparkDigest');
  });
}
