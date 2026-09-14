import 'package:flutter_test/flutter_test.dart';
import 'package:dabberli/models/realtor_verification.dart';

void main() {
  // Shape returned by list_pending_realtor_applications().
  final listRowJson = {
    'verification_id': 'v1',
    'realtor_id': 'u1',
    'full_name': 'Jane Realtor',
    'email': 'jane@example.com',
    'company_name': 'Jane Realty',
    'license_number': 'LIC-123',
    'license_expiry': '2030-01-01',
    'document_url': 'https://example.com/doc.pdf',
    'created_at': '2024-01-01T00:00:00.000Z',
  };

  // Shape returned by get_my_verification_status().
  final statusRowJson = {
    'verification_id': 'v2',
    'verification_type': 'realtor_license',
    'verification_status': 'approved',
    'rejection_reason': null,
    'document_url': 'https://example.com/doc.pdf',
    'created_at': '2024-01-01T00:00:00.000Z',
    'reviewed_at': '2024-01-02T00:00:00.000Z',
  };

  group('RealtorVerification', () {
    test('fromJson parses a list_pending_realtor_applications row', () {
      final v = RealtorVerification.fromJson(listRowJson);

      expect(v.id, 'v1');
      expect(v.realtorId, 'u1');
      expect(v.fullName, 'Jane Realtor');
      expect(v.email, 'jane@example.com');
      expect(v.companyName, 'Jane Realty');
      expect(v.licenseNumber, 'LIC-123');
      expect(v.licenseExpiry, DateTime.parse('2030-01-01'));
      expect(v.documentUrl, 'https://example.com/doc.pdf');
      // No verification_status column in this shape: defaults to pending.
      expect(v.status, 'pending');
      expect(v.createdAt, DateTime.parse('2024-01-01T00:00:00.000Z'));
    });

    test('fromJson parses a get_my_verification_status row', () {
      final v = RealtorVerification.fromJson(statusRowJson);

      expect(v.id, 'v2');
      expect(v.status, 'approved');
      expect(v.rejectionReason, isNull);
      expect(v.documentUrl, 'https://example.com/doc.pdf');
      expect(v.reviewedAt, DateTime.parse('2024-01-02T00:00:00.000Z'));
      expect(v.createdAt, DateTime.parse('2024-01-01T00:00:00.000Z'));
      // Fields not present in this shape.
      expect(v.realtorId, isNull);
      expect(v.companyName, isNull);
      expect(v.licenseExpiry, isNull);
    });

    test('fromJson handles null optional fields', () {
      final v = RealtorVerification.fromJson({
        'verification_id': 'v3',
        'created_at': '2024-01-01T00:00:00.000Z',
      });

      expect(v.status, 'pending');
      expect(v.licenseNumber, isNull);
      expect(v.documentUrl, isNull);
      expect(v.rejectionReason, isNull);
      expect(v.reviewedAt, isNull);
    });

    test('isApproved and isPending reflect status', () {
      final approved = RealtorVerification.fromJson(statusRowJson);
      final pending = RealtorVerification.fromJson({
        ...statusRowJson,
        'verification_status': 'pending',
      });

      expect(approved.isApproved, isTrue);
      expect(approved.isPending, isFalse);
      expect(pending.isApproved, isFalse);
      expect(pending.isPending, isTrue);
    });

    test('equality and hashCode are value-based', () {
      final a = RealtorVerification.fromJson(listRowJson);
      final b = RealtorVerification.fromJson(listRowJson);
      final c = RealtorVerification.fromJson(statusRowJson);

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });
  });
}
