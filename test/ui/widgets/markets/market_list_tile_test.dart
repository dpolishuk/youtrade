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
    name: 'Bitcoin / USD',
    venue: Venue.binance,
    assetClass: AssetClass.crypto,
    price: 68421.35,
    change24hPercent: 2.34,
    sparkline: [66200, 66800, 67100, 66900, 67500, 67900, 67700, 68100, 68421],
  );

  const optionsMarket = MarketScreenerItem(
    symbol: 'BTCOPT',
    name: 'Bitcoin Options',
    venue: Venue.binance,
    assetClass: AssetClass.options,
    price: 0.0,
    change24hPercent: 0.0,
    sparkline: [0.1, 0.2, 0.15, 0.18, 0.12, 0.14, 0.16, 0.13, 0.15],
  );

  Widget buildTile(MarketScreenerItem market, GoRouter router) {
    return MaterialApp.router(
      theme: AppTheme.dark(AppVisualDirection.carbon),
      routerConfig: router,
    );
  }

  group('MarketListTile', () {
    testWidgets('navigates to /trading?symbol=BTC for regular market', (
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
      expect(router.state.uri.queryParameters['symbol'], 'BTC');
    });

    testWidgets('navigates to /markets/options/BTCOPT for options market', (
      tester,
    ) async {
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
          GoRoute(
            path: '/markets/options/:symbol',
            builder: (_, _) => const Scaffold(body: Text('Options')),
          ),
        ],
      );

      await tester.pumpWidget(buildTile(optionsMarket, router));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(MarketListTile));
      await tester.pumpAndSettle();

      expect(router.state.uri.path, '/markets/options/BTCOPT');
      expect(router.state.pathParameters['symbol'], 'BTCOPT');
    });
  });
}
