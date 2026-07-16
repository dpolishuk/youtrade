import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:youtrade/data/datasources/mock/deterministic_market_data_store.dart';
import 'package:youtrade/core/failures.dart';
import 'package:youtrade/core/result.dart';
import 'package:youtrade/data/repositories/market_data_repository_impl.dart';
import 'package:youtrade/domain/sources/market_cache.dart';
import 'package:youtrade/domain/entities/candle.dart';
import 'package:youtrade/domain/entities/order_book.dart';
import 'package:youtrade/domain/entities/symbol.dart';
import 'package:youtrade/domain/entities/ticker.dart';
import 'package:youtrade/domain/entities/timeframe.dart';
import 'package:youtrade/domain/entities/trade.dart';
import 'package:youtrade/domain/entities/venue.dart';
import 'package:youtrade/domain/registry/exchange_capability.dart';
import 'package:youtrade/domain/sources/candle_source.dart';
import 'package:youtrade/domain/sources/market_stream_source.dart';
import 'package:youtrade/domain/sources/order_book_source.dart';
import 'package:youtrade/domain/sources/market_data_store.dart';
import 'package:youtrade/domain/sources/ticker_source.dart';
import 'package:youtrade/domain/sources/trade_source.dart';

class _FakeRegistry implements ExchangeCapabilityRegistry {
  @override
  List<ExchangeCapability> get all => [
    const ExchangeCapability(
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
    ),
  ];

  @override
  ExchangeCapability? forVenue(Venue venue) =>
      all.firstWhere((c) => c.venue == venue);

  @override
  bool isSymbolSupported(TradingSymbol symbol) => true;
}

class _LimitedRegistry implements ExchangeCapabilityRegistry {
  @override
  List<ExchangeCapability> get all => [
    const ExchangeCapability(
      venue: Venue.binance,
      supportedFeatures: {MarketDataFeature.restTicker},
    ),
  ];

  @override
  ExchangeCapability? forVenue(Venue venue) =>
      all.firstWhere((c) => c.venue == venue);

  @override
  bool isSymbolSupported(TradingSymbol symbol) => true;
}

class _EmptyRegistry implements ExchangeCapabilityRegistry {
  @override
  List<ExchangeCapability> get all => [];

  @override
  ExchangeCapability? forVenue(Venue venue) => null;

  @override
  bool isSymbolSupported(TradingSymbol symbol) => false;
}

class _ThrowingTickerSource implements TickerSource {
  @override
  Future<Result<Ticker>> fetchTicker(TradingSymbol symbol) async =>
      throw Exception('boom');
}

class _ThrowingCandleSource implements CandleSource {
  @override
  Future<Result<List<Candle>>> fetchCandles(
    TradingSymbol symbol,
    Timeframe timeframe, {
    int? limit,
  }) async => throw Exception('boom');
}

class _ThrowingOrderBookSource2 implements OrderBookSource {
  @override
  Future<Result<OrderBook>> fetchOrderBook(
    TradingSymbol symbol, {
    int? depth,
  }) async => throw Exception('boom');
}

class _ThrowingTradeSource2 implements TradeSource {
  @override
  Future<Result<List<Trade>>> fetchTrades(
    TradingSymbol symbol, {
    int? limit,
  }) async => throw Exception('boom');
}

class _FailingTickerSource implements TickerSource {
  @override
  Future<Result<Ticker>> fetchTicker(TradingSymbol symbol) async =>
      const Err<Ticker>(NetworkFailure('no network'));
}

class _FailingCandleSource implements CandleSource {
  @override
  Future<Result<List<Candle>>> fetchCandles(
    TradingSymbol symbol,
    Timeframe timeframe, {
    int? limit,
  }) async => const Err<List<Candle>>(NetworkFailure('no network'));
}

class _FailingOrderBookSource implements OrderBookSource {
  @override
  Future<Result<OrderBook>> fetchOrderBook(
    TradingSymbol symbol, {
    int? depth,
  }) async => const Err<OrderBook>(NetworkFailure('no network'));
}

class _FailingTradeSource implements TradeSource {
  @override
  Future<Result<List<Trade>>> fetchTrades(
    TradingSymbol symbol, {
    int? limit,
  }) async => const Err<List<Trade>>(NetworkFailure('no network'));
}

class _FailingStreamSource implements MarketStreamSource {
  @override
  Stream<Result<Ticker>> watchTicker(TradingSymbol symbol) =>
      Stream.value(const Err<Ticker>(NetworkFailure('no network')));

  @override
  Stream<Result<OrderBook>> watchOrderBook(TradingSymbol symbol) =>
      Stream.value(const Err<OrderBook>(NetworkFailure('no network')));

  @override
  Stream<Result<List<Trade>>> watchTrades(TradingSymbol symbol) =>
      Stream.value(const Err<List<Trade>>(NetworkFailure('no network')));
}

class _SuccessfulTickerSource implements TickerSource {
  const _SuccessfulTickerSource(this.ticker);

  final Ticker ticker;

  @override
  Future<Result<Ticker>> fetchTicker(TradingSymbol symbol) async =>
      Success(ticker);
}

class _SuccessfulCandleSource implements CandleSource {
  const _SuccessfulCandleSource(this.candles);

  final List<Candle> candles;

  @override
  Future<Result<List<Candle>>> fetchCandles(
    TradingSymbol symbol,
    Timeframe timeframe, {
    int? limit,
  }) async => Success(candles);
}

class _SuccessfulOrderBookSource implements OrderBookSource {
  const _SuccessfulOrderBookSource(this.orderBook);

  final OrderBook orderBook;

  @override
  Future<Result<OrderBook>> fetchOrderBook(
    TradingSymbol symbol, {
    int? depth,
  }) async => Success(orderBook);
}

class _SuccessfulTradeSource implements TradeSource {
  const _SuccessfulTradeSource(this.trades);

  final List<Trade> trades;

  @override
  Future<Result<List<Trade>>> fetchTrades(
    TradingSymbol symbol, {
    int? limit,
  }) async => Success(trades);
}

class _SuccessfulStreamSource implements MarketStreamSource {
  const _SuccessfulStreamSource({
    required this.ticker,
    required this.orderBook,
    required this.trades,
  });

  final Ticker ticker;
  final OrderBook orderBook;
  final List<Trade> trades;

  @override
  Stream<Result<Ticker>> watchTicker(TradingSymbol symbol) async* {
    yield Success(ticker);
  }

  @override
  Stream<Result<OrderBook>> watchOrderBook(TradingSymbol symbol) async* {
    yield Success(orderBook);
  }

  @override
  Stream<Result<List<Trade>>> watchTrades(TradingSymbol symbol) async* {
    yield Success(trades);
  }
}

class _DelayedTickerSource implements TickerSource {
  final _completer = Completer<Ticker>();

  void complete(Ticker ticker) => _completer.complete(ticker);

  @override
  Future<Result<Ticker>> fetchTicker(TradingSymbol symbol) async =>
      Success(await _completer.future);
}

class _DelayedCandleSource implements CandleSource {
  final _completer = Completer<List<Candle>>();

  void complete(List<Candle> candles) => _completer.complete(candles);

  @override
  Future<Result<List<Candle>>> fetchCandles(
    TradingSymbol symbol,
    Timeframe timeframe, {
    int? limit,
  }) async => Success(await _completer.future);
}

class _DelayedOrderBookSource implements OrderBookSource {
  final _completer = Completer<OrderBook>();

  void complete(OrderBook orderBook) => _completer.complete(orderBook);

  @override
  Future<Result<OrderBook>> fetchOrderBook(
    TradingSymbol symbol, {
    int? depth,
  }) async => Success(await _completer.future);
}

class _DelayedTradeSource implements TradeSource {
  final _completer = Completer<List<Trade>>();

  void complete(List<Trade> trades) => _completer.complete(trades);

  @override
  Future<Result<List<Trade>>> fetchTrades(
    TradingSymbol symbol, {
    int? limit,
  }) async => Success(await _completer.future);
}

class _FakeMarketCacheDataSource implements MarketCache {
  final _tickers = <String, Ticker>{};
  final _candles = <String, List<Candle>>{};
  final _orderBooks = <String, OrderBook>{};
  final _trades = <String, List<Trade>>{};

  @override
  Future<void> saveTicker(Ticker ticker) async {
    _tickers[ticker.symbol.id] = ticker;
  }

  @override
  Future<Ticker?> getTicker(TradingSymbol symbol) async => _tickers[symbol.id];

  @override
  Future<void> saveCandles(
    TradingSymbol symbol,
    Timeframe timeframe,
    List<Candle> candles,
  ) async {
    _candles[_candleKey(symbol, timeframe)] = candles;
  }

  @override
  Future<List<Candle>> getCandles(
    TradingSymbol symbol,
    Timeframe timeframe, {
    int? limit,
  }) async {
    final list = _candles[_candleKey(symbol, timeframe)] ?? [];
    if (limit != null) return list.take(limit).toList();
    return list;
  }

  String _candleKey(TradingSymbol symbol, Timeframe timeframe) =>
      '${symbol.id}:${timeframe.code}';

  @override
  Future<void> saveOrderBook(TradingSymbol symbol, OrderBook orderBook) async {
    _orderBooks[symbol.id] = orderBook;
  }

  @override
  Future<OrderBook?> getOrderBook(TradingSymbol symbol) async =>
      _orderBooks[symbol.id];

  @override
  Future<void> saveTrades(TradingSymbol symbol, List<Trade> trades) async {
    _trades[symbol.id] = trades;
  }

  @override
  Future<List<Trade>?> getTrades(TradingSymbol symbol) async =>
      _trades[symbol.id];
}

final class _ParseFailureTickerSource implements TickerSource {
  @override
  Future<Result<Ticker>> fetchTicker(TradingSymbol symbol) async =>
      const Err<Ticker>(ParseFailure('ticker parse error'));
}

final class _ParseFailureCandleSource implements CandleSource {
  @override
  Future<Result<List<Candle>>> fetchCandles(
    TradingSymbol symbol,
    Timeframe timeframe, {
    int? limit,
  }) async => const Err<List<Candle>>(ParseFailure('candles parse error'));
}

final class _ParseFailureOrderBookSource implements OrderBookSource {
  @override
  Future<Result<OrderBook>> fetchOrderBook(
    TradingSymbol symbol, {
    int? depth,
  }) async => const Err<OrderBook>(ParseFailure('order book parse error'));
}

final class _ParseFailureTradeSource implements TradeSource {
  @override
  Future<Result<List<Trade>>> fetchTrades(
    TradingSymbol symbol, {
    int? limit,
  }) async => const Err<List<Trade>>(ParseFailure('trades parse error'));
}

final class _ThrowingMarketDataStore implements MarketDataStore {
  @override
  Future<Ticker> getTicker(TradingSymbol symbol) async =>
      throw Exception('store boom');

  @override
  Future<List<Candle>> getCandles(
    TradingSymbol symbol,
    Timeframe timeframe, {
    int? limit,
  }) async => throw Exception('store boom');

  @override
  Future<OrderBook> getOrderBook(TradingSymbol symbol, {int? depth}) async =>
      throw Exception('store boom');

  @override
  Future<List<Trade>> getTrades(TradingSymbol symbol, {int? limit}) async =>
      throw Exception('store boom');

  @override
  Stream<Ticker> watchTicker(TradingSymbol symbol) =>
      Stream.error(Exception('store boom'));

  @override
  Stream<OrderBook> watchOrderBook(TradingSymbol symbol) =>
      Stream.error(Exception('store boom'));

  @override
  Stream<List<Trade>> watchTrades(TradingSymbol symbol) =>
      Stream.error(Exception('store boom'));
}

void _expectTickerEquals(Ticker actual, Ticker expected) {
  expect(actual.symbol, expected.symbol);
  expect(actual.lastPrice, expected.lastPrice);
  expect(actual.bid, expected.bid);
  expect(actual.ask, expected.ask);
  expect(actual.change24h, expected.change24h);
  expect(actual.change24hPercent, expected.change24hPercent);
  expect(actual.volume, expected.volume);
}

void _expectCandlesEqual(List<Candle> actual, List<Candle> expected) {
  expect(actual.length, expected.length);
  for (var i = 0; i < actual.length; i++) {
    final a = actual[i];
    final e = expected[i];
    expect(a.open, e.open);
    expect(a.high, e.high);
    expect(a.low, e.low);
    expect(a.close, e.close);
    expect(a.volume, e.volume);
  }
}

void _expectOrderBookEquals(OrderBook actual, OrderBook expected) {
  expect(actual.bids, expected.bids);
  expect(actual.asks, expected.asks);
}

void _expectTradesEqual(List<Trade> actual, List<Trade> expected) {
  expect(actual.length, expected.length);
  for (var i = 0; i < actual.length; i++) {
    final a = actual[i];
    final e = expected[i];
    expect(a.price, e.price);
    expect(a.amount, e.amount);
    expect(a.side, e.side);
    expect(a.tradeId, e.tradeId);
  }
}

void main() {
  group('MarketDataRepositoryImpl with fake sources', () {
    final symbol = TradingSymbol(
      base: 'BTC',
      quote: 'USDT',
      venue: Venue.binance,
      rawSymbol: 'BTCUSDT',
    );

    final expectedTicker = Ticker(
      symbol: symbol,
      lastPrice: 12345.0,
      bid: 12340.0,
      ask: 12350.0,
      change24h: 100.0,
      change24hPercent: 0.01,
      volume: 9876.0,
      timestamp: DateTime.utc(2026, 6, 21, 12),
    );

    final expectedCandles = [
      Candle(
        open: 1.0,
        high: 2.0,
        low: 0.5,
        close: 1.5,
        volume: 100.0,
        timestamp: DateTime.utc(2026, 6, 21, 11),
      ),
      Candle(
        open: 1.5,
        high: 2.5,
        low: 1.0,
        close: 2.0,
        volume: 200.0,
        timestamp: DateTime.utc(2026, 6, 21, 12),
      ),
    ];

    final expectedOrderBook = OrderBook(
      bids: const [OrderBookLevel(price: 99.0, amount: 1.5)],
      asks: const [OrderBookLevel(price: 101.0, amount: 2.5)],
      timestamp: DateTime.utc(2026, 6, 21, 12),
    );

    // Catches the repository returning wrong ticker fields when the REST
    // source succeeds.
    test('getTicker returns exact ticker from source', () async {
      final repository = MarketDataRepositoryImpl(
        registry: _FakeRegistry(),
        venueSources: {
          Venue.binance: VenueSources(
            ticker: _SuccessfulTickerSource(expectedTicker),
            candles: _FailingCandleSource(),
            orderBook: _FailingOrderBookSource(),
            trades: _FailingTradeSource(),
            stream: _FailingStreamSource(),
          ),
        },
      );

      final result = await repository.getTicker(symbol);

      expect(result, isA<Success<Ticker>>());
      expect((result as Success<Ticker>).value, expectedTicker);
    });

    // Catches the repository truncating, reordering, or corrupting candles
    // returned by the REST source.
    test('getCandles returns exact candles from source', () async {
      final repository = MarketDataRepositoryImpl(
        registry: _FakeRegistry(),
        venueSources: {
          Venue.binance: VenueSources(
            ticker: _FailingTickerSource(),
            candles: _SuccessfulCandleSource(expectedCandles),
            orderBook: _FailingOrderBookSource(),
            trades: _FailingTradeSource(),
            stream: _FailingStreamSource(),
          ),
        },
      );

      final result = await repository.getCandles(
        symbol,
        Timeframe.h1,
        limit: expectedCandles.length,
      );

      expect(result, isA<Success<List<Candle>>>());
      expect((result as Success<List<Candle>>).value, expectedCandles);
    });

    // Catches the repository returning wrong order book levels or amounts when
    // the REST source succeeds.
    test('getOrderBook returns exact order book from source', () async {
      final repository = MarketDataRepositoryImpl(
        registry: _FakeRegistry(),
        venueSources: {
          Venue.binance: VenueSources(
            ticker: _FailingTickerSource(),
            candles: _FailingCandleSource(),
            orderBook: _SuccessfulOrderBookSource(expectedOrderBook),
            trades: _FailingTradeSource(),
            stream: _FailingStreamSource(),
          ),
        },
      );

      final result = await repository.getOrderBook(symbol, depth: 1);

      expect(result, isA<Success<OrderBook>>());
      expect((result as Success<OrderBook>).value, expectedOrderBook);
    });

    // Catches stream source values not being propagated exactly by the
    // repository.
    test('watchTicker emits exact ticker values from stream source', () async {
      final repository = MarketDataRepositoryImpl(
        registry: _FakeRegistry(),
        venueSources: {
          Venue.binance: VenueSources(
            ticker: _FailingTickerSource(),
            candles: _FailingCandleSource(),
            orderBook: _FailingOrderBookSource(),
            trades: _FailingTradeSource(),
            stream: _SuccessfulStreamSource(
              ticker: expectedTicker,
              orderBook: expectedOrderBook,
              trades: const [],
            ),
          ),
        },
      );

      final value = await repository.watchTicker(symbol).first;

      expect(value, Success<Ticker>(expectedTicker));
    });
  });

  group('MarketDataRepositoryImpl offline fallback', () {
    final symbol = TradingSymbol(
      base: 'BTC',
      quote: 'USDT',
      venue: Venue.binance,
      rawSymbol: 'BTCUSDT',
    );

    test('getTicker returns mock data when offline', () async {
      final expectedStore = const DeterministicMarketDataStore();
      final expected = await expectedStore.getTicker(symbol);
      final repository = MarketDataRepositoryImpl(
        registry: _FakeRegistry(),
        fallbackStore: const DeterministicMarketDataStore(),
      );

      final result = await repository.getTicker(symbol);

      expect(result, isA<Success<Ticker>>());
      _expectTickerEquals((result as Success<Ticker>).value, expected);
    });

    test('getCandles returns mock data when offline', () async {
      final expectedStore = const DeterministicMarketDataStore();
      final expected = await expectedStore.getCandles(
        symbol,
        Timeframe.h1,
        limit: 5,
      );
      final repository = MarketDataRepositoryImpl(
        registry: _FakeRegistry(),
        fallbackStore: const DeterministicMarketDataStore(),
      );

      final result = await repository.getCandles(
        symbol,
        Timeframe.h1,
        limit: 5,
      );

      expect(result, isA<Success<List<Candle>>>());
      _expectCandlesEqual((result as Success<List<Candle>>).value, expected);
    });

    test('watchTicker emits mock data when offline', () async {
      final expectedStore = const DeterministicMarketDataStore();
      final expected = await expectedStore.watchTicker(symbol).first;
      final repository = MarketDataRepositoryImpl(
        registry: _FakeRegistry(),
        fallbackStore: const DeterministicMarketDataStore(),
      );

      final values = await repository.watchTicker(symbol).take(1).toList();

      expect(values.length, 1);
      expect(values.first, isA<Success<Ticker>>());
      _expectTickerEquals((values.first as Success<Ticker>).value, expected);
    });

    test('watchOrderBook emits mock data when offline', () async {
      final expectedStore = const DeterministicMarketDataStore();
      final expected = await expectedStore.watchOrderBook(symbol).first;
      final repository = MarketDataRepositoryImpl(
        registry: _FakeRegistry(),
        fallbackStore: const DeterministicMarketDataStore(),
      );

      final values = await repository.watchOrderBook(symbol).take(1).toList();

      expect(values.length, 1);
      expect(values.first, isA<Success<OrderBook>>());
      _expectOrderBookEquals(
        (values.first as Success<OrderBook>).value,
        expected,
      );
    });

    test('watchTrades emits mock data when offline', () async {
      final expectedStore = const DeterministicMarketDataStore();
      final expected = await expectedStore.watchTrades(symbol).first;
      final repository = MarketDataRepositoryImpl(
        registry: _FakeRegistry(),
        fallbackStore: const DeterministicMarketDataStore(),
      );

      final values = await repository.watchTrades(symbol).take(1).toList();

      expect(values.length, 1);
      expect(values.first, isA<Success<List<Trade>>>());
      _expectTradesEqual(
        (values.first as Success<List<Trade>>).value,
        expected,
      );
    });
  });

  group('MarketDataRepositoryImpl network failure fallback', () {
    final symbol = TradingSymbol(
      base: 'BTC',
      quote: 'USDT',
      venue: Venue.binance,
      rawSymbol: 'BTCUSDT',
    );

    late VenueSources failingSources;

    setUp(() {
      failingSources = VenueSources(
        ticker: _FailingTickerSource(),
        candles: _FailingCandleSource(),
        orderBook: _FailingOrderBookSource(),
        trades: _FailingTradeSource(),
        stream: _FailingStreamSource(),
      );
    });

    test('getTicker falls back to mock on network failure', () async {
      final expectedStore = const DeterministicMarketDataStore();
      final expected = await expectedStore.getTicker(symbol);
      final repository = MarketDataRepositoryImpl(
        registry: _FakeRegistry(),

        venueSources: {Venue.binance: failingSources},
      );

      final result = await repository.getTicker(symbol);

      expect(result, isA<Success<Ticker>>());
      _expectTickerEquals((result as Success<Ticker>).value, expected);
    });

    test('getCandles falls back to mock on network failure', () async {
      final expectedStore = const DeterministicMarketDataStore();
      final expected = await expectedStore.getCandles(
        symbol,
        Timeframe.h1,
        limit: 3,
      );
      final repository = MarketDataRepositoryImpl(
        registry: _FakeRegistry(),

        venueSources: {Venue.binance: failingSources},
      );

      final result = await repository.getCandles(
        symbol,
        Timeframe.h1,
        limit: 3,
      );

      expect(result, isA<Success<List<Candle>>>());
      _expectCandlesEqual((result as Success<List<Candle>>).value, expected);
    });

    test('getOrderBook falls back to mock on network failure', () async {
      final expectedStore = const DeterministicMarketDataStore();
      final expected = await expectedStore.getOrderBook(symbol, depth: 3);
      final repository = MarketDataRepositoryImpl(
        registry: _FakeRegistry(),

        venueSources: {Venue.binance: failingSources},
      );

      final result = await repository.getOrderBook(symbol, depth: 3);

      expect(result, isA<Success<OrderBook>>());
      _expectOrderBookEquals((result as Success<OrderBook>).value, expected);
    });

    test('getTrades falls back to mock on network failure', () async {
      final expectedStore = const DeterministicMarketDataStore();
      final expected = await expectedStore.getTrades(symbol, limit: 3);
      final repository = MarketDataRepositoryImpl(
        registry: _FakeRegistry(),

        venueSources: {Venue.binance: failingSources},
      );

      final result = await repository.getTrades(symbol, limit: 3);

      expect(result, isA<Success<List<Trade>>>());
      _expectTradesEqual((result as Success<List<Trade>>).value, expected);
    });
  });

  group('MarketDataRepositoryImpl cache-first behavior', () {
    final symbol = TradingSymbol(
      base: 'BTC',
      quote: 'USDT',
      venue: Venue.binance,
      rawSymbol: 'BTCUSDT',
    );

    final networkTicker = Ticker(
      symbol: symbol,
      lastPrice: 200,
      bid: 199,
      ask: 201,
      change24h: 2,
      change24hPercent: 0.02,
      volume: 2000,
      timestamp: DateTime.utc(2026, 6, 21, 12, 0, 1),
    );

    final freshTicker = Ticker(
      symbol: symbol,
      lastPrice: 100,
      bid: 99,
      ask: 101,
      change24h: 1,
      change24hPercent: 0.01,
      volume: 1000,
      timestamp: DateTime.now().toUtc().subtract(const Duration(seconds: 10)),
    );

    final staleTicker = Ticker(
      symbol: symbol,
      lastPrice: 100,
      bid: 99,
      ask: 101,
      change24h: 1,
      change24hPercent: 0.01,
      volume: 1000,
      timestamp: DateTime.now().toUtc().subtract(const Duration(minutes: 1)),
    );

    final networkCandles = [
      Candle(
        open: 2,
        high: 3,
        low: 1,
        close: 2.5,
        volume: 200,
        timestamp: DateTime.utc(2026, 6, 21, 12),
      ),
    ];

    final freshCandles = [
      Candle(
        open: 1,
        high: 2,
        low: 0.5,
        close: 1.5,
        volume: 100,
        timestamp: DateTime.now().toUtc().subtract(const Duration(minutes: 2)),
      ),
    ];

    final staleCandles = [
      Candle(
        open: 1,
        high: 2,
        low: 0.5,
        close: 1.5,
        volume: 100,
        timestamp: DateTime.now().toUtc().subtract(const Duration(minutes: 10)),
      ),
    ];

    final networkOrderBook = OrderBook(
      bids: const [OrderBookLevel(price: 199, amount: 1)],
      asks: const [OrderBookLevel(price: 201, amount: 1)],
      timestamp: DateTime.utc(2026, 6, 21, 12),
    );

    final freshOrderBook = OrderBook(
      bids: const [OrderBookLevel(price: 99, amount: 1)],
      asks: const [OrderBookLevel(price: 101, amount: 1)],
      timestamp: DateTime.now().toUtc().subtract(const Duration(seconds: 10)),
    );

    final staleOrderBook = OrderBook(
      bids: const [OrderBookLevel(price: 99, amount: 1)],
      asks: const [OrderBookLevel(price: 101, amount: 1)],
      timestamp: DateTime.now().toUtc().subtract(const Duration(minutes: 1)),
    );

    final networkTrades = [
      Trade(
        price: 200,
        amount: 2,
        side: TradeSide.sell,
        timestamp: DateTime.utc(2026, 6, 21, 12),
        tradeId: 't2',
      ),
    ];

    final freshTrades = [
      Trade(
        price: 100,
        amount: 1,
        side: TradeSide.buy,
        timestamp: DateTime.now().toUtc().subtract(const Duration(seconds: 10)),
        tradeId: 't1',
      ),
    ];

    final staleTrades = [
      Trade(
        price: 100,
        amount: 1,
        side: TradeSide.buy,
        timestamp: DateTime.now().toUtc().subtract(const Duration(minutes: 2)),
        tradeId: 't1',
      ),
    ];

    VenueSources failingSources() => VenueSources(
      ticker: _FailingTickerSource(),
      candles: _FailingCandleSource(),
      orderBook: _FailingOrderBookSource(),
      trades: _FailingTradeSource(),
      stream: _FailingStreamSource(),
    );

    test('getTicker returns fresh cache without waiting for network', () async {
      final cache = _FakeMarketCacheDataSource()..saveTicker(freshTicker);
      final delayedSource = _DelayedTickerSource();
      final repository = MarketDataRepositoryImpl(
        registry: _FakeRegistry(),

        cache: cache,
        venueSources: {
          Venue.binance: VenueSources(
            ticker: delayedSource,
            candles: _FailingCandleSource(),
            orderBook: _FailingOrderBookSource(),
            trades: _FailingTradeSource(),
            stream: _FailingStreamSource(),
          ),
        },
      );

      final future = repository.getTicker(symbol);
      final result = await future;

      expect(result, isA<Success<Ticker>>());
      expect((result as Success<Ticker>).value, freshTicker);

      delayedSource.complete(networkTicker);
      await pumpEventQueue();
      expect(await cache.getTicker(symbol), freshTicker);
    });

    test('getTicker saves network result to cache', () async {
      final cache = _FakeMarketCacheDataSource();
      final repository = MarketDataRepositoryImpl(
        registry: _FakeRegistry(),

        cache: cache,
        venueSources: {
          Venue.binance: VenueSources(
            ticker: _SuccessfulTickerSource(networkTicker),
            candles: _FailingCandleSource(),
            orderBook: _FailingOrderBookSource(),
            trades: _FailingTradeSource(),
            stream: _FailingStreamSource(),
          ),
        },
      );

      final result = await repository.getTicker(symbol);

      expect(result, isA<Success<Ticker>>());
      expect((result as Success<Ticker>).value, networkTicker);
      expect(await cache.getTicker(symbol), networkTicker);
    });

    test('getTicker falls back to stale cache on network failure', () async {
      final cache = _FakeMarketCacheDataSource()..saveTicker(staleTicker);
      final repository = MarketDataRepositoryImpl(
        registry: _FakeRegistry(),

        cache: cache,
        venueSources: {Venue.binance: failingSources()},
      );

      final result = await repository.getTicker(symbol);

      expect(result, isA<Success<Ticker>>());
      expect((result as Success<Ticker>).value, staleTicker);
    });

    test('getTicker returns cached data when offline', () async {
      final cache = _FakeMarketCacheDataSource()..saveTicker(freshTicker);
      final repository = MarketDataRepositoryImpl(
        registry: _FakeRegistry(),
        fallbackStore: const DeterministicMarketDataStore(),
        cache: cache,
      );

      final result = await repository.getTicker(symbol);

      expect(result, isA<Success<Ticker>>());
      expect((result as Success<Ticker>).value, freshTicker);
    });

    test(
      'getCandles returns fresh cache without waiting for network',
      () async {
        final cache = _FakeMarketCacheDataSource()
          ..saveCandles(symbol, Timeframe.h1, freshCandles);
        final delayedSource = _DelayedCandleSource();
        final repository = MarketDataRepositoryImpl(
          registry: _FakeRegistry(),

          cache: cache,
          venueSources: {
            Venue.binance: VenueSources(
              ticker: _FailingTickerSource(),
              candles: delayedSource,
              orderBook: _FailingOrderBookSource(),
              trades: _FailingTradeSource(),
              stream: _FailingStreamSource(),
            ),
          },
        );

        final future = repository.getCandles(symbol, Timeframe.h1);
        final result = await future;

        expect(result, isA<Success<List<Candle>>>());
        expect((result as Success<List<Candle>>).value, freshCandles);

        delayedSource.complete(networkCandles);
        await pumpEventQueue();
        expect(await cache.getCandles(symbol, Timeframe.h1), freshCandles);
      },
    );

    test('getCandles saves network result to cache', () async {
      final cache = _FakeMarketCacheDataSource();
      final repository = MarketDataRepositoryImpl(
        registry: _FakeRegistry(),

        cache: cache,
        venueSources: {
          Venue.binance: VenueSources(
            ticker: _FailingTickerSource(),
            candles: _SuccessfulCandleSource(networkCandles),
            orderBook: _FailingOrderBookSource(),
            trades: _FailingTradeSource(),
            stream: _FailingStreamSource(),
          ),
        },
      );

      final result = await repository.getCandles(symbol, Timeframe.h1);

      expect(result, isA<Success<List<Candle>>>());
      expect((result as Success<List<Candle>>).value, networkCandles);
      expect(await cache.getCandles(symbol, Timeframe.h1), networkCandles);
    });

    test('getCandles falls back to stale cache on network failure', () async {
      final cache = _FakeMarketCacheDataSource()
        ..saveCandles(symbol, Timeframe.h1, staleCandles);
      final repository = MarketDataRepositoryImpl(
        registry: _FakeRegistry(),

        cache: cache,
        venueSources: {Venue.binance: failingSources()},
      );

      final result = await repository.getCandles(symbol, Timeframe.h1);

      expect(result, isA<Success<List<Candle>>>());
      expect((result as Success<List<Candle>>).value, staleCandles);
    });

    test(
      'getOrderBook returns fresh cache without waiting for network',
      () async {
        final cache = _FakeMarketCacheDataSource()
          ..saveOrderBook(symbol, freshOrderBook);
        final delayedSource = _DelayedOrderBookSource();
        final repository = MarketDataRepositoryImpl(
          registry: _FakeRegistry(),

          cache: cache,
          venueSources: {
            Venue.binance: VenueSources(
              ticker: _FailingTickerSource(),
              candles: _FailingCandleSource(),
              orderBook: delayedSource,
              trades: _FailingTradeSource(),
              stream: _FailingStreamSource(),
            ),
          },
        );

        final future = repository.getOrderBook(symbol);
        final result = await future;

        expect(result, isA<Success<OrderBook>>());
        expect((result as Success<OrderBook>).value, freshOrderBook);

        delayedSource.complete(networkOrderBook);
        await pumpEventQueue();
        expect(await cache.getOrderBook(symbol), freshOrderBook);
      },
    );

    test('getOrderBook saves network result to cache', () async {
      final cache = _FakeMarketCacheDataSource();
      final repository = MarketDataRepositoryImpl(
        registry: _FakeRegistry(),

        cache: cache,
        venueSources: {
          Venue.binance: VenueSources(
            ticker: _FailingTickerSource(),
            candles: _FailingCandleSource(),
            orderBook: _SuccessfulOrderBookSource(networkOrderBook),
            trades: _FailingTradeSource(),
            stream: _FailingStreamSource(),
          ),
        },
      );

      final result = await repository.getOrderBook(symbol);

      expect(result, isA<Success<OrderBook>>());
      expect((result as Success<OrderBook>).value, networkOrderBook);
      expect(await cache.getOrderBook(symbol), networkOrderBook);
    });

    test('getOrderBook falls back to stale cache on network failure', () async {
      final cache = _FakeMarketCacheDataSource()
        ..saveOrderBook(symbol, staleOrderBook);
      final repository = MarketDataRepositoryImpl(
        registry: _FakeRegistry(),

        cache: cache,
        venueSources: {Venue.binance: failingSources()},
      );

      final result = await repository.getOrderBook(symbol);

      expect(result, isA<Success<OrderBook>>());
      expect((result as Success<OrderBook>).value, staleOrderBook);
    });

    test('getTrades returns fresh cache without waiting for network', () async {
      final cache = _FakeMarketCacheDataSource()
        ..saveTrades(symbol, freshTrades);
      final delayedSource = _DelayedTradeSource();
      final repository = MarketDataRepositoryImpl(
        registry: _FakeRegistry(),

        cache: cache,
        venueSources: {
          Venue.binance: VenueSources(
            ticker: _FailingTickerSource(),
            candles: _FailingCandleSource(),
            orderBook: _FailingOrderBookSource(),
            trades: delayedSource,
            stream: _FailingStreamSource(),
          ),
        },
      );

      final future = repository.getTrades(symbol);
      final result = await future;

      expect(result, isA<Success<List<Trade>>>());
      expect((result as Success<List<Trade>>).value, freshTrades);

      delayedSource.complete(networkTrades);
      await pumpEventQueue();
      expect(await cache.getTrades(symbol), freshTrades);
    });

    test(
      'getTicker background refresh updates cache when network is newer',
      () async {
        final newerNetworkTicker = Ticker(
          symbol: symbol,
          lastPrice: 300,
          bid: 299,
          ask: 301,
          change24h: 3,
          change24hPercent: 0.03,
          volume: 3000,
          timestamp: DateTime.now().toUtc().add(const Duration(seconds: 1)),
        );
        final cache = _FakeMarketCacheDataSource()..saveTicker(freshTicker);
        final delayedSource = _DelayedTickerSource();
        final repository = MarketDataRepositoryImpl(
          registry: _FakeRegistry(),

          cache: cache,
          venueSources: {
            Venue.binance: VenueSources(
              ticker: delayedSource,
              candles: _FailingCandleSource(),
              orderBook: _FailingOrderBookSource(),
              trades: _FailingTradeSource(),
              stream: _FailingStreamSource(),
            ),
          },
        );

        final future = repository.getTicker(symbol);
        final result = await future;

        expect(result, isA<Success<Ticker>>());
        expect((result as Success<Ticker>).value, freshTicker);

        delayedSource.complete(newerNetworkTicker);
        await pumpEventQueue();
        expect(await cache.getTicker(symbol), newerNetworkTicker);
      },
    );

    test(
      'getCandles background refresh updates cache when network is newer',
      () async {
        final newerNetworkCandles = [
          Candle(
            open: 3,
            high: 4,
            low: 2,
            close: 3.5,
            volume: 300,
            timestamp: DateTime.now().toUtc().add(const Duration(seconds: 1)),
          ),
        ];
        final cache = _FakeMarketCacheDataSource()
          ..saveCandles(symbol, Timeframe.h1, freshCandles);
        final delayedSource = _DelayedCandleSource();
        final repository = MarketDataRepositoryImpl(
          registry: _FakeRegistry(),

          cache: cache,
          venueSources: {
            Venue.binance: VenueSources(
              ticker: _FailingTickerSource(),
              candles: delayedSource,
              orderBook: _FailingOrderBookSource(),
              trades: _FailingTradeSource(),
              stream: _FailingStreamSource(),
            ),
          },
        );

        final future = repository.getCandles(symbol, Timeframe.h1);
        final result = await future;

        expect(result, isA<Success<List<Candle>>>());
        expect((result as Success<List<Candle>>).value, freshCandles);

        delayedSource.complete(newerNetworkCandles);
        await pumpEventQueue();
        expect(
          await cache.getCandles(symbol, Timeframe.h1),
          newerNetworkCandles,
        );
      },
    );

    test(
      'getOrderBook background refresh updates cache when network is newer',
      () async {
        final newerNetworkOrderBook = OrderBook(
          bids: const [OrderBookLevel(price: 299, amount: 1)],
          asks: const [OrderBookLevel(price: 301, amount: 1)],
          timestamp: DateTime.now().toUtc().add(const Duration(seconds: 1)),
        );
        final cache = _FakeMarketCacheDataSource()
          ..saveOrderBook(symbol, freshOrderBook);
        final delayedSource = _DelayedOrderBookSource();
        final repository = MarketDataRepositoryImpl(
          registry: _FakeRegistry(),

          cache: cache,
          venueSources: {
            Venue.binance: VenueSources(
              ticker: _FailingTickerSource(),
              candles: _FailingCandleSource(),
              orderBook: delayedSource,
              trades: _FailingTradeSource(),
              stream: _FailingStreamSource(),
            ),
          },
        );

        final future = repository.getOrderBook(symbol);
        final result = await future;

        expect(result, isA<Success<OrderBook>>());
        expect((result as Success<OrderBook>).value, freshOrderBook);

        delayedSource.complete(newerNetworkOrderBook);
        await pumpEventQueue();
        expect(await cache.getOrderBook(symbol), newerNetworkOrderBook);
      },
    );

    test(
      'getTrades background refresh updates cache when network is newer',
      () async {
        final newerNetworkTrades = [
          Trade(
            price: 300,
            amount: 3,
            side: TradeSide.buy,
            timestamp: DateTime.now().toUtc().add(const Duration(seconds: 1)),
            tradeId: 't3',
          ),
        ];
        final cache = _FakeMarketCacheDataSource()
          ..saveTrades(symbol, freshTrades);
        final delayedSource = _DelayedTradeSource();
        final repository = MarketDataRepositoryImpl(
          registry: _FakeRegistry(),

          cache: cache,
          venueSources: {
            Venue.binance: VenueSources(
              ticker: _FailingTickerSource(),
              candles: _FailingCandleSource(),
              orderBook: _FailingOrderBookSource(),
              trades: delayedSource,
              stream: _FailingStreamSource(),
            ),
          },
        );

        final future = repository.getTrades(symbol);
        final result = await future;

        expect(result, isA<Success<List<Trade>>>());
        expect((result as Success<List<Trade>>).value, freshTrades);

        delayedSource.complete(newerNetworkTrades);
        await pumpEventQueue();
        expect(await cache.getTrades(symbol), newerNetworkTrades);
      },
    );

    test('getTrades saves network result to cache', () async {
      final cache = _FakeMarketCacheDataSource();
      final repository = MarketDataRepositoryImpl(
        registry: _FakeRegistry(),

        cache: cache,
        venueSources: {
          Venue.binance: VenueSources(
            ticker: _FailingTickerSource(),
            candles: _FailingCandleSource(),
            orderBook: _FailingOrderBookSource(),
            trades: _SuccessfulTradeSource(networkTrades),
            stream: _FailingStreamSource(),
          ),
        },
      );

      final result = await repository.getTrades(symbol);

      expect(result, isA<Success<List<Trade>>>());
      expect((result as Success<List<Trade>>).value, networkTrades);
      expect(await cache.getTrades(symbol), networkTrades);
    });

    test('getTrades falls back to stale cache on network failure', () async {
      final cache = _FakeMarketCacheDataSource()
        ..saveTrades(symbol, staleTrades);
      final repository = MarketDataRepositoryImpl(
        registry: _FakeRegistry(),

        cache: cache,
        venueSources: {Venue.binance: failingSources()},
      );

      final result = await repository.getTrades(symbol);

      expect(result, isA<Success<List<Trade>>>());
      expect((result as Success<List<Trade>>).value, staleTrades);
    });

    test(
      'getTicker returns fresh cache and keeps it when background refresh throws',
      () async {
        final cache = _FakeMarketCacheDataSource()..saveTicker(freshTicker);
        final repository = MarketDataRepositoryImpl(
          registry: _FakeRegistry(),

          cache: cache,
          venueSources: {
            Venue.binance: VenueSources(
              ticker: _ThrowingTickerSource(),
              candles: _FailingCandleSource(),
              orderBook: _FailingOrderBookSource(),
              trades: _FailingTradeSource(),
              stream: _FailingStreamSource(),
            ),
          },
        );

        final result = await repository.getTicker(symbol);

        expect(result, isA<Success<Ticker>>());
        expect((result as Success<Ticker>).value, freshTicker);
        await pumpEventQueue();
        expect(await cache.getTicker(symbol), freshTicker);
      },
    );

    test('watchTicker emits cached snapshot before network updates', () async {
      final cache = _FakeMarketCacheDataSource()..saveTicker(freshTicker);
      final repository = MarketDataRepositoryImpl(
        registry: _FakeRegistry(),

        cache: cache,
        venueSources: {
          Venue.binance: VenueSources(
            ticker: _FailingTickerSource(),
            candles: _FailingCandleSource(),
            orderBook: _FailingOrderBookSource(),
            trades: _FailingTradeSource(),
            stream: _SuccessfulStreamSource(
              ticker: networkTicker,
              orderBook: networkOrderBook,
              trades: networkTrades,
            ),
          ),
        },
      );

      final values = await repository.watchTicker(symbol).take(2).toList();

      expect(values.length, 2);
      expect((values[0] as Success<Ticker>).value, freshTicker);
      expect((values[1] as Success<Ticker>).value, networkTicker);
    });

    test(
      'watchOrderBook emits cached snapshot before network updates',
      () async {
        final cache = _FakeMarketCacheDataSource()
          ..saveOrderBook(symbol, freshOrderBook);
        final repository = MarketDataRepositoryImpl(
          registry: _FakeRegistry(),

          cache: cache,
          venueSources: {
            Venue.binance: VenueSources(
              ticker: _FailingTickerSource(),
              candles: _FailingCandleSource(),
              orderBook: _FailingOrderBookSource(),
              trades: _FailingTradeSource(),
              stream: _SuccessfulStreamSource(
                ticker: networkTicker,
                orderBook: networkOrderBook,
                trades: networkTrades,
              ),
            ),
          },
        );

        final values = await repository.watchOrderBook(symbol).take(2).toList();

        expect(values.length, 2);
        expect((values[0] as Success<OrderBook>).value, freshOrderBook);
        expect((values[1] as Success<OrderBook>).value, networkOrderBook);
      },
    );

    test('watchTrades emits cached snapshot before network updates', () async {
      final cache = _FakeMarketCacheDataSource()
        ..saveTrades(symbol, freshTrades);
      final repository = MarketDataRepositoryImpl(
        registry: _FakeRegistry(),

        cache: cache,
        venueSources: {
          Venue.binance: VenueSources(
            ticker: _FailingTickerSource(),
            candles: _FailingCandleSource(),
            orderBook: _FailingOrderBookSource(),
            trades: _FailingTradeSource(),
            stream: _SuccessfulStreamSource(
              ticker: networkTicker,
              orderBook: networkOrderBook,
              trades: networkTrades,
            ),
          ),
        },
      );

      final values = await repository.watchTrades(symbol).take(2).toList();

      expect(values.length, 2);
      expect((values[0] as Success<List<Trade>>).value, freshTrades);
      expect((values[1] as Success<List<Trade>>).value, networkTrades);
    });
  });

  group('MarketDataRepositoryImpl unsupported features', () {
    final symbol = TradingSymbol(
      base: 'BTC',
      quote: 'USDT',
      venue: Venue.binance,
      rawSymbol: 'BTCUSDT',
    );

    test('getTicker returns exact UnsupportedFeatureFailure', () async {
      final repository = MarketDataRepositoryImpl(registry: _EmptyRegistry());

      final result = await repository.getTicker(symbol);

      expect(result, isA<Err<Ticker>>());
      result.when(
        success: (_) => fail('expected failure'),
        failure: (failure) {
          expect(failure, isA<UnsupportedFeatureFailure>());
          expect(failure.message, 'REST ticker is not supported by Binance');
        },
      );
    });

    test('getCandles returns exact UnsupportedFeatureFailure', () async {
      final repository = MarketDataRepositoryImpl(registry: _LimitedRegistry());

      final result = await repository.getCandles(symbol, Timeframe.h1);

      expect(result, isA<Err<List<Candle>>>());
      result.when(
        success: (_) => fail('expected failure'),
        failure: (failure) {
          expect(failure, isA<UnsupportedFeatureFailure>());
          expect(failure.message, 'REST candles is not supported by Binance');
        },
      );
    });

    test('getOrderBook returns exact UnsupportedFeatureFailure', () async {
      final repository = MarketDataRepositoryImpl(registry: _LimitedRegistry());

      final result = await repository.getOrderBook(symbol);

      expect(result, isA<Err<OrderBook>>());
      result.when(
        success: (_) => fail('expected failure'),
        failure: (failure) {
          expect(failure, isA<UnsupportedFeatureFailure>());
          expect(
            failure.message,
            'REST order book is not supported by Binance',
          );
        },
      );
    });

    test('getTrades returns exact UnsupportedFeatureFailure', () async {
      final repository = MarketDataRepositoryImpl(registry: _LimitedRegistry());

      final result = await repository.getTrades(symbol);

      expect(result, isA<Err<List<Trade>>>());
      result.when(
        success: (_) => fail('expected failure'),
        failure: (failure) {
          expect(failure, isA<UnsupportedFeatureFailure>());
          expect(failure.message, 'REST trades is not supported by Binance');
        },
      );
    });

    test('watchTicker yields exact UnsupportedFeatureFailure', () async {
      final repository = MarketDataRepositoryImpl(registry: _LimitedRegistry());

      final value = await repository.watchTicker(symbol).first;

      expect(value, isA<Err<Ticker>>());
      value.when(
        success: (_) => fail('expected failure'),
        failure: (failure) {
          expect(failure, isA<UnsupportedFeatureFailure>());
          expect(failure.message, 'WS ticker is not supported by Binance');
        },
      );
    });
  });

  group('MarketDataRepositoryImpl source exception path', () {
    final symbol = TradingSymbol(
      base: 'BTC',
      quote: 'USDT',
      venue: Venue.binance,
      rawSymbol: 'BTCUSDT',
    );

    test('getTicker returns UnknownFailure when source throws', () async {
      final repository = MarketDataRepositoryImpl(
        registry: _FakeRegistry(),
        venueSources: {
          Venue.binance: VenueSources(
            ticker: _ThrowingTickerSource(),
            candles: _FailingCandleSource(),
            orderBook: _FailingOrderBookSource(),
            trades: _FailingTradeSource(),
            stream: _FailingStreamSource(),
          ),
        },
      );

      final result = await repository.getTicker(symbol);

      expect(result, isA<Err<Ticker>>());
      result.when(
        success: (_) => fail('expected failure'),
        failure: (failure) {
          expect(failure, isA<UnknownFailure>());
          expect(
            failure.message,
            'Binance REST ticker source failed: Exception: boom',
          );
        },
      );
    });

    test('getCandles returns UnknownFailure when source throws', () async {
      final repository = MarketDataRepositoryImpl(
        registry: _FakeRegistry(),
        venueSources: {
          Venue.binance: VenueSources(
            ticker: _FailingTickerSource(),
            candles: _ThrowingCandleSource(),
            orderBook: _FailingOrderBookSource(),
            trades: _FailingTradeSource(),
            stream: _FailingStreamSource(),
          ),
        },
      );

      final result = await repository.getCandles(symbol, Timeframe.h1);

      expect(result, isA<Err<List<Candle>>>());
      result.when(
        success: (_) => fail('expected failure'),
        failure: (failure) {
          expect(failure, isA<UnknownFailure>());
          expect(
            failure.message,
            'Binance REST candles source failed: Exception: boom',
          );
        },
      );
    });

    test('getOrderBook returns UnknownFailure when source throws', () async {
      final repository = MarketDataRepositoryImpl(
        registry: _FakeRegistry(),
        venueSources: {
          Venue.binance: VenueSources(
            ticker: _FailingTickerSource(),
            candles: _FailingCandleSource(),
            orderBook: _ThrowingOrderBookSource2(),
            trades: _FailingTradeSource(),
            stream: _FailingStreamSource(),
          ),
        },
      );

      final result = await repository.getOrderBook(symbol);

      expect(result, isA<Err<OrderBook>>());
      result.when(
        success: (_) => fail('expected failure'),
        failure: (failure) {
          expect(failure, isA<UnknownFailure>());
          expect(
            failure.message,
            'Binance REST order book source failed: Exception: boom',
          );
        },
      );
    });

    test('getTrades returns UnknownFailure when source throws', () async {
      final repository = MarketDataRepositoryImpl(
        registry: _FakeRegistry(),
        venueSources: {
          Venue.binance: VenueSources(
            ticker: _FailingTickerSource(),
            candles: _FailingCandleSource(),
            orderBook: _FailingOrderBookSource(),
            trades: _ThrowingTradeSource2(),
            stream: _FailingStreamSource(),
          ),
        },
      );

      final result = await repository.getTrades(symbol);

      expect(result, isA<Err<List<Trade>>>());
      result.when(
        success: (_) => fail('expected failure'),
        failure: (failure) {
          expect(failure, isA<UnknownFailure>());
          expect(
            failure.message,
            'Binance REST trades source failed: Exception: boom',
          );
        },
      );
    });
  });

  group('MarketDataRepositoryImpl missing venue sources fallback', () {
    final symbol = TradingSymbol(
      base: 'BTC',
      quote: 'USDT',
      venue: Venue.binance,
      rawSymbol: 'BTCUSDT',
    );

    test(
      'getTicker falls back to mock when venueSources has no entry',
      () async {
        final expectedStore = const DeterministicMarketDataStore();
        final expected = await expectedStore.getTicker(symbol);
        final repository = MarketDataRepositoryImpl(
          registry: _FakeRegistry(),
          fallbackStore: const DeterministicMarketDataStore(),
        );

        final result = await repository.getTicker(symbol);

        expect(result, isA<Success<Ticker>>());
        _expectTickerEquals((result as Success<Ticker>).value, expected);
      },
    );

    test(
      'getCandles falls back to mock when venueSources has no entry',
      () async {
        final expectedStore = const DeterministicMarketDataStore();
        final expected = await expectedStore.getCandles(
          symbol,
          Timeframe.h1,
          limit: 3,
        );
        final repository = MarketDataRepositoryImpl(
          registry: _FakeRegistry(),
          fallbackStore: const DeterministicMarketDataStore(),
        );

        final result = await repository.getCandles(
          symbol,
          Timeframe.h1,
          limit: 3,
        );

        expect(result, isA<Success<List<Candle>>>());
        _expectCandlesEqual((result as Success<List<Candle>>).value, expected);
      },
    );

    test(
      'getOrderBook falls back to mock when venueSources has no entry',
      () async {
        final expectedStore = const DeterministicMarketDataStore();
        final expected = await expectedStore.getOrderBook(symbol, depth: 3);
        final repository = MarketDataRepositoryImpl(
          registry: _FakeRegistry(),
          fallbackStore: const DeterministicMarketDataStore(),
        );

        final result = await repository.getOrderBook(symbol, depth: 3);

        expect(result, isA<Success<OrderBook>>());
        _expectOrderBookEquals((result as Success<OrderBook>).value, expected);
      },
    );

    test(
      'getTrades falls back to mock when venueSources has no entry',
      () async {
        final expectedStore = const DeterministicMarketDataStore();
        final expected = await expectedStore.getTrades(symbol, limit: 3);
        final repository = MarketDataRepositoryImpl(
          registry: _FakeRegistry(),
          fallbackStore: const DeterministicMarketDataStore(),
        );

        final result = await repository.getTrades(symbol, limit: 3);

        expect(result, isA<Success<List<Trade>>>());
        _expectTradesEqual((result as Success<List<Trade>>).value, expected);
      },
    );
  });

  group('MarketDataRepositoryImpl parse failure path', () {
    final symbol = TradingSymbol(
      base: 'BTC',
      quote: 'USDT',
      venue: Venue.binance,
      rawSymbol: 'BTCUSDT',
    );

    VenueSources parseFailingSources() => VenueSources(
      ticker: _ParseFailureTickerSource(),
      candles: _ParseFailureCandleSource(),
      orderBook: _ParseFailureOrderBookSource(),
      trades: _ParseFailureTradeSource(),
      stream: _FailingStreamSource(),
    );

    test(
      'getTicker returns ParseFailure when source returns ParseFailure',
      () async {
        final repository = MarketDataRepositoryImpl(
          registry: _FakeRegistry(),
          venueSources: {Venue.binance: parseFailingSources()},
        );

        final result = await repository.getTicker(symbol);

        expect(result, isA<Err<Ticker>>());
        result.when(
          success: (_) => fail('expected failure'),
          failure: (failure) {
            expect(failure, isA<ParseFailure>());
            expect(failure.message, 'ticker parse error');
          },
        );
      },
    );

    test(
      'getCandles returns ParseFailure when source returns ParseFailure',
      () async {
        final repository = MarketDataRepositoryImpl(
          registry: _FakeRegistry(),
          venueSources: {Venue.binance: parseFailingSources()},
        );

        final result = await repository.getCandles(symbol, Timeframe.h1);

        expect(result, isA<Err<List<Candle>>>());
        result.when(
          success: (_) => fail('expected failure'),
          failure: (failure) {
            expect(failure, isA<ParseFailure>());
            expect(failure.message, 'candles parse error');
          },
        );
      },
    );

    test(
      'getOrderBook returns ParseFailure when source returns ParseFailure',
      () async {
        final repository = MarketDataRepositoryImpl(
          registry: _FakeRegistry(),
          venueSources: {Venue.binance: parseFailingSources()},
        );

        final result = await repository.getOrderBook(symbol);

        expect(result, isA<Err<OrderBook>>());
        result.when(
          success: (_) => fail('expected failure'),
          failure: (failure) {
            expect(failure, isA<ParseFailure>());
            expect(failure.message, 'order book parse error');
          },
        );
      },
    );

    test(
      'getTrades returns ParseFailure when source returns ParseFailure',
      () async {
        final repository = MarketDataRepositoryImpl(
          registry: _FakeRegistry(),
          venueSources: {Venue.binance: parseFailingSources()},
        );

        final result = await repository.getTrades(symbol);

        expect(result, isA<Err<List<Trade>>>());
        result.when(
          success: (_) => fail('expected failure'),
          failure: (failure) {
            expect(failure, isA<ParseFailure>());
            expect(failure.message, 'trades parse error');
          },
        );
      },
    );
  });

  group('MarketDataRepositoryImpl fallback store failure path', () {
    final symbol = TradingSymbol(
      base: 'BTC',
      quote: 'USDT',
      venue: Venue.binance,
      rawSymbol: 'BTCUSDT',
    );

    VenueSources networkFailingSources() => VenueSources(
      ticker: _FailingTickerSource(),
      candles: _FailingCandleSource(),
      orderBook: _FailingOrderBookSource(),
      trades: _FailingTradeSource(),
      stream: _FailingStreamSource(),
    );

    test(
      'getTicker returns UnknownFailure when network fails and mock throws',
      () async {
        final repository = MarketDataRepositoryImpl(
          registry: _FakeRegistry(),
          venueSources: {Venue.binance: networkFailingSources()},
          fallbackStore: _ThrowingMarketDataStore(),
        );

        final result = await repository.getTicker(symbol);

        expect(result, isA<Err<Ticker>>());
        result.when(
          success: (_) => fail('expected failure'),
          failure: (failure) {
            expect(failure, isA<UnknownFailure>());
            expect(failure.message, 'fallback store failed');
          },
        );
      },
    );

    test(
      'getCandles returns UnknownFailure when network fails and mock throws',
      () async {
        final repository = MarketDataRepositoryImpl(
          registry: _FakeRegistry(),
          venueSources: {Venue.binance: networkFailingSources()},
          fallbackStore: _ThrowingMarketDataStore(),
        );

        final result = await repository.getCandles(symbol, Timeframe.h1);

        expect(result, isA<Err<List<Candle>>>());
        result.when(
          success: (_) => fail('expected failure'),
          failure: (failure) {
            expect(failure, isA<UnknownFailure>());
            expect(failure.message, 'fallback store failed');
          },
        );
      },
    );

    test(
      'getOrderBook returns UnknownFailure when network fails and mock throws',
      () async {
        final repository = MarketDataRepositoryImpl(
          registry: _FakeRegistry(),
          venueSources: {Venue.binance: networkFailingSources()},
          fallbackStore: _ThrowingMarketDataStore(),
        );

        final result = await repository.getOrderBook(symbol);

        expect(result, isA<Err<OrderBook>>());
        result.when(
          success: (_) => fail('expected failure'),
          failure: (failure) {
            expect(failure, isA<UnknownFailure>());
            expect(failure.message, 'fallback store failed');
          },
        );
      },
    );

    test(
      'getTrades returns UnknownFailure when network fails and mock throws',
      () async {
        final repository = MarketDataRepositoryImpl(
          registry: _FakeRegistry(),
          venueSources: {Venue.binance: networkFailingSources()},
          fallbackStore: _ThrowingMarketDataStore(),
        );

        final result = await repository.getTrades(symbol);

        expect(result, isA<Err<List<Trade>>>());
        result.when(
          success: (_) => fail('expected failure'),
          failure: (failure) {
            expect(failure, isA<UnknownFailure>());
            expect(failure.message, 'fallback store failed');
          },
        );
      },
    );
  });

  group('MarketDataRepositoryImpl background refresh exception path', () {
    final symbol = TradingSymbol(
      base: 'BTC',
      quote: 'USDT',
      venue: Venue.binance,
      rawSymbol: 'BTCUSDT',
    );

    final freshTicker = Ticker(
      symbol: symbol,
      lastPrice: 100,
      bid: 99,
      ask: 101,
      change24h: 1,
      change24hPercent: 0.01,
      volume: 1000,
      timestamp: DateTime.now().toUtc().subtract(const Duration(seconds: 10)),
    );

    final freshCandles = [
      Candle(
        open: 1,
        high: 2,
        low: 0.5,
        close: 1.5,
        volume: 100,
        timestamp: DateTime.now().toUtc().subtract(const Duration(minutes: 2)),
      ),
    ];

    final freshOrderBook = OrderBook(
      bids: const [OrderBookLevel(price: 99, amount: 1)],
      asks: const [OrderBookLevel(price: 101, amount: 1)],
      timestamp: DateTime.now().toUtc().subtract(const Duration(seconds: 10)),
    );

    final freshTrades = [
      Trade(
        price: 100,
        amount: 1,
        side: TradeSide.buy,
        timestamp: DateTime.now().toUtc().subtract(const Duration(seconds: 10)),
        tradeId: 't1',
      ),
    ];

    test(
      'getTicker returns cached value when background refresh throws',
      () async {
        final cache = _FakeMarketCacheDataSource()..saveTicker(freshTicker);
        final repository = MarketDataRepositoryImpl(
          registry: _FakeRegistry(),
          cache: cache,
          venueSources: {
            Venue.binance: VenueSources(
              ticker: _ThrowingTickerSource(),
              candles: _FailingCandleSource(),
              orderBook: _FailingOrderBookSource(),
              trades: _FailingTradeSource(),
              stream: _FailingStreamSource(),
            ),
          },
        );

        final result = await repository.getTicker(symbol);

        expect(result, isA<Success<Ticker>>());
        expect((result as Success<Ticker>).value, freshTicker);
        await pumpEventQueue();
      },
    );

    test(
      'getCandles returns cached value when background refresh throws',
      () async {
        final cache = _FakeMarketCacheDataSource()
          ..saveCandles(symbol, Timeframe.h1, freshCandles);
        final repository = MarketDataRepositoryImpl(
          registry: _FakeRegistry(),
          cache: cache,
          venueSources: {
            Venue.binance: VenueSources(
              ticker: _FailingTickerSource(),
              candles: _ThrowingCandleSource(),
              orderBook: _FailingOrderBookSource(),
              trades: _FailingTradeSource(),
              stream: _FailingStreamSource(),
            ),
          },
        );

        final result = await repository.getCandles(symbol, Timeframe.h1);

        expect(result, isA<Success<List<Candle>>>());
        expect((result as Success<List<Candle>>).value, freshCandles);
        await pumpEventQueue();
      },
    );

    test(
      'getOrderBook returns cached value when background refresh throws',
      () async {
        final cache = _FakeMarketCacheDataSource()
          ..saveOrderBook(symbol, freshOrderBook);
        final repository = MarketDataRepositoryImpl(
          registry: _FakeRegistry(),
          cache: cache,
          venueSources: {
            Venue.binance: VenueSources(
              ticker: _FailingTickerSource(),
              candles: _FailingCandleSource(),
              orderBook: _ThrowingOrderBookSource2(),
              trades: _FailingTradeSource(),
              stream: _FailingStreamSource(),
            ),
          },
        );

        final result = await repository.getOrderBook(symbol);

        expect(result, isA<Success<OrderBook>>());
        expect((result as Success<OrderBook>).value, freshOrderBook);
        await pumpEventQueue();
      },
    );

    test(
      'getTrades returns cached value when background refresh throws',
      () async {
        final cache = _FakeMarketCacheDataSource()
          ..saveTrades(symbol, freshTrades);
        final repository = MarketDataRepositoryImpl(
          registry: _FakeRegistry(),
          cache: cache,
          venueSources: {
            Venue.binance: VenueSources(
              ticker: _FailingTickerSource(),
              candles: _FailingCandleSource(),
              orderBook: _FailingOrderBookSource(),
              trades: _ThrowingTradeSource2(),
              stream: _FailingStreamSource(),
            ),
          },
        );

        final result = await repository.getTrades(symbol);

        expect(result, isA<Success<List<Trade>>>());
        expect((result as Success<List<Trade>>).value, freshTrades);
        await pumpEventQueue();
      },
    );
  });

  group('MarketDataRepositoryImpl watch mock fallback', () {
    final symbol = TradingSymbol(
      base: 'BTC',
      quote: 'USDT',
      venue: Venue.binance,
      rawSymbol: 'BTCUSDT',
    );

    test(
      'watchTicker falls back to mock stream when no cache and no stream source',
      () async {
        const expectedStore = DeterministicMarketDataStore();
        final expected = await expectedStore.getTicker(symbol);
        final repository = MarketDataRepositoryImpl(
          registry: _FakeRegistry(),
          fallbackStore: const DeterministicMarketDataStore(),
        );

        final values = await repository.watchTicker(symbol).take(1).toList();

        expect(values.length, 1);
        expect(values[0], isA<Success<Ticker>>());
        _expectTickerEquals((values[0] as Success<Ticker>).value, expected);
      },
    );

    test(
      'watchOrderBook falls back to mock stream when no cache and no stream source',
      () async {
        const expectedStore = DeterministicMarketDataStore();
        final expected = await expectedStore.getOrderBook(symbol);
        final repository = MarketDataRepositoryImpl(
          registry: _FakeRegistry(),
          fallbackStore: const DeterministicMarketDataStore(),
        );

        final values = await repository.watchOrderBook(symbol).take(1).toList();

        expect(values.length, 1);
        expect(values[0], isA<Success<OrderBook>>());
        _expectOrderBookEquals(
          (values[0] as Success<OrderBook>).value,
          expected,
        );
      },
    );

    test(
      'watchTrades falls back to mock stream when no cache and no stream source',
      () async {
        const expectedStore = DeterministicMarketDataStore();
        final expected = await expectedStore.getTrades(symbol);
        final repository = MarketDataRepositoryImpl(
          registry: _FakeRegistry(),
          fallbackStore: const DeterministicMarketDataStore(),
        );

        final values = await repository.watchTrades(symbol).take(1).toList();

        expect(values.length, 1);
        expect(values[0], isA<Success<List<Trade>>>());
        _expectTradesEqual((values[0] as Success<List<Trade>>).value, expected);
      },
    );
  });
}
