import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/bybit_config.dart';
import '../../../core/screener_score.dart';
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

/// Sort options offered in the market screener dropdown.
enum SortOption {
  score('Score'),
  turnover('Volume'),
  changePct('Change %'),
  openInterest('Open Interest'),
  fundingRate('Funding'),
  volatility('Volatility'),
  spread('Spread'),
  price('Price');

  const SortOption(this.label);
  final String label;
}

/// Extracts the numeric sort key for [item] under the given [option].
///
/// For [SortOption.volatility] the key is the 24h range relative to the
/// previous price: `(high - low) / prevPrice24h`. For [SortOption.spread] the
/// key is the bid-ask spread relative to the midpoint.
double sortKeyValue(MarketScreenerItem item, SortOption option) {
  switch (option) {
    case SortOption.score:
      return item.compositeScore;
    case SortOption.turnover:
      return item.turnover24h;
    case SortOption.changePct:
      return item.change24hPercent;
    case SortOption.openInterest:
      return item.openInterestValue;
    case SortOption.fundingRate:
      return item.fundingRate;
    case SortOption.volatility:
      final prev = item.prevPrice24h > 0 ? item.prevPrice24h : 1.0;
      return (item.highPrice24h - item.lowPrice24h) / prev;
    case SortOption.spread:
      final mid = (item.ask1Price + item.bid1Price) / 2;
      final denom = mid > 0 ? mid : 1.0;
      return (item.ask1Price - item.bid1Price) / denom;
    case SortOption.price:
      return item.price;
  }
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
    this.turnover24h = 0.0,
    this.highPrice24h = 0.0,
    this.lowPrice24h = 0.0,
    this.prevPrice24h = 0.0,
    this.openInterestValue = 0.0,
    this.fundingRate = 0.0,
    this.bid1Price = 0.0,
    this.ask1Price = 0.0,
    this.markPrice = 0.0,
    this.indexPrice = 0.0,
    this.compositeScore = 0.0,
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
  final double turnover24h;
  final double highPrice24h;
  final double lowPrice24h;
  final double prevPrice24h;
  final double openInterestValue;
  final double fundingRate;
  final double bid1Price;
  final double ask1Price;
  final double markPrice;
  final double indexPrice;
  final double compositeScore;
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
///
/// [compositeScore] is assigned by [ScreenerScore] after z-score normalization;
/// pass `0.0` for items that did not pass the guard rails.
MarketScreenerItem tickerToScreenerItem(
  Map<String, dynamic> ticker,
  AssetClass assetClass, {
  double compositeScore = 0.0,
}) {
  final rawSymbol = ticker['symbol'] as String? ?? '';
  final lastPrice =
      double.tryParse(ticker['lastPrice'] as String? ?? '') ?? 0.0;
  final price24hPcnt =
      double.tryParse(ticker['price24hPcnt'] as String? ?? '') ?? 0.0;
  final volume24h =
      double.tryParse(ticker['volume24h'] as String? ?? '') ?? 0.0;
  final turnover24h =
      double.tryParse(ticker['turnover24h'] as String? ?? '') ?? 0.0;
  return MarketScreenerItem(
    symbol: displaySymbol(rawSymbol),
    rawSymbol: rawSymbol,
    name: rawSymbol,
    venue: Venue.bybit,
    assetClass: assetClass,
    price: lastPrice,
    change24hPercent: price24hPcnt * 100,
    volume24h: volume24h,
    turnover24h: turnover24h,
    highPrice24h:
        double.tryParse(ticker['highPrice24h'] as String? ?? '') ?? 0.0,
    lowPrice24h: double.tryParse(ticker['lowPrice24h'] as String? ?? '') ?? 0.0,
    prevPrice24h:
        double.tryParse(ticker['prevPrice24h'] as String? ?? '') ?? 0.0,
    openInterestValue:
        double.tryParse(ticker['openInterestValue'] as String? ?? '') ?? 0.0,
    fundingRate: double.tryParse(ticker['fundingRate'] as String? ?? '') ?? 0.0,
    bid1Price: double.tryParse(ticker['bid1Price'] as String? ?? '') ?? 0.0,
    ask1Price: double.tryParse(ticker['ask1Price'] as String? ?? '') ?? 0.0,
    markPrice: double.tryParse(ticker['markPrice'] as String? ?? '') ?? 0.0,
    indexPrice: double.tryParse(ticker['indexPrice'] as String? ?? '') ?? 0.0,
    compositeScore: compositeScore,
    priceDecimals: priceDecimals(lastPrice),
  );
}

final marketScreenerSearchProvider = StateProvider<String>((ref) => '');

final marketScreenerFilterProvider = StateProvider<MarketCategory?>(
  (ref) => null,
);

/// Currently selected sort option and direction for the screener.
final marketScreenerSortProvider =
    StateProvider<({SortOption option, bool descending})>(
      (ref) => (option: SortOption.score, descending: true),
    );

/// Provides the [BybitRestClient] used by the screener. Override in tests to
/// inject a mock client.
final marketScreenerBybitClientProvider = Provider<BybitRestClient>((ref) {
  final client = BybitRestClient(baseUrl: BybitConfig.baseUrl);
  ref.onDispose(client.close);
  return client;
});

/// Fetches ALL available linear (perpetual) and spot tickers from the Bybit
/// demo API, maps them to [MarketScreenerItem]s, and ranks them by a
/// z-score-normalized composite score ([ScreenerScore]).
///
/// If one category fails the other is still returned; only when *both*
/// categories fail does the provider throw. Items that fail the liquidity /
/// spread / open-interest guard rails are still included but with
/// `compositeScore` 0, sorting below tradeable items.
final marketScreenerItemsProvider = FutureProvider<List<MarketScreenerItem>>((
  ref,
) async {
  final client = ref.watch(marketScreenerBybitClientProvider);

  final results = await Future.wait([
    client.fetchAllTickers('linear'),
    client.fetchAllTickers('spot'),
  ]);

  // Collect raw ticker maps alongside their asset class so we can score and
  // build items in a single pass after z-score normalization.
  final tickerMaps = <Map<String, dynamic>>[];
  final assetClasses = <AssetClass>[];
  var hadSuccess = false;

  for (var i = 0; i < results.length; i++) {
    final assetClass = i == 0 ? AssetClass.perp : AssetClass.spot;
    results[i].when(
      success: (tickers) {
        for (final ticker in tickers) {
          tickerMaps.add(ticker);
          assetClasses.add(assetClass);
        }
        hadSuccess = true;
      },
      failure: (_) {},
    );
  }

  if (!hadSuccess) {
    throw Exception('Failed to fetch market data from Bybit');
  }

  // Compute composite scores via z-score normalization + guard rails.
  // Key by category:symbol to avoid collision when same symbol exists in both
  // linear and spot (e.g. BTCUSDT).
  final rawTickers = <RawTicker>[];
  final scoreKeys = <String>[];
  for (var i = 0; i < tickerMaps.length; i++) {
    final symbol = tickerMaps[i]['symbol'] as String? ?? '';
    final category = assetClasses[i] == AssetClass.perp ? 'linear' : 'spot';
    rawTickers.add(RawTicker.fromBybitTicker(tickerMaps[i]));
    scoreKeys.add('$category:$symbol');
  }
  final scores = ScreenerScore.compute(rawTickers);
  final scoreByKey = <String, double>{};
  final scoreList = scores.values.toList();
  for (var i = 0; i < scoreKeys.length && i < scoreList.length; i++) {
    scoreByKey[scoreKeys[i]] = scoreList[i];
  }

  // Build items with their composite score; items failing guard rails
  // default to negative infinity (sort below scored items).
  final items = List<MarketScreenerItem>.generate(tickerMaps.length, (i) {
    final symbol = tickerMaps[i]['symbol'] as String? ?? '';
    final category = assetClasses[i] == AssetClass.perp ? 'linear' : 'spot';
    final key = '$category:$symbol';
    return tickerToScreenerItem(
      tickerMaps[i],
      assetClasses[i],
      compositeScore: scoreByKey[key] ?? double.negativeInfinity,
    );
  });

  // Sort by composite score descending — highest-ranked first.
  items.sort((a, b) => b.compositeScore.compareTo(a.compositeScore));

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
      final sort = ref.watch(marketScreenerSortProvider);
      return ref.watch(marketScreenerItemsProvider).whenData((markets) {
        final filtered = markets.where((market) {
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

        filtered.sort((a, b) {
          final cmp = sortKeyValue(
            a,
            sort.option,
          ).compareTo(sortKeyValue(b, sort.option));
          return sort.descending ? -cmp : cmp;
        });

        return filtered;
      });
    });
