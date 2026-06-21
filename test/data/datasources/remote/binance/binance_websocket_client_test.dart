import 'dart:async';

import 'package:async/async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:youtrade/core/failures.dart';
import 'package:youtrade/core/result.dart';
import 'package:youtrade/data/datasources/remote/binance/binance_websocket_client.dart';
import 'package:youtrade/domain/entities/order_book.dart';
import 'package:youtrade/domain/entities/symbol.dart';
import 'package:youtrade/domain/entities/ticker.dart';
import 'package:youtrade/domain/entities/venue.dart';

class _FakeWebSocketChannel extends StreamChannelMixin<dynamic>
    implements WebSocketChannel {
  _FakeWebSocketChannel() : _outgoing = StreamController<dynamic>.broadcast() {
    _sink = _FakeWebSocketSink(_outgoing.sink);
  }

  final StreamController<dynamic> _incoming = StreamController<dynamic>();
  final StreamController<dynamic> _outgoing;
  late final _FakeWebSocketSink _sink;

  void add(dynamic value) => _incoming.add(value);

  void addError(Object error, [StackTrace? stackTrace]) =>
      _incoming.addError(error, stackTrace);

  @override
  Stream<dynamic> get stream => _incoming.stream;

  @override
  _FakeWebSocketSink get sink => _sink;

  @override
  Future<void> get ready => Future.value();

  @override
  String? get protocol => null;

  @override
  int? get closeCode => null;

  @override
  String? get closeReason => null;
}

class _FakeWebSocketSink extends DelegatingStreamSink<dynamic>
    implements WebSocketSink {
  _FakeWebSocketSink(super.sink);

  bool closed = false;

  @override
  Future close([int? closeCode, String? closeReason]) {
    closed = true;
    return super.close();
  }
}

void main() {
  group('BinanceWebSocketClient', () {
    final symbol = TradingSymbol(
      base: 'BTC',
      quote: 'USDT',
      venue: Venue.binance,
      rawSymbol: 'BTCUSDT',
    );

    test('watchTicker parses mini ticker message', () async {
      late _FakeWebSocketChannel channel;
      final client = BinanceWebSocketClient(
        channelFactory: (_) {
          channel = _FakeWebSocketChannel();
          return channel;
        },
      );

      final values = client.watchTicker(symbol);
      final future = values.first;
      await Future.delayed(Duration.zero);

      channel.add(
        '{"e":"24hrTicker","E":1718952000000,"s":"BTCUSDT","c":"100.0","b":"99.5","a":"100.5","p":"1.0","P":"1.0","v":"1000.0"}',
      );

      final result = await future;
      expect(result, isA<Success>());
      result.when(
        success: (ticker) => expect(ticker.lastPrice, 100.0),
        failure: (_) => fail('expected success'),
      );
    });

    test('watchOrderBook parses depth message', () async {
      late _FakeWebSocketChannel channel;
      final client = BinanceWebSocketClient(
        channelFactory: (_) {
          channel = _FakeWebSocketChannel();
          return channel;
        },
      );

      final values = client.watchOrderBook(symbol);
      final future = values.first;
      await Future.delayed(Duration.zero);

      channel.add('{"b":[["99.0","1.0"]],"a":[["101.0","1.0"]]}');

      final result = await future;
      expect(result, isA<Success>());
      result.when(
        success: (orderBook) {
          expect(orderBook.bids.first.price, 99.0);
          expect(orderBook.asks.first.price, 101.0);
        },
        failure: (_) => fail('expected success'),
      );
    });

    test('watchTrades parses trade message', () async {
      late _FakeWebSocketChannel channel;
      final client = BinanceWebSocketClient(
        channelFactory: (_) {
          channel = _FakeWebSocketChannel();
          return channel;
        },
      );

      final values = client.watchTrades(symbol);
      final future = values.first;
      await Future.delayed(Duration.zero);

      channel.add(
        '{"e":"trade","E":1718952000000,"s":"BTCUSDT","t":1,"p":"100.0","q":"1.0","m":false,"T":1718952000000}',
      );

      final result = await future;
      expect(result, isA<Success>());
      result.when(
        success: (trades) {
          expect(trades.length, 1);
          expect(trades.first.price, 100.0);
        },
        failure: (_) => fail('expected success'),
      );
    });

    test('watchTicker closes sink when subscription is cancelled', () async {
      late _FakeWebSocketChannel channel;
      final client = BinanceWebSocketClient(
        channelFactory: (_) {
          channel = _FakeWebSocketChannel();
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
      late _FakeWebSocketChannel channel;
      final client = BinanceWebSocketClient(
        channelFactory: (_) {
          channel = _FakeWebSocketChannel();
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
      late _FakeWebSocketChannel channel;
      final client = BinanceWebSocketClient(
        channelFactory: (_) {
          channel = _FakeWebSocketChannel();
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
      late _FakeWebSocketChannel channel;
      final client = BinanceWebSocketClient(
        channelFactory: (_) {
          channel = _FakeWebSocketChannel();
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
            startsWith('Binance WS ticker parse failed: FormatException'),
          );
        },
      );
    });

    test('watchTicker emits ParseFailure on empty message', () async {
      late _FakeWebSocketChannel channel;
      final client = BinanceWebSocketClient(
        channelFactory: (_) {
          channel = _FakeWebSocketChannel();
          return channel;
        },
      );

      final future = client.watchTicker(symbol).first;
      await Future.delayed(Duration.zero);
      channel.add('');

      final result = await future;
      expect(result, isA<Err<Ticker>>());
      result.when(
        success: (_) => fail('expected failure'),
        failure: (failure) {
          expect(failure, isA<ParseFailure>());
          expect(
            failure.message,
            startsWith('Binance WS ticker parse failed: FormatException'),
          );
        },
      );
    });

    test('watchTicker emits ParseFailure on missing required fields', () async {
      late _FakeWebSocketChannel channel;
      final client = BinanceWebSocketClient(
        channelFactory: (_) {
          channel = _FakeWebSocketChannel();
          return channel;
        },
      );

      final future = client.watchTicker(symbol).first;
      await Future.delayed(Duration.zero);
      channel.add('{}');

      final result = await future;
      expect(result, isA<Err<Ticker>>());
      result.when(
        success: (_) => fail('expected failure'),
        failure: (failure) {
          expect(failure, isA<ParseFailure>());
          expect(
            failure.message,
            startsWith('Binance WS ticker parse failed:'),
          );
          expect(failure.message, contains("type 'Null'"));
        },
      );
    });

    test('watchTicker emits UnknownFailure on stream error', () async {
      late _FakeWebSocketChannel channel;
      final client = BinanceWebSocketClient(
        channelFactory: (_) {
          channel = _FakeWebSocketChannel();
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
          expect(failure.message, 'Binance WS ticker error');
          expect((failure as UnknownFailure).error, error);
        },
      );
    });

    test('watchOrderBook parses depth update delta message', () async {
      late _FakeWebSocketChannel channel;
      final client = BinanceWebSocketClient(
        channelFactory: (_) {
          channel = _FakeWebSocketChannel();
          return channel;
        },
      );

      final future = client.watchOrderBook(symbol).first;
      await Future.delayed(Duration.zero);
      channel.add(
        '{"e":"depthUpdate","E":1718952000000,"s":"BTCUSDT","b":[["99.0","1.0"]],"a":[["101.0","1.0"]]}',
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
