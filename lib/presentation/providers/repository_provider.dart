import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/local/app_database.dart';
import '../../data/datasources/local/market_cache_data_source.dart';
import '../../data/datasources/mock/deterministic_market_data_store.dart';
import '../../data/datasources/remote/binance/binance_rest_client.dart';
import '../../data/datasources/remote/binance/binance_websocket_client.dart';
import '../../data/datasources/remote/bybit/bybit_rest_client.dart';
import '../../data/datasources/remote/bybit/bybit_websocket_client.dart';
import '../../data/datasources/remote/coinbase/coinbase_rest_client.dart';
import '../../data/datasources/remote/coinbase/coinbase_websocket_client.dart';
import '../../data/datasources/remote/okx/okx_rest_client.dart';
import '../../data/datasources/remote/okx/okx_websocket_client.dart';
import '../../data/repositories/market_data_repository_impl.dart';
import '../../domain/entities/symbol.dart';
import '../../domain/entities/venue.dart';
import '../../domain/registry/exchange_capability.dart';
import '../../domain/repositories/market_data_repository.dart';
import 'connectivity_provider.dart';

const _allMarketDataFeatures = <MarketDataFeature>{
  MarketDataFeature.restTicker,
  MarketDataFeature.restCandles,
  MarketDataFeature.restOrderBook,
  MarketDataFeature.restTrades,
  MarketDataFeature.wsTicker,
  MarketDataFeature.wsOrderBook,
  MarketDataFeature.wsTrades,
};

final class _StaticExchangeCapabilityRegistry
    implements ExchangeCapabilityRegistry {
  const _StaticExchangeCapabilityRegistry();

  static final List<ExchangeCapability> _capabilities = [
    const ExchangeCapability(
      venue: Venue.binance,
      supportedFeatures: _allMarketDataFeatures,
    ),
    const ExchangeCapability(
      venue: Venue.bybit,
      supportedFeatures: _allMarketDataFeatures,
    ),
    const ExchangeCapability(
      venue: Venue.okx,
      supportedFeatures: _allMarketDataFeatures,
    ),
    const ExchangeCapability(
      venue: Venue.coinbase,
      supportedFeatures: _allMarketDataFeatures,
    ),
  ];

  /// Symbols that should always use deterministic mock data because they are
  /// mockup-only assets (stocks, commodities) and not supported by the live
  /// exchange products used in this demo.
  static const _mockOnlySymbols = {'AAPL', 'NVDA', 'TSLA', 'GC=F', 'CL=F'};

  @override
  List<ExchangeCapability> get all => _capabilities;

  @override
  ExchangeCapability? forVenue(Venue venue) {
    try {
      return _capabilities.firstWhere((c) => c.venue == venue);
    } on StateError {
      return null;
    }
  }

  @override
  bool isSymbolSupported(TradingSymbol symbol) =>
      !_mockOnlySymbols.contains(symbol.rawSymbol);
}

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

final exchangeCapabilityRegistryProvider = Provider<ExchangeCapabilityRegistry>(
  (ref) => const _StaticExchangeCapabilityRegistry(),
);

final _binanceRestClientProvider = Provider<BinanceRestClient>((ref) {
  final client = BinanceRestClient();
  ref.onDispose(client.close);
  return client;
});

final _bybitRestClientProvider = Provider<BybitRestClient>((ref) {
  final client = BybitRestClient();
  ref.onDispose(client.close);
  return client;
});

final _okxRestClientProvider = Provider<OKXRestClient>((ref) {
  final client = OKXRestClient();
  ref.onDispose(client.close);
  return client;
});

final _coinbaseRestClientProvider = Provider<CoinbaseRestClient>((ref) {
  final client = CoinbaseRestClient();
  ref.onDispose(client.close);
  return client;
});

final binanceWebSocketClientProvider = Provider<BinanceWebSocketClient>((ref) {
  final client = BinanceWebSocketClient();
  ref.onDispose(client.closeAll);
  return client;
});

final bybitWebSocketClientProvider = Provider<BybitWebSocketClient>((ref) {
  final client = BybitWebSocketClient();
  ref.onDispose(client.closeAll);
  return client;
});

final okxWebSocketClientProvider = Provider<OKXWebSocketClient>((ref) {
  final client = OKXWebSocketClient();
  ref.onDispose(client.closeAll);
  return client;
});

final coinbaseWebSocketClientProvider = Provider<CoinbaseWebSocketClient>((
  ref,
) {
  final client = CoinbaseWebSocketClient();
  ref.onDispose(client.closeAll);
  return client;
});

final marketDataRepositoryProvider = Provider<MarketDataRepository>((ref) {
  final database = ref.watch(appDatabaseProvider);
  final cache = MarketCacheDataSource(database: database);

  final binanceRest = ref.watch(_binanceRestClientProvider);
  final bybitRest = ref.watch(_bybitRestClientProvider);
  final okxRest = ref.watch(_okxRestClientProvider);
  final coinbaseRest = ref.watch(_coinbaseRestClientProvider);

  // Keep websocket clients alive across connectivity changes by watching them
  // unconditionally. The provider passes an empty venueSources map when offline
  // so the repository uses the fallback store instead of real-time streams.
  final binanceWs = ref.watch(binanceWebSocketClientProvider);
  final bybitWs = ref.watch(bybitWebSocketClientProvider);
  final okxWs = ref.watch(okxWebSocketClientProvider);
  final coinbaseWs = ref.watch(coinbaseWebSocketClientProvider);

  final isOnline = ref.watch(connectivityProvider).valueOrNull ?? true;

  return MarketDataRepositoryImpl(
    registry: const _StaticExchangeCapabilityRegistry(),
    fallbackStore: const DeterministicMarketDataStore(),
    cache: cache,
    venueSources: isOnline
        ? {
            Venue.binance: VenueSources(
              ticker: binanceRest,
              candles: binanceRest,
              orderBook: binanceRest,
              trades: binanceRest,
              stream: binanceWs,
            ),
            Venue.bybit: VenueSources(
              ticker: bybitRest,
              candles: bybitRest,
              orderBook: bybitRest,
              trades: bybitRest,
              stream: bybitWs,
            ),
            Venue.okx: VenueSources(
              ticker: okxRest,
              candles: okxRest,
              orderBook: okxRest,
              trades: okxRest,
              stream: okxWs,
            ),
            Venue.coinbase: VenueSources(
              ticker: coinbaseRest,
              candles: coinbaseRest,
              orderBook: coinbaseRest,
              trades: coinbaseRest,
              stream: coinbaseWs,
            ),
          }
        : const {},
  );
});
