import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:youtrade/core/failures.dart';
import 'package:youtrade/core/result.dart';
import 'package:youtrade/data/datasources/remote/bybit/bybit_rest_client.dart';
import 'package:youtrade/domain/entities/candle.dart';
import 'package:youtrade/domain/entities/order_book.dart';
import 'package:youtrade/domain/entities/symbol.dart';
import 'package:youtrade/domain/entities/ticker.dart';
import 'package:youtrade/domain/entities/timeframe.dart';
import 'package:youtrade/domain/entities/trade.dart';
import 'package:youtrade/domain/entities/venue.dart';

void main() {
  group('BybitRestClient', () {
    final symbol = TradingSymbol(
      base: 'BTC',
      quote: 'USDT',
      venue: Venue.bybit,
      rawSymbol: 'BTCUSDT',
    );

    test('default base URL is demo endpoint', () async {
      String? capturedHost;
      final client = BybitRestClient(
        httpClient: MockClient((request) async {
          capturedHost = request.url.host;
          return http.Response(
            '{"retCode":0,"retMsg":"OK","result":{"category":"spot","list":[{"symbol":"BTCUSDT","lastPrice":"100.0","bid1Price":"99.5","ask1Price":"100.5","price24hPcnt":"0.01","turnover24h":"1000.0","volume24h":"1000.0"}]}}',
            200,
          );
        }),
      );
      await client.fetchTicker(symbol);
      expect(capturedHost, 'api-demo.bybit.com');
    });

    test('fetchTicker returns Success on valid response', () async {
      final client = BybitRestClient(
        httpClient: MockClient((request) async {
          expect(request.url.path, '/v5/market/tickers');
          expect(request.url.queryParameters['category'], 'spot');
          expect(request.url.queryParameters['symbol'], 'BTCUSDT');
          return http.Response(
            '{"retCode":0,"retMsg":"OK","result":{"category":"spot","list":[{"symbol":"BTCUSDT","lastPrice":"100.0","bid1Price":"99.5","ask1Price":"100.5","price24hPcnt":"0.01","turnover24h":"1000.0","volume24h":"1000.0"}]}}',
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
          expect(ticker.change24hPercent, 1.0);
          expect(ticker.volume, 1000.0);
        },
        failure: (_) => fail('expected success'),
      );
    });

    // Catches the wrong failure type or message when Bybit returns a non-200
    // response, which would hide the real HTTP error from callers.
    test('fetchTicker returns Failure on non-200', () async {
      final client = BybitRestClient(
        httpClient: MockClient((_) async => http.Response('bad', 400)),
      );
      final result = await client.fetchTicker(symbol);
      expect(result, isA<Err<Ticker>>());
      result.when(
        success: (_) => fail('expected failure'),
        failure: (failure) {
          expect(failure, isA<NetworkFailure>());
          expect(failure.message, 'Bybit ticker 400');
        },
      );
    });

    test('fetchCandles returns Success on valid response', () async {
      final client = BybitRestClient(
        httpClient: MockClient((request) async {
          expect(request.url.path, '/v5/market/kline');
          expect(request.url.queryParameters['interval'], '60');
          return http.Response(
            '{"retCode":0,"retMsg":"OK","result":{"category":"spot","symbol":"BTCUSDT","list":[["1718952000000","1.0","2.0","0.5","1.5","100.0","0"]]}}',
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
      final client = BybitRestClient(
        httpClient: MockClient((request) async {
          expect(request.url.path, '/v5/market/orderbook');
          expect(request.url.queryParameters['limit'], '5');
          return http.Response(
            '{"retCode":0,"retMsg":"OK","result":{"s":"BTCUSDT","b":[["99.0","1.0"]],"a":[["101.0","1.0"]],"ts":1718952000000,"u":1}}',
            200,
          );
        }),
      );

      final result = await client.fetchOrderBook(symbol, depth: 5);
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
      final client = BybitRestClient(
        httpClient: MockClient((request) async {
          expect(request.url.path, '/v5/market/recent-trade');
          expect(request.url.queryParameters['limit'], '1');
          return http.Response(
            '{"retCode":0,"retMsg":"OK","result":{"category":"spot","list":[{"execId":"1","symbol":"BTCUSDT","price":"100.0","size":"1.0","side":"Buy","time":"1718952000000"}]}}',
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

    test('fetchTicker returns ParseFailure on empty list', () async {
      final client = BybitRestClient(
        httpClient: MockClient((request) async {
          expect(request.url.path, '/v5/market/tickers');
          return http.Response(
            '{"retCode":0,"retMsg":"OK","result":{"category":"spot","list":[]}}',
            200,
          );
        }),
      );

      final result = await client.fetchTicker(symbol);
      expect(result, isA<Err<Ticker>>());
      result.when(
        success: (_) => fail('expected failure'),
        failure: (failure) {
          expect(failure, isA<ParseFailure>());
          expect(failure.message, startsWith('Bybit ticker parse failed:'));
          expect(failure.message, contains('No element'));
        },
      );
    });

    test('fetchCandles returns ParseFailure on type mismatch', () async {
      final client = BybitRestClient(
        httpClient: MockClient((request) async {
          expect(request.url.path, '/v5/market/kline');
          return http.Response(
            '{"retCode":0,"retMsg":"OK","result":{"category":"spot","symbol":"BTCUSDT","list":"not-a-list"}}',
            200,
          );
        }),
      );

      final result = await client.fetchCandles(symbol, Timeframe.h1, limit: 1);
      expect(result, isA<Err<List<Candle>>>());
      result.when(
        success: (_) => fail('expected failure'),
        failure: (failure) {
          expect(failure, isA<ParseFailure>());
          expect(failure.message, startsWith('Bybit candles parse failed:'));
          expect(
            failure.message,
            contains("type 'String' is not a subtype of type 'List<dynamic>'"),
          );
        },
      );
    });

    test('fetchTicker returns NetworkFailure on retCode != 0', () async {
      final client = BybitRestClient(
        httpClient: MockClient(
          (_) async => http.Response(
            '{"retCode":10016,"retMsg":"Invalid symbol","result":{}}',
            200,
          ),
        ),
      );

      final result = await client.fetchTicker(symbol);
      expect(result, isA<Err<Ticker>>());
      result.when(
        success: (_) => fail('expected failure'),
        failure: (failure) {
          expect(failure, isA<NetworkFailure>());
          expect(
            failure.message,
            'Bybit ticker API error: 10016 Invalid symbol',
          );
        },
      );
    });

    test('fetchCandles returns NetworkFailure on retCode != 0', () async {
      final client = BybitRestClient(
        httpClient: MockClient(
          (_) async => http.Response(
            '{"retCode":10016,"retMsg":"Invalid interval","result":{}}',
            200,
          ),
        ),
      );

      final result = await client.fetchCandles(symbol, Timeframe.h1, limit: 1);
      expect(result, isA<Err<List<Candle>>>());
      result.when(
        success: (_) => fail('expected failure'),
        failure: (failure) {
          expect(failure, isA<NetworkFailure>());
          expect(
            failure.message,
            'Bybit candles API error: 10016 Invalid interval',
          );
        },
      );
    });

    test('fetchOrderBook returns NetworkFailure on retCode != 0', () async {
      final client = BybitRestClient(
        httpClient: MockClient(
          (_) async => http.Response(
            '{"retCode":10016,"retMsg":"Invalid depth","result":{}}',
            200,
          ),
        ),
      );

      final result = await client.fetchOrderBook(symbol, depth: 5);
      expect(result, isA<Err<OrderBook>>());
      result.when(
        success: (_) => fail('expected failure'),
        failure: (failure) {
          expect(failure, isA<NetworkFailure>());
          expect(
            failure.message,
            'Bybit order book API error: 10016 Invalid depth',
          );
        },
      );
    });

    test('fetchTrades returns NetworkFailure on retCode != 0', () async {
      final client = BybitRestClient(
        httpClient: MockClient(
          (_) async => http.Response(
            '{"retCode":10016,"retMsg":"Invalid category","result":{}}',
            200,
          ),
        ),
      );

      final result = await client.fetchTrades(symbol, limit: 1);
      expect(result, isA<Err<List<Trade>>>());
      result.when(
        success: (_) => fail('expected failure'),
        failure: (failure) {
          expect(failure, isA<NetworkFailure>());
          expect(
            failure.message,
            'Bybit trades API error: 10016 Invalid category',
          );
        },
      );
    });

    test('fetchTicker returns ParseFailure on malformed JSON', () async {
      final client = BybitRestClient(
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
            startsWith('Bybit ticker parse failed: FormatException'),
          );
        },
      );
    });

    test('fetchTicker returns ParseFailure on missing required fields', () async {
      final client = BybitRestClient(
        httpClient: MockClient(
          (_) async => http.Response(
            '{"retCode":0,"retMsg":"OK","result":{"category":"spot","list":[{}]}}',
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
          expect(failure.message, startsWith('Bybit ticker parse failed:'));
          expect(failure.message, contains("type 'Null'"));
        },
      );
    });

    test('fetchTrades returns ParseFailure on unknown side', () async {
      final client = BybitRestClient(
        httpClient: MockClient(
          (_) async => http.Response(
            '{"retCode":0,"retMsg":"OK","result":{"category":"spot","list":[{"execId":"1","symbol":"BTCUSDT","price":"100.0","size":"1.0","side":"unknown","time":"1718952000000"}]}}',
            200,
          ),
        ),
      );

      final result = await client.fetchTrades(symbol, limit: 1);
      expect(result, isA<Err<List<Trade>>>());
      result.when(
        success: (_) => fail('expected failure'),
        failure: (failure) {
          expect(failure, isA<ParseFailure>());
          expect(
            failure.message,
            startsWith(
              'Bybit trades parse failed: FormatException: Unknown trade side: unknown',
            ),
          );
        },
      );
    });

    test('fetchTicker returns NetworkFailure on request exception', () async {
      final client = BybitRestClient(
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
            'Bybit ticker request failed: Exception: timeout',
          );
        },
      );
    });

    test('fetchTicker returns ParseFailure on empty body', () async {
      final client = BybitRestClient(
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
            startsWith('Bybit ticker parse failed: FormatException'),
          );
        },
      );
    });

    test('fetchCandles returns ParseFailure on malformed list element', () async {
      final client = BybitRestClient(
        httpClient: MockClient(
          (_) async => http.Response(
            '{"retCode":0,"retMsg":"OK","result":{"category":"spot","symbol":"BTCUSDT","list":[["not-an-int"]]}}',
            200,
          ),
        ),
      );

      final result = await client.fetchCandles(symbol, Timeframe.h1, limit: 1);
      expect(result, isA<Err<List<Candle>>>());
      result.when(
        success: (_) => fail('expected failure'),
        failure: (failure) {
          expect(failure, isA<ParseFailure>());
          expect(failure.message, startsWith('Bybit candles parse failed:'));
          expect(failure.message, contains('RangeError'));
        },
      );
    });

    test(
      'fetchOrderBook returns Success with empty bids when key missing',
      () async {
        final client = BybitRestClient(
          httpClient: MockClient(
            (_) async => http.Response(
              '{"retCode":0,"retMsg":"OK","result":{"s":"BTCUSDT","a":[["101.0","1.0"]]}}',
              200,
            ),
          ),
        );

        final result = await client.fetchOrderBook(symbol, depth: 5);
        expect(result, isA<Success<OrderBook>>());
        result.when(
          success: (orderBook) {
            expect(orderBook.bids, isEmpty);
            expect(orderBook.asks.first.price, 101.0);
          },
          failure: (_) => fail('expected success'),
        );
      },
    );

    test('fetchTrades returns ParseFailure on missing fields', () async {
      final client = BybitRestClient(
        httpClient: MockClient(
          (_) async => http.Response(
            '{"retCode":0,"retMsg":"OK","result":{"category":"spot","list":[{"execId":"1"}]}}',
            200,
          ),
        ),
      );

      final result = await client.fetchTrades(symbol, limit: 1);
      expect(result, isA<Err<List<Trade>>>());
      result.when(
        success: (_) => fail('expected failure'),
        failure: (failure) {
          expect(failure, isA<ParseFailure>());
          expect(failure.message, startsWith('Bybit trades parse failed:'));
          expect(failure.message, contains("type 'Null'"));
        },
      );
    });

    test('fetchTicker returns NetworkFailure on timeout', () async {
      final client = BybitRestClient(
        httpClient: MockClient((_) async => throw TimeoutException('timeout')),
      );
      final result = await client.fetchTicker(symbol);
      expect(result, isA<Err<Ticker>>());
      result.when(
        success: (_) => fail('expected failure'),
        failure: (failure) {
          expect(failure, isA<NetworkFailure>());
          expect(failure.message, 'Bybit ticker request timed out');
        },
      );
    });

    test('fetchCandles returns NetworkFailure on timeout', () async {
      final client = BybitRestClient(
        httpClient: MockClient((_) async => throw TimeoutException('timeout')),
      );
      final result = await client.fetchCandles(symbol, Timeframe.h1);
      expect(result, isA<Err<List<Candle>>>());
      result.when(
        success: (_) => fail('expected failure'),
        failure: (failure) {
          expect(failure, isA<NetworkFailure>());
          expect(failure.message, 'Bybit candles request timed out');
        },
      );
    });

    test('fetchOrderBook returns NetworkFailure on timeout', () async {
      final client = BybitRestClient(
        httpClient: MockClient((_) async => throw TimeoutException('timeout')),
      );
      final result = await client.fetchOrderBook(symbol);
      expect(result, isA<Err<OrderBook>>());
      result.when(
        success: (_) => fail('expected failure'),
        failure: (failure) {
          expect(failure, isA<NetworkFailure>());
          expect(failure.message, 'Bybit order book request timed out');
        },
      );
    });

    test('fetchTrades returns NetworkFailure on timeout', () async {
      final client = BybitRestClient(
        httpClient: MockClient((_) async => throw TimeoutException('timeout')),
      );
      final result = await client.fetchTrades(symbol);
      expect(result, isA<Err<List<Trade>>>());
      result.when(
        success: (_) => fail('expected failure'),
        failure: (failure) {
          expect(failure, isA<NetworkFailure>());
          expect(failure.message, 'Bybit trades request timed out');
        },
      );
    });
  });

  group('fetchAllTickers', () {
    test('returns Success with list of ticker maps for linear', () async {
      final client = BybitRestClient(
        httpClient: MockClient((request) async {
          expect(request.url.path, '/v5/market/tickers');
          expect(request.url.queryParameters['category'], 'linear');
          expect(request.url.queryParameters.containsKey('symbol'), isFalse);
          return http.Response(
            '{"retCode":0,"retMsg":"OK","result":{"category":"linear","list":['
            '{"symbol":"BTCUSDT","lastPrice":"65000.0","price24hPcnt":"0.05","volume24h":"1000000.0"},'
            '{"symbol":"ETHUSDT","lastPrice":"3200.0","price24hPcnt":"-0.02","volume24h":"500000.0"}'
            ']}}',
            200,
          );
        }),
      );

      final result = await client.fetchAllTickers('linear');
      expect(result, isA<Success<List<Map<String, dynamic>>>>());
      result.when(
        success: (tickers) {
          expect(tickers.length, 2);
          expect(tickers[0]['symbol'], 'BTCUSDT');
          expect(tickers[1]['symbol'], 'ETHUSDT');
        },
        failure: (_) => fail('expected success'),
      );
    });

    test('returns Success with list of ticker maps for spot', () async {
      final client = BybitRestClient(
        httpClient: MockClient((request) async {
          expect(request.url.queryParameters['category'], 'spot');
          return http.Response(
            '{"retCode":0,"retMsg":"OK","result":{"category":"spot","list":['
            '{"symbol":"SOLUSDT","lastPrice":"150.0","price24hPcnt":"0.03","volume24h":"200000.0"}'
            ']}}',
            200,
          );
        }),
      );

      final result = await client.fetchAllTickers('spot');
      expect(result, isA<Success<List<Map<String, dynamic>>>>());
      result.when(
        success: (tickers) {
          expect(tickers.length, 1);
          expect(tickers[0]['symbol'], 'SOLUSDT');
        },
        failure: (_) => fail('expected success'),
      );
    });

    test('returns Success with empty list when API returns empty', () async {
      final client = BybitRestClient(
        httpClient: MockClient(
          (_) async => http.Response(
            '{"retCode":0,"retMsg":"OK","result":{"category":"linear","list":[]}}',
            200,
          ),
        ),
      );

      final result = await client.fetchAllTickers('linear');
      expect(result, isA<Success<List<Map<String, dynamic>>>>());
      result.when(
        success: (tickers) => expect(tickers, isEmpty),
        failure: (_) => fail('expected success'),
      );
    });

    test('returns NetworkFailure on non-200', () async {
      final client = BybitRestClient(
        httpClient: MockClient((_) async => http.Response('bad', 400)),
      );
      final result = await client.fetchAllTickers('linear');
      expect(result, isA<Err<List<Map<String, dynamic>>>>());
      result.when(
        success: (_) => fail('expected failure'),
        failure: (failure) {
          expect(failure, isA<NetworkFailure>());
          expect(failure.message, 'Bybit tickers 400');
        },
      );
    });

    test('returns NetworkFailure on retCode != 0', () async {
      final client = BybitRestClient(
        httpClient: MockClient(
          (_) async => http.Response(
            '{"retCode":10001,"retMsg":"Params error","result":{}}',
            200,
          ),
        ),
      );

      final result = await client.fetchAllTickers('linear');
      expect(result, isA<Err<List<Map<String, dynamic>>>>());
      result.when(
        success: (_) => fail('expected failure'),
        failure: (failure) {
          expect(failure, isA<NetworkFailure>());
          expect(
            failure.message,
            'Bybit tickers API error: 10001 Params error',
          );
        },
      );
    });

    test('returns ParseFailure on malformed JSON', () async {
      final client = BybitRestClient(
        httpClient: MockClient((_) async => http.Response('not-json', 200)),
      );

      final result = await client.fetchAllTickers('linear');
      expect(result, isA<Err<List<Map<String, dynamic>>>>());
      result.when(
        success: (_) => fail('expected failure'),
        failure: (failure) {
          expect(failure, isA<ParseFailure>());
          expect(
            failure.message,
            startsWith('Bybit tickers parse failed: FormatException'),
          );
        },
      );
    });

    test('returns NetworkFailure on timeout', () async {
      final client = BybitRestClient(
        httpClient: MockClient((_) async => throw TimeoutException('timeout')),
      );
      final result = await client.fetchAllTickers('linear');
      expect(result, isA<Err<List<Map<String, dynamic>>>>());
      result.when(
        success: (_) => fail('expected failure'),
        failure: (failure) {
          expect(failure, isA<NetworkFailure>());
          expect(failure.message, 'Bybit tickers request timed out');
        },
      );
    });
  });
}
