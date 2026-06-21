import 'package:flutter_test/flutter_test.dart';
import 'package:youtrade/core/result.dart';
import 'package:youtrade/data/repositories/market_data_repository_impl.dart';
import 'package:youtrade/domain/entities/symbol.dart';
import 'package:youtrade/domain/entities/timeframe.dart';
import 'package:youtrade/domain/entities/venue.dart';
import 'package:youtrade/domain/registry/exchange_capability.dart';

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
}

void main() {
  group('MarketDataRepositoryImpl with mock store', () {
    final symbol = TradingSymbol(
      base: 'BTC',
      quote: 'USDT',
      venue: Venue.binance,
      rawSymbol: 'BTCUSDT',
    );
    late MarketDataRepositoryImpl repository;

    setUp(() {
      repository = MarketDataRepositoryImpl(registry: _FakeRegistry());
    });

    test('getTicker returns Success with ticker', () async {
      final result = await repository.getTicker(symbol);
      expect(result, isA<Success>());
      result.when(
        success: (ticker) {
          expect(ticker.symbol, symbol);
          expect(ticker.lastPrice, greaterThan(0));
        },
        failure: (_) => fail('expected success'),
      );
    });

    test('getCandles returns Success with candles', () async {
      final result = await repository.getCandles(
        symbol,
        Timeframe.h1,
        limit: 5,
      );
      expect(result, isA<Success>());
      result.when(
        success: (candles) => expect(candles.length, 5),
        failure: (_) => fail('expected success'),
      );
    });

    test('getOrderBook returns Success with order book', () async {
      final result = await repository.getOrderBook(symbol, depth: 3);
      expect(result, isA<Success>());
      result.when(
        success: (orderBook) {
          expect(orderBook.bids.length, 3);
          expect(orderBook.asks.length, 3);
        },
        failure: (_) => fail('expected success'),
      );
    });

    test('watchTicker emits Success values', () async {
      final values = await repository.watchTicker(symbol).take(2).toList();
      expect(values.length, 2);
      expect(values.every((r) => r is Success), isTrue);
    });
  });
}
