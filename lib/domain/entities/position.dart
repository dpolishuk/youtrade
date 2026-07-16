import 'package:flutter/material.dart';

/// An open trading position displayed in the Positions tab.
@immutable
class Position {
  const Position({
    required this.symbol,
    required this.sym0,
    required this.side,
    required this.venue,
    required this.qty,
    required this.value,
    required this.pnl,
    required this.tint,
    required this.iconColor,
  });

  final String symbol;
  final String sym0;
  final String side;
  final String venue;
  final String qty;
  final String value;
  final String pnl;
  final Color tint;
  final Color iconColor;

  bool get isLong => side == 'LONG';
}
