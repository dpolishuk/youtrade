import 'dart:math';
import '../../../core/formatting.dart';
import 'dart:async';

import 'package:flutter/material.dart';

import '../../../domain/entities/candle.dart';
import '../../../domain/entities/options_chain_strike.dart';
import '../../../domain/entities/order.dart';
import '../../../domain/entities/order_book.dart';
import '../../../domain/entities/position.dart';
import '../../../domain/entities/symbol.dart';
import '../../../domain/entities/ticker.dart';
import '../../../domain/entities/timeframe.dart';
import '../../../domain/entities/trade.dart';
import '../../../domain/entities/venue.dart';
import '../../../domain/entities/exchange_balance.dart';
import '../../../domain/entities/exchange_detail_snapshot.dart';

import '../../../domain/sources/market_data_store.dart';

/// Deterministic fallback market-data store.
///
/// Uses the same Park-Miller PRNG and `series()` algorithm as
/// `mockups/YouTrade.dc.html` so every returned value matches the mockup
/// exactly. The public API implements [MarketDataStore].
typedef _ExchangeAsset = ({String symbol, double qty, String glyph});

final class DeterministicMarketDataStore implements MarketDataStore {
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
  ///
  /// AAPL is tinted with the current directional [accent] via
  /// [portfolioPositionsFor]; this const fallback preserves the Flux dark
  /// turquoise for tests and callers that do not supply an accent.
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

  /// Returns [portfolioPositions] with AAPL tinted using the directional
  /// [accent] color instead of the hard-coded Flux turquoise.
  static List<Position> portfolioPositionsFor({required Color accent}) {
    return portfolioPositions.map((position) {
      if (position.symbol != 'AAPL') return position;
      return Position(
        symbol: position.symbol,
        sym0: position.sym0,
        side: position.side,
        venue: position.venue,
        qty: position.qty,
        value: position.value,
        pnl: position.pnl,
        tint: accent.withValues(alpha: 0.16),
        iconColor: accent,
      );
    }).toList();
  }

  /// Static open orders matching the mockup Orders & History screen.
  static const List<Order> openOrders = [
    Order(
      symbol: 'BTCUSDT',
      side: 'BUY',
      type: 'Limit',
      venue: 'Binance',
      price: '58,400.0',
      qty: '0.50',
      filled: '0%',
    ),
    Order(
      symbol: 'ETHUSDT',
      side: 'SELL',
      type: 'Stop',
      venue: 'Bybit',
      price: '3,050.00',
      qty: '8.0',
      filled: '0%',
    ),
    Order(
      symbol: 'SOLUSDT',
      side: 'BUY',
      type: 'Limit',
      venue: 'OKX',
      price: '150.00',
      qty: '120',
      filled: '34%',
    ),
    Order(
      symbol: 'AAPL',
      side: 'BUY',
      type: 'Limit',
      venue: 'Coinbase',
      price: '218.00',
      qty: '50',
      filled: '0%',
    ),
  ];

  /// Static history orders matching the mockup Orders & History screen.
  static const List<Order> historyOrders = [
    Order(
      symbol: 'BTCUSDT',
      side: 'BUY',
      type: 'Market',
      venue: 'Binance',
      price: '56,820.0',
      qty: '1.34',
      time: '09:12',
      status: 'Filled',
    ),
    Order(
      symbol: 'GC=F',
      side: 'SELL',
      type: 'Limit',
      venue: 'OKX',
      price: '2,640.0',
      qty: '4',
      time: '08:47',
      status: 'Filled',
    ),
    Order(
      symbol: 'ETHUSDT',
      side: 'BUY',
      type: 'Limit',
      venue: 'Bybit',
      price: '2,910.00',
      qty: '14.5',
      time: '08:30',
      status: 'Filled',
    ),
    Order(
      symbol: 'NVDA',
      side: 'SELL',
      type: 'Market',
      venue: 'Coinbase',
      price: '115.20',
      qty: '40',
      time: 'Yest',
      status: 'Filled',
    ),
    Order(
      symbol: 'SOLUSDT',
      side: 'BUY',
      type: 'Limit',
      venue: 'OKX',
      price: '162.40',
      qty: '60',
      time: 'Yest',
      status: 'Cancelled',
    ),
  ];

  /// Asset class mix label shown above the allocation bar.
  static const String portfolioAssetMix =
      'Spot 41 · Perp 38 · Eq 12 · Fut 6 · Opt 3';

  static const Map<
    Venue,
    ({double total, double pnl, String kinds, List<_ExchangeAsset> assets})
  >
  _exchangeDetails = {
    Venue.binance: (
      total: 312480.0,
      pnl: 6620.0,
      kinds: 'Spot · Perp · Options',
      assets: <_ExchangeAsset>[
        (symbol: 'BTC', qty: 1.84, glyph: '฿'),
        (symbol: 'ETH', qty: 12.4, glyph: 'Ξ'),
        (symbol: 'USDT', qty: 88420.0, glyph: r'$'),
        (symbol: 'SOL', qty: 210.0, glyph: '◎'),
      ],
    ),
    Venue.bybit: (
      total: 198320.0,
      pnl: -1710.0,
      kinds: 'Perp · Spot',
      assets: <_ExchangeAsset>[
        (symbol: 'ETH', qty: 22.5, glyph: 'Ξ'),
        (symbol: 'USDT', qty: 64200.0, glyph: r'$'),
        (symbol: 'BTC', qty: 0.9, glyph: '฿'),
      ],
    ),
    Venue.okx: (
      total: 146900.0,
      pnl: 2080.0,
      kinds: 'Spot · Perp · Options',
      assets: <_ExchangeAsset>[
        (symbol: 'XAU', qty: 12.0, glyph: 'Au'),
        (symbol: 'USDT', qty: 98300.0, glyph: r'$'),
        (symbol: 'SOL', qty: 420.0, glyph: '◎'),
      ],
    ),
    Venue.coinbase: (
      total: 88540.0,
      pnl: 270.0,
      kinds: 'Spot · Stocks',
      assets: <_ExchangeAsset>[
        (symbol: 'AAPL', qty: 120.0, glyph: 'A'),
        (symbol: 'NVDA', qty: 80.0, glyph: 'N'),
        (symbol: 'USD', qty: 32100.0, glyph: r'$'),
      ],
    ),
  };

  static const Map<Venue, Color> _exchangeColors = {
    Venue.binance: Color(0xFFF0B90B),
    Venue.bybit: Color(0xFFF7A600),
    Venue.coinbase: Color(0xFF0052FF),
  };

  /// Returns the deterministic exchange-detail snapshot for [venue].
  ///
  /// OKX is rendered with the current [accent] color because the mockup ties
  /// OKX to the directional accent token.
  static ExchangeDetailSnapshot exchangeDetailFor(
    Venue venue, {
    required Color accent,
  }) {
    final data = _exchangeDetails[venue] ?? _exchangeDetails[Venue.binance]!;
    final total = data.total;
    final pnl = data.pnl;
    final color = venue == Venue.okx
        ? accent
        : _exchangeColors[venue] ?? accent;

    final assets = data.assets.map((asset) {
      final value = _assetValue(asset);
      final share = (value / total * 100).round().clamp(0, 100);
      return ExchangeBalance(
        symbol: asset.symbol,
        glyph: asset.glyph,
        valueFormatted: formatMoney(value, decimals: 0),
        sharePercent: share,
        shareColor: color,
      );
    }).toList();

    final pnlPercent = pnl / total * 100;

    return ExchangeDetailSnapshot(
      total: formatMoney(total, decimals: 0),
      pnl: '${pnl >= 0 ? '+' : ''}${formatMoney(pnl, decimals: 0)}',
      pnlPercent:
          '${pnlPercent >= 0 ? '+' : ''}${pnlPercent.toStringAsFixed(2)}%',
      kinds: data.kinds,
      color: color,
      assets: assets,
    );
  }

  static double _assetValue(_ExchangeAsset asset) {
    if (asset.symbol == 'USDT' || asset.symbol == 'USD') {
      return asset.qty;
    }
    if (asset.symbol == 'BTC') {
      return asset.qty * btcLastPrice;
    }
    if (asset.symbol == 'XAU') {
      return asset.qty * _candles['GC=F']!.last.close;
    }
    if (asset.symbol == 'AAPL') {
      return asset.qty * _candles['AAPL']!.last.close;
    }
    final pair = '${asset.symbol}USDT';
    if (_candles.containsKey(pair)) {
      return asset.qty * _candles[pair]!.last.close;
    }
    return asset.qty * 200.0;
  }

  /// Last BTC price from the deterministic series.
  static double get btcLastPrice => _candles['BTCUSDT']!.last.close;

  /// First BTC open from the deterministic series.
  static double get btcFirstOpen => _candles['BTCUSDT']!.first.open;

  /// ATM strike for BTC options derived from the deterministic spot price.
  static double get btcOptionsAtmStrike {
    final spot = btcLastPrice;
    return (spot / 2000).round() * 2000.0;
  }

  /// Expiration labels shown on the BTC options chain.
  static const List<String> btcOptionExpiries = [
    '26 JUN',
    '25 JUL',
    '29 AUG',
    '26 SEP',
  ];

  /// Deterministic BTC options chain rows matching the mockup exactly.
  static final List<OptionChainStrike> btcOptionsChain = List.unmodifiable(
    _buildBtcOptionsChain(),
  );

  static List<OptionChainStrike> _buildBtcOptionsChain() {
    final spot = btcLastPrice;
    final base = btcOptionsAtmStrike;
    final strikes = <double>[];
    for (var i = -4; i <= 4; i++) {
      strikes.add(base + i * 2000);
    }

    final optR = _rng(7);
    return strikes.map((strike) {
      final callInTheMoney = spot > strike;
      final distance = (spot - strike) / spot;
      final callDelta = (0.5 + distance * 4).clamp(0.02, 0.98);
      final putDelta = callDelta - 1;
      final callMark =
          (spot - strike).clamp(0.0, double.infinity) / spot +
          (0.5 + optR()) * 0.02;
      final putMark =
          (strike - spot).clamp(0.0, double.infinity) / spot +
          (0.5 + optR()) * 0.02;
      final iv = 48 + optR() * 30;
      final isAtm = (strike - base).abs() < 1;

      return OptionChainStrike(
        strike: strike,
        isAtm: isAtm,
        callInTheMoney: callInTheMoney,
        callIv: iv,
        callDelta: callDelta,
        callMark: callMark,
        putIv: iv + 4,
        putDelta: putDelta,
        putMark: putMark,
      );
    }).toList();
  }

  /// Synchronous last price and 24h change for the screener.
  static ({double last, double change24hPercent}) screenerTicker(
    String rawSymbol,
  ) {
    final data = _candles[rawSymbol] ?? _candles['BTCUSDT']!;
    final last = data.last.close;
    final first24 = data.length >= 24
        ? data[data.length - 24].close
        : data.first.close;
    final change = last - first24;
    final changePct = first24 != 0 ? change / first24 * 100 : 0.0;
    return (last: last, change24hPercent: changePct);
  }

  /// Synchronous sparkline closes for the screener.
  static List<double> screenerSparkline(String rawSymbol, {int periods = 30}) {
    final data = _candles[rawSymbol] ?? _candles['BTCUSDT']!;
    final start = max(0, data.length - periods);
    return data.sublist(start).map((c) => c.close).toList();
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

  @override
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

  @override
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

  @override
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

  @override
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

  @override
  Stream<Ticker> watchTicker(TradingSymbol symbol) async* {
    yield await getTicker(symbol);
  }

  @override
  Stream<OrderBook> watchOrderBook(TradingSymbol symbol) async* {
    yield await getOrderBook(symbol);
  }

  @override
  Stream<List<Trade>> watchTrades(TradingSymbol symbol) async* {
    yield await getTrades(symbol);
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
