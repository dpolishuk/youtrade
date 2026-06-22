import 'venue.dart';

final class TradingSymbol {
  factory TradingSymbol({
    required String base,
    required String quote,
    required Venue venue,
    String? rawSymbol,
  }) {
    final normalizedBase = base.trim().toUpperCase();
    final normalizedQuote = quote.trim().toUpperCase();
    if (normalizedBase.isEmpty) {
      throw ArgumentError.value(base, 'base', 'base must be non-empty');
    }
    if (normalizedBase.contains('\x00')) {
      throw ArgumentError.value(
        base,
        'base',
        'base must not contain null bytes',
      );
    }
    if (normalizedBase.contains(RegExp(r'\s'))) {
      throw ArgumentError.value(
        base,
        'base',
        'base must not contain whitespace',
      );
    }
    if (normalizedQuote.isEmpty) {
      throw ArgumentError.value(quote, 'quote', 'quote must be non-empty');
    }
    if (normalizedQuote.contains('\x00')) {
      throw ArgumentError.value(
        quote,
        'quote',
        'quote must not contain null bytes',
      );
    }
    if (normalizedQuote.contains(RegExp(r'\s'))) {
      throw ArgumentError.value(
        quote,
        'quote',
        'quote must not contain whitespace',
      );
    }

    const symbolPartPattern = r'^[A-Za-z0-9.\-=]{1,20}$';
    final symbolPartRegex = RegExp(symbolPartPattern);
    if (!symbolPartRegex.hasMatch(normalizedBase)) {
      throw ArgumentError.value(
        base,
        'base',
        'base must match $symbolPartPattern',
      );
    }
    if (!symbolPartRegex.hasMatch(normalizedQuote)) {
      throw ArgumentError.value(
        quote,
        'quote',
        'quote must match $symbolPartPattern',
      );
    }

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
