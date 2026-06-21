import 'symbol.dart';

final class Ticker {
  const Ticker({
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
