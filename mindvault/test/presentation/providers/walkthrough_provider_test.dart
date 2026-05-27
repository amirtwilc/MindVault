import 'package:flutter_test/flutter_test.dart';
import 'package:mindvault/presentation/providers/shared_preferences_provider.dart';
import 'package:mindvault/presentation/providers/walkthrough_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  ProviderContainer makeContainer(SharedPreferences prefs) {
    return ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
    ]);
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('shows automatically when walkthrough has not completed', () async {
    final prefs = await SharedPreferences.getInstance();
    final container = makeContainer(prefs);
    addTearDown(container.dispose);

    final state = container.read(walkthroughProvider);

    expect(state.isVisible, isTrue);
    expect(state.isManual, isFalse);
  });

  test('stays hidden when walkthrough has completed', () async {
    SharedPreferences.setMockInitialValues({
      walkthroughCompletedPrefsKey: true,
    });
    final prefs = await SharedPreferences.getInstance();
    final container = makeContainer(prefs);
    addTearDown(container.dispose);

    final state = container.read(walkthroughProvider);

    expect(state.isVisible, isFalse);
  });

  test('complete persists completion and hides walkthrough', () async {
    final prefs = await SharedPreferences.getInstance();
    final container = makeContainer(prefs);
    addTearDown(container.dispose);

    await container.read(walkthroughProvider.notifier).complete();

    expect(container.read(walkthroughProvider).isVisible, isFalse);
    expect(prefs.getBool(walkthroughCompletedPrefsKey), isTrue);
  });

  test('skip persists completion and hides walkthrough', () async {
    final prefs = await SharedPreferences.getInstance();
    final container = makeContainer(prefs);
    addTearDown(container.dispose);

    await container.read(walkthroughProvider.notifier).skip();

    expect(container.read(walkthroughProvider).isVisible, isFalse);
    expect(prefs.getBool(walkthroughCompletedPrefsKey), isTrue);
  });

  test('manual replay shows without clearing completed flag', () async {
    SharedPreferences.setMockInitialValues({
      walkthroughCompletedPrefsKey: true,
    });
    final prefs = await SharedPreferences.getInstance();
    final container = makeContainer(prefs);
    addTearDown(container.dispose);

    await container.read(walkthroughProvider.notifier).startManual();

    final state = container.read(walkthroughProvider);
    expect(state.isVisible, isTrue);
    expect(state.isManual, isTrue);
    expect(prefs.getBool(walkthroughCompletedPrefsKey), isTrue);
  });
}
