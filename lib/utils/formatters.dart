import 'package:intl/intl.dart';

/// Centralized formatting helpers for prices, dates, and numbers.
///
/// These helpers keep presentation logic out of widgets and services so
/// that currency and date output stays consistent across the app.
class Formatters {
  const Formatters._();

  static final NumberFormat _priceFormat = NumberFormat('#,##0', 'en_US');

  /// Formats a numeric [value] as a price string with thousands separators.
  ///
  /// Example: `formatPrice(1500000)` returns `"1,500,000"`.
  /// Returns an empty string when [value] is null.
  static String formatPrice(num? value) {
    if (value == null) return '';
    return _priceFormat.format(value);
  }
}
