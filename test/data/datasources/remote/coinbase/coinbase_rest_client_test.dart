import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:youtrade/core/failures.dart';
import 'package:youtrade/core/result.dart';
import 'package:youtrade/data/datasources/remote/coinbase/coinbase_rest_client.dart';
import 'package:youtrade/domain/entities/candle.dart';
import 'package:youtrade/domain/entities/order_book.dart';
import 'package:youtrade/domain/entities/symbol.dart';
import 'package:youtrade/domain/entities/ticker.dart';
import 'package:youtrade/domain/entities/timeframe.dart';
import 'package:youtrade/domain/entities/trade.dart';
import 'package:youtrade/domain/entities/venue.dart';

void main() {
  group('CoinbaseRestClient', () {
    final symbol = TradingSymbol(
      base: 'BTC',
      quote: 'USD',
      venue: Venue.coinbase,
      rawSymbol: 'BTCUSD',
    );

    http.Client twoCallClient({
      required http.Response statsResponse,
      required http.Response tickerResponse,
    }) {
      return MockClient((request) async {
        if (request.url.path == '/products/BTC-USD/stats') {
          return statsResponse;
        }
        if (request.url.path == '/products/BTC-USD/ticker') {
          return tickerResponse;
        }
        return http.Response('not found', 404);
      });
    }

    test('fetchTicker returns Success on valid responses', () async {
      final client = CoinbaseRestClient(
        httpClient: twoCallClient(
          statsResponse: http.Response(
            '{"open":"99.0","high":"110.0","low":"90.0","volume":"1000.0","last":"100.0","volume_30day":"50000.0"}',
            200,
          ),
          tickerResponse: http.Response(
            '{"trade_id":1,"price":"100.0","size":"1.0","bid":"99.5","ask":"100.5","volume":"1000.0","time":"2024-06-21T12:00:00.000Z"}',
            200,
          ),
        ),
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
            DateTime.parse('2024-06-21T12:00:00.000Z').toUtc(),
          );
        },
        failure: (_) => fail('expected success'),
      );
    });

    test('fetchTicker prefers quote volume over stats volume', () async {
      final client = CoinbaseRestClient(
        httpClient: twoCallClient(
          statsResponse: http.Response(
            '{"open":"99.0","high":"110.0","low":"90.0","volume":"1000.0","last":"100.0","volume_30day":"50000.0"}',
            200,
          ),
          tickerResponse: http.Response(
            '{"trade_id":1,"price":"100.0","size":"1.0","bid":"99.5","ask":"100.5","volume":"750.0","time":"2024-06-21T12:00:00.000Z"}',
            200,
          ),
        ),
      );

      final result = await client.fetchTicker(symbol);
      expect(result, isA<Success<Ticker>>());
      result.when(
        success: (ticker) => expect(ticker.volume, 750.0),
        failure: (_) => fail('expected success'),
      );
    });

    test('fetchTicker returns Failure when stats returns non-200', () async {
      final client = CoinbaseRestClient(
        httpClient: twoCallClient(
          statsResponse: http.Response('bad', 400),
          tickerResponse: http.Response(
            '{"trade_id":1,"price":"100.0","bid":"99.5","ask":"100.5","time":"2024-06-21T12:00:00.000Z"}',
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
          expect(failure.message, 'Coinbase ticker stats 400');
        },
      );
    });

    test('fetchTicker returns Failure when quote returns non-200', () async {
      final client = CoinbaseRestClient(
        httpClient: twoCallClient(
          statsResponse: http.Response(
            '{"open":"99.0","volume":"1000.0","last":"100.0"}',
            200,
          ),
          tickerResponse: http.Response('bad', 400),
        ),
      );
      final result = await client.fetchTicker(symbol);
      expect(result, isA<Err<Ticker>>());
      result.when(
        success: (_) => fail('expected failure'),
        failure: (failure) {
          expect(failure, isA<NetworkFailure>());
          expect(failure.message, 'Coinbase ticker quote 400');
        },
      );
    });

    test('fetchCandles returns Success on valid response', () async {
      final client = CoinbaseRestClient(
        httpClient: MockClient((request) async {
          expect(request.url.path, '/products/BTC-USD/candles');
          expect(request.url.queryParameters['granularity'], '3600');
          return http.Response('[[1718952000,0.5,2.0,1.0,1.5,100.0]]', 200);
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
          expect(
            candles.first.timestamp,
            DateTime.fromMillisecondsSinceEpoch(1718952000000, isUtc: true),
          );
        },
        failure: (_) => fail('expected success'),
      );
    });

    test('fetchCandles returns Failure on non-200', () async {
      final client = CoinbaseRestClient(
        httpClient: MockClient((_) async => http.Response('bad', 400)),
      );
      final result = await client.fetchCandles(symbol, Timeframe.h1);
      expect(result, isA<Err<List<Candle>>>());
      result.when(
        success: (_) => fail('expected failure'),
        failure: (failure) {
          expect(failure, isA<NetworkFailure>());
          expect(failure.message, 'Coinbase candles 400');
        },
      );
    });

    test('fetchCandles returns ParseFailure on type mismatch', () async {
      final client = CoinbaseRestClient(
        httpClient: MockClient(
          (_) async => http.Response('{"not":"a list"}', 200),
        ),
      );

      final result = await client.fetchCandles(symbol, Timeframe.h1);
      expect(result, isA<Err<List<Candle>>>());
      result.when(
        success: (_) => fail('expected failure'),
        failure: (failure) {
          expect(failure, isA<ParseFailure>());
          expect(failure.message, startsWith('Coinbase candles parse failed:'));
          expect(
            failure.message,
            contains("is not a subtype of type 'List<dynamic>'"),
          );
        },
      );
    });

    test('fetchOrderBook returns Success on valid response', () async {
      final client = CoinbaseRestClient(
        httpClient: MockClient((request) async {
          expect(request.url.path, '/products/BTC-USD/book');
          expect(request.url.queryParameters['level'], '2');
          return http.Response(
            '{"sequence":1,"bids":[["99.5","1",1]],"asks":[["100.5","1",1]]}',
            200,
          );
        }),
      );

      final result = await client.fetchOrderBook(symbol);
      expect(result, isA<Success<OrderBook>>());
      result.when(
        success: (orderBook) {
          expect(orderBook.bids.first.price, 99.5);
          expect(orderBook.asks.first.price, 100.5);
        },
        failure: (_) => fail('expected success'),
      );
    });

    test('fetchOrderBook returns Failure on non-200', () async {
      final client = CoinbaseRestClient(
        httpClient: MockClient((_) async => http.Response('bad', 400)),
      );
      final result = await client.fetchOrderBook(symbol);
      expect(result, isA<Err<OrderBook>>());
      result.when(
        success: (_) => fail('expected failure'),
        failure: (failure) {
          expect(failure, isA<NetworkFailure>());
          expect(failure.message, 'Coinbase order book 400');
        },
      );
    });

    test('fetchTrades returns Success on valid response', () async {
      final client = CoinbaseRestClient(
        httpClient: MockClient((request) async {
          expect(request.url.path, '/products/BTC-USD/trades');
          return http.Response(
            '[{"time":"2024-06-21T12:00:00.000Z","trade_id":1,"price":"100.0","size":"1.0","side":"buy"}]',
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
      final client = CoinbaseRestClient(
        httpClient: MockClient((_) async => http.Response('bad', 400)),
      );
      final result = await client.fetchTrades(symbol);
      expect(result, isA<Err<List<Trade>>>());
      result.when(
        success: (_) => fail('expected failure'),
        failure: (failure) {
          expect(failure, isA<NetworkFailure>());
          expect(failure.message, 'Coinbase trades 400');
        },
      );
    });

    test('fetchTrades returns ParseFailure on malformed response', () async {
      final client = CoinbaseRestClient(
        httpClient: MockClient(
          (_) async => http.Response('[{"side":"buy"}]', 200),
        ),
      );

      final result = await client.fetchTrades(symbol, limit: 1);
      expect(result, isA<Err<List<Trade>>>());
      result.when(
        success: (_) => fail('expected failure'),
        failure: (failure) {
          expect(failure, isA<ParseFailure>());
          expect(failure.message, startsWith('Coinbase trades parse failed:'));
          expect(failure.message, contains("type 'Null'"));
        },
      );
    });

    test('fetchTicker returns 0.0 change24hPercent when open is 0', () async {
      final client = CoinbaseRestClient(
        httpClient: twoCallClient(
          statsResponse: http.Response(
            '{"open":"0","high":"110.0","low":"90.0","volume":"1000.0","last":"100.0","volume_30day":"50000.0"}',
            200,
          ),
          tickerResponse: http.Response(
            '{"trade_id":1,"price":"100.0","size":"1.0","bid":"99.5","ask":"100.5","volume":"1000.0","time":"2024-06-21T12:00:00.000Z"}',
            200,
          ),
        ),
      );

      final result = await client.fetchTicker(symbol);
      expect(result, isA<Success<Ticker>>());
      result.when(
        success: (ticker) => expect(ticker.change24hPercent, 0.0),
        failure: (_) => fail('expected success'),
      );
    });

    test(
      'fetchTicker falls back to stats volume when quote volume is null',
      () async {
        final client = CoinbaseRestClient(
          httpClient: twoCallClient(
            statsResponse: http.Response(
              '{"open":"99.0","high":"110.0","low":"90.0","volume":"5000.0","last":"100.0","volume_30day":"50000.0"}',
              200,
            ),
            tickerResponse: http.Response(
              '{"trade_id":1,"price":"100.0","size":"1.0","bid":"99.5","ask":"100.5","time":"2024-06-21T12:00:00.000Z"}',
              200,
            ),
          ),
        );

        final result = await client.fetchTicker(symbol);
        expect(result, isA<Success<Ticker>>());
        result.when(
          success: (ticker) => expect(ticker.volume, 5000.0),
          failure: (_) => fail('expected success'),
        );
      },
    );

    test('fetchCandles returns NetworkFailure on request exception', () async {
      final client = CoinbaseRestClient(
        httpClient: MockClient((_) async => throw Exception('timeout')),
      );
      final result = await client.fetchCandles(symbol, Timeframe.h1);
      expect(result, isA<Err<List<Candle>>>());
      result.when(
        success: (_) => fail('expected failure'),
        failure: (failure) {
          expect(failure, isA<NetworkFailure>());
          expect(
            failure.message,
            'Coinbase candles request failed: Exception: timeout',
          );
        },
      );
    });

    test('fetchCandles returns ParseFailure on non-numeric values', () async {
      final client = CoinbaseRestClient(
        httpClient: MockClient(
          (_) async =>
              http.Response('[["not-a-time",0.5,2.0,1.0,1.5,100.0]]', 200),
        ),
      );

      final result = await client.fetchCandles(symbol, Timeframe.h1, limit: 1);
      expect(result, isA<Err<List<Candle>>>());
      result.when(
        success: (_) => fail('expected failure'),
        failure: (failure) {
          expect(failure, isA<ParseFailure>());
          expect(failure.message, startsWith('Coinbase candles parse failed:'));
          expect(failure.message, contains('FormatException'));
        },
      );
    });

    test('fetchOrderBook returns ParseFailure on malformed JSON', () async {
      final client = CoinbaseRestClient(
        httpClient: MockClient((_) async => http.Response('not-json', 200)),
      );
      final result = await client.fetchOrderBook(symbol);
      expect(result, isA<Err<OrderBook>>());
      result.when(
        success: (_) => fail('expected failure'),
        failure: (failure) {
          expect(failure, isA<ParseFailure>());
          expect(
            failure.message,
            startsWith('Coinbase order book parse failed:'),
          );
        },
      );
    });

    test(
      'fetchOrderBook returns NetworkFailure on request exception',
      () async {
        final client = CoinbaseRestClient(
          httpClient: MockClient((_) async => throw Exception('timeout')),
        );
        final result = await client.fetchOrderBook(symbol);
        expect(result, isA<Err<OrderBook>>());
        result.when(
          success: (_) => fail('expected failure'),
          failure: (failure) {
            expect(failure, isA<NetworkFailure>());
            expect(
              failure.message,
              'Coinbase order book request failed: Exception: timeout',
            );
          },
        );
      },
    );

    test('fetchTrades returns NetworkFailure on request exception', () async {
      final client = CoinbaseRestClient(
        httpClient: MockClient((_) async => throw Exception('timeout')),
      );
      final result = await client.fetchTrades(symbol);
      expect(result, isA<Err<List<Trade>>>());
      result.when(
        success: (_) => fail('expected failure'),
        failure: (failure) {
          expect(failure, isA<NetworkFailure>());
          expect(
            failure.message,
            'Coinbase trades request failed: Exception: timeout',
          );
        },
      );
    });

    test(
      'fetchTicker returns ParseFailure on missing required fields',
      () async {
        final client = CoinbaseRestClient(
          httpClient: twoCallClient(
            statsResponse: http.Response('{"open":"99.0"}', 200),
            tickerResponse: http.Response('{"trade_id":1}', 200),
          ),
        );

        final result = await client.fetchTicker(symbol);
        expect(result, isA<Err<Ticker>>());
        result.when(
          success: (_) => fail('expected failure'),
          failure: (failure) {
            expect(failure, isA<ParseFailure>());
            expect(
              failure.message,
              startsWith('Coinbase ticker parse failed:'),
            );
            expect(failure.message, contains("type 'Null'"));
          },
        );
      },
    );

    test('fetchTicker returns NetworkFailure on request exception', () async {
      final client = CoinbaseRestClient(
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
            'Coinbase ticker request failed: Exception: timeout',
          );
        },
      );
    });

    test('fetchCandles returns ParseFailure on empty list element', () async {
      final client = CoinbaseRestClient(
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
          expect(failure.message, startsWith('Coinbase candles parse failed:'));
          expect(failure.message, contains('FormatException'));
        },
      );
    });

    test('fetchCandles returns ParseFailure on empty outer array', () async {
      final client = CoinbaseRestClient(
        httpClient: MockClient((_) async => http.Response('[]', 200)),
      );

      final result = await client.fetchCandles(symbol, Timeframe.h1);
      expect(result, isA<Err<List<Candle>>>());
      result.when(
        success: (_) => fail('expected failure'),
        failure: (failure) {
          expect(failure, isA<ParseFailure>());
          expect(
            failure.message,
            'Coinbase candles parse failed: empty response',
          );
        },
      );
    });

    test('fetchTrades returns ParseFailure on negative price', () async {
      final client = CoinbaseRestClient(
        httpClient: MockClient(
          (_) async => http.Response(
            '[{"time":"2024-06-21T12:00:00.000Z","trade_id":1,"price":"-100.0","size":"1.0","side":"buy"}]',
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
          expect(failure.message, startsWith('Coinbase trades parse failed:'));
        },
      );
    });

    test('fetchTrades returns ParseFailure on negative size', () async {
      final client = CoinbaseRestClient(
        httpClient: MockClient(
          (_) async => http.Response(
            '[{"time":"2024-06-21T12:00:00.000Z","trade_id":1,"price":"100.0","size":"-1.0","side":"buy"}]',
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
          expect(failure.message, startsWith('Coinbase trades parse failed:'));
        },
      );
    });

    test('fetchTrades returns ParseFailure on unknown side', () async {
      final client = CoinbaseRestClient(
        httpClient: MockClient(
          (_) async => http.Response(
            '[{"time":"2024-06-21T12:00:00.000Z","trade_id":1,"price":"100.0","size":"1.0","side":"unknown"}]',
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
              'Coinbase trades parse failed: FormatException: Unknown trade side: unknown',
            ),
          );
        },
      );
    });

    test(
      'fetchTicker returns NetworkFailure when stats succeeds but quote throws',
      () async {
        final client = CoinbaseRestClient(
          httpClient: MockClient((request) async {
            if (request.url.path == '/products/BTC-USD/stats') {
              return http.Response(
                '{"open":"99.0","volume":"1000.0","last":"100.0"}',
                200,
              );
            }
            throw Exception('quote boom');
          }),
        );

        final result = await client.fetchTicker(symbol);
        expect(result, isA<Err<Ticker>>());
        result.when(
          success: (_) => fail('expected failure'),
          failure: (failure) {
            expect(failure, isA<NetworkFailure>());
            expect(
              failure.message,
              'Coinbase ticker request failed: Exception: quote boom',
            );
          },
        );
      },
    );

    test('fetchTicker returns ParseFailure when quote time is missing', () async {
      final client = CoinbaseRestClient(
        httpClient: twoCallClient(
          statsResponse: http.Response(
            '{"open":"99.0","volume":"1000.0","last":"100.0"}',
            200,
          ),
          tickerResponse: http.Response(
            '{"trade_id":1,"price":"100.0","bid":"99.5","ask":"100.5","volume":"1000.0"}',
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
          expect(failure.message, startsWith('Coinbase ticker parse failed:'));
        },
      );
    });

    test('fetchTicker returns ParseFailure when quote time is invalid', () async {
      final client = CoinbaseRestClient(
        httpClient: twoCallClient(
          statsResponse: http.Response(
            '{"open":"99.0","volume":"1000.0","last":"100.0"}',
            200,
          ),
          tickerResponse: http.Response(
            '{"trade_id":1,"price":"100.0","bid":"99.5","ask":"100.5","volume":"1000.0","time":"not-a-time"}',
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
          expect(failure.message, startsWith('Coinbase ticker parse failed:'));
          expect(failure.message, contains('FormatException'));
        },
      );
    });

    test('fetchTicker change24hPercent with negative open', () async {
      final client = CoinbaseRestClient(
        httpClient: twoCallClient(
          statsResponse: http.Response(
            '{"open":"-100.0","high":"110.0","low":"90.0","volume":"1000.0","last":"100.0","volume_30day":"50000.0"}',
            200,
          ),
          tickerResponse: http.Response(
            '{"trade_id":1,"price":"100.0","size":"1.0","bid":"99.5","ask":"100.5","volume":"1000.0","time":"2024-06-21T12:00:00.000Z"}',
            200,
          ),
        ),
      );

      final result = await client.fetchTicker(symbol);
      expect(result, isA<Success<Ticker>>());
      result.when(
        success: (ticker) {
          expect(ticker.change24h, 200.0);
          expect(ticker.change24hPercent, -2.0);
        },
        failure: (_) => fail('expected success'),
      );
    });

    test('fetchOrderBook returns ParseFailure when bids are missing', () async {
      final client = CoinbaseRestClient(
        httpClient: MockClient(
          (_) async =>
              http.Response('{"sequence":1,"asks":[["100.5","1",1]]}', 200),
        ),
      );

      final result = await client.fetchOrderBook(symbol);
      expect(result, isA<Err<OrderBook>>());
      result.when(
        success: (_) => fail('expected failure'),
        failure: (failure) {
          expect(failure, isA<ParseFailure>());
          expect(
            failure.message,
            startsWith('Coinbase order book parse failed:'),
          );
        },
      );
    });

    test('fetchOrderBook returns ParseFailure when asks are missing', () async {
      final client = CoinbaseRestClient(
        httpClient: MockClient(
          (_) async =>
              http.Response('{"sequence":1,"bids":[["99.5","1",1]]}', 200),
        ),
      );

      final result = await client.fetchOrderBook(symbol);
      expect(result, isA<Err<OrderBook>>());
      result.when(
        success: (_) => fail('expected failure'),
        failure: (failure) {
          expect(failure, isA<ParseFailure>());
          expect(
            failure.message,
            startsWith('Coinbase order book parse failed:'),
          );
        },
      );
    });

    test('fetchTicker returns NetworkFailure on timeout', () async {
      final client = CoinbaseRestClient(
        httpClient: MockClient(
          (_) async => throw TimeoutException('timed out'),
        ),
      );

      final result = await client.fetchTicker(symbol);
      expect(result, isA<Err<Ticker>>());
      result.when(
        success: (_) => fail('expected failure'),
        failure: (failure) {
          expect(failure, isA<NetworkFailure>());
          expect(failure.message, 'Coinbase ticker stats request timed out');
        },
      );
    });

    test('fetchCandles returns NetworkFailure on timeout', () async {
      final client = CoinbaseRestClient(
        httpClient: MockClient(
          (_) async => throw TimeoutException('timed out'),
        ),
      );

      final result = await client.fetchCandles(symbol, Timeframe.h1);
      expect(result, isA<Err<List<Candle>>>());
      result.when(
        success: (_) => fail('expected failure'),
        failure: (failure) {
          expect(failure, isA<NetworkFailure>());
          expect(failure.message, 'Coinbase candles request timed out');
        },
      );
    });

    test('fetchOrderBook returns NetworkFailure on timeout', () async {
      final client = CoinbaseRestClient(
        httpClient: MockClient(
          (_) async => throw TimeoutException('timed out'),
        ),
      );

      final result = await client.fetchOrderBook(symbol);
      expect(result, isA<Err<OrderBook>>());
      result.when(
        success: (_) => fail('expected failure'),
        failure: (failure) {
          expect(failure, isA<NetworkFailure>());
          expect(failure.message, 'Coinbase order book request timed out');
        },
      );
    });

    test('fetchTrades returns NetworkFailure on timeout', () async {
      final client = CoinbaseRestClient(
        httpClient: MockClient(
          (_) async => throw TimeoutException('timed out'),
        ),
      );

      final result = await client.fetchTrades(symbol);
      expect(result, isA<Err<List<Trade>>>());
      result.when(
        success: (_) => fail('expected failure'),
        failure: (failure) {
          expect(failure, isA<NetworkFailure>());
          expect(failure.message, 'Coinbase trades request timed out');
        },
      );
    });
  });
}
