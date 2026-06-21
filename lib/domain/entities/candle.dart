final class Candle {
  const Candle({
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
    required this.timestamp,
  });

  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;
  final DateTime timestamp;

  double get body => close - open;

  double get range => high - low;

  bool get isBullish => close >= open;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Candle &&
          open == other.open &&
          high == other.high &&
          low == other.low &&
          close == other.close &&
          volume == other.volume &&
          timestamp == other.timestamp;

  @override
  int get hashCode => Object.hash(open, high, low, close, volume, timestamp);

  @override
  String toString() =>
      'Candle(O:$open H:$high L:$low C:$close V:$volume @ $timestamp)';
}
