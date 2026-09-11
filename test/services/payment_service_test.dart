import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:dabberli/services/payment_service.dart';
import 'package:dabberli/utils/error_handler.dart';

import 'test_helpers.dart';

void main() {
  late MockSupabaseService supabaseService;
  late MockSupabaseClient client;
  late PaymentService service;

  setUpAll(registerServiceFallbacks);

  setUp(() {
    supabaseService = MockSupabaseService();
    client = MockSupabaseClient();
    when(() => supabaseService.client).thenReturn(client);
    service = PaymentService(supabaseService: supabaseService);
  });

  group('plans', () {
    test('exposes the basic and pro plans', () {
      expect(
        PaymentService.plans.map((p) => p.id),
        containsAll(['basic', 'pro']),
      );
    });
  });

  group('getCurrentSubscription', () {
    test('throws AppException when the user is not signed in', () async {
      when(() => supabaseService.getCurrentUserId()).thenReturn(null);

      expect(
        () => service.getCurrentSubscription(),
        throwsA(isA<AppException>()),
      );
    });

    test('returns null when no subscription exists', () async {
      when(() => supabaseService.getCurrentUserId()).thenReturn('user-1');

      final query = MockSupabaseQueryBuilder();
      final filter = MockPostgrestFilterBuilder<Map<String, dynamic>?>();

      when(() => client.from('subscriptions')).thenAnswer((_) => query);
      when(() => query.select()).thenAnswer((_) => filter);
      when(() => filter.eq(any(), any())).thenAnswer((_) => filter);
      when(() => filter.maybeSingle()).thenAnswer((_) async => null);

      expect(await service.getCurrentSubscription(), isNull);
    });

    test('maps a row into a Subscription model', () async {
      when(() => supabaseService.getCurrentUserId()).thenReturn('user-1');

      final query = MockSupabaseQueryBuilder();
      final filter = MockPostgrestFilterBuilder<Map<String, dynamic>?>();

      when(() => client.from('subscriptions')).thenAnswer((_) => query);
      when(() => query.select()).thenAnswer((_) => filter);
      when(() => filter.eq(any(), any())).thenAnswer((_) => filter);
      when(() => filter.maybeSingle()).thenAnswer((_) async => {
            'id': 's1',
            'realtor_id': 'user-1',
            'plan': 'pro',
            'status': 'active',
            'cancel_at_period_end': false,
            'created_at': '2024-01-01T00:00:00.000Z',
            'updated_at': '2024-01-01T00:00:00.000Z',
          });

      final subscription = await service.getCurrentSubscription();

      expect(subscription, isNotNull);
      expect(subscription!.plan, 'pro');
    });
  });

  group('createCheckoutSession', () {
    test('returns the checkout url from the function response', () async {
      when(() => supabaseService.getCurrentUserId()).thenReturn('user-1');

      final functions = MockFunctionsClient();
      when(() => client.functions).thenReturn(functions);
      when(
        () => functions.invoke('create-checkout', body: any(named: 'body')),
      ).thenAnswer((_) async => {'url': 'https://pay.example.com/session'});

      final url = await service.createCheckoutSession(
        planId: 'pro',
        successUrl: 'https://app.example.com/success',
        cancelUrl: 'https://app.example.com/cancel',
      );

      expect(url, 'https://pay.example.com/session');
    });

    test('throws AppException when the response has no url', () async {
      when(() => supabaseService.getCurrentUserId()).thenReturn('user-1');

      final functions = MockFunctionsClient();
      when(() => client.functions).thenReturn(functions);
      when(
        () => functions.invoke('create-checkout', body: any(named: 'body')),
      ).thenAnswer((_) async => <String, dynamic>{});

      expect(
        () => service.createCheckoutSession(
          planId: 'pro',
          successUrl: 'https://app.example.com/success',
          cancelUrl: 'https://app.example.com/cancel',
        ),
        throwsA(isA<AppException>()),
      );
    });
  });

  group('cancelSubscription', () {
    test('sets cancel_at_period_end to true', () async {
      when(() => supabaseService.getCurrentUserId()).thenReturn('user-1');

      final query = MockSupabaseQueryBuilder();
      final filter = MockPostgrestFilterBuilder<dynamic>();

      when(() => client.from('subscriptions')).thenAnswer((_) => query);
      when(() => query.update(any())).thenAnswer((_) => filter);
      when(() => filter.eq(any(), any())).thenAnswer((_) async => null);

      await service.cancelSubscription();

      verify(() => query.update({'cancel_at_period_end': true})).called(1);
    });
  });

  group('hasActiveSubscription', () {
    test('returns false when there is no subscription', () async {
      when(() => supabaseService.getCurrentUserId()).thenReturn('user-1');

      final query = MockSupabaseQueryBuilder();
      final filter = MockPostgrestFilterBuilder<Map<String, dynamic>?>();

      when(() => client.from('subscriptions')).thenAnswer((_) => query);
      when(() => query.select()).thenAnswer((_) => filter);
      when(() => filter.eq(any(), any())).thenAnswer((_) => filter);
      when(() => filter.maybeSingle()).thenAnswer((_) async => null);

      expect(await service.hasActiveSubscription(), isFalse);
    });
  });
}
