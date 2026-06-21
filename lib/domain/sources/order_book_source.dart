import '../../core/result.dart';
import '../entities/order_book.dart';
import '../entities/symbol.dart';

abstract interface class OrderBookSource {
  Future<Result<OrderBook>> fetchOrderBook(TradingSymbol symbol, {int? depth});
}
