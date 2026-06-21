import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:youtrade/presentation/theme/app_theme.dart';
import 'package:youtrade/presentation/theme/theme_mode.dart';
import 'package:youtrade/ui/screens/options_chain_screen.dart';

void main() {
  group('OptionsChainScreen', () {
    testWidgets(
      'renders without overflow and shows expiry selector and strike rows',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark(AppVisualDirection.flux),
            home: const OptionsChainScreen(),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Options'), findsOneWidget);
        expect(find.text('BTC'), findsOneWidget);
        expect(find.text('OPTIONS'), findsOneWidget);
        expect(find.text('26 JUN'), findsOneWidget);
        expect(find.text('25 JUL'), findsOneWidget);
        expect(find.textContaining('ATM strike'), findsOneWidget);
        expect(find.textContaining('68,000'), findsWidgets);

        final overflowError = tester.takeException();
        expect(overflowError, isNull);
      },
    );

    testWidgets('switching expiry updates selected pill', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(AppVisualDirection.flux),
          home: const OptionsChainScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('26 JUN'), findsOneWidget);

      await tester.tap(find.text('25 JUL'));
      await tester.pumpAndSettle();

      expect(find.text('25 JUL'), findsOneWidget);
      expect(find.text('29 AUG'), findsOneWidget);
    });
  });
}
