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

void main() {
  final symbol = _symbol;

  group('tickerStreamProvider', () {
    test('emits AsyncData when repository returns Success', () async {
      final container = ProviderContainer(
        overrides: [
          marketDataRepositoryProvider.overrideWithValue(_SuccessRepository()),
        ],
      );
      addTearDown(container.dispose);

      await container.read(tickerStreamProvider(symbol).future);

      expect(
        container.read(tickerStreamProvider(symbol)),
        isA<AsyncData<Ticker>>(),
      );
    });

    test('emits AsyncError when repository returns Failure', () async {
      final container = ProviderContainer(
        overrides: [
          marketDataRepositoryProvider.overrideWithValue(_FailureRepository()),
        ],
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(tickerStreamProvider(symbol).future),
        throwsA(isA<Failure>()),
      );

      expect(container.read(tickerStreamProvider(symbol)), isA<AsyncError>());
    });
  });

  group('candlesProvider', () {
    test('emits AsyncData when repository returns Success', () async {
      final container = ProviderContainer(
        overrides: [
          marketDataRepositoryProvider.overrideWithValue(_SuccessRepository()),
        ],
      );
      addTearDown(container.dispose);

      await container.read(candlesProvider(symbol).future);

      expect(
        container.read(candlesProvider(symbol)),
        isA<AsyncData<List<Candle>>>(),
      );
    });

    test('emits AsyncError when repository returns Failure', () async {
      final container = ProviderContainer(
        overrides: [
          marketDataRepositoryProvider.overrideWithValue(_FailureRepository()),
        ],
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(candlesProvider(symbol).future),
        throwsA(isA<Failure>()),
      );

      expect(container.read(candlesProvider(symbol)), isA<AsyncError>());
    });
  });

  group('orderBookStreamProvider', () {
    test('emits AsyncData when repository returns Success', () async {
      final container = ProviderContainer(
        overrides: [
          marketDataRepositoryProvider.overrideWithValue(_SuccessRepository()),
        ],
      );
      addTearDown(container.dispose);

      await container.read(orderBookStreamProvider(symbol).future);

      expect(
        container.read(orderBookStreamProvider(symbol)),
        isA<AsyncData<OrderBook>>(),
      );
    });

    test('emits AsyncError when repository returns Failure', () async {
      final container = ProviderContainer(
        overrides: [
          marketDataRepositoryProvider.overrideWithValue(_FailureRepository()),
        ],
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(orderBookStreamProvider(symbol).future),
        throwsA(isA<Failure>()),
      );

      expect(
        container.read(orderBookStreamProvider(symbol)),
        isA<AsyncError>(),
      );
    });
  });

  group('tradesStreamProvider', () {
    test('emits AsyncData when repository returns Success', () async {
      final container = ProviderContainer(
        overrides: [
          marketDataRepositoryProvider.overrideWithValue(_SuccessRepository()),
        ],
      );
      addTearDown(container.dispose);

      await container.read(tradesStreamProvider(symbol).future);

      expect(
        container.read(tradesStreamProvider(symbol)),
        isA<AsyncData<List<Trade>>>(),
      );
    });

    test('emits AsyncError when repository returns Failure', () async {
      final container = ProviderContainer(
        overrides: [
          marketDataRepositoryProvider.overrideWithValue(_FailureRepository()),
        ],
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(tradesStreamProvider(symbol).future),
        throwsA(isA<Failure>()),
      );

      expect(container.read(tradesStreamProvider(symbol)), isA<AsyncError>());
    });
  });
}
