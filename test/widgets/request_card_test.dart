import 'package:dabberli/models/models.dart';
import 'package:dabberli/widgets/request_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

PropertyRequest _buildRequest({
  String title = 'Looking for a 3BR apartment',
  String city = 'Dubai',
  String? areaName = 'Marina',
  String? description = 'Close to the metro.',
  double? minPrice = 1000000,
  double? maxPrice = 2000000,
  bool isUrgent = false,
}) {
  final now = DateTime(2024, 1, 1);
  return PropertyRequest(
    id: 'request-1',
    buyerId: 'buyer-1',
    category: 'residential',
    title: title,
    description: description,
    city: city,
    areaName: areaName,
    minPrice: minPrice,
    maxPrice: maxPrice,
    isUrgent: isUrgent,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('RequestCard', () {
    testWidgets('renders the request details', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: RequestCard(request: _buildRequest())),
        ),
      );

      expect(find.text('Looking for a 3BR apartment'), findsOneWidget);
      expect(find.text('Marina, Dubai'), findsOneWidget);
      expect(find.text('Close to the metro.'), findsOneWidget);
      expect(find.text('AED 1,000,000 - AED 2,000,000'), findsOneWidget);
    });

    testWidgets('invokes onTap when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RequestCard(
              request: _buildRequest(),
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(InkWell));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('shows the urgent chip when urgent', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RequestCard(request: _buildRequest(isUrgent: true)),
          ),
        ),
      );

      expect(find.text('Urgent'), findsOneWidget);
    });

    testWidgets('shows a fallback price label when no price is set',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RequestCard(
              request: _buildRequest(minPrice: null, maxPrice: null),
            ),
          ),
        ),
      );

      expect(find.text('Price not specified'), findsOneWidget);
    });

    testWidgets('falls back to the city when no area is set', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RequestCard(request: _buildRequest(areaName: null)),
          ),
        ),
      );

      expect(find.text('Dubai'), findsOneWidget);
    });
  });
}
