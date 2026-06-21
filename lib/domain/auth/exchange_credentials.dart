import '../entities/venue.dart';

final class ExchangeCredentials {
  const ExchangeCredentials({
    required this.venue,
    required this.apiKey,
    required this.secret,
    this.isEnabled = true,
  });

  final Venue venue;
  final String apiKey;
  final String secret;
  final bool isEnabled;

  ExchangeCredentials copyWith({
    Venue? venue,
    String? apiKey,
    String? secret,
    bool? isEnabled,
  }) {
    return ExchangeCredentials(
      venue: venue ?? this.venue,
      apiKey: apiKey ?? this.apiKey,
      secret: secret ?? this.secret,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'venue': venue.id,
      'apiKey': apiKey,
      'secret': secret,
      'isEnabled': isEnabled,
    };
  }

  factory ExchangeCredentials.fromJson(Map<String, dynamic> json) {
    final venueId = json['venue'] as String;
    final venue = Venue.values.firstWhere(
      (v) => v.id == venueId,
      orElse: () => throw FormatException('Unknown venue id: $venueId'),
    );

    return ExchangeCredentials(
      venue: venue,
      apiKey: json['apiKey'] as String,
      secret: json['secret'] as String,
      isEnabled: json['isEnabled'] as bool? ?? true,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExchangeCredentials &&
          runtimeType == other.runtimeType &&
          venue == other.venue &&
          apiKey == other.apiKey &&
          secret == other.secret &&
          isEnabled == other.isEnabled;

  @override
  int get hashCode => Object.hash(venue, apiKey, secret, isEnabled);

  @override
  String toString() {
    return 'ExchangeCredentials(venue: ${venue.displayName}, '
        'apiKey: ${_mask(apiKey)}, secret: ${_mask(secret)}, '
        'isEnabled: $isEnabled)';
  }

  String _mask(String value) {
    if (value.length <= 8) return '***';
    return '${value.substring(0, 4)}...${value.substring(value.length - 4)}';
  }
}
