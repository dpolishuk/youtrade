import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../../domain/entities/candle.dart';
import '../../../domain/entities/order_book.dart';
import '../../../domain/entities/position.dart';
import '../../../domain/entities/symbol.dart';
import '../../../domain/entities/ticker.dart';
import '../../../domain/entities/timeframe.dart';
import '../../../domain/entities/trade.dart';
import '../../../domain/entities/venue.dart';

/// Deterministic replacement for [MockMarketDataStore].
///
/// Uses the same Park-Miller PRNG and `series()` algorithm as
/// `mockups/YouTrade.dc.html` so every returned value matches the mockup
/// exactly. The public API is identical to [MockMarketDataStore]; existing
/// tests for that class continue to pass unchanged.
final class DeterministicMarketDataStore {
  const DeterministicMarketDataStore();

  static const int _modulus = 2147483647;
  static const int _multiplier = 16807;

  /// Park-Miller RNG closure for an integer seed.
  ///
  /// The mockup always passes integer seeds (e.g. `7`, `sym.length*31+7`),
  /// so this takes an int directly rather than hashing an arbitrary object.
  static double Function() _rng(int seed) {
    var state = seed % _modulus;
    if (state <= 0) state += _modulus - 1;
    return () {
      state = (state * _multiplier) % _modulus;
      return state / _modulus;
    };
  }

  /// Generates an OHLCV series matching the mockup's `series()` function.
  static List<_RawCandle> _series(
    int seed,
    int n,
    double start,
    double vol,
    double drift,
  ) {
    final r = _rng(seed);
    final out = <_RawCandle>[];
    var px = start;
    for (var i = 0; i < n; i++) {
      final open = px;
      final ch = (r() - 0.5) * vol * 2 + drift;
      final close = max(open * (1 + ch), open * 0.5);
      final high = max(open, close) * (1 + r() * vol * 0.6);
      final low = min(open, close) * (1 - r() * vol * 0.6);
      final volume = (0.4 + r()) * (0.6 + ch.abs() * 30);
      out.add(
        _RawCandle(
          open: open,
          high: high,
          low: low,
          close: close,
          volume: volume,
        ),
      );
      px = close;
    }
    return out;
  }

  static final Map<String, List<_RawCandle>> _candles = {
    'BTCUSDT': _series(7, 120, 58000, 0.018, 0.0016),
    'ETHUSDT': _series(13, 120, 2950, 0.022, 0.0012),
    'SOLUSDT': _series(29, 120, 168, 0.03, 0.0021),
    'AAPL': _series(41, 120, 224, 0.012, 0.0008),
    'GC=F': _series(53, 120, 2620, 0.008, 0.0006),
  };

  static final List<double> _equityCurve = () {
    final r = _rng(99);
    final eq = <double>[];
    var v = 820000.0;
    for (var i = 0; i < 90; i++) {
      v *= 1 + (r() - 0.46) * 0.02;
      eq.add(v);
    }
    return eq;
  }();

  /// Extracted portfolio net worth: sum of the four venue balances.
  static const double portfolioNetWorth = 746240.0;

  /// Extracted 24h delta amount.
  static const double portfolio24hDelta = 14820.0;

  /// Extracted 24h delta percentage.
  static const String portfolio24hDeltaPct = '+2.04%';

  /// Full deterministic equity curve used by the Portfolio screen.
  static List<double> get equityCurve => List.unmodifiable(_equityCurve);

  /// First point of the mockup equity curve.
  static double get firstEquityCurvePoint => _equityCurve.first;

  /// Portfolio allocation percentages and colors by venue.
  static const Map<Venue, ({double share, Color color, Color tint})>
  portfolioAllocation = {
    Venue.binance: (
      share: 41.9,
      color: Color(0xFFF0B90B),
      tint: Color(0x24F0B90B),
    ),
    Venue.bybit: (
      share: 26.6,
      color: Color(0xFFF7A600),
      tint: Color(0x24F7A600),
    ),
    Venue.okx: (share: 19.7, color: Color(0xFF00E6D2), tint: Color(0x2800E6D2)),
    Venue.coinbase: (
      share: 11.9,
      color: Color(0xFF0052FF),
      tint: Color(0x240052FF),
    ),
  };

  /// Exchange balances and 24h percent changes shown on the Portfolio screen.
  static const Map<Venue, ({double value, double percentChange})>
  portfolioExchanges = {
    Venue.binance: (value: 312480.0, percentChange: 2.14),
    Venue.bybit: (value: 198320.0, percentChange: -0.86),
    Venue.okx: (value: 146900.0, percentChange: 1.42),
    Venue.coinbase: (value: 88540.0, percentChange: 0.31),
  };

  /// Static position data matching the mockup Portfolio screen.
  static const List<Position> portfolioPositions = [
    Position(
      symbol: 'BTCUSDT',
      sym0: '฿',
      side: 'LONG',
      venue: 'Binance Perp',
      qty: '1.84 BTC',
      value: '\$107,320',
      pnl: '+\$4,210',
      tint: Color(0x24F7931A),
      iconColor: Color(0xFFF7931A),
    ),
    Position(
      symbol: 'ETHUSDT',
      sym0: 'Ξ',
      side: 'LONG',
      venue: 'Bybit Perp',
      qty: '22.5 ETH',
      value: '\$66,375',
      pnl: '-\$820',
      tint: Color(0x28627EEA),
      iconColor: Color(0xFF8B9CF0),
    ),
    Position(
      symbol: 'AAPL',
      sym0: 'A',
      side: 'LONG',
      venue: 'Coinbase',
      qty: '120 sh',
      value: '\$26,880',
      pnl: '+\$312',
      tint: Color(0x2800E6D2),
      iconColor: Color(0xFF00E6D2),
    ),
    Position(
      symbol: 'GC=F',
      sym0: 'Au',
      side: 'SHORT',
      venue: 'OKX Futures',
      qty: '4 lots',
      value: '\$31,200',
      pnl: '+\$680',
      tint: Color(0x28FFC457),
      iconColor: Color(0xFFFFC457),
    ),
  ];

  /// Asset class mix label shown above the allocation bar.
  static const String portfolioAssetMix =
      'Spot 41 · Perp 38 · Eq 12 · Fut 6 · Opt 3';

  /// Last BTC price from the deterministic series.
  static double get btcLastPrice => _candles['BTCUSDT']!.last.close;

  /// First BTC open from the deterministic series.
  static double get btcFirstOpen => _candles['BTCUSDT']!.first.open;

  /// ATM strike for BTC options derived from the deterministic spot price.
  static double get btcOptionsAtmStrike {
    final spot = btcLastPrice;
    return (spot / 2000).round() * 2000.0;
  }

  List<_RawCandle> _rawCandlesFor(TradingSymbol symbol) {
    final key = symbol.rawSymbol;
    return _candles[key] ?? _candles['BTCUSDT']!;
  }

  static String _id(TradingSymbol symbol) => symbol.rawSymbol;

  static double _volumeFor(List<_RawCandle> data, double lastPrice) {
    final vol = data
        .skip(max(0, data.length - 24))
        .fold(0.0, (sum, c) => sum + c.volume);
    return vol * lastPrice / 1e6;
  }

  Future<Ticker> getTicker(TradingSymbol symbol) async {
    final data = _rawCandlesFor(symbol);
    final last = data.last.close;
    final first24 = data.length >= 24
        ? data[data.length - 24].close
        : data.first.close;
    final change = last - first24;
    final changePct = first24 != 0 ? change / first24 * 100 : 0.0;
    return Ticker(
      symbol: symbol,
      lastPrice: last,
      bid: last * 0.9995,
      ask: last * 1.0005,
      change24h: change,
      change24hPercent: changePct,
      volume: _volumeFor(data, last),
      timestamp: _mockTimestamp,
    );
  }

  Future<List<Candle>> getCandles(
    TradingSymbol symbol,
    Timeframe timeframe, {
    int? limit,
  }) async {
    final data = _rawCandlesFor(symbol);
    final count = min(limit ?? data.length, data.length);
    final view = data.sublist(data.length - count);
    final now = _mockTimestamp;
    return view.indexed
        .map(
          (entry) => Candle(
            open: entry.$2.open,
            high: entry.$2.high,
            low: entry.$2.low,
            close: entry.$2.close,
            volume: entry.$2.volume,
            timestamp: now.subtract(
              Duration(seconds: timeframe.seconds * (count - 1 - entry.$1)),
            ),
          ),
        )
        .toList();
  }

  Future<OrderBook> getOrderBook(TradingSymbol symbol, {int? depth}) async {
    final data = _rawCandlesFor(symbol);
    final last = data.last.close;
    final tick = last * 0.0004;
    final levels = depth ?? 9;
    final r = _rng(_id(symbol).length * 31 + 7);

    final asks = <OrderBookLevel>[];
    for (var i = 0; i < levels; i++) {
      final sz = 0.3 + r() * 2.2;
      asks.add(OrderBookLevel(price: last + tick * (i + 1), amount: sz));
    }
    final bids = <OrderBookLevel>[];
    for (var i = 0; i < levels; i++) {
      final sz = 0.3 + r() * 2.2;
      bids.add(OrderBookLevel(price: last - tick * (i + 1), amount: sz));
    }

    return OrderBook(bids: bids, asks: asks, timestamp: _mockTimestamp);
  }

  Future<List<Trade>> getTrades(TradingSymbol symbol, {int? limit}) async {
    final data = _rawCandlesFor(symbol);
    final last = data.last.close;
    final tick = last * 0.0004;
    final count = limit ?? 10;
    final r = _rng(_id(symbol).length * 31 + 7);
    final trades = <Trade>[];
    for (var i = 0; i < count; i++) {
      final up = r() > 0.45;
      final price = last + (r() - 0.5) * tick * 6;
      final size = r() * 1.6 + 0.02;
      trades.add(
        Trade(
          price: price,
          amount: size,
          side: up ? TradeSide.buy : TradeSide.sell,
          timestamp: _mockTimestamp.subtract(Duration(seconds: i)),
          tradeId: 'mock-trade-$i',
        ),
      );
    }
    return trades;
  }

  Stream<Ticker> watchTicker(TradingSymbol symbol) {
    Timer? timer;
    final controller = StreamController<Ticker>(
      onCancel: () => timer?.cancel(),
    );
    timer = Timer.periodic(const Duration(seconds: 1), (_) async {
      controller.add(await getTicker(symbol));
    });
    return controller.stream;
  }

  Stream<OrderBook> watchOrderBook(TradingSymbol symbol) {
    Timer? timer;
    final controller = StreamController<OrderBook>(
      onCancel: () => timer?.cancel(),
    );
    timer = Timer.periodic(const Duration(seconds: 1), (_) async {
      controller.add(await getOrderBook(symbol));
    });
    return controller.stream;
  }

  Stream<List<Trade>> watchTrades(TradingSymbol symbol) {
    Timer? timer;
    final controller = StreamController<List<Trade>>(
      onCancel: () => timer?.cancel(),
    );
    timer = Timer.periodic(const Duration(seconds: 1), (_) async {
      controller.add(await getTrades(symbol));
    });
    return controller.stream;
  }

  /// Fixed UTC timestamp used for all deterministic mock data.
  static final DateTime _mockTimestamp = DateTime.utc(2026, 6, 21, 9, 41, 0);
}

final class _RawCandle {
  const _RawCandle({
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });

  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;
}
