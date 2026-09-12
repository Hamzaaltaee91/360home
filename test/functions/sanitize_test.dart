import 'package:flutter_test/flutter_test.dart';

// NOTE: These tests exercise the pure sanitization helpers defined in
// `supabase/functions/_shared/sanitize.ts`. They are mirrored here as Dart
// tests to keep parity with the existing `rate_limit_test.dart` convention,
// which documents the expected behavior of the shared Edge Function helpers.

/// Dart mirror of `sanitizeString` from `_shared/sanitize.ts`.
String sanitizeString(Object? value, {int maxLength = 2000}) {
  if (value == null) return '';
  final raw = value.toString();
  final cleaned = raw
      .replaceAll(RegExp(r'[\u0000-\u0008\u000B\u000C\u000E-\u001F\u007F]'), '')
      .replaceAll(
        RegExp(
          r'<\s*\/?\s*(script|style|iframe|object|embed|link|meta)\b[^>]*>',
          caseSensitive: false,
        ),
        '',
      )
      .replaceAll(
        RegExp(r'\son[a-z]+\s*=\s*("[^"]*"|''[^'']*''|[^\s>]+)',
            caseSensitive: false),
        '',
      )
      .replaceAll(
        RegExp(r'(javascript|data|vbscript)\s*:', caseSensitive: false),
        '',
      )
      .replaceAll(RegExp(r'<\/?[a-z][^>]*>', caseSensitive: false), '')
      .trim();
  return cleaned.length > maxLength ? cleaned.substring(0, maxLength) : cleaned;
}

/// Dart mirror of `sanitizeUuid`.
String sanitizeUuid(Object? value) {
  final id = sanitizeString(value, maxLength: 64);
  final pattern = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  );
  return pattern.hasMatch(id) ? id.toLowerCase() : '';
}

/// Dart mirror of `sanitizeInt`.
int? sanitizeInt(Object? value, {int? min, int? max}) {
  final parsedNum = value is num ? value : double.tryParse(value?.toString() ?? '');
  if (parsedNum == null || !parsedNum.isFinite) return null;
  var result = parsedNum.truncate();
  if (min != null && result < min) result = min;
  if (max != null && result > max) result = max;
  return result;
}

void main() {
  group('sanitizeString', () {
    test('returns empty string for null/undefined', () {
      expect(sanitizeString(null), '');
    });

    test('trims whitespace', () {
      expect(sanitizeString('  hello  '), 'hello');
    });

    test('strips script tags', () {
      expect(
        sanitizeString('<script>alert(1)</script>hello'),
        'alert(1)hello',
      );
    });

    test('strips inline event handlers', () {
      expect(
        sanitizeString('<img src=x onerror=alert(1)>'),
        '',
      );
    });

    test('strips javascript: protocol', () {
      expect(
        sanitizeString('javascript:alert(1)'),
        'alert(1)',
      );
    });

    test('strips control characters', () {
      expect(sanitizeString('a\u0000b\u001Fc'), 'abc');
    });

    test('caps length', () {
      final long = 'a' * 3000;
      expect(sanitizeString(long).length, 2000);
      expect(sanitizeString(long, maxLength: 10).length, 10);
    });
  });

  group('sanitizeUuid', () {
    test('accepts valid uuid and lowercases it', () {
      expect(
        sanitizeUuid('A0EBC0DE-1234-4ABC-9DEF-0123456789AB'),
        'a0ebc0de-1234-4abc-9def-0123456789ab',
      );
    });

    test('rejects invalid uuid', () {
      expect(sanitizeUuid('not-a-uuid'), '');
      expect(sanitizeUuid(null), '');
    });
  });

  group('sanitizeInt', () {
    test('parses and clamps', () {
      expect(sanitizeInt('5', min: 1, max: 10), 5);
      expect(sanitizeInt('0', min: 1, max: 10), 1);
      expect(sanitizeInt('100', min: 1, max: 10), 10);
    });

    test('returns null for invalid input', () {
      expect(sanitizeInt('abc'), null);
      expect(sanitizeInt(null), null);
    });
  });
}
