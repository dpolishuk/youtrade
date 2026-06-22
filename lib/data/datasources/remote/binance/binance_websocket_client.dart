import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../../core/failures.dart';
import '../../../../core/result.dart';
import '../../../../domain/entities/order_book.dart';
import '../../../../domain/entities/symbol.dart';
import '../../../../domain/entities/ticker.dart';
import '../../../../domain/entities/trade.dart';
import '../../../../domain/sources/market_stream_source.dart';

typedef WebSocketChannelFactory = WebSocketChannel Function(String streamName);

class BinanceWebSocketClient implements MarketStreamSource {
  BinanceWebSocketClient({
    WebSocketChannelFactory? channelFactory,
    String? baseUrl,
  }) : _channelFactory = channelFactory ?? _defaultFactory(baseUrl);

  final WebSocketChannelFactory _channelFactory;
  final List<Future<void> Function()> _sessions = [];

  static WebSocketChannelFactory _defaultFactory(String? baseUrl) {
    return (streamName) {
      final uri = Uri.parse(
        '${baseUrl ?? 'wss://stream.binance.com:9443/ws'}/$streamName',
      );
      return WebSocketChannel.connect(uri);
    };
  }

  String _streamName(TradingSymbol symbol, String suffix) =>
      '${symbol.rawSymbol.toLowerCase()}$suffix';

  @override
  Stream<Result<Ticker>> watchTicker(TradingSymbol symbol) {
    return _watch(
      _streamName(symbol, '@ticker'),
      (json) => Success(_parseTicker(symbol, json)),
      (e) => Err(ParseFailure('Binance WS ticker parse failed: $e')),
      (e) => Err(UnknownFailure('Binance WS ticker error', error: e)),
    );
  }

  @override
  Stream<Result<OrderBook>> watchOrderBook(TradingSymbol symbol) {
    return _watch(
      _streamName(symbol, '@depth'),
      (json) => Success(_parseOrderBook(json)),
      (e) => Err(ParseFailure('Binance WS order book parse failed: $e')),
      (e) => Err(UnknownFailure('Binance WS order book error', error: e)),
    );
  }

  @override
  Stream<Result<List<Trade>>> watchTrades(TradingSymbol symbol) {
    return _watch(
      _streamName(symbol, '@trade'),
      (json) => Success([_parseTrade(json)]),
      (e) => Err(ParseFailure('Binance WS trade parse failed: $e')),
      (e) => Err(UnknownFailure('Binance WS trade error', error: e)),
    );
  }

  Stream<T> _watch<T>(
    String streamName,
    T Function(Map<String, dynamic> json) parse,
    T Function(Object) onParseError,
    T Function(Object) onError,
  ) {
    final channel = _channelFactory(streamName);
    StreamSubscription<dynamic>? subscription;
    var disposed = false;

    Future<void> disposeSession() async {
      if (disposed) return;
      disposed = true;
      await subscription?.cancel();
      await channel.sink.close();
    }

    _sessions.add(disposeSession);

    final controller = StreamController<T>();
    controller.onCancel = () async {
      await disposeSession();
      _sessions.remove(disposeSession);
      if (!controller.isClosed) controller.close();
    };

    subscription = channel.stream.listen(
      (message) {
        try {
          final json = jsonDecode(message as String) as Map<String, dynamic>;
          controller.add(parse(json));
        } on FormatException catch (e) {
          controller.add(onParseError(e));
        } on TypeError catch (e) {
          controller.add(onParseError(e));
        } on StateError catch (e) {
          controller.add(onParseError(e));
        } on RangeError catch (e) {
          controller.add(onParseError(e));
        } on ArgumentError catch (e) {
          controller.add(onParseError(e));
        }
      },
      onError: (Object error) => controller.add(onError(error)),
      onDone: controller.close,
    );

    return controller.stream;
  }

  void closeAll() {
    for (final dispose in _sessions.toList()) {
      unawaited(dispose());
    }
    _sessions.clear();
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
