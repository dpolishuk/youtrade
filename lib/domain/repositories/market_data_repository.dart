import '../../core/result.dart';
import '../entities/candle.dart';
import '../entities/order_book.dart';
import '../entities/symbol.dart';
import '../entities/ticker.dart';
import '../entities/timeframe.dart';
import '../entities/trade.dart';

abstract interface class MarketDataRepository {
  Future<Result<Ticker>> getTicker(TradingSymbol symbol);

  Future<Result<List<Candle>>> getCandles(
    TradingSymbol symbol,
    Timeframe timeframe, {
    int? limit,
  });

  Future<Result<OrderBook>> getOrderBook(TradingSymbol symbol, {int? depth});

  Future<Result<List<Trade>>> getTrades(TradingSymbol symbol, {int? limit});

  Stream<Result<Ticker>> watchTicker(TradingSymbol symbol);

  Stream<Result<OrderBook>> watchOrderBook(TradingSymbol symbol);

  Stream<Result<List<Trade>>> watchTrades(TradingSymbol symbol);
}
