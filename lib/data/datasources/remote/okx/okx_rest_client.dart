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

final class OKXRestClient
    implements TickerSource, CandleSource, OrderBookSource, TradeSource {
  OKXRestClient({http.Client? httpClient, String? baseUrl})
    : _httpClient = httpClient ?? http.Client(),
      _baseUrl = baseUrl ?? 'https://www.okx.com';

  final http.Client _httpClient;
  final String _baseUrl;

  Uri _uri(String path, Map<String, String> query) =>
      Uri.parse('$_baseUrl$path').replace(queryParameters: query);

  String _instId(TradingSymbol symbol) => '${symbol.base}-${symbol.quote}';

  String _apiErrorMessage(Map<String, dynamic> json, String context) {
    final code = json['code'] as String?;
    if (code == null || code == '0') return '';
    final msg = json['msg'] as String? ?? '';
    return 'OKX $context API error: $code $msg';
  }

  Map<String, dynamic> _firstDataItem(Map<String, dynamic> json) {
    final data = json['data'] as List<dynamic>;
    return data.first as Map<String, dynamic>;
  }

  @override
  Future<Result<Ticker>> fetchTicker(TradingSymbol symbol) async {
    try {
      final response = await _httpClient.get(
        _uri('/api/v5/market/ticker', {'instId': _instId(symbol)}),
      );
      if (response.statusCode != 200) {
        return Err(NetworkFailure('OKX ticker ${response.statusCode}'));
      }
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final apiError = _apiErrorMessage(json, 'ticker');
      if (apiError.isNotEmpty) {
        return Err(NetworkFailure(apiError));
      }
      return Success(_parseTicker(symbol, _firstDataItem(json)));
    } on FormatException catch (e) {
      return Err(ParseFailure('OKX ticker parse failed: $e'));
    } on TypeError catch (e) {
      return Err(ParseFailure('OKX ticker parse failed: $e'));
    } on StateError catch (e) {
      return Err(ParseFailure('OKX ticker parse failed: $e'));
    } on RangeError catch (e) {
      return Err(ParseFailure('OKX ticker parse failed: $e'));
    } on Exception catch (e) {
      return Err(NetworkFailure('OKX ticker request failed: $e'));
    }
  }

  @override
  Future<Result<List<Candle>>> fetchCandles(
    TradingSymbol symbol,
    Timeframe timeframe, {
    int? limit,
  }) async {
    try {
      final response = await _httpClient.get(
        _uri('/api/v5/market/history-candles', {
          'instId': _instId(symbol),
          'bar': _timeframeCode(timeframe),
          if (limit != null) 'limit': limit.toString(),
        }),
      );
      if (response.statusCode != 200) {
        return Err(NetworkFailure('OKX candles ${response.statusCode}'));
      }
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final apiError = _apiErrorMessage(json, 'candles');
      if (apiError.isNotEmpty) {
        return Err(NetworkFailure(apiError));
      }
      final data = json['data'] as List<dynamic>;
      return Success(
        data.map((e) => _parseCandle(e as List<dynamic>)).toList(),
      );
    } on FormatException catch (e) {
      return Err(ParseFailure('OKX candles parse failed: $e'));
    } on TypeError catch (e) {
      return Err(ParseFailure('OKX candles parse failed: $e'));
    } on StateError catch (e) {
      return Err(ParseFailure('OKX candles parse failed: $e'));
    } on RangeError catch (e) {
      return Err(ParseFailure('OKX candles parse failed: $e'));
    } on Exception catch (e) {
      return Err(NetworkFailure('OKX candles request failed: $e'));
    }
  }

  @override
  Future<Result<OrderBook>> fetchOrderBook(
    TradingSymbol symbol, {
    int? depth,
  }) async {
    try {
      final response = await _httpClient.get(
        _uri('/api/v5/market/books', {
          'instId': _instId(symbol),
          if (depth != null) 'sz': depth.toString(),
        }),
      );
      if (response.statusCode != 200) {
        return Err(NetworkFailure('OKX order book ${response.statusCode}'));
      }
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final apiError = _apiErrorMessage(json, 'order book');
      if (apiError.isNotEmpty) {
        return Err(NetworkFailure(apiError));
      }
      return Success(_parseOrderBook(_firstDataItem(json)));
    } on FormatException catch (e) {
      return Err(ParseFailure('OKX order book parse failed: $e'));
    } on TypeError catch (e) {
      return Err(ParseFailure('OKX order book parse failed: $e'));
    } on StateError catch (e) {
      return Err(ParseFailure('OKX order book parse failed: $e'));
    } on RangeError catch (e) {
      return Err(ParseFailure('OKX order book parse failed: $e'));
    } on Exception catch (e) {
      return Err(NetworkFailure('OKX order book request failed: $e'));
    }
  }

  @override
  Future<Result<List<Trade>>> fetchTrades(
    TradingSymbol symbol, {
    int? limit,
  }) async {
    try {
      final response = await _httpClient.get(
        _uri('/api/v5/market/trades', {
          'instId': _instId(symbol),
          if (limit != null) 'limit': limit.toString(),
        }),
      );
      if (response.statusCode != 200) {
        return Err(NetworkFailure('OKX trades ${response.statusCode}'));
      }
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final apiError = _apiErrorMessage(json, 'trades');
      if (apiError.isNotEmpty) {
        return Err(NetworkFailure(apiError));
      }
      final data = json['data'] as List<dynamic>;
      return Success(
        data.map((e) => _parseTrade(e as Map<String, dynamic>)).toList(),
      );
    } on FormatException catch (e) {
      return Err(ParseFailure('OKX trades parse failed: $e'));
    } on TypeError catch (e) {
      return Err(ParseFailure('OKX trades parse failed: $e'));
    } on StateError catch (e) {
      return Err(ParseFailure('OKX trades parse failed: $e'));
    } on RangeError catch (e) {
      return Err(ParseFailure('OKX trades parse failed: $e'));
    } on Exception catch (e) {
      return Err(NetworkFailure('OKX trades request failed: $e'));
    }
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

  String _timeframeCode(Timeframe timeframe) {
    return switch (timeframe) {
      Timeframe.m1 => '1m',
      Timeframe.m5 => '5m',
      Timeframe.m15 => '15m',
      Timeframe.m30 => '30m',
      Timeframe.h1 => '1H',
      Timeframe.h4 => '4H',
      Timeframe.d1 => '1D',
    };
  }
}
