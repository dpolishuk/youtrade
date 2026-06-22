import 'package:flutter_test/flutter_test.dart';
import 'package:youtrade/data/datasources/mock/deterministic_market_data_store.dart';
import 'package:youtrade/domain/entities/symbol.dart';
import 'package:youtrade/domain/entities/timeframe.dart';
import 'package:youtrade/domain/entities/trade.dart';
import 'package:youtrade/domain/entities/venue.dart';

void main() {
  group('DeterministicMarketDataStore', () {
    final btc = TradingSymbol(
      base: 'BTC',
      quote: 'USDT',
      venue: Venue.binance,
      rawSymbol: 'BTCUSDT',
    );

    late DeterministicMarketDataStore store;

    setUp(() => store = DeterministicMarketDataStore());

    test('portfolio net worth matches mockup', () {
      expect(
        DeterministicMarketDataStore.portfolioNetWorth,
        746240.0,
        reason: 'Sum of Binance/Bybit/OKX/Coinbase balances from mockup',
      );
    });

    test('24h delta matches mockup', () {
      expect(DeterministicMarketDataStore.portfolio24hDelta, 14820.0);
      expect(DeterministicMarketDataStore.portfolio24hDeltaPct, '+2.04%');
    });

    test('first equity curve point matches mockup', () {
      expect(
        DeterministicMarketDataStore.firstEquityCurvePoint,
        closeTo(812468.7068931296, 1e-9),
      );
    });

    test('BTC last price matches deterministic mockup', () {
      expect(
        DeterministicMarketDataStore.btcLastPrice,
        closeTo(105154.04697406417, 1e-9),
      );
    });

    test('BTC first open matches deterministic mockup', () {
      expect(DeterministicMarketDataStore.btcFirstOpen, 58000.0);
    });

    test('options ATM strike matches deterministic spot', () {
      expect(DeterministicMarketDataStore.btcOptionsAtmStrike, 106000.0);
    });

    test('returns deterministic BTC options chain', () {
      final chain = DeterministicMarketDataStore.btcOptionsChain;
      final strikes = chain.map((r) => r.strike).toList();

      expect(chain.length, 9);
      expect(strikes, [
        98000,
        100000,
        102000,
        104000,
        106000,
        108000,
        110000,
        112000,
        114000,
      ]);

      final atm = chain.firstWhere((r) => r.isAtm);
      expect(atm.strike, 106000.0);
      expect(atm.callInTheMoney, isFalse);
      expect(atm.callIv, closeTo(59.226943359350, 1e-9));
      expect(atm.callDelta, closeTo(0.467820429160, 1e-9));
      expect(atm.callMark, closeTo(0.026335148456, 1e-9));
      expect(atm.putIv, closeTo(63.226943359350, 1e-9));
      expect(atm.putDelta, closeTo(-0.532179570840, 1e-9));
      expect(atm.putMark, closeTo(0.022884988184, 1e-9));

      final itmCall = chain.first;
      expect(itmCall.strike, 98000.0);
      expect(itmCall.callInTheMoney, isTrue);
      expect(itmCall.callIv, closeTo(56.677117660957, 1e-9));
      expect(itmCall.callMark, closeTo(0.078035062809, 1e-9));
    });

    test('returns deterministic BTC option expiries', () {
      expect(DeterministicMarketDataStore.btcOptionExpiries, [
        '26 JUN',
        '25 JUL',
        '29 AUG',
        '26 SEP',
      ]);
    });

    test('returns deterministic BTC ticker', () async {
      final ticker = await store.getTicker(btc);

      expect(ticker.symbol, btc);
      expect(ticker.lastPrice, closeTo(105154.04697406417, 1e-9));
      expect(ticker.bid, closeTo(105154.04697406417 * 0.9995, 1e-6));
      expect(ticker.ask, closeTo(105154.04697406417 * 1.0005, 1e-6));
      expect(ticker.change24h, isPositive);
      expect(ticker.change24hPercent, isPositive);
      expect(ticker.volume, isPositive);
    });

    test('returns deterministic candles for BTC', () async {
      final candles = await store.getCandles(btc, Timeframe.h1, limit: 10);

      expect(candles.length, 10);
      expect(candles.last.close, closeTo(105154.04697406417, 1e-9));
      expect(candles.first.open, closeTo(101991.92335507207, 1e-9));
      expect(candles.last.timestamp.isAfter(candles.first.timestamp), isTrue);
    });

    test(
      'returns order book with descending bids and ascending asks',
      () async {
        final orderBook = await store.getOrderBook(btc, depth: 5);

        expect(orderBook.bids.length, 5);
        expect(orderBook.asks.length, 5);
        expect(orderBook.bestBid, greaterThan(orderBook.bids.last.price));
        expect(orderBook.bestAsk, lessThan(orderBook.asks.last.price));
        expect(orderBook.spread, greaterThan(0));
      },
    );

    test('returns deterministic trades for BTC', () async {
      final trades = await store.getTrades(btc, limit: 3);

      expect(trades.length, 3);
      expect(trades.first.tradeId, 'mock-trade-0');
      expect(trades.first.side, TradeSide.sell);
      expect(trades.first.price, closeTo(105145.07890125892, 1e-9));
      expect(trades.first.amount, closeTo(0.4289474746999087, 1e-9));
    });

    test('watchTicker emits deterministic values', () async {
      final values = await store.watchTicker(btc).take(2).toList();

      expect(values.length, 2);
      expect(values.first.symbol, btc);
      expect(values.first.lastPrice, closeTo(105154.04697406417, 1e-9));
    });

    test('ETH last price is deterministic and differs from BTC', () async {
      final eth = TradingSymbol(
        base: 'ETH',
        quote: 'USDT',
        venue: Venue.bybit,
        rawSymbol: 'ETHUSDT',
      );
      final ticker = await store.getTicker(eth);

      expect(ticker.lastPrice, isNot(closeTo(105154.04697406417, 1e-3)));
      expect(ticker.lastPrice, closeTo(2887.8860130257644, 1e-6));
    });

    test('screenerTicker returns deterministic last price and 24h change', () {
      final btc = DeterministicMarketDataStore.screenerTicker('BTCUSDT');

      expect(btc.last, closeTo(105154.04697406417, 1e-9));
      expect(btc.change24hPercent, closeTo(6.423290746323324, 1e-9));
    });

    test('screenerSparkline returns last 30 closes', () {
      final spark = DeterministicMarketDataStore.screenerSparkline('BTCUSDT');

      expect(spark.length, 30);
      expect(spark.last, closeTo(105154.04697406417, 1e-9));
    });

    test('screener helpers fall back to BTC when symbol is unknown', () {
      final fallback = DeterministicMarketDataStore.screenerTicker('UNKNOWN');
      final spark = DeterministicMarketDataStore.screenerSparkline('UNKNOWN');

      expect(fallback.last, closeTo(105154.04697406417, 1e-9));
      expect(spark.last, closeTo(105154.04697406417, 1e-9));
    });
  });
}
