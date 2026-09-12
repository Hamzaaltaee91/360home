import 'package:dabberli/widgets/map_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MapPicker', () {
    testWidgets('shows prompt when no location selected', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: MapPicker())),
      );

      expect(find.text('Tap to select a location'), findsOneWidget);
      expect(find.text('No location selected'), findsOneWidget);
    });

    testWidgets('reports a coordinate when tapped', (tester) async {
      LatLng? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MapPicker(onChanged: (value) => selected = value),
          ),
        ),
      );

      await tester.tap(find.byType(GestureDetector).first);
      await tester.pump();

      expect(selected, isNotNull);
      expect(selected!.latitude, inInclusiveRange(-90, 90));
      expect(selected!.longitude, inInclusiveRange(-180, 180));
    });

    testWidgets('renders initial location', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MapPicker(initialLocation: LatLng(24.7136, 46.6753)),
          ),
        ),
      );

      expect(find.textContaining('24.71360'), findsOneWidget);
    });
  });
}
