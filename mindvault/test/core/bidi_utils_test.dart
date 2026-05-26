import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindvault/core/utils/bidi_utils.dart';

void main() {
  group('firstStrongOf', () {
    test('returns ltr for English text', () {
      expect(firstStrongOf('hello world'), TextDirection.ltr);
    });

    test('returns rtl for Hebrew text', () {
      expect(firstStrongOf('שלום עולם'), TextDirection.rtl);
    });

    test('returns rtl for Arabic text', () {
      expect(firstStrongOf('مرحبا بالعالم'), TextDirection.rtl);
    });

    test('returns ltr for German text with umlauts', () {
      expect(firstStrongOf('Über alles'), TextDirection.ltr);
    });

    test('returns null for empty string', () {
      expect(firstStrongOf(''), isNull);
    });

    test('returns null for digits-only', () {
      expect(firstStrongOf('123 456'), isNull);
    });

    test('returns null for punctuation-only', () {
      expect(firstStrongOf('... !! ??'), isNull);
    });

    test('skips leading digits and uses the first strong char', () {
      expect(firstStrongOf('123 שלום'), TextDirection.rtl);
      expect(firstStrongOf('123 hello'), TextDirection.ltr);
    });
  });

  group('paragraphDirectionAt', () {
    test('empty text returns localeDefault', () {
      expect(
        paragraphDirectionAt(
            text: '', cursor: 0, localeDefault: TextDirection.rtl),
        TextDirection.rtl,
      );
    });

    test('uses cursor paragraph first strong char', () {
      const text = 'hello\nשלום';
      expect(
        paragraphDirectionAt(
            text: text, cursor: 8, localeDefault: TextDirection.ltr),
        TextDirection.rtl,
      );
      expect(
        paragraphDirectionAt(
            text: text, cursor: 2, localeDefault: TextDirection.rtl),
        TextDirection.ltr,
      );
    });

    test('inherits previous paragraph direction when current is empty', () {
      const text = 'שלום\n';
      expect(
        paragraphDirectionAt(
            text: text, cursor: text.length, localeDefault: TextDirection.ltr),
        TextDirection.rtl,
      );
    });

    test('inherits across multiple empty paragraphs', () {
      const text = 'hello\n\n\n';
      expect(
        paragraphDirectionAt(
            text: text, cursor: text.length, localeDefault: TextDirection.rtl),
        TextDirection.ltr,
      );
    });

    test('falls back to localeDefault when no strong char anywhere', () {
      expect(
        paragraphDirectionAt(
            text: '123\n456', cursor: 5, localeDefault: TextDirection.rtl),
        TextDirection.rtl,
      );
    });

    test('cursor at start of empty first paragraph uses locale default', () {
      expect(
        paragraphDirectionAt(
            text: '\nhello', cursor: 0, localeDefault: TextDirection.rtl),
        TextDirection.rtl,
      );
    });

    test('cursor clamps when out of range', () {
      expect(
        paragraphDirectionAt(
            text: 'hello', cursor: 999, localeDefault: TextDirection.rtl),
        TextDirection.ltr,
      );
    });
  });

  group('lockedBodyDirection', () {
    test('empty body returns localeDefault', () {
      expect(lockedBodyDirection('', TextDirection.rtl), TextDirection.rtl);
      expect(lockedBodyDirection('', TextDirection.ltr), TextDirection.ltr);
    });

    test('Hebrew first strong char returns rtl regardless of locale', () {
      expect(lockedBodyDirection('שלום עולם', TextDirection.ltr),
          TextDirection.rtl);
    });

    test('English first strong char returns ltr regardless of locale', () {
      expect(lockedBodyDirection('hello world', TextDirection.rtl),
          TextDirection.ltr);
    });

    test('digits-only body falls back to localeDefault', () {
      expect(
          lockedBodyDirection('123 456', TextDirection.rtl), TextDirection.rtl);
      expect(
          lockedBodyDirection('123 456', TextDirection.ltr), TextDirection.ltr);
    });

    test('first strong char wins even when later paragraphs differ', () {
      // The whole-body lock looks at the very first strong char, not per
      // paragraph — that's the deliberate trade-off for working selection.
      expect(lockedBodyDirection('hello\nשלום', TextDirection.rtl),
          TextDirection.ltr);
      expect(lockedBodyDirection('שלום\nhello', TextDirection.ltr),
          TextDirection.rtl);
    });
  });
}
