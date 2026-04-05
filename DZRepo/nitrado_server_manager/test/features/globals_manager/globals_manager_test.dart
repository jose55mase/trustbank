import 'package:flutter_test/flutter_test.dart';
import 'package:nitrado_server_manager/features/globals_manager/globals_helpers.dart';

void main() {
  group('isValidNumericValue', () {
    test('accepts positive integers', () {
      expect(isValidNumericValue('42'), isTrue);
      expect(isValidNumericValue('0'), isTrue);
      expect(isValidNumericValue('1000'), isTrue);
    });

    test('accepts negative integers', () {
      expect(isValidNumericValue('-1'), isTrue);
      expect(isValidNumericValue('-100'), isTrue);
    });

    test('accepts positive decimals', () {
      expect(isValidNumericValue('3.14'), isTrue);
      expect(isValidNumericValue('0.82'), isTrue);
      expect(isValidNumericValue('0.0'), isTrue);
    });

    test('accepts negative decimals', () {
      expect(isValidNumericValue('-0.5'), isTrue);
      expect(isValidNumericValue('-3.14'), isTrue);
    });

    test('rejects empty string', () {
      expect(isValidNumericValue(''), isFalse);
    });

    test('rejects whitespace-only string', () {
      expect(isValidNumericValue('   '), isFalse);
    });

    test('rejects alphabetic strings', () {
      expect(isValidNumericValue('abc'), isFalse);
      expect(isValidNumericValue('hello'), isFalse);
    });

    test('rejects mixed alphanumeric strings', () {
      expect(isValidNumericValue('12abc'), isFalse);
      expect(isValidNumericValue('abc12'), isFalse);
    });

    test('rejects special characters', () {
      expect(isValidNumericValue('!@#'), isFalse);
      expect(isValidNumericValue('1,000'), isFalse);
    });

    test('rejects multiple dots', () {
      expect(isValidNumericValue('1.2.3'), isFalse);
    });

    test('rejects trailing dot', () {
      expect(isValidNumericValue('42.'), isFalse);
    });

    test('rejects leading dot', () {
      expect(isValidNumericValue('.5'), isFalse);
    });
  });
}
