import '../../core/result.dart';
import '../entities/candle.dart';
import '../entities/symbol.dart';
import '../entities/timeframe.dart';

abstract interface class CandleSource {
  Future<Result<List<Candle>>> fetchCandles(
    TradingSymbol symbol,
    Timeframe timeframe, {
    int? limit,
  });
}
