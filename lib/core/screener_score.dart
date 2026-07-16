import 'dart:math';

/// Computes z-score normalized composite screening scores for crypto symbols.
///
/// Fields from the Bybit ticker API span orders of magnitude (turnover can be
/// $5B for BTC vs $50K for a micro-cap). Raw sorting would let magnitude
/// dominate. Z-score normalization places every dimension on a comparable
/// [-3, 3]-ish scale before combining them with explicit weights.
class ScreenerScore {
  /// Day-trader default weights (must sum to 1.0).
  static const double weightLiquidity = 0.40;
  static const double weightVolatility = 0.30;
  static const double weightMomentum = 0.20;
  static const double weightFunding = 0.10;

  /// Guard-rail thresholds. Symbols failing any threshold are excluded so
  /// illiquid or wide-spread coins do not pollute the ranking.
  static const double minTurnover = 5e6; // $5M USDT
  static const double maxSpreadPct = 0.002; // 0.20 %
  static const double minOiValue = 1e6; // $1M USDT

  /// Compute composite scores for a list of raw ticker data.
  ///
  /// Returns a list of composite scores, one per input ticker, preserving
  /// the input order. Tickers that fail the guard rails receive
  /// [double.negativeInfinity] so they always sort below valid scores.
  static List<double> compute(List<RawTicker> tickers) {
    if (tickers.isEmpty) return [];

    // Build parallel arrays: index in original list + tradeable ticker
    final tradeableIndices = <int>[];
    final tradeable = <RawTicker>[];
    for (var i = 0; i < tickers.length; i++) {
      if (_passesGuardRails(tickers[i])) {
        tradeableIndices.add(i);
        tradeable.add(tickers[i]);
      }
    }

    // Initialize all scores to -infinity (guard rail failures)
    final scores = List<double>.filled(tickers.length, double.negativeInfinity);

    if (tradeable.isEmpty) return scores;

    final logTurnovers = tradeable.map((t) => log(t.turnover24h)).toList();
    final logOiValues = tradeable.map((t) => log(t.openInterestValue)).toList();
    final spreads = tradeable.map((t) => t.spreadPct).toList();
    final rangePcts = tradeable.map((t) => t.rangePct).toList();
    final vwMoms = tradeable.map((t) => t.vwMomentum).toList();
    final fundingScores = tradeable.map((t) => t.fundingScore).toList();

    for (var j = 0; j < tradeable.length; j++) {
      final liquidity =
          _zScore(logTurnovers[j], logTurnovers) +
          _zScore(logOiValues[j], logOiValues) -
          _zScore(spreads[j], spreads);
      final volatility = _zScore(rangePcts[j], rangePcts);
      final momentum = _zScore(vwMoms[j], vwMoms);
      final funding = _zScore(fundingScores[j], fundingScores);

      scores[tradeableIndices[j]] =
          weightLiquidity * liquidity +
          weightVolatility * volatility +
          weightMomentum * momentum +
          weightFunding * funding;
    }
    return scores;
  }

  static bool _passesGuardRails(RawTicker t) {
    return t.turnover24h > minTurnover &&
        t.spreadPct < maxSpreadPct &&
        t.openInterestValue > minOiValue;
  }

  /// Population z-score: (value - mean) / std.
  ///
  /// When the standard deviation is effectively zero (all values identical up
  /// to floating-point noise — e.g. `0.05 + 0.05 + 0.05 != 0.15` in IEEE 754),
  /// returns `0` so constant dimensions do not inject spurious signal.
  static double _zScore(double value, List<double> all) {
    if (all.length < 2) return 0;
    final mean = all.reduce((a, b) => a + b) / all.length;
    final variance =
        all.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) / all.length;
    final std = sqrt(variance);
    if (std < 1e-9) return 0;
    return (value - mean) / std;
  }
}

/// Raw ticker data extracted from a Bybit API response, used for scoring.
class RawTicker {
  const RawTicker({
    required this.symbol,
    required this.turnover24h,
    required this.openInterestValue,
    required this.spreadPct,
    required this.rangePct,
    required this.vwMomentum,
    required this.fundingScore,
  });

  final String symbol;
  final double turnover24h;
  final double openInterestValue;
  final double spreadPct; // (ask - bid) / mid
  final double rangePct; // (high - low) / prevPrice24h
  final double vwMomentum; // price24hPcnt * log(turnover24h)
  final double fundingScore; // |fundingRate| * sign(price24hPcnt)

  /// Parses a raw Bybit `/v5/market/tickers` list entry into a [RawTicker].
  factory RawTicker.fromBybitTicker(Map<String, dynamic> ticker) {
    final symbol = ticker['symbol'] as String? ?? '';
    final turnover =
        double.tryParse(ticker['turnover24h'] as String? ?? '') ?? 0.0;
    final oiValue =
        double.tryParse(ticker['openInterestValue'] as String? ?? '') ?? 0.0;
    final bid = double.tryParse(ticker['bid1Price'] as String? ?? '') ?? 0.0;
    final ask = double.tryParse(ticker['ask1Price'] as String? ?? '') ?? 0.0;
    final mid = (bid + ask) / 2;
    final high =
        double.tryParse(ticker['highPrice24h'] as String? ?? '') ?? 0.0;
    final low = double.tryParse(ticker['lowPrice24h'] as String? ?? '') ?? 0.0;
    final prev24h =
        double.tryParse(ticker['prevPrice24h'] as String? ?? '') ?? 0.0;
    final pricePcnt =
        double.tryParse(ticker['price24hPcnt'] as String? ?? '') ?? 0.0;
    final fundingRate =
        double.tryParse(ticker['fundingRate'] as String? ?? '') ?? 0.0;

    return RawTicker(
      symbol: symbol,
      turnover24h: turnover,
      openInterestValue: oiValue,
      spreadPct: mid > 0 ? (ask - bid) / mid : 1.0,
      rangePct: prev24h > 0 ? (high - low) / prev24h : 0.0,
      vwMomentum: turnover > 0 ? pricePcnt * log(turnover) : 0.0,
      fundingScore: fundingRate.abs() * pricePcnt.sign,
    );
  }
}
