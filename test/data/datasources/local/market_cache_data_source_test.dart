import 'package:drift/drift.dart' hide isNull, isNotNull;
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

    // Catches OHLCV field corruption, volume loss, or ordering bugs in the
    // candle cache roundtrip.
    test('saves and retrieves candles', () async {
      final olderCandle = Candle(
        open: 1.0,
        high: 2.0,
        low: 0.5,
        close: 1.5,
        volume: 100.0,
        timestamp: DateTime(2026, 6, 21, 11),
      );
      final newerCandle = Candle(
        open: 1.5,
        high: 2.5,
        low: 1.0,
        close: 2.0,
        volume: 200.0,
        timestamp: DateTime(2026, 6, 21, 12),
      );
      final candles = [olderCandle, newerCandle];
      await cache.saveCandles(symbol, Timeframe.h1, candles);
      final retrieved = await cache.getCandles(symbol, Timeframe.h1);
      // The data source returns candles ordered oldest-first.
      expect(retrieved, [olderCandle, newerCandle]);
    });

    // Catches bid/ask level corruption, amount loss, or timestamp drift in the
    // order book cache roundtrip.
    test('saves and retrieves order book', () async {
      final orderBook = OrderBook(
        bids: const [OrderBookLevel(price: 99.0, amount: 1.0)],
        asks: const [OrderBookLevel(price: 101.0, amount: 1.0)],
        timestamp: DateTime(2026, 6, 21, 12),
      );
      await cache.saveOrderBook(symbol, orderBook);
      final retrieved = await cache.getOrderBook(symbol);
      expect(retrieved, isNotNull);
      expect(retrieved!.bids, orderBook.bids);
      expect(retrieved.asks, orderBook.asks);
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

    test('returns null for missing ticker', () async {
      final retrieved = await cache.getTicker(symbol);
      expect(retrieved, isNull);
    });

    test('returns empty list for missing candles', () async {
      final retrieved = await cache.getCandles(symbol, Timeframe.h1);
      expect(retrieved, isEmpty);
    });

    test('returns null for missing order book', () async {
      final retrieved = await cache.getOrderBook(symbol);
      expect(retrieved, isNull);
    });

    test('returns null for missing trades', () async {
      final retrieved = await cache.getTrades(symbol);
      expect(retrieved, isNull);
    });

    test('saves and retrieves empty candle list', () async {
      await cache.saveCandles(symbol, Timeframe.h1, const []);
      final retrieved = await cache.getCandles(symbol, Timeframe.h1);
      expect(retrieved, isEmpty);
    });

    test(
      'saveTrades stores newest trade timestamp as cache timestamp',
      () async {
        final olderTrade = Trade(
          price: 100.0,
          amount: 1.0,
          side: TradeSide.buy,
          timestamp: DateTime(2026, 6, 21, 11),
          tradeId: 't1',
        );
        final newerTrade = Trade(
          price: 200.0,
          amount: 2.0,
          side: TradeSide.sell,
          timestamp: DateTime(2026, 6, 21, 13),
          tradeId: 't2',
        );
        await cache.saveTrades(symbol, [olderTrade, newerTrade]);
        final row =
            await (database.cachedTrades.select()
                  ..where((t) => t.symbolId.equals(symbol.id)))
                .getSingle();
        expect(row.timestamp, newerTrade.timestamp);
      },
    );

    test('saves and retrieves empty trade list', () async {
      await cache.saveTrades(symbol, const []);
      final retrieved = await cache.getTrades(symbol);
      expect(retrieved, isEmpty);
    });

    test('limit parameter truncates candles oldest first', () async {
      final candles = [
        Candle(
          open: 1.0,
          high: 2.0,
          low: 0.5,
          close: 1.5,
          volume: 100.0,
          timestamp: DateTime(2026, 6, 21, 10),
        ),
        Candle(
          open: 1.5,
          high: 2.5,
          low: 1.0,
          close: 2.0,
          volume: 200.0,
          timestamp: DateTime(2026, 6, 21, 11),
        ),
        Candle(
          open: 2.0,
          high: 3.0,
          low: 1.5,
          close: 2.5,
          volume: 300.0,
          timestamp: DateTime(2026, 6, 21, 12),
        ),
      ];
      await cache.saveCandles(symbol, Timeframe.h1, candles);
      final retrieved = await cache.getCandles(symbol, Timeframe.h1, limit: 2);
      expect(retrieved.length, 2);
      expect(retrieved.first, candles.first);
      expect(retrieved.last, candles[1]);
    });

    test('duplicate save updates ticker', () async {
      final oldTicker = Ticker(
        symbol: symbol,
        lastPrice: 100.0,
        bid: 99.5,
        ask: 100.5,
        change24h: 1.0,
        change24hPercent: 0.01,
        volume: 1000.0,
        timestamp: DateTime(2026, 6, 21, 12),
      );
      final newTicker = Ticker(
        symbol: symbol,
        lastPrice: 200.0,
        bid: 199.5,
        ask: 200.5,
        change24h: 2.0,
        change24hPercent: 0.02,
        volume: 2000.0,
        timestamp: DateTime(2026, 6, 21, 13),
      );
      await cache.saveTicker(oldTicker);
      await cache.saveTicker(newTicker);
      final retrieved = await cache.getTicker(symbol);
      expect(retrieved, newTicker);
    });

    test('duplicate save updates order book', () async {
      final oldOrderBook = OrderBook(
        bids: const [OrderBookLevel(price: 99.0, amount: 1.0)],
        asks: const [OrderBookLevel(price: 101.0, amount: 1.0)],
        timestamp: DateTime(2026, 6, 21, 12),
      );
      final newOrderBook = OrderBook(
        bids: const [OrderBookLevel(price: 199.0, amount: 2.0)],
        asks: const [OrderBookLevel(price: 201.0, amount: 2.0)],
        timestamp: DateTime(2026, 6, 21, 13),
      );
      await cache.saveOrderBook(symbol, oldOrderBook);
      await cache.saveOrderBook(symbol, newOrderBook);
      final retrieved = await cache.getOrderBook(symbol);
      expect(retrieved, isNotNull);
      expect(retrieved!.bids, newOrderBook.bids);
      expect(retrieved.asks, newOrderBook.asks);
      expect(retrieved.timestamp, newOrderBook.timestamp);
    });

    test('duplicate save updates trades', () async {
      final oldTrades = [
        Trade(
          price: 100.0,
          amount: 1.0,
          side: TradeSide.buy,
          timestamp: DateTime(2026, 6, 21, 12),
          tradeId: 't1',
        ),
      ];
      final newTrades = [
        Trade(
          price: 200.0,
          amount: 2.0,
          side: TradeSide.sell,
          timestamp: DateTime(2026, 6, 21, 13),
          tradeId: 't2',
        ),
      ];
      await cache.saveTrades(symbol, oldTrades);
      await cache.saveTrades(symbol, newTrades);
      final retrieved = await cache.getTrades(symbol);
      expect(retrieved, newTrades);
    });

    test('returns null when order book JSON is malformed', () async {
      await database
          .into(database.cachedOrderBooks)
          .insert(
            CachedOrderBooksCompanion.insert(
              symbolId: symbol.id,
              bidsJson: 'not-json',
              asksJson: 'not-json',
              timestamp: DateTime(2026, 6, 21, 12),
            ),
          );
      final retrieved = await cache.getOrderBook(symbol);
      expect(retrieved, isNull);
    });

    test('returns null when trades JSON is malformed', () async {
      await database
          .into(database.cachedTrades)
          .insert(
            CachedTradesCompanion.insert(
              symbolId: symbol.id,
              tradesJson: 'not-json',
              timestamp: DateTime(2026, 6, 21, 12),
            ),
          );
      final retrieved = await cache.getTrades(symbol);
      expect(retrieved, isNull);
    });

    test('returns null when order book JSON is missing fields', () async {
      await database
          .into(database.cachedOrderBooks)
          .insert(
            CachedOrderBooksCompanion.insert(
              symbolId: symbol.id,
              bidsJson: '[{"amount":1.0}]',
              asksJson: '[{"price":101.0}]',
              timestamp: DateTime(2026, 6, 21, 12),
            ),
          );
      final retrieved = await cache.getOrderBook(symbol);
      expect(retrieved, isNull);
    });

    test('returns null when trade side is unknown', () async {
      await database
          .into(database.cachedTrades)
          .insert(
            CachedTradesCompanion.insert(
              symbolId: symbol.id,
              tradesJson:
                  '[{"price":100.0,"amount":1.0,"side":"invalid","timestamp":"2026-06-21T12:00:00.000Z","tradeId":"t1"}]',
              timestamp: DateTime(2026, 6, 21, 12),
            ),
          );
      final retrieved = await cache.getTrades(symbol);
      expect(retrieved, isNull);
    });
  });
}
