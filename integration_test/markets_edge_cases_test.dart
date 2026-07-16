import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> navigateToMarkets(WidgetTester tester) async {
    await pumpAuthenticatedApp(tester);
    await tester.tap(find.byKey(const Key('bottom-nav-item-1')));
    await tester.pumpAndSettle(const Duration(seconds: 5));
  }

  group('Markets edge cases', () {
    testWidgets('search with no results shows empty state', (tester) async {
      await navigateToMarkets(tester);

      expect(find.text('BTC'), findsOneWidget);
      expect(find.text('ETH'), findsOneWidget);
      expect(find.text('SOL'), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('markets_search_field')),
        'ZZZZZ',
      );
      await tester.pumpAndSettle();

      expect(find.text('No markets found'), findsOneWidget);
      expect(find.text('BTC'), findsNothing);
      expect(find.text('ETH'), findsNothing);
      expect(find.text('SOL'), findsNothing);
      await binding.takeScreenshot('markets_search_no_results');
    });

    testWidgets('filter perpetuals shows only perp items', (tester) async {
      await navigateToMarkets(tester);

      expect(find.text('BTC'), findsOneWidget);
      expect(find.text('ETH'), findsOneWidget);
      expect(find.text('SOL'), findsOneWidget);

      await tester.tap(find.text('Perpetuals'));
      await tester.pumpAndSettle();

      expect(find.text('BTC'), findsOneWidget);
      expect(find.text('ETH'), findsOneWidget);
      expect(find.text('SOL'), findsNothing);
      expect(find.text('PERP'), findsWidgets);
      await binding.takeScreenshot('markets_filter_perpetuals');
    });

    testWidgets('filter spot shows only spot items', (tester) async {
      await navigateToMarkets(tester);

      expect(find.text('BTC'), findsOneWidget);
      expect(find.text('ETH'), findsOneWidget);
      expect(find.text('SOL'), findsOneWidget);

      await tester.tap(find.text('Spot'));
      await tester.pumpAndSettle();

      expect(find.text('SOL'), findsOneWidget);
      expect(find.text('BTC'), findsNothing);
      expect(find.text('ETH'), findsNothing);
      expect(find.text('SPOT'), findsWidgets);
      await binding.takeScreenshot('markets_filter_spot');
    });

    testWidgets('market list renders without overflow', (tester) async {
      await navigateToMarkets(tester);

      expect(find.text('BTC'), findsOneWidget);
      expect(find.text('ETH'), findsOneWidget);
      expect(find.text('SOL'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await binding.takeScreenshot('markets_no_overflow');
    });

    testWidgets('long symbol name renders without overflow', (tester) async {
      await navigateToMarkets(tester);

      expect(find.text('BTC'), findsOneWidget);
      expect(find.text('ETH'), findsOneWidget);
      expect(find.text('SOL'), findsOneWidget);

      // Scroll through the full list to trigger layout of every row,
      // then verify no RenderFlex overflow was reported.
      await tester.scrollUntilVisible(
        find.text('SOL'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      await binding.takeScreenshot('markets_long_symbol_no_overflow');
    });

    testWidgets('tap non-BTC symbol navigates to terminal', (tester) async {
      await navigateToMarkets(tester);

      await tester.tap(find.text('ETH'));
      await tester.pump(const Duration(seconds: 5));

      expect(find.text('ETHUSDT'), findsWidgets);
      expect(find.text('Buy / Long'), findsOneWidget);
      await binding.takeScreenshot('markets_navigate_eth');
    });
  });
}
