import 'package:flutter_test/flutter_test.dart';
import 'package:youtrade/core/failures.dart';
import 'package:youtrade/core/result.dart';
import 'package:youtrade/data/datasources/remote/okx/okx_websocket_client.dart';
import 'package:youtrade/domain/entities/order_book.dart';
import 'package:youtrade/domain/entities/symbol.dart';
import 'package:youtrade/domain/entities/ticker.dart';
import 'package:youtrade/domain/entities/trade.dart';
import 'package:youtrade/domain/entities/venue.dart';

import '../../../../fakes/fake_websocket_channel.dart';

void main() {
  group('OKXWebSocketClient', () {
    final symbol = TradingSymbol(
      base: 'BTC',
      quote: 'USDT',
      venue: Venue.okx,
      rawSymbol: 'BTCUSDT',
    );

    test('watchTicker sends subscribe and parses ticker message', () async {
      late FakeWebSocketChannel channel;
      final outgoing = <dynamic>[];
      final client = OKXWebSocketClient(
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
      expect(outgoing.first, contains('"op":"subscribe"'));
      expect(outgoing.first, contains('"channel":"tickers"'));
      expect(outgoing.first, contains('"instId":"BTC-USDT"'));

      channel.add(
        '{"arg":{"channel":"tickers","instId":"BTC-USDT"},"data":[{"instId":"BTC-USDT","last":"100.0","bidPx":"99.5","askPx":"100.5","open24h":"99.0","vol24h":"1000.0","ts":"1718952000000"}]}',
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
      final client = OKXWebSocketClient(
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
      expect(outgoing.first, contains('"channel":"books"'));

      channel.add(
        '{"arg":{"channel":"books","instId":"BTC-USDT"},"action":"snapshot","data":[{"bids":[["99.0","1.0","0","1"]],"asks":[["101.0","1.0","0","1"]],"ts":"1718952000000"}]}',
      );

      final result = await future;
      expect(result, isA<Success<OrderBook>>());
      result.when(
        success: (orderBook) {
          expect(orderBook.bids.first.price, 99.0);
          expect(orderBook.asks.first.price, 101.0);
        },
        failure: (_) => fail('expected success'),
      );
    });

    test('watchTrades sends subscribe and parses trade message', () async {
      late FakeWebSocketChannel channel;
      final outgoing = <dynamic>[];
      final client = OKXWebSocketClient(
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
      expect(outgoing.first, contains('"channel":"trades"'));

      channel.add(
        '{"arg":{"channel":"trades","instId":"BTC-USDT"},"data":[{"instId":"BTC-USDT","tradeId":"1","px":"100.0","sz":"1.0","side":"buy","ts":"1718952000000"}]}',
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

    test('watchTicker closes sink when subscription is cancelled', () async {
      late FakeWebSocketChannel channel;
      final client = OKXWebSocketClient(
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
      final client = OKXWebSocketClient(
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
      final client = OKXWebSocketClient(
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
      final client = OKXWebSocketClient(
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
            startsWith('OKX WS ticker parse failed: FormatException'),
          );
        },
      );
    });

    test('watchTicker emits ParseFailure on empty data list', () async {
      late FakeWebSocketChannel channel;
      final client = OKXWebSocketClient(
        channelFactory: (url) {
          channel = FakeWebSocketChannel();
          return channel;
        },
      );

      final future = client.watchTicker(symbol).first;
      await Future.delayed(Duration.zero);
      channel.add(
        '{"arg":{"channel":"tickers","instId":"BTC-USDT"},"data":[]}',
      );

      final result = await future;
      expect(result, isA<Err<Ticker>>());
      result.when(
        success: (_) => fail('expected failure'),
        failure: (failure) {
          expect(failure, isA<ParseFailure>());
          expect(failure.message, startsWith('OKX WS ticker parse failed:'));
          expect(failure.message, contains('Bad state'));
        },
      );
    });

    test('watchTicker emits UnknownFailure on stream error', () async {
      late FakeWebSocketChannel channel;
      final client = OKXWebSocketClient(
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
          expect(failure.message, 'OKX WS ticker error');
          expect((failure as UnknownFailure).error, error);
        },
      );
    });

    test('watchTicker ignores subscription ack without data list', () async {
      late FakeWebSocketChannel channel;
      final client = OKXWebSocketClient(
        channelFactory: (url) {
          channel = FakeWebSocketChannel();
          return channel;
        },
      );

      final future = client.watchTicker(symbol).first;
      await Future.delayed(Duration.zero);

      channel.add(
        '{"event":"subscribe","arg":{"channel":"tickers","instId":"BTC-USDT"}}',
      );
      channel.add(
        '{"arg":{"channel":"tickers","instId":"BTC-USDT"},"data":[{"instId":"BTC-USDT","last":"100.0","bidPx":"99.5","askPx":"100.5","open24h":"99.0","vol24h":"1000.0","ts":"1718952000000"}]}',
      );

      final result = await future;
      expect(result, isA<Success<Ticker>>());
    });

    test('watchOrderBook emits UnknownFailure on stream error', () async {
      late FakeWebSocketChannel channel;
      final client = OKXWebSocketClient(
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
          expect(failure.message, 'OKX WS order book error');
          expect((failure as UnknownFailure).error, error);
        },
      );
    });

    test('watchTrades emits UnknownFailure on stream error', () async {
      late FakeWebSocketChannel channel;
      final client = OKXWebSocketClient(
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
          expect(failure.message, 'OKX WS trades error');
          expect((failure as UnknownFailure).error, error);
        },
      );
    });

    test('watchTicker emits UnknownFailure on connection failure', () async {
      late FakeWebSocketChannel channel;
      final client = OKXWebSocketClient(
        channelFactory: (url) {
          channel = FakeWebSocketChannel(
            ready: Future.error(Exception('connect failed')),
          );
          return channel;
        },
      );

      final error = await client.watchTicker(symbol).first;
      expect(error, isA<Err<Ticker>>());
      error.when(
        success: (_) => fail('expected failure'),
        failure: (failure) {
          expect(failure, isA<UnknownFailure>());
          expect(failure.message, 'OKX WS ticker error');
          expect((failure as UnknownFailure).error, isA<Exception>());
        },
      );
    });

    test('watchOrderBook emits UnknownFailure on connection failure', () async {
      late FakeWebSocketChannel channel;
      final client = OKXWebSocketClient(
        channelFactory: (url) {
          channel = FakeWebSocketChannel(
            ready: Future.error(Exception('connect failed')),
          );
          return channel;
        },
      );

      final error = await client.watchOrderBook(symbol).first;
      expect(error, isA<Err<OrderBook>>());
    });

    test('watchTrades emits UnknownFailure on connection failure', () async {
      late FakeWebSocketChannel channel;
      final client = OKXWebSocketClient(
        channelFactory: (url) {
          channel = FakeWebSocketChannel(
            ready: Future.error(Exception('connect failed')),
          );
          return channel;
        },
      );

      final error = await client.watchTrades(symbol).first;
      expect(error, isA<Err<List<Trade>>>());
    });

    test('watchOrderBook parses delta message', () async {
      late FakeWebSocketChannel channel;
      final client = OKXWebSocketClient(
        channelFactory: (url) {
          channel = FakeWebSocketChannel();
          return channel;
        },
      );

      final future = client.watchOrderBook(symbol).first;
      await Future.delayed(Duration.zero);
      channel.add(
        '{"arg":{"channel":"books","instId":"BTC-USDT"},"action":"update","data":[{"bids":[["99.0","1.0","0","1"]],"asks":[["101.0","1.0","0","1"]],"ts":"1718952000000"}]}',
      );

      final result = await future;
      expect(result, isA<Success<OrderBook>>());
      result.when(
        success: (orderBook) {
          expect(orderBook.bids.first.price, 99.0);
          expect(orderBook.asks.first.price, 101.0);
        },
        failure: (_) => fail('expected success'),
      );
    });
  });
}
