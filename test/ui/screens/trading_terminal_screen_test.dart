import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:youtrade/core/failures.dart';
import 'package:youtrade/core/result.dart';
import 'package:youtrade/data/datasources/mock/deterministic_market_data_store.dart';
import 'package:youtrade/data/repositories/market_data_repository_impl.dart';
import 'package:youtrade/domain/entities/candle.dart';
import 'package:youtrade/domain/entities/order_book.dart';
import 'package:youtrade/domain/entities/symbol.dart';
import 'package:youtrade/domain/entities/ticker.dart';
import 'package:youtrade/domain/entities/timeframe.dart';
import 'package:youtrade/domain/entities/trade.dart';
import 'package:youtrade/domain/entities/venue.dart';
import 'package:youtrade/domain/registry/exchange_capability.dart';
import 'package:youtrade/domain/repositories/market_data_repository.dart';
import 'package:youtrade/presentation/providers/market_screener_provider.dart';
import 'package:youtrade/presentation/providers/repository_provider.dart';
import 'package:youtrade/presentation/theme/app_theme.dart';
import 'package:youtrade/presentation/theme/theme_mode.dart';
import 'package:youtrade/ui/screens/trading_terminal_screen.dart';
import 'package:youtrade/ui/widgets/trading_terminal/candlestick_chart.dart';
import 'package:youtrade/ui/widgets/trading_terminal/fundamentals_card.dart';
import 'package:youtrade/ui/widgets/trading_terminal/signal_gauge.dart';
import 'package:youtrade/ui/widgets/trading_terminal/trade_ticket.dart';

final _deterministicRepository = _DeterministicRepository();

final class _DeterministicRepository implements MarketDataRepository {
  _DeterministicRepository()
    : _delegate = MarketDataRepositoryImpl(
        registry: const _FakeRegistry(),
        fallbackStore: const DeterministicMarketDataStore(),
      );

  final MarketDataRepository _delegate;

  @override
  Future<Result<Ticker>> getTicker(TradingSymbol symbol) =>
      _delegate.getTicker(symbol);

  @override
  Future<Result<List<Candle>>> getCandles(
    TradingSymbol symbol,
    Timeframe timeframe, {
    int? limit,
  }) => _delegate.getCandles(symbol, timeframe, limit: limit);

  @override
  Future<Result<OrderBook>> getOrderBook(TradingSymbol symbol, {int? depth}) =>
      _delegate.getOrderBook(symbol, depth: depth);

  @override
  Future<Result<List<Trade>>> getTrades(TradingSymbol symbol, {int? limit}) =>
      _delegate.getTrades(symbol, limit: limit);

  @override
  Stream<Result<Ticker>> watchTicker(TradingSymbol symbol) async* {
    yield await getTicker(symbol);
  }

  @override
  Stream<Result<OrderBook>> watchOrderBook(TradingSymbol symbol) async* {
    yield await getOrderBook(symbol);
  }

  @override
  Stream<Result<List<Trade>>> watchTrades(TradingSymbol symbol) async* {
    yield await getTrades(symbol);
  }
}

final class _FakeRegistry implements ExchangeCapabilityRegistry {
  const _FakeRegistry();

  @override
  List<ExchangeCapability> get all => [];

  @override
  ExchangeCapability? forVenue(Venue venue) => const ExchangeCapability(
    venue: Venue.binance,
    supportedFeatures: {
      MarketDataFeature.restTicker,
      MarketDataFeature.restCandles,
      MarketDataFeature.restOrderBook,
      MarketDataFeature.restTrades,
      MarketDataFeature.wsTicker,
      MarketDataFeature.wsOrderBook,
      MarketDataFeature.wsTrades,
    },
  );

  @override
  bool isSymbolSupported(TradingSymbol symbol) => true;
}

final class _ErrorRepository implements MarketDataRepository {
  const _ErrorRepository();

  @override
  Future<Result<Ticker>> getTicker(TradingSymbol symbol) async =>
      const Err<Ticker>(UnknownFailure('Repository error'));

  @override
  Future<Result<List<Candle>>> getCandles(
    TradingSymbol symbol,
    Timeframe timeframe, {
    int? limit,
  }) async => const Err<List<Candle>>(UnknownFailure('Repository error'));

  @override
  Future<Result<OrderBook>> getOrderBook(
    TradingSymbol symbol, {
    int? depth,
  }) async => const Err<OrderBook>(UnknownFailure('Repository error'));

  @override
  Future<Result<List<Trade>>> getTrades(
    TradingSymbol symbol, {
    int? limit,
  }) async => const Err<List<Trade>>(UnknownFailure('Repository error'));

  @override
  Stream<Result<Ticker>> watchTicker(TradingSymbol symbol) =>
      Stream.value(const Err<Ticker>(UnknownFailure('Repository error')));

  @override
  Stream<Result<OrderBook>> watchOrderBook(TradingSymbol symbol) =>
      Stream.value(const Err<OrderBook>(UnknownFailure('Repository error')));

  @override
  Stream<Result<List<Trade>>> watchTrades(TradingSymbol symbol) =>
      Stream.value(const Err<List<Trade>>(UnknownFailure('Repository error')));
}

final _testScreenerItems = [
  MarketScreenerItem(
    symbol: displaySymbol('BTCUSDT'),
    rawSymbol: 'BTCUSDT',
    name: 'BTCUSDT',
    venue: Venue.bybit,
    assetClass: AssetClass.perp,
    price: 65000.0,
    change24hPercent: 5.23,
    priceDecimals: 1,
  ),
  MarketScreenerItem(
    symbol: displaySymbol('ETHUSDT'),
    rawSymbol: 'ETHUSDT',
    name: 'ETHUSDT',
    venue: Venue.bybit,
    assetClass: AssetClass.perp,
    price: 3200.0,
    change24hPercent: -2.34,
    priceDecimals: 2,
  ),
];

Widget _buildApp({String? symbol}) {
  return ProviderScope(
    overrides: [
      marketDataRepositoryProvider.overrideWithValue(_deterministicRepository),
      marketScreenerItemsProvider.overrideWith(
        (ref) async => _testScreenerItems,
      ),
    ],
    child: MaterialApp.router(
      theme: AppTheme.dark(AppVisualDirection.flux),
      routerConfig: GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => TradingTerminalScreen(symbol: symbol),
          ),
          GoRoute(
            path: '/markets/compare',
            builder: (context, state) =>
                const Scaffold(body: Center(child: Text('Compare'))),
          ),
        ],
      ),
    ),
  );
}

void main() {
  group('TradingTerminalScreen', () {
    testWidgets('normalizes BTCUSDT symbol parameter to BTC', (tester) async {
      final repository = _SymbolRecordingRepository();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            marketDataRepositoryProvider.overrideWithValue(repository),
          ],
          child: MaterialApp.router(
            theme: AppTheme.dark(AppVisualDirection.flux),
            routerConfig: GoRouter(
              routes: [
                GoRoute(
                  path: '/',
                  builder: (context, state) =>
                      const TradingTerminalScreen(symbol: 'BTCUSDT'),
                ),
                GoRoute(
                  path: '/markets/compare',
                  builder: (context, state) =>
                      const Scaffold(body: Center(child: Text('Compare'))),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      for (var i = 0; i < 20 && repository.recordedSymbol == null; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(repository.recordedSymbol, isNotNull);
      expect(repository.recordedSymbol!.base, 'BTC');
      expect(repository.recordedSymbol!.rawSymbol, 'BTCUSDT');
    });

    testWidgets('repository error shows error UI with retry button', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            marketDataRepositoryProvider.overrideWithValue(
              const _ErrorRepository(),
            ),
          ],
          child: MaterialApp.router(
            theme: AppTheme.dark(AppVisualDirection.flux),
            routerConfig: GoRouter(
              routes: [
                GoRoute(
                  path: '/',
                  builder: (context, state) => const TradingTerminalScreen(),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Failed to load market data'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('renders BTC terminal with deterministic values', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(CandlestickChart), findsOneWidget);
      expect(find.byType(TradeTicket), findsOneWidget);
      expect(find.text('Trade'), findsOneWidget);
      expect(find.text('Book'), findsOneWidget);
      expect(find.text('Info'), findsOneWidget);
      expect(find.text('Signals'), findsOneWidget);

      // Search bar shows the currently selected symbol as hint text.
      expect(find.text('BTC'), findsWidgets);
      expect(find.text('BTCUSDT'), findsOneWidget);

      // Class tag and header metadata.
      expect(find.text('PERP'), findsOneWidget);
      expect(find.text('Bitcoin Perpetual · Bybit'), findsOneWidget);

      // Last price uses one decimal for BTC.
      expect(find.text('105,154.0'), findsWidgets);
      expect(find.textContaining('+6.42%'), findsOneWidget);

      // Trade tab defaults.
      expect(find.text('Limit'), findsOneWidget);
      expect(find.text('Market'), findsOneWidget);
      expect(find.text('Stop'), findsOneWidget);
      expect(find.text('Buy / Long BTC'), findsOneWidget);
    });

    testWidgets('uses symbol parameter when provided', (tester) async {
      await tester.pumpWidget(_buildApp(symbol: 'ETH'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('ETHUSDT'), findsOneWidget);
      expect(find.text('Ethereum Perpetual · Bybit'), findsOneWidget);
    });

    testWidgets(
      'selecting from search overrides the deep-linked symbol parameter',
      (tester) async {
        await tester.pumpWidget(_buildApp(symbol: 'ETH'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('ETHUSDT'), findsOneWidget);

        await tester.enterText(
          find.byKey(const ValueKey('symbol_search_field')),
          'BTC',
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const ValueKey('search_result_BTCUSDT')));
        await tester.pumpAndSettle();

        expect(find.text('Bitcoin Perpetual · Bybit'), findsOneWidget);
      },
    );

    testWidgets('parses arbitrary USDT pair to correct base', (tester) async {
      await tester.pumpWidget(_buildApp(symbol: 'DOGEUSDT'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Header shows the raw pair and metadata derived from base 'DOGE'.
      expect(find.text('DOGEUSDT'), findsOneWidget);
      expect(find.text('DOGE · Bybit'), findsOneWidget);
      expect(find.text('Buy / Long DOGE'), findsOneWidget);
    });

    testWidgets('parses bare base symbol as USDT pair', (tester) async {
      await tester.pumpWidget(_buildApp(symbol: 'ADA'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // ADA is treated as base with USDT quote; rawSymbol becomes ADAUSDT.
      expect(find.text('ADAUSDT'), findsOneWidget);
      expect(find.text('ADA · Bybit'), findsOneWidget);
    });

    testWidgets(
      'falls back to default symbol when symbol parameter is invalid',
      (tester) async {
        await tester.pumpWidget(_buildApp(symbol: 'ETH!'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.textContaining('BTC'), findsWidgets);
      },
    );

    testWidgets('shows SnackBar and falls back when symbol contains a slash', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp(symbol: 'BTC/USD'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Invalid symbol parameter: BTC/USD'), findsOneWidget);
      expect(find.textContaining('BTC'), findsWidgets);
    });

    testWidgets('falls back to default for symbol longer than 20 characters', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp(symbol: 'A' * 21));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('Invalid symbol parameter'), findsOneWidget);
      expect(find.textContaining('BTC'), findsWidgets);
    });

    testWidgets(
      'selecting a different timeframe fetches candles for that timeframe',
      (tester) async {
        final repository = _TimeframeRecordingRepository();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              marketDataRepositoryProvider.overrideWithValue(repository),
            ],
            child: MaterialApp.router(
              theme: AppTheme.dark(AppVisualDirection.flux),
              routerConfig: GoRouter(
                routes: [
                  GoRoute(
                    path: '/',
                    builder: (context, state) => const TradingTerminalScreen(),
                  ),
                  GoRoute(
                    path: '/markets/compare',
                    builder: (context, state) =>
                        const Scaffold(body: Center(child: Text('Compare'))),
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pump();
        for (var i = 0; i < 20 && repository.lastCandleTimeframe == null; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(repository.lastCandleTimeframe, Timeframe.h1);

        await tester.tap(find.text('4H'));
        await tester.pump();
        for (
          var i = 0;
          i < 20 && repository.lastCandleTimeframe == Timeframe.h1;
          i++
        ) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(repository.lastCandleTimeframe, Timeframe.h4);
      },
    );

    testWidgets('switches to Book tab and shows order book', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Book'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('PRICE'), findsOneWidget);
      expect(find.text('SIZE (BTC)'), findsOneWidget);
      expect(find.textContaining('spread'), findsOneWidget);
    });

    testWidgets('switches to Info tab and shows FundamentalsCard', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Info'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(FundamentalsCard), findsOneWidget);
      expect(find.text('MARKET CAP'), findsOneWidget);
      expect(find.text('\$1.14T'), findsOneWidget);
      expect(find.text('24H VOLUME'), findsOneWidget);
      expect(find.text('\$38.2B'), findsOneWidget);
      expect(find.text('ABOUT'), findsOneWidget);
    });

    testWidgets('switches to Signals tab and shows SignalGauge', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Signals'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(SignalGauge), findsOneWidget);
      expect(find.text('OSCILLATORS'), findsOneWidget);
      expect(find.text('MOVING AVERAGES'), findsOneWidget);
      expect(find.text('PIVOT LEVELS'), findsOneWidget);
    });

    testWidgets('compare button navigates to /markets/compare', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.byIcon(Icons.stacked_line_chart));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Compare'), findsOneWidget);
    });

    testWidgets('submit CTA shows confirmation dialog', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.ensureVisible(find.text('Buy / Long BTC'));
      await tester.tap(find.text('Buy / Long BTC'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Confirm Buy'), findsOneWidget);
      expect(find.text('Confirm'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });
  });
}

final class _SymbolRecordingRepository implements MarketDataRepository {
  _SymbolRecordingRepository()
    : _delegate = MarketDataRepositoryImpl(
        registry: const _FakeRegistry(),
        fallbackStore: const DeterministicMarketDataStore(),
      );

  final MarketDataRepository _delegate;
  TradingSymbol? recordedSymbol;

  @override
  Future<Result<Ticker>> getTicker(TradingSymbol symbol) async {
    recordedSymbol ??= symbol;
    return _delegate.getTicker(symbol);
  }

  @override
  Future<Result<List<Candle>>> getCandles(
    TradingSymbol symbol,
    Timeframe timeframe, {
    int? limit,
  }) => _delegate.getCandles(symbol, timeframe, limit: limit);

  @override
  Future<Result<OrderBook>> getOrderBook(TradingSymbol symbol, {int? depth}) =>
      _delegate.getOrderBook(symbol, depth: depth);

  @override
  Future<Result<List<Trade>>> getTrades(TradingSymbol symbol, {int? limit}) =>
      _delegate.getTrades(symbol, limit: limit);

  @override
  Stream<Result<Ticker>> watchTicker(TradingSymbol symbol) async* {
    yield await getTicker(symbol);
  }

  @override
  Stream<Result<OrderBook>> watchOrderBook(TradingSymbol symbol) async* {
    yield await getOrderBook(symbol);
  }

  @override
  Stream<Result<List<Trade>>> watchTrades(TradingSymbol symbol) async* {
    yield await getTrades(symbol);
  }
}

final class _TimeframeRecordingRepository implements MarketDataRepository {
  _TimeframeRecordingRepository()
    : _delegate = MarketDataRepositoryImpl(
        registry: const _FakeRegistry(),
        fallbackStore: const DeterministicMarketDataStore(),
      );

  final MarketDataRepository _delegate;
  Timeframe? lastCandleTimeframe;

  @override
  Future<Result<Ticker>> getTicker(TradingSymbol symbol) =>
      _delegate.getTicker(symbol);

  @override
  Future<Result<List<Candle>>> getCandles(
    TradingSymbol symbol,
    Timeframe timeframe, {
    int? limit,
  }) async {
    lastCandleTimeframe = timeframe;
    return _delegate.getCandles(symbol, timeframe, limit: limit);
  }

  @override
  Future<Result<OrderBook>> getOrderBook(TradingSymbol symbol, {int? depth}) =>
      _delegate.getOrderBook(symbol, depth: depth);

  @override
  Future<Result<List<Trade>>> getTrades(TradingSymbol symbol, {int? limit}) =>
      _delegate.getTrades(symbol, limit: limit);

  @override
  Stream<Result<Ticker>> watchTicker(TradingSymbol symbol) async* {
    yield await getTicker(symbol);
  }

  @override
  Stream<Result<OrderBook>> watchOrderBook(TradingSymbol symbol) async* {
    yield await getOrderBook(symbol);
  }

  @override
  Stream<Result<List<Trade>>> watchTrades(TradingSymbol symbol) async* {
    yield await getTrades(symbol);
  }
}
