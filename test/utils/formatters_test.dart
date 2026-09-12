import 'package:dabberli/utils/formatters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Formatters.formatPrice', () {
    test('returns empty string for null', () {
      expect(Formatters.formatPrice(null), '');
    });

    test('formats zero', () {
      expect(Formatters.formatPrice(0), '0');
    });

    test('formats small integers without separators', () {
      expect(Formatters.formatPrice(999), '999');
    });

    test('adds thousands separators', () {
      expect(Formatters.formatPrice(1500000), '1,500,000');
    });

    test('formats doubles by rounding to whole numbers', () {
      expect(Formatters.formatPrice(1234.56), '1,235');
    });
  });
}
