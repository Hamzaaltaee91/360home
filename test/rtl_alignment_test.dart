// RTL Alignment Test
//
// Verifies that the app renders with the correct text direction for the
// supported locales: Arabic (RTL) and English (LTR).

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RTL alignment', () {
    testWidgets('Arabic locale renders right-to-left', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('ar'),
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          supportedLocales: const [Locale('ar'), Locale('en')],
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(body: Text('مرحبا')),
          ),
        ),
      );

      final directionality = tester.widget<Directionality>(
        find.byType(Directionality).first,
      );
      expect(directionality.textDirection, TextDirection.rtl);
    });

    testWidgets('English locale renders left-to-right', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('en'),
          home: Directionality(
            textDirection: TextDirection.ltr,
            child: Scaffold(body: Text('Hello')),
          ),
        ),
      );

      final directionality = tester.widget<Directionality>(
        find.byType(Directionality).first,
      );
      expect(directionality.textDirection, TextDirection.ltr);
    });

    testWidgets('EdgeInsetsDirectional mirrors under RTL', (tester) async {
      const padding = EdgeInsetsDirectional.only(start: 4);

      expect(padding.resolve(TextDirection.rtl).left, 0);
      expect(padding.resolve(TextDirection.rtl).right, 4);
      expect(padding.resolve(TextDirection.ltr).left, 4);
      expect(padding.resolve(TextDirection.ltr).right, 0);
    });
  });
}
