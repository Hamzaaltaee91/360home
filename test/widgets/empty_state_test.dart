import 'package:dabberli/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EmptyState', () {
    testWidgets('renders the title and default icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: EmptyState(title: 'Nothing here')),
        ),
      );

      expect(find.text('Nothing here'), findsOneWidget);
      expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
    });

    testWidgets('renders the message when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              title: 'Nothing here',
              message: 'Try again later',
            ),
          ),
        ),
      );

      expect(find.text('Try again later'), findsOneWidget);
    });

    testWidgets('renders the action widget when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyState(
              title: 'Nothing here',
              action: ElevatedButton(
                onPressed: () {},
                child: const Text('Add'),
              ),
            ),
          ),
        ),
      );

      expect(find.widgetWithText(ElevatedButton, 'Add'), findsOneWidget);
    });

    testWidgets('uses the provided icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(title: 'Empty', icon: Icons.search_off),
          ),
        ),
      );

      expect(find.byIcon(Icons.search_off), findsOneWidget);
    });

    testWidgets('centers content when fullScreen is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: EmptyState(title: 'Empty', fullScreen: true)),
        ),
      );

      expect(
        find.ancestor(
          of: find.text('Empty'),
          matching: find.byType(Center),
        ),
        findsOneWidget,
      );
    });
  });
}
