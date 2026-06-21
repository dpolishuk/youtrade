enum TradeSide { buy, sell }

final class Trade {
  const Trade({
    required this.price,
    required this.amount,
    required this.side,
    required this.timestamp,
    this.tradeId,
  });

  final double price;
  final double amount;
  final TradeSide side;
  final DateTime timestamp;
  final String? tradeId;

  double get value => price * amount;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Trade &&
          price == other.price &&
          amount == other.amount &&
          side == other.side &&
          timestamp == other.timestamp &&
          tradeId == other.tradeId;

  @override
  int get hashCode => Object.hash(price, amount, side, timestamp, tradeId);

  @override
  String toString() => 'Trade(${side.name}: \$$price x $amount @ $timestamp)';
}
