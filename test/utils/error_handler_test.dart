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

    test('falls back to a generic message for unknown errors', () {
      expect(
        SupabaseErrorHandler.handle(Exception('boom')).message,
        'حدث خطأ غير متوقع، يرجى المحاولة مرة أخرى',
      );
    });
  });
}
