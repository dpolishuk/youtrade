import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:youtrade/domain/entities/order.dart';
import 'package:youtrade/presentation/theme/app_theme.dart';
import 'package:youtrade/presentation/theme/theme_mode.dart';
import 'package:youtrade/ui/widgets/orders/order_list_tile.dart';

void main() {
  group('OrderListTile', () {
    Future<void> pumpTile(
      WidgetTester tester, {
      required Order order,
      void Function(Order order)? onCancel,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(AppVisualDirection.flux),
          home: Scaffold(
            body: OrderListTile(order: order, onCancel: onCancel),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('passes the order object to onCancel when tapped', (
      tester,
    ) async {
      const order = Order(
        symbol: 'BTCUSDT',
        side: 'BUY',
        type: 'LIMIT',
        venue: 'Binance',
        price: '58,400.0',
        qty: '0.50',
        filled: '0.17',
      );
      Order? capturedOrder;

      await pumpTile(tester, order: order, onCancel: (o) => capturedOrder = o);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(capturedOrder, order);
    });
  });
}
