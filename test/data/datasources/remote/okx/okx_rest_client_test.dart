import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:youtrade/core/failures.dart';
import 'package:youtrade/core/result.dart';
import 'package:youtrade/data/datasources/remote/okx/okx_rest_client.dart';
import 'package:youtrade/domain/entities/candle.dart';
import 'package:youtrade/domain/entities/order_book.dart';
import 'package:youtrade/domain/entities/symbol.dart';
import 'package:youtrade/domain/entities/ticker.dart';
import 'package:youtrade/domain/entities/timeframe.dart';
import 'package:youtrade/domain/entities/trade.dart';
import 'package:youtrade/domain/entities/venue.dart';

void main() {
  group('OKXRestClient', () {
    final symbol = TradingSymbol(
      base: 'BTC',
      quote: 'USDT',
      venue: Venue.okx,
      rawSymbol: 'BTCUSDT',
    );

    test('fetchTicker returns Success on valid response', () async {
      final client = OKXRestClient(
        httpClient: MockClient((request) async {
          expect(request.url.path, '/api/v5/market/ticker');
          expect(request.url.queryParameters['instId'], 'BTC-USDT');
          return http.Response(
            '{"code":"0","msg":"","data":[{"instId":"BTC-USDT","last":"100.0","bidPx":"99.5","askPx":"100.5","open24h":"99.0","vol24h":"1000.0","ts":"1718952000000"}]}',
            200,
          );
        }),
      );

      final result = await client.fetchTicker(symbol);
      expect(result, isA<Success<Ticker>>());
      result.when(
        success: (ticker) {
          expect(ticker.lastPrice, 100.0);
          expect(ticker.bid, 99.5);
          expect(ticker.ask, 100.5);
          expect(ticker.change24h, 1.0);
          expect(ticker.change24hPercent, closeTo(0.010101, 0.000001));
          expect(ticker.volume, 1000.0);
          expect(
            ticker.timestamp,
            DateTime.fromMillisecondsSinceEpoch(1718952000000, isUtc: true),
          );
        },
        failure: (_) => fail('expected success'),
      );
    });

    test('fetchTicker returns Failure on non-200', () async {
      final client = OKXRestClient(
        httpClient: MockClient((_) async => http.Response('bad', 400)),
      );
      final result = await client.fetchTicker(symbol);
      expect(result, isA<Err<Ticker>>());
      result.when(
        success: (_) => fail('expected failure'),
        failure: (failure) {
          expect(failure, isA<NetworkFailure>());
          expect(failure.message, 'OKX ticker 400');
        },
      );
    });

    test('fetchTicker returns NetworkFailure on API error code', () async {
      final client = OKXRestClient(
        httpClient: MockClient(
          (_) async => http.Response('{"code":"50001","msg":"Invalid"}', 200),
        ),
      );
      final result = await client.fetchTicker(symbol);
      expect(result, isA<Err<Ticker>>());
      result.when(
        success: (_) => fail('expected failure'),
        failure: (failure) {
          expect(failure, isA<NetworkFailure>());
          expect(failure.message, 'OKX ticker API error: 50001 Invalid');
        },
      );
    });

    test('fetchCandles returns Success on valid response', () async {
      final client = OKXRestClient(
        httpClient: MockClient((request) async {
          expect(request.url.path, '/api/v5/market/history-candles');
          expect(request.url.queryParameters['instId'], 'BTC-USDT');
          expect(request.url.queryParameters['bar'], '1H');
          return http.Response(
            '{"code":"0","data":[["1718952000000","1.0","2.0","0.5","1.5","100.0","10000.0"]]}',
            200,
          );
        }),
      );

      final result = await client.fetchCandles(symbol, Timeframe.h1, limit: 1);
      expect(result, isA<Success<List<Candle>>>());
      result.when(
        success: (candles) {
          expect(candles.length, 1);
          expect(candles.first.open, 1.0);
          expect(candles.first.high, 2.0);
          expect(candles.first.low, 0.5);
          expect(candles.first.close, 1.5);
          expect(candles.first.volume, 100.0);
        },
        failure: (_) => fail('expected success'),
      );
    });

    test('fetchCandles returns Failure on non-200', () async {
      final client = OKXRestClient(
        httpClient: MockClient((_) async => http.Response('bad', 400)),
      );
      final result = await client.fetchCandles(symbol, Timeframe.h1);
      expect(result, isA<Err<List<Candle>>>());
      result.when(
        success: (_) => fail('expected failure'),
        failure: (failure) {
          expect(failure, isA<NetworkFailure>());
          expect(failure.message, 'OKX candles 400');
        },
      );
    });

    test('fetchCandles returns ParseFailure on type mismatch', () async {
      final client = OKXRestClient(
        httpClient: MockClient(
          (_) async =>
              http.Response('{"code":"0","data":{"not":"a list"}}', 200),
        ),
      );

      final result = await client.fetchCandles(symbol, Timeframe.h1);
      expect(result, isA<Err<List<Candle>>>());
      result.when(
        success: (_) => fail('expected failure'),
        failure: (failure) => expect(failure, isA<ParseFailure>()),
      );
    });

    test('fetchOrderBook returns Success on valid response', () async {
      final client = OKXRestClient(
        httpClient: MockClient((request) async {
          expect(request.url.path, '/api/v5/market/books');
          expect(request.url.queryParameters['sz'], '1');
          return http.Response(
            '{"code":"0","data":[{"bids":[["99.0","1.0","0","1"]],"asks":[["101.0","1.0","0","1"]]}]}',
            200,
          );
        }),
      );

      final result = await client.fetchOrderBook(symbol, depth: 1);
      expect(result, isA<Success<OrderBook>>());
      result.when(
        success: (orderBook) {
          expect(orderBook.bids.first.price, 99.0);
          expect(orderBook.asks.first.price, 101.0);
        },
        failure: (_) => fail('expected success'),
      );
    });

    test('fetchOrderBook returns Failure on non-200', () async {
      final client = OKXRestClient(
        httpClient: MockClient((_) async => http.Response('bad', 400)),
      );
      final result = await client.fetchOrderBook(symbol);
      expect(result, isA<Err<OrderBook>>());
      result.when(
        success: (_) => fail('expected failure'),
        failure: (failure) {
          expect(failure, isA<NetworkFailure>());
          expect(failure.message, 'OKX order book 400');
        },
      );
    });

    test('fetchTrades returns Success on valid response', () async {
      final client = OKXRestClient(
        httpClient: MockClient((request) async {
          expect(request.url.path, '/api/v5/market/trades');
          expect(request.url.queryParameters['limit'], '1');
          return http.Response(
            '{"code":"0","data":[{"instId":"BTC-USDT","tradeId":"1","px":"100.0","sz":"1.0","side":"buy","ts":"1718952000000"}]}',
            200,
          );
        }),
      );

      final result = await client.fetchTrades(symbol, limit: 1);
      expect(result, isA<Success<List<Trade>>>());
      result.when(
        success: (trades) {
          expect(trades.length, 1);
          expect(trades.first.price, 100.0);
          expect(trades.first.side, TradeSide.buy);
        },
        failure: (_) => fail('expected success'),
      );
    });

    test('fetchTrades returns Failure on non-200', () async {
      final client = OKXRestClient(
        httpClient: MockClient((_) async => http.Response('bad', 400)),
      );
      final result = await client.fetchTrades(symbol);
      expect(result, isA<Err<List<Trade>>>());
      result.when(
        success: (_) => fail('expected failure'),
        failure: (failure) {
          expect(failure, isA<NetworkFailure>());
          expect(failure.message, 'OKX trades 400');
        },
      );
    });

    test('fetchTrades returns ParseFailure on malformed response', () async {
      final client = OKXRestClient(
        httpClient: MockClient(
          (_) async =>
              http.Response('{"code":"0","data":[{"side":"buy"}]}', 200),
        ),
      );

      final result = await client.fetchTrades(symbol, limit: 1);
      expect(result, isA<Err<List<Trade>>>());
      result.when(
        success: (_) => fail('expected failure'),
        failure: (failure) => expect(failure, isA<ParseFailure>()),
      );
    });

    test(
      'fetchTicker returns ParseFailure on missing required fields',
      () async {
        final client = OKXRestClient(
          httpClient: MockClient(
            (_) async => http.Response(
              '{"code":"0","data":[{"instId":"BTC-USDT"}]}',
              200,
            ),
          ),
        );

        final result = await client.fetchTicker(symbol);
        expect(result, isA<Err<Ticker>>());
        result.when(
          success: (_) => fail('expected failure'),
          failure: (failure) {
            expect(failure, isA<ParseFailure>());
            expect(failure.message, startsWith('OKX ticker parse failed:'));
            expect(failure.message, contains("type 'Null'"));
          },
        );
      },
    );

    test('fetchTicker returns NetworkFailure on request exception', () async {
      final client = OKXRestClient(
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
            'OKX ticker request failed: Exception: timeout',
          );
        },
      );
    });

    test('fetchTicker returns ParseFailure on empty data list', () async {
      final client = OKXRestClient(
        httpClient: MockClient(
          (_) async => http.Response('{"code":"0","data":[]}', 200),
        ),
      );

      final result = await client.fetchTicker(symbol);
      expect(result, isA<Err<Ticker>>());
      result.when(
        success: (_) => fail('expected failure'),
        failure: (failure) {
          expect(failure, isA<ParseFailure>());
          expect(failure.message, startsWith('OKX ticker parse failed:'));
          expect(failure.message, contains('Bad state'));
        },
      );
    });
  });
}
