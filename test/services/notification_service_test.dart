import 'package:flutter_test/flutter_test.dart';
import 'package:dabberli/models/models.dart';

void main() {
  group('Notification model', () {
    final json = {
      'id': 'n1',
      'user_id': 'u1',
      'type': 'offer_received',
      'title': 'عرض جديد',
      'body': 'لديك عرض جديد على طلبك',
      'data': {'offer_id': 'o1'},
      'is_read': false,
      'created_at': '2026-01-01T00:00:00.000Z',
    };

    test('fromJson parses all fields', () {
      final notification = Notification.fromJson(json);

      expect(notification.id, 'n1');
      expect(notification.userId, 'u1');
      expect(notification.type, 'offer_received');
      expect(notification.title, 'عرض جديد');
      expect(notification.body, 'لديك عرض جديد على طلبك');
      expect(notification.data, {'offer_id': 'o1'});
      expect(notification.isRead, isFalse);
      expect(notification.createdAt, DateTime.utc(2026, 1, 1));
    });

    test('fromJson defaults is_read to false when missing', () {
      final withoutRead = Map<String, dynamic>.from(json)..remove('is_read');
      expect(Notification.fromJson(withoutRead).isRead, isFalse);
    });

    test('toJson round-trips', () {
      final notification = Notification.fromJson(json);
      expect(notification.toJson(), json);
    });

    test('copyWith overrides only provided fields', () {
      final notification = Notification.fromJson(json);
      final updated = notification.copyWith(isRead: true);

      expect(updated.isRead, isTrue);
      expect(updated.id, notification.id);
      expect(updated.title, notification.title);
    });

    test('equality is value based', () {
      final a = Notification.fromJson(json);
      final b = Notification.fromJson(json);

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(a.copyWith(isRead: true))));
    });
  });
}
