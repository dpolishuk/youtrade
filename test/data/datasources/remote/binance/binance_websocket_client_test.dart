import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:youtrade/core/result.dart';
import 'package:youtrade/data/datasources/remote/binance/binance_websocket_client.dart';
import 'package:youtrade/domain/entities/symbol.dart';
import 'package:youtrade/domain/entities/venue.dart';

void main() {
  group('BinanceWebSocketClient', () {
    final symbol = TradingSymbol(
      base: 'BTC',
      quote: 'USDT',
      venue: Venue.binance,
      rawSymbol: 'BTCUSDT',
    );
    late StreamController<dynamic> controller;
    late BinanceWebSocketClient client;

    setUp(() {
      controller = StreamController<dynamic>();
      client = BinanceWebSocketClient(streamFactory: (_) => controller.stream);
    });

    tearDown(() {
      controller.close();
    });

    test('watchTicker parses mini ticker message', () async {
      final values = client.watchTicker(symbol);
      controller.add(
        '{"e":"24hrTicker","E":1718952000000,"s":"BTCUSDT","c":"100.0","b":"99.5","a":"100.5","p":"1.0","P":"1.0","v":"1000.0"}',
      );
      final result = await values.first;
      expect(result, isA<Success>());
      result.when(
        success: (ticker) => expect(ticker.lastPrice, 100.0),
        failure: (_) => fail('expected success'),
      );
    });

    test('watchOrderBook parses depth message', () async {
      final values = client.watchOrderBook(symbol);
      controller.add('{"b":[["99.0","1.0"]],"a":[["101.0","1.0"]]}');
      final result = await values.first;
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
      final values = client.watchTrades(symbol);
      controller.add(
        '{"e":"trade","E":1718952000000,"s":"BTCUSDT","t":1,"p":"100.0","q":"1.0","m":false,"T":1718952000000}',
      );
      final result = await values.first;
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
