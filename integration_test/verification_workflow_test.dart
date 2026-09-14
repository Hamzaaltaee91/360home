// Integration test: Realtor Verification Workflow
//
// End-to-end flow: Realtor signs up → submits a realtor application
// (company name, license number, license expiry, document URL) → the
// request is persisted with a "pending" status → it can be fetched back
// via `getMyVerification`.
//
// The test skips gracefully when `SUPABASE_URL` / `SUPABASE_ANON_KEY` are
// not provided, so CI without a live backend does not fail.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

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
    const companyName = 'Integration Realty';
    const licenseNumber = 'LIC-INTEGRATION-0001';
    const documentUrl = 'https://example.com/license.pdf';
    final licenseExpiry = DateTime.now().add(const Duration(days: 365));

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

        // Submit the realtor application.
        await service.submitVerification(
          companyName: companyName,
          licenseNumber: licenseNumber,
          licenseExpiry: licenseExpiry,
          documentUrl: documentUrl,
        );

        // Fetch it back and confirm persistence.
        final fetched = await service.getMyVerification();
        expect(fetched, isNotNull);
        expect(fetched!.status, 'pending');
        expect(fetched.documentUrl, documentUrl);
        expect(fetched.rejectionReason, isNull);
        expect(fetched.reviewedAt, isNull);
      },
    );
  });
}
