import 'package:flutter_test/flutter_test.dart';
import 'package:mindvault/core/utils/id_generator.dart';

void main() {
  group('generateId', () {
    test('produces a string in UUID v4 format', () {
      final id = generateId();
      final uuidRegex = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      );
      expect(uuidRegex.hasMatch(id), isTrue, reason: 'Got: $id');
    });

    test('version nibble is 4', () {
      final id = generateId();
      // 3rd group starts with '4'
      expect(id.split('-')[2][0], equals('4'));
    });

    test('variant nibble is 8, 9, a, or b', () {
      final id = generateId();
      final variantChar = id.split('-')[3][0];
      expect(['8', '9', 'a', 'b'], contains(variantChar));
    });

    test('every call returns a unique id', () {
      final ids = List.generate(1000, (_) => generateId()).toSet();
      expect(ids.length, equals(1000));
    });

    test('id is lowercase hex with hyphens only', () {
      final id = generateId();
      expect(id.replaceAll('-', ''), matches(RegExp(r'^[0-9a-f]{32}$')));
    });
  });
}
