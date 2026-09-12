// Analytics Service

import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/error_handler.dart';
import 'supabase_service.dart';

/// Aggregated performance metrics for a realtor.
class RealtorStats {
  const RealtorStats({
    required this.totalOffers,
    required this.acceptedOffers,
    required this.rejectedOffers,
    required this.pendingOffers,
    required this.averageResponseTime,
    required this.totalInteractions,
  });

  final int totalOffers;
  final int acceptedOffers;
  final int rejectedOffers;
  final int pendingOffers;

  /// Average time to respond, in hours.
  final double averageResponseTime;
  final int totalInteractions;

  factory RealtorStats.fromJson(Map<String, dynamic> json) {
    return RealtorStats(
      totalOffers: json['total_offers'] as int? ?? 0,
      acceptedOffers: json['accepted_offers'] as int? ?? 0,
      rejectedOffers: json['rejected_offers'] as int? ?? 0,
      pendingOffers: json['pending_offers'] as int? ?? 0,
      averageResponseTime:
          (json['average_response_time'] as num?)?.toDouble() ?? 0,
      totalInteractions: json['total_interactions'] as int? ?? 0,
    );
  }
}

/// Aggregated activity metrics for a buyer.
class BuyerStats {
  const BuyerStats({
    required this.totalRequests,
    required this.activeRequests,
    required this.totalOffersReceived,
    required this.totalOffersAccepted,
    required this.responseRate,
  });

  final int totalRequests;
  final int activeRequests;
  final int totalOffersReceived;
  final int totalOffersAccepted;

  /// Percentage of offers the buyer responded to (0-100).
  final double responseRate;

  factory BuyerStats.fromJson(Map<String, dynamic> json) {
    return BuyerStats(
      totalRequests: json['total_requests'] as int? ?? 0,
      activeRequests: json['active_requests'] as int? ?? 0,
      totalOffersReceived: json['total_offers_received'] as int? ?? 0,
      totalOffersAccepted: json['total_offers_accepted'] as int? ?? 0,
      responseRate: (json['response_rate'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Platform-wide metrics for a given period.
class PlatformStats {
  const PlatformStats({
    required this.periodFrom,
    required this.periodTo,
    required this.newUsersTotal,
    required this.newUsersBuyers,
    required this.newUsersRealtors,
    required this.propertyRequests,
    required this.realtorOffers,
    required this.offerAcceptanceRate,
    required this.averageOffersPerRequest,
  });

  final String periodFrom;
  final String periodTo;
  final int newUsersTotal;
  final int newUsersBuyers;
  final int newUsersRealtors;
  final int propertyRequests;
  final int realtorOffers;

  /// Percentage of offers accepted (0-100).
  final double offerAcceptanceRate;
  final double averageOffersPerRequest;

  factory PlatformStats.fromJson(Map<String, dynamic> json) {
    final period = json['period'] as Map<String, dynamic>? ?? const {};
    final newUsers = json['new_users'] as Map<String, dynamic>? ?? const {};

    return PlatformStats(
      periodFrom: period['from'] as String? ?? '',
      periodTo: period['to'] as String? ?? '',
      newUsersTotal: newUsers['total'] as int? ?? 0,
      newUsersBuyers: newUsers['buyers'] as int? ?? 0,
      newUsersRealtors: newUsers['realtors'] as int? ?? 0,
      propertyRequests: json['property_requests'] as int? ?? 0,
      realtorOffers: json['realtor_offers'] as int? ?? 0,
      offerAcceptanceRate:
          (json['offer_acceptance_rate'] as num?)?.toDouble() ?? 0,
      averageOffersPerRequest:
          (json['average_offers_per_request'] as num?)?.toDouble() ?? 0,
    );
  }
}

class AnalyticsService {
  AnalyticsService({SupabaseService? supabaseService})
      : _supabase = supabaseService ?? SupabaseService();

  final SupabaseService _supabase;

  SupabaseClient get _client => _supabase.client;

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

  /// Fetches performance metrics for the current realtor.
  Future<RealtorStats> getRealtorStats({
    DateTime? dateFrom,
    DateTime? dateTo,
  }) {
    return _guard(() async {
      final userId = _requireUserId();

      final response = await _client.functions.invoke(
        'analytics',
        body: {
          'type': 'realtor',
          'user_id': userId,
          if (dateFrom != null) 'date_from': dateFrom.toIso8601String(),
          if (dateTo != null) 'date_to': dateTo.toIso8601String(),
        },
      );

      return RealtorStats.fromJson(response.data as Map<String, dynamic>);
    });
  }

  /// Fetches activity metrics for the current buyer.
  Future<BuyerStats> getBuyerStats({
    DateTime? dateFrom,
    DateTime? dateTo,
  }) {
    return _guard(() async {
      final userId = _requireUserId();

      final response = await _client.functions.invoke(
        'analytics',
        body: {
          'type': 'buyer',
          'user_id': userId,
          if (dateFrom != null) 'date_from': dateFrom.toIso8601String(),
          if (dateTo != null) 'date_to': dateTo.toIso8601String(),
        },
      );

      return BuyerStats.fromJson(response.data as Map<String, dynamic>);
    });
  }

  /// Fetches platform-wide metrics for the given period.
  Future<PlatformStats> getPlatformStats({
    DateTime? dateFrom,
    DateTime? dateTo,
  }) {
    return _guard(() async {
      final response = await _client.functions.invoke(
        'analytics',
        body: {
          'type': 'platform',
          if (dateFrom != null) 'date_from': dateFrom.toIso8601String(),
          if (dateTo != null) 'date_to': dateTo.toIso8601String(),
        },
      );

      return PlatformStats.fromJson(response.data as Map<String, dynamic>);
    });
  }
}
