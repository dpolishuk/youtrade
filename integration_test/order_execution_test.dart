import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> navigateToTerminal(WidgetTester tester) async {
    await pumpAuthenticatedApp(tester);
    await tester.tap(find.byKey(const Key('bottom-nav-item-2')));
    await tester.pumpAndSettle(const Duration(seconds: 5));
  }

  Future<void> navigateToOrders(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Orders \u2192'));
    await tester.tap(find.text('Orders \u2192'));
    await tester.pumpAndSettle(const Duration(seconds: 5));
  }

  group('Order placement', () {
    testWidgets('limit order submit shows confirmation dialog', (tester) async {
      await navigateToTerminal(tester);

      await tester.ensureVisible(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.textContaining('Confirm'), findsOneWidget);
      expect(find.text('Confirm'), findsOneWidget);
      expect(find.textContaining('BTC'), findsWidgets);
      expect(tester.takeException(), isNull);
      await binding.takeScreenshot('order_place_limit_confirmation');
    });

    testWidgets('market order submit shows confirmation dialog', (
      tester,
    ) async {
      await navigateToTerminal(tester);

      await tester.tap(find.text('Market'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.textContaining('Confirm'), findsOneWidget);
      expect(find.textContaining('Market order'), findsOneWidget);
      expect(find.text('Confirm'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await binding.takeScreenshot('order_place_market_confirmation');
    });
  });

  group('Order cancellation', () {
    testWidgets('cancel shows confirmation dialog', (tester) async {
      await pumpAuthenticatedApp(tester);
      await navigateToOrders(tester);

      expect(find.text('Cancel'), findsWidgets);

      await tester.tap(find.text('Cancel').first);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.text('Cancel this order?'), findsOneWidget);
      expect(find.text('Cancel Order'), findsOneWidget);
      expect(find.text('Keep Order'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await binding.takeScreenshot('order_cancel_confirmation');
    });

    testWidgets('cancel error shows error message', (tester) async {
      await pumpAuthenticatedAppWithAccountClient(
        tester,
        accountClient: cancelErrorAccountClient(),
      );
      await navigateToOrders(tester);

      await tester.tap(find.text('Cancel').first);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      await tester.tap(find.text('Cancel Order'));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.textContaining('order not found'), findsOneWidget);
      expect(find.text('Cancel Order'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await binding.takeScreenshot('order_cancel_error');
    });
  });
}
