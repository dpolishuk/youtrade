import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatting.dart';
import '../../core/result.dart';
import '../../domain/entities/account_order.dart';
import '../../domain/entities/order.dart';
import 'portfolio_data_provider.dart';

/// All data needed to render the Orders & History screen.
@immutable
class OrdersData {
  const OrdersData({
    required this.openOrders,
    required this.historyOrders,
    this.needsCredentials = false,
  });

  /// Sentinel [OrdersData] used when API credentials are not configured.
  const factory OrdersData.needsCredentials() = _NeedsCredentialsOrdersData;

  final List<Order> openOrders;
  final List<Order> historyOrders;
  final bool needsCredentials;
}

final class _NeedsCredentialsOrdersData extends OrdersData {
  const _NeedsCredentialsOrdersData()
    : super(
        openOrders: const [],
        historyOrders: const [],
        needsCredentials: true,
      );
}

/// Maps a Bybit [AccountOrder] into the UI [Order] entity.
Order accountOrderToOrder(AccountOrder order) {
  final fillPercent = order.qty > 0
      ? (order.cumExecQty / order.qty * 100).clamp(0, 100).round()
      : 0;
  return Order(
    orderId: order.orderId,
    symbol: order.symbol,
    side: order.isBuy ? 'BUY' : 'SELL',
    type: order.orderType,
    venue: 'Bybit',
    price: formatNumber(order.price),
    qty: formatNumber(order.qty, decimals: order.qty >= 1 ? 2 : 4),
    filled: '$fillPercent%',
    time: formatOrderTime(order.createdTime),
    status: order.orderStatus,
  );
}

/// Formats a Bybit epoch-millis timestamp string into `HH:mm` (UTC) for
/// deterministic display. Returns `null` when the input is missing or invalid.
String? formatOrderTime(String? createdTimeMs) {
  if (createdTimeMs == null || createdTimeMs.isEmpty) return null;
  final ms = int.tryParse(createdTimeMs);
  if (ms == null) return null;
  final dt = DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
  final hour = dt.hour.toString().padLeft(2, '0');
  final minute = dt.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

/// Provider that exposes real Bybit open orders and order history.
///
/// When credentials are missing ([bybitHasCredentialsProvider] is false) the
/// returned [OrdersData] has [OrdersData.needsCredentials] set to true so the
/// screen can render a "Connect API key" state.
final ordersProvider = FutureProvider<OrdersData>((ref) async {
  if (!ref.watch(bybitHasCredentialsProvider)) {
    return OrdersData.needsCredentials();
  }

  final client = ref.watch(bybitAccountClientProvider);

  final openResult = await client.getOpenOrders();
  final openOrders = switch (openResult) {
    Success(value: final orders) => orders.map(accountOrderToOrder).toList(),
    Err(failure: final f) => throw Exception(f.message),
  };

  final historyResult = await client.getOrderHistory();
  final historyOrders = switch (historyResult) {
    Success(value: final orders) => orders.map(accountOrderToOrder).toList(),
    Err(failure: final f) => throw Exception(f.message),
  };

  return OrdersData(openOrders: openOrders, historyOrders: historyOrders);
});
