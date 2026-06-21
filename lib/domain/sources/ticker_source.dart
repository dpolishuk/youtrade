import '../../core/result.dart';
import '../entities/symbol.dart';
import '../entities/ticker.dart';

abstract interface class TickerSource {
  Future<Result<Ticker>> fetchTicker(TradingSymbol symbol);
}
