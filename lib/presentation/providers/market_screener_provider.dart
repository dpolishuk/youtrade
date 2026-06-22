import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/mock/deterministic_market_data_store.dart';
import '../../domain/entities/venue.dart';

enum MarketCategory {
  crypto('Crypto'),
  stocks('Stocks'),
  futures('Futures'),
  options('Options');

  const MarketCategory(this.label);
  final String label;
}

enum AssetClass {
  perp('PERP', MarketCategory.crypto),
  spot('SPOT', MarketCategory.crypto),
  stock('STOCK', MarketCategory.stocks),
  fut('FUT', MarketCategory.futures),
  opt('OPT', MarketCategory.options);

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
  final List<double> sparkline;
}

final marketScreenerSearchProvider = StateProvider<String>((ref) => '');

final marketScreenerFilterProvider = StateProvider<String>((ref) => 'All');

final marketScreenerItemsProvider = Provider<List<MarketScreenerItem>>((ref) {
  return _mockMarkets;
});

final filteredMarketScreenerItemsProvider = Provider<List<MarketScreenerItem>>((
  ref,
) {
  final query = ref.watch(marketScreenerSearchProvider).trim().toLowerCase();
  final filter = ref.watch(marketScreenerFilterProvider);
  final markets = ref.watch(marketScreenerItemsProvider);

  return markets.where((market) {
    final matchesFilter =
        filter == 'All' || market.assetClass.category.label == filter;
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

String _displaySymbol(String rawSymbol) {
  return rawSymbol.replaceAll('USDT', '').replaceAll('=F', '');
}

List<double> _sparkline(String rawSymbol) {
  return DeterministicMarketDataStore.screenerSparkline(rawSymbol);
}

MarketScreenerItem _row({
  required String rawSymbol,
  required String name,
  required Venue venue,
  required AssetClass assetClass,
  required int decimals,
  double? price,
  double? change24hPercent,
}) {
  final ticker = price == null
      ? DeterministicMarketDataStore.screenerTicker(rawSymbol)
      : null;
  return MarketScreenerItem(
    symbol: _displaySymbol(rawSymbol),
    rawSymbol: rawSymbol,
    name: name,
    venue: venue,
    assetClass: assetClass,
    price: price ?? ticker!.last,
    change24hPercent: change24hPercent ?? ticker!.change24hPercent,
    priceDecimals: decimals,
    sparkline: _sparkline(rawSymbol),
  );
}

final _mockMarkets = <MarketScreenerItem>[
  _row(
    rawSymbol: 'BTCUSDT',
    name: 'Bitcoin Perp',
    venue: Venue.binance,
    assetClass: AssetClass.perp,
    decimals: 1,
  ),
  _row(
    rawSymbol: 'ETHUSDT',
    name: 'Ethereum Perp',
    venue: Venue.bybit,
    assetClass: AssetClass.perp,
    decimals: 2,
  ),
  _row(
    rawSymbol: 'SOLUSDT',
    name: 'Solana',
    venue: Venue.okx,
    assetClass: AssetClass.spot,
    decimals: 2,
  ),
  _row(
    rawSymbol: 'AAPL',
    name: 'Apple Inc.',
    venue: Venue.coinbase,
    assetClass: AssetClass.stock,
    decimals: 2,
  ),
  _row(
    rawSymbol: 'GC=F',
    name: 'Gold Futures',
    venue: Venue.okx,
    assetClass: AssetClass.fut,
    decimals: 1,
  ),
  MarketScreenerItem(
    symbol: 'NVDA',
    rawSymbol: 'NVDA',
    name: 'NVIDIA Corp',
    venue: Venue.coinbase,
    assetClass: AssetClass.stock,
    price: 118.42,
    change24hPercent: 3.21,
    priceDecimals: 2,
  ),
  MarketScreenerItem(
    symbol: 'XRP',
    rawSymbol: 'XRPUSDT',
    name: 'XRP',
    venue: Venue.binance,
    assetClass: AssetClass.spot,
    price: 0.6284,
    change24hPercent: -1.42,
    priceDecimals: 4,
  ),
  MarketScreenerItem(
    symbol: 'CL',
    rawSymbol: 'CL=F',
    name: 'Crude Oil WTI',
    venue: Venue.okx,
    assetClass: AssetClass.fut,
    price: 71.84,
    change24hPercent: -0.86,
    priceDecimals: 2,
  ),
  MarketScreenerItem(
    symbol: 'TSLA',
    rawSymbol: 'TSLA',
    name: 'Tesla Inc.',
    venue: Venue.coinbase,
    assetClass: AssetClass.stock,
    price: 248.91,
    change24hPercent: 1.94,
    priceDecimals: 2,
  ),
  MarketScreenerItem(
    symbol: 'BTC-28K-C',
    rawSymbol: 'BTC-28K-C',
    name: 'BTC Call 70k',
    venue: Venue.bybit,
    assetClass: AssetClass.opt,
    price: 0.0421,
    change24hPercent: 8.12,
    priceDecimals: 4,
  ),
];
