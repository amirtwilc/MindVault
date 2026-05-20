import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindvault/l10n/app_localizations.dart';
import 'package:mindvault/presentation/widgets/checklist_note_view.dart';

Widget _harness(
  Widget child, {
  Locale locale = const Locale('en'),
  TextDirection direction = TextDirection.ltr,
}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppStrings.localizationsDelegates,
    supportedLocales: AppStrings.supportedLocales,
    home: Directionality(
      textDirection: direction,
      child: Scaffold(body: child),
    ),
  );
}

void main() {
  testWidgets('shows remove done tasks when a single item is completed',
      (tester) async {
    var removed = false;
    await tester.pumpWidget(_harness(ChecklistNoteView(
      rows: [
        ChecklistRowData(id: 'done', text: 'Done task', isCompleted: true),
      ],
      isEditing: false,
      onRowsChanged: (_) {},
      onRemoveCompleted: () async => removed = true,
    )));

    expect(find.text('Remove done tasks'), findsOneWidget);
    await tester.tap(find.text('Remove done tasks'));
    await tester.pump();
    expect(removed, isTrue);
  });

  testWidgets('places the checkbox on the right for RTL checklist text',
      (tester) async {
    await tester.pumpWidget(_harness(ChecklistNoteView(
      rows: [
        ChecklistRowData(id: 'rtl', text: 'שלום', isCompleted: false),
      ],
      isEditing: false,
      onRowsChanged: (_) {},
    )));

    final rowBox = tester.renderObject<RenderBox>(
      find
          .ancestor(
            of: find.text('שלום'),
            matching: find.byType(Row),
          )
          .first,
    );
    final checkboxBox = tester.renderObject<RenderBox>(find.byType(Checkbox));
    final textBox = tester.renderObject<RenderBox>(find.text('שלום'));
    final rowOrigin = rowBox.localToGlobal(Offset.zero);
    final checkboxOrigin = checkboxBox.localToGlobal(Offset.zero);
    final textOrigin = textBox.localToGlobal(Offset.zero);

    expect(checkboxOrigin.dx - rowOrigin.dx,
        greaterThan(textOrigin.dx - rowOrigin.dx));
  });

  testWidgets('enter on a non-empty draft creates and focuses the next row',
      (tester) async {
    var rows = [ChecklistRowData(id: null, text: '', isCompleted: false)];

    await tester.pumpWidget(_harness(StatefulBuilder(
      builder: (context, setState) => ChecklistNoteView(
        rows: rows,
        isEditing: true,
        onRowsChanged: (next) => setState(() => rows = next),
      ),
    )));

    await tester.enterText(find.byType(TextField).first, 'First');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(rows.map((row) => row.text), equals(['First', '']));
    expect(find.byType(TextField), findsNWidgets(2));
    final secondField = tester.widget<TextField>(find.byType(TextField).last);
    expect(secondField.focusNode?.hasFocus, isTrue);
  });

  testWidgets('keeps a focused draft row stable when the parent rebuilds',
      (tester) async {
    final row = ChecklistRowData(id: null, text: '', isCompleted: false);
    var rows = [row];
    var rebuildToken = 0;

    await tester.pumpWidget(_harness(StatefulBuilder(
      builder: (context, setState) => Column(
        children: [
          TextButton(
            onPressed: () => setState(() => rebuildToken++),
            child: Text('rebuild $rebuildToken'),
          ),
          ChecklistNoteView(
            rows: rows,
            isEditing: true,
            onRowsChanged: (next) => setState(() => rows = next),
          ),
        ],
      ),
    )));

    await tester.enterText(find.byType(TextField), 'Task');
    await tester.tap(find.textContaining('rebuild'));
    await tester.pumpAndSettle();

    expect(rows.single.localId, row.localId);
    expect(rows.single.text, 'Task');
    expect(find.text('Task'), findsOneWidget);
  });
}
