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
  final key = symbol.rawSymbol.toUpperCase();
  return switch (key) {
    'BTCUSDT' => const SymbolMetadata(
      name: 'Bitcoin Perpetual',
      symbolClass: SymbolClass.perp,
      base: 'BTC',
      decimals: 1,
      venue: Venue.binance,
    ),
    'ETHUSDT' => const SymbolMetadata(
      name: 'Ethereum Perpetual',
      symbolClass: SymbolClass.perp,
      base: 'ETH',
      decimals: 2,
      venue: Venue.bybit,
    ),
    'SOLUSDT' => const SymbolMetadata(
      name: 'Solana',
      symbolClass: SymbolClass.spot,
      base: 'SOL',
      decimals: 2,
      venue: Venue.okx,
    ),
    'AAPL' => const SymbolMetadata(
      name: 'Apple Inc.',
      symbolClass: SymbolClass.equity,
      base: 'AAPL',
      decimals: 2,
      venue: Venue.coinbase,
    ),
    'GC=F' => const SymbolMetadata(
      name: 'Gold Futures · Dec',
      symbolClass: SymbolClass.future,
      base: 'XAU',
      decimals: 1,
      venue: Venue.okx,
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
