import 'package:dabberli/widgets/image_picker_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ImagePickerWidget', () {
    testWidgets('renders the add button and counter', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ImagePickerWidget(maxImages: 3)),
        ),
      );

      expect(find.byIcon(Icons.add_a_photo), findsOneWidget);
      expect(find.text('0/3 images'), findsOneWidget);
    });

    testWidgets('opens the source sheet when the add button is tapped',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ImagePickerWidget()),
        ),
      );

      await tester.tap(find.byIcon(Icons.add_a_photo));
      await tester.pumpAndSettle();

      expect(find.text('Choose from gallery'), findsOneWidget);
      expect(find.text('Take a photo'), findsOneWidget);
    });

    testWidgets('does not show the add button when disabled', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ImagePickerWidget(enabled: false)),
        ),
      );

      final button = tester.widget<InkWell>(
        find.ancestor(
          of: find.byIcon(Icons.add_a_photo),
          matching: find.byType(InkWell),
        ),
      );
      expect(button.onTap, isNull);
    });
  });
}
