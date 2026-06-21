import 'symbol.dart';

final class Ticker {
  factory Ticker({
    required TradingSymbol symbol,
    required double lastPrice,
    required double bid,
    required double ask,
    required double change24h,
    required double change24hPercent,
    required double volume,
    required DateTime timestamp,
  }) {
    void requireFinite(double value, String name) {
      if (value.isNaN || value.isInfinite) {
        throw ArgumentError.value(value, name, '$name must be finite');
      }
    }

    requireFinite(lastPrice, 'lastPrice');
    requireFinite(bid, 'bid');
    requireFinite(ask, 'ask');
    requireFinite(change24h, 'change24h');
    requireFinite(change24hPercent, 'change24hPercent');
    requireFinite(volume, 'volume');

    return Ticker._(
      symbol: symbol,
      lastPrice: lastPrice,
      bid: bid,
      ask: ask,
      change24h: change24h,
      change24hPercent: change24hPercent,
      volume: volume,
      timestamp: timestamp,
    );
  }

  const Ticker._({
    required this.symbol,
    required this.lastPrice,
    required this.bid,
    required this.ask,
    required this.change24h,
    required this.change24hPercent,
    required this.volume,
    required this.timestamp,
  });

  final TradingSymbol symbol;
  final double lastPrice;
  final double bid;
  final double ask;
  final double change24h;
  final double change24hPercent;
  final double volume;
  final DateTime timestamp;

  double get spread => ask - bid;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Ticker &&
          symbol == other.symbol &&
          lastPrice == other.lastPrice &&
          bid == other.bid &&
          ask == other.ask &&
          change24h == other.change24h &&
          change24hPercent == other.change24hPercent &&
          volume == other.volume &&
          timestamp == other.timestamp;

  @override
  int get hashCode => Object.hash(
    symbol,
    lastPrice,
    bid,
    ask,
    change24h,
    change24hPercent,
    volume,
    timestamp,
  );

  @override
  String toString() => 'Ticker(${symbol.id}: \$lastPrice @ $timestamp)';
}
