import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Orders flow', () {
    testWidgets(
      'navigates to Orders, switches tabs, and cancels an open order',
      (tester) async {
        await pumpAuthenticatedAppWithMockStore(tester);

        await tester.ensureVisible(find.text('Orders →'));
        await tester.tap(find.text('Orders →'));
        await tester.pumpAndSettle(const Duration(seconds: 5));

        expect(find.text('Orders'), findsOneWidget);
        expect(find.text('Open'), findsOneWidget);
        expect(find.text('History'), findsOneWidget);
        expect(find.text('Positions'), findsOneWidget);
        expect(find.text('BTCUSDT'), findsWidgets);
        expect(find.text('Cancel'), findsWidgets);
        await binding.takeScreenshot('orders_open_tab');

        await tester.tap(find.text('History'));
        await tester.pumpAndSettle(const Duration(seconds: 2));
        expect(find.textContaining('Filled'), findsWidgets);
        expect(find.textContaining('Cancelled'), findsOneWidget);
        await binding.takeScreenshot('orders_history_tab');

        await tester.tap(find.text('Positions'));
        await tester.pumpAndSettle(const Duration(seconds: 2));
        expect(find.textContaining('Bybit Perp'), findsOneWidget);
        expect(find.textContaining('0.1000 BTC'), findsOneWidget);
        await binding.takeScreenshot('orders_positions_tab');

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle(const Duration(seconds: 2));

        expect(find.text('XRPUSDT'), findsOneWidget);
        await tester.tap(find.text('Cancel').last);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        expect(find.text('Cancel this order?'), findsOneWidget);
        await tester.tap(find.text('Cancel Order'));
        await tester.pumpAndSettle(const Duration(seconds: 2));

        expect(find.text('XRPUSDT'), findsNothing);
        expect(find.text('Order cancelled'), findsOneWidget);
        await binding.takeScreenshot('orders_after_cancel');
      },
      timeout: const Timeout(Duration(minutes: 5)),
    );
  });
}
