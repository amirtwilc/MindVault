import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindvault/core/constants/category_colors.dart';

void main() {
  group('categoryColor', () {
    test('returns default blue-grey for null', () {
      expect(categoryColor(null), equals(const Color(0xFF78909C)));
    });

    test('returns default blue-grey for empty string', () {
      expect(categoryColor(''), equals(const Color(0xFF78909C)));
    });

    test('parses a valid 7-char hex string', () {
      expect(categoryColor('#EF5350'), equals(const Color(0xFFEF5350)));
    });

    test('parses all colors in kCategoryColors without throwing', () {
      for (final hex in kCategoryColors) {
        expect(() => categoryColor(hex), returnsNormally);
      }
    });

    test('parsed color has full opacity', () {
      final c = categoryColor('#42A5F5');
      expect(c.alpha, equals(255));
    });
  });

  group('categoryTextColor', () {
    test('returns white on dark background', () {
      // #EF5350 red — luminance ~0.21 → white text
      final bg = categoryColor('#EF5350');
      expect(categoryTextColor(bg), equals(Colors.white));
    });

    test('returns black on light/bright background', () {
      // #FFCA28 amber — luminance ~0.56 → black text
      final bg = categoryColor('#FFCA28');
      expect(categoryTextColor(bg), equals(Colors.black87));
    });

    test('returns black on white', () {
      expect(categoryTextColor(Colors.white), equals(Colors.black87));
    });

    test('returns white on black', () {
      expect(categoryTextColor(Colors.black), equals(Colors.white));
    });

    test('luminance threshold is 0.45', () {
      // A color with luminance just above 0.45 → black text
      const slightlyAbove = Color(0xFFAAAAAA); // grey ~0.40 luminance
      final result = categoryTextColor(slightlyAbove);
      expect(
        result,
        slightlyAbove.computeLuminance() > 0.45 ? Colors.black87 : Colors.white,
      );
    });
  });
}
