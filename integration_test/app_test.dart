import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App smoke test', () {
    testWidgets('launches, authenticates, and visits every tab', (
      tester,
    ) async {
      await pumpAuthenticatedApp(tester);

      expect(find.text('Aggregated net worth · 4 venues'), findsOneWidget);
      expect(find.textContaining(r'$746,240'), findsOneWidget);
      expect(find.text('+2.04%'), findsOneWidget);
      expect(find.text('Binance'), findsOneWidget);
      expect(find.text('OKX'), findsOneWidget);
      await binding.takeScreenshot('portfolio_tab');

      await tester.ensureVisible(find.text('Orders →'));
      await tester.tap(find.text('Orders →'));
      await tester.pumpAndSettle(const Duration(seconds: 5));
      expect(find.text('Orders'), findsOneWidget);
      await binding.takeScreenshot('orders_screen');

      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Markets'),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));
      expect(find.text('Markets'), findsWidgets);
      expect(find.text('BTC'), findsOneWidget);
      await binding.takeScreenshot('markets_tab');

      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Trade'),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));
      expect(find.text('Terminal'), findsOneWidget);
      expect(find.text('BTC · Binance'), findsOneWidget);
      await binding.takeScreenshot('trading_tab');

      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Options'),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));
      expect(find.text('BTC'), findsWidgets);
      await binding.takeScreenshot('options_tab');

      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('More'),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));
      expect(find.text('Account'), findsWidgets);
      expect(find.text('Appearance'), findsOneWidget);
      await binding.takeScreenshot('more_tab');
    });
  });
}
