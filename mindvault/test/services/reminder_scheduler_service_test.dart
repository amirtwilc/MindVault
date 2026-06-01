import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindvault/services/reminder_scheduler_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('mindvault/reminders');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('initial notification prompt does not request exact alarm access',
      () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return {
        'notificationsAllowed': true,
        'exactAlarmsAllowed': false,
      };
    });

    final result = await ReminderSchedulerService(prefs)
        .ensureInitialNotificationPromptOnce();

    expect(result.notificationsAllowed, isTrue);
    expect(result.exactAlarmsAllowed, isFalse);
    expect(calls, hasLength(1));
    expect(calls.single.method, 'requestPermissions');
    expect(
      calls.single.arguments,
      containsPair('requestExactAlarm', false),
    );
  });

  test('user reminder scheduling can request exact alarm access', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return {
        'notificationsAllowed': true,
        'exactAlarmsAllowed': true,
      };
    });

    final result = await ReminderSchedulerService(prefs)
        .ensureSchedulingPermissionsForUserAction();

    expect(result.notificationsAllowed, isTrue);
    expect(result.exactAlarmsAllowed, isTrue);
    expect(calls, hasLength(1));
    expect(calls.single.method, 'requestPermissions');
    expect(
      calls.single.arguments,
      containsPair('requestExactAlarm', true),
    );
  });
}
