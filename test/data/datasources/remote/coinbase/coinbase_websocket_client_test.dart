import 'package:flutter_test/flutter_test.dart';
import 'package:youtrade/core/failures.dart';
import 'package:youtrade/core/result.dart';
import 'package:youtrade/data/datasources/remote/coinbase/coinbase_websocket_client.dart';
import 'package:youtrade/domain/entities/order_book.dart';
import 'package:youtrade/domain/entities/symbol.dart';
import 'package:youtrade/domain/entities/ticker.dart';
import 'package:youtrade/domain/entities/trade.dart';
import 'package:youtrade/domain/entities/venue.dart';

import '../../../../fakes/fake_websocket_channel.dart';

void main() {
  group('CoinbaseWebSocketClient', () {
    final symbol = TradingSymbol(
      base: 'BTC',
      quote: 'USD',
      venue: Venue.coinbase,
      rawSymbol: 'BTCUSD',
    );

    test('watchTicker sends subscribe and parses ticker message', () async {
      late FakeWebSocketChannel channel;
      final outgoing = <dynamic>[];
      final client = CoinbaseWebSocketClient(
        channelFactory: (url) {
          channel = FakeWebSocketChannel();
          channel.outgoingStream.listen(outgoing.add);
          return channel;
        },
      );

      final values = client.watchTicker(symbol);
      final future = values.first;
      await Future.delayed(Duration.zero);

      expect(outgoing.length, 1);
      expect(outgoing.first, contains('"type":"subscribe"'));
      expect(outgoing.first, contains('"channels":["ticker"]'));
      expect(outgoing.first, contains('"product_ids":["BTC-USD"]'));

      channel.add(
        '{"type":"ticker","sequence":1,"product_id":"BTC-USD","price":"100.0","open_24h":"99.0","volume_24h":"1000.0","low_24h":"90.0","high_24h":"110.0","best_bid":"99.5","best_ask":"100.5","time":"2024-06-21T12:00:00.000Z","trade_id":1,"last_size":"1.0"}',
      );

      final result = await future;
      expect(result, isA<Success<Ticker>>());
      result.when(
        success: (ticker) {
          expect(ticker.lastPrice, 100.0);
          expect(ticker.bid, 99.5);
          expect(ticker.ask, 100.5);
          expect(ticker.change24h, 1.0);
          expect(ticker.volume, 1000.0);
        },
        failure: (_) => fail('expected success'),
      );
    });

    test('watchOrderBook sends subscribe and parses snapshot message', () async {
      late FakeWebSocketChannel channel;
      final outgoing = <dynamic>[];
      final client = CoinbaseWebSocketClient(
        channelFactory: (url) {
          channel = FakeWebSocketChannel();
          channel.outgoingStream.listen(outgoing.add);
          return channel;
        },
      );

      final values = client.watchOrderBook(symbol);
      final future = values.first;
      await Future.delayed(Duration.zero);

      expect(outgoing.length, 1);
      expect(outgoing.first, contains('"channels":["level2"]'));

      channel.add(
        '{"type":"snapshot","product_id":"BTC-USD","bids":[["99.5","1"]],"asks":[["100.5","1"]]}',
      );

      final result = await future;
      expect(result, isA<Success<OrderBook>>());
      result.when(
        success: (orderBook) {
          expect(orderBook.bids.first.price, 99.5);
          expect(orderBook.asks.first.price, 100.5);
        },
        failure: (_) => fail('expected success'),
      );
    });

    test('watchTrades sends subscribe and parses match message', () async {
      late FakeWebSocketChannel channel;
      final outgoing = <dynamic>[];
      final client = CoinbaseWebSocketClient(
        channelFactory: (url) {
          channel = FakeWebSocketChannel();
          channel.outgoingStream.listen(outgoing.add);
          return channel;
        },
      );

      final values = client.watchTrades(symbol);
      final future = values.first;
      await Future.delayed(Duration.zero);

      expect(outgoing.length, 1);
      expect(outgoing.first, contains('"channels":["matches"]'));

      channel.add(
        '{"type":"match","trade_id":1,"sequence":1,"maker_order_id":"m1","taker_order_id":"t1","time":"2024-06-21T12:00:00.000Z","product_id":"BTC-USD","size":"1.0","price":"100.0","side":"buy"}',
      );

      final result = await future;
      expect(result, isA<Success<List<Trade>>>());
      result.when(
        success: (trades) {
          expect(trades.length, 1);
          expect(trades.first.price, 100.0);
        },
        failure: (_) => fail('expected success'),
      );
    });

    test('watchTicker ignores non-ticker messages', () async {
      late FakeWebSocketChannel channel;
      final client = CoinbaseWebSocketClient(
        channelFactory: (url) {
          channel = FakeWebSocketChannel();
          return channel;
        },
      );

      final future = client.watchTicker(symbol).first;
      await Future.delayed(Duration.zero);

      channel.add('{"type":"subscriptions"}');
      channel.add(
        '{"type":"ticker","sequence":1,"product_id":"BTC-USD","price":"100.0","open_24h":"99.0","volume_24h":"1000.0","low_24h":"90.0","high_24h":"110.0","best_bid":"99.5","best_ask":"100.5","time":"2024-06-21T12:00:00.000Z","trade_id":1,"last_size":"1.0"}',
      );

      final result = await future;
      expect(result, isA<Success<Ticker>>());
    });

    test('watchTicker closes sink when subscription is cancelled', () async {
      late FakeWebSocketChannel channel;
      final client = CoinbaseWebSocketClient(
        channelFactory: (url) {
          channel = FakeWebSocketChannel();
          return channel;
        },
      );

      final subscription = client.watchTicker(symbol).listen(null);
      await Future.delayed(Duration.zero);

      expect(channel.sink.closed, isFalse);

      await subscription.cancel();

      expect(channel.sink.closed, isTrue);
    });

    test('watchOrderBook closes sink when subscription is cancelled', () async {
      late FakeWebSocketChannel channel;
      final client = CoinbaseWebSocketClient(
        channelFactory: (url) {
          channel = FakeWebSocketChannel();
          return channel;
        },
      );

      final subscription = client.watchOrderBook(symbol).listen(null);
      await Future.delayed(Duration.zero);

      expect(channel.sink.closed, isFalse);

      await subscription.cancel();

      expect(channel.sink.closed, isTrue);
    });

    test('watchTrades closes sink when subscription is cancelled', () async {
      late FakeWebSocketChannel channel;
      final client = CoinbaseWebSocketClient(
        channelFactory: (url) {
          channel = FakeWebSocketChannel();
          return channel;
        },
      );

      final subscription = client.watchTrades(symbol).listen(null);
      await Future.delayed(Duration.zero);

      expect(channel.sink.closed, isFalse);

      await subscription.cancel();

      expect(channel.sink.closed, isTrue);
    });

    test('watchTicker emits ParseFailure on malformed message', () async {
      late FakeWebSocketChannel channel;
      final client = CoinbaseWebSocketClient(
        channelFactory: (url) {
          channel = FakeWebSocketChannel();
          return channel;
        },
      );

      final future = client.watchTicker(symbol).first;
      await Future.delayed(Duration.zero);
      channel.add('not-json');

      final result = await future;
      expect(result, isA<Err<Ticker>>());
      result.when(
        success: (_) => fail('expected failure'),
        failure: (failure) {
          expect(failure, isA<ParseFailure>());
          expect(
            failure.message,
            startsWith('Coinbase WS ticker parse failed: FormatException'),
          );
        },
      );
    });

    test('watchTicker emits ParseFailure on missing required fields', () async {
      late FakeWebSocketChannel channel;
      final client = CoinbaseWebSocketClient(
        channelFactory: (url) {
          channel = FakeWebSocketChannel();
          return channel;
        },
      );

      final future = client.watchTicker(symbol).first;
      await Future.delayed(Duration.zero);
      channel.add('{"type":"ticker","product_id":"BTC-USD"}');

      final result = await future;
      expect(result, isA<Err<Ticker>>());
      result.when(
        success: (_) => fail('expected failure'),
        failure: (failure) {
          expect(failure, isA<ParseFailure>());
          expect(
            failure.message,
            startsWith('Coinbase WS ticker parse failed:'),
          );
          expect(failure.message, contains("type 'Null'"));
        },
      );
    });

    test('watchTicker emits UnknownFailure on stream error', () async {
      late FakeWebSocketChannel channel;
      final client = CoinbaseWebSocketClient(
        channelFactory: (url) {
          channel = FakeWebSocketChannel();
          return channel;
        },
      );

      final error = Exception('ws error');
      final future = client.watchTicker(symbol).first;
      await Future.delayed(Duration.zero);
      channel.addError(error);

      final result = await future;
      expect(result, isA<Err<Ticker>>());
      result.when(
        success: (_) => fail('expected failure'),
        failure: (failure) {
          expect(failure, isA<UnknownFailure>());
          expect(failure.message, 'Coinbase WS ticker error');
          expect((failure as UnknownFailure).error, error);
        },
      );
    });

    test('watchOrderBook emits UnknownFailure on stream error', () async {
      late FakeWebSocketChannel channel;
      final client = CoinbaseWebSocketClient(
        channelFactory: (url) {
          channel = FakeWebSocketChannel();
          return channel;
        },
      );

      final error = Exception('ws error');
      final future = client.watchOrderBook(symbol).first;
      await Future.delayed(Duration.zero);
      channel.addError(error);

      final result = await future;
      expect(result, isA<Err<OrderBook>>());
      result.when(
        success: (_) => fail('expected failure'),
        failure: (failure) {
          expect(failure, isA<UnknownFailure>());
          expect(failure.message, 'Coinbase WS order book error');
          expect((failure as UnknownFailure).error, error);
        },
      );
    });

    test('watchTrades emits UnknownFailure on stream error', () async {
      late FakeWebSocketChannel channel;
      final client = CoinbaseWebSocketClient(
        channelFactory: (url) {
          channel = FakeWebSocketChannel();
          return channel;
        },
      );

      final error = Exception('ws error');
      final future = client.watchTrades(symbol).first;
      await Future.delayed(Duration.zero);
      channel.addError(error);

      final result = await future;
      expect(result, isA<Err<List<Trade>>>());
      result.when(
        success: (_) => fail('expected failure'),
        failure: (failure) {
          expect(failure, isA<UnknownFailure>());
          expect(failure.message, 'Coinbase WS trade error');
          expect((failure as UnknownFailure).error, error);
        },
      );
    });

    test('watchTicker emits UnknownFailure on connection failure', () async {
      final client = CoinbaseWebSocketClient(
        channelFactory: (url) => FakeWebSocketChannel(
          ready: Future.error(Exception('connect failed')),
        ),
      );

      final error = await client.watchTicker(symbol).first;
      expect(error, isA<Err<Ticker>>());
      error.when(
        success: (_) => fail('expected failure'),
        failure: (failure) {
          expect(failure, isA<UnknownFailure>());
          expect(failure.message, 'Coinbase WS ticker error');
        },
      );
    });

    test('watchOrderBook emits UnknownFailure on connection failure', () async {
      final client = CoinbaseWebSocketClient(
        channelFactory: (url) => FakeWebSocketChannel(
          ready: Future.error(Exception('connect failed')),
        ),
      );

      final result = await client.watchOrderBook(symbol).first;
      expect(result, isA<Err<OrderBook>>());
      result.when(
        success: (_) => fail('expected failure'),
        failure: (failure) {
          expect(failure, isA<UnknownFailure>());
          expect(failure.message, 'Coinbase WS order book error');
        },
      );
    });

    test('watchTrades emits UnknownFailure on connection failure', () async {
      final client = CoinbaseWebSocketClient(
        channelFactory: (url) => FakeWebSocketChannel(
          ready: Future.error(Exception('connect failed')),
        ),
      );

      final result = await client.watchTrades(symbol).first;
      expect(result, isA<Err<List<Trade>>>());
      result.when(
        success: (_) => fail('expected failure'),
        failure: (failure) {
          expect(failure, isA<UnknownFailure>());
          expect(failure.message, 'Coinbase WS trade error');
        },
      );
    });

    test('watchOrderBook parses l2update message', () async {
      late FakeWebSocketChannel channel;
      final client = CoinbaseWebSocketClient(
        channelFactory: (url) {
          channel = FakeWebSocketChannel();
          return channel;
        },
      );

      final future = client.watchOrderBook(symbol).first;
      await Future.delayed(Duration.zero);
      channel.add(
        '{"type":"l2update","product_id":"BTC-USD","changes":[["buy","99.5","1"],["sell","100.5","1"]]}',
      );

      final result = await future;
      expect(result, isA<Success<OrderBook>>());
      result.when(
        success: (orderBook) {
          expect(orderBook.bids.first.price, 99.5);
          expect(orderBook.asks.first.price, 100.5);
        },
        failure: (_) => fail('expected success'),
      );
    });

    test('watchTicker ignores message for wrong product_id', () async {
      late FakeWebSocketChannel channel;
      final client = CoinbaseWebSocketClient(
        channelFactory: (url) {
          channel = FakeWebSocketChannel();
          return channel;
        },
      );

      final future = client.watchTicker(symbol).first;
      await Future.delayed(Duration.zero);

      channel.add(
        '{"type":"ticker","sequence":1,"product_id":"ETH-USD","price":"200.0","open_24h":"199.0","volume_24h":"1000.0","low_24h":"190.0","high_24h":"210.0","best_bid":"199.5","best_ask":"200.5","time":"2024-06-21T12:00:00.000Z","trade_id":1,"last_size":"1.0"}',
      );
      channel.add(
        '{"type":"ticker","sequence":2,"product_id":"BTC-USD","price":"100.0","open_24h":"99.0","volume_24h":"1000.0","low_24h":"90.0","high_24h":"110.0","best_bid":"99.5","best_ask":"100.5","time":"2024-06-21T12:00:00.000Z","trade_id":2,"last_size":"1.0"}',
      );

      final result = await future;
      expect(result, isA<Success<Ticker>>());
      result.when(
        success: (ticker) => expect(ticker.lastPrice, 100.0),
        failure: (_) => fail('expected success'),
      );
    });

    test('watchTrades returns ParseFailure on unknown side', () async {
      late FakeWebSocketChannel channel;
      final client = CoinbaseWebSocketClient(
        channelFactory: (url) {
          channel = FakeWebSocketChannel();
          return channel;
        },
      );

      final future = client.watchTrades(symbol).first;
      await Future.delayed(Duration.zero);
      channel.add(
        '{"type":"match","trade_id":1,"sequence":1,"maker_order_id":"m1","taker_order_id":"t1","time":"2024-06-21T12:00:00.000Z","product_id":"BTC-USD","size":"1.0","price":"100.0","side":"unknown"}',
      );

      final result = await future;
      expect(result, isA<Err<List<Trade>>>());
      result.when(
        success: (_) => fail('expected failure'),
        failure: (failure) {
          expect(failure, isA<ParseFailure>());
          expect(
            failure.message,
            startsWith('Coinbase WS trade parse failed:'),
          );
        },
      );
    });

    test('watchOrderBook handles empty bids and asks in snapshot', () async {
      late FakeWebSocketChannel channel;
      final client = CoinbaseWebSocketClient(
        channelFactory: (url) {
          channel = FakeWebSocketChannel();
          return channel;
        },
      );

      final future = client.watchOrderBook(symbol).first;
      await Future.delayed(Duration.zero);
      channel.add(
        '{"type":"snapshot","product_id":"BTC-USD","bids":[],"asks":[]}',
      );

      final result = await future;
      expect(result, isA<Success<OrderBook>>());
      result.when(
        success: (orderBook) {
          expect(orderBook.bids, isEmpty);
          expect(orderBook.asks, isEmpty);
        },
        failure: (_) => fail('expected success'),
      );
    });

    test('watchOrderBook handles empty changes in l2update', () async {
      late FakeWebSocketChannel channel;
      final client = CoinbaseWebSocketClient(
        channelFactory: (url) {
          channel = FakeWebSocketChannel();
          return channel;
        },
      );

      final future = client.watchOrderBook(symbol).first;
      await Future.delayed(Duration.zero);
      channel.add('{"type":"l2update","product_id":"BTC-USD","changes":[]}');

      final result = await future;
      expect(result, isA<Success<OrderBook>>());
      result.when(
        success: (orderBook) {
          expect(orderBook.bids, isEmpty);
          expect(orderBook.asks, isEmpty);
        },
        failure: (_) => fail('expected success'),
      );
    });

    test('watchTicker emits error then recovery', () async {
      late FakeWebSocketChannel channel;
      final client = CoinbaseWebSocketClient(
        channelFactory: (url) {
          channel = FakeWebSocketChannel();
          return channel;
        },
      );

      final values = client.watchTicker(symbol).take(2).toList();
      await Future.delayed(Duration.zero);

      channel.add('not-json');
      channel.add(
        '{"type":"ticker","sequence":1,"product_id":"BTC-USD","price":"100.0","open_24h":"99.0","volume_24h":"1000.0","low_24h":"90.0","high_24h":"110.0","best_bid":"99.5","best_ask":"100.5","time":"2024-06-21T12:00:00.000Z","trade_id":1,"last_size":"1.0"}',
      );

      final results = await values;
      expect(results.length, 2);
      expect(results[0], isA<Err<Ticker>>());
      expect(results[1], isA<Success<Ticker>>());
    });
  });
}
