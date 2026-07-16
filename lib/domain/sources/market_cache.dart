import '../entities/candle.dart';
import '../entities/order_book.dart';
import '../entities/symbol.dart';
import '../entities/ticker.dart';
import '../entities/timeframe.dart';
import '../entities/trade.dart';

abstract interface class MarketCache {
  Future<void> saveTicker(Ticker ticker);

  Future<Ticker?> getTicker(TradingSymbol symbol);

  Future<void> saveCandles(
    TradingSymbol symbol,
    Timeframe timeframe,
    List<Candle> candles,
  );

  Future<List<Candle>> getCandles(
    TradingSymbol symbol,
    Timeframe timeframe, {
    int? limit,
  });

  Future<void> saveOrderBook(TradingSymbol symbol, OrderBook orderBook);

  Future<OrderBook?> getOrderBook(TradingSymbol symbol);

  Future<void> saveTrades(TradingSymbol symbol, List<Trade> trades);

  Future<List<Trade>?> getTrades(TradingSymbol symbol);
}
