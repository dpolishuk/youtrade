import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:youtrade/core/failures.dart';
import 'package:youtrade/core/result.dart';
import 'package:youtrade/data/datasources/remote/binance/binance_rest_client.dart';
import 'package:youtrade/domain/entities/candle.dart';
import 'package:youtrade/domain/entities/order_book.dart';
import 'package:youtrade/domain/entities/symbol.dart';
import 'package:youtrade/domain/entities/ticker.dart';
import 'package:youtrade/domain/entities/timeframe.dart';
import 'package:youtrade/domain/entities/trade.dart';
import 'package:youtrade/domain/entities/venue.dart';

void main() {
  group('BinanceRestClient', () {
    final symbol = TradingSymbol(
      base: 'BTC',
      quote: 'USDT',
      venue: Venue.binance,
      rawSymbol: 'BTCUSDT',
    );

    test('fetchTicker returns Success on valid response', () async {
      final client = BinanceRestClient(
        httpClient: MockClient((request) async {
          expect(request.url.path, '/api/v3/ticker/24hr');
          return http.Response(
            '{"symbol":"BTCUSDT","lastPrice":"100.0","bidPrice":"99.5","askPrice":"100.5","priceChange":"1.0","priceChangePercent":"1.0","volume":"1000.0","closeTime":1718952000000}',
            200,
          );
        }),
      );

      final result = await client.fetchTicker(symbol);
      expect(result, isA<Success>());
      result.when(
        success: (ticker) {
          expect(ticker.lastPrice, 100.0);
          expect(ticker.bid, 99.5);
          expect(ticker.ask, 100.5);
        },
        failure: (_) => fail('expected success'),
      );
    });

    // Catches the wrong failure type or message when Binance returns a non-200
    // response, which would hide the real HTTP error from callers.
    test('fetchTicker returns Failure on non-200', () async {
      final client = BinanceRestClient(
        httpClient: MockClient((_) async => http.Response('bad', 400)),
      );
      final result = await client.fetchTicker(symbol);
      expect(result, isA<Err<Ticker>>());
      result.when(
        success: (_) => fail('expected failure'),
        failure: (failure) {
          expect(failure, isA<NetworkFailure>());
          expect(failure.message, 'Binance ticker 400');
        },
      );
    });

    test('fetchCandles returns Success on valid response', () async {
      final client = BinanceRestClient(
        httpClient: MockClient((request) async {
          expect(request.url.path, '/api/v3/klines');
          return http.Response(
            '[[1718952000000,"1.0","2.0","0.5","1.5","100.0",-1,-1,"1",-1,-1,-1]]',
            200,
          );
        }),
      );

      final result = await client.fetchCandles(symbol, Timeframe.h1, limit: 1);
      expect(result, isA<Success>());
      result.when(
        success: (candles) {
          expect(candles.length, 1);
          expect(candles.first.open, 1.0);
          expect(candles.first.close, 1.5);
        },
        failure: (_) => fail('expected success'),
      );
    });

    test('fetchOrderBook returns Success on valid response', () async {
      final client = BinanceRestClient(
        httpClient: MockClient((request) async {
          expect(request.url.path, '/api/v3/depth');
          return http.Response(
            '{"lastUpdateId":1,"bids":[["99.0","1.0"]],"asks":[["101.0","1.0"]]}',
            200,
          );
        }),
      );

      final result = await client.fetchOrderBook(symbol, depth: 1);
      expect(result, isA<Success>());
      result.when(
        success: (orderBook) {
          expect(orderBook.bids.first.price, 99.0);
          expect(orderBook.asks.first.price, 101.0);
        },
        failure: (_) => fail('expected success'),
      );
    });

    test('fetchTrades returns Success on valid response', () async {
      final client = BinanceRestClient(
        httpClient: MockClient((request) async {
          expect(request.url.path, '/api/v3/trades');
          return http.Response(
            '[{"id":1,"price":"100.0","qty":"1.0","time":1718952000000,"isBuyerMaker":false}]',
            200,
          );
        }),
      );

      final result = await client.fetchTrades(symbol, limit: 1);
      expect(result, isA<Success>());
      result.when(
        success: (trades) {
          expect(trades.length, 1);
          expect(trades.first.price, 100.0);
          expect(trades.first.side, TradeSide.buy);
        },
        failure: (_) => fail('expected success'),
      );
    });

    test('fetchTrades returns ParseFailure on malformed response', () async {
      final client = BinanceRestClient(
        httpClient: MockClient((request) async {
          expect(request.url.path, '/api/v3/trades');
          return http.Response(
            '[{"id":1,"price":"100.0","qty":"1.0","time":"not-an-int","isBuyerMaker":false}]',
            200,
          );
        }),
      );

      final result = await client.fetchTrades(symbol, limit: 1);
      expect(result, isA<Err<List<Trade>>>());
      result.when(
        success: (_) => fail('expected failure'),
        failure: (failure) => expect(failure, isA<ParseFailure>()),
      );
    });

    test('fetchTrades returns ParseFailure on type mismatch', () async {
      final client = BinanceRestClient(
        httpClient: MockClient((request) async {
          expect(request.url.path, '/api/v3/trades');
          return http.Response('{"not":"a list"}', 200);
        }),
      );

      final result = await client.fetchTrades(symbol, limit: 1);
      expect(result, isA<Err<List<Trade>>>());
      result.when(
        success: (_) => fail('expected failure'),
        failure: (failure) => expect(failure, isA<ParseFailure>()),
      );
    });

    test('fetchTicker returns ParseFailure on malformed JSON', () async {
      final client = BinanceRestClient(
        httpClient: MockClient((_) async => http.Response('not-json', 200)),
      );

      final result = await client.fetchTicker(symbol);
      expect(result, isA<Err<Ticker>>());
      result.when(
        success: (_) => fail('expected failure'),
        failure: (failure) {
          expect(failure, isA<ParseFailure>());
          expect(
            failure.message,
            startsWith('Binance ticker parse failed: FormatException'),
          );
        },
      );
    });

    test(
      'fetchTicker returns ParseFailure on missing required fields',
      () async {
        final client = BinanceRestClient(
          httpClient: MockClient((_) async => http.Response('{}', 200)),
        );

        final result = await client.fetchTicker(symbol);
        expect(result, isA<Err<Ticker>>());
        result.when(
          success: (_) => fail('expected failure'),
          failure: (failure) {
            expect(failure, isA<ParseFailure>());
            expect(failure.message, startsWith('Binance ticker parse failed:'));
            expect(failure.message, contains("type 'Null'"));
          },
        );
      },
    );

    test('fetchTicker returns NetworkFailure on request exception', () async {
      final client = BinanceRestClient(
        httpClient: MockClient((_) async => throw Exception('timeout')),
      );

      final result = await client.fetchTicker(symbol);
      expect(result, isA<Err<Ticker>>());
      result.when(
        success: (_) => fail('expected failure'),
        failure: (failure) {
          expect(failure, isA<NetworkFailure>());
          expect(
            failure.message,
            'Binance ticker request failed: Exception: timeout',
          );
        },
      );
    });

    test('fetchTicker returns ParseFailure on empty body', () async {
      final client = BinanceRestClient(
        httpClient: MockClient((_) async => http.Response('', 200)),
      );

      final result = await client.fetchTicker(symbol);
      expect(result, isA<Err<Ticker>>());
      result.when(
        success: (_) => fail('expected failure'),
        failure: (failure) {
          expect(failure, isA<ParseFailure>());
          expect(
            failure.message,
            startsWith('Binance ticker parse failed: FormatException'),
          );
        },
      );
    });

    test('fetchCandles returns ParseFailure on empty list element', () async {
      final client = BinanceRestClient(
        httpClient: MockClient(
          (_) async => http.Response('[["not-an-int"]]', 200),
        ),
      );

      final result = await client.fetchCandles(symbol, Timeframe.h1, limit: 1);
      expect(result, isA<Err<List<Candle>>>());
      result.when(
        success: (_) => fail('expected failure'),
        failure: (failure) {
          expect(failure, isA<ParseFailure>());
          expect(failure.message, startsWith('Binance candles parse failed:'));
          expect(failure.message, contains('RangeError'));
        },
      );
    });

    test('fetchOrderBook returns ParseFailure on missing bids key', () async {
      final client = BinanceRestClient(
        httpClient: MockClient(
          (_) async => http.Response('{"asks":[["101.0","1.0"]]}', 200),
        ),
      );

      final result = await client.fetchOrderBook(symbol, depth: 1);
      expect(result, isA<Err<OrderBook>>());
      result.when(
        success: (_) => fail('expected failure'),
        failure: (failure) {
          expect(failure, isA<ParseFailure>());
          expect(
            failure.message,
            startsWith('Binance order book parse failed:'),
          );
          expect(failure.message, contains("type 'Null'"));
        },
      );
    });

    test('fetchTrades returns ParseFailure on missing fields', () async {
      final client = BinanceRestClient(
        httpClient: MockClient((_) async => http.Response('[{"id":1}]', 200)),
      );

      final result = await client.fetchTrades(symbol, limit: 1);
      expect(result, isA<Err<List<Trade>>>());
      result.when(
        success: (_) => fail('expected failure'),
        failure: (failure) {
          expect(failure, isA<ParseFailure>());
          expect(failure.message, startsWith('Binance trades parse failed:'));
          expect(failure.message, contains("type 'Null'"));
        },
      );
    });
  });
}
