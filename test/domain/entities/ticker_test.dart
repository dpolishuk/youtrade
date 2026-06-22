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

    test('negative spread is computed when ask is below bid', () {
      final ticker = Ticker(
        symbol: symbol,
        lastPrice: 100.0,
        bid: 100.5,
        ask: 99.5,
        change24h: 0.0,
        change24hPercent: 0.0,
        volume: 0.0,
        timestamp: DateTime(2026, 6, 21, 12, 0),
      );
      expect(ticker.spread, -1.0);
    });

    test('zero spread is computed when ask equals bid', () {
      final ticker = Ticker(
        symbol: symbol,
        lastPrice: 100.0,
        bid: 100.0,
        ask: 100.0,
        change24h: 0.0,
        change24hPercent: 0.0,
        volume: 0.0,
        timestamp: DateTime(2026, 6, 21, 12, 0),
      );
      expect(ticker.spread, 0.0);
    });

    test('rejects NaN prices to prevent corrupt ticker data propagating', () {
      expect(
        () => Ticker(
          symbol: symbol,
          lastPrice: double.nan,
          bid: 99.0,
          ask: 101.0,
          change24h: 0.0,
          change24hPercent: 0.0,
          volume: 0.0,
          timestamp: DateTime(2026, 6, 21, 12, 0),
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => Ticker(
          symbol: symbol,
          lastPrice: 100.0,
          bid: double.nan,
          ask: 101.0,
          change24h: 0.0,
          change24hPercent: 0.0,
          volume: 0.0,
          timestamp: DateTime(2026, 6, 21, 12, 0),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test(
      'rejects infinite prices to prevent corrupt ticker data propagating',
      () {
        expect(
          () => Ticker(
            symbol: symbol,
            lastPrice: double.infinity,
            bid: 99.0,
            ask: 101.0,
            change24h: 0.0,
            change24hPercent: 0.0,
            volume: 0.0,
            timestamp: DateTime(2026, 6, 21, 12, 0),
          ),
          throwsA(isA<ArgumentError>()),
        );
        expect(
          () => Ticker(
            symbol: symbol,
            lastPrice: double.negativeInfinity,
            bid: 99.0,
            ask: 101.0,
            change24h: 0.0,
            change24hPercent: 0.0,
            volume: 0.0,
            timestamp: DateTime(2026, 6, 21, 12, 0),
          ),
          throwsA(isA<ArgumentError>()),
        );
      },
    );

    test(
      'equality treats same instant as equal regardless of timezone flag',
      () {
        final utc = Ticker(
          symbol: symbol,
          lastPrice: 100.0,
          bid: 99.0,
          ask: 101.0,
          change24h: 0.0,
          change24hPercent: 0.0,
          volume: 0.0,
          timestamp: DateTime.utc(2026, 6, 21, 12, 0),
        );
        final parsed = Ticker(
          symbol: symbol,
          lastPrice: 100.0,
          bid: 99.0,
          ask: 101.0,
          change24h: 0.0,
          change24hPercent: 0.0,
          volume: 0.0,
          timestamp: DateTime.parse('2026-06-21T08:00:00-04:00'),
        );
        expect(utc, parsed);
      },
    );

    test(
      'equality distinguishes different instants even when wall clock matches',
      () {
        final utcNoon = Ticker(
          symbol: symbol,
          lastPrice: 100.0,
          bid: 99.0,
          ask: 101.0,
          change24h: 0.0,
          change24hPercent: 0.0,
          volume: 0.0,
          timestamp: DateTime.utc(2026, 6, 21, 12, 0),
        );
        final offsetNoon = Ticker(
          symbol: symbol,
          lastPrice: 100.0,
          bid: 99.0,
          ask: 101.0,
          change24h: 0.0,
          change24hPercent: 0.0,
          volume: 0.0,
          timestamp: DateTime.parse('2026-06-21T12:00:00-04:00'),
        );
        expect(utcNoon, isNot(equals(offsetNoon)));
      },
    );
  });
}
