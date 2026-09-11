import 'package:dabberli/models/models.dart';
import 'package:dabberli/widgets/property_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

RealtorOffer _buildOffer({
  String propertyTitle = 'Sunny Villa',
  String propertyAddress = 'Palm Jumeirah, Dubai',
  String? propertyDescription = 'A lovely villa with a sea view.',
  double offeredPrice = 1500000,
}) {
  final now = DateTime(2024, 1, 1);
  return RealtorOffer(
    id: 'offer-1',
    realtorId: 'realtor-1',
    requestId: 'request-1',
    propertyTitle: propertyTitle,
    propertyDescription: propertyDescription,
    propertyAddress: propertyAddress,
    offeredPrice: offeredPrice,
    createdAt: now,
    updatedAt: now,
    expiresAt: now.add(const Duration(days: 30)),
  );
}

void main() {
  group('PropertyCard', () {
    testWidgets('renders the offer details', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: PropertyCard(offer: _buildOffer())),
        ),
      );

      expect(find.text('Sunny Villa'), findsOneWidget);
      expect(find.text('Palm Jumeirah, Dubai'), findsOneWidget);
      expect(find.text('A lovely villa with a sea view.'), findsOneWidget);
      expect(find.text('\$1,500,000'), findsOneWidget);
    });

    testWidgets('invokes onTap when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PropertyCard(
              offer: _buildOffer(),
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(InkWell));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('renders the trailing widget when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PropertyCard(
              offer: _buildOffer(),
              trailing: const Chip(label: Text('New')),
            ),
          ),
        ),
      );

      expect(find.text('New'), findsOneWidget);
    });

    testWidgets('omits the description when empty', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PropertyCard(
              offer: _buildOffer(propertyDescription: ''),
            ),
          ),
        ),
      );

      expect(find.text('A lovely villa with a sea view.'), findsNothing);
    });
  });
}
