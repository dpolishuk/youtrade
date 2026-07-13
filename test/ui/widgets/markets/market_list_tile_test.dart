import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:youtrade/domain/entities/venue.dart';
import 'package:youtrade/presentation/providers/market_screener_provider.dart';
import 'package:youtrade/presentation/theme/app_theme.dart';
import 'package:youtrade/presentation/theme/theme_mode.dart';
import 'package:youtrade/ui/widgets/markets/market_list_tile.dart';

void main() {
  const cryptoMarket = MarketScreenerItem(
    symbol: 'BTC',
    rawSymbol: 'BTCUSDT',
    name: 'Bitcoin Perp',
    venue: Venue.binance,
    assetClass: AssetClass.perp,
    price: 105154.04697406417,
    change24hPercent: 6.42,
    priceDecimals: 1,
    sparkline: [
      101991.92,
      102500.0,
      103000.0,
      103500.0,
      104000.0,
      104500.0,
      105000.0,
      105154.04697406417,
    ],
  );

  const optionsMarket = MarketScreenerItem(
    symbol: 'BTC-28K-C',
    rawSymbol: 'BTC-28K-C',
    name: 'BTC Call 70k',
    venue: Venue.bybit,
    assetClass: AssetClass.spot,
    price: 0.0421,
    change24hPercent: 8.12,
    priceDecimals: 4,
    sparkline: [],
  );

  Widget buildTile(MarketScreenerItem market, GoRouter router) {
    return MaterialApp.router(
      theme: AppTheme.dark(AppVisualDirection.carbon),
      routerConfig: router,
    );
  }

  group('MarketListTile', () {
    testWidgets('renders symbol, badge, name, venue, price and change', (
      tester,
    ) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) =>
                Scaffold(body: MarketListTile(market: cryptoMarket)),
          ),
        ],
      );

      await tester.pumpWidget(buildTile(cryptoMarket, router));
      await tester.pumpAndSettle();

      expect(find.text('BTC'), findsOneWidget);
      expect(find.text('PERP'), findsOneWidget);
      expect(find.text('Bitcoin Perp'), findsOneWidget);
      expect(find.text('BIN'), findsOneWidget);
      expect(find.text('105,154.0'), findsOneWidget);
      expect(find.text('+6.42%'), findsOneWidget);

      final theme = Theme.of(tester.element(find.byType(MarketListTile)));
      final symbolText = tester.widget<Text>(find.text('BTC'));
      expect(symbolText.style?.color, theme.colorScheme.onSurface);
    });

    testWidgets('navigates to /trading?symbol=BTCUSDT for regular market', (
      tester,
    ) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) =>
                Scaffold(body: MarketListTile(market: cryptoMarket)),
          ),
          GoRoute(
            path: '/trading',
            builder: (_, _) => const Scaffold(body: Text('Trading')),
          ),
          GoRoute(
            path: '/markets/options/:symbol',
            builder: (_, _) => const Scaffold(body: Text('Options')),
          ),
        ],
      );

      await tester.pumpWidget(buildTile(cryptoMarket, router));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(MarketListTile));
      await tester.pumpAndSettle();

      expect(router.state.uri.path, '/trading');
      expect(router.state.uri.queryParameters['symbol'], 'BTCUSDT');
    });

    testWidgets('all markets navigate to trading terminal', (tester) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) =>
                Scaffold(body: MarketListTile(market: optionsMarket)),
          ),
          GoRoute(
            path: '/trading',
            builder: (_, _) => const Scaffold(body: Text('Trading')),
          ),
        ],
      );

      await tester.pumpWidget(buildTile(optionsMarket, router));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(MarketListTile));
      await tester.pumpAndSettle();

      expect(router.state.uri.path, '/trading');
      expect(router.state.uri.queryParameters['symbol'], 'BTC-28K-C');
    });
  });
}
