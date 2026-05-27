import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'shared_preferences_provider.dart';

const walkthroughCompletedPrefsKey = 'app_walkthrough.completed.v1';

class WalkthroughState {
  final bool isVisible;
  final bool isManual;

  const WalkthroughState({
    required this.isVisible,
    required this.isManual,
  });

  const WalkthroughState.hidden()
      : isVisible = false,
        isManual = false;

  const WalkthroughState.visible({required this.isManual}) : isVisible = true;
}

class WalkthroughNotifier extends StateNotifier<WalkthroughState> {
  WalkthroughNotifier(this._prefs)
      : super(
          _prefs.getBool(walkthroughCompletedPrefsKey) == true
              ? const WalkthroughState.hidden()
              : const WalkthroughState.visible(isManual: false),
        );

  final SharedPreferences _prefs;

  Future<void> startManual() async {
    state = const WalkthroughState.visible(isManual: true);
  }

  Future<void> complete() async {
    await _prefs.setBool(walkthroughCompletedPrefsKey, true);
    state = const WalkthroughState.hidden();
  }

  Future<void> skip() => complete();
}

final walkthroughProvider =
    StateNotifierProvider<WalkthroughNotifier, WalkthroughState>((ref) {
  return WalkthroughNotifier(ref.watch(sharedPreferencesProvider));
});
