import 'package:dabberli/widgets/error_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppErrorWidget', () {
    testWidgets('renders a default message when none is provided',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: AppErrorWidget())),
      );

      expect(find.text('Something went wrong.'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('renders the provided message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AppErrorWidget(message: 'Network failed')),
        ),
      );

      expect(find.text('Network failed'), findsOneWidget);
    });

    testWidgets('does not render a retry button when onRetry is null',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: AppErrorWidget())),
      );

      expect(find.byType(FilledButton), findsNothing);
    });

    testWidgets('invokes onRetry when the retry button is tapped',
        (tester) async {
      var retried = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppErrorWidget(onRetry: () => retried = true),
          ),
        ),
      );

      await tester.tap(find.widgetWithText(FilledButton, 'Retry'));
      await tester.pump();

      expect(retried, isTrue);
    });

    testWidgets('uses a custom retry label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppErrorWidget(onRetry: () {}, retryLabel: 'Try again'),
          ),
        ),
      );

      expect(find.text('Try again'), findsOneWidget);
    });
  });
}
