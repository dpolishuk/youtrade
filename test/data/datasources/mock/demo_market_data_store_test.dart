import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:youtrade/data/datasources/mock/demo_market_data_store.dart';
import 'package:youtrade/domain/entities/symbol.dart';
import 'package:youtrade/domain/entities/timeframe.dart';
import 'package:youtrade/domain/entities/trade.dart';
import 'package:youtrade/domain/entities/venue.dart';

void main() {
  group('DemoMarketDataStore', () {
    final symbol = TradingSymbol(
      base: 'BTC',
      quote: 'USDT',
      venue: Venue.binance,
      rawSymbol: 'BTCUSDT',
    );
    late DemoMarketDataStore store;

    setUp(() => store = DemoMarketDataStore());

    test('returns deterministic ticker for symbol', () async {
      final ticker = await store.getTicker(symbol);

      expect(ticker.symbol, symbol);
      expect(ticker.lastPrice, closeTo(62668.40509202628, 1e-9));
      expect(ticker.bid, closeTo(62637.070889480274, 1e-9));
      expect(ticker.ask, closeTo(62699.73929457229, 1e-9));
      expect(ticker.spread, closeTo(62.66840509201512, 1e-9));
      expect(ticker.timestamp, isNotNull);
      expect(
        DateTime.now().toUtc().difference(ticker.timestamp).inSeconds,
        lessThan(5),
      );
    });

    test('returns candles for symbol and timeframe', () async {
      final candles = await store.getCandles(symbol, Timeframe.h1, limit: 10);

      expect(candles.length, 10);

      final first = candles.first;
      expect(first.open, closeTo(63109.0, 1e-9));
      expect(first.high, closeTo(63490.27174398782, 1e-9));
      expect(first.low, closeTo(62253.74015263581, 1e-9));
      expect(first.close, closeTo(62668.40509202628, 1e-9));
      expect(first.volume, closeTo(1394654.3731219976, 1e-9));

      final last = candles.last;
      expect(last.open, closeTo(62922.26275821006, 1e-9));
      expect(last.high, closeTo(63346.73879738399, 1e-9));
      expect(last.low, closeTo(62096.08382479038, 1e-9));
      expect(last.close, closeTo(62504.629314044396, 1e-9));
      expect(last.volume, closeTo(1762680.8913776842, 1e-9));

      for (var i = 0; i < candles.length - 1; i++) {
        expect(
          candles[i].timestamp.isBefore(candles[i + 1].timestamp),
          isTrue,
          reason: 'candle $i should be older than candle ${i + 1}',
        );
      }

      for (final candle in candles) {
        final highest = math.max(
          math.max(candle.open, candle.close),
          candle.low,
        );
        final lowest = math.min(
          math.min(candle.open, candle.close),
          candle.high,
        );
        expect(
          candle.high,
          greaterThanOrEqualTo(highest),
          reason: 'high should be >= max(open, close, low)',
        );
        expect(
          candle.low,
          lessThanOrEqualTo(lowest),
          reason: 'low should be <= min(open, close, high)',
        );
      }
    });

    test('returns order book with bids and asks', () async {
      final orderBook = await store.getOrderBook(symbol, depth: 5);

      expect(orderBook.bids.length, 5);
      expect(orderBook.asks.length, 5);

      expect(orderBook.bestBid, closeTo(62605.73668693426, 1e-9));
      expect(orderBook.bids.first.amount, closeTo(6.141479725361217, 1e-9));
      expect(orderBook.bestAsk, closeTo(62731.0734971183, 1e-9));
      expect(orderBook.asks.first.amount, closeTo(6.716810157870647, 1e-9));

      expect(orderBook.spread, closeTo(125.3368101840412, 1e-9));
      expect(orderBook.spread, greaterThan(0));

      for (var i = 0; i < orderBook.bids.length - 1; i++) {
        expect(
          orderBook.bids[i].price,
          greaterThan(orderBook.bids[i + 1].price),
          reason: 'bids should be sorted descending',
        );
      }

      for (var i = 0; i < orderBook.asks.length - 1; i++) {
        expect(
          orderBook.asks[i].price,
          lessThan(orderBook.asks[i + 1].price),
          reason: 'asks should be sorted ascending',
        );
      }
    });

    test('returns trades for symbol', () async {
      final trades = await store.getTrades(symbol, limit: 3);

      expect(trades.length, 3);

      expect(trades[0].price, closeTo(62668.40509202628, 1e-9));
      expect(trades[0].amount, closeTo(3.0307398626806084, 1e-9));
      expect(trades[0].side, TradeSide.sell);
      expect(trades[0].tradeId, 'mock-trade-0');

      expect(trades[1].price, closeTo(63234.803956395765, 1e-9));
      expect(trades[1].amount, closeTo(1.1695008816734076, 1e-9));
      expect(trades[1].side, TradeSide.buy);
      expect(trades[1].tradeId, 'mock-trade-1');

      expect(trades[2].price, closeTo(62680.580823489414, 1e-9));
      expect(trades[2].amount, closeTo(2.067785068677937, 1e-9));
      expect(trades[2].side, TradeSide.sell);
      expect(trades[2].tradeId, 'mock-trade-2');

      for (final trade in trades) {
        expect(trade.tradeId, startsWith('mock-trade-'));
        expect(trade.timestamp, isNotNull);
      }
    });

    test('watchTicker emits values', () async {
      final values = await store.watchTicker(symbol).take(2).toList();

      expect(values.length, 2);
      expect(values.first.symbol, symbol);
      expect(values.first.lastPrice, closeTo(62668.40509202628, 1e-9));
    });
  });
}
