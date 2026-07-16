import 'package:flutter/material.dart';

/// A trading order displayed in the Open or History tab.
@immutable
class Order {
  const Order({
    required this.symbol,
    required this.side,
    required this.type,
    required this.venue,
    required this.price,
    required this.qty,
    this.filled,
    this.time,
    this.status,
  });

  final String symbol;
  final String side;
  final String type;
  final String venue;
  final String price;
  final String qty;
  final String? filled;
  final String? time;
  final String? status;

  bool get isBuy => side == 'BUY';
}
