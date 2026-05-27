import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindvault/l10n/app_localizations.dart';
import 'package:mindvault/presentation/widgets/memory_help_dialog.dart';

Widget _harness() {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppStrings.localizationsDelegates,
    supportedLocales: AppStrings.supportedLocales,
    home: Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: ElevatedButton(
            onPressed: () => showMemoryHelpDialog(context),
            child: const Text('Open help'),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('shows all memory feature explanations', (tester) async {
    await tester.pumpWidget(_harness());
    await tester.tap(find.text('Open help'));
    await tester.pumpAndSettle();

    expect(find.text('Memory features'), findsOneWidget);
    expect(find.text('Record'), findsOneWidget);
    expect(find.text('Copy'), findsOneWidget);
    expect(find.text('Reminder'), findsOneWidget);
    expect(find.text('Lock'), findsOneWidget);
    expect(find.text('Cluster'), findsOneWidget);
    expect(find.text('Type'), findsOneWidget);
    expect(find.text('Title'), findsOneWidget);
    expect(
      find.text('Use voice recording to dictate into the title or body.'),
      findsOneWidget,
    );
    expect(
      find.text('Copy the memory body to the clipboard.'),
      findsOneWidget,
    );
    expect(
      find.text('Set an alert for this memory; notifications must be allowed.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    expect(find.text('Memory features'), findsNothing);
  });
}
