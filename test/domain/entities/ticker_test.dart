import 'package:flutter_test/flutter_test.dart';
import 'package:youtrade/domain/entities/symbol.dart';
import 'package:youtrade/domain/entities/ticker.dart';
import 'package:youtrade/domain/entities/venue.dart';

void main() {
  group('Ticker', () {
    final symbol = TradingSymbol(
      base: 'BTC',
      quote: 'USDT',
      venue: Venue.binance,
      rawSymbol: 'BTCUSDT',
    );

    test('spread is computed as ask minus bid', () {
      final ticker = Ticker(
        symbol: symbol,
        lastPrice: 100.0,
        bid: 99.5,
        ask: 100.5,
        change24h: 1.0,
        change24hPercent: 0.01,
        volume: 1000.0,
        timestamp: DateTime(2026, 6, 21, 12, 0),
      );
      expect(ticker.spread, 1.0);
    });

    test('tickers with same values are equal', () {
      final a = Ticker(
        symbol: symbol,
        lastPrice: 100.0,
        bid: 99.0,
        ask: 101.0,
        change24h: 0.0,
        change24hPercent: 0.0,
        volume: 0.0,
        timestamp: DateTime(2026, 6, 21, 12, 0),
      );
      final b = Ticker(
        symbol: symbol,
        lastPrice: 100.0,
        bid: 99.0,
        ask: 101.0,
        change24h: 0.0,
        change24hPercent: 0.0,
        volume: 0.0,
        timestamp: DateTime(2026, 6, 21, 12, 0),
      );
      expect(a, b);
    });

    test('tickers with different timestamps are not equal', () {
      final a = Ticker(
        symbol: symbol,
        lastPrice: 100.0,
        bid: 99.0,
        ask: 101.0,
        change24h: 0.0,
        change24hPercent: 0.0,
        volume: 0.0,
        timestamp: DateTime(2026, 6, 21, 12, 0),
      );
      final b = Ticker(
        symbol: symbol,
        lastPrice: 100.0,
        bid: 99.0,
        ask: 101.0,
        change24h: 0.0,
        change24hPercent: 0.0,
        volume: 0.0,
        timestamp: DateTime(2026, 6, 21, 12, 1),
      );
      expect(a, isNot(equals(b)));
    });
  });
}
