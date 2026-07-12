import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Markets flow', () {
    testWidgets('shows screener values and navigates to trading', (
      tester,
    ) async {
      await pumpAuthenticatedApp(tester);

      await tester.tap(find.byKey(const Key('bottom-nav-item-1')));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('BTC'), findsOneWidget);
      expect(find.text('65,000.0'), findsOneWidget);
      expect(find.text('+5.23%'), findsOneWidget);
      await binding.takeScreenshot('markets_tab');

      await tester.tap(find.text('BTC'));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Buy / Long'), findsOneWidget);
      await binding.takeScreenshot('trading_terminal_from_markets');
    });

    testWidgets('search filters the market list', (tester) async {
      await pumpAuthenticatedApp(tester);

      await tester.tap(find.byKey(const Key('bottom-nav-item-1')));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('BTC'), findsOneWidget);
      expect(find.text('ETH'), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('markets_search_field')),
        'btc',
      );
      await tester.pumpAndSettle();

      expect(find.text('BTC'), findsOneWidget);
      expect(find.text('ETH'), findsNothing);
    });
  });
}
