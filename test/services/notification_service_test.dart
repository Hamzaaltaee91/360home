import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:dabberli/services/notification_service.dart';
import 'package:dabberli/utils/error_handler.dart';

import 'test_helpers.dart';

void main() {
  late MockSupabaseService supabaseService;
  late MockSupabaseClient client;
  late NotificationService service;

  setUpAll(registerServiceFallbacks);

  setUp(() {
    supabaseService = MockSupabaseService();
    client = MockSupabaseClient();
    when(() => supabaseService.client).thenReturn(client);
    service = NotificationService(supabaseService: supabaseService);
  });

  group('getNotifications', () {
    test('throws AppException when the user is not signed in', () async {
      when(() => supabaseService.getCurrentUserId()).thenReturn(null);

      expect(
        () => service.getNotifications(),
        throwsA(isA<AppException>()),
      );
    });

    test('maps rows into Notification models', () async {
      when(() => supabaseService.getCurrentUserId()).thenReturn('user-1');

      final query = MockSupabaseQueryBuilder();
      final filter = MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();
      final ordered =
          MockPostgrestTransformBuilder<List<Map<String, dynamic>>>();

      when(() => client.from('notifications')).thenAnswer((_) => query);
      when(() => query.select()).thenAnswer((_) => filter);
      when(() => filter.eq(any(), any())).thenAnswer((_) => filter);
      when(() => filter.order(any(), ascending: any(named: 'ascending')))
          .thenAnswer((_) => ordered);
      when(() => ordered.range(any(), any())).thenAnswer((_) async => [
            {
              'id': 'n1',
              'user_id': 'user-1',
              'type': 'offer_received',
              'title': 'عرض جديد',
              'body': 'وصلك عرض جديد',
              'data': {'offer_id': 'o1'},
              'is_read': false,
              'created_at': '2024-01-01T00:00:00.000Z',
            },
          ]);

      final result = await service.getNotifications();

      expect(result.items, hasLength(1));
      expect(result.items.first.id, 'n1');
      expect(result.items.first.isRead, isFalse);
      expect(result.hasMore, isFalse);
    });

    test('translates PostgrestException into AppException', () async {
      when(() => supabaseService.getCurrentUserId()).thenReturn('user-1');

      final query = MockSupabaseQueryBuilder();
      when(() => client.from('notifications')).thenAnswer((_) => query);
      when(() => query.select()).thenThrow(
        const PostgrestException(message: 'boom', code: '42501'),
      );

      expect(
        () => service.getNotifications(),
        throwsA(
          isA<AppException>().having(
            (e) => e.message,
            'message',
            'ليس لديك صلاحية لتنفيذ هذا الإجراء',
          ),
        ),
      );
    });
  });

  group('getUnreadCount', () {
    test('returns the count from the response', () async {
      when(() => supabaseService.getCurrentUserId()).thenReturn('user-1');

      final query = MockSupabaseQueryBuilder();
      final filter = MockPostgrestFilterBuilder<PostgrestResponse<dynamic>>();

      when(() => client.from('notifications')).thenAnswer((_) => query);
      when(() => query.select('id')).thenAnswer((_) => filter);
      when(() => filter.eq(any(), any())).thenAnswer((_) => filter);
      when(() => filter.count()).thenAnswer(
        (_) async => PostgrestResponse<dynamic>([], count: 3),
      );

      expect(await service.getUnreadCount(), 3);
    });
  });

  group('markAsRead', () {
    test('updates the notification row', () async {
      final query = MockSupabaseQueryBuilder();
      final filter = MockPostgrestFilterBuilder<dynamic>();

      when(() => client.from('notifications')).thenAnswer((_) => query);
      when(() => query.update(any())).thenAnswer((_) => filter);
      when(() => filter.eq(any(), any())).thenAnswer((_) async => null);

      await service.markAsRead('n1');

      verify(() => query.update({'is_read': true})).called(1);
    });
  });

  group('markAllAsRead', () {
    test('throws AppException when the user is not signed in', () async {
      when(() => supabaseService.getCurrentUserId()).thenReturn(null);

      expect(
        () => service.markAllAsRead(),
        throwsA(isA<AppException>()),
      );
    });
  });
}
