import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:youtrade/presentation/theme/app_theme.dart';
import 'package:youtrade/presentation/theme/theme_mode.dart';
import 'package:youtrade/ui/screens/exchange_detail_screen.dart';

void main() {
  Widget buildScreen() {
    return MaterialApp(
      theme: AppTheme.dark(AppVisualDirection.flux),
      home: const ExchangeDetailScreen(),
    );
  }

  group('ExchangeDetailScreen', () {
    testWidgets('renders venue header and status cards', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('All portfolios'), findsOneWidget);

      expect(find.text('Binance'), findsWidgets);
      expect(find.text('45.2%'), findsOneWidget);
      expect(find.text('Spot · Perp · Options'), findsOneWidget);

      expect(find.text('API LIVE'), findsOneWidget);
      expect(find.text('Read-only keys active'), findsOneWidget);

      expect(find.text('Balance'), findsOneWidget);
      expect(find.text(r'$312,480.00'), findsOneWidget);

      expect(find.text('24h P&L'), findsOneWidget);
      expect(find.text(r'+$6,620.00'), findsOneWidget);
      expect(find.text('+2.12%'), findsOneWidget);
    });

    testWidgets('shows asset balances with values and shares', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Balances'), findsOneWidget);

      expect(find.text('BTC'), findsOneWidget);
      expect(find.text('ETH'), findsOneWidget);
      expect(find.text('USDT'), findsOneWidget);
      expect(find.text('SOL'), findsOneWidget);

      expect(find.text(r'$158,400'), findsOneWidget);
      expect(find.text(r'$37,120'), findsOneWidget);
      expect(find.text(r'$88,420'), findsOneWidget);
      expect(find.text(r'$28,540'), findsOneWidget);

      expect(find.text('1%'), findsOneWidget);
      expect(find.text('0%'), findsNWidgets(3));
    });

    testWidgets('shows recent trade history with exact details', (
      tester,
    ) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Recent Trades'), findsOneWidget);

      expect(find.text('BUY'), findsNWidgets(2));
      expect(find.text('SELL'), findsOneWidget);

      expect(find.text('BTCUSDT'), findsOneWidget);
      expect(find.text('ETHUSDT'), findsOneWidget);
      expect(find.text('SOLUSDT'), findsOneWidget);

      expect(find.text('Limit · Binance · 09:12'), findsOneWidget);
      expect(find.text('Stop · Binance · 08:47'), findsOneWidget);
      expect(find.text('Limit · Binance · 08:30'), findsOneWidget);

      expect(find.text(r'$58,400.0'), findsOneWidget);
      expect(find.text(r'$3,050.00'), findsOneWidget);
      expect(find.text(r'$150.00'), findsOneWidget);

      expect(find.text('0.50 BTC'), findsOneWidget);
      expect(find.text('8.0 ETH'), findsOneWidget);
      expect(find.text('120 SOL'), findsOneWidget);
    });
  });
}
