import 'dart:async';

import 'package:async/async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:youtrade/core/result.dart';
import 'package:youtrade/data/datasources/remote/bybit/bybit_websocket_client.dart';
import 'package:youtrade/domain/entities/symbol.dart';
import 'package:youtrade/domain/entities/venue.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class _FakeWebSocketChannel extends StreamChannelMixin<dynamic>
    implements WebSocketChannel {
  _FakeWebSocketChannel() : _outgoing = StreamController<dynamic>.broadcast();

  final StreamController<dynamic> _incoming = StreamController<dynamic>();
  final StreamController<dynamic> _outgoing;

  void add(dynamic value) => _incoming.add(value);

  Stream<dynamic> get outgoingStream => _outgoing.stream;

  @override
  Stream<dynamic> get stream => _incoming.stream;

  @override
  WebSocketSink get sink => _FakeWebSocketSink(_outgoing.sink);

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

  @override
  Future close([int? closeCode, String? closeReason]) => super.close();
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
      expect(result, isA<Success>());
      result.when(
        success: (ticker) => expect(ticker.lastPrice, 100.0),
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
      expect(result, isA<Success>());
      result.when(
        success: (orderBook) {
          expect(orderBook.bids.first.price, 99.0);
          expect(orderBook.asks.first.price, 101.0);
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
      expect(result, isA<Success>());
      result.when(
        success: (trades) {
          expect(trades.length, 1);
          expect(trades.first.price, 100.0);
        },
        failure: (_) => fail('expected success'),
      );
    });
  });
}
