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

import '../../../fakes/fake_pin_auth_service.dart';

class _MockLocalAuthService extends Mock implements LocalAuthService {}

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
  late _MockLocalAuthService mockService;
  late FakePinAuthService fakePinAuth;

  setUp(() {
    mockService = _MockLocalAuthService();
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

  group('ScaffoldWithNavBar', () {
    testWidgets('renders mockup tab labels in order', (tester) async {
      when(
        () => mockService.canCheckBiometrics(),
      ).thenAnswer((_) async => false);

      final container = createContainer();
      final router = container.read(appRouterProvider);

      container.read(authNotifierProvider.notifier).authenticateWithPin('1234');
      router.go('/');

      await tester.pumpWidget(
        buildRouter(router: router, container: container),
      );
      await pumpFrames(tester);

      final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      final labels = navBar.destinations
          .whereType<NavigationDestination>()
          .map((d) => d.label)
          .toList();

      expect(labels, ['Portfolio', 'Markets', 'Trade', 'Options', 'More']);
    });

    testWidgets('uses mockup background and indicator colors', (tester) async {
      when(
        () => mockService.canCheckBiometrics(),
      ).thenAnswer((_) async => false);

      final container = createContainer();
      final router = container.read(appRouterProvider);

      container.read(authNotifierProvider.notifier).authenticateWithPin('1234');
      router.go('/');

      await tester.pumpWidget(
        buildRouter(router: router, container: container),
      );
      await pumpFrames(tester);

      final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(navBar.backgroundColor, const Color(0xFF080B12));
      expect(navBar.indicatorColor, Colors.transparent);
    });
  });
}
