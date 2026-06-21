import '../../core/failures.dart';
import '../../core/result.dart';
import '../../domain/entities/candle.dart';
import '../../domain/entities/order_book.dart';
import '../../domain/entities/symbol.dart';
import '../../domain/entities/ticker.dart';
import '../../domain/entities/timeframe.dart';
import '../../domain/entities/trade.dart';
import '../../domain/registry/exchange_capability.dart';
import '../../domain/repositories/market_data_repository.dart';
import '../datasources/mock/mock_market_data_store.dart';

final class MarketDataRepositoryImpl implements MarketDataRepository {
  MarketDataRepositoryImpl({
    required this._registry,
    MockMarketDataStore? mockStore,
  }) : _mockStore = mockStore ?? MockMarketDataStore();

  final ExchangeCapabilityRegistry _registry;
  final MockMarketDataStore _mockStore;

  @override
  Future<Result<Ticker>> getTicker(TradingSymbol symbol) async {
    final capability = _registry.forVenue(symbol.venue);
    if (capability == null ||
        !capability.supports(MarketDataFeature.restTicker)) {
      return Err(UnsupportedFeatureFailure('offline', 'REST ticker'));
    }
    try {
      return Success(await _mockStore.getTicker(symbol));
    } on Exception catch (e) {
      return Err(UnknownFailure('mock ticker failed', error: e));
    }
  }

  @override
  Future<Result<List<Candle>>> getCandles(
    TradingSymbol symbol,
    Timeframe timeframe, {
    int? limit,
  }) async {
    final capability = _registry.forVenue(symbol.venue);
    if (capability == null ||
        !capability.supports(MarketDataFeature.restCandles)) {
      return Err(UnsupportedFeatureFailure('offline', 'REST candles'));
    }
    try {
      return Success(
        await _mockStore.getCandles(symbol, timeframe, limit: limit),
      );
    } on Exception catch (e) {
      return Err(UnknownFailure('mock candles failed', error: e));
    }
  }

  @override
  Future<Result<OrderBook>> getOrderBook(
    TradingSymbol symbol, {
    int? depth,
  }) async {
    final capability = _registry.forVenue(symbol.venue);
    if (capability == null ||
        !capability.supports(MarketDataFeature.restOrderBook)) {
      return Err(UnsupportedFeatureFailure('offline', 'REST order book'));
    }
    try {
      return Success(await _mockStore.getOrderBook(symbol, depth: depth));
    } on Exception catch (e) {
      return Err(UnknownFailure('mock order book failed', error: e));
    }
  }

  @override
  Future<Result<List<Trade>>> getTrades(
    TradingSymbol symbol, {
    int? limit,
  }) async {
    final capability = _registry.forVenue(symbol.venue);
    if (capability == null ||
        !capability.supports(MarketDataFeature.restTrades)) {
      return Err(UnsupportedFeatureFailure('offline', 'REST trades'));
    }
    try {
      return Success(await _mockStore.getTrades(symbol, limit: limit));
    } on Exception catch (e) {
      return Err(UnknownFailure('mock trades failed', error: e));
    }
  }

  @override
  Stream<Result<Ticker>> watchTicker(TradingSymbol symbol) async* {
    final capability = _registry.forVenue(symbol.venue);
    if (capability == null ||
        !capability.supports(MarketDataFeature.wsTicker)) {
      yield Err(UnsupportedFeatureFailure('offline', 'WS ticker'));
      return;
    }
    await for (final ticker in _mockStore.watchTicker(symbol)) {
      yield Success(ticker);
    }
  }

  @override
  Stream<Result<OrderBook>> watchOrderBook(TradingSymbol symbol) async* {
    final capability = _registry.forVenue(symbol.venue);
    if (capability == null ||
        !capability.supports(MarketDataFeature.wsOrderBook)) {
      yield Err(UnsupportedFeatureFailure('offline', 'WS order book'));
      return;
    }
    await for (final orderBook in _mockStore.watchOrderBook(symbol)) {
      yield Success(orderBook);
    }
  }

  @override
  Stream<Result<List<Trade>>> watchTrades(TradingSymbol symbol) async* {
    final capability = _registry.forVenue(symbol.venue);
    if (capability == null ||
        !capability.supports(MarketDataFeature.wsTrades)) {
      yield Err(UnsupportedFeatureFailure('offline', 'WS trades'));
      return;
    }
    await for (final trades in _mockStore.watchTrades(symbol)) {
      yield Success(trades);
    }
  }
}
