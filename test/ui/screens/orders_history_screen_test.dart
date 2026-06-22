import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:youtrade/data/datasources/mock/deterministic_market_data_store.dart';
import 'package:youtrade/presentation/theme/app_theme.dart';
import 'package:youtrade/presentation/theme/theme_mode.dart';
import 'package:youtrade/ui/screens/orders_history_screen.dart';
import 'package:youtrade/ui/widgets/orders/order_list_tile.dart';

void main() {
  group('OrdersHistoryScreen', () {
    Future<void> pumpScreen(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(AppVisualDirection.flux),
          home: const OrdersHistoryScreen(),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('renders title "Orders" with mockup typography', (
      tester,
    ) async {
      await pumpScreen(tester);

      final title = tester.widget<Text>(find.text('Orders'));
      expect(title.style?.fontFamily, 'Space Grotesk');
      expect(title.style?.fontSize, 18);
      expect(title.style?.fontWeight, FontWeight.w600);
      expect(title.style?.letterSpacing, closeTo(-0.02 * 18, 0.01));
      expect(title.style?.color, const Color(0xFFF2F5FA));
    });

    testWidgets('renders Open / History / Positions tabs', (tester) async {
      await pumpScreen(tester);

      expect(find.text('Open'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);
      expect(find.text('Positions'), findsOneWidget);
    });

    testWidgets('active tab uses fg and accent underline', (tester) async {
      await pumpScreen(tester);

      final activeContainer = tester.widget<Container>(
        find
            .ancestor(of: find.text('Open'), matching: find.byType(Container))
            .first,
      );
      final decoration = activeContainer.decoration! as BoxDecoration;
      final border = decoration.border! as Border;
      expect(border.bottom.color, const Color(0xFF00E6D2));
      expect(border.bottom.width, 2);

      final activeText = tester.widget<Text>(find.text('Open'));
      expect(activeText.style?.fontFamily, 'JetBrains Mono');
      expect(activeText.style?.fontSize, 11);
      expect(activeText.style?.fontWeight, FontWeight.w600);
      expect(activeText.style?.color, const Color(0xFFF2F5FA));
    });

    testWidgets('inactive tab uses fg3 and transparent underline', (
      tester,
    ) async {
      await pumpScreen(tester);

      final inactiveContainer = tester.widget<Container>(
        find
            .ancestor(
              of: find.text('History'),
              matching: find.byType(Container),
            )
            .first,
      );
      final decoration = inactiveContainer.decoration! as BoxDecoration;
      final border = decoration.border! as Border;
      expect(border.bottom.color, Colors.transparent);

      final inactiveText = tester.widget<Text>(find.text('History'));
      expect(inactiveText.style?.color, const Color(0x57FFFFFF));
    });

    testWidgets('Open tab shows deterministic open orders', (tester) async {
      await pumpScreen(tester);

      for (final order in DeterministicMarketDataStore.openOrders) {
        expect(find.text(order.symbol), findsWidgets);
      }
      expect(find.text('Cancel'), findsNWidgets(4));
      expect(find.textContaining('58,400.0'), findsOneWidget);
      expect(find.textContaining('0.50'), findsOneWidget);
      expect(find.textContaining('34% filled'), findsOneWidget);
    });

    testWidgets('open order card matches mockup styling', (tester) async {
      await pumpScreen(tester);

      final firstCard = tester.widget<OrderListTile>(
        find.byType(OrderListTile).first,
      );
      expect(firstCard.order.symbol, 'BTCUSDT');

      final symbol = tester.widget<Text>(find.text('BTCUSDT').first);
      expect(symbol.style?.fontSize, 13);
      expect(symbol.style?.fontWeight, FontWeight.w600);
      expect(symbol.style?.color, const Color(0xFFF2F5FA));

      final cancel = tester.widget<Text>(find.text('Cancel').first);
      expect(cancel.style?.fontFamily, 'JetBrains Mono');
      expect(cancel.style?.fontSize, 10);
      expect(cancel.style?.fontWeight, FontWeight.w600);
      expect(cancel.style?.color, const Color(0xFF00E6D2));
    });

    testWidgets('Cancel removes the open order from the list', (tester) async {
      await pumpScreen(tester);

      expect(find.text('AAPL'), findsOneWidget);

      await tester.tap(find.text('Cancel').last);
      await tester.pumpAndSettle();

      expect(find.text('AAPL'), findsNothing);
      expect(find.text('Cancel'), findsNWidgets(3));
    });

    testWidgets('History tab shows deterministic history orders', (
      tester,
    ) async {
      await pumpScreen(tester);

      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();

      for (final order in DeterministicMarketDataStore.historyOrders) {
        expect(find.text(order.symbol), findsWidgets);
      }
      expect(find.textContaining('09:12'), findsOneWidget);
      expect(find.textContaining('Yest'), findsNWidgets(2));
      expect(find.textContaining('Filled'), findsWidgets);
      expect(find.textContaining('Cancelled'), findsOneWidget);
    });

    testWidgets('history status colors match mockup', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();

      final filledStatus = tester.widget<Text>(
        find.textContaining('Filled').first,
      );
      expect(filledStatus.style?.color, const Color(0x8CFFFFFF));

      final cancelledStatus = tester.widget<Text>(
        find.textContaining('Cancelled'),
      );
      expect(cancelledStatus.style?.color, const Color(0x57FFFFFF));
    });

    testWidgets('Positions tab shows deterministic positions', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.text('Positions'));
      await tester.pumpAndSettle();

      for (final position in DeterministicMarketDataStore.portfolioPositions) {
        expect(find.text(position.symbol), findsWidgets);
      }
      expect(find.textContaining('Binance Perp'), findsOneWidget);
      expect(find.textContaining('1.84 BTC'), findsOneWidget);
      expect(find.text('LONG'), findsWidgets);
    });

    testWidgets('position row matches mockup styling', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.text('Positions'));
      await tester.pumpAndSettle();

      final value = tester.widget<Text>(find.text(r'$107,320').first);
      expect(value.style?.fontFamily, 'JetBrains Mono');
      expect(value.style?.fontSize, 12.5);
      expect(value.style?.fontWeight, FontWeight.w600);
      expect(value.style?.color, const Color(0xFFF2F5FA));

      final pnl = tester.widget<Text>(find.text(r'+$4,210'));
      expect(pnl.style?.fontFamily, 'JetBrains Mono');
      expect(pnl.style?.fontSize, 10.5);
      expect(pnl.style?.fontWeight, FontWeight.w600);
      expect(pnl.style?.color, const Color(0xFF2EE6A6));
    });

    testWidgets('screen does not overflow on iPhone 17 frame', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await pumpScreen(tester);

      expect(find.byType(OrdersHistoryScreen), findsOneWidget);
      await tester.binding.setSurfaceSize(null);
    });
  });
}
