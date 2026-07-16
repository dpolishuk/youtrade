import 'package:flutter_test/flutter_test.dart';
import 'package:youtrade/domain/entities/symbol.dart';
import 'package:youtrade/domain/entities/symbol_metadata.dart';
import 'package:youtrade/domain/entities/venue.dart';

void main() {
  group('resolveSymbolMetadata', () {
    test('matches known BTCUSDT on Binance', () {
      final meta = resolveSymbolMetadata(
        TradingSymbol(
          base: 'BTC',
          quote: 'USDT',
          venue: Venue.binance,
          rawSymbol: 'BTCUSDT',
        ),
      );

      expect(meta.name, 'Bitcoin Perpetual');
      expect(meta.symbolClass, SymbolClass.perp);
      expect(meta.venue, Venue.binance);
    });

    test('matches known BTCUSDT on Bybit', () {
      final meta = resolveSymbolMetadata(
        TradingSymbol(
          base: 'BTC',
          quote: 'USDT',
          venue: Venue.bybit,
          rawSymbol: 'BTCUSDT',
        ),
      );

      expect(meta.name, 'Bitcoin Perpetual');
      expect(meta.symbolClass, SymbolClass.perp);
      expect(meta.venue, Venue.bybit);
    });

    test('matches known SOLUSDT on Bybit', () {
      final meta = resolveSymbolMetadata(
        TradingSymbol(
          base: 'SOL',
          quote: 'USDT',
          venue: Venue.bybit,
          rawSymbol: 'SOLUSDT',
        ),
      );

      expect(meta.name, 'Solana');
      expect(meta.venue, Venue.bybit);
    });

    test('matches known XRPUSDT on Bybit', () {
      final meta = resolveSymbolMetadata(
        TradingSymbol(
          base: 'XRP',
          quote: 'USDT',
          venue: Venue.bybit,
          rawSymbol: 'XRPUSDT',
        ),
      );

      expect(meta.name, 'XRP');
      expect(meta.venue, Venue.bybit);
    });

    test('matches known ETHUSDT on Bybit', () {
      final meta = resolveSymbolMetadata(
        TradingSymbol(
          base: 'ETH',
          quote: 'USDT',
          venue: Venue.bybit,
          rawSymbol: 'ETHUSDT',
        ),
      );

      expect(meta.name, 'Ethereum Perpetual');
      expect(meta.venue, Venue.bybit);
    });

    test('distinguishes same raw symbol on different venues', () {
      final ethOnBinance = resolveSymbolMetadata(
        TradingSymbol(
          base: 'ETH',
          quote: 'USDT',
          venue: Venue.binance,
          rawSymbol: 'ETHUSDT',
        ),
      );

      expect(ethOnBinance.name, 'ETH');
      expect(ethOnBinance.venue, Venue.binance);
    });

    test('falls back to symbol venue for unknown symbol', () {
      final meta = resolveSymbolMetadata(
        TradingSymbol(
          base: 'UNKNOWN',
          quote: 'USDT',
          venue: Venue.okx,
          rawSymbol: 'UNKNOWNUSDT',
        ),
      );

      expect(meta.name, 'UNKNOWN');
      expect(meta.venue, Venue.okx);
    });

    test('test_unknown_usdt_symbol_gets_correct_base', () {
      final meta = resolveSymbolMetadata(
        TradingSymbol(
          base: 'DOGE',
          quote: 'USDT',
          venue: Venue.bybit,
          rawSymbol: 'DOGEUSDT',
        ),
      );

      expect(meta.base, 'DOGE');
      expect(meta.venue, Venue.bybit);
    });

    test('test_unknown_symbol_gets_perp_class', () {
      final meta = resolveSymbolMetadata(
        TradingSymbol(
          base: 'PEPE',
          quote: 'USDT',
          venue: Venue.bybit,
          rawSymbol: 'PEPEUSDT',
        ),
      );

      expect(meta.symbolClass, SymbolClass.perp);
    });

    test('test_unknown_symbol_decimals_default_to_two', () {
      final meta = resolveSymbolMetadata(
        TradingSymbol(
          base: 'AVAX',
          quote: 'USDT',
          venue: Venue.bybit,
          rawSymbol: 'AVAXUSDT',
        ),
      );

      expect(meta.decimals, 2);
    });
  });
}
