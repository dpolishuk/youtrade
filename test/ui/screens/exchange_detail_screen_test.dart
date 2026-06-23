import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:youtrade/presentation/theme/app_theme.dart';
import 'package:youtrade/presentation/theme/theme_mode.dart';
import 'package:youtrade/ui/screens/exchange_detail_screen.dart';

void main() {
  Widget buildScreen({String exchangeId = 'binance'}) {
    return ProviderScope(
      child: MaterialApp(
        theme: AppTheme.dark(AppVisualDirection.flux),
        home: ExchangeDetailScreen(exchangeId: exchangeId),
      ),
    );
  }

  group('ExchangeDetailScreen', () {
    testWidgets('renders Binance detail exactly from mockup', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('All portfolios'), findsOneWidget);
      expect(find.text('Binance'), findsWidgets);
      expect(find.text('Spot · Perp · Options'), findsOneWidget);
      expect(find.text('API LIVE'), findsOneWidget);

      expect(find.text('Balance'), findsOneWidget);
      expect(find.text(r'$312,480'), findsOneWidget);

      expect(find.text('24h P&L'), findsOneWidget);
      expect(find.text(r'+$6,620'), findsOneWidget);
      expect(find.text('+2.12%'), findsOneWidget);

      expect(find.text('Balances'), findsOneWidget);

      expect(find.text('BTC'), findsOneWidget);
      expect(find.text('ETH'), findsOneWidget);
      expect(find.text('USDT'), findsOneWidget);
      expect(find.text('SOL'), findsOneWidget);

      expect(find.text(r'$193,483'), findsOneWidget);
      expect(find.text(r'$35,810'), findsOneWidget);
      expect(find.text(r'$88,420'), findsOneWidget);
      expect(find.text(r'$35,072'), findsOneWidget);

      expect(find.text('62%'), findsOneWidget);
      expect(find.text('11%'), findsNWidgets(2));
      expect(find.text('28%'), findsOneWidget);
    });

    testWidgets('switches to Bybit when chip tapped', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Bybit'));
      await tester.pumpAndSettle();

      expect(find.text('Bybit'), findsWidgets);
      expect(find.text('Perp · Spot'), findsOneWidget);
      expect(find.text(r'$198,320'), findsOneWidget);
      expect(find.text(r'-$1,710'), findsOneWidget);
      expect(find.text('-0.86%'), findsOneWidget);

      expect(find.text('ETH'), findsOneWidget);
      expect(find.text(r'$64,977'), findsOneWidget);
      expect(find.text(r'$64,200'), findsOneWidget);
      expect(find.text('BTC'), findsOneWidget);
      expect(find.text(r'$94,639'), findsOneWidget);
    });

    testWidgets('switches to OKX when chip tapped', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('OKX'));
      await tester.pumpAndSettle();

      expect(find.text('OKX'), findsWidgets);
      expect(find.text('Spot · Perp · Options'), findsOneWidget);
      expect(find.text(r'$146,900'), findsOneWidget);
      expect(find.text(r'+$2,080'), findsOneWidget);
      expect(find.text('+1.42%'), findsOneWidget);

      expect(find.text('XAU'), findsOneWidget);
      expect(find.text(r'$33,350'), findsOneWidget);
      expect(find.text(r'$98,300'), findsOneWidget);
      expect(find.text('SOL'), findsOneWidget);
      expect(find.text(r'$70,143'), findsOneWidget);
    });

    testWidgets('switches to Coinbase when chip tapped', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Coinbase'));
      await tester.pumpAndSettle();

      expect(find.text('Coinbase'), findsWidgets);
      expect(find.text('Spot · Stocks'), findsOneWidget);
      expect(find.text(r'$88,540'), findsOneWidget);
      expect(find.text(r'+$270'), findsOneWidget);
      expect(find.text('+0.30%'), findsOneWidget);

      expect(find.text('AAPL'), findsOneWidget);
      expect(find.text(r'$28,199'), findsOneWidget);
      expect(find.text('NVDA'), findsOneWidget);
      expect(find.text(r'$16,000'), findsOneWidget);
      expect(find.text('USD'), findsOneWidget);
      expect(find.text(r'$32,100'), findsOneWidget);
    });

    testWidgets('renders Binance fallback for unknown exchange id', (
      tester,
    ) async {
      await tester.pumpWidget(buildScreen(exchangeId: 'unknown'));
      await tester.pumpAndSettle();

      expect(find.text('Binance'), findsWidgets);
      expect(find.text('Spot · Perp · Options'), findsOneWidget);
      expect(find.text(r'$312,480'), findsOneWidget);
      expect(find.text('Bybit'), findsOneWidget);
      expect(find.text('OKX'), findsOneWidget);
      expect(find.text('Coinbase'), findsOneWidget);
    });

    testWidgets('back button pops the route', (tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            navigatorKey: navigatorKey,
            theme: AppTheme.dark(AppVisualDirection.flux),
            home: const Scaffold(body: Center(child: Text('Home'))),
          ),
        ),
      );

      navigatorKey.currentState!.push(
        MaterialPageRoute(builder: (_) => const ExchangeDetailScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('All portfolios'), findsOneWidget);

      await tester.tap(find.text('All portfolios'));
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('renders Binance for unknown exchange id', (tester) async {
      await tester.pumpWidget(buildScreen(exchangeId: 'not-a-venue'));
      await tester.pumpAndSettle();

      expect(find.text('Binance'), findsWidgets);
      expect(find.text(r'$312,480'), findsOneWidget);
    });
  });
}
