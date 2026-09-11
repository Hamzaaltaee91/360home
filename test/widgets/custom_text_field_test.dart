import 'package:dabberli/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CustomTextField', () {
    testWidgets('renders the label and hint', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomTextField(label: 'Email', hintText: 'you@example.com'),
          ),
        ),
      );

      expect(find.text('Email'), findsOneWidget);
      expect(find.text('you@example.com'), findsOneWidget);
    });

    testWidgets('updates the controller on input', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: CustomTextField(controller: controller)),
        ),
      );

      await tester.enterText(find.byType(TextFormField), 'hello');
      expect(controller.text, 'hello');
    });

    testWidgets('shows a validation error', (tester) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              key: formKey,
              child: CustomTextField(
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'Required' : null,
              ),
            ),
          ),
        ),
      );

      formKey.currentState!.validate();
      await tester.pump();

      expect(find.text('Required'), findsOneWidget);
    });

    testWidgets('obscures text when obscureText is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: CustomTextField(obscureText: true)),
        ),
      );

      final field = tester.widget<TextFormField>(find.byType(TextFormField));
      expect(field.obscureText, isTrue);
    });

    testWidgets('is not editable when enabled is false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: CustomTextField(enabled: false)),
        ),
      );

      final field = tester.widget<TextFormField>(find.byType(TextFormField));
      expect(field.enabled, isFalse);
    });
  });
}
