import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:youtrade/core/result.dart';
import 'package:youtrade/domain/auth/local_auth_service.dart';
import 'package:youtrade/domain/entities/candle.dart';
import 'package:youtrade/domain/entities/order_book.dart';
import 'package:youtrade/domain/entities/symbol.dart';
import 'package:youtrade/domain/entities/ticker.dart';
import 'package:youtrade/domain/entities/timeframe.dart';
import 'package:youtrade/domain/entities/trade.dart';
import 'package:youtrade/domain/repositories/market_data_repository.dart';
import 'package:youtrade/presentation/auth/auth_guard_provider.dart';
import 'package:youtrade/presentation/providers/repository_provider.dart';
import 'package:youtrade/presentation/routing/app_router.dart';
import 'package:youtrade/presentation/theme/app_theme.dart';
import 'package:youtrade/presentation/theme/theme_mode.dart';
import 'package:youtrade/ui/screens/compare_screen.dart';
import 'package:youtrade/ui/screens/exchange_detail_screen.dart';
import 'package:youtrade/ui/screens/markets_screen.dart';
import 'package:youtrade/ui/screens/options_chain_screen.dart';
import 'package:youtrade/ui/screens/portfolio_screen.dart';
import 'package:youtrade/ui/screens/trading_terminal_screen.dart';

import '../../fakes/fake_pin_auth_service.dart';

class MockLocalAuthService extends Mock implements LocalAuthService {}

final class _FakeMarketDataRepository implements MarketDataRepository {
  @override
  Future<Result<Ticker>> getTicker(TradingSymbol symbol) async => Success(
    Ticker(
      symbol: symbol,
      lastPrice: 100000,
      bid: 99900,
      ask: 100100,
      change24h: 1000,
      change24hPercent: 0.01,
      volume: 1000,
      timestamp: DateTime.utc(2026, 1, 1),
    ),
  );

  @override
  Future<Result<List<Candle>>> getCandles(
    TradingSymbol symbol,
    Timeframe timeframe, {
    int? limit,
  }) async => const Success<List<Candle>>([]);

  @override
  Future<Result<OrderBook>> getOrderBook(
    TradingSymbol symbol, {
    int? depth,
  }) async => Success(
    OrderBook(
      bids: const [],
      asks: const [],
      timestamp: DateTime.utc(2026, 1, 1),
    ),
  );

  @override
  Future<Result<List<Trade>>> getTrades(
    TradingSymbol symbol, {
    int? limit,
  }) async => const Success<List<Trade>>([]);

  @override
  Stream<Result<Ticker>> watchTicker(TradingSymbol symbol) => Stream.value(
    Success(
      Ticker(
        symbol: symbol,
        lastPrice: 100000,
        bid: 99900,
        ask: 100100,
        change24h: 1000,
        change24hPercent: 0.01,
        volume: 1000,
        timestamp: DateTime.utc(2026, 1, 1),
      ),
    ),
  );

  @override
  Stream<Result<OrderBook>> watchOrderBook(TradingSymbol symbol) =>
      Stream.value(
        Success(
          OrderBook(
            bids: const [],
            asks: const [],
            timestamp: DateTime.utc(2026, 1, 1),
          ),
        ),
      );

  @override
  Stream<Result<List<Trade>>> watchTrades(TradingSymbol symbol) =>
      Stream.value(const Success<List<Trade>>([]));
}

void main() {
  late MockLocalAuthService mockService;
  late FakePinAuthService fakePinAuth;

  setUp(() {
    mockService = MockLocalAuthService();
    fakePinAuth = FakePinAuthService(initialPin: '1234');
  });

  ProviderContainer createContainer() {
    return ProviderContainer(
      overrides: [
        localAuthServiceProvider.overrideWithValue(mockService),
        pinAuthServiceProvider.overrideWithValue(fakePinAuth),
        marketDataRepositoryProvider.overrideWithValue(
          _FakeMarketDataRepository(),
        ),
      ],
    );
  }

  Future<void> pumpFrames(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  Widget buildRouter({
    required GoRouter router,
    required ProviderContainer container,
  }) {
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        theme: AppTheme.dark(AppVisualDirection.carbon),
        darkTheme: AppTheme.dark(AppVisualDirection.carbon),
        themeMode: ThemeMode.dark,
        routerConfig: router,
      ),
    );
  }

  group('AppRouter', () {
    testWidgets('redirects unauthenticated users to /auth', (tester) async {
      when(
        () => mockService.canCheckBiometrics(),
      ).thenAnswer((_) async => false);

      final container = createContainer();
      final router = container.read(appRouterProvider);

      await tester.pumpWidget(
        buildRouter(router: router, container: container),
      );
      await pumpFrames(tester);

      expect(router.state.uri.path, '/auth');
      expect(router.state.uri.queryParameters['from'], '/');
      expect(find.text('YouTrade is locked'), findsOneWidget);
    });

    testWidgets('allows unauthenticated users to access /markets', (
      tester,
    ) async {
      when(
        () => mockService.canCheckBiometrics(),
      ).thenAnswer((_) async => false);

      final container = createContainer();
      final router = container.read(appRouterProvider);
      router.go('/markets');

      await tester.pumpWidget(
        buildRouter(router: router, container: container),
      );
      await pumpFrames(tester);

      expect(router.state.uri.path, '/markets');
      expect(find.byType(MarketsScreen), findsOneWidget);
    });

    testWidgets('allows unauthenticated users to access /markets/compare', (
      tester,
    ) async {
      when(
        () => mockService.canCheckBiometrics(),
      ).thenAnswer((_) async => false);

      final container = createContainer();
      final router = container.read(appRouterProvider);
      router.go('/markets/compare');

      await tester.pumpWidget(
        buildRouter(router: router, container: container),
      );
      await pumpFrames(tester);

      expect(router.state.uri.path, '/markets/compare');
      expect(find.byType(CompareScreen), findsOneWidget);
    });

    testWidgets(
      'redirects unauthenticated users from /markets/exchange/:id to auth',
      (tester) async {
        when(
          () => mockService.canCheckBiometrics(),
        ).thenAnswer((_) async => false);

        final container = createContainer();
        final router = container.read(appRouterProvider);
        router.go('/markets/exchange/binance');

        await tester.pumpWidget(
          buildRouter(router: router, container: container),
        );
        await pumpFrames(tester);

        expect(router.state.uri.path, '/auth');
        expect(
          router.state.uri.queryParameters['from'],
          '/markets/exchange/binance',
        );
        expect(find.text('YouTrade is locked'), findsOneWidget);
      },
    );

    testWidgets(
      'redirects authenticated users back to requested route after auth',
      (tester) async {
        when(
          () => mockService.canCheckBiometrics(),
        ).thenAnswer((_) async => false);

        final container = createContainer();
        final router = container.read(appRouterProvider);
        router.go('/orders');

        await tester.pumpWidget(
          buildRouter(router: router, container: container),
        );
        await pumpFrames(tester);

        expect(router.state.uri.path, '/auth');
        expect(router.state.uri.queryParameters['from'], '/orders');

        await tester.enterText(find.byType(TextField), '1234');
        await tester.tap(find.text('Unlock with PIN'));
        await pumpFrames(tester);

        expect(router.state.uri.path, '/orders');
      },
    );

    testWidgets('bottom navigation switches tabs and updates URL', (
      tester,
    ) async {
      when(
        () => mockService.canCheckBiometrics(),
      ).thenAnswer((_) async => false);

      final container = createContainer();
      final router = container.read(appRouterProvider);

      await tester.pumpWidget(
        buildRouter(router: router, container: container),
      );
      await pumpFrames(tester);

      await tester.enterText(find.byType(TextField), '1234');
      await tester.tap(find.text('Unlock with PIN'));
      await pumpFrames(tester);

      expect(router.state.uri.path, '/');
      expect(find.byType(NavigationBar), findsOneWidget);

      await tester.tap(find.text('Markets'));
      await pumpFrames(tester);
      expect(router.state.uri.path, '/markets');
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        1,
      );

      await tester.tap(find.text('Trade'));
      await pumpFrames(tester);
      expect(router.state.uri.path, '/trading');
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        2,
      );

      await tester.tap(find.text('Options'));
      await pumpFrames(tester);
      expect(router.state.uri.path, '/markets/options/BTC');
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        3,
      );

      await tester.tap(find.text('More'));
      await pumpFrames(tester);
      expect(router.state.uri.path, '/account');
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        4,
      );
    });

    testWidgets(
      'deep links to /markets/exchange/binance render detail screen',
      (tester) async {
        when(
          () => mockService.canCheckBiometrics(),
        ).thenAnswer((_) async => false);

        final container = createContainer();
        final router = container.read(appRouterProvider);

        container
            .read(authNotifierProvider.notifier)
            .authenticateWithPin('1234');
        router.go('/markets/exchange/binance');

        await tester.pumpWidget(
          buildRouter(router: router, container: container),
        );
        await pumpFrames(tester);

        expect(router.state.uri.path, '/markets/exchange/binance');
        expect(find.byType(ExchangeDetailScreen), findsOneWidget);
        expect(find.text('Binance'), findsWidgets);
      },
    );

    testWidgets('deep links to /trading?symbol=BTC render trading terminal', (
      tester,
    ) async {
      when(
        () => mockService.canCheckBiometrics(),
      ).thenAnswer((_) async => false);

      final container = createContainer();
      final router = container.read(appRouterProvider);

      container.read(authNotifierProvider.notifier).authenticateWithPin('1234');
      router.go('/trading?symbol=BTC');

      await tester.pumpWidget(
        buildRouter(router: router, container: container),
      );
      await pumpFrames(tester);

      expect(router.state.uri.path, '/trading');
      expect(router.state.uri.queryParameters['symbol'], 'BTC');
      expect(find.byType(TradingTerminalScreen), findsOneWidget);
    });

    testWidgets('deep link /trading?symbol=ETH! falls back to default symbol', (
      tester,
    ) async {
      when(
        () => mockService.canCheckBiometrics(),
      ).thenAnswer((_) async => false);

      final container = createContainer();
      final router = container.read(appRouterProvider);

      container.read(authNotifierProvider.notifier).authenticateWithPin('1234');
      router.go('/trading?symbol=ETH!');

      await tester.pumpWidget(
        buildRouter(router: router, container: container),
      );
      await pumpFrames(tester);

      expect(router.state.uri.path, '/trading');
      expect(find.byType(TradingTerminalScreen), findsOneWidget);
      expect(find.textContaining('BTC'), findsWidgets);
    });

    testWidgets('deep links to /markets/options/BTC render options chain', (
      tester,
    ) async {
      when(
        () => mockService.canCheckBiometrics(),
      ).thenAnswer((_) async => false);

      final container = createContainer();
      final router = container.read(appRouterProvider);

      container.read(authNotifierProvider.notifier).authenticateWithPin('1234');
      router.go('/markets/options/BTC');

      await tester.pumpWidget(
        buildRouter(router: router, container: container),
      );
      await pumpFrames(tester);

      expect(router.state.uri.path, '/markets/options/BTC');
      expect(router.state.pathParameters['symbol'], 'BTC');
      expect(find.byType(OptionsChainScreen), findsOneWidget);
    });

    testWidgets(
      'deep links to /markets/options/BTCUSDT normalize display symbol',
      (tester) async {
        when(
          () => mockService.canCheckBiometrics(),
        ).thenAnswer((_) async => false);

        final container = createContainer();
        final router = container.read(appRouterProvider);

        container
            .read(authNotifierProvider.notifier)
            .authenticateWithPin('1234');
        router.go('/markets/options/BTCUSDT');

        await tester.pumpWidget(
          buildRouter(router: router, container: container),
        );
        await pumpFrames(tester);

        expect(router.state.uri.path, '/markets/options/BTCUSDT');
        expect(router.state.pathParameters['symbol'], 'BTCUSDT');
        expect(find.byType(OptionsChainScreen), findsOneWidget);
        expect(find.text('BTC'), findsOneWidget);
      },
    );

    testWidgets('/markets/options defaults to BTC for authenticated users', (
      tester,
    ) async {
      when(
        () => mockService.canCheckBiometrics(),
      ).thenAnswer((_) async => false);

      final container = createContainer();
      final router = container.read(appRouterProvider);

      container.read(authNotifierProvider.notifier).authenticateWithPin('1234');
      router.go('/markets/options');

      await tester.pumpWidget(
        buildRouter(router: router, container: container),
      );
      await pumpFrames(tester);

      expect(router.state.uri.path, '/markets/options/BTC');
      expect(router.state.pathParameters['symbol'], 'BTC');
      expect(find.byType(OptionsChainScreen), findsOneWidget);
    });

    testWidgets(
      'redirects unauthenticated users from /markets/options to auth',
      (tester) async {
        when(
          () => mockService.canCheckBiometrics(),
        ).thenAnswer((_) async => false);

        final container = createContainer();
        final router = container.read(appRouterProvider);
        router.go('/markets/options');

        await tester.pumpWidget(
          buildRouter(router: router, container: container),
        );
        await pumpFrames(tester);

        expect(router.state.uri.path, '/auth');
        expect(router.state.uri.queryParameters['from'], '/markets/options');
        expect(find.text('YouTrade is locked'), findsOneWidget);
      },
    );

    testWidgets('redirects authenticated users away from /auth', (
      tester,
    ) async {
      when(
        () => mockService.canCheckBiometrics(),
      ).thenAnswer((_) async => false);

      final container = createContainer();
      final router = container.read(appRouterProvider);

      container.read(authNotifierProvider.notifier).authenticateWithPin('1234');
      router.go('/auth');

      await tester.pumpWidget(
        buildRouter(router: router, container: container),
      );
      await pumpFrames(tester);

      expect(router.state.uri.path, '/');
      expect(find.byType(PortfolioScreen), findsOneWidget);
    });

    testWidgets('rejects external redirect target in from query parameter', (
      tester,
    ) async {
      when(
        () => mockService.canCheckBiometrics(),
      ).thenAnswer((_) async => false);

      final container = createContainer();
      final router = container.read(appRouterProvider);
      router.go('/auth?from=https://example.com');

      container.read(authNotifierProvider.notifier).authenticateWithPin('1234');

      await tester.pumpWidget(
        buildRouter(router: router, container: container),
      );
      await pumpFrames(tester);

      expect(router.state.uri.path, '/');
      expect(find.byType(PortfolioScreen), findsOneWidget);
    });

    testWidgets('rejects from query parameter starting with //', (
      tester,
    ) async {
      when(
        () => mockService.canCheckBiometrics(),
      ).thenAnswer((_) async => false);

      final container = createContainer();
      final router = container.read(appRouterProvider);
      router.go('/auth?from=//evil.com');

      container.read(authNotifierProvider.notifier).authenticateWithPin('1234');

      await tester.pumpWidget(
        buildRouter(router: router, container: container),
      );
      await pumpFrames(tester);

      expect(router.state.uri.path, '/');
      expect(find.byType(PortfolioScreen), findsOneWidget);
    });

    testWidgets('falls back to home for invalid deep links', (tester) async {
      when(
        () => mockService.canCheckBiometrics(),
      ).thenAnswer((_) async => false);

      final container = createContainer();
      final router = container.read(appRouterProvider);

      container.read(authNotifierProvider.notifier).authenticateWithPin('1234');
      router.go('/not-a-valid-route');

      await tester.pumpWidget(
        buildRouter(router: router, container: container),
      );
      await pumpFrames(tester);

      expect(router.state.uri.path, '/');
      expect(find.byType(PortfolioScreen), findsOneWidget);
    });

    testWidgets(
      'preserves markets shell branch when navigating within branch',
      (tester) async {
        when(
          () => mockService.canCheckBiometrics(),
        ).thenAnswer((_) async => false);

        final container = createContainer();
        final router = container.read(appRouterProvider);

        container
            .read(authNotifierProvider.notifier)
            .authenticateWithPin('1234');
        router.go('/markets');

        await tester.pumpWidget(
          buildRouter(router: router, container: container),
        );
        await pumpFrames(tester);

        expect(router.state.uri.path, '/markets');
        expect(find.byType(NavigationBar), findsOneWidget);
        expect(
          tester
              .widget<NavigationBar>(find.byType(NavigationBar))
              .selectedIndex,
          1,
        );

        router.go('/markets/exchange/binance');
        await pumpFrames(tester);

        expect(router.state.uri.path, '/markets/exchange/binance');
        expect(find.byType(ExchangeDetailScreen), findsOneWidget);
        expect(
          tester
              .widget<NavigationBar>(find.byType(NavigationBar))
              .selectedIndex,
          1,
        );
      },
    );
  });
}
