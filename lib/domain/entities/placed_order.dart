final class PlacedOrder {
  const PlacedOrder({required this.orderId, this.orderLinkId});

  final String orderId;
  final String? orderLinkId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlacedOrder &&
          orderId == other.orderId &&
          orderLinkId == other.orderLinkId;

  @override
  int get hashCode => Object.hash(orderId, orderLinkId);

  @override
  String toString() =>
      'PlacedOrder(orderId: $orderId, orderLinkId: $orderLinkId)';
}
