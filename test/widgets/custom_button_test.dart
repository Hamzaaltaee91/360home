import 'package:dabberli/widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CustomButton', () {
    testWidgets('renders the label and responds to taps', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              label: 'Submit',
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Submit'), findsOneWidget);
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('is disabled when onPressed is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: CustomButton(label: 'Submit')),
        ),
      );

      final button = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('shows a progress indicator while loading', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              label: 'Submit',
              isLoading: true,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Submit'), findsNothing);
    });

    testWidgets('ignores taps while loading', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              label: 'Submit',
              isLoading: true,
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      expect(tapped, isFalse);
    });

    testWidgets('renders an icon when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              label: 'Add',
              icon: Icons.add,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('does not expand when expand is false', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              label: 'Submit',
              expand: false,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(
        find.ancestor(
          of: find.byType(ElevatedButton),
          matching: find.byType(SizedBox),
        ),
        findsNothing,
      );
    });
  });
}
