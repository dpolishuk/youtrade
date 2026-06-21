import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/local/app_database.dart';
import '../../data/datasources/local/market_cache_data_source.dart';
import '../../data/datasources/remote/binance/binance_rest_client.dart';
import '../../data/datasources/remote/binance/binance_websocket_client.dart';
import '../../data/datasources/remote/bybit/bybit_rest_client.dart';
import '../../data/datasources/remote/bybit/bybit_websocket_client.dart';
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

final marketDataRepositoryProvider = Provider<MarketDataRepository>((ref) {
  final connectivityAsync = ref.watch(connectivityProvider);
  final isOnline = connectivityAsync.valueOrNull ?? true;

  final database = ref.watch(appDatabaseProvider);
  final cache = MarketCacheDataSource(database: database);

  final binanceRest = BinanceRestClient();
  final bybitRest = BybitRestClient();

  return MarketDataRepositoryImpl(
    registry: const _StaticExchangeCapabilityRegistry(),
    isOnline: isOnline,
    cache: cache,
    venueSources: {
      Venue.binance: VenueSources(
        ticker: binanceRest,
        candles: binanceRest,
        orderBook: binanceRest,
        trades: binanceRest,
        stream: BinanceWebSocketClient(),
      ),
      Venue.bybit: VenueSources(
        ticker: bybitRest,
        candles: bybitRest,
        orderBook: bybitRest,
        trades: bybitRest,
        stream: BybitWebSocketClient(),
      ),
    },
  );
});
