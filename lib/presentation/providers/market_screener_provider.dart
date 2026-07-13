import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/bybit_config.dart';
import '../../data/datasources/remote/bybit/bybit_rest_client.dart';
import '../../domain/entities/venue.dart';

enum MarketCategory {
  perp('Perpetuals'),
  spot('Spot');

  const MarketCategory(this.label);
  final String label;
}

enum AssetClass {
  perp('PERP', MarketCategory.perp),
  spot('SPOT', MarketCategory.spot);

  const AssetClass(this.badge, this.category);

  final String badge;
  final MarketCategory category;
}

final class MarketScreenerItem {
  const MarketScreenerItem({
    required this.symbol,
    required this.rawSymbol,
    required this.name,
    required this.venue,
    required this.assetClass,
    required this.price,
    required this.change24hPercent,
    required this.priceDecimals,
    this.volume24h = 0.0,
    this.sparkline = const [],
  });

  final String symbol;
  final String rawSymbol;
  final String name;
  final Venue venue;
  final AssetClass assetClass;
  final double price;
  final double change24hPercent;
  final int priceDecimals;
  final double volume24h;
  final List<double> sparkline;
}

/// Strips the trailing `USDT` quote suffix from a raw symbol for compact
/// display (e.g. `BTCUSDT` -> `BTC`).
String displaySymbol(String rawSymbol) {
  if (rawSymbol.endsWith('USDT')) {
    return rawSymbol.substring(0, rawSymbol.length - 4);
  }
  return rawSymbol;
}

/// Picks a sensible number of decimal places based on price magnitude.
int priceDecimals(double price) {
  if (price >= 10000) return 1;
  if (price >= 1) return 2;
  if (price >= 0.01) return 4;
  return 6;
}

/// Maps a raw Bybit ticker JSON map to a [MarketScreenerItem].
///
/// [assetClass] is determined by the API category the ticker came from:
/// `linear` -> [AssetClass.perp], `spot` -> [AssetClass.spot].
MarketScreenerItem tickerToScreenerItem(
  Map<String, dynamic> ticker,
  AssetClass assetClass,
) {
  final rawSymbol = ticker['symbol'] as String? ?? '';
  final lastPrice =
      double.tryParse(ticker['lastPrice'] as String? ?? '') ?? 0.0;
  final price24hPcnt =
      double.tryParse(ticker['price24hPcnt'] as String? ?? '') ?? 0.0;
  final volume24h =
      double.tryParse(ticker['volume24h'] as String? ?? '') ?? 0.0;
  return MarketScreenerItem(
    symbol: displaySymbol(rawSymbol),
    rawSymbol: rawSymbol,
    name: rawSymbol,
    venue: Venue.bybit,
    assetClass: assetClass,
    price: lastPrice,
    change24hPercent: price24hPcnt * 100,
    volume24h: volume24h,
    priceDecimals: priceDecimals(lastPrice),
  );
}

final marketScreenerSearchProvider = StateProvider<String>((ref) => '');

final marketScreenerFilterProvider = StateProvider<MarketCategory?>(
  (ref) => null,
);

/// Provides the [BybitRestClient] used by the screener. Override in tests to
/// inject a mock client.
final marketScreenerBybitClientProvider = Provider<BybitRestClient>((ref) {
  final client = BybitRestClient(baseUrl: BybitConfig.baseUrl);
  ref.onDispose(client.close);
  return client;
});

/// Fetches ALL available linear (perpetual) and spot tickers from the Bybit
/// demo API and maps them to [MarketScreenerItem]s.
///
/// If one category fails the other is still returned; only when *both*
/// categories fail does the provider throw.
final marketScreenerItemsProvider = FutureProvider<List<MarketScreenerItem>>((
  ref,
) async {
  final client = ref.watch(marketScreenerBybitClientProvider);

  final results = await Future.wait([
    client.fetchAllTickers('linear'),
    client.fetchAllTickers('spot'),
  ]);

  final items = <MarketScreenerItem>[];
  var hadSuccess = false;

  for (var i = 0; i < results.length; i++) {
    final assetClass = i == 0 ? AssetClass.perp : AssetClass.spot;
    results[i].when(
      success: (tickers) {
        items.addAll(tickers.map((t) => tickerToScreenerItem(t, assetClass)));
        hadSuccess = true;
      },
      failure: (_) {},
    );
  }

  if (!hadSuccess) {
    throw Exception('Failed to fetch market data from Bybit');
  }

  return items;
});

/// Filters the screener items by the current search query and category filter.
///
/// Returns an [AsyncValue] that mirrors the loading/error state of
/// [marketScreenerItemsProvider] and applies filtering only to resolved data.
final filteredMarketScreenerItemsProvider =
    Provider<AsyncValue<List<MarketScreenerItem>>>((ref) {
      final query = ref
          .watch(marketScreenerSearchProvider)
          .trim()
          .toLowerCase();
      final filter = ref.watch(marketScreenerFilterProvider);
      return ref.watch(marketScreenerItemsProvider).whenData((markets) {
        return markets.where((market) {
          final matchesFilter =
              filter == null || market.assetClass.category == filter;
          final matchesSearch =
              query.isEmpty ||
              market.symbol.toLowerCase().contains(query) ||
              market.rawSymbol.toLowerCase().contains(query) ||
              market.name.toLowerCase().contains(query) ||
              market.venue.displayName.toLowerCase().contains(query) ||
              market.venue.shortCode.toLowerCase().contains(query);
          return matchesFilter && matchesSearch;
        }).toList();
      });
    });
