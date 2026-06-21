import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Markets flow', () {
    testWidgets('opens a market item and shows exchange detail', (
      tester,
    ) async {
      await pumpAuthenticatedApp(tester);

      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Markets'),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));
      expect(find.text('BTC'), findsOneWidget);

      await tester.tap(find.text('BTC'));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Terminal'), findsOneWidget);
      expect(find.text('BTC · Binance'), findsOneWidget);
      await binding.takeScreenshot('trading_terminal_from_markets');
    });
  });
}
