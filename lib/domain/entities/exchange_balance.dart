import 'package:flutter/material.dart';

@immutable
class ExchangeBalance {
  const ExchangeBalance({
    required this.symbol,
    required this.glyph,
    required this.valueFormatted,
    required this.sharePercent,
    required this.shareColor,
  });

  final String symbol;
  final String glyph;
  final String valueFormatted;
  final int sharePercent;
  final Color shareColor;
}
