import '../../core/result.dart';
import '../entities/symbol.dart';
import '../entities/ticker.dart';
import '../repositories/market_data_repository.dart';

final class WatchTickerUseCase {
  const WatchTickerUseCase(this._repository);

  final MarketDataRepository _repository;

  Stream<Result<Ticker>> call(TradingSymbol symbol) =>
      _repository.watchTicker(symbol);
}
