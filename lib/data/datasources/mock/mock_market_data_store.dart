import 'dart:math';

import '../../../domain/entities/candle.dart';
import '../../../domain/entities/order_book.dart';
import '../../../domain/entities/symbol.dart';
import '../../../domain/entities/ticker.dart';
import '../../../domain/entities/timeframe.dart';
import '../../../domain/entities/trade.dart';

final class MockMarketDataStore {
  MockMarketDataStore({Random? random}) : _random = random ?? Random(42);

  final Random _random;

  double _seedPrice(TradingSymbol symbol) {
    final hash = symbol.id.hashCode.abs() % 100000;
    return (hash + 10000).toDouble();
  }

  double _jitter(double price) {
    return price * (1 + (_random.nextDouble() - 0.5) * 0.02);
  }

  Future<Ticker> getTicker(TradingSymbol symbol) async {
    final lastPrice = _jitter(_seedPrice(symbol));
    final bid = lastPrice * 0.9995;
    final ask = lastPrice * 1.0005;
    return Ticker(
      symbol: symbol,
      lastPrice: lastPrice,
      bid: bid,
      ask: ask,
      change24h: lastPrice * 0.01 * (_random.nextDouble() - 0.5),
      change24hPercent: 0.01 * (_random.nextDouble() - 0.5),
      volume: lastPrice * 1000 * _random.nextDouble(),
      timestamp: DateTime.now().toUtc(),
    );
  }

  Future<List<Candle>> getCandles(
    TradingSymbol symbol,
    Timeframe timeframe, {
    int? limit,
  }) async {
    final count = limit ?? 100;
    final basePrice = _seedPrice(symbol);
    final candles = <Candle>[];
    var price = basePrice;
    final now = DateTime.now().toUtc();
    for (var i = count - 1; i >= 0; i--) {
      final open = price;
      final close = _jitter(open);
      final high = open > close
          ? open * (1 + _random.nextDouble() * 0.01)
          : close * (1 + _random.nextDouble() * 0.01);
      final low = open < close
          ? open * (1 - _random.nextDouble() * 0.01)
          : close * (1 - _random.nextDouble() * 0.01);
      price = close;
      candles.add(
        Candle(
          open: open,
          high: high,
          low: low,
          close: close,
          volume: basePrice * 100 * _random.nextDouble(),
          timestamp: now.subtract(Duration(seconds: timeframe.seconds * i)),
        ),
      );
    }
    return candles.reversed.toList();
  }

  Future<OrderBook> getOrderBook(TradingSymbol symbol, {int? depth}) async {
    final levels = depth ?? 10;
    final midPrice = _jitter(_seedPrice(symbol));
    final bids = <OrderBookLevel>[];
    final asks = <OrderBookLevel>[];
    for (var i = 0; i < levels; i++) {
      bids.add(
        OrderBookLevel(
          price: midPrice * (1 - 0.001 * (i + 1)),
          amount: 0.1 + _random.nextDouble() * 10,
        ),
      );
      asks.add(
        OrderBookLevel(
          price: midPrice * (1 + 0.001 * (i + 1)),
          amount: 0.1 + _random.nextDouble() * 10,
        ),
      );
    }
    return OrderBook(bids: bids, asks: asks, timestamp: DateTime.now().toUtc());
  }

  Future<List<Trade>> getTrades(TradingSymbol symbol, {int? limit}) async {
    final count = limit ?? 20;
    final basePrice = _seedPrice(symbol);
    final trades = <Trade>[];
    final now = DateTime.now().toUtc();
    for (var i = 0; i < count; i++) {
      trades.add(
        Trade(
          price: _jitter(basePrice),
          amount: 0.01 + _random.nextDouble() * 5,
          side: _random.nextBool() ? TradeSide.buy : TradeSide.sell,
          timestamp: now.subtract(Duration(seconds: i)),
          tradeId: 'mock-trade-$i',
        ),
      );
    }
    return trades;
  }

  Stream<Ticker> watchTicker(TradingSymbol symbol) async* {
    while (true) {
      await Future.delayed(const Duration(seconds: 1));
      yield await getTicker(symbol);
    }
  }

  Stream<OrderBook> watchOrderBook(TradingSymbol symbol) async* {
    while (true) {
      await Future.delayed(const Duration(seconds: 1));
      yield await getOrderBook(symbol);
    }
  }

  Stream<List<Trade>> watchTrades(TradingSymbol symbol) async* {
    while (true) {
      await Future.delayed(const Duration(seconds: 1));
      yield await getTrades(symbol);
    }
  }
}
