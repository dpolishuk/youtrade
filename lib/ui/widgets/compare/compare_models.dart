import 'dart:math';

import 'package:flutter/material.dart';

/// A symbol available for comparison.
@immutable
class CompareSymbol {
  const CompareSymbol({
    required this.symbol,
    required this.color,
    required this.basePrice,
  });

  final String symbol;
  final Color color;
  final double basePrice;
}

/// Normalized series and derived statistics for a single symbol.
@immutable
class CompareSeries {
  const CompareSeries({
    required this.symbol,
    required this.prices,
    required this.normalized,
    required this.totalReturn,
    required this.volatility,
  });

  final CompareSymbol symbol;
  final List<double> prices;
  final List<double> normalized;
  final double totalReturn;
  final double volatility;
}

/// Available comparison time ranges and the number of data points each uses.
enum CompareTimeRange {
  oneDay('1D', 24),
  oneWeek('1W', 7),
  oneMonth('1M', 30),
  threeMonths('3M', 90),
  oneYear('1Y', 252);

  const CompareTimeRange(this.label, this.pointCount);

  final String label;
  final int pointCount;
}

/// Static palette for the comparison symbols.
const compareSymbols = [
  CompareSymbol(symbol: 'BTC', color: Color(0xFFF7931A), basePrice: 100000),
  CompareSymbol(symbol: 'ETH', color: Color(0xFF627EEA), basePrice: 5000),
  CompareSymbol(symbol: 'SOL', color: Color(0xFF14F195), basePrice: 200),
  CompareSymbol(symbol: 'XRP', color: Color(0xFFFF4D4D), basePrice: 1),
];

/// Generates deterministic mock series for the selected symbols.
List<CompareSeries> generateCompareSeries(
  List<CompareSymbol> symbols,
  int pointCount,
) {
  return symbols
      .map((symbol) => _generateForSymbol(symbol, pointCount))
      .toList();
}

CompareSeries _generateForSymbol(CompareSymbol symbol, int pointCount) {
  final random = Random(symbol.symbol.hashCode + pointCount);
  final prices = <double>[];
  var price = symbol.basePrice;

  for (var i = 0; i < pointCount; i++) {
    prices.add(price);
    final drift = (random.nextDouble() - 0.47) * 0.08;
    price *= 1 + drift;
  }

  final first = prices.first;
  final normalized = prices.map((p) => (p / first - 1) * 100).toList();

  final dailyReturns = <double>[];
  for (var i = 1; i < prices.length; i++) {
    dailyReturns.add(prices[i] / prices[i - 1] - 1);
  }

  final meanReturn = dailyReturns.isEmpty
      ? 0.0
      : dailyReturns.reduce((a, b) => a + b) / dailyReturns.length;
  final variance = dailyReturns.isEmpty
      ? 0.0
      : dailyReturns
                .map((r) => pow(r - meanReturn, 2) as double)
                .reduce((a, b) => a + b) /
            dailyReturns.length;

  return CompareSeries(
    symbol: symbol,
    prices: prices,
    normalized: normalized,
    totalReturn: (prices.last / first - 1) * 100,
    volatility: sqrt(variance) * 100,
  );
}

/// Pearson correlation between the daily returns of two series.
double correlation(CompareSeries a, CompareSeries b) {
  final returnsA = _dailyReturns(a.prices);
  final returnsB = _dailyReturns(b.prices);

  if (returnsA.length != returnsB.length || returnsA.isEmpty) return 0;

  final meanA = returnsA.reduce((x, y) => x + y) / returnsA.length;
  final meanB = returnsB.reduce((x, y) => x + y) / returnsB.length;

  var numerator = 0.0;
  var denomA = 0.0;
  var denomB = 0.0;

  for (var i = 0; i < returnsA.length; i++) {
    final da = returnsA[i] - meanA;
    final db = returnsB[i] - meanB;
    numerator += da * db;
    denomA += da * da;
    denomB += db * db;
  }

  final denominator = sqrt(denomA * denomB);
  return denominator == 0 ? 0 : numerator / denominator;
}

List<double> _dailyReturns(List<double> prices) {
  final returns = <double>[];
  for (var i = 1; i < prices.length; i++) {
    returns.add(prices[i] / prices[i - 1] - 1);
  }
  return returns;
}

/// Ratio of the last prices of two series.
double priceRatio(CompareSeries a, CompareSeries b) {
  return b.prices.last == 0 ? 0 : a.prices.last / b.prices.last;
}
