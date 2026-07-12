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

      expect(find.text('YouTrade'), findsOneWidget);
      expect(find.text('AGGREGATED NET WORTH · 2 VENUES'), findsOneWidget);
      expect(find.textContaining(r'$50,000'), findsOneWidget);
      expect(find.text('+0.30%'), findsOneWidget);
      expect(find.text('USDT'), findsOneWidget);
      expect(find.text('BTC'), findsOneWidget);
      await binding.takeScreenshot('portfolio_tab');

      await tester.ensureVisible(find.text('Orders →'));
      await tester.tap(find.text('Orders →'));
      await tester.pumpAndSettle(const Duration(seconds: 30));
      expect(find.text('Orders'), findsOneWidget);
      expect(find.text('YouTrade'), findsOneWidget);
      await binding.takeScreenshot('orders_screen');

      await tester.tap(find.byKey(const Key('bottom-nav-item-1')));
      await tester.pumpAndSettle(const Duration(seconds: 30));
      expect(find.text('Markets'), findsWidgets);
      expect(find.text('BTC'), findsOneWidget);
      expect(find.text('YouTrade'), findsOneWidget);
      await binding.takeScreenshot('markets_tab');

      await tester.tap(find.byKey(const Key('bottom-nav-item-2')));
      await tester.pumpAndSettle(const Duration(seconds: 30));
      expect(find.text('Buy / Long'), findsOneWidget);
      expect(find.text('Bitcoin Perpetual · Bybit'), findsOneWidget);
      expect(find.text('YouTrade'), findsOneWidget);
      await binding.takeScreenshot('trading_tab');

      await tester.tap(find.byKey(const Key('bottom-nav-item-3')));
      await tester.pumpAndSettle(const Duration(seconds: 30));
      expect(find.text('BTC'), findsWidgets);
      expect(find.text('YouTrade'), findsOneWidget);
      await binding.takeScreenshot('options_tab');

      await tester.tap(find.byKey(const Key('bottom-nav-item-4')));
      await tester.pumpAndSettle(const Duration(seconds: 30));
      expect(find.text('Account'), findsWidgets);
      expect(find.text('APPEARANCE'), findsOneWidget);
      expect(find.text('YouTrade'), findsOneWidget);
      await binding.takeScreenshot('more_tab');
    });
  });
}
