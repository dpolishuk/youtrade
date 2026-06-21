import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/local/app_database.dart';
import '../../data/datasources/local/market_cache_data_source.dart';
import '../../data/datasources/remote/binance/binance_rest_client.dart';
import '../../data/datasources/remote/binance/binance_websocket_client.dart';
import '../../data/datasources/remote/bybit/bybit_rest_client.dart';
import '../../data/datasources/remote/bybit/bybit_websocket_client.dart';
import '../../data/datasources/remote/coinbase/coinbase_rest_client.dart';
import '../../data/datasources/remote/coinbase/coinbase_websocket_client.dart';
import '../../data/datasources/remote/okx/okx_rest_client.dart';
import '../../data/datasources/remote/okx/okx_websocket_client.dart';
import '../../data/repositories/market_data_repository_impl.dart';
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
}

final appDatabaseProvider = Provider<AppDatabase>((ref) => AppDatabase());

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

final _binanceWebSocketClientProvider = Provider<BinanceWebSocketClient>(
  (ref) => BinanceWebSocketClient(),
);

final _bybitWebSocketClientProvider = Provider<BybitWebSocketClient>(
  (ref) => BybitWebSocketClient(),
);

final _okxWebSocketClientProvider = Provider<OKXWebSocketClient>(
  (ref) => OKXWebSocketClient(),
);

final _coinbaseWebSocketClientProvider = Provider<CoinbaseWebSocketClient>(
  (ref) => CoinbaseWebSocketClient(),
);

final marketDataRepositoryProvider = Provider<MarketDataRepository>((ref) {
  final database = ref.watch(appDatabaseProvider);
  final cache = MarketCacheDataSource(database: database);

  final binanceRest = ref.watch(_binanceRestClientProvider);
  final bybitRest = ref.watch(_bybitRestClientProvider);
  final okxRest = ref.watch(_okxRestClientProvider);
  final coinbaseRest = ref.watch(_coinbaseRestClientProvider);

  final repository = MarketDataRepositoryImpl(
    registry: const _StaticExchangeCapabilityRegistry(),
    isOnline: ref.read(connectivityProvider).valueOrNull ?? true,
    cache: cache,
    venueSources: {
      Venue.binance: VenueSources(
        ticker: binanceRest,
        candles: binanceRest,
        orderBook: binanceRest,
        trades: binanceRest,
        stream: ref.watch(_binanceWebSocketClientProvider),
      ),
      Venue.bybit: VenueSources(
        ticker: bybitRest,
        candles: bybitRest,
        orderBook: bybitRest,
        trades: bybitRest,
        stream: ref.watch(_bybitWebSocketClientProvider),
      ),
      Venue.okx: VenueSources(
        ticker: okxRest,
        candles: okxRest,
        orderBook: okxRest,
        trades: okxRest,
        stream: ref.watch(_okxWebSocketClientProvider),
      ),
      Venue.coinbase: VenueSources(
        ticker: coinbaseRest,
        candles: coinbaseRest,
        orderBook: coinbaseRest,
        trades: coinbaseRest,
        stream: ref.watch(_coinbaseWebSocketClientProvider),
      ),
    },
  );

  ref.listen(connectivityProvider, (_, next) {
    repository.isOnline = next.valueOrNull ?? true;
  });

  return repository;
});
