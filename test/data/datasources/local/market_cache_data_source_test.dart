import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:youtrade/data/datasources/local/app_database.dart';
import 'package:youtrade/data/datasources/local/market_cache_data_source.dart';
import 'package:youtrade/domain/entities/candle.dart';
import 'package:youtrade/domain/entities/order_book.dart';
import 'package:youtrade/domain/entities/symbol.dart';
import 'package:youtrade/domain/entities/ticker.dart';
import 'package:youtrade/domain/entities/timeframe.dart';
import 'package:youtrade/domain/entities/trade.dart';
import 'package:youtrade/domain/entities/venue.dart';

void main() {
  group('MarketCacheDataSource', () {
    late AppDatabase database;
    late MarketCacheDataSource cache;
    final symbol = TradingSymbol(
      base: 'BTC',
      quote: 'USDT',
      venue: Venue.binance,
      rawSymbol: 'BTCUSDT',
    );

    setUp(() {
      database = AppDatabase(database: NativeDatabase.memory());
      cache = MarketCacheDataSource(database: database);
    });

    tearDown(() async {
      await database.close();
    });

    test('saves and retrieves a ticker', () async {
      final ticker = Ticker(
        symbol: symbol,
        lastPrice: 100.0,
        bid: 99.5,
        ask: 100.5,
        change24h: 1.0,
        change24hPercent: 0.01,
        volume: 1000.0,
        timestamp: DateTime(2026, 6, 21, 12),
      );
      await cache.saveTicker(ticker);
      final retrieved = await cache.getTicker(symbol);
      expect(retrieved, ticker);
    });

    test('saves and retrieves candles', () async {
      final candles = [
        Candle(
          open: 1.0,
          high: 2.0,
          low: 0.5,
          close: 1.5,
          volume: 100.0,
          timestamp: DateTime(2026, 6, 21, 11),
        ),
        Candle(
          open: 1.5,
          high: 2.5,
          low: 1.0,
          close: 2.0,
          volume: 200.0,
          timestamp: DateTime(2026, 6, 21, 12),
        ),
      ];
      await cache.saveCandles(symbol, Timeframe.h1, candles);
      final retrieved = await cache.getCandles(symbol, Timeframe.h1);
      expect(retrieved.length, 2);
      expect(retrieved.map((c) => c.close), containsAll([1.5, 2.0]));
    });

    test('saves and retrieves order book', () async {
      final orderBook = OrderBook(
        bids: const [OrderBookLevel(price: 99.0, amount: 1.0)],
        asks: const [OrderBookLevel(price: 101.0, amount: 1.0)],
        timestamp: DateTime(2026, 6, 21, 12),
      );
      await cache.saveOrderBook(symbol, orderBook);
      final retrieved = await cache.getOrderBook(symbol);
      expect(retrieved, isNotNull);
      expect(retrieved!.bids.first.price, 99.0);
      expect(retrieved.asks.first.price, 101.0);
      expect(retrieved.timestamp, orderBook.timestamp);
    });

    test('saves and retrieves trades', () async {
      final trades = [
        Trade(
          price: 100.0,
          amount: 1.0,
          side: TradeSide.buy,
          timestamp: DateTime(2026, 6, 21, 12),
          tradeId: 't1',
        ),
      ];
      await cache.saveTrades(symbol, trades);
      final retrieved = await cache.getTrades(symbol);
      expect(retrieved, trades);
    });
  });
}
