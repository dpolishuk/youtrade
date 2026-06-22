import 'dart:async';

import '../entities/candle.dart';
import '../entities/order_book.dart';
import '../entities/symbol.dart';
import '../entities/ticker.dart';
import '../entities/timeframe.dart';
import '../entities/trade.dart';

/// Synchronous-style store for deterministic or seeded mock market data.
///
/// Implementations must return the same values for the same inputs so tests
/// and UI screenshots are stable.
abstract interface class MarketDataStore {
  Future<Ticker> getTicker(TradingSymbol symbol);

  Future<List<Candle>> getCandles(
    TradingSymbol symbol,
    Timeframe timeframe, {
    int? limit,
  });

  Future<OrderBook> getOrderBook(TradingSymbol symbol, {int? depth});

  Future<List<Trade>> getTrades(TradingSymbol symbol, {int? limit});

  Stream<Ticker> watchTicker(TradingSymbol symbol);

  Stream<OrderBook> watchOrderBook(TradingSymbol symbol);

  Stream<List<Trade>> watchTrades(TradingSymbol symbol);
}
