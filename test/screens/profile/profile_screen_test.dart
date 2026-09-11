import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dabberli/screens/profile/profile_screen.dart';

void main() {
  testWidgets('ProfileScreen renders app bar title', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: ProfileScreen()),
    );

    expect(find.text('الملف الشخصي'), findsOneWidget);
  });
}
