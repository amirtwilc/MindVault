import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindvault/presentation/providers/ai_search_provider.dart';
import 'package:mindvault/presentation/providers/locale_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  ProviderContainer makeContainer(SharedPreferences prefs) {
    return ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
    ]);
  }

  test('returns null when no locale stored', () async {
    final prefs = await SharedPreferences.getInstance();
    final container = makeContainer(prefs);
    addTearDown(container.dispose);

    expect(container.read(localeProvider), isNull);
  });

  test('reads stored locale on init', () async {
    SharedPreferences.setMockInitialValues({'app_locale': 'he'});
    final prefs = await SharedPreferences.getInstance();
    final container = makeContainer(prefs);
    addTearDown(container.dispose);

    expect(container.read(localeProvider), const Locale('he'));
  });

  test('setLocale persists and updates state', () async {
    final prefs = await SharedPreferences.getInstance();
    final container = makeContainer(prefs);
    addTearDown(container.dispose);

    await container.read(localeProvider.notifier).setLocale(const Locale('de'));

    expect(container.read(localeProvider), const Locale('de'));
    expect(prefs.getString('app_locale'), 'de');
  });

  test('setLocale(null) clears stored value', () async {
    SharedPreferences.setMockInitialValues({'app_locale': 'he'});
    final prefs = await SharedPreferences.getInstance();
    final container = makeContainer(prefs);
    addTearDown(container.dispose);

    await container.read(localeProvider.notifier).setLocale(null);

    expect(container.read(localeProvider), isNull);
    expect(prefs.containsKey('app_locale'), isFalse);
  });
}
