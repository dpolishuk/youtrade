import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:youtrade/core/failures.dart';
import 'package:youtrade/core/result.dart';
import 'package:youtrade/domain/entities/candle.dart';
import 'package:youtrade/domain/entities/order_book.dart';
import 'package:youtrade/domain/entities/symbol.dart';
import 'package:youtrade/domain/entities/ticker.dart';
import 'package:youtrade/domain/entities/timeframe.dart';
import 'package:youtrade/domain/entities/trade.dart';
import 'package:youtrade/domain/entities/venue.dart';
import 'package:youtrade/domain/repositories/market_data_repository.dart';
import 'package:youtrade/presentation/providers/market_data_providers.dart';
import 'package:youtrade/presentation/providers/repository_provider.dart';

final _symbol = TradingSymbol(
  base: 'BTC',
  quote: 'USDT',
  venue: Venue.binance,
  rawSymbol: 'BTCUSDT',
);

final _timestamp = DateTime.utc(2026, 1, 1);

Ticker _ticker(TradingSymbol symbol) => Ticker(
  symbol: symbol,
  lastPrice: 100000,
  bid: 99900,
  ask: 100100,
  change24h: 1000,
  change24hPercent: 0.01,
  volume: 1000,
  timestamp: _timestamp,
);

Candle _candle() => Candle(
  open: 1,
  high: 2,
  low: 0.5,
  close: 1.5,
  volume: 100,
  timestamp: _timestamp,
);

OrderBook _orderBook() => OrderBook(
  bids: const [OrderBookLevel(price: 99, amount: 1)],
  asks: const [OrderBookLevel(price: 101, amount: 1)],
  timestamp: _timestamp,
);

Trade _trade() => Trade(
  price: 100,
  amount: 1,
  side: TradeSide.buy,
  timestamp: _timestamp,
  tradeId: 't1',
);

final class _SuccessRepository implements MarketDataRepository {
  @override
  Future<Result<Ticker>> getTicker(TradingSymbol symbol) async =>
      Success(_ticker(symbol));

  @override
  Future<Result<List<Candle>>> getCandles(
    TradingSymbol symbol,
    Timeframe timeframe, {
    int? limit,
  }) async => Success([_candle()]);

  @override
  Future<Result<OrderBook>> getOrderBook(
    TradingSymbol symbol, {
    int? depth,
  }) async => Success(_orderBook());

  @override
  Future<Result<List<Trade>>> getTrades(
    TradingSymbol symbol, {
    int? limit,
  }) async => Success([_trade()]);

  @override
  Stream<Result<Ticker>> watchTicker(TradingSymbol symbol) =>
      Stream.value(Success(_ticker(symbol)));

  @override
  Stream<Result<OrderBook>> watchOrderBook(TradingSymbol symbol) =>
      Stream.value(Success(_orderBook()));

  @override
  Stream<Result<List<Trade>>> watchTrades(TradingSymbol symbol) =>
      Stream.value(Success([_trade()]));
}

final class _FailureRepository implements MarketDataRepository {
  static const _failure = NetworkFailure('fake failure');

  @override
  Future<Result<Ticker>> getTicker(TradingSymbol symbol) async =>
      const Err(_failure);

  @override
  Future<Result<List<Candle>>> getCandles(
    TradingSymbol symbol,
    Timeframe timeframe, {
    int? limit,
  }) async => const Err(_failure);

  @override
  Future<Result<OrderBook>> getOrderBook(
    TradingSymbol symbol, {
    int? depth,
  }) async => const Err(_failure);

  @override
  Future<Result<List<Trade>>> getTrades(
    TradingSymbol symbol, {
    int? limit,
  }) async => const Err(_failure);

  @override
  Stream<Result<Ticker>> watchTicker(TradingSymbol symbol) =>
      Stream.value(Err(_failure));

  @override
  Stream<Result<OrderBook>> watchOrderBook(TradingSymbol symbol) =>
      Stream.value(Err(_failure));

  @override
  Stream<Result<List<Trade>>> watchTrades(TradingSymbol symbol) =>
      Stream.value(Err(_failure));
}

typedef _GetCandlesCallback =
    void Function(TradingSymbol symbol, Timeframe timeframe);

final class _RecordingRepository implements MarketDataRepository {
  const _RecordingRepository({required this.delegate, this.onGetCandles});

  final MarketDataRepository delegate;
  final _GetCandlesCallback? onGetCandles;

  @override
  Future<Result<Ticker>> getTicker(TradingSymbol symbol) =>
      delegate.getTicker(symbol);

  @override
  Future<Result<List<Candle>>> getCandles(
    TradingSymbol symbol,
    Timeframe timeframe, {
    int? limit,
  }) {
    onGetCandles?.call(symbol, timeframe);
    return delegate.getCandles(symbol, timeframe, limit: limit);
  }

  @override
  Future<Result<OrderBook>> getOrderBook(TradingSymbol symbol, {int? depth}) =>
      delegate.getOrderBook(symbol, depth: depth);

  @override
  Future<Result<List<Trade>>> getTrades(TradingSymbol symbol, {int? limit}) =>
      delegate.getTrades(symbol, limit: limit);

  @override
  Stream<Result<Ticker>> watchTicker(TradingSymbol symbol) =>
      delegate.watchTicker(symbol);

  @override
  Stream<Result<OrderBook>> watchOrderBook(TradingSymbol symbol) =>
      delegate.watchOrderBook(symbol);

  @override
  Stream<Result<List<Trade>>> watchTrades(TradingSymbol symbol) =>
      delegate.watchTrades(symbol);
}

void main() {
  final symbol = _symbol;

  group('tickerStreamProvider', () {
    // Catches the provider exposing the wrong ticker value when the repository
    // succeeds.
    test('emits AsyncData with exact ticker', () async {
      final container = ProviderContainer(
        overrides: [
          marketDataRepositoryProvider.overrideWithValue(_SuccessRepository()),
        ],
      );
      addTearDown(container.dispose);

      await container.read(tickerStreamProvider(symbol).future);

      expect(
        container.read(tickerStreamProvider(symbol)),
        isA<AsyncData<Ticker>>().having(
          (state) => state.value,
          'value',
          _ticker(symbol),
        ),
      );
    });

    // REST polling silently skips failed polls — the stream stays in a
    // non-error state and never emits data.
    test('silently skips failed polls without emitting AsyncError', () async {
      final container = ProviderContainer(
        overrides: [
          marketDataRepositoryProvider.overrideWithValue(_FailureRepository()),
        ],
      );
      addTearDown(container.dispose);

      container.listen(tickerStreamProvider(symbol), (_, _) {});
      await Future<void>.delayed(Duration.zero);

      final state = container.read(tickerStreamProvider(symbol));
      expect(state, isNot(isA<AsyncError>()));
      expect(state, isNot(isA<AsyncData<Ticker>>()));
    });
  });

  group('candlesProvider', () {
    // Catches the provider exposing the wrong candle list when the repository
    // succeeds.
    test('emits AsyncData with exact candles', () async {
      final container = ProviderContainer(
        overrides: [
          marketDataRepositoryProvider.overrideWithValue(_SuccessRepository()),
        ],
      );
      addTearDown(container.dispose);

      await container.read(candlesProvider((symbol, Timeframe.h1)).future);

      expect(
        container.read(candlesProvider((symbol, Timeframe.h1))),
        isA<AsyncData<List<Candle>>>().having((state) => state.value, 'value', [
          _candle(),
        ]),
      );
    });

    // Catches the provider passing the wrong timeframe to the repository.
    test('passes the requested timeframe to the repository', () async {
      Timeframe? capturedTimeframe;
      final repository = _SuccessRepository();
      final recordingRepository = _RecordingRepository(
        delegate: repository,
        onGetCandles: (_, timeframe) => capturedTimeframe = timeframe,
      );
      final container = ProviderContainer(
        overrides: [
          marketDataRepositoryProvider.overrideWithValue(recordingRepository),
        ],
      );
      addTearDown(container.dispose);

      await container.read(candlesProvider((symbol, Timeframe.h4)).future);

      expect(capturedTimeframe, Timeframe.h4);
      expect(
        container.read(candlesProvider((symbol, Timeframe.h4))),
        isA<AsyncData<List<Candle>>>().having((state) => state.value, 'value', [
          _candle(),
        ]),
      );
    });

    // Catches the provider swallowing or misreporting the failure type when the
    // repository fails.
    test('emits AsyncError with exact NetworkFailure', () async {
      final container = ProviderContainer(
        overrides: [
          marketDataRepositoryProvider.overrideWithValue(_FailureRepository()),
        ],
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(candlesProvider((symbol, Timeframe.h1)).future),
        throwsA(_FailureRepository._failure),
      );

      expect(
        container.read(candlesProvider((symbol, Timeframe.h1))),
        isA<AsyncError>().having(
          (state) => state.error,
          'error',
          _FailureRepository._failure,
        ),
      );
    });
  });

  group('orderBookStreamProvider', () {
    // Catches the provider exposing the wrong order book value when the
    // repository succeeds.
    test('emits AsyncData with exact order book', () async {
      final container = ProviderContainer(
        overrides: [
          marketDataRepositoryProvider.overrideWithValue(_SuccessRepository()),
        ],
      );
      addTearDown(container.dispose);

      await container.read(orderBookStreamProvider(symbol).future);

      expect(
        container.read(orderBookStreamProvider(symbol)),
        isA<AsyncData<OrderBook>>().having(
          (state) => state.value,
          'value',
          _orderBook(),
        ),
      );
    });

    // REST polling silently skips failed polls — the stream stays in a
    // non-error state and never emits data.
    test('silently skips failed polls without emitting AsyncError', () async {
      final container = ProviderContainer(
        overrides: [
          marketDataRepositoryProvider.overrideWithValue(_FailureRepository()),
        ],
      );
      addTearDown(container.dispose);

      container.listen(orderBookStreamProvider(symbol), (_, _) {});
      await Future<void>.delayed(Duration.zero);

      final state = container.read(orderBookStreamProvider(symbol));
      expect(state, isNot(isA<AsyncError>()));
      expect(state, isNot(isA<AsyncData<OrderBook>>()));
    });
  });

  group('tradesStreamProvider', () {
    // Catches the provider exposing the wrong trade list when the repository
    // succeeds.
    test('emits AsyncData with exact trades', () async {
      final container = ProviderContainer(
        overrides: [
          marketDataRepositoryProvider.overrideWithValue(_SuccessRepository()),
        ],
      );
      addTearDown(container.dispose);

      await container.read(tradesStreamProvider(symbol).future);

      expect(
        container.read(tradesStreamProvider(symbol)),
        isA<AsyncData<List<Trade>>>().having((state) => state.value, 'value', [
          _trade(),
        ]),
      );
    });

    // REST polling silently skips failed polls — the stream stays in a
    // non-error state and never emits data.
    test('silently skips failed polls without emitting AsyncError', () async {
      final container = ProviderContainer(
        overrides: [
          marketDataRepositoryProvider.overrideWithValue(_FailureRepository()),
        ],
      );
      addTearDown(container.dispose);

      container.listen(tradesStreamProvider(symbol), (_, _) {});
      await Future<void>.delayed(Duration.zero);

      final state = container.read(tradesStreamProvider(symbol));
      expect(state, isNot(isA<AsyncError>()));
      expect(state, isNot(isA<AsyncData<List<Trade>>>()));
    });
  });
}
