// Payment Service

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/subscription.dart';
import '../utils/error_handler.dart';
import 'supabase_service.dart';

/// A selectable subscription plan offered to realtors.
class SubscriptionPlan {
  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.price,
    required this.currency,
    required this.interval,
    this.features = const [],
  });

  final String id;
  final String name;
  final double price;
  final String currency;
  final String interval; // 'month', 'year'
  final List<String> features;
}

class PaymentService {
  PaymentService({SupabaseService? supabaseService})
      : _supabase = supabaseService ?? SupabaseService();

  final SupabaseService _supabase;

  SupabaseClient get _client => _supabase.client;

  /// The plans available for purchase.
  static const List<SubscriptionPlan> plans = [
    SubscriptionPlan(
      id: 'basic',
      name: 'الأساسية',
      price: 99,
      currency: 'AED',
      interval: 'month',
      features: ['عروض غير محدودة', 'دعم عبر البريد الإلكتروني'],
    ),
    SubscriptionPlan(
      id: 'pro',
      name: 'الاحترافية',
      price: 249,
      currency: 'AED',
      interval: 'month',
      features: [
        'عروض غير محدودة',
        'ظهور مميز في نتائج البحث',
        'تحليلات متقدمة',
        'دعم ذو أولوية',
      ],
    ),
  ];

  /// Runs [action], translating any thrown error into a standardized
  /// [AppException] with a user-friendly message.
  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (error) {
      throw SupabaseErrorHandler.handle(error);
    }
  }

  String _requireUserId() {
    final userId = _supabase.getCurrentUserId();
    if (userId == null) throw const AppException('المستخدم غير مسجل دخول');
    return userId;
  }

  /// Returns the current user's subscription, or `null` if none exists.
  Future<Subscription?> getCurrentSubscription() {
    return _guard(() async {
      final userId = _requireUserId();

      final response = await _client
          .from('subscriptions')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return null;
      return Subscription.fromJson(response);
    });
  }

  /// Starts a checkout session for [planId] and returns the payment URL the
  /// user should be redirected to.
  Future<String> createCheckoutSession({
    required String planId,
    required String successUrl,
    required String cancelUrl,
  }) {
    return _guard(() async {
      final userId = _requireUserId();

      final response = await _client.functions.invoke(
        'create-checkout',
        body: {
          'user_id': userId,
          'plan_id': planId,
          'success_url': successUrl,
          'cancel_url': cancelUrl,
        },
      );

      final url = (response.data as Map<String, dynamic>)['url'] as String?;
      if (url == null) {
        throw const AppException('تعذّر إنشاء جلسة الدفع');
      }
      return url;
    });
  }

  /// Cancels the current subscription at the end of the billing period.
  Future<void> cancelSubscription() {
    return _guard(() async {
      final userId = _requireUserId();

      await _client
          .from('subscriptions')
          .update({'cancel_at_period_end': true}).eq('user_id', userId);
    });
  }

  /// Reverses a pending cancellation, keeping the subscription active.
  Future<void> resumeSubscription() {
    return _guard(() async {
      final userId = _requireUserId();

      await _client
          .from('subscriptions')
          .update({'cancel_at_period_end': false}).eq('user_id', userId);
    });
  }

  /// Whether the current user has an active paid subscription.
  Future<bool> hasActiveSubscription() {
    return _guard(() async {
      final subscription = await getCurrentSubscription();
      return subscription?.isActive ?? false;
    });
  }
}
