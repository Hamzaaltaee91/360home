/// Centralized input validation helpers.
///
/// Each validator returns `null` when the value is valid, or a
/// user-friendly error message when it is not. This makes them drop-in
/// compatible with Flutter's `TextFormField.validator` signature.
class Validators {
  const Validators._();

  static final RegExp _emailRegExp = RegExp(
    r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$',
  );

  /// Matches international phone numbers with an optional leading `+`
  /// followed by 7 to 15 digits. Spaces, dashes, and parentheses are allowed.
  static final RegExp _phoneRegExp = RegExp(
    r'^\+?[0-9][0-9\s\-()]{6,18}[0-9]$',
  );

  /// Validates an email address.
  static String? email(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Email is required';
    }
    if (!_emailRegExp.hasMatch(trimmed)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  /// Validates a phone number.
  static String? phone(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Phone number is required';
    }
    if (!_phoneRegExp.hasMatch(trimmed)) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  /// Validates a price value.
  ///
  /// [min] and [max] are optional inclusive bounds.
  static String? price(String? value, {num? min, num? max}) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Price is required';
    }

    final parsed = num.tryParse(trimmed);
    if (parsed == null) {
      return 'Enter a valid price';
    }
    if (parsed < 0) {
      return 'Price cannot be negative';
    }
    if (min != null && parsed < min) {
      return 'Price must be at least $min';
    }
    if (max != null && parsed > max) {
      return 'Price must be at most $max';
    }
    return null;
  }

  /// Validates that a value is not null or empty.
  static String? required(String? value, {String field = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$field is required';
    }
    return null;
  }

  /// Validates a password meets minimum strength requirements.
  static String? password(String? value, {int minLength = 8}) {
    final trimmed = value ?? '';
    if (trimmed.isEmpty) {
      return 'Password is required';
    }
    if (trimmed.length < minLength) {
      return 'Password must be at least $minLength characters';
    }
    return null;
  }
}
