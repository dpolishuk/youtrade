import 'dart:math';

/// Formats a price-like number with grouping and a sensible number of decimals.
String formatPrice(num value, {int maxDecimals = 4}) {
  final abs = value.abs();
  final decimals = abs >= 1000
      ? 2
      : abs >= 1
      ? maxDecimals
      : abs >= 0.01
      ? 4
      : 6;

  return _formatNumber(value, decimals);
}

/// Formats a chart axis value: no decimals above 1000, one decimal 100-999,
/// two decimals below 100. Matches the mockup's `axisNum()`.
String formatAxisNumber(num value) {
  final abs = value.abs();
  if (abs >= 1000) return _formatNumber(value.round(), 0);
  if (abs >= 100) return _formatNumber(value, 1);
  return _formatNumber(value, 2);
}

/// Formats a mockup-style price with a fixed decimal count and grouping.
String formatFixedPrice(num value, int decimals) {
  return _formatNumber(value, decimals);
}

/// Formats a price with dynamic decimal places chosen to always reveal at
/// least four significant digits, regardless of magnitude.
///
/// Examples:
///   64708.60    -> "64,708.60"
///   1.2345      -> "1.2345"
///   0.0006789   -> "0.000679"
///   0.000012345 -> "0.00001235"
String formatPriceSmart(num value) {
  final abs = value.abs().toDouble();
  final decimals = _smartDecimals(abs);
  return _formatNumber(value, decimals);
}

int _smartDecimals(double abs) {
  if (abs == 0) return 2;
  if (abs >= 1000) return 2;
  if (abs >= 1) return 4;
  if (abs >= 0.01) return 4;
  if (abs >= 0.0001) return 6;
  if (abs >= 0.000001) return 8;
  if (abs >= 0.00000001) return 10;
  return 12;
}

/// Formats a large quantity / volume compactly (e.g. 1.2K, 3.4M).
String formatCompact(num value) {
  final abs = value.abs();
  if (abs >= 1e9) {
    return '${(value / 1e9).toStringAsFixed(2)}B';
  }
  if (abs >= 1e6) {
    return '${(value / 1e6).toStringAsFixed(2)}M';
  }
  if (abs >= 1e3) {
    return '${(value / 1e3).toStringAsFixed(2)}K';
  }
  return value.toStringAsFixed(2);
}

/// Formats a percentage change with two decimals and a leading sign.
String formatPercent(num value) {
  final sign = value >= 0 ? '+' : '';
  return '$sign${value.toStringAsFixed(2)}%';
}

String _formatNumber(num value, int decimals) {
  if (decimals == 0) {
    final rounded = value.round();
    return _groupInteger(rounded.toString());
  }
  final rounded = (value * pow(10, decimals)).round() / pow(10, decimals);
  final parts = rounded.toStringAsFixed(decimals).split('.');
  final integerPart = parts[0];
  final fractionalPart = parts[1];

  return '${_groupInteger(integerPart)}.$fractionalPart';
}

String _groupInteger(String integerPart) {
  final buffer = StringBuffer();
  var count = 0;
  for (var i = integerPart.length - 1; i >= 0; i--) {
    buffer.write(integerPart[i]);
    count++;
    if (i != 0 && count % 3 == 0) {
      buffer.write(',');
    }
  }
  return buffer.toString().split('').reversed.join();
}
