import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/venue.dart';

enum AssetClass {
  crypto('Crypto'),
  forex('Forex'),
  equities('Equities'),
  commodities('Commodities'),
  options('Options');

  const AssetClass(this.label);

  final String label;
}

final class MarketScreenerItem {
  const MarketScreenerItem({
    required this.symbol,
    required this.name,
    required this.venue,
    required this.assetClass,
    required this.price,
    required this.change24hPercent,
    required this.sparkline,
  });

  final String symbol;
  final String name;
  final Venue venue;
  final AssetClass assetClass;
  final double price;
  final double change24hPercent;
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
    final matchesFilter = filter == 'All' || market.assetClass.label == filter;
    final matchesSearch =
        query.isEmpty ||
        market.symbol.toLowerCase().contains(query) ||
        market.name.toLowerCase().contains(query) ||
        market.venue.displayName.toLowerCase().contains(query);
    return matchesFilter && matchesSearch;
  }).toList();
});

final _mockMarkets = <MarketScreenerItem>[
  MarketScreenerItem(
    symbol: 'BTC',
    name: 'Bitcoin / USD',
    venue: Venue.binance,
    assetClass: AssetClass.crypto,
    price: 68421.35,
    change24hPercent: 2.34,
    sparkline: const [
      66200,
      66800,
      67100,
      66900,
      67500,
      67900,
      67700,
      68100,
      68421,
    ],
  ),
  MarketScreenerItem(
    symbol: 'ETH',
    name: 'Ethereum / USD',
    venue: Venue.bybit,
    assetClass: AssetClass.crypto,
    price: 3520.12,
    change24hPercent: -1.12,
    sparkline: const [3550, 3540, 3530, 3560, 3545, 3520, 3510, 3530, 3520],
  ),
  MarketScreenerItem(
    symbol: 'SOL',
    name: 'Solana / USD',
    venue: Venue.binance,
    assetClass: AssetClass.crypto,
    price: 145.67,
    change24hPercent: 5.78,
    sparkline: const [136, 138, 137, 140, 142, 141, 143, 144, 145],
  ),
  MarketScreenerItem(
    symbol: 'EURUSD',
    name: 'Euro / US Dollar',
    venue: Venue.okx,
    assetClass: AssetClass.forex,
    price: 1.0845,
    change24hPercent: 0.21,
    sparkline: const [
      1.0820,
      1.0830,
      1.0825,
      1.0835,
      1.0840,
      1.0838,
      1.0842,
      1.0845,
      1.0845,
    ],
  ),
  MarketScreenerItem(
    symbol: 'GBPJPY',
    name: 'British Pound / Japanese Yen',
    venue: Venue.okx,
    assetClass: AssetClass.forex,
    price: 198.42,
    change24hPercent: -0.45,
    sparkline: const [
      199.0,
      198.8,
      198.6,
      198.7,
      198.5,
      198.4,
      198.3,
      198.4,
      198.42,
    ],
  ),
  MarketScreenerItem(
    symbol: 'AAPL',
    name: 'Apple Inc.',
    venue: Venue.coinbase,
    assetClass: AssetClass.equities,
    price: 189.52,
    change24hPercent: 0.87,
    sparkline: const [
      186.0,
      187.0,
      186.5,
      188.0,
      188.5,
      189.0,
      188.8,
      189.2,
      189.52,
    ],
  ),
  MarketScreenerItem(
    symbol: 'TSLA',
    name: 'Tesla, Inc.',
    venue: Venue.coinbase,
    assetClass: AssetClass.equities,
    price: 172.18,
    change24hPercent: -2.34,
    sparkline: const [
      176.0,
      175.0,
      174.0,
      173.5,
      173.0,
      172.5,
      172.0,
      171.5,
      172.18,
    ],
  ),
  MarketScreenerItem(
    symbol: 'XAUUSD',
    name: 'Gold / US Dollar',
    venue: Venue.bybit,
    assetClass: AssetClass.commodities,
    price: 2324.60,
    change24hPercent: 0.12,
    sparkline: const [2315, 2318, 2317, 2320, 2322, 2321, 2323, 2324, 2324.6],
  ),
  MarketScreenerItem(
    symbol: 'XAGUSD',
    name: 'Silver / US Dollar',
    venue: Venue.bybit,
    assetClass: AssetClass.commodities,
    price: 29.45,
    change24hPercent: -0.78,
    sparkline: const [
      29.7,
      29.65,
      29.6,
      29.55,
      29.5,
      29.48,
      29.46,
      29.47,
      29.45,
    ],
  ),
];
