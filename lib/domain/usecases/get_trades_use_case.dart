import '../../core/result.dart';
import '../entities/symbol.dart';
import '../entities/trade.dart';
import '../repositories/market_data_repository.dart';

final class GetTradesUseCase {
  const GetTradesUseCase(this._repository);

  final MarketDataRepository _repository;

  Future<Result<List<Trade>>> call(TradingSymbol symbol, {int? limit}) =>
      _repository.getTrades(symbol, limit: limit);
}
