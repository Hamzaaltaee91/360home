import 'package:flutter_test/flutter_test.dart';
import 'package:dabberli/models/property_photo.dart';

void main() {
  group('PropertyPhoto', () {
    final createdAt = DateTime.parse('2024-01-01T00:00:00.000Z');

    final json = <String, dynamic>{
      'id': 'photo-1',
      'request_id': 'request-1',
      'offer_id': null,
      'url': 'https://example.com/photo.jpg',
      'caption': 'Front view',
      'sort_order': 2,
      'created_at': createdAt.toIso8601String(),
    };

    test('fromJson parses all fields', () {
      final photo = PropertyPhoto.fromJson(json);

      expect(photo.id, 'photo-1');
      expect(photo.requestId, 'request-1');
      expect(photo.offerId, isNull);
      expect(photo.url, 'https://example.com/photo.jpg');
      expect(photo.caption, 'Front view');
      expect(photo.sortOrder, 2);
      expect(photo.createdAt, createdAt);
    });

    test('fromJson applies defaults for optional fields', () {
      final photo = PropertyPhoto.fromJson({
        'id': 'photo-2',
        'request_id': 'request-2',
        'url': 'https://example.com/photo2.jpg',
        'created_at': createdAt.toIso8601String(),
      });

      expect(photo.offerId, isNull);
      expect(photo.caption, isNull);
      expect(photo.sortOrder, 0);
    });

    test('toJson round-trips through fromJson', () {
      final photo = PropertyPhoto.fromJson(json);
      final roundTripped = PropertyPhoto.fromJson(photo.toJson());

      expect(roundTripped, photo);
    });

    test('isOfferPhoto reflects offerId presence', () {
      final requestPhoto = PropertyPhoto.fromJson(json);
      final offerPhoto = requestPhoto.copyWith(offerId: 'offer-1');

      expect(requestPhoto.isOfferPhoto, isFalse);
      expect(offerPhoto.isOfferPhoto, isTrue);
    });

    test('copyWith overrides only provided fields', () {
      final photo = PropertyPhoto.fromJson(json);
      final updated = photo.copyWith(caption: 'Back view', sortOrder: 5);

      expect(updated.caption, 'Back view');
      expect(updated.sortOrder, 5);
      expect(updated.id, photo.id);
      expect(updated.url, photo.url);
    });

    test('equality and hashCode are value based', () {
      final a = PropertyPhoto.fromJson(json);
      final b = PropertyPhoto.fromJson(json);

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(equals(a.copyWith(caption: 'Different'))));
    });
  });
}
