import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/failures.dart';
import '../../../../core/result.dart';
import '../../../../domain/entities/candle.dart';
import '../../../../domain/entities/order_book.dart';
import '../../../../domain/entities/symbol.dart';
import '../../../../domain/entities/ticker.dart';
import '../../../../domain/entities/timeframe.dart';
import '../../../../domain/entities/trade.dart';
import '../../../../domain/sources/candle_source.dart';
import '../../../../domain/sources/order_book_source.dart';
import '../../../../domain/sources/ticker_source.dart';
import '../../../../domain/sources/trade_source.dart';

final class BybitRestClient
    implements TickerSource, CandleSource, OrderBookSource, TradeSource {
  BybitRestClient({http.Client? httpClient, String? baseUrl})
    : _httpClient = httpClient ?? http.Client(),
      _baseUrl = baseUrl ?? 'https://api.bybit.com';

  final http.Client _httpClient;
  final String _baseUrl;

  void close() => _httpClient.close();

  Uri _uri(String path, Map<String, String> query) =>
      Uri.parse('$_baseUrl$path').replace(queryParameters: query);

  String _apiErrorMessage(Map<String, dynamic> json, String context) {
    final retCode = json['retCode'] as int?;
    if (retCode == null || retCode == 0) return '';
    final retMsg = json['retMsg'] as String? ?? '';
    return 'Bybit $context API error: $retCode $retMsg';
  }

  @override
  Future<Result<Ticker>> fetchTicker(TradingSymbol symbol) async {
    try {
      final response = await _httpClient
          .get(
            _uri('/v5/market/tickers', {
              'category': 'spot',
              'symbol': symbol.rawSymbol,
            }),
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        return Err(NetworkFailure('Bybit ticker ${response.statusCode}'));
      }
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final apiError = _apiErrorMessage(json, 'ticker');
      if (apiError.isNotEmpty) {
        return Err(NetworkFailure(apiError));
      }
      final result = json['result'] as Map<String, dynamic>;
      final list = result['list'] as List<dynamic>;
      final tickerJson = list.first as Map<String, dynamic>;
      return Success(_parseTicker(symbol, tickerJson));
    } on TimeoutException {
      return const Err(NetworkFailure('Bybit ticker request timed out'));
    } on FormatException catch (e) {
      return Err(ParseFailure('Bybit ticker parse failed: $e'));
    } on TypeError catch (e) {
      return Err(ParseFailure('Bybit ticker parse failed: $e'));
    } on StateError catch (e) {
      return Err(ParseFailure('Bybit ticker parse failed: $e'));
    } on RangeError catch (e) {
      return Err(ParseFailure('Bybit ticker parse failed: $e'));
    } on Exception catch (e) {
      return Err(NetworkFailure('Bybit ticker request failed: $e'));
    }
  }

  @override
  Future<Result<List<Candle>>> fetchCandles(
    TradingSymbol symbol,
    Timeframe timeframe, {
    int? limit,
  }) async {
    try {
      final response = await _httpClient
          .get(
            _uri('/v5/market/kline', {
              'category': 'spot',
              'symbol': symbol.rawSymbol,
              'interval': _timeframeCode(timeframe),
              if (limit != null) 'limit': limit.toString(),
            }),
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        return Err(NetworkFailure('Bybit candles ${response.statusCode}'));
      }
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final apiError = _apiErrorMessage(json, 'candles');
      if (apiError.isNotEmpty) {
        return Err(NetworkFailure(apiError));
      }
      final result = json['result'] as Map<String, dynamic>;
      final list = result['list'] as List<dynamic>;
      return Success(
        list.map((e) => _parseCandle(e as List<dynamic>)).toList(),
      );
    } on TimeoutException {
      return const Err(NetworkFailure('Bybit candles request timed out'));
    } on FormatException catch (e) {
      return Err(ParseFailure('Bybit candles parse failed: $e'));
    } on TypeError catch (e) {
      return Err(ParseFailure('Bybit candles parse failed: $e'));
    } on StateError catch (e) {
      return Err(ParseFailure('Bybit candles parse failed: $e'));
    } on RangeError catch (e) {
      return Err(ParseFailure('Bybit candles parse failed: $e'));
    } on Exception catch (e) {
      return Err(NetworkFailure('Bybit candles request failed: $e'));
    }
  }

  @override
  Future<Result<OrderBook>> fetchOrderBook(
    TradingSymbol symbol, {
    int? depth,
  }) async {
    try {
      final response = await _httpClient
          .get(
            _uri('/v5/market/orderbook', {
              'category': 'spot',
              'symbol': symbol.rawSymbol,
              if (depth != null) 'limit': depth.toString(),
            }),
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        return Err(NetworkFailure('Bybit order book ${response.statusCode}'));
      }
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final apiError = _apiErrorMessage(json, 'order book');
      if (apiError.isNotEmpty) {
        return Err(NetworkFailure(apiError));
      }
      final result = json['result'] as Map<String, dynamic>;
      return Success(_parseOrderBook(result));
    } on TimeoutException {
      return const Err(NetworkFailure('Bybit order book request timed out'));
    } on FormatException catch (e) {
      return Err(ParseFailure('Bybit order book parse failed: $e'));
    } on TypeError catch (e) {
      return Err(ParseFailure('Bybit order book parse failed: $e'));
    } on StateError catch (e) {
      return Err(ParseFailure('Bybit order book parse failed: $e'));
    } on RangeError catch (e) {
      return Err(ParseFailure('Bybit order book parse failed: $e'));
    } on Exception catch (e) {
      return Err(NetworkFailure('Bybit order book request failed: $e'));
    }
  }

  @override
  Future<Result<List<Trade>>> fetchTrades(
    TradingSymbol symbol, {
    int? limit,
  }) async {
    try {
      final response = await _httpClient
          .get(
            _uri('/v5/market/recent-trade', {
              'category': 'spot',
              'symbol': symbol.rawSymbol,
              if (limit != null) 'limit': limit.toString(),
            }),
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        return Err(NetworkFailure('Bybit trades ${response.statusCode}'));
      }
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final apiError = _apiErrorMessage(json, 'trades');
      if (apiError.isNotEmpty) {
        return Err(NetworkFailure(apiError));
      }
      final result = json['result'] as Map<String, dynamic>;
      final list = result['list'] as List<dynamic>;
      return Success(
        list.map((e) => _parseTrade(e as Map<String, dynamic>)).toList(),
      );
    } on TimeoutException {
      return const Err(NetworkFailure('Bybit trades request timed out'));
    } on FormatException catch (e) {
      return Err(ParseFailure('Bybit trades parse failed: $e'));
    } on TypeError catch (e) {
      return Err(ParseFailure('Bybit trades parse failed: $e'));
    } on StateError catch (e) {
      return Err(ParseFailure('Bybit trades parse failed: $e'));
    } on RangeError catch (e) {
      return Err(ParseFailure('Bybit trades parse failed: $e'));
    } on Exception catch (e) {
      return Err(NetworkFailure('Bybit trades request failed: $e'));
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

  Candle _parseCandle(List<dynamic> data) {
    return Candle(
      open: double.parse(data[1] as String),
      high: double.parse(data[2] as String),
      low: double.parse(data[3] as String),
      close: double.parse(data[4] as String),
      volume: double.parse(data[5] as String),
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        int.parse(data[0] as String),
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
    final sideString = json['side'] as String;
    final side = switch (sideString.toLowerCase()) {
      'buy' => TradeSide.buy,
      'sell' => TradeSide.sell,
      _ => throw FormatException('Unknown trade side: $sideString'),
    };
    return Trade(
      price: double.parse(json['price'] as String),
      amount: double.parse(json['size'] as String),
      side: side,
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        int.parse(json['time'] as String),
        isUtc: true,
      ),
      tradeId: json['execId']?.toString(),
    );
  }

  String _timeframeCode(Timeframe timeframe) {
    return switch (timeframe) {
      Timeframe.m1 => '1',
      Timeframe.m5 => '5',
      Timeframe.m15 => '15',
      Timeframe.m30 => '30',
      Timeframe.h1 => '60',
      Timeframe.h4 => '240',
      Timeframe.d1 => 'D',
    };
  }
}
