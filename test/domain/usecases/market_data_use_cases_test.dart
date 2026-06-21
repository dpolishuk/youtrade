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
import 'package:youtrade/domain/registry/exchange_capability.dart';
import 'package:youtrade/domain/repositories/market_data_repository.dart';
import 'package:youtrade/domain/usecases/market_data_use_cases.dart';

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

final class _FakeRepository implements MarketDataRepository {
  _FakeRepository({
    this.tickerResult,
    this.candlesResult,
    this.tradesResult,
    this.tickerStream,
    this.orderBookStream,
    this.tradesStream,
  });

  final Result<Ticker>? tickerResult;
  final Result<List<Candle>>? candlesResult;
  final Result<List<Trade>>? tradesResult;
  final Stream<Result<Ticker>>? tickerStream;
  final Stream<Result<OrderBook>>? orderBookStream;
  final Stream<Result<List<Trade>>>? tradesStream;

  @override
  Future<Result<Ticker>> getTicker(TradingSymbol symbol) async =>
      tickerResult ?? Success(_ticker(symbol));

  @override
  Future<Result<List<Candle>>> getCandles(
    TradingSymbol symbol,
    Timeframe timeframe, {
    int? limit,
  }) async => candlesResult ?? Success([_candle()]);

  @override
  Future<Result<OrderBook>> getOrderBook(
    TradingSymbol symbol, {
    int? depth,
  }) async => Success(_orderBook());

  @override
  Future<Result<List<Trade>>> getTrades(
    TradingSymbol symbol, {
    int? limit,
  }) async => tradesResult ?? Success([_trade()]);

  @override
  Stream<Result<Ticker>> watchTicker(TradingSymbol symbol) =>
      tickerStream ?? Stream.value(Success(_ticker(symbol)));

  @override
  Stream<Result<OrderBook>> watchOrderBook(TradingSymbol symbol) =>
      orderBookStream ?? Stream.value(Success(_orderBook()));

  @override
  Stream<Result<List<Trade>>> watchTrades(TradingSymbol symbol) =>
      tradesStream ?? Stream.value(Success([_trade()]));
}

final class _FakeRegistry implements ExchangeCapabilityRegistry {
  const _FakeRegistry(this.capabilities);

  final List<ExchangeCapability> capabilities;

  @override
  List<ExchangeCapability> get all => capabilities;

  @override
  ExchangeCapability? forVenue(Venue venue) {
    try {
      return capabilities.firstWhere((c) => c.venue == venue);
    } on StateError {
      return null;
    }
  }
}

void main() {
  final symbol = _symbol;

  group('GetTickerUseCase', () {
    test('returns ticker from repository', () async {
      final expected = _ticker(symbol);
      final repository = _FakeRepository(tickerResult: Success(expected));
      final useCase = GetTickerUseCase(repository);

      final result = await useCase.call(symbol);

      expect(result, Success(expected));
    });

    test('returns failure from repository', () async {
      const failure = NetworkFailure('offline');
      final repository = _FakeRepository(tickerResult: const Err(failure));
      final useCase = GetTickerUseCase(repository);

      final result = await useCase.call(symbol);

      expect(result, const Err<Ticker>(failure));
    });
  });

  group('GetCandlesUseCase', () {
    test('returns candles from repository', () async {
      final expected = [_candle()];
      final repository = _FakeRepository(candlesResult: Success(expected));
      final useCase = GetCandlesUseCase(repository);

      final result = await useCase.call(symbol, Timeframe.h1);

      expect(result, Success(expected));
    });

    test('passes limit to repository', () async {
      Timeframe? capturedTimeframe;
      int? capturedLimit;
      final repository = _FakeRepository(candlesResult: Success([_candle()]));
      final decoratedRepository = _RecordingRepository(
        delegate: repository,
        onGetCandles: (s, t, l) {
          capturedTimeframe = t;
          capturedLimit = l;
        },
      );
      final useCase = GetCandlesUseCase(decoratedRepository);

      await useCase.call(symbol, Timeframe.h4, limit: 50);

      expect(capturedTimeframe, Timeframe.h4);
      expect(capturedLimit, 50);
    });
  });

  group('GetTradesUseCase', () {
    test('returns trades from repository', () async {
      final expected = [_trade()];
      final repository = _FakeRepository(tradesResult: Success(expected));
      final useCase = GetTradesUseCase(repository);

      final result = await useCase.call(symbol);

      expect(result, Success(expected));
    });

    test('passes limit to repository', () async {
      int? capturedLimit;
      final repository = _FakeRepository(tradesResult: Success([_trade()]));
      final decoratedRepository = _RecordingRepository(
        delegate: repository,
        onGetTrades: (s, l) => capturedLimit = l,
      );
      final useCase = GetTradesUseCase(decoratedRepository);

      await useCase.call(symbol, limit: 25);

      expect(capturedLimit, 25);
    });
  });

  group('WatchTickerUseCase', () {
    test('emits ticker from repository stream', () async {
      final expected = _ticker(symbol);
      final repository = _FakeRepository(
        tickerStream: Stream.value(Success(expected)),
      );
      final useCase = WatchTickerUseCase(repository);

      await expectLater(
        useCase.call(symbol),
        emitsInOrder([Success(expected)]),
      );
    });
  });

  group('WatchOrderBookUseCase', () {
    test('emits order book from repository stream', () async {
      final expected = _orderBook();
      final repository = _FakeRepository(
        orderBookStream: Stream.value(Success(expected)),
      );
      final useCase = WatchOrderBookUseCase(repository);

      await expectLater(
        useCase.call(symbol),
        emitsInOrder([Success(expected)]),
      );
    });
  });

  group('WatchTradesUseCase', () {
    test('emits trades from repository stream', () async {
      final expected = [_trade()];
      final repository = _FakeRepository(
        tradesStream: Stream.value(Success(expected)),
      );
      final useCase = WatchTradesUseCase(repository);

      await expectLater(
        useCase.call(symbol),
        emitsInOrder([Success(expected)]),
      );
    });
  });

  group('GetSupportedFeaturesUseCase', () {
    test('returns supported features for a venue', () {
      const features = {
        MarketDataFeature.restTicker,
        MarketDataFeature.wsTicker,
      };
      final registry = _FakeRegistry([
        const ExchangeCapability(
          venue: Venue.binance,
          supportedFeatures: features,
        ),
      ]);
      final useCase = GetSupportedFeaturesUseCase(registry);

      final result = useCase.call(Venue.binance);

      expect(result, features);
    });

    test('returns empty set when venue is unknown', () {
      const registry = _FakeRegistry([]);
      final useCase = GetSupportedFeaturesUseCase(registry);

      final result = useCase.call(Venue.bybit);

      expect(result, isEmpty);
    });
  });
}

typedef _GetCandlesCallback =
    void Function(TradingSymbol symbol, Timeframe timeframe, int? limit);

typedef _GetTradesCallback = void Function(TradingSymbol symbol, int? limit);

final class _RecordingRepository implements MarketDataRepository {
  _RecordingRepository({
    required this.delegate,
    this.onGetCandles,
    this.onGetTrades,
  });

  final MarketDataRepository delegate;
  final _GetCandlesCallback? onGetCandles;
  final _GetTradesCallback? onGetTrades;

  @override
  Future<Result<Ticker>> getTicker(TradingSymbol symbol) =>
      delegate.getTicker(symbol);

  @override
  Future<Result<List<Candle>>> getCandles(
    TradingSymbol symbol,
    Timeframe timeframe, {
    int? limit,
  }) {
    onGetCandles?.call(symbol, timeframe, limit);
    return delegate.getCandles(symbol, timeframe, limit: limit);
  }

  @override
  Future<Result<OrderBook>> getOrderBook(TradingSymbol symbol, {int? depth}) =>
      delegate.getOrderBook(symbol, depth: depth);

  @override
  Future<Result<List<Trade>>> getTrades(TradingSymbol symbol, {int? limit}) {
    onGetTrades?.call(symbol, limit);
    return delegate.getTrades(symbol, limit: limit);
  }

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
