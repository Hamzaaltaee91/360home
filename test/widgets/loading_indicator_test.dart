import 'package:dabberli/widgets/loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LoadingIndicator', () {
    testWidgets('renders a CircularProgressIndicator', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: LoadingIndicator())),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders the message when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: LoadingIndicator(message: 'Loading data')),
        ),
      );

      expect(find.text('Loading data'), findsOneWidget);
    });

    testWidgets('does not render a message when omitted', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: LoadingIndicator())),
      );

      expect(find.byType(Text), findsNothing);
    });

    testWidgets('applies the requested size', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: LoadingIndicator(size: 64)),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(
        find
            .ancestor(
              of: find.byType(CircularProgressIndicator),
              matching: find.byType(SizedBox),
            )
            .first,
      );
      expect(sizedBox.width, 64);
      expect(sizedBox.height, 64);
    });

    testWidgets('centers content when fullScreen is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: LoadingIndicator(fullScreen: true)),
        ),
      );

      expect(
        find.ancestor(
          of: find.byType(CircularProgressIndicator),
          matching: find.byType(Center),
        ),
        findsOneWidget,
      );
    });
  });
}
