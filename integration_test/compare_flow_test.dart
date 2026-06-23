import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Compare flow', () {
    testWidgets('terminal compare button navigates to Compare screen', (
      tester,
    ) async {
      await pumpAuthenticatedApp(tester);

      await tester.tap(find.byKey(const Key('bottom-nav-item-2')));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Bitcoin Perpetual · Binance'), findsOneWidget);
      expect(find.byIcon(Icons.stacked_line_chart), findsOneWidget);
      await binding.takeScreenshot('trading_terminal_compare_button');

      await tester.tap(find.byIcon(Icons.stacked_line_chart));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Compare'), findsOneWidget);
      expect(find.text('3/4 · normalized %'), findsOneWidget);
      expect(find.text('BTC'), findsWidgets);
      expect(find.text('ETH'), findsWidgets);
      expect(find.text('SOL'), findsWidgets);
      expect(find.text('60-period stats'), findsOneWidget);
      await binding.takeScreenshot('compare_screen');
    });
  });
}
