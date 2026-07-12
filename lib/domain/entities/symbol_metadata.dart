import 'symbol.dart';
import 'venue.dart';

/// Metadata for a mockup symbol used by the Trading Terminal screen.
///
/// Mirrors the `symMeta()` function in `mockups/YouTrade.dc.html` so labels,
/// class tags, decimals, and venue names match the mockup exactly.
final class SymbolMetadata {
  const SymbolMetadata({
    required this.name,
    required this.symbolClass,
    required this.base,
    required this.decimals,
    required this.venue,
  });

  final String name;
  final SymbolClass symbolClass;
  final String base;
  final int decimals;
  final Venue venue;

  bool get showsFunding =>
      symbolClass == SymbolClass.perp || symbolClass == SymbolClass.future;

  bool get showsLeverage =>
      symbolClass == SymbolClass.perp || symbolClass == SymbolClass.future;
}

enum SymbolClass {
  perp('PERP'),
  spot('SPOT'),
  equity('EQUITY'),
  future('FUTURE'),
  option('OPTION');

  const SymbolClass(this.label);

  final String label;
}

SymbolMetadata resolveSymbolMetadata(TradingSymbol symbol) {
  final key = (symbol.venue, symbol.rawSymbol.toUpperCase());
  return switch (key) {
    (Venue.binance, 'BTCUSDT') => const SymbolMetadata(
      name: 'Bitcoin Perpetual',
      symbolClass: SymbolClass.perp,
      base: 'BTC',
      decimals: 1,
      venue: Venue.binance,
    ),
    (Venue.bybit, 'BTCUSDT') => const SymbolMetadata(
      name: 'Bitcoin Perpetual',
      symbolClass: SymbolClass.perp,
      base: 'BTC',
      decimals: 1,
      venue: Venue.bybit,
    ),
    (Venue.bybit, 'ETHUSDT') => const SymbolMetadata(
      name: 'Ethereum Perpetual',
      symbolClass: SymbolClass.perp,
      base: 'ETH',
      decimals: 2,
      venue: Venue.bybit,
    ),
    (Venue.bybit, 'SOLUSDT') => const SymbolMetadata(
      name: 'Solana',
      symbolClass: SymbolClass.perp,
      base: 'SOL',
      decimals: 2,
      venue: Venue.bybit,
    ),
    (Venue.bybit, 'XRPUSDT') => const SymbolMetadata(
      name: 'XRP',
      symbolClass: SymbolClass.perp,
      base: 'XRP',
      decimals: 4,
      venue: Venue.bybit,
    ),
    (Venue.okx, 'SOLUSDT') => const SymbolMetadata(
      name: 'Solana',
      symbolClass: SymbolClass.spot,
      base: 'SOL',
      decimals: 2,
      venue: Venue.okx,
    ),
    (Venue.binance, 'XRPUSDT') => const SymbolMetadata(
      name: 'XRP',
      symbolClass: SymbolClass.spot,
      base: 'XRP',
      decimals: 4,
      venue: Venue.binance,
    ),
    (Venue.coinbase, 'AAPL') => const SymbolMetadata(
      name: 'Apple Inc.',
      symbolClass: SymbolClass.equity,
      base: 'AAPL',
      decimals: 2,
      venue: Venue.coinbase,
    ),
    (Venue.coinbase, 'NVDA') => const SymbolMetadata(
      name: 'NVIDIA Corp.',
      symbolClass: SymbolClass.equity,
      base: 'NVDA',
      decimals: 2,
      venue: Venue.coinbase,
    ),
    (Venue.coinbase, 'TSLA') => const SymbolMetadata(
      name: 'Tesla Inc.',
      symbolClass: SymbolClass.equity,
      base: 'TSLA',
      decimals: 2,
      venue: Venue.coinbase,
    ),
    (Venue.okx, 'GC=F') => const SymbolMetadata(
      name: 'Gold Futures \u00b7 Dec',
      symbolClass: SymbolClass.future,
      base: 'XAU',
      decimals: 1,
      venue: Venue.okx,
    ),
    (Venue.okx, 'CL=F') => const SymbolMetadata(
      name: 'Crude Oil Futures \u00b7 Dec',
      symbolClass: SymbolClass.future,
      base: 'CL',
      decimals: 2,
      venue: Venue.okx,
    ),
    (Venue.bybit, 'BTC-28K-C') => const SymbolMetadata(
      name: 'BTC 28K Call',
      symbolClass: SymbolClass.option,
      base: 'BTC-28K-C',
      decimals: 2,
      venue: Venue.bybit,
    ),
    _ => SymbolMetadata(
      name: symbol.base,
      symbolClass: SymbolClass.spot,
      base: symbol.base,
      decimals: 2,
      venue: symbol.venue,
    ),
  };
}

/// Label shown in the symbol switcher chips.
String chipLabel(String rawSymbol) {
  final upper = rawSymbol.toUpperCase();
  if (upper == 'GC=F') return 'GOLD';
  return upper.replaceAll('USDT', '');
}
