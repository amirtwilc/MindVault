import 'package:flutter_test/flutter_test.dart';
import 'package:mindvault/core/utils/note_preview.dart';

void main() {
  group('NotePreview.displayTitle', () {
    test('returns stored title when non-empty', () {
      expect(NotePreview.displayTitle('My Title', 'some body'), 'My Title');
    });

    test('derives from body when stored title is empty', () {
      expect(NotePreview.displayTitle('', 'Hello world this is my note'),
          'Hello world this is');
    });

    test('returns empty string when both are empty', () {
      expect(NotePreview.displayTitle('', ''), '');
    });

    test('derives only up to 4 tokens', () {
      expect(NotePreview.displayTitle('', 'a'), 'a');
      expect(NotePreview.displayTitle('', 'a b'), 'a b');
      expect(NotePreview.displayTitle('', 'a b c d e'), 'a b c d');
    });
  });

  group('NotePreview.previewBody', () {
    test('returns full body when stored title is non-empty', () {
      expect(
        NotePreview.previewBody('My Title', 'line one\nline two'),
        'line one\nline two',
      );
    });

    test('returns empty string when body is empty', () {
      expect(NotePreview.previewBody('', ''), '');
    });

    // Spec table: first line has 4 tokens → preview is second line
    test('first line ≤4 tokens: preview is rest after first line', () {
      expect(NotePreview.previewBody('', 'This is my 1\nrule'), 'rule');
    });

    // Spec table: first line has 3 tokens
    test('first line 3 tokens with more lines', () {
      expect(NotePreview.previewBody('', '?! is my\n1\nrule'), '1\nrule');
    });

    // Spec table: first line ≤4 tokens, whitespace-only middle line
    test('first line ≤4 tokens: skips whitespace-only middle line', () {
      expect(NotePreview.previewBody('', 'This is\n     \nmy rule'), 'my rule');
    });

    // Spec table: first line 1 token, empty line, then content
    test('first line 1 token: skips empty line, shows next content', () {
      expect(NotePreview.previewBody('', 'a\n\nb'), 'b');
    });

    // Spec table: first line >4 tokens → tail of first line is preview start
    test('first line >4 tokens: preview starts from token 5', () {
      expect(
        NotePreview.previewBody('', 'This is a long story\nAnd it continues'),
        'story\nAnd it continues',
      );
    });

    // Spec example d: single long line, no second line
    test('first line >4 tokens, no subsequent lines: preview is tail only', () {
      expect(
        NotePreview.previewBody('', 'This is a really long story'),
        'long story',
      );
    });

    test('first line exactly 4 tokens, no subsequent lines: preview is empty',
        () {
      expect(NotePreview.previewBody('', 'This is my title'), '');
    });

    test('first line 1 token, no subsequent lines: preview is empty', () {
      expect(NotePreview.previewBody('', 'alone'), '');
    });

    test('multiple empty lines between content lines are all stripped', () {
      expect(NotePreview.previewBody('', 'hello\n\n\nworld'), 'world');
    });

    // Spec preview table row 1: 6-token first line
    test('6-token first line: preview = remaining of first line + second line',
        () {
      expect(
        NotePreview.previewBody(
            '', 'My first ever note in MindVault\nThis is working'),
        'in MindVault\nThis is working',
      );
    });

    // Spec preview table row 2: first line ≤4 tokens, second line has content
    test('first line ≤4 tokens: entire first line is title, second is preview',
        () {
      expect(
        NotePreview.previewBody('', 'My first\never note in MindVault'),
        'ever note in MindVault',
      );
    });
  });
}
