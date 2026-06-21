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

    test('rejects internal whitespace in base or quote', () {
      expect(
        () =>
            TradingSymbol(base: 'BTC USD', quote: 'USDT', venue: Venue.binance),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => TradingSymbol(base: 'BTC', quote: 'US DT', venue: Venue.binance),
        throwsA(isA<ArgumentError>()),
      );
    });

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

    test('normalizes unicode base and quote without corruption', () {
      final symbol = TradingSymbol(
        base: '日本語',
        quote: '韩元',
        venue: Venue.binance,
      );
      expect(symbol.base, '日本語');
      expect(symbol.quote, '韩元');
      expect(symbol.id, '日本語/韩元');
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

    test('handles very long base and quote without truncation', () {
      final longBase = 'A' * 1000;
      final longQuote = 'B' * 1000;
      final symbol = TradingSymbol(
        base: longBase,
        quote: longQuote,
        venue: Venue.binance,
      );
      expect(symbol.base, longBase);
      expect(symbol.quote, longQuote);
      expect(symbol.base.length, 1000);
      expect(symbol.quote.length, 1000);
      expect(symbol.id, '$longBase/$longQuote');
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
