import 'package:flutter_test/flutter_test.dart';
import 'package:dabberli/services/analytics_service.dart';

void main() {
  group('RealtorStats', () {
    final json = {
      'total_offers': 10,
      'accepted_offers': 4,
      'rejected_offers': 3,
      'pending_offers': 3,
      'average_response_time': 2.5,
      'total_interactions': 7,
    };

    test('fromJson parses all fields', () {
      final stats = RealtorStats.fromJson(json);

      expect(stats.totalOffers, 10);
      expect(stats.acceptedOffers, 4);
      expect(stats.rejectedOffers, 3);
      expect(stats.pendingOffers, 3);
      expect(stats.averageResponseTime, 2.5);
      expect(stats.totalInteractions, 7);
    });

    test('fromJson defaults missing fields to zero', () {
      final stats = RealtorStats.fromJson(const {});

      expect(stats.totalOffers, 0);
      expect(stats.averageResponseTime, 0);
      expect(stats.totalInteractions, 0);
    });

    test('fromJson accepts integer response time', () {
      final stats = RealtorStats.fromJson(
        Map<String, dynamic>.from(json)..['average_response_time'] = 3,
      );

      expect(stats.averageResponseTime, 3.0);
    });
  });

  group('BuyerStats', () {
    final json = {
      'total_requests': 5,
      'active_requests': 2,
      'total_offers_received': 8,
      'total_offers_accepted': 3,
      'response_rate': 75,
    };

    test('fromJson parses all fields', () {
      final stats = BuyerStats.fromJson(json);

      expect(stats.totalRequests, 5);
      expect(stats.activeRequests, 2);
      expect(stats.totalOffersReceived, 8);
      expect(stats.totalOffersAccepted, 3);
      expect(stats.responseRate, 75.0);
    });

    test('fromJson defaults missing fields to zero', () {
      final stats = BuyerStats.fromJson(const {});

      expect(stats.totalRequests, 0);
      expect(stats.responseRate, 0);
    });
  });

  group('PlatformStats', () {
    final json = {
      'period': {'from': '2026-01-01T00:00:00.000Z', 'to': '2026-01-31T00:00:00.000Z'},
      'new_users': {'total': 20, 'buyers': 12, 'realtors': 8},
      'property_requests': 15,
      'realtor_offers': 30,
      'offer_acceptance_rate': 40,
      'average_offers_per_request': 2.0,
    };

    test('fromJson parses nested fields', () {
      final stats = PlatformStats.fromJson(json);

      expect(stats.periodFrom, '2026-01-01T00:00:00.000Z');
      expect(stats.periodTo, '2026-01-31T00:00:00.000Z');
      expect(stats.newUsersTotal, 20);
      expect(stats.newUsersBuyers, 12);
      expect(stats.newUsersRealtors, 8);
      expect(stats.propertyRequests, 15);
      expect(stats.realtorOffers, 30);
      expect(stats.offerAcceptanceRate, 40.0);
      expect(stats.averageOffersPerRequest, 2.0);
    });

    test('fromJson defaults missing nested fields', () {
      final stats = PlatformStats.fromJson(const {});

      expect(stats.periodFrom, '');
      expect(stats.periodTo, '');
      expect(stats.newUsersTotal, 0);
      expect(stats.offerAcceptanceRate, 0);
    });
  });
}
