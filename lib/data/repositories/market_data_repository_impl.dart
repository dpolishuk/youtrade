import '../../core/failures.dart';
import '../../core/result.dart';
import '../../domain/entities/candle.dart';
import '../../domain/entities/order_book.dart';
import '../../domain/entities/symbol.dart';
import '../../domain/entities/ticker.dart';
import '../../domain/entities/timeframe.dart';
import '../../domain/entities/trade.dart';
import '../../domain/entities/venue.dart';
import '../../domain/registry/exchange_capability.dart';
import '../../domain/repositories/market_data_repository.dart';
import '../../domain/sources/candle_source.dart';
import '../../domain/sources/market_stream_source.dart';
import '../../domain/sources/order_book_source.dart';
import '../../domain/sources/ticker_source.dart';
import '../../domain/sources/trade_source.dart';
import '../datasources/mock/mock_market_data_store.dart';

final class VenueSources {
  const VenueSources({
    required this.ticker,
    required this.candles,
    required this.orderBook,
    required this.trades,
    required this.stream,
  });

  final TickerSource ticker;
  final CandleSource candles;
  final OrderBookSource orderBook;
  final TradeSource trades;
  final MarketStreamSource stream;
}

final class MarketDataRepositoryImpl implements MarketDataRepository {
  MarketDataRepositoryImpl({
    required this._registry,
    MockMarketDataStore? mockStore,
    Map<Venue, VenueSources>? venueSources,
  }) : _mockStore = mockStore ?? MockMarketDataStore(),
       _venueSources = venueSources ?? const {};

  final ExchangeCapabilityRegistry _registry;
  final MockMarketDataStore _mockStore;
  final Map<Venue, VenueSources> _venueSources;

  @override
  Future<Result<Ticker>> getTicker(TradingSymbol symbol) async {
    final capability = _registry.forVenue(symbol.venue);
    if (capability == null ||
        !capability.supports(MarketDataFeature.restTicker)) {
      return Err(
        UnsupportedFeatureFailure(symbol.venue.displayName, 'REST ticker'),
      );
    }
    final sources = _venueSources[symbol.venue];
    if (sources != null) {
      return sources.ticker.fetchTicker(symbol);
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
      return Err(
        UnsupportedFeatureFailure(symbol.venue.displayName, 'REST candles'),
      );
    }
    final sources = _venueSources[symbol.venue];
    if (sources != null) {
      return sources.candles.fetchCandles(symbol, timeframe, limit: limit);
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
      return Err(
        UnsupportedFeatureFailure(symbol.venue.displayName, 'REST order book'),
      );
    }
    final sources = _venueSources[symbol.venue];
    if (sources != null) {
      return sources.orderBook.fetchOrderBook(symbol, depth: depth);
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
      return Err(
        UnsupportedFeatureFailure(symbol.venue.displayName, 'REST trades'),
      );
    }
    final sources = _venueSources[symbol.venue];
    if (sources != null) {
      return sources.trades.fetchTrades(symbol, limit: limit);
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
      yield Err(
        UnsupportedFeatureFailure(symbol.venue.displayName, 'WS ticker'),
      );
      return;
    }
    final sources = _venueSources[symbol.venue];
    if (sources != null) {
      yield* sources.stream.watchTicker(symbol);
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
      yield Err(
        UnsupportedFeatureFailure(symbol.venue.displayName, 'WS order book'),
      );
      return;
    }
    final sources = _venueSources[symbol.venue];
    if (sources != null) {
      yield* sources.stream.watchOrderBook(symbol);
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
      yield Err(
        UnsupportedFeatureFailure(symbol.venue.displayName, 'WS trades'),
      );
      return;
    }
    final sources = _venueSources[symbol.venue];
    if (sources != null) {
      yield* sources.stream.watchTrades(symbol);
      return;
    }
    await for (final trades in _mockStore.watchTrades(symbol)) {
      yield Success(trades);
    }
  }
}
