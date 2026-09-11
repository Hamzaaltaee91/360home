import 'package:dabberli/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validators.email', () {
    test('returns null for valid emails', () {
      expect(Validators.email('user@example.com'), isNull);
      expect(Validators.email('first.last+tag@sub.domain.co'), isNull);
      expect(Validators.email('  spaced@example.com  '), isNull);
    });

    test('returns error for empty or null input', () {
      expect(Validators.email(null), 'Email is required');
      expect(Validators.email(''), 'Email is required');
      expect(Validators.email('   '), 'Email is required');
    });

    test('returns error for malformed emails', () {
      expect(Validators.email('not-an-email'), 'Enter a valid email address');
      expect(Validators.email('user@'), 'Enter a valid email address');
      expect(Validators.email('@example.com'), 'Enter a valid email address');
      expect(Validators.email('user@domain'), 'Enter a valid email address');
      expect(
        Validators.email('user name@example.com'),
        'Enter a valid email address',
      );
    });
  });

  group('Validators.phone', () {
    test('returns null for valid phone numbers', () {
      expect(Validators.phone('1234567'), isNull);
      expect(Validators.phone('+1234567890'), isNull);
      expect(Validators.phone('(123) 456-7890'), isNull);
      expect(Validators.phone('  123-456-7890  '), isNull);
    });

    test('returns error for empty or null input', () {
      expect(Validators.phone(null), 'Phone number is required');
      expect(Validators.phone(''), 'Phone number is required');
      expect(Validators.phone('   '), 'Phone number is required');
    });

    test('returns error for malformed phone numbers', () {
      expect(Validators.phone('abc'), 'Enter a valid phone number');
      expect(Validators.phone('123'), 'Enter a valid phone number');
      expect(Validators.phone('+'), 'Enter a valid phone number');
    });
  });

  group('Validators.price', () {
    test('returns null for valid prices', () {
      expect(Validators.price('100'), isNull);
      expect(Validators.price('0'), isNull);
      expect(Validators.price('99.99'), isNull);
      expect(Validators.price('  250  '), isNull);
    });

    test('returns error for empty or null input', () {
      expect(Validators.price(null), 'Price is required');
      expect(Validators.price(''), 'Price is required');
      expect(Validators.price('   '), 'Price is required');
    });

    test('returns error for non-numeric input', () {
      expect(Validators.price('abc'), 'Enter a valid price');
    });

    test('returns error for negative prices', () {
      expect(Validators.price('-5'), 'Price cannot be negative');
    });

    test('enforces inclusive bounds', () {
      expect(Validators.price('50', min: 100), 'Price must be at least 100');
      expect(Validators.price('500', max: 100), 'Price must be at most 100');
      expect(Validators.price('150', min: 100, max: 200), isNull);
      expect(Validators.price('100', min: 100, max: 100), isNull);
    });
  });

  group('Validators.required', () {
    test('returns null for non-empty values', () {
      expect(Validators.required('value'), isNull);
      expect(Validators.required('  value  '), isNull);
    });

    test('returns error for null and blank values', () {
      expect(Validators.required(null), 'This field is required');
      expect(Validators.required(''), 'This field is required');
      expect(Validators.required('   '), 'This field is required');
    });

    test('uses the provided field name', () {
      expect(Validators.required(null, field: 'Name'), 'Name is required');
    });
  });

  group('Validators.password', () {
    test('returns null for passwords meeting the minimum length', () {
      expect(Validators.password('supersecret'), isNull);
      expect(Validators.password('12345678'), isNull);
    });

    test('returns error for empty or null input', () {
      expect(Validators.password(null), 'Password is required');
      expect(Validators.password(''), 'Password is required');
    });

    test('returns error for passwords below the minimum length', () {
      expect(
        Validators.password('short'),
        'Password must be at least 8 characters',
      );
      expect(
        Validators.password('123', minLength: 4),
        'Password must be at least 4 characters',
      );
    });
  });

  group('Validators.passwordStrength', () {
    test('returns 0 for empty or null input', () {
      expect(Validators.passwordStrength(null), 0);
      expect(Validators.passwordStrength(''), 0);
    });

    test('scores based on length, character mix, and symbols', () {
      expect(Validators.passwordStrength('abc'), 0);
      expect(Validators.passwordStrength('abcdefgh'), 1);
      expect(Validators.passwordStrength('abcdefgh1234'), 3);
      expect(Validators.passwordStrength('abcdefgh1234!'), 4);
    });
  });

  group('Validators.passwordStrengthLabel', () {
    test('maps scores to human-readable labels', () {
      expect(Validators.passwordStrengthLabel(0), 'ضعيفة');
      expect(Validators.passwordStrengthLabel(1), 'ضعيفة');
      expect(Validators.passwordStrengthLabel(2), 'متوسطة');
      expect(Validators.passwordStrengthLabel(3), 'جيدة');
      expect(Validators.passwordStrengthLabel(4), 'قوية');
    });
  });
}
