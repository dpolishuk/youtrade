import '../../core/result.dart';
import '../entities/order_book.dart';
import '../entities/symbol.dart';
import '../repositories/market_data_repository.dart';

final class WatchOrderBookUseCase {
  const WatchOrderBookUseCase(this._repository);

  final MarketDataRepository _repository;

  Stream<Result<OrderBook>> call(TradingSymbol symbol) =>
      _repository.watchOrderBook(symbol);
}
