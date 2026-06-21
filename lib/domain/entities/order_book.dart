final class OrderBookLevel {
  const OrderBookLevel({required this.price, required this.amount});

  final double price;
  final double amount;

  double get value => price * amount;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderBookLevel && price == other.price && amount == other.amount;

  @override
  int get hashCode => Object.hash(price, amount);

  @override
  String toString() => 'OrderBookLevel(\$$price x $amount)';
}

final class OrderBook {
  const OrderBook({
    required this.bids,
    required this.asks,
    required this.timestamp,
  });

  final List<OrderBookLevel> bids;
  final List<OrderBookLevel> asks;
  final DateTime timestamp;

  double? get bestBid => bids.isNotEmpty ? bids.first.price : null;

  double? get bestAsk => asks.isNotEmpty ? asks.first.price : null;

  double? get spread {
    final bestBid = this.bestBid;
    final bestAsk = this.bestAsk;
    if (bestBid == null || bestAsk == null) return null;
    return bestAsk - bestBid;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderBook &&
          bids == other.bids &&
          asks == other.asks &&
          timestamp == other.timestamp;

  @override
  int get hashCode => Object.hash(bids, asks, timestamp);

  @override
  String toString() =>
      'OrderBook(bids:${bids.length}, asks:${asks.length} @ $timestamp)';
}
