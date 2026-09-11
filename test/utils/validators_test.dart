import 'package:dabberli/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validators.email', () {
    test('returns null for valid emails', () {
      expect(Validators.email('user@example.com'), isNull);
      expect(Validators.email('first.last+tag@sub.domain.co'), isNull);
    });

    test('rejects empty and malformed emails', () {
      expect(Validators.email(null), isNotNull);
      expect(Validators.email(''), isNotNull);
      expect(Validators.email('not-an-email'), isNotNull);
      expect(Validators.email('user@'), isNotNull);
    });
  });

  group('Validators.phone', () {
    test('returns null for valid phone numbers', () {
      expect(Validators.phone('+1234567890'), isNull);
      expect(Validators.phone('(123) 456-7890'), isNull);
    });

    test('rejects empty and malformed phone numbers', () {
      expect(Validators.phone(null), isNotNull);
      expect(Validators.phone(''), isNotNull);
      expect(Validators.phone('abc'), isNotNull);
      expect(Validators.phone('123'), isNotNull);
    });
  });

  group('Validators.price', () {
    test('returns null for valid prices', () {
      expect(Validators.price('100'), isNull);
      expect(Validators.price('99.99'), isNull);
    });

    test('enforces bounds', () {
      expect(Validators.price('50', min: 100), isNotNull);
      expect(Validators.price('500', max: 100), isNotNull);
      expect(Validators.price('150', min: 100, max: 200), isNull);
    });

    test('rejects empty, non-numeric, and negative values', () {
      expect(Validators.price(null), isNotNull);
      expect(Validators.price(''), isNotNull);
      expect(Validators.price('abc'), isNotNull);
      expect(Validators.price('-5'), isNotNull);
    });
  });

  group('Validators.required', () {
    test('returns null for non-empty values', () {
      expect(Validators.required('value'), isNull);
    });

    test('rejects null and blank values', () {
      expect(Validators.required(null), isNotNull);
      expect(Validators.required('   '), isNotNull);
    });
  });

  group('Validators.password', () {
    test('returns null for strong passwords', () {
      expect(Validators.password('supersecret'), isNull);
    });

    test('rejects short passwords', () {
      expect(Validators.password('short'), isNotNull);
      expect(Validators.password(null), isNotNull);
    });
  });
}
