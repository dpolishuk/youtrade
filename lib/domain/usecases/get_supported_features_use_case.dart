import '../entities/venue.dart';
import '../registry/exchange_capability.dart';

final class GetSupportedFeaturesUseCase {
  const GetSupportedFeaturesUseCase(this._registry);

  final ExchangeCapabilityRegistry _registry;

  Set<MarketDataFeature> call(Venue venue) {
    final capability = _registry.forVenue(venue);
    return capability?.supportedFeatures ?? const {};
  }
}
