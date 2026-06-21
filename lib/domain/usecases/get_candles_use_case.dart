import '../../core/result.dart';
import '../entities/candle.dart';
import '../entities/symbol.dart';
import '../entities/timeframe.dart';
import '../repositories/market_data_repository.dart';

final class GetCandlesUseCase {
  const GetCandlesUseCase(this._repository);

  final MarketDataRepository _repository;

  Future<Result<List<Candle>>> call(
    TradingSymbol symbol,
    Timeframe timeframe, {
    int? limit,
  }) => _repository.getCandles(symbol, timeframe, limit: limit);
}
