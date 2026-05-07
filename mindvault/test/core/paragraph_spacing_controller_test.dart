import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindvault/core/utils/paragraph_spacing_controller.dart';

// The controller's only observable behaviour is the [TextSpan] tree it
// produces from buildTextSpan / buildReadSpan. We assert structural
// properties on that tree — not exact heights or pixel layouts — because
// the actual sizes are font-dependent and brittle. The behaviours we
// guarantee:
//
//   - Paragraph-start characters get an elevated `height`.
//   - Soft-wrapped (no `\n`) text gets the base height.
//   - A trailing `\n` (cursor sits on a fresh empty line) still has SOME
//     span carrying the elevated height — without this the empty line
//     looks visually identical to a soft-wrapped continuation.
//   - The total visible-text length of the rendered tree never exceeds
//     the controller's `text` length, so cursor offsets within the
//     editable string remain consistent.

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Recursively flattens the span tree to a list of (text, height) pairs,
  // skipping spans that have no text (e.g. children-only wrappers).
  List<({String text, double? height})> _flatten(InlineSpan span) {
    final out = <({String text, double? height})>[];
    span.visitChildren((s) {
      if (s is TextSpan && s.text != null && s.text!.isNotEmpty) {
        out.add((text: s.text!, height: s.style?.height));
      }
      return true;
    });
    return out;
  }

  // Sums the lengths of every text-bearing span — what Flutter actually
  // renders. For cursor stability inside `text` this must be `>= text.length`
  // and any extra characters must come strictly after text.length (only
  // legal at the very end).
  int _renderedLength(InlineSpan span) =>
      _flatten(span).fold(0, (n, e) => n + e.text.length);

  TextSpan _buildSpan(ParagraphSpacingController ctrl) {
    return ctrl.buildTextSpan(
      context: _MinimalBuildContext(),
      style: const TextStyle(),
      withComposing: false,
    );
  }

  group('ParagraphSpacingController', () {
    test('plain text has no elevated spans', () {
      final ctrl = ParagraphSpacingController(text: 'hello world');
      final flat = _flatten(_buildSpan(ctrl));
      expect(flat.length, 1);
      expect(flat.first.text, 'hello world');
      // No heights other than the base 1.0.
      expect(flat.every((e) => e.height == 1.0 || e.height == null), isTrue);
    });

    test('paragraph-start char after \\n is elevated', () {
      final ctrl = ParagraphSpacingController(text: 'first\nsecond');
      final flat = _flatten(_buildSpan(ctrl));
      // Find the span whose text starts the second paragraph ("s" of "second").
      final paraStartSpan =
          flat.firstWhere((e) => e.text == 's', orElse: () => (text: '', height: null));
      expect(paraStartSpan.height, isNotNull);
      expect(paraStartSpan.height! > 1.0, isTrue,
          reason: 'first char of new paragraph should be elevated');
    });

    test('trailing \\n produces a span with elevated height (empty cursor line)',
        () {
      final ctrl = ParagraphSpacingController(text: 'hello\n');
      final flat = _flatten(_buildSpan(ctrl));
      final hasElevated = flat.any((e) => (e.height ?? 0) > 1.0);
      expect(hasElevated, isTrue,
          reason:
              'an empty trailing line must carry the paragraph height so the '
              'cursor sits with a real paragraph gap, not a single line gap');
    });

    test('trailing \\n does not change rendered length below text length', () {
      final ctrl = ParagraphSpacingController(text: 'hello\n');
      final span = _buildSpan(ctrl);
      // Any extra phantom characters are only allowed AFTER the editable text.
      // The invariant we care about is that selection offsets within `text`
      // map to the same characters in the rendered output.
      expect(_renderedLength(span) >= ctrl.text.length, isTrue);
      // First text.length characters of the render must equal ctrl.text.
      final flat = _flatten(span);
      final buf = StringBuffer();
      for (final s in flat) {
        if (buf.length >= ctrl.text.length) break;
        final remaining = ctrl.text.length - buf.length;
        buf.write(s.text.substring(0, s.text.length.clamp(0, remaining)));
      }
      expect(buf.toString(), ctrl.text);
    });

    test('empty paragraph mid-text also gets elevated', () {
      // "foo\n\nbar" — there are two paragraph breaks. The empty line
      // between foo and bar should carry the paragraph height (via the
      // second `\n` itself), and "b" of "bar" should also carry it.
      final ctrl = ParagraphSpacingController(text: 'foo\n\nbar');
      final flat = _flatten(_buildSpan(ctrl));
      // "b" of "bar" should be elevated.
      final bSpan =
          flat.firstWhere((e) => e.text == 'b', orElse: () => (text: '', height: null));
      expect(bSpan.height, isNotNull);
      expect(bSpan.height! > 1.0, isTrue);
      // At least one elevated `\n` should exist (the empty paragraph's own).
      final elevatedNewline =
          flat.any((e) => e.text == '\n' && (e.height ?? 0) > 1.0);
      expect(elevatedNewline, isTrue);
    });

    test('buildReadSpan is consistent with buildTextSpan for plain content',
        () {
      const text = 'one\ntwo\nthree';
      final readSpan = ParagraphSpacingController.buildReadSpan(
          text, const TextStyle(fontSize: 16));
      final ctrl = ParagraphSpacingController(text: text);
      final editSpan = _buildSpan(ctrl);
      // Both must render the same logical text content (no trailing \n means
      // no ZWS appended, so they match exactly).
      final readChars = _flatten(readSpan).map((e) => e.text).join();
      final editChars = _flatten(editSpan).map((e) => e.text).join();
      expect(readChars, editChars);
    });

    test('empty text returns an empty span', () {
      final ctrl = ParagraphSpacingController(text: '');
      final flat = _flatten(_buildSpan(ctrl));
      expect(flat, isEmpty);
    });
  });

  // The view-mode renderer must give us BOTH per-paragraph direction AND
  // cross-paragraph drag-selection (so users can copy multiple lines at once).
  // It used to use SelectableText per paragraph, which broke selection
  // chaining — these tests guard the SelectionArea + plain-Text approach.
  group('buildBidiAwareView', () {
    Widget harness(Widget child, {TextDirection ambient = TextDirection.ltr}) {
      return MaterialApp(
        home: Directionality(
          textDirection: ambient,
          child: Scaffold(body: child),
        ),
      );
    }

    testWidgets('wraps the rendered column in a SelectionArea', (tester) async {
      final view = ParagraphSpacingController.buildBidiAwareView(
        'hello\nworld',
        const TextStyle(fontSize: 14),
        TextDirection.ltr,
      );
      await tester.pumpWidget(harness(view));

      expect(find.byType(SelectionArea), findsOneWidget);
      // SelectableText would create its own selection scope and break the
      // SelectionArea chain — must not be present.
      expect(find.byType(SelectableText), findsNothing);
      expect(find.text('hello'), findsOneWidget);
      expect(find.text('world'), findsOneWidget);
    });

    testWidgets('per-paragraph Directionality matches first strong char',
        (tester) async {
      final view = ParagraphSpacingController.buildBidiAwareView(
        'hello\nשלום',
        const TextStyle(fontSize: 14),
        TextDirection.ltr,
      );
      await tester.pumpWidget(harness(view));

      final ltrDir = tester.widget<Directionality>(
        find
            .ancestor(
              of: find.text('hello'),
              matching: find.byType(Directionality),
            )
            .first,
      );
      final rtlDir = tester.widget<Directionality>(
        find
            .ancestor(
              of: find.text('שלום'),
              matching: find.byType(Directionality),
            )
            .first,
      );

      expect(ltrDir.textDirection, TextDirection.ltr);
      expect(rtlDir.textDirection, TextDirection.rtl);
    });

    testWidgets('mixed-direction body still renders inside one SelectionArea',
        (tester) async {
      final view = ParagraphSpacingController.buildBidiAwareView(
        'hello\nשלום\nworld',
        const TextStyle(fontSize: 14),
        TextDirection.ltr,
      );
      await tester.pumpWidget(harness(view));

      // Single SelectionArea must own all three paragraphs.
      expect(find.byType(SelectionArea), findsOneWidget);
      expect(find.text('hello'), findsOneWidget);
      expect(find.text('שלום'), findsOneWidget);
      expect(find.text('world'), findsOneWidget);
    });
  });
}

class _MinimalBuildContext implements BuildContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
