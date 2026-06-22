import 'dart:math';

import 'package:flutter/material.dart';

import '../../../data/datasources/mock/deterministic_market_data_store.dart';

/// A symbol available for comparison.
@immutable
class CompareSymbol {
  const CompareSymbol({
    required this.symbol,
    required this.color,
    required this.rawSymbol,
  });

  final String symbol;
  final Color color;
  final String rawSymbol;
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

/// Static palette for the comparison symbols matching the mockup exactly.
const compareSymbols = [
  CompareSymbol(symbol: 'BTC', color: Color(0xFF00E6D2), rawSymbol: 'BTCUSDT'),
  CompareSymbol(symbol: 'ETH', color: Color(0xFFFFB020), rawSymbol: 'ETHUSDT'),
  CompareSymbol(symbol: 'SOL', color: Color(0xFFFF5D77), rawSymbol: 'SOLUSDT'),
  CompareSymbol(symbol: 'AAPL', color: Color(0xFF8B9CF0), rawSymbol: 'AAPL'),
  CompareSymbol(symbol: 'GOLD', color: Color(0xFFC9A6FF), rawSymbol: 'GC=F'),
];

/// Generates deterministic 30-period mock series for the selected symbols.
List<CompareSeries> generateCompareSeries(
  List<CompareSymbol> symbols, {
  int periods = 30,
}) {
  return symbols.map((symbol) => _generateForSymbol(symbol, periods)).toList();
}

CompareSeries _generateForSymbol(CompareSymbol symbol, int periods) {
  final prices = DeterministicMarketDataStore.screenerSparkline(
    symbol.rawSymbol,
    periods: periods,
  );

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
