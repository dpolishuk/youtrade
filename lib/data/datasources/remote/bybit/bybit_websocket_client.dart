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

typedef WebSocketChannelFactory = WebSocketChannel Function(String url);

class BybitWebSocketClient implements MarketStreamSource {
  BybitWebSocketClient({
    WebSocketChannelFactory? channelFactory,
    String? baseUrl,
  }) : _channelFactory = channelFactory ?? _defaultFactory(baseUrl);

  final WebSocketChannelFactory _channelFactory;
  final List<Future<void> Function()> _sessions = [];

  static WebSocketChannelFactory _defaultFactory(String? baseUrl) {
    final url = baseUrl ?? 'wss://stream-demo.bybit.com/v5/public/linear';
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
  Stream<Result<Ticker>> watchTicker(TradingSymbol symbol) {
    return _watch(
      _subscribeMessage('tickers', symbol),
      (json) =>
          Success(_parseTicker(symbol, json['data'] as Map<String, dynamic>)),
      (e) => Err(ParseFailure('Bybit WS ticker parse failed: $e')),
      (e) => Err(UnknownFailure('Bybit WS ticker error', error: e)),
    );
  }

  @override
  Stream<Result<OrderBook>> watchOrderBook(TradingSymbol symbol) {
    return _watch(
      _subscribeMessage('orderbook', symbol),
      (json) => Success(_parseOrderBook(json['data'] as Map<String, dynamic>)),
      (e) => Err(ParseFailure('Bybit WS order book parse failed: $e')),
      (e) => Err(UnknownFailure('Bybit WS order book error', error: e)),
    );
  }

  @override
  Stream<Result<List<Trade>>> watchTrades(TradingSymbol symbol) {
    return _watch(
      _subscribeMessage('publicTrade', symbol),
      (json) => Success(
        (json['data'] as List<dynamic>)
            .map((e) => _parseTrade(e as Map<String, dynamic>))
            .toList(),
      ),
      (e) => Err(ParseFailure('Bybit WS trade parse failed: $e')),
      (e) => Err(UnknownFailure('Bybit WS trade error', error: e)),
    );
  }

  Stream<T> _watch<T>(
    String subscribeMessage,
    T Function(Map<String, dynamic> json) parse,
    T Function(Object) onParseError,
    T Function(Object) onError,
  ) {
    final channel = _channelFactory('');
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

    channel.ready
        .then((_) {
          if (disposed || controller.isClosed) return;
          try {
            channel.sink.add(subscribeMessage);
          } on StateError {
            if (disposed) return;
            rethrow;
          }
          subscription = channel.stream.listen(
            (message) {
              try {
                final json =
                    jsonDecode(message as String) as Map<String, dynamic>;
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
              } on Exception catch (e) {
                controller.add(onError(e));
              } on Error catch (e) {
                controller.add(onError(e));
              }
            },
            onError: (Object error) => controller.add(onError(error)),
            onDone: controller.close,
          );
        })
        .catchError((Object error, StackTrace stackTrace) {
          if (disposed || controller.isClosed) return;
          if (!controller.isClosed) {
            controller.add(onError(error));
            controller.close();
          }
        });

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
      lastPrice: double.parse(json['lastPrice'] as String),
      bid: double.parse(json['bid1Price'] as String),
      ask: double.parse(json['ask1Price'] as String),
      change24h: json['price24h'] == null
          ? 0.0
          : double.parse(json['price24h'] as String),
      change24hPercent: double.parse(json['price24hPcnt'] as String) * 100,
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
