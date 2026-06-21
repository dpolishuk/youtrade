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

    test('rejects empty or whitespace base/quote', () {
      expect(
        () => TradingSymbol(base: '', quote: 'USDT', venue: Venue.binance),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => TradingSymbol(base: 'BTC ', quote: 'USDT', venue: Venue.binance),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => TradingSymbol(base: 'BTC', quote: ' USDT', venue: Venue.binance),
        throwsA(isA<AssertionError>()),
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
  });
}
