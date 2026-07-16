import '../../core/result.dart';
import '../entities/symbol.dart';
import '../entities/ticker.dart';
import '../repositories/market_data_repository.dart';

final class GetTickerUseCase {
  const GetTickerUseCase(this._repository);

  final MarketDataRepository _repository;

  Future<Result<Ticker>> call(TradingSymbol symbol) =>
      _repository.getTicker(symbol);
}
