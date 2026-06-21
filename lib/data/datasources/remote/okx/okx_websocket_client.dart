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

final class OKXWebSocketClient implements MarketStreamSource {
  OKXWebSocketClient({WebSocketChannelFactory? channelFactory, String? baseUrl})
    : _channelFactory = channelFactory ?? _defaultFactory(baseUrl);

  final WebSocketChannelFactory _channelFactory;

  static WebSocketChannelFactory _defaultFactory(String? baseUrl) {
    final url = baseUrl ?? 'wss://ws.okx.com:8443/ws/v5/public';
    return (_) => WebSocketChannel.connect(Uri.parse(url));
  }

  String _instId(TradingSymbol symbol) => '${symbol.base}-${symbol.quote}';

  String _subscribeMessage(String channel, TradingSymbol symbol) {
    return jsonEncode({
      'op': 'subscribe',
      'args': [
        {'channel': channel, 'instId': _instId(symbol)},
      ],
    });
  }

  @override
  Stream<Result<Ticker>> watchTicker(TradingSymbol symbol) {
    return _watch(
      _subscribeMessage('tickers', symbol),
      _instId(symbol),
      _hasDataList,
      (json) {
        final data =
            (json['data'] as List<dynamic>).first as Map<String, dynamic>;
        return Success(_parseTicker(symbol, data));
      },
      (e) => Err(ParseFailure('OKX WS ticker parse failed: $e')),
      (e) => Err(UnknownFailure('OKX WS ticker error', error: e)),
    );
  }

  @override
  Stream<Result<OrderBook>> watchOrderBook(TradingSymbol symbol) {
    return _watch(
      _subscribeMessage('books', symbol),
      _instId(symbol),
      _hasDataList,
      (json) {
        final data =
            (json['data'] as List<dynamic>).first as Map<String, dynamic>;
        return Success(_parseOrderBook(data));
      },
      (e) => Err(ParseFailure('OKX WS order book parse failed: $e')),
      (e) => Err(UnknownFailure('OKX WS order book error', error: e)),
    );
  }

  @override
  Stream<Result<List<Trade>>> watchTrades(TradingSymbol symbol) {
    return _watch(
      _subscribeMessage('trades', symbol),
      _instId(symbol),
      _hasDataList,
      (json) => Success(
        (json['data'] as List<dynamic>)
            .map((e) => _parseTrade(e as Map<String, dynamic>))
            .toList(),
      ),
      (e) => Err(ParseFailure('OKX WS trades parse failed: $e')),
      (e) => Err(UnknownFailure('OKX WS trades error', error: e)),
    );
  }

  bool _hasDataList(Map<String, dynamic> json) => json['data'] is List<dynamic>;

  Stream<T> _watch<T>(
    String subscribeMessage,
    String expectedInstId,
    bool Function(Map<String, dynamic> json) isRelevant,
    T Function(Map<String, dynamic> json) parse,
    T Function(Object) onParseError,
    T Function(Object) onError,
  ) {
    final channel = _channelFactory('');
    StreamSubscription<dynamic>? subscription;

    final controller = StreamController<T>(
      onCancel: () async {
        await subscription?.cancel();
        await channel.sink.close();
      },
    );

    channel.ready
        .then((_) {
          if (controller.isClosed) return;
          channel.sink.add(subscribeMessage);
          subscription = channel.stream.listen(
            (message) {
              try {
                final json =
                    jsonDecode(message as String) as Map<String, dynamic>;
                final arg = json['arg'];
                if (arg is Map<String, dynamic>) {
                  final instId = arg['instId'];
                  if (instId is String && instId != expectedInstId) return;
                }
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
          if (!controller.isClosed) {
            controller.add(onError(error));
            controller.close();
          }
        });

    return controller.stream;
  }

  Ticker _parseTicker(TradingSymbol symbol, Map<String, dynamic> json) {
    final lastPrice = double.parse(json['last'] as String);
    final open24h = double.parse(json['open24h'] as String);
    final change24h = lastPrice - open24h;
    final change24hPercent = open24h == 0.0 ? 0.0 : change24h / open24h;

    return Ticker(
      symbol: symbol,
      lastPrice: lastPrice,
      bid: double.parse(json['bidPx'] as String),
      ask: double.parse(json['askPx'] as String),
      change24h: change24h,
      change24hPercent: change24hPercent,
      volume: double.parse(json['vol24h'] as String),
      timestamp: _parseTimestamp(json['ts'] as String?),
    );
  }

  DateTime _parseTimestamp(String? ts) {
    if (ts == null || ts.isEmpty) return DateTime.now().toUtc();
    return DateTime.fromMillisecondsSinceEpoch(int.parse(ts), isUtc: true);
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
    return OrderBookLevel(
      price: double.parse(data[0] as String),
      amount: double.parse(data[1] as String),
    );
  }

  Trade _parseTrade(Map<String, dynamic> json) {
    final sideString = json['side'] as String;
    return Trade(
      price: double.parse(json['px'] as String),
      amount: double.parse(json['sz'] as String),
      side: sideString.toLowerCase() == 'buy' ? TradeSide.buy : TradeSide.sell,
      timestamp: _parseTimestamp(json['ts'] as String?),
      tradeId: json['tradeId']?.toString(),
    );
  }
}
