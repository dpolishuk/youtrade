import 'package:flutter/material.dart';

import 'exchange_balance.dart';

@immutable
class ExchangeDetailSnapshot {
  const ExchangeDetailSnapshot({
    required this.total,
    required this.pnl,
    required this.pnlPercent,
    required this.kinds,
    required this.color,
    required this.assets,
  });

  final String total;
  final String pnl;
  final String pnlPercent;
  final String kinds;
  final Color color;
  final List<ExchangeBalance> assets;
}
