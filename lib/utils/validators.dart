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

  /// Evaluates password strength on a 0–4 scale.
  ///
  /// A point is awarded for each of: length >= 8, length >= 12, containing
  /// a letter and a digit, and containing a symbol. Returns 0 for an empty
  /// password.
  static int passwordStrength(String? value) {
    final password = value ?? '';
    if (password.isEmpty) {
      return 0;
    }

    var score = 0;
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    if (RegExp(r'[A-Za-z]').hasMatch(password) &&
        RegExp(r'[0-9]').hasMatch(password)) {
      score++;
    }
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(password)) {
      score++;
    }
    return score;
  }

  /// Human-readable label for a [passwordStrength] score.
  static String passwordStrengthLabel(int score) {
    switch (score) {
      case 0:
      case 1:
        return 'ضعيفة';
      case 2:
        return 'متوسطة';
      case 3:
        return 'جيدة';
      default:
        return 'قوية';
    }
  }
}
