final class AccountOrder {
  const AccountOrder({
    required this.orderId,
    required this.symbol,
    required this.side,
    required this.orderType,
    required this.price,
    required this.qty,
    required this.orderStatus,
    this.createdTime,
    this.cumExecQty = 0.0,
  });

  final String orderId;
  final String symbol;
  final String side;
  final String orderType;
  final double price;
  final double qty;
  final String orderStatus;
  final String? createdTime;

  /// Cumulative executed (filled) quantity returned by Bybit.
  final double cumExecQty;

  bool get isBuy => side == 'Buy';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccountOrder &&
          orderId == other.orderId &&
          symbol == other.symbol &&
          side == other.side &&
          orderType == other.orderType &&
          price == other.price &&
          qty == other.qty &&
          cumExecQty == other.cumExecQty &&
          orderStatus == other.orderStatus &&
          createdTime == other.createdTime;

  @override
  int get hashCode => Object.hash(
    orderId,
    symbol,
    side,
    orderType,
    price,
    qty,
    cumExecQty,
    orderStatus,
    createdTime,
  );

  @override
  String toString() =>
      'AccountOrder($orderId: $side $qty $symbol @ $price ($orderStatus))';
}
