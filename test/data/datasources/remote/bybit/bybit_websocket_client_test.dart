import 'dart:async';

import 'package:async/async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:youtrade/core/failures.dart';
import 'package:youtrade/core/result.dart';
import 'package:youtrade/data/datasources/remote/bybit/bybit_websocket_client.dart';
import 'package:youtrade/domain/entities/order_book.dart';
import 'package:youtrade/domain/entities/symbol.dart';
import 'package:youtrade/domain/entities/ticker.dart';
import 'package:youtrade/domain/entities/trade.dart';
import 'package:youtrade/domain/entities/venue.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class _FakeWebSocketChannel extends StreamChannelMixin<dynamic>
    implements WebSocketChannel {
  _FakeWebSocketChannel({Future<void>? ready})
    : _ready = ready ?? Future.value(),
      _outgoing = StreamController<dynamic>.broadcast() {
    _sink = _FakeWebSocketSink(_outgoing.sink);
  }

  final Future<void> _ready;
  final StreamController<dynamic> _incoming = StreamController<dynamic>();
  final StreamController<dynamic> _outgoing;
  late final _FakeWebSocketSink _sink;

  void add(dynamic value) => _incoming.add(value);

  void addError(Object error, [StackTrace? stackTrace]) =>
      _incoming.addError(error, stackTrace);

  Stream<dynamic> get outgoingStream => _outgoing.stream;

  @override
  Stream<dynamic> get stream => _incoming.stream;

  @override
  _FakeWebSocketSink get sink => _sink;

  @override
  Future<void> get ready => _ready;

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

class _StateErrorSink extends DelegatingStreamSink<dynamic>
    implements WebSocketSink {
  _StateErrorSink(super.sink);

  bool closed = false;

  @override
  Future close([int? closeCode, String? closeReason]) {
    closed = true;
    return super.close();
  }

  @override
  void add(dynamic value) {
    throw StateError('sink is closed');
  }
}

class _StateErrorChannel extends StreamChannelMixin<dynamic>
    implements WebSocketChannel {
  _StateErrorChannel({Future<void>? ready})
    : _ready = ready ?? Future.value(),
      _outgoing = StreamController<dynamic>.broadcast() {
    _sink = _StateErrorSink(_outgoing.sink);
  }

  final Future<void> _ready;
  final StreamController<dynamic> _incoming = StreamController<dynamic>();
  final StreamController<dynamic> _outgoing;
  late final _StateErrorSink _sink;

  void add(dynamic value) => _incoming.add(value);

  void addError(Object error, [StackTrace? stackTrace]) =>
      _incoming.addError(error, stackTrace);

  @override
  Stream<dynamic> get stream => _incoming.stream;

  @override
  _StateErrorSink get sink => _sink;

  @override
  Future<void> get ready => _ready;

  @override
  String? get protocol => null;

  @override
  int? get closeCode => null;

  @override
  String? get closeReason => null;
}

void main() {
  group('BybitWebSocketClient', () {
    final symbol = TradingSymbol(
      base: 'BTC',
      quote: 'USDT',
      venue: Venue.bybit,
      rawSymbol: 'BTCUSDT',
    );

    test('watchTicker sends subscribe and parses ticker message', () async {
      late _FakeWebSocketChannel channel;
      final outgoing = <dynamic>[];
      final client = BybitWebSocketClient(
        channelFactory: (url) {
          channel = _FakeWebSocketChannel();
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
      expect(outgoing.first, contains('"symbol":"BTCUSDT"'));

      channel.add(
        '{"topic":"tickers.BTCUSDT","ts":1718952000000,"data":{"symbol":"BTCUSDT","lastPrice":"100.0","bid1Price":"99.5","ask1Price":"100.5","price24hPcnt":"0.01","turnover24h":"1000.0","volume24h":"1000.0"}}',
      );

      final result = await future;
      expect(result, isA<Success<Ticker>>());
      result.when(
        success: (ticker) {
          expect(ticker.lastPrice, 100.0);
          expect(ticker.bid, 99.5);
          expect(ticker.ask, 100.5);
          expect(ticker.change24h, 0.0);
          expect(ticker.change24hPercent, 1.0);
          expect(ticker.volume, 1000.0);
          expect(
            DateTime.now().toUtc().difference(ticker.timestamp).inSeconds,
            lessThan(5),
          );
        },
        failure: (_) => fail('expected success'),
      );
    });

    test('watchOrderBook sends subscribe and parses orderbook message', () async {
      late _FakeWebSocketChannel channel;
      final outgoing = <dynamic>[];
      final client = BybitWebSocketClient(
        channelFactory: (url) {
          channel = _FakeWebSocketChannel();
          channel.outgoingStream.listen(outgoing.add);
          return channel;
        },
      );

      final values = client.watchOrderBook(symbol);
      final future = values.first;
      await Future.delayed(Duration.zero);

      expect(outgoing.length, 1);
      expect(outgoing.first, contains('"channel":"orderbook"'));

      channel.add(
        '{"topic":"orderbook.1.BTCUSDT","ts":1718952000000,"type":"snapshot","data":{"s":"BTCUSDT","b":[["99.0","1.0"]],"a":[["101.0","1.0"]],"u":1,"seq":1}}',
      );

      final result = await future;
      expect(result, isA<Success<OrderBook>>());
      result.when(
        success: (orderBook) {
          expect(orderBook.bids, hasLength(1));
          expect(orderBook.bids.first.price, 99.0);
          expect(orderBook.bids.first.amount, 1.0);
          expect(orderBook.asks, hasLength(1));
          expect(orderBook.asks.first.price, 101.0);
          expect(orderBook.asks.first.amount, 1.0);
        },
        failure: (_) => fail('expected success'),
      );
    });

    test('watchTrades sends subscribe and parses trade message', () async {
      late _FakeWebSocketChannel channel;
      final outgoing = <dynamic>[];
      final client = BybitWebSocketClient(
        channelFactory: (url) {
          channel = _FakeWebSocketChannel();
          channel.outgoingStream.listen(outgoing.add);
          return channel;
        },
      );

      final values = client.watchTrades(symbol);
      final future = values.first;
      await Future.delayed(Duration.zero);

      expect(outgoing.length, 1);
      expect(outgoing.first, contains('"channel":"publicTrade"'));

      channel.add(
        '{"topic":"publicTrade.BTCUSDT","ts":1718952000000,"data":[{"i":"1","T":1718952000000,"p":"100.0","v":"1.0","S":"Buy","s":"BTCUSDT"}]}',
      );

      final result = await future;
      expect(result, isA<Success<List<Trade>>>());
      result.when(
        success: (trades) {
          expect(trades, hasLength(1));
          expect(trades.first.price, 100.0);
          expect(trades.first.amount, 1.0);
          expect(trades.first.side, TradeSide.buy);
          expect(trades.first.tradeId, '1');
        },
        failure: (_) => fail('expected success'),
      );
    });

    test('watchTicker closes sink when subscription is cancelled', () async {
      late _FakeWebSocketChannel channel;
      final client = BybitWebSocketClient(
        channelFactory: (url) {
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
      final client = BybitWebSocketClient(
        channelFactory: (url) {
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
      final client = BybitWebSocketClient(
        channelFactory: (url) {
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
      final client = BybitWebSocketClient(
        channelFactory: (url) {
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
            startsWith('Bybit WS ticker parse failed: FormatException'),
          );
        },
      );
    });

    test('watchTicker emits ParseFailure on empty message', () async {
      late _FakeWebSocketChannel channel;
      final client = BybitWebSocketClient(
        channelFactory: (url) {
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
            startsWith('Bybit WS ticker parse failed: FormatException'),
          );
        },
      );
    });

    test('watchTicker emits ParseFailure on missing data key', () async {
      late _FakeWebSocketChannel channel;
      final client = BybitWebSocketClient(
        channelFactory: (url) {
          channel = _FakeWebSocketChannel();
          return channel;
        },
      );

      final future = client.watchTicker(symbol).first;
      await Future.delayed(Duration.zero);
      channel.add('{"topic":"tickers.BTCUSDT","ts":1718952000000}');

      final result = await future;
      expect(result, isA<Err<Ticker>>());
      result.when(
        success: (_) => fail('expected failure'),
        failure: (failure) {
          expect(failure, isA<ParseFailure>());
          expect(failure.message, startsWith('Bybit WS ticker parse failed:'));
          expect(failure.message, contains("type 'Null'"));
        },
      );
    });

    test('watchTicker emits UnknownFailure on stream error', () async {
      late _FakeWebSocketChannel channel;
      final client = BybitWebSocketClient(
        channelFactory: (url) {
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
          expect(failure.message, 'Bybit WS ticker error');
          expect((failure as UnknownFailure).error, error);
        },
      );
    });

    test('watchOrderBook parses delta message', () async {
      late _FakeWebSocketChannel channel;
      final client = BybitWebSocketClient(
        channelFactory: (url) {
          channel = _FakeWebSocketChannel();
          return channel;
        },
      );

      final future = client.watchOrderBook(symbol).first;
      await Future.delayed(Duration.zero);
      channel.add(
        '{"topic":"orderbook.1.BTCUSDT","ts":1718952000000,"type":"delta","data":{"s":"BTCUSDT","b":[["99.0","1.0"]],"a":[["101.0","1.0"]],"u":2,"seq":2}}',
      );

      final result = await future;
      expect(result, isA<Success<OrderBook>>());
      result.when(
        success: (orderBook) {
          expect(orderBook.bids.first.price, 99.0);
          expect(orderBook.asks.first.price, 101.0);
        },
        failure: (_) => fail('expected failure'),
      );
    });

    test('closeAll closes every active subscription sink', () async {
      final channels = <_FakeWebSocketChannel>[];
      final client = BybitWebSocketClient(
        channelFactory: (url) {
          final channel = _FakeWebSocketChannel();
          channels.add(channel);
          return channel;
        },
      );

      client.watchTicker(symbol).listen(null);
      client.watchOrderBook(symbol).listen(null);
      client.watchTrades(symbol).listen(null);
      await Future.delayed(Duration.zero);

      expect(channels.length, 3);
      for (final channel in channels) {
        expect(channel.sink.closed, isFalse);
      }

      client.closeAll();
      await pumpEventQueue();

      for (final channel in channels) {
        expect(channel.sink.closed, isTrue);
      }
    });

    test(
      'cancel subscription before ready completes closes sink cleanly',
      () async {
        final readyCompleter = Completer<void>();
        late _FakeWebSocketChannel channel;
        final client = BybitWebSocketClient(
          channelFactory: (url) {
            channel = _FakeWebSocketChannel(ready: readyCompleter.future);
            return channel;
          },
        );

        final subscription = client.watchTicker(symbol).listen(null);
        await Future.delayed(Duration.zero);

        expect(channel.sink.closed, isFalse);
        await subscription.cancel();
        expect(channel.sink.closed, isTrue);

        readyCompleter.complete();
        await pumpEventQueue();

        expect(channel.sink.closed, isTrue);
      },
    );

    test('sink.add throwing StateError after disposal is handled', () async {
      final client = BybitWebSocketClient(
        channelFactory: (url) => _StateErrorChannel(),
      );

      final future = client.watchTicker(symbol).first;
      await Future.delayed(Duration.zero);

      final result = await future;
      expect(result, isA<Err<Ticker>>());
      result.when(
        success: (_) => fail('expected failure'),
        failure: (failure) {
          expect(failure, isA<UnknownFailure>());
          expect(failure.message, 'Bybit WS ticker error');
        },
      );
    });
  });
}
