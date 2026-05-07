import 'package:flutter_test/flutter_test.dart';
import 'package:mindvault/core/utils/auto_title_generator.dart';

void main() {
  group('AutoTitleGenerator.fromBody', () {
    test('takes first 4 words of a longer line', () {
      final result = AutoTitleGenerator.fromBody(
          'one two three four five six seven');
      expect(result, equals('one two three four'));
    });

    test('returns the single word if line has only one', () {
      expect(AutoTitleGenerator.fromBody('alone'), equals('alone'));
    });

    test('skips leading empty lines', () {
      expect(
        AutoTitleGenerator.fromBody('\n\n  \nfirst real line here'),
        equals('first real line here'),
      );
    });

    test('returns at most 4 words even when line is short', () {
      expect(AutoTitleGenerator.fromBody('two words'), equals('two words'));
    });

    test('only the first non-empty paragraph is used', () {
      final result = AutoTitleGenerator.fromBody(
          'first paragraph here\n\nsecond paragraph also exists');
      expect(result, equals('first paragraph here'));
    });

    test('handles Hebrew first line by counting whitespace tokens', () {
      final result = AutoTitleGenerator.fromBody('שלום עולם זוהי בדיקה נוספת');
      expect(result, equals('שלום עולם זוהי בדיקה'));
    });

    test('returns empty string when body is whitespace-only', () {
      expect(AutoTitleGenerator.fromBody('   \n\t\n  '), equals(''));
    });

    test('collapses multiple spaces to single in output', () {
      expect(
        AutoTitleGenerator.fromBody('hello   world   from    test'),
        equals('hello world from test'),
      );
    });
  });
}
