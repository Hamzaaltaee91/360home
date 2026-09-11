// Integration test: Realtor Verification Workflow
//
// End-to-end flow: Realtor signs up → submits a verification request
// (license number + document URL) → the request is persisted with a
// "pending" status → it can be fetched back via `getMyVerification`.
//
// The test skips gracefully when `SUPABASE_URL` / `SUPABASE_ANON_KEY` are
// not provided, so CI without a live backend does not fail.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:dabberli/services/supabase_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final supabaseUrl = Platform.environment['SUPABASE_URL'];
  final supabaseAnonKey = Platform.environment['SUPABASE_ANON_KEY'];

  final isConfigured =
      supabaseUrl != null &&
      supabaseUrl.isNotEmpty &&
      supabaseAnonKey != null &&
      supabaseAnonKey.isNotEmpty;

  group('Realtor Verification Workflow', () {
    late SupabaseService service;
    late String realtorEmail;
    const realtorPassword = 'Test1234!';
    const licenseNumber = 'LIC-INTEGRATION-0001';
    const documentUrl = 'https://example.com/license.pdf';

    setUpAll(() async {
      if (!isConfigured) return;

      await SupabaseService().initialize(
        supabaseUrl: supabaseUrl,
        supabaseAnonKey: supabaseAnonKey,
      );
      service = SupabaseService();

      // Unique email per run to avoid collisions on a shared backend.
      realtorEmail =
          'realtor.verify.${DateTime.now().millisecondsSinceEpoch}@example.com';

      await service.signUp(
        email: realtorEmail,
        password: realtorPassword,
        fullName: 'Integration Realtor',
        role: 'realtor',
      );
    });

    tearDownAll(() async {
      if (!isConfigured) return;
      await service.signOut();
    });

    testWidgets(
      'realtor submits a verification request that is stored as pending',
      (tester) async {
        if (!isConfigured) {
          // ignore: avoid_print
          print(
            'Skipping verification workflow test: SUPABASE_URL / '
            'SUPABASE_ANON_KEY not set.',
          );
          return;
        }

        // Ensure we are authenticated before submitting.
        expect(service.isAuthenticated(), isTrue);

        // No verification should exist yet for a fresh realtor.
        final before = await service.getMyVerification();
        expect(before, isNull);

        // Submit the verification request.
        final submitted = await service.submitVerification(
          licenseNumber: licenseNumber,
          documentUrl: documentUrl,
        );

        expect(submitted.status, 'pending');
        expect(submitted.licenseNumber, licenseNumber);
        expect(submitted.documentUrl, documentUrl);
        expect(submitted.rejectionReason, isNull);
        expect(submitted.verifiedBy, isNull);
        expect(submitted.reviewedAt, isNull);

        // Fetch it back and confirm persistence.
        final fetched = await service.getMyVerification();
        expect(fetched, isNotNull);
        expect(fetched!.id, submitted.id);
        expect(fetched.status, 'pending');
        expect(fetched.licenseNumber, licenseNumber);
        expect(fetched.documentUrl, documentUrl);
      },
    );
  });
}
