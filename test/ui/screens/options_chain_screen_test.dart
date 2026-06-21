import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:youtrade/presentation/theme/app_theme.dart';
import 'package:youtrade/presentation/theme/theme_mode.dart';
import 'package:youtrade/ui/screens/options_chain_screen.dart';

void main() {
  group('OptionsChainScreen', () {
    Widget buildScreen() {
      return MaterialApp(
        theme: AppTheme.dark(AppVisualDirection.flux),
        home: const OptionsChainScreen(),
      );
    }

    testWidgets(
      'renders spot header, expiry pills, chain headers and strike rows',
      (tester) async {
        await tester.pumpWidget(buildScreen());
        await tester.pumpAndSettle();

        expect(find.text('Options'), findsOneWidget);

        expect(find.text('BTC'), findsOneWidget);
        expect(find.text('OPTIONS'), findsOneWidget);
        expect(find.text('68,432'), findsOneWidget);

        expect(find.text('26 JUN'), findsOneWidget);
        expect(find.text('25 JUL'), findsOneWidget);
        expect(find.text('29 AUG'), findsOneWidget);
        expect(find.text('26 SEP'), findsOneWidget);

        expect(find.text('Calls'), findsOneWidget);
        expect(find.text('Strike'), findsOneWidget);
        expect(find.text('Puts'), findsOneWidget);
        expect(find.text('IV'), findsNWidgets(2));
        expect(find.text('Δ'), findsNWidgets(2));
        expect(find.text('Mark'), findsNWidgets(2));

        expect(find.text('ATM strike 68,000 · highlighted'), findsOneWidget);

        for (final strike in ['60,000', '62,000', '64,000', '66,000']) {
          expect(find.text(strike), findsOneWidget);
        }
        expect(find.text('68,000'), findsOneWidget);
        for (final strike in ['70,000', '72,000', '74,000', '76,000']) {
          expect(find.text(strike), findsOneWidget);
        }

        expect(find.text('0.98'), findsOneWidget);
        expect(find.text('0.1482'), findsOneWidget);
        expect(find.text('0.53'), findsOneWidget);
        expect(find.text('0.0363'), findsOneWidget);
        expect(find.text('-0.47'), findsOneWidget);
        expect(find.text('0.0290'), findsOneWidget);
        expect(find.text('0.0771'), findsOneWidget);
        expect(find.text('0.1316'), findsOneWidget);
      },
    );

    testWidgets('switching expiry keeps all pills visible', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('26 JUN'), findsOneWidget);

      await tester.tap(find.text('25 JUL'));
      await tester.pumpAndSettle();

      expect(find.text('26 JUN'), findsOneWidget);
      expect(find.text('25 JUL'), findsOneWidget);
      expect(find.text('29 AUG'), findsOneWidget);
      expect(find.text('26 SEP'), findsOneWidget);
      expect(find.text('ATM strike 68,000 · highlighted'), findsOneWidget);
    });
  });
}
