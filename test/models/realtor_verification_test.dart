import 'package:flutter_test/flutter_test.dart';
import 'package:dabberli/models/realtor_verification.dart';

void main() {
  final json = {
    'id': 'v1',
    'user_id': 'u1',
    'status': 'approved',
    'license_number': 'LIC-123',
    'document_url': 'https://example.com/doc.pdf',
    'rejection_reason': null,
    'verified_by': 'admin1',
    'reviewed_at': '2024-01-02T00:00:00.000Z',
    'created_at': '2024-01-01T00:00:00.000Z',
    'updated_at': '2024-01-02T00:00:00.000Z',
  };

  group('RealtorVerification', () {
    test('fromJson parses all fields', () {
      final v = RealtorVerification.fromJson(json);

      expect(v.id, 'v1');
      expect(v.userId, 'u1');
      expect(v.status, 'approved');
      expect(v.licenseNumber, 'LIC-123');
      expect(v.documentUrl, 'https://example.com/doc.pdf');
      expect(v.rejectionReason, isNull);
      expect(v.verifiedBy, 'admin1');
      expect(v.reviewedAt, DateTime.parse('2024-01-02T00:00:00.000Z'));
      expect(v.createdAt, DateTime.parse('2024-01-01T00:00:00.000Z'));
      expect(v.updatedAt, DateTime.parse('2024-01-02T00:00:00.000Z'));
    });

    test('fromJson handles null optional fields', () {
      final v = RealtorVerification.fromJson({
        'id': 'v2',
        'user_id': 'u2',
        'status': 'pending',
        'created_at': '2024-01-01T00:00:00.000Z',
        'updated_at': '2024-01-01T00:00:00.000Z',
      });

      expect(v.licenseNumber, isNull);
      expect(v.documentUrl, isNull);
      expect(v.rejectionReason, isNull);
      expect(v.verifiedBy, isNull);
      expect(v.reviewedAt, isNull);
    });

    test('toJson round-trips through fromJson', () {
      final v = RealtorVerification.fromJson(json);
      final roundTripped = RealtorVerification.fromJson(v.toJson());

      expect(roundTripped, v);
    });

    test('isApproved and isPending reflect status', () {
      final approved = RealtorVerification.fromJson(json);
      final pending = RealtorVerification.fromJson({
        ...json,
        'status': 'pending',
      });

      expect(approved.isApproved, isTrue);
      expect(approved.isPending, isFalse);
      expect(pending.isApproved, isFalse);
      expect(pending.isPending, isTrue);
    });

    test('copyWith overrides only provided fields', () {
      final v = RealtorVerification.fromJson(json);
      final updated = v.copyWith(status: 'rejected', rejectionReason: 'blurry');

      expect(updated.status, 'rejected');
      expect(updated.rejectionReason, 'blurry');
      expect(updated.id, v.id);
      expect(updated.userId, v.userId);
      expect(updated.licenseNumber, v.licenseNumber);
    });

    test('equality and hashCode are value-based', () {
      final a = RealtorVerification.fromJson(json);
      final b = RealtorVerification.fromJson(json);

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(a.copyWith(status: 'rejected')));
    });
  });
}
