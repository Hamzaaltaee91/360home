import 'package:dabberli/utils/error_handler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('SupabaseErrorHandler', () {
    test('returns the same AppException unchanged', () {
      const original = AppException('رسالة مخصصة');
      expect(SupabaseErrorHandler.handle(original), same(original));
    });

    test('maps invalid login credentials to a standard message', () {
      final error = AuthException('Invalid login credentials');
      final result = SupabaseErrorHandler.handle(error);
      expect(result.message, 'البريد الإلكتروني أو كلمة المرور غير صحيحة');
      expect(result.cause, same(error));
    });

    test('maps unconfirmed email to a standard message', () {
      final error = AuthException('Email not confirmed');
      expect(
        SupabaseErrorHandler.handle(error).message,
        'يرجى تأكيد البريد الإلكتروني أولاً',
      );
    });

    test('maps already registered email to a standard message', () {
      final error = AuthException('User already registered');
      expect(
        SupabaseErrorHandler.handle(error).message,
        'يوجد حساب مسجل بهذا البريد الإلكتروني بالفعل',
      );
    });

    test('maps password errors to a standard message', () {
      final error = AuthException('Password should be at least 6 characters');
      expect(
        SupabaseErrorHandler.handle(error).message,
        'كلمة المرور لا تستوفي المتطلبات',
      );
    });

    test('falls back to the original auth message when unrecognized', () {
      final error = AuthException('Something else went wrong');
      expect(
        SupabaseErrorHandler.handle(error).message,
        'Something else went wrong',
      );
    });

    test('falls back to a generic auth message when empty', () {
      final error = AuthException('');
      expect(
        SupabaseErrorHandler.handle(error).message,
        'فشلت عملية المصادقة، يرجى المحاولة مرة أخرى',
      );
    });

    test('maps duplicate key postgrest errors', () {
      final error = PostgrestException(message: 'duplicate', code: '23505');
      expect(SupabaseErrorHandler.handle(error).message, 'هذا السجل موجود بالفعل');
    });

    test('maps missing row postgrest errors', () {
      final error = PostgrestException(message: 'no rows', code: 'PGRST116');
      expect(
        SupabaseErrorHandler.handle(error).message,
        'لم يتم العثور على البيانات المطلوبة',
      );
    });

    test('maps foreign key postgrest errors', () {
      final error = PostgrestException(message: 'fk', code: '23503');
      expect(SupabaseErrorHandler.handle(error).message, 'السجل المرتبط غير موجود');
    });

    test('maps permission postgrest errors', () {
      final error = PostgrestException(message: 'denied', code: '42501');
      expect(
        SupabaseErrorHandler.handle(error).message,
        'ليس لديك صلاحية لتنفيذ هذا الإجراء',
      );
    });

    test('falls back to the original postgrest message when unrecognized', () {
      final error = PostgrestException(message: 'weird', code: 'XXXXX');
      expect(SupabaseErrorHandler.handle(error).message, 'weird');
    });

    test('falls back to a generic postgrest message when empty', () {
      final error = PostgrestException(message: '', code: 'XXXXX');
      expect(
        SupabaseErrorHandler.handle(error).message,
        'حدث خطأ في قاعدة البيانات، يرجى المحاولة مرة أخرى',
      );
    });

    test('maps storage errors using their message', () {
      final error = StorageException('Bucket not found');
      expect(SupabaseErrorHandler.handle(error).message, 'Bucket not found');
    });

    test('falls back to a generic storage message when empty', () {
      final error = StorageException('');
      expect(
        SupabaseErrorHandler.handle(error).message,
        'حدث خطأ أثناء التعامل مع الملف، يرجى المحاولة مرة أخرى',
      );
    });

    test('falls back to a generic message for unknown errors', () {
      expect(
        SupabaseErrorHandler.handle(Exception('boom')).message,
        'حدث خطأ غير متوقع، يرجى المحاولة مرة أخرى',
      );
    });

    test('preserves the original error as the cause', () {
      final error = Exception('boom');
      expect(SupabaseErrorHandler.handle(error).cause, same(error));
    });
  });

  group('AppException', () {
    test('exposes message, code, and cause', () {
      final cause = Exception('root');
      const exception = AppException('رسالة', code: 'E1', cause: null);
      expect(exception.message, 'رسالة');
      expect(exception.code, 'E1');
      expect(exception.cause, isNull);
      expect(AppException('x', cause: cause).cause, same(cause));
    });

    test('toString includes the code and message', () {
      const exception = AppException('رسالة', code: 'E1');
      expect(exception.toString(), 'AppException(E1): رسالة');
    });
  });
}
