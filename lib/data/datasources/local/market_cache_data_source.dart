import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../domain/entities/candle.dart';
import '../../../domain/entities/order_book.dart';
import '../../../domain/entities/symbol.dart';
import '../../../domain/entities/ticker.dart';
import '../../../domain/entities/timeframe.dart';
import '../../../domain/entities/trade.dart';
import '../../../domain/sources/market_cache.dart';
import 'app_database.dart';

final class MarketCacheDataSource implements MarketCache {
  MarketCacheDataSource({required this._database});

  final AppDatabase _database;

  @override
  Future<void> saveTicker(Ticker ticker) async {
    await _database.cachedTickers.insertOnConflictUpdate(
      CachedTickersCompanion.insert(
        symbolId: ticker.symbol.id,
        lastPrice: ticker.lastPrice,
        bid: ticker.bid,
        ask: ticker.ask,
        change24h: ticker.change24h,
        change24hPercent: ticker.change24hPercent,
        volume: ticker.volume,
        timestamp: ticker.timestamp,
      ),
    );
  }

  @override
  Future<Ticker?> getTicker(TradingSymbol symbol) async {
    final row =
        await (_database.cachedTickers.select()
              ..where((t) => t.symbolId.equals(symbol.id)))
            .getSingleOrNull();
    if (row == null) return null;
    return Ticker(
      symbol: symbol,
      lastPrice: row.lastPrice,
      bid: row.bid,
      ask: row.ask,
      change24h: row.change24h,
      change24hPercent: row.change24hPercent,
      volume: row.volume,
      timestamp: row.timestamp,
    );
  }

  @override
  Future<void> saveCandles(
    TradingSymbol symbol,
    Timeframe timeframe,
    List<Candle> candles,
  ) async {
    await _database.batch((batch) {
      batch.insertAllOnConflictUpdate(
        _database.cachedCandles,
        candles
            .map(
              (c) => CachedCandlesCompanion.insert(
                symbolId: symbol.id,
                timeframeCode: timeframe.code,
                open: c.open,
                high: c.high,
                low: c.low,
                close: c.close,
                volume: c.volume,
                timestamp: c.timestamp,
              ),
            )
            .toList(),
      );
    });
  }

  @override
  Future<List<Candle>> getCandles(
    TradingSymbol symbol,
    Timeframe timeframe, {
    int? limit,
  }) async {
    final query = _database.cachedCandles.select()
      ..where(
        (c) =>
            c.symbolId.equals(symbol.id) &
            c.timeframeCode.equals(timeframe.code),
      )
      ..orderBy([
        (c) => OrderingTerm(expression: c.timestamp, mode: OrderingMode.desc),
      ]);
    if (limit != null) {
      query.limit(limit);
    }
    final rows = await query.get();
    return rows
        .map(
          (r) => Candle(
            open: r.open,
            high: r.high,
            low: r.low,
            close: r.close,
            volume: r.volume,
            timestamp: r.timestamp,
          ),
        )
        .toList()
        .reversed
        .toList();
  }

  @override
  Future<void> saveOrderBook(TradingSymbol symbol, OrderBook orderBook) async {
    final bids = orderBook.bids
        .map((l) => {'price': l.price, 'amount': l.amount})
        .toList();
    final asks = orderBook.asks
        .map((l) => {'price': l.price, 'amount': l.amount})
        .toList();
    await _database.cachedOrderBooks.insertOnConflictUpdate(
      CachedOrderBooksCompanion.insert(
        symbolId: symbol.id,
        bidsJson: jsonEncode(bids),
        asksJson: jsonEncode(asks),
        timestamp: orderBook.timestamp,
      ),
    );
  }

  @override
  Future<OrderBook?> getOrderBook(TradingSymbol symbol) async {
    final row =
        await (_database.cachedOrderBooks.select()
              ..where((o) => o.symbolId.equals(symbol.id)))
            .getSingleOrNull();
    if (row == null) return null;
    try {
      return OrderBook(
        bids: _decodeLevels(row.bidsJson),
        asks: _decodeLevels(row.asksJson),
        timestamp: row.timestamp,
      );
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    } on StateError {
      return null;
    }
  }

  @override
  Future<void> saveTrades(TradingSymbol symbol, List<Trade> trades) async {
    final payload = trades
        .map(
          (t) => {
            'price': t.price,
            'amount': t.amount,
            'side': t.side.name,
            'timestamp': t.timestamp.toIso8601String(),
            'tradeId': t.tradeId,
          },
        )
        .toList();
    final timestamp = trades.isEmpty
        ? DateTime.now().toUtc()
        : trades.map((t) => t.timestamp).reduce((a, b) => a.isAfter(b) ? a : b);
    await _database.cachedTrades.insertOnConflictUpdate(
      CachedTradesCompanion.insert(
        symbolId: symbol.id,
        tradesJson: jsonEncode(payload),
        timestamp: timestamp,
      ),
    );
  }

  @override
  Future<List<Trade>?> getTrades(TradingSymbol symbol) async {
    final row =
        await (_database.cachedTrades.select()
              ..where((t) => t.symbolId.equals(symbol.id)))
            .getSingleOrNull();
    if (row == null) return null;
    try {
      final decoded = jsonDecode(row.tradesJson) as List<dynamic>;
      return decoded.map(_decodeTrade).toList();
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    } on StateError {
      return null;
    } on ArgumentError {
      return null;
    }
  }

  List<OrderBookLevel> _decodeLevels(String json) {
    final decoded = jsonDecode(json) as List<dynamic>;
    return decoded
        .map(
          (l) => OrderBookLevel(
            price: (l['price'] as num).toDouble(),
            amount: (l['amount'] as num).toDouble(),
          ),
        )
        .toList();
  }

  Trade _decodeTrade(dynamic t) {
    final map = t as Map<String, dynamic>;
    return Trade(
      price: (map['price'] as num).toDouble(),
      amount: (map['amount'] as num).toDouble(),
      side: TradeSide.values.byName(map['side'] as String),
      timestamp: DateTime.parse(map['timestamp'] as String),
      tradeId: map['tradeId'] as String?,
    );
  }
}
