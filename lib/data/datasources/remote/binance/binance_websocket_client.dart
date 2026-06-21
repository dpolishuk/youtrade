import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../../core/failures.dart';
import '../../../../core/result.dart';
import '../../../../domain/entities/order_book.dart';
import '../../../../domain/entities/symbol.dart';
import '../../../../domain/entities/ticker.dart';
import '../../../../domain/entities/trade.dart';
import '../../../../domain/sources/market_stream_source.dart';

typedef StreamFactory = Stream<dynamic> Function(String streamName);

final class BinanceWebSocketClient implements MarketStreamSource {
  BinanceWebSocketClient({StreamFactory? streamFactory, String? baseUrl})
    : _streamFactory = streamFactory ?? _defaultFactory(baseUrl);

  final StreamFactory _streamFactory;

  static StreamFactory _defaultFactory(String? baseUrl) {
    return (streamName) {
      final uri = Uri.parse(
        '${baseUrl ?? 'wss://stream.binance.com:9443/ws'}/$streamName',
      );
      return WebSocketChannel.connect(uri).stream;
    };
  }

  String _streamName(TradingSymbol symbol, String suffix) =>
      '${symbol.rawSymbol.toLowerCase()}$suffix';

  @override
  Stream<Result<Ticker>> watchTicker(TradingSymbol symbol) async* {
    await for (final message in _streamFactory(
      _streamName(symbol, '@ticker'),
    )) {
      try {
        final json = jsonDecode(message as String) as Map<String, dynamic>;
        yield Success(_parseTicker(symbol, json));
      } on FormatException catch (e) {
        yield Err(ParseFailure('Binance WS ticker parse failed: $e'));
      } on Exception catch (e) {
        yield Err(UnknownFailure('Binance WS ticker error', error: e));
      }
    }
  }

  @override
  Stream<Result<OrderBook>> watchOrderBook(TradingSymbol symbol) async* {
    await for (final message in _streamFactory(_streamName(symbol, '@depth'))) {
      try {
        final json = jsonDecode(message as String) as Map<String, dynamic>;
        yield Success(_parseOrderBook(json));
      } on FormatException catch (e) {
        yield Err(ParseFailure('Binance WS order book parse failed: $e'));
      } on Exception catch (e) {
        yield Err(UnknownFailure('Binance WS order book error', error: e));
      }
    }
  }

  @override
  Stream<Result<List<Trade>>> watchTrades(TradingSymbol symbol) async* {
    await for (final message in _streamFactory(_streamName(symbol, '@trade'))) {
      try {
        final json = jsonDecode(message as String) as Map<String, dynamic>;
        yield Success([_parseTrade(json)]);
      } on FormatException catch (e) {
        yield Err(ParseFailure('Binance WS trade parse failed: $e'));
      } on Exception catch (e) {
        yield Err(UnknownFailure('Binance WS trade error', error: e));
      }
    }
  }

  Ticker _parseTicker(TradingSymbol symbol, Map<String, dynamic> json) {
    return Ticker(
      symbol: symbol,
      lastPrice: double.parse(json['c'] as String),
      bid: double.parse(json['b'] as String),
      ask: double.parse(json['a'] as String),
      change24h: double.parse(json['p'] as String),
      change24hPercent: double.parse(json['P'] as String) / 100,
      volume: double.parse(json['v'] as String),
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        json['E'] as int,
        isUtc: true,
      ),
    );
  }

  OrderBook _parseOrderBook(Map<String, dynamic> json) {
    final bids = (json['b'] as List<dynamic>? ?? [])
        .map((e) => _parseLevel(e as List<dynamic>))
        .toList();
    final asks = (json['a'] as List<dynamic>? ?? [])
        .map((e) => _parseLevel(e as List<dynamic>))
        .toList();
    return OrderBook(bids: bids, asks: asks, timestamp: DateTime.now().toUtc());
  }

  OrderBookLevel _parseLevel(List<dynamic> data) {
    return OrderBookLevel(
      price: double.parse(data[0] as String),
      amount: double.parse(data[1] as String),
    );
  }

  Trade _parseTrade(Map<String, dynamic> json) {
    return Trade(
      price: double.parse(json['p'] as String),
      amount: double.parse(json['q'] as String),
      side: (json['m'] as bool) ? TradeSide.sell : TradeSide.buy,
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        json['T'] as int,
        isUtc: true,
      ),
      tradeId: json['t']?.toString(),
    );
  }
}
