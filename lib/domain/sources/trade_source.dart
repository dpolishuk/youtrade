import '../../core/result.dart';
import '../entities/symbol.dart';
import '../entities/trade.dart';

abstract interface class TradeSource {
  Future<Result<List<Trade>>> fetchTrades(TradingSymbol symbol, {int? limit});
}
