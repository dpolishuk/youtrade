import 'package:flutter_test/flutter_test.dart';
import 'package:youtrade/domain/entities/symbol.dart';
import 'package:youtrade/domain/entities/venue.dart';

void main() {
  group('TradingSymbol', () {
    test('normalizes lowercase input to uppercase', () {
      final symbol = TradingSymbol(
        base: 'btc',
        quote: 'usdt',
        venue: Venue.binance,
        rawSymbol: 'BTCUSDT',
      );
      expect(symbol.id, 'BTC/USDT');
      expect(symbol.base, 'BTC');
      expect(symbol.quote, 'USDT');
    });

    test('rejects empty or whitespace-only base/quote after trim', () {
      expect(
        () => TradingSymbol(base: '', quote: 'USDT', venue: Venue.binance),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => TradingSymbol(base: '   ', quote: 'USDT', venue: Venue.binance),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => TradingSymbol(base: 'BTC', quote: '  ', venue: Venue.binance),
        throwsA(isA<ArgumentError>()),
      );
    });

    test(
      'rejects base or quote containing characters outside the allowlist',
      () {
        expect(
          () => TradingSymbol(
            base: 'BTC USD',
            quote: 'USDT',
            venue: Venue.binance,
          ),
          throwsA(isA<ArgumentError>()),
        );
        expect(
          () =>
              TradingSymbol(base: 'BTC', quote: 'US DT', venue: Venue.binance),
          throwsA(isA<ArgumentError>()),
        );
        expect(
          () => TradingSymbol(base: '日本語', quote: 'USDT', venue: Venue.binance),
          throwsA(isA<ArgumentError>()),
        );
        expect(
          () => TradingSymbol(base: 'BTC', quote: '韩元', venue: Venue.binance),
          throwsA(isA<ArgumentError>()),
        );
        expect(
          () =>
              TradingSymbol(base: 'BTC!', quote: 'USDT', venue: Venue.binance),
          throwsA(isA<ArgumentError>()),
        );
      },
    );

    test('preserves exchange-specific raw symbol', () {
      final coinbase = TradingSymbol(
        base: 'BTC',
        quote: 'USDT',
        venue: Venue.coinbase,
        rawSymbol: 'BTC-USDT',
      );
      expect(coinbase.rawSymbol, 'BTC-USDT');
    });

    test('symbols with same id but different venues are not equal', () {
      final binance = TradingSymbol(
        base: 'BTC',
        quote: 'USDT',
        venue: Venue.binance,
        rawSymbol: 'BTCUSDT',
      );
      final coinbase = TradingSymbol(
        base: 'BTC',
        quote: 'USDT',
        venue: Venue.coinbase,
        rawSymbol: 'BTC-USDT',
      );
      expect(binance, isNot(equals(coinbase)));
    });

    test('rejects base or quote longer than 20 characters', () {
      final longBase = 'A' * 21;
      final longQuote = 'B' * 21;
      expect(
        () =>
            TradingSymbol(base: longBase, quote: 'USDT', venue: Venue.binance),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () =>
            TradingSymbol(base: 'BTC', quote: longQuote, venue: Venue.binance),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects null byte in base or quote to prevent malformed symbols', () {
      expect(
        () =>
            TradingSymbol(base: 'BTC\x00', quote: 'USDT', venue: Venue.binance),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () =>
            TradingSymbol(base: 'BTC', quote: 'USD\x00T', venue: Venue.binance),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('trims leading and trailing whitespace before normalizing', () {
      final symbol = TradingSymbol(
        base: '  btc  ',
        quote: '\tusdt\n',
        venue: Venue.binance,
      );
      expect(symbol.base, 'BTC');
      expect(symbol.quote, 'USDT');
      expect(symbol.id, 'BTC/USDT');
    });

    test('supports unknown venue for runtime-unrecognized exchanges', () {
      final symbol = TradingSymbol(
        base: 'BTC',
        quote: 'USDT',
        venue: Venue.unknown,
      );
      expect(symbol.venue, Venue.unknown);
      expect(symbol.venue.displayName, 'Unknown');
      expect(symbol.venue.id, 'unknown');
    });
  });
}
