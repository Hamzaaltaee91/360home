import 'package:dabberli/screens/settings_screen.dart';
import 'package:dabberli/services/settings_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('renders language, notifications, and theme controls',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
    await tester.pumpAndSettle();

    expect(find.text('الإعدادات'), findsOneWidget);
    expect(find.text('العربية'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('تفعيل الإشعارات'), findsOneWidget);
    expect(find.text('الوضع الليلي'), findsOneWidget);
  });

  testWidgets('toggling dark mode updates the settings service',
      (tester) async {
    final settings = SettingsService();
    await settings.setDarkMode(false);

    await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('الوضع الليلي'));
    await tester.pumpAndSettle();

    expect(settings.darkMode, isTrue);
  });

  testWidgets('toggling notifications updates the settings service',
      (tester) async {
    final settings = SettingsService();
    await settings.setNotificationsEnabled(true);

    await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('تفعيل الإشعارات'));
    await tester.pumpAndSettle();

    expect(settings.notificationsEnabled, isFalse);
  });
}
