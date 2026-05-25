import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindvault/core/constants/jot_constants.dart';
import 'package:mindvault/l10n/app_localizations.dart';
import 'package:mindvault/presentation/providers/encryption_provider.dart';
import 'package:mindvault/presentation/screens/widget/widget_jot_compose_screen.dart';

Widget _host() {
  return ProviderScope(
    overrides: [
      aesKeyProvider.overrideWith((_) => enc.Key.fromLength(32)),
    ],
    child: MaterialApp(
      localizationsDelegates: AppStrings.localizationsDelegates,
      supportedLocales: AppStrings.supportedLocales,
      home: const WidgetJotComposeScreen(),
    ),
  );
}

void main() {
  testWidgets('shows character counter only from 50 chars',
      (WidgetTester tester) async {
    await tester.pumpWidget(_host());
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'a' * 49);
    await tester.pump();
    expect(find.text('49/100 characters'), findsNothing);

    await tester.enterText(find.byType(TextField), 'a' * 50);
    await tester.pump();
    expect(find.text('50/100 characters'), findsOneWidget);
  });

  testWidgets('enforces 100 char max and colors the full counter red',
      (WidgetTester tester) async {
    await tester.pumpWidget(_host());
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'a' * 120);
    await tester.pump();

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text.length, equals(JotConstants.maxChars));

    final counter = tester.widget<Text>(find.text('100/100 characters'));
    final error =
        Theme.of(tester.element(find.byType(TextField))).colorScheme.error;
    expect(counter.style?.color, equals(error));
  });

  testWidgets('uses an auto-growing focused text field',
      (WidgetTester tester) async {
    await tester.pumpWidget(_host());
    await tester.pump();

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.autofocus, isTrue);
    expect(field.minLines, equals(1));
    expect(field.maxLines, isNull);
    expect(field.keyboardType, equals(TextInputType.multiline));
  });
}
