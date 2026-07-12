import 'dart:math';

/// Adds comma separators to an integer (e.g. 1234567 -> 1,234,567).
String addCommas(int value) {
  return value.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (match) => ',',
  );
}

/// Formats a number with comma separators and the given decimal count.
String formatNumber(double value, {int decimals = 2}) {
  final isNegative = value < 0;
  final abs = value.abs();
  final scaled = (abs * pow(10, decimals)).round();
  final whole = scaled ~/ pow(10, decimals);
  final wholeFormatted = addCommas(whole);
  if (decimals == 0) {
    return '${isNegative ? '-' : ''}$wholeFormatted';
  }
  final frac = (scaled % pow(10, decimals).toInt()).toString().padLeft(
    decimals,
    '0',
  );
  return '${isNegative ? '-' : ''}$wholeFormatted.$frac';
}

/// Formats a USD amount with comma separators and the given decimal count.
String formatMoney(double value, {required int decimals}) {
  final sign = value < 0 ? '-' : '';
  return '$sign\$${formatNumber(value.abs(), decimals: decimals)}';
}

/// Formats a USD amount with two decimal places.
String formatCurrency(double value) => formatMoney(value, decimals: 2);

/// Formats a USD amount with no decimal places.
String formatCompactMoney(double value) => formatMoney(value, decimals: 0);
