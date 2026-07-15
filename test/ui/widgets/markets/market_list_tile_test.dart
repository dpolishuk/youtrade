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

  const longSymbolMarket = MarketScreenerItem(
    symbol: '10000PEPE',
    rawSymbol: '10000PEPEUSDT',
    name: '10000 Pepe',
    venue: Venue.bybit,
    assetClass: AssetClass.perp,
    price: 0.012345,
    change24hPercent: -3.21,
    priceDecimals: 5,
    sparkline: [],
  );

  const metricsMarket = MarketScreenerItem(
    symbol: 'ETH',
    rawSymbol: 'ETHUSDT',
    name: 'Ethereum Perp',
    venue: Venue.bybit,
    assetClass: AssetClass.perp,
    price: 3200.0,
    change24hPercent: 2.5,
    priceDecimals: 2,
    turnover24h: 1234567890.0,
    openInterestValue: 4567000000.0,
    fundingRate: 0.0001,
    highPrice24h: 3300.0,
    lowPrice24h: 3100.0,
    prevPrice24h: 3200.0,
    bid1Price: 3198.0,
    ask1Price: 3202.0,
    sparkline: [],
  );

  Widget buildTile(MarketScreenerItem market, GoRouter router) {
    return MaterialApp.router(
      theme: AppTheme.dark(AppVisualDirection.carbon),
      routerConfig: router,
    );
  }

  Widget buildTileWithSort(MarketScreenerItem market, SortOption? activeSort) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => Scaffold(
            body: MarketListTile(market: market, activeSort: activeSort),
          ),
        ),
      ],
    );
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

    testWidgets('long symbol renders without overflow', (tester) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) =>
                Scaffold(body: MarketListTile(market: longSymbolMarket)),
          ),
        ],
      );

      await tester.pumpWidget(buildTile(longSymbolMarket, router));
      await tester.pumpAndSettle();

      expect(find.text('10000PEPE'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('default shows price and change', (tester) async {
      await tester.pumpWidget(buildTileWithSort(metricsMarket, null));
      await tester.pumpAndSettle();

      expect(find.text('3,200.00'), findsOneWidget);
      expect(find.text('+2.50%'), findsOneWidget);
      expect(find.text('VOLUME'), findsNothing);
      expect(find.text('OI'), findsNothing);
    });

    testWidgets('sort by volume shows turnover', (tester) async {
      await tester.pumpWidget(
        buildTileWithSort(metricsMarket, SortOption.turnover),
      );
      await tester.pumpAndSettle();

      expect(find.text('\$1.2B'), findsOneWidget);
      expect(find.text('VOLUME'), findsOneWidget);
      expect(find.text('3,200.00'), findsNothing);
    });

    testWidgets('sort by open interest shows OI', (tester) async {
      await tester.pumpWidget(
        buildTileWithSort(metricsMarket, SortOption.openInterest),
      );
      await tester.pumpAndSettle();

      expect(find.text('\$4.6B'), findsOneWidget);
      expect(find.text('OI'), findsOneWidget);
    });

    testWidgets('sort by funding shows funding rate colored', (tester) async {
      await tester.pumpWidget(
        buildTileWithSort(metricsMarket, SortOption.fundingRate),
      );
      await tester.pumpAndSettle();

      // fundingRate 0.0001 -> *100 -> 0.01%
      expect(find.text('0.01'), findsOneWidget);
      expect(find.text('FUNDING'), findsOneWidget);
      final fundingText = tester.widget<Text>(find.text('0.01'));
      expect(fundingText.style?.color, isNotNull);
    });

    testWidgets('sort by volatility shows range percent', (tester) async {
      await tester.pumpWidget(
        buildTileWithSort(metricsMarket, SortOption.volatility),
      );
      await tester.pumpAndSettle();

      // range = (3300 - 3100) / 3200 * 100 = 6.25%
      expect(find.text('6.25'), findsOneWidget);
      expect(find.text('VOLAT'), findsOneWidget);
    });

    testWidgets('sort by spread shows basis points', (tester) async {
      await tester.pumpWidget(
        buildTileWithSort(metricsMarket, SortOption.spread),
      );
      await tester.pumpAndSettle();

      // mid = 3200, spread = (3202 - 3198) / 3200 * 10000 = 12.5bp
      expect(find.text('12.5bp'), findsOneWidget);
      expect(find.text('SPRD'), findsOneWidget);
    });

    testWidgets('sort by score keeps default price view', (tester) async {
      await tester.pumpWidget(
        buildTileWithSort(metricsMarket, SortOption.score),
      );
      await tester.pumpAndSettle();

      expect(find.text('3,200.00'), findsOneWidget);
      expect(find.text('+2.50%'), findsOneWidget);
      expect(find.text('VOLUME'), findsNothing);
    });
  });
}
