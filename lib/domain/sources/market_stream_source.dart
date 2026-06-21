import '../../core/result.dart';
import '../entities/order_book.dart';
import '../entities/symbol.dart';
import '../entities/ticker.dart';
import '../entities/trade.dart';

abstract interface class MarketStreamSource {
  Stream<Result<Ticker>> watchTicker(TradingSymbol symbol);

  Stream<Result<OrderBook>> watchOrderBook(TradingSymbol symbol);

  Stream<Result<List<Trade>>> watchTrades(TradingSymbol symbol);
}
