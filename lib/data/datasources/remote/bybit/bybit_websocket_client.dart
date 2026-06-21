import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../../core/failures.dart';
import '../../../../core/result.dart';
import '../../../../domain/entities/order_book.dart';
import '../../../../domain/entities/symbol.dart';
import '../../../../domain/entities/ticker.dart';
import '../../../../domain/entities/trade.dart';
import '../../../../domain/sources/market_stream_source.dart';

typedef WebSocketChannelFactory = WebSocketChannel Function(String url);

final class BybitWebSocketClient implements MarketStreamSource {
  BybitWebSocketClient({
    WebSocketChannelFactory? channelFactory,
    String? baseUrl,
  }) : _channelFactory = channelFactory ?? _defaultFactory(baseUrl);

  final WebSocketChannelFactory _channelFactory;

  static WebSocketChannelFactory _defaultFactory(String? baseUrl) {
    final url = baseUrl ?? 'wss://stream.bybit.com/v5/public/spot';
    return (_) => WebSocketChannel.connect(Uri.parse(url));
  }

  String _subscribeMessage(String channel, TradingSymbol symbol) {
    return jsonEncode({
      'op': 'subscribe',
      'args': [
        {'channel': channel, 'symbol': symbol.rawSymbol},
      ],
    });
  }

  @override
  Stream<Result<Ticker>> watchTicker(TradingSymbol symbol) async* {
    final channel = _channelFactory('');
    await channel.ready;
    channel.sink.add(_subscribeMessage('tickers', symbol));
    await for (final message in channel.stream) {
      try {
        final json = jsonDecode(message as String) as Map<String, dynamic>;
        final data = json['data'] as Map<String, dynamic>;
        yield Success(_parseTicker(symbol, data));
      } on FormatException catch (e) {
        yield Err(ParseFailure('Bybit WS ticker parse failed: $e'));
      } on Exception catch (e) {
        yield Err(UnknownFailure('Bybit WS ticker error', error: e));
      }
    }
  }

  @override
  Stream<Result<OrderBook>> watchOrderBook(TradingSymbol symbol) async* {
    final channel = _channelFactory('');
    await channel.ready;
    channel.sink.add(_subscribeMessage('orderbook', symbol));
    await for (final message in channel.stream) {
      try {
        final json = jsonDecode(message as String) as Map<String, dynamic>;
        final data = json['data'] as Map<String, dynamic>;
        yield Success(_parseOrderBook(data));
      } on FormatException catch (e) {
        yield Err(ParseFailure('Bybit WS order book parse failed: $e'));
      } on Exception catch (e) {
        yield Err(UnknownFailure('Bybit WS order book error', error: e));
      }
    }
  }

  @override
  Stream<Result<List<Trade>>> watchTrades(TradingSymbol symbol) async* {
    final channel = _channelFactory('');
    await channel.ready;
    channel.sink.add(_subscribeMessage('publicTrade', symbol));
    await for (final message in channel.stream) {
      try {
        final json = jsonDecode(message as String) as Map<String, dynamic>;
        final data = json['data'] as List<dynamic>;
        yield Success(
          data.map((e) => _parseTrade(e as Map<String, dynamic>)).toList(),
        );
      } on FormatException catch (e) {
        yield Err(ParseFailure('Bybit WS trade parse failed: $e'));
      } on Exception catch (e) {
        yield Err(UnknownFailure('Bybit WS trade error', error: e));
      }
    }
  }

  Ticker _parseTicker(TradingSymbol symbol, Map<String, dynamic> json) {
    return Ticker(
      symbol: symbol,
      lastPrice: double.parse(json['lastPrice'] as String),
      bid: double.parse(json['bid1Price'] as String),
      ask: double.parse(json['ask1Price'] as String),
      change24h: json['price24h'] == null
          ? 0.0
          : double.parse(json['price24h'] as String),
      change24hPercent: double.parse(json['price24hPcnt'] as String),
      volume: double.parse(json['volume24h'] as String),
      timestamp: DateTime.now().toUtc(),
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
    final sideString = json['S'] as String;
    return Trade(
      price: double.parse(json['p'] as String),
      amount: double.parse(json['v'] as String),
      side: sideString.toLowerCase() == 'buy' ? TradeSide.buy : TradeSide.sell,
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        json['T'] as int,
        isUtc: true,
      ),
      tradeId: json['i']?.toString(),
    );
  }
}
