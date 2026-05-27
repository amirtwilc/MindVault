import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindvault/l10n/app_localizations.dart';
import 'package:mindvault/presentation/providers/reminder_provider.dart';
import 'package:mindvault/presentation/providers/shared_preferences_provider.dart';
import 'package:mindvault/presentation/providers/walkthrough_provider.dart';
import 'package:mindvault/presentation/widgets/app_walkthrough_overlay.dart';
import 'package:mindvault/services/reminder_scheduler_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeReminderScheduler extends ReminderSchedulerService {
  int notificationRequests = 0;
  int backgroundMarks = 0;
  int backgroundOpens = 0;
  bool? requestedExactAlarm;

  @override
  Future<ReminderPermissionResult> requestPermissions({
    required bool requestExactAlarm,
  }) async {
    notificationRequests++;
    requestedExactAlarm = requestExactAlarm;
    return const ReminderPermissionResult(
      notificationsAllowed: true,
      exactAlarmsAllowed: true,
    );
  }

  @override
  Future<void> markBackgroundPermissionPromptDone() async {
    backgroundMarks++;
  }

  @override
  Future<bool> openBackgroundPermissionSettings() async {
    backgroundOpens++;
    return true;
  }
}

class _Harness {
  final ProviderContainer container;
  final _FakeReminderScheduler scheduler;
  final List<int> navigations;

  _Harness(this.container, this.scheduler, this.navigations);
}

Future<_Harness> _pumpHarness(
  WidgetTester tester, {
  Locale locale = const Locale('en'),
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(walkthroughCompletedPrefsKey, false);
  final scheduler = _FakeReminderScheduler();
  final navigations = <int>[];
  final keys = {
    WalkthroughTarget.archive: GlobalKey(),
    WalkthroughTarget.sparks: GlobalKey(),
    WalkthroughTarget.clusters: GlobalKey(),
    WalkthroughTarget.recall: GlobalKey(),
  };
  final container = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    reminderSchedulerProvider.overrideWithValue(scheduler),
  ]);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      key: UniqueKey(),
      container: container,
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppStrings.localizationsDelegates,
        supportedLocales: AppStrings.supportedLocales,
        home: Scaffold(
          body: Stack(
            children: [
              Positioned(
                left: 8,
                bottom: 8,
                child: SizedBox(
                  key: keys[WalkthroughTarget.archive],
                  width: 80,
                  height: 48,
                ),
              ),
              Positioned(
                left: 96,
                bottom: 8,
                child: SizedBox(
                  key: keys[WalkthroughTarget.sparks],
                  width: 80,
                  height: 48,
                ),
              ),
              Positioned(
                left: 184,
                bottom: 8,
                child: SizedBox(
                  key: keys[WalkthroughTarget.clusters],
                  width: 80,
                  height: 48,
                ),
              ),
              Positioned(
                left: 272,
                bottom: 8,
                child: SizedBox(
                  key: keys[WalkthroughTarget.recall],
                  width: 80,
                  height: 48,
                ),
              ),
              AppWalkthroughOverlay(
                targetKeys: keys,
                onNavigateToSection: navigations.add,
              ),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  addTearDown(container.dispose);
  return _Harness(container, scheduler, navigations);
}

Future<void> _advanceToStep(WidgetTester tester, int step) async {
  if (step >= 1) {
    await tester.tap(find.text('Allow notifications'));
    await tester.pumpAndSettle();
  }
  if (step >= 2) {
    await tester.tap(find.text('Open settings'));
    await tester.pumpAndSettle();
  }
  for (var current = 2; current < step; current++) {
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
  }
}

void main() {
  for (var step = 0; step < 7; step++) {
    testWidgets('skip hides and completes from step $step', (tester) async {
      final harness = await _pumpHarness(tester);
      await _advanceToStep(tester, step);

      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      expect(harness.container.read(walkthroughProvider).isVisible, isFalse);
      expect(find.text('Skip'), findsNothing);
    });
  }

  testWidgets('notification button requests notification permission only',
      (tester) async {
    final harness = await _pumpHarness(tester);

    await tester.tap(find.text('Allow notifications'));
    await tester.pumpAndSettle();

    expect(harness.scheduler.notificationRequests, 1);
    expect(harness.scheduler.requestedExactAlarm, isFalse);
    expect(find.text('Keep reminders reliable'), findsOneWidget);
    expect(find.text('Open settings'), findsOneWidget);
  });

  testWidgets('background settings button marks prompt and opens settings',
      (tester) async {
    final harness = await _pumpHarness(tester);
    await _advanceToStep(tester, 1);

    await tester.tap(find.text('Open settings'));
    await tester.pumpAndSettle();

    expect(harness.scheduler.backgroundMarks, 1);
    expect(harness.scheduler.backgroundOpens, 1);
    expect(find.text('Archive'), findsOneWidget);
    expect(find.text('3 / 7'), findsOneWidget);
  });

  testWidgets(
      'background settings later button advances without opening settings',
      (tester) async {
    final harness = await _pumpHarness(tester);
    await _advanceToStep(tester, 1);

    await tester.tap(find.text('I will do this later'));
    await tester.pumpAndSettle();

    expect(harness.scheduler.backgroundMarks, 0);
    expect(harness.scheduler.backgroundOpens, 0);
    expect(find.text('Archive'), findsOneWidget);
    expect(find.text('3 / 7'), findsOneWidget);
  });

  testWidgets('coach mark steps navigate through the expected sections',
      (tester) async {
    final harness = await _pumpHarness(tester);

    await _advanceToStep(tester, 6);

    expect(harness.navigations, [0, 2, 3, 1]);
  });

  testWidgets('done returns to archive, completes, and hides the walkthrough',
      (tester) async {
    final harness = await _pumpHarness(tester);
    await _advanceToStep(tester, 6);

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(harness.navigations.last, 0);
    expect(harness.container.read(walkthroughProvider).isVisible, isFalse);
    expect(find.text('Done'), findsNothing);
  });

  testWidgets('manual replay restarts from the first step', (tester) async {
    final harness = await _pumpHarness(tester);
    await _advanceToStep(tester, 6);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    await harness.container.read(walkthroughProvider.notifier).startManual();
    await tester.pumpAndSettle();

    expect(find.text('1 / 7'), findsOneWidget);
    expect(find.text('Allow notifications'), findsOneWidget);
  });

  testWidgets('action buttons fit in a narrow translated layout',
      (tester) async {
    tester.view.physicalSize = const Size(300, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpHarness(tester, locale: const Locale('hi'));
    await tester.tap(find.text('सूचनाएं अनुमति दें'));
    await tester.pumpAndSettle();

    expect(find.text('सेटिंग खोलें'), findsOneWidget);
    expect(find.text('मैं यह बाद में करूंगा'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
