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
  final rounded = (value * pow(10, decimals)).round() / pow(10, decimals);
  final parts = rounded.toStringAsFixed(decimals).split('.');
  final integerPart = parts[0];
  final fractionalPart = parts[1];

  final buffer = StringBuffer();
  var count = 0;
  for (var i = integerPart.length - 1; i >= 0; i--) {
    buffer.write(integerPart[i]);
    count++;
    if (i != 0 && count % 3 == 0) {
      buffer.write(',');
    }
  }
  final groupedInteger = buffer.toString().split('').reversed.join();

  if (decimals == 0) return groupedInteger;
  return '$groupedInteger.$fractionalPart';
}
