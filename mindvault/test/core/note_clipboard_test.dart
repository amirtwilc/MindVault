import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindvault/core/utils/note_clipboard.dart';
import 'package:mindvault/l10n/app_localizations.dart';

/// Captures Clipboard.setData calls made through the platform channel so we
/// can assert what was copied without depending on a real platform clipboard.
class _ClipboardCapture {
  String? lastText;

  void install() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        lastText = (call.arguments as Map)['text'] as String?;
      }
      if (call.method == 'Clipboard.getData') {
        return <String, dynamic>{'text': lastText ?? ''};
      }
      return null;
    });
  }

  void reset() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  }
}

Widget _harness(void Function(BuildContext) onPress) {
  return MaterialApp(
    localizationsDelegates: AppStrings.localizationsDelegates,
    supportedLocales: AppStrings.supportedLocales,
    locale: const Locale('en'),
    home: Scaffold(
      body: Builder(
        builder: (ctx) => Center(
          child: ElevatedButton(
            onPressed: () => onPress(ctx),
            child: const Text('go'),
          ),
        ),
      ),
    ),
  );
}

void main() {
  late _ClipboardCapture clip;

  setUp(() {
    clip = _ClipboardCapture()..install();
  });

  tearDown(() => clip.reset());

  testWidgets('copies body to system clipboard', (tester) async {
    await tester.pumpWidget(_harness((ctx) => copyNoteBody(ctx, 'line one\nline two')));
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();
    expect(clip.lastText, 'line one\nline two');
  });

  testWidgets('shows confirmation snackbar after copying', (tester) async {
    await tester.pumpWidget(_harness((ctx) => copyNoteBody(ctx, 'hello')));
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump(); // start the snackbar animation
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Note copied'), findsOneWidget);
  });

  testWidgets('no-op when body is empty', (tester) async {
    await tester.pumpWidget(_harness((ctx) => copyNoteBody(ctx, '')));
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();
    expect(clip.lastText, isNull);
    expect(find.text('Note copied'), findsNothing);
  });
}
