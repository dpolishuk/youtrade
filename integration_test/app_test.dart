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

      expect(find.text('Aggregated net worth · 3 venues'), findsOneWidget);
      expect(find.textContaining(r'$124,350'), findsOneWidget);
      await binding.takeScreenshot('portfolio_tab');

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
          matching: find.text('Trading'),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));
      expect(find.text('Terminal'), findsOneWidget);
      expect(find.text('BTC · Binance'), findsOneWidget);
      await binding.takeScreenshot('trading_tab');

      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Orders'),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));
      expect(find.text('Open'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);
      expect(find.text('Positions'), findsOneWidget);
      await binding.takeScreenshot('orders_tab');

      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Account'),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));
      expect(find.text('Account'), findsWidgets);
      expect(find.text('Appearance'), findsOneWidget);
      await binding.takeScreenshot('account_tab');
    });
  });
}
