import '../entities/venue.dart';

enum MarketDataFeature {
  restTicker,
  restCandles,
  restOrderBook,
  restTrades,
  wsTicker,
  wsOrderBook,
  wsTrades,
}

final class ExchangeCapability {
  const ExchangeCapability({
    required this.venue,
    required this.supportedFeatures,
  });

  final Venue venue;
  final Set<MarketDataFeature> supportedFeatures;

  bool supports(MarketDataFeature feature) =>
      supportedFeatures.contains(feature);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExchangeCapability &&
          venue == other.venue &&
          supportedFeatures == other.supportedFeatures;

  @override
  int get hashCode => Object.hash(venue, supportedFeatures);

  @override
  String toString() =>
      'ExchangeCapability(${venue.displayName}: $supportedFeatures)';
}

abstract interface class ExchangeCapabilityRegistry {
  ExchangeCapability? forVenue(Venue venue);

  List<ExchangeCapability> get all;
}
