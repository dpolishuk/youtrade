import 'dart:async';

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
import '../../domain/sources/market_cache.dart';
import '../../domain/sources/market_stream_source.dart';
import '../../domain/sources/order_book_source.dart';
import '../../domain/sources/ticker_source.dart';
import '../../domain/sources/trade_source.dart';
import '../../domain/sources/market_data_store.dart';
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
    required this.registry,
    MarketDataStore? mockStore,
    Map<Venue, VenueSources>? venueSources,
    this.cache,
    this.isOnline = true,
  }) : _mockStore = mockStore ?? MockMarketDataStore(),
       _venueSources = venueSources ?? const {};

  final ExchangeCapabilityRegistry registry;
  final MarketDataStore _mockStore;
  final Map<Venue, VenueSources> _venueSources;
  final MarketCache? cache;
  bool isOnline;

  static const _tickerTtl = Duration(seconds: 30);
  static const _candlesTtl = Duration(minutes: 5);
  static const _orderBookTtl = Duration(seconds: 30);
  static const _tradesTtl = Duration(minutes: 1);

  bool _isFresh(DateTime timestamp, Duration ttl) {
    return DateTime.now().toUtc().difference(timestamp) <= ttl;
  }

  Future<void> _refreshInBackground<T>(
    Future<Result<T>> Function() fetch,
    Future<T?> Function() getCached,
    Future<void> Function(T value) save, {
    required bool isOnline,
    bool Function(T fetched, T cached)? isNewer,
  }) async {
    if (!isOnline) return;
    try {
      final result = await fetch();
      if (result is Success<T>) {
        final cached = await getCached();
        if (cached != null &&
            isNewer != null &&
            !isNewer(result.value, cached)) {
          return;
        }
        await save(result.value);
      }
    } on Exception {
      // Background refresh failures are not surfaced to callers.
    }
  }

  Future<Result<T>> _fetchWithCache<T>({
    required String errorContext,
    required VenueSources? sources,
    required bool isOnline,
    required Future<T?> Function() getCached,
    required bool Function(T cached) isFresh,
    required Future<Result<T>> Function() fetchFromSource,
    required Future<void> Function(T value) saveToCache,
    required Future<T> Function() fetchMock,
    bool Function(T fetched, T cached)? isNewer,
  }) async {
    final cached = await getCached();

    if (sources == null || !isOnline) {
      if (cached != null) return Success(cached);
      try {
        return Success(await fetchMock());
      } on Exception catch (e) {
        return Err(UnknownFailure('mock fallback failed', error: e));
      }
    }

    if (cached != null && isFresh(cached)) {
      unawaited(
        _refreshInBackground(
          fetchFromSource,
          getCached,
          saveToCache,
          isOnline: isOnline,
          isNewer: isNewer,
        ),
      );
      return Success(cached);
    }

    try {
      final result = await fetchFromSource();
      if (result is Success<T>) {
        await saveToCache(result.value);
        return result;
      }

      if (cached != null) return Success(cached);

      if (result is Err<T> && result.failure is NetworkFailure) {
        try {
          return Success(await fetchMock());
        } on Exception catch (e) {
          return Err(UnknownFailure('mock fallback failed', error: e));
        }
      }

      return result;
    } on Exception catch (e) {
      return Err(UnknownFailure('$errorContext source failed: $e', error: e));
    }
  }

  @override
  Future<Result<Ticker>> getTicker(TradingSymbol symbol) async {
    final capability = registry.forVenue(symbol.venue);
    if (capability == null ||
        !capability.supports(MarketDataFeature.restTicker)) {
      return Err(
        UnsupportedFeatureFailure(symbol.venue.displayName, 'REST ticker'),
      );
    }
    final sources = _venueSources[symbol.venue];
    final isOnline = this.isOnline;
    return _fetchWithCache(
      errorContext: '${symbol.venue.displayName} REST ticker',
      sources: sources,
      isOnline: isOnline,
      getCached: () async => cache?.getTicker(symbol),
      isFresh: (ticker) => _isFresh(ticker.timestamp, _tickerTtl),
      fetchFromSource: () => sources!.ticker.fetchTicker(symbol),
      saveToCache: (ticker) async {
        await cache?.saveTicker(ticker);
      },
      fetchMock: () => _mockStore.getTicker(symbol),
      isNewer: (fetched, cached) => fetched.timestamp.isAfter(cached.timestamp),
    );
  }

  @override
  Future<Result<List<Candle>>> getCandles(
    TradingSymbol symbol,
    Timeframe timeframe, {
    int? limit,
  }) async {
    final capability = registry.forVenue(symbol.venue);
    if (capability == null ||
        !capability.supports(MarketDataFeature.restCandles)) {
      return Err(
        UnsupportedFeatureFailure(symbol.venue.displayName, 'REST candles'),
      );
    }
    final sources = _venueSources[symbol.venue];
    final isOnline = this.isOnline;
    return _fetchWithCache(
      errorContext: '${symbol.venue.displayName} REST candles',
      sources: sources,
      isOnline: isOnline,
      getCached: () async {
        final candles =
            await cache?.getCandles(symbol, timeframe, limit: limit) ?? [];
        return candles.isNotEmpty ? candles : null;
      },
      isFresh: (candles) =>
          candles.isNotEmpty && _isFresh(candles.last.timestamp, _candlesTtl),
      fetchFromSource: () async {
        final result = await sources!.candles.fetchCandles(
          symbol,
          timeframe,
          limit: limit,
        );
        if (result is Success<List<Candle>>) {
          final sorted = [...result.value]
            ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
          return Success(sorted);
        }
        return result;
      },
      saveToCache: (candles) async {
        await cache?.saveCandles(symbol, timeframe, candles);
      },
      fetchMock: () => _mockStore.getCandles(symbol, timeframe, limit: limit),
      isNewer: (fetched, cached) {
        if (fetched.isEmpty || cached.isEmpty) return true;
        return fetched.last.timestamp.isAfter(cached.last.timestamp);
      },
    );
  }

  @override
  Future<Result<OrderBook>> getOrderBook(
    TradingSymbol symbol, {
    int? depth,
  }) async {
    final capability = registry.forVenue(symbol.venue);
    if (capability == null ||
        !capability.supports(MarketDataFeature.restOrderBook)) {
      return Err(
        UnsupportedFeatureFailure(symbol.venue.displayName, 'REST order book'),
      );
    }
    final sources = _venueSources[symbol.venue];
    final isOnline = this.isOnline;
    return _fetchWithCache(
      errorContext: '${symbol.venue.displayName} REST order book',
      sources: sources,
      isOnline: isOnline,
      getCached: () async => cache?.getOrderBook(symbol),
      isFresh: (orderBook) => _isFresh(orderBook.timestamp, _orderBookTtl),
      fetchFromSource: () =>
          sources!.orderBook.fetchOrderBook(symbol, depth: depth),
      saveToCache: (orderBook) async {
        await cache?.saveOrderBook(symbol, orderBook);
      },
      fetchMock: () => _mockStore.getOrderBook(symbol, depth: depth),
      isNewer: (fetched, cached) => fetched.timestamp.isAfter(cached.timestamp),
    );
  }

  @override
  Future<Result<List<Trade>>> getTrades(
    TradingSymbol symbol, {
    int? limit,
  }) async {
    final capability = registry.forVenue(symbol.venue);
    if (capability == null ||
        !capability.supports(MarketDataFeature.restTrades)) {
      return Err(
        UnsupportedFeatureFailure(symbol.venue.displayName, 'REST trades'),
      );
    }
    final sources = _venueSources[symbol.venue];
    final isOnline = this.isOnline;
    return _fetchWithCache(
      errorContext: '${symbol.venue.displayName} REST trades',
      sources: sources,
      isOnline: isOnline,
      getCached: () async => cache?.getTrades(symbol),
      isFresh: (trades) {
        if (trades.isEmpty) return false;
        final newest = trades.reduce(
          (a, b) => a.timestamp.isAfter(b.timestamp) ? a : b,
        );
        return _isFresh(newest.timestamp, _tradesTtl);
      },
      fetchFromSource: () => sources!.trades.fetchTrades(symbol, limit: limit),
      saveToCache: (trades) async {
        await cache?.saveTrades(symbol, trades);
      },
      fetchMock: () => _mockStore.getTrades(symbol, limit: limit),
      isNewer: (fetched, cached) {
        if (fetched.isEmpty) return false;
        final fetchedNewest = fetched.reduce(
          (a, b) => a.timestamp.isAfter(b.timestamp) ? a : b,
        );
        if (cached.isEmpty) return true;
        final cachedNewest = cached.reduce(
          (a, b) => a.timestamp.isAfter(b.timestamp) ? a : b,
        );
        return fetchedNewest.timestamp.isAfter(cachedNewest.timestamp);
      },
    );
  }

  @override
  Stream<Result<Ticker>> watchTicker(TradingSymbol symbol) async* {
    final capability = registry.forVenue(symbol.venue);
    if (capability == null ||
        !capability.supports(MarketDataFeature.wsTicker)) {
      yield Err(
        UnsupportedFeatureFailure(symbol.venue.displayName, 'WS ticker'),
      );
      return;
    }

    final cached = await cache?.getTicker(symbol);
    if (cached != null) {
      yield Success(cached);
    }

    final isOnline = this.isOnline;
    if (!isOnline) {
      await for (final ticker in _mockStore.watchTicker(symbol)) {
        yield Success(ticker);
      }
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
    final capability = registry.forVenue(symbol.venue);
    if (capability == null ||
        !capability.supports(MarketDataFeature.wsOrderBook)) {
      yield Err(
        UnsupportedFeatureFailure(symbol.venue.displayName, 'WS order book'),
      );
      return;
    }

    final cached = await cache?.getOrderBook(symbol);
    if (cached != null) {
      yield Success(cached);
    }

    final isOnline = this.isOnline;
    if (!isOnline) {
      await for (final orderBook in _mockStore.watchOrderBook(symbol)) {
        yield Success(orderBook);
      }
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
    final capability = registry.forVenue(symbol.venue);
    if (capability == null ||
        !capability.supports(MarketDataFeature.wsTrades)) {
      yield Err(
        UnsupportedFeatureFailure(symbol.venue.displayName, 'WS trades'),
      );
      return;
    }

    final cached = await cache?.getTrades(symbol);
    if (cached != null) {
      yield Success(cached);
    }

    final isOnline = this.isOnline;
    if (!isOnline) {
      await for (final trades in _mockStore.watchTrades(symbol)) {
        yield Success(trades);
      }
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
