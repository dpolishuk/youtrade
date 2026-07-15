import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:youtrade/core/screener_score.dart';

void main() {
  group('ScreenerScore.compute', () {
    test('z-score normalization produces scores with mean ~0', () {
      // Only turnover varies; everything else constant so z-scores for
      // those dimensions are zero and L = zScore(logTurnover).
      final tickers = [
        RawTicker(
          symbol: 'A',
          turnover24h: 1e7,
          openInterestValue: 2e6,
          spreadPct: 0.001,
          rangePct: 0.05,
          vwMomentum: 0.5,
          fundingScore: 0.001,
        ),
        RawTicker(
          symbol: 'B',
          turnover24h: 1e9,
          openInterestValue: 2e6,
          spreadPct: 0.001,
          rangePct: 0.05,
          vwMomentum: 0.5,
          fundingScore: 0.001,
        ),
        RawTicker(
          symbol: 'C',
          turnover24h: 1e11,
          openInterestValue: 2e6,
          spreadPct: 0.001,
          rangePct: 0.05,
          vwMomentum: 0.5,
          fundingScore: 0.001,
        ),
      ];

      final scores = ScreenerScore.compute(tickers);
      final sum = scores.values.reduce((a, b) => a + b);

      // Z-scores are mean-centered, so the composite mean is ~0.
      expect(sum, closeTo(0.0, 1e-9));
      // Orders-of-magnitude ranking is preserved.
      expect(scores['C']! > scores['B']!, isTrue);
      expect(scores['B']! > scores['A']!, isTrue);
    });

    test('composite score ranks high-liquidity ticker first', () {
      final tickers = [
        RawTicker(
          symbol: 'LOW',
          turnover24h: 6e6,
          openInterestValue: 2e6,
          spreadPct: 0.001,
          rangePct: 0.02,
          vwMomentum: 0.1,
          fundingScore: 0.0001,
        ),
        RawTicker(
          symbol: 'HIGH',
          turnover24h: 5e9,
          openInterestValue: 50e6,
          spreadPct: 0.0001,
          rangePct: 0.05,
          vwMomentum: 1.0,
          fundingScore: 0.001,
        ),
      ];

      final scores = ScreenerScore.compute(tickers);

      expect(scores['HIGH']! > scores['LOW']!, isTrue);
    });

    test('guard rails filter illiquid tickers', () {
      final tickers = [
        RawTicker(
          symbol: 'ILLIQUID',
          turnover24h: 1e6,
          openInterestValue: 2e6,
          spreadPct: 0.001,
          rangePct: 0.05,
          vwMomentum: 0.5,
          fundingScore: 0.001,
        ),
        RawTicker(
          symbol: 'LIQUID',
          turnover24h: 1e9,
          openInterestValue: 2e6,
          spreadPct: 0.001,
          rangePct: 0.05,
          vwMomentum: 0.5,
          fundingScore: 0.001,
        ),
      ];

      final scores = ScreenerScore.compute(tickers);

      expect(scores.containsKey('ILLIQUID'), isFalse);
      expect(scores.containsKey('LIQUID'), isTrue);
    });

    test('guard rails filter wide-spread tickers', () {
      final tickers = [
        RawTicker(
          symbol: 'WIDESPREAD',
          turnover24h: 1e9,
          openInterestValue: 2e6,
          spreadPct: 0.005,
          rangePct: 0.05,
          vwMomentum: 0.5,
          fundingScore: 0.001,
        ),
        RawTicker(
          symbol: 'TIGHTSPREAD',
          turnover24h: 1e9,
          openInterestValue: 2e6,
          spreadPct: 0.0005,
          rangePct: 0.05,
          vwMomentum: 0.5,
          fundingScore: 0.001,
        ),
      ];

      final scores = ScreenerScore.compute(tickers);

      expect(scores.containsKey('WIDESPREAD'), isFalse);
      expect(scores.containsKey('TIGHTSPREAD'), isTrue);
    });

    test('guard rails filter low open-interest tickers', () {
      final tickers = [
        RawTicker(
          symbol: 'LOWOI',
          turnover24h: 1e9,
          openInterestValue: 5e5,
          spreadPct: 0.001,
          rangePct: 0.05,
          vwMomentum: 0.5,
          fundingScore: 0.001,
        ),
        RawTicker(
          symbol: 'HIGHOI',
          turnover24h: 1e9,
          openInterestValue: 5e7,
          spreadPct: 0.001,
          rangePct: 0.05,
          vwMomentum: 0.5,
          fundingScore: 0.001,
        ),
      ];

      final scores = ScreenerScore.compute(tickers);

      expect(scores.containsKey('LOWOI'), isFalse);
      expect(scores.containsKey('HIGHOI'), isTrue);
    });

    test('volume-weighted momentum gives higher score to higher volume', () {
      // Same turnover/OI/spread/range/funding; only vwMomentum differs.
      final tickers = [
        RawTicker(
          symbol: 'LOWMOM',
          turnover24h: 1e9,
          openInterestValue: 2e6,
          spreadPct: 0.001,
          rangePct: 0.05,
          vwMomentum: 0.1,
          fundingScore: 0.001,
        ),
        RawTicker(
          symbol: 'HIMOM',
          turnover24h: 1e9,
          openInterestValue: 2e6,
          spreadPct: 0.001,
          rangePct: 0.05,
          vwMomentum: 2.0,
          fundingScore: 0.001,
        ),
      ];

      final scores = ScreenerScore.compute(tickers);

      expect(scores['HIMOM']! > scores['LOWMOM']!, isTrue);
    });

    test(
      'funding score direction rewards positive funding with positive price',
      () {
        final tickers = [
          RawTicker(
            symbol: 'NEG',
            turnover24h: 1e9,
            openInterestValue: 2e6,
            spreadPct: 0.001,
            rangePct: 0.05,
            vwMomentum: 0.5,
            fundingScore: -0.002,
          ),
          RawTicker(
            symbol: 'POS',
            turnover24h: 1e9,
            openInterestValue: 2e6,
            spreadPct: 0.001,
            rangePct: 0.05,
            vwMomentum: 0.5,
            fundingScore: 0.002,
          ),
        ];

        final scores = ScreenerScore.compute(tickers);

        expect(scores['POS']! > scores['NEG']!, isTrue);
      },
    );

    test('empty list returns empty map', () {
      expect(ScreenerScore.compute([]), isEmpty);
    });

    test('single ticker returns zero z-score', () {
      final tickers = [
        RawTicker(
          symbol: 'SOLO',
          turnover24h: 1e9,
          openInterestValue: 2e6,
          spreadPct: 0.001,
          rangePct: 0.05,
          vwMomentum: 0.5,
          fundingScore: 0.001,
        ),
      ];

      final scores = ScreenerScore.compute(tickers);

      expect(scores['SOLO'], 0.0);
    });
  });

  group('RawTicker.fromBybitTicker', () {
    test('parses all fields from Bybit ticker JSON', () {
      final t = RawTicker.fromBybitTicker({
        'symbol': 'BTCUSDT',
        'turnover24h': '5000000000.0',
        'openInterestValue': '50000000.0',
        'bid1Price': '64999.0',
        'ask1Price': '65001.0',
        'highPrice24h': '66000.0',
        'lowPrice24h': '64000.0',
        'prevPrice24h': '65000.0',
        'price24hPcnt': '0.05',
        'fundingRate': '0.0001',
      });

      expect(t.symbol, 'BTCUSDT');
      expect(t.turnover24h, 5e9);
      expect(t.openInterestValue, 5e7);
      expect(t.spreadPct, closeTo((65001 - 64999) / 65000, 1e-9));
      expect(t.rangePct, closeTo((66000 - 64000) / 65000, 1e-9));
      expect(t.vwMomentum, closeTo(0.05 * log(5e9), 1e-6));
      expect(t.fundingScore, closeTo(0.0001, 1e-9));
    });

    test('funding score is negative when price is down', () {
      final t = RawTicker.fromBybitTicker({
        'symbol': 'ETHUSDT',
        'turnover24h': '1000000000.0',
        'openInterestValue': '20000000.0',
        'bid1Price': '3199.0',
        'ask1Price': '3201.0',
        'highPrice24h': '3300.0',
        'lowPrice24h': '3100.0',
        'prevPrice24h': '3200.0',
        'price24hPcnt': '-0.02',
        'fundingRate': '0.0001',
      });

      expect(t.fundingScore, closeTo(-0.0001, 1e-9));
    });

    test('defaults to safe values when fields are missing', () {
      final t = RawTicker.fromBybitTicker(<String, dynamic>{});

      expect(t.symbol, '');
      expect(t.turnover24h, 0.0);
      expect(t.spreadPct, 1.0);
    });
  });
}
