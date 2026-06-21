import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:youtrade/presentation/theme/app_theme.dart';
import 'package:youtrade/presentation/theme/theme_mode.dart';
import 'package:youtrade/ui/screens/orders_history_screen.dart';

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

    testWidgets('renders without overflow and shows tabs', (tester) async {
      await pumpScreen(tester);

      expect(find.text('Orders'), findsOneWidget);
      expect(find.text('Open'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);
      expect(find.text('Positions'), findsOneWidget);
    });

    testWidgets('shows open orders by default', (tester) async {
      await pumpScreen(tester);

      expect(find.text('BTCUSDT'), findsWidgets);
      expect(find.text('Cancel'), findsWidgets);
      expect(find.textContaining('0%'), findsWidgets);
    });

    testWidgets('switches to History tab and shows filled orders', (
      tester,
    ) async {
      await pumpScreen(tester);

      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Filled'), findsWidgets);
      expect(find.textContaining('Cancelled'), findsOneWidget);
      expect(find.textContaining('09:12'), findsOneWidget);
    });

    testWidgets('switches to Positions tab and shows positions', (
      tester,
    ) async {
      await pumpScreen(tester);

      await tester.tap(find.text('Positions'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Binance Perp'), findsOneWidget);
      expect(find.textContaining('1.84 BTC'), findsOneWidget);
      expect(find.text('LONG'), findsWidgets);
    });
  });
}
