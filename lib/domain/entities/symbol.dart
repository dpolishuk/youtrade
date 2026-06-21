import 'venue.dart';

final class TradingSymbol {
  factory TradingSymbol({
    required String base,
    required String quote,
    required Venue venue,
    String? rawSymbol,
  }) {
    assert(base.isNotEmpty, 'base must be non-empty');
    assert(!base.contains(' '), 'base must not contain whitespace');
    assert(quote.isNotEmpty, 'quote must be non-empty');
    assert(!quote.contains(' '), 'quote must not contain whitespace');
    final normalizedBase = base.trim().toUpperCase();
    final normalizedQuote = quote.trim().toUpperCase();
    return TradingSymbol._(
      base: normalizedBase,
      quote: normalizedQuote,
      venue: venue,
      rawSymbol: rawSymbol ?? '$normalizedBase$normalizedQuote',
    );
  }

  const TradingSymbol._({
    required this.base,
    required this.quote,
    required this.venue,
    required this.rawSymbol,
  });

  final String base;
  final String quote;
  final Venue venue;
  final String rawSymbol;

  String get id => '$base/$quote';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TradingSymbol &&
          base == other.base &&
          quote == other.quote &&
          venue == other.venue &&
          rawSymbol == other.rawSymbol;

  @override
  int get hashCode => Object.hash(base, quote, venue, rawSymbol);

  @override
  String toString() => 'TradingSymbol($id @ ${venue.displayName})';
}
