import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindvault/domain/entities/category.dart';
import 'package:mindvault/domain/entities/note.dart';
import 'package:mindvault/domain/entities/tier_limits.dart';
import 'package:mindvault/l10n/app_localizations.dart';
import 'package:mindvault/presentation/providers/auth_provider.dart';
import 'package:mindvault/presentation/providers/categories_provider.dart';
import 'package:mindvault/presentation/providers/jots_provider.dart';
import 'package:mindvault/presentation/providers/locale_provider.dart';
import 'package:mindvault/presentation/providers/notes_provider.dart';
import 'package:mindvault/presentation/providers/shared_preferences_provider.dart';
import 'package:mindvault/presentation/providers/tier_provider.dart';
import 'package:mindvault/presentation/providers/walkthrough_provider.dart';
import 'package:mindvault/presentation/screens/home/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeCategoriesNotifier extends CategoriesNotifier {
  @override
  Future<List<Category>> build() async => const [];
}

Widget _harness(ProviderContainer container) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppStrings.localizationsDelegates,
      supportedLocales: AppStrings.supportedLocales,
      home: const SettingsScreen(),
    ),
  );
}

void main() {
  testWidgets('replay walkthrough tile starts manual walkthrough',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      walkthroughCompletedPrefsKey: true,
    });
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      currentUserProvider.overrideWithValue(null),
      tierProvider.overrideWith((ref) async => TierLimits.free()),
      aiSearchesTodayProvider.overrideWith((ref) async => 0),
      jotsAiUsageTodayProvider.overrideWith((ref) async => 0),
      allNotesProvider.overrideWith((ref) => Stream.value(const <Note>[])),
      categoriesProvider.overrideWith(_FakeCategoriesNotifier.new),
      localeProvider.overrideWith((ref) => LocaleNotifier(prefs)),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(_harness(container));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Replay walkthrough'),
      300,
      scrollable: find.byType(Scrollable),
    );

    await tester.tap(find.text('Replay walkthrough'));
    await tester.pumpAndSettle();

    final state = container.read(walkthroughProvider);
    expect(state.isVisible, isTrue);
    expect(state.isManual, isTrue);
  });
}
