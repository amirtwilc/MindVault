import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindvault/presentation/widgets/bidi_aware_text_field.dart';

Widget _harness({
  required TextEditingController controller,
  TextDirection ambient = TextDirection.ltr,
}) {
  return MaterialApp(
    home: Directionality(
      textDirection: ambient,
      child: Scaffold(
        body: BidiAwareTextField(controller: controller, maxLines: null),
      ),
    ),
  );
}

TextDirection _innerDirection(WidgetTester tester) {
  final field = tester.widget<TextField>(find.byType(TextField));
  return field.textDirection!;
}

void main() {
  testWidgets('uses ambient direction when text is empty', (tester) async {
    final ctrl = TextEditingController();
    await tester.pumpWidget(_harness(controller: ctrl, ambient: TextDirection.rtl));
    expect(_innerDirection(tester), TextDirection.rtl);
  });

  testWidgets('switches to RTL when first strong char is Hebrew', (tester) async {
    final ctrl = TextEditingController();
    await tester.pumpWidget(_harness(controller: ctrl, ambient: TextDirection.ltr));

    ctrl.value = const TextEditingValue(
      text: 'שלום',
      selection: TextSelection.collapsed(offset: 4),
    );
    await tester.pump();

    expect(_innerDirection(tester), TextDirection.rtl);
  });

  testWidgets('inherits previous paragraph direction on a fresh empty line',
      (tester) async {
    final ctrl = TextEditingController();
    await tester.pumpWidget(_harness(controller: ctrl, ambient: TextDirection.ltr));

    ctrl.value = const TextEditingValue(
      text: 'שלום\n',
      selection: TextSelection.collapsed(offset: 5),
    );
    await tester.pump();

    expect(_innerDirection(tester), TextDirection.rtl);
  });

  testWidgets('switches to LTR when typing English on a new line',
      (tester) async {
    final ctrl = TextEditingController();
    await tester.pumpWidget(_harness(controller: ctrl, ambient: TextDirection.ltr));

    ctrl.value = const TextEditingValue(
      text: 'שלום\nhello',
      selection: TextSelection.collapsed(offset: 10),
    );
    await tester.pump();

    expect(_innerDirection(tester), TextDirection.ltr);
  });
}
