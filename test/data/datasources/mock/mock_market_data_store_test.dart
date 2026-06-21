import 'package:flutter_test/flutter_test.dart';
import 'package:youtrade/data/datasources/mock/mock_market_data_store.dart';
import 'package:youtrade/domain/entities/symbol.dart';
import 'package:youtrade/domain/entities/timeframe.dart';
import 'package:youtrade/domain/entities/venue.dart';

void main() {
  group('MockMarketDataStore', () {
    final symbol = TradingSymbol(
      base: 'BTC',
      quote: 'USDT',
      venue: Venue.binance,
      rawSymbol: 'BTCUSDT',
    );
    final store = MockMarketDataStore();

    test('returns deterministic ticker for symbol', () async {
      final ticker = await store.getTicker(symbol);
      expect(ticker.symbol, symbol);
      expect(ticker.lastPrice, greaterThan(0));
      expect(ticker.spread, greaterThanOrEqualTo(0));
    });

    test('returns candles for symbol and timeframe', () async {
      final candles = await store.getCandles(symbol, Timeframe.h1, limit: 10);
      expect(candles.length, 10);
      expect(candles.first.high, greaterThanOrEqualTo(candles.first.low));
    });

    test('returns order book with bids and asks', () async {
      final orderBook = await store.getOrderBook(symbol, depth: 5);
      expect(orderBook.bids.length, 5);
      expect(orderBook.asks.length, 5);
      expect(orderBook.spread, greaterThan(0));
    });

    test('returns trades for symbol', () async {
      final trades = await store.getTrades(symbol, limit: 3);
      expect(trades.length, 3);
    });

    test('watchTicker emits values', () async {
      final values = await store.watchTicker(symbol).take(2).toList();
      expect(values.length, 2);
      expect(values.first.symbol, symbol);
    });
  });
}
