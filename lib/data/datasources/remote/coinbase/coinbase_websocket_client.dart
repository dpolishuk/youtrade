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

class CoinbaseWebSocketClient implements MarketStreamSource {
  CoinbaseWebSocketClient({
    WebSocketChannelFactory? channelFactory,
    String? baseUrl,
  }) : _channelFactory = channelFactory ?? _defaultFactory(baseUrl);

  final WebSocketChannelFactory _channelFactory;
  final List<Future<void> Function()> _sessions = [];

  static WebSocketChannelFactory _defaultFactory(String? baseUrl) {
    final url = baseUrl ?? 'wss://ws-feed.exchange.coinbase.com';
    return (_) => WebSocketChannel.connect(Uri.parse(url));
  }

  String _productId(TradingSymbol symbol) => '${symbol.base}-${symbol.quote}';

  String _subscribeMessage(String channel, TradingSymbol symbol) {
    return jsonEncode({
      'type': 'subscribe',
      'product_ids': [_productId(symbol)],
      'channels': [channel],
    });
  }

  @override
  Stream<Result<Ticker>> watchTicker(TradingSymbol symbol) {
    final productId = _productId(symbol);
    return _watch(
      _subscribeMessage('ticker', symbol),
      (json) => json['type'] == 'ticker' && json['product_id'] == productId,
      (json) => Success(_parseTicker(symbol, json)),
      (e) => Err(ParseFailure('Coinbase WS ticker parse failed: $e')),
      (e) => Err(UnknownFailure('Coinbase WS ticker error', error: e)),
    );
  }

  @override
  Stream<Result<OrderBook>> watchOrderBook(TradingSymbol symbol) {
    return _watch(
      _subscribeMessage('level2', symbol),
      (json) => json['type'] == 'snapshot',
      (json) => Success(_parseOrderBook(json)),
      (e) => Err(ParseFailure('Coinbase WS order book parse failed: $e')),
      (e) => Err(UnknownFailure('Coinbase WS order book error', error: e)),
    );
  }

  @override
  Stream<Result<List<Trade>>> watchTrades(TradingSymbol symbol) {
    return _watch(
      _subscribeMessage('matches', symbol),
      (json) => json['type'] == 'match',
      (json) => Success([_parseTrade(json)]),
      (e) => Err(ParseFailure('Coinbase WS trade parse failed: $e')),
      (e) => Err(UnknownFailure('Coinbase WS trade error', error: e)),
    );
  }

  Stream<T> _watch<T>(
    String subscribeMessage,
    bool Function(Map<String, dynamic> json) isRelevant,
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

    final controller = StreamController<T>(
      onCancel: () async {
        await disposeSession();
        _sessions.remove(disposeSession);
      },
    );

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
                if (!isRelevant(json)) return;
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
    final lastPrice = double.parse(json['price'] as String);
    final open24h = double.parse(json['open_24h'] as String);
    final change24h = lastPrice - open24h;
    final change24hPercent = open24h == 0.0 ? 0.0 : change24h / open24h;

    return Ticker(
      symbol: symbol,
      lastPrice: lastPrice,
      bid: double.parse(json['best_bid'] as String),
      ask: double.parse(json['best_ask'] as String),
      change24h: change24h,
      change24hPercent: change24hPercent,
      volume: double.parse(json['volume_24h'] as String),
      timestamp: DateTime.parse(json['time'] as String).toUtc(),
    );
  }

  OrderBook _parseOrderBook(Map<String, dynamic> json) {
    final bids = (json['bids'] as List<dynamic>? ?? [])
        .map((e) => _parseLevel(e as List<dynamic>))
        .toList();
    final asks = (json['asks'] as List<dynamic>? ?? [])
        .map((e) => _parseLevel(e as List<dynamic>))
        .toList();
    return OrderBook(bids: bids, asks: asks, timestamp: DateTime.now().toUtc());
  }

  OrderBookLevel _parseLevel(List<dynamic> data) {
    // Accept both [price, size] and [side, price, size]
    final offset = data.length >= 3 ? 1 : 0;
    return OrderBookLevel(
      price: double.parse(data[offset] as String),
      amount: double.parse(data[offset + 1] as String),
    );
  }

  Trade _parseTrade(Map<String, dynamic> json) {
    final sideString = (json['side'] as String).toLowerCase();
    final side = switch (sideString) {
      'buy' => TradeSide.buy,
      'sell' => TradeSide.sell,
      _ => throw FormatException('Unknown trade side: $sideString'),
    };
    return Trade(
      price: double.parse(json['price'] as String),
      amount: double.parse(json['size'] as String),
      side: side,
      timestamp: DateTime.parse(json['time'] as String).toUtc(),
      tradeId: json['trade_id']?.toString(),
    );
  }
}
