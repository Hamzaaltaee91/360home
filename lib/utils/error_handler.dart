import 'package:supabase_flutter/supabase_flutter.dart';

/// Standardized error handling for Supabase and application errors.
///
/// Converts low-level exceptions into user-friendly messages so the UI can
/// display consistent feedback without leaking implementation details.
class AppException implements Exception {
  const AppException(this.message, {this.code, this.cause});

  /// User-friendly message safe to display in the UI.
  final String message;

  /// Optional machine-readable error code.
  final String? code;

  /// The original error that triggered this exception, if any.
  final Object? cause;

  @override
  String toString() => 'AppException($code): $message';
}

/// Centralizes translation of errors into [AppException]s.
class SupabaseErrorHandler {
  const SupabaseErrorHandler._();

  /// Converts an arbitrary [error] into a user-friendly [AppException].
  static AppException handle(Object error, [StackTrace? stackTrace]) {
    if (error is AppException) {
      return error;
    }

    if (error is AuthException) {
      return AppException(
        _authMessage(error),
        code: error.statusCode,
        cause: error,
      );
    }

    if (error is PostgrestException) {
      return AppException(
        _postgrestMessage(error),
        code: error.code,
        cause: error,
      );
    }

    if (error is StorageException) {
      return AppException(
        error.message.isNotEmpty
            ? error.message
            : 'حدث خطأ أثناء التعامل مع الملف، يرجى المحاولة مرة أخرى',
        code: error.statusCode,
        cause: error,
      );
    }

    return AppException(
      'حدث خطأ غير متوقع، يرجى المحاولة مرة أخرى',
      cause: error,
    );
  }

  static String _authMessage(AuthException error) {
    final message = error.message.toLowerCase();
    if (message.contains('invalid login credentials')) {
      return 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
    }
    if (message.contains('email not confirmed')) {
      return 'يرجى تأكيد البريد الإلكتروني أولاً';
    }
    if (message.contains('user already registered')) {
      return 'يوجد حساب مسجل بهذا البريد الإلكتروني بالفعل';
    }
    if (message.contains('password')) {
      return 'كلمة المرور لا تستوفي المتطلبات';
    }
    return error.message.isNotEmpty
        ? error.message
        : 'فشلت عملية المصادقة، يرجى المحاولة مرة أخرى';
  }

  static String _postgrestMessage(PostgrestException error) {
    switch (error.code) {
      case '23505':
        return 'هذا السجل موجود بالفعل';
      case '23503':
        return 'السجل المرتبط غير موجود';
      case '42501':
        return 'ليس لديك صلاحية لتنفيذ هذا الإجراء';
      case 'PGRST116':
        return 'لم يتم العثور على البيانات المطلوبة';
      default:
        return error.message.isNotEmpty
            ? error.message
            : 'حدث خطأ في قاعدة البيانات، يرجى المحاولة مرة أخرى';
    }
  }
}
