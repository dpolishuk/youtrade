import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> navigateToOrders(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Orders \u2192'));
    await tester.tap(find.text('Orders \u2192'));
    await tester.pumpAndSettle(const Duration(seconds: 5));
  }

  group('Orders edge cases', () {
    testWidgets('empty open orders shows no open orders message', (
      tester,
    ) async {
      await pumpAuthenticatedAppWithAccountClient(
        tester,
        accountClient: emptyOpenOrdersAccountClient(),
      );
      await navigateToOrders(tester);

      expect(find.text('No open orders'), findsOneWidget);
      expect(find.text('Cancel'), findsNothing);
      expect(tester.takeException(), isNull);
      await binding.takeScreenshot('orders_empty_open');
    });

    testWidgets('empty order history shows no order history message', (
      tester,
    ) async {
      await pumpAuthenticatedAppWithAccountClient(
        tester,
        accountClient: emptyHistoryOrdersAccountClient(),
      );
      await navigateToOrders(tester);

      await tester.tap(find.text('History'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.text('No order history'), findsOneWidget);
      expect(find.textContaining('Filled'), findsNothing);
      expect(tester.takeException(), isNull);
      await binding.takeScreenshot('orders_empty_history');
    });

    testWidgets(
      'tab switching changes displayed content between Open, History, and Positions',
      (tester) async {
        await pumpAuthenticatedAppWithAccountClient(
          tester,
          accountClient: emptyOpenOrdersAccountClient(),
        );
        await navigateToOrders(tester);

        expect(find.text('No open orders'), findsOneWidget);

        await tester.tap(find.text('History'));
        await tester.pumpAndSettle(const Duration(seconds: 2));
        expect(find.textContaining('Filled'), findsWidgets);
        expect(find.text('No order history'), findsNothing);

        await tester.tap(find.text('Positions'));
        await tester.pumpAndSettle(const Duration(seconds: 2));
        expect(find.text('No open positions'), findsOneWidget);

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle(const Duration(seconds: 2));
        expect(find.text('No open orders'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await binding.takeScreenshot('orders_tab_switching');
      },
    );
  });
}
