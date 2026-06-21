import '../../core/result.dart';
import '../entities/symbol.dart';
import '../entities/trade.dart';
import '../repositories/market_data_repository.dart';

final class WatchTradesUseCase {
  const WatchTradesUseCase(this._repository);

  final MarketDataRepository _repository;

  Stream<Result<List<Trade>>> call(TradingSymbol symbol) =>
      _repository.watchTrades(symbol);
}
