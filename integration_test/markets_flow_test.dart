import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Markets flow', () {
    testWidgets('shows mockup screener values and navigates', (tester) async {
      await pumpAuthenticatedApp(tester);

      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Markets'),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('BTC'), findsOneWidget);
      expect(find.text('Bitcoin Perp'), findsOneWidget);
      expect(find.text('105,154.0'), findsOneWidget);
      expect(find.text('+6.42%'), findsOneWidget);
      await binding.takeScreenshot('markets_tab');

      await tester.tap(find.text('BTC'));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Buy / Long'), findsOneWidget);
      expect(find.text('Bitcoin Perpetual · Binance'), findsOneWidget);
      await binding.takeScreenshot('trading_terminal_from_markets');
    });

    testWidgets('options row navigates to options chain', (tester) async {
      await pumpAuthenticatedApp(tester);

      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Markets'),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tester.scrollUntilVisible(
        find.text('BTC-28K-C'),
        80,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('BTC-28K-C'));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('BTC-28K-C'), findsWidgets);
      expect(find.text('OPTIONS'), findsOneWidget);
      await binding.takeScreenshot('options_chain_from_markets');
    });
  });
}
