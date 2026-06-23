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

final class BinanceRestClient
    implements TickerSource, CandleSource, OrderBookSource, TradeSource {
  BinanceRestClient({http.Client? httpClient, String? baseUrl})
    : _httpClient = httpClient ?? http.Client(),
      _baseUrl = baseUrl ?? 'https://api.binance.com';

  final http.Client _httpClient;
  final String _baseUrl;

  void close() => _httpClient.close();

  Uri _uri(String path, Map<String, String> query) =>
      Uri.parse('$_baseUrl$path').replace(queryParameters: query);

  @override
  Future<Result<Ticker>> fetchTicker(TradingSymbol symbol) async {
    try {
      final response = await _httpClient
          .get(_uri('/api/v3/ticker/24hr', {'symbol': symbol.rawSymbol}))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        return Err(NetworkFailure('Binance ticker ${response.statusCode}'));
      }
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return Success(_parseTicker(symbol, json));
    } on TimeoutException {
      return const Err(NetworkFailure('Binance ticker request timed out'));
    } on FormatException catch (e) {
      return Err(ParseFailure('Binance ticker parse failed: $e'));
    } on TypeError catch (e) {
      return Err(ParseFailure('Binance ticker parse failed: $e'));
    } on StateError catch (e) {
      return Err(ParseFailure('Binance ticker parse failed: $e'));
    } on RangeError catch (e) {
      return Err(ParseFailure('Binance ticker parse failed: $e'));
    } on Exception catch (e) {
      return Err(NetworkFailure('Binance ticker request failed: $e'));
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
            _uri('/api/v3/klines', {
              'symbol': symbol.rawSymbol,
              'interval': _timeframeCode(timeframe),
              if (limit != null) 'limit': limit.toString(),
            }),
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        return Err(NetworkFailure('Binance candles ${response.statusCode}'));
      }
      final json = jsonDecode(response.body) as List<dynamic>;
      return Success(
        json.map((e) => _parseCandle(e as List<dynamic>)).toList(),
      );
    } on TimeoutException {
      return const Err(NetworkFailure('Binance candles request timed out'));
    } on FormatException catch (e) {
      return Err(ParseFailure('Binance candles parse failed: $e'));
    } on TypeError catch (e) {
      return Err(ParseFailure('Binance candles parse failed: $e'));
    } on StateError catch (e) {
      return Err(ParseFailure('Binance candles parse failed: $e'));
    } on RangeError catch (e) {
      return Err(ParseFailure('Binance candles parse failed: $e'));
    } on Exception catch (e) {
      return Err(NetworkFailure('Binance candles request failed: $e'));
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
            _uri('/api/v3/depth', {
              'symbol': symbol.rawSymbol,
              if (depth != null) 'limit': depth.toString(),
            }),
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        return Err(NetworkFailure('Binance order book ${response.statusCode}'));
      }
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return Success(_parseOrderBook(json));
    } on TimeoutException {
      return const Err(NetworkFailure('Binance order book request timed out'));
    } on FormatException catch (e) {
      return Err(ParseFailure('Binance order book parse failed: $e'));
    } on TypeError catch (e) {
      return Err(ParseFailure('Binance order book parse failed: $e'));
    } on StateError catch (e) {
      return Err(ParseFailure('Binance order book parse failed: $e'));
    } on RangeError catch (e) {
      return Err(ParseFailure('Binance order book parse failed: $e'));
    } on Exception catch (e) {
      return Err(NetworkFailure('Binance order book request failed: $e'));
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
            _uri('/api/v3/trades', {
              'symbol': symbol.rawSymbol,
              if (limit != null) 'limit': limit.toString(),
            }),
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        return Err(NetworkFailure('Binance trades ${response.statusCode}'));
      }
      final json = jsonDecode(response.body) as List<dynamic>;
      return Success(
        json.map((e) => _parseTrade(e as Map<String, dynamic>)).toList(),
      );
    } on TimeoutException {
      return const Err(NetworkFailure('Binance trades request timed out'));
    } on FormatException catch (e) {
      return Err(ParseFailure('Binance trades parse failed: $e'));
    } on TypeError catch (e) {
      return Err(ParseFailure('Binance trades parse failed: $e'));
    } on StateError catch (e) {
      return Err(ParseFailure('Binance trades parse failed: $e'));
    } on RangeError catch (e) {
      return Err(ParseFailure('Binance trades parse failed: $e'));
    } on Exception catch (e) {
      return Err(NetworkFailure('Binance trades request failed: $e'));
    }
  }

  Ticker _parseTicker(TradingSymbol symbol, Map<String, dynamic> json) {
    return Ticker(
      symbol: symbol,
      lastPrice: double.parse(json['lastPrice'] as String),
      bid: double.parse(json['bidPrice'] as String),
      ask: double.parse(json['askPrice'] as String),
      change24h: double.parse(json['priceChange'] as String),
      change24hPercent:
          double.parse(json['priceChangePercent'] as String) / 100,
      volume: double.parse(json['volume'] as String),
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        json['closeTime'] as int,
        isUtc: true,
      ),
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
        data[0] as int,
        isUtc: true,
      ),
    );
  }

  OrderBook _parseOrderBook(Map<String, dynamic> json) {
    final bids = (json['bids'] as List<dynamic>)
        .map((e) => _parseLevel(e as List<dynamic>))
        .toList();
    final asks = (json['asks'] as List<dynamic>)
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
      price: double.parse(json['price'] as String),
      amount: double.parse(json['qty'] as String),
      side: (json['isBuyerMaker'] as bool) ? TradeSide.sell : TradeSide.buy,
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        json['time'] as int,
        isUtc: true,
      ),
      tradeId: json['id']?.toString(),
    );
  }

  String _timeframeCode(Timeframe timeframe) {
    return switch (timeframe) {
      Timeframe.w1 => '1w',
      _ => timeframe.code,
    };
  }
}
