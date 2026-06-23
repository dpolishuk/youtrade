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

final class CoinbaseRestClient
    implements TickerSource, CandleSource, OrderBookSource, TradeSource {
  CoinbaseRestClient({http.Client? httpClient, String? baseUrl})
    : _httpClient = httpClient ?? http.Client(),
      _baseUrl = baseUrl ?? 'https://api.exchange.coinbase.com';

  final http.Client _httpClient;
  final String _baseUrl;

  void close() => _httpClient.close();

  Uri _uri(String path, Map<String, String> query) =>
      Uri.parse('$_baseUrl$path').replace(queryParameters: query);

  String _productId(TradingSymbol symbol) => '${symbol.base}-${symbol.quote}';

  @override
  Future<Result<Ticker>> fetchTicker(TradingSymbol symbol) async {
    try {
      final statsResult = await _fetchStats(symbol);
      final quoteResult = await _fetchTickerQuote(symbol);
      return statsResult.flatMap(
        (stats) =>
            quoteResult.map((quote) => _buildTicker(symbol, stats, quote)),
      );
    } on FormatException catch (e) {
      return Err(ParseFailure('Coinbase ticker parse failed: $e'));
    } on TypeError catch (e) {
      return Err(ParseFailure('Coinbase ticker parse failed: $e'));
    } on StateError catch (e) {
      return Err(ParseFailure('Coinbase ticker parse failed: $e'));
    } on RangeError catch (e) {
      return Err(ParseFailure('Coinbase ticker parse failed: $e'));
    } on Exception catch (e) {
      return Err(NetworkFailure('Coinbase ticker request failed: $e'));
    }
  }

  Future<Result<Map<String, dynamic>>> _fetchStats(TradingSymbol symbol) async {
    try {
      final response = await _httpClient
          .get(_uri('/products/${_productId(symbol)}/stats', const {}))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        return Err(
          NetworkFailure('Coinbase ticker stats ${response.statusCode}'),
        );
      }
      return Success(jsonDecode(response.body) as Map<String, dynamic>);
    } on TimeoutException {
      return const Err(
        NetworkFailure('Coinbase ticker stats request timed out'),
      );
    }
  }

  Future<Result<Map<String, dynamic>>> _fetchTickerQuote(
    TradingSymbol symbol,
  ) async {
    try {
      final response = await _httpClient
          .get(_uri('/products/${_productId(symbol)}/ticker', const {}))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        return Err(
          NetworkFailure('Coinbase ticker quote ${response.statusCode}'),
        );
      }
      return Success(jsonDecode(response.body) as Map<String, dynamic>);
    } on TimeoutException {
      return const Err(
        NetworkFailure('Coinbase ticker quote request timed out'),
      );
    }
  }

  Ticker _buildTicker(
    TradingSymbol symbol,
    Map<String, dynamic> stats,
    Map<String, dynamic> quote,
  ) {
    final lastPrice = double.parse(quote['price'] as String);
    final open24h = double.parse(stats['open'] as String);
    final change24h = lastPrice - open24h;
    final change24hPercent = open24h == 0.0 ? 0.0 : change24h / open24h * 100;

    return Ticker(
      symbol: symbol,
      lastPrice: lastPrice,
      bid: double.parse(quote['bid'] as String),
      ask: double.parse(quote['ask'] as String),
      change24h: change24h,
      change24hPercent: change24hPercent,
      volume: double.parse(
        (quote['volume'] as String?) ?? (stats['volume'] as String),
      ),
      timestamp: DateTime.parse(quote['time'] as String).toUtc(),
    );
  }

  @override
  Future<Result<List<Candle>>> fetchCandles(
    TradingSymbol symbol,
    Timeframe timeframe, {
    int? limit,
  }) async {
    try {
      final query = <String, String>{
        'granularity': _granularity(timeframe).toString(),
      };
      if (limit != null) {
        query['limit'] = limit.toString();
      }
      final response = await _httpClient
          .get(_uri('/products/${_productId(symbol)}/candles', query))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        return Err(NetworkFailure('Coinbase candles ${response.statusCode}'));
      }
      final json = jsonDecode(response.body) as List<dynamic>;
      if (json.isEmpty) {
        return Err(
          const ParseFailure('Coinbase candles parse failed: empty response'),
        );
      }
      return Success(
        json.map((e) => _parseCandle(e as List<dynamic>)).toList(),
      );
    } on TimeoutException {
      return const Err(NetworkFailure('Coinbase candles request timed out'));
    } on FormatException catch (e) {
      return Err(ParseFailure('Coinbase candles parse failed: $e'));
    } on TypeError catch (e) {
      return Err(ParseFailure('Coinbase candles parse failed: $e'));
    } on StateError catch (e) {
      return Err(ParseFailure('Coinbase candles parse failed: $e'));
    } on RangeError catch (e) {
      return Err(ParseFailure('Coinbase candles parse failed: $e'));
    } on Exception catch (e) {
      return Err(NetworkFailure('Coinbase candles request failed: $e'));
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
            _uri('/products/${_productId(symbol)}/book', const {'level': '2'}),
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        return Err(
          NetworkFailure('Coinbase order book ${response.statusCode}'),
        );
      }
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return Success(_parseOrderBook(json));
    } on TimeoutException {
      return const Err(NetworkFailure('Coinbase order book request timed out'));
    } on FormatException catch (e) {
      return Err(ParseFailure('Coinbase order book parse failed: $e'));
    } on TypeError catch (e) {
      return Err(ParseFailure('Coinbase order book parse failed: $e'));
    } on StateError catch (e) {
      return Err(ParseFailure('Coinbase order book parse failed: $e'));
    } on RangeError catch (e) {
      return Err(ParseFailure('Coinbase order book parse failed: $e'));
    } on Exception catch (e) {
      return Err(NetworkFailure('Coinbase order book request failed: $e'));
    }
  }

  @override
  Future<Result<List<Trade>>> fetchTrades(
    TradingSymbol symbol, {
    int? limit,
  }) async {
    try {
      final query = <String, String>{};
      if (limit != null) {
        query['limit'] = limit.toString();
      }
      final response = await _httpClient
          .get(_uri('/products/${_productId(symbol)}/trades', query))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        return Err(NetworkFailure('Coinbase trades ${response.statusCode}'));
      }
      final json = jsonDecode(response.body) as List<dynamic>;
      return Success(
        json.map((e) => _parseTrade(e as Map<String, dynamic>)).toList(),
      );
    } on TimeoutException {
      return const Err(NetworkFailure('Coinbase trades request timed out'));
    } on FormatException catch (e) {
      return Err(ParseFailure('Coinbase trades parse failed: $e'));
    } on TypeError catch (e) {
      return Err(ParseFailure('Coinbase trades parse failed: $e'));
    } on StateError catch (e) {
      return Err(ParseFailure('Coinbase trades parse failed: $e'));
    } on RangeError catch (e) {
      return Err(ParseFailure('Coinbase trades parse failed: $e'));
    } on Exception catch (e) {
      return Err(NetworkFailure('Coinbase trades request failed: $e'));
    }
  }

  Candle _parseCandle(List<dynamic> data) {
    final timeSeconds = _parseInt(data[0]);
    return Candle(
      open: _parseDouble(data[3]),
      high: _parseDouble(data[2]),
      low: _parseDouble(data[1]),
      close: _parseDouble(data[4]),
      volume: _parseDouble(data[5]),
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        timeSeconds * 1000,
        isUtc: true,
      ),
    );
  }

  double _parseDouble(dynamic value) {
    if (value is String) return double.parse(value);
    if (value is num) return value.toDouble();
    throw FormatException('Expected numeric value, got $value');
  }

  int _parseInt(dynamic value) {
    if (value is String) return int.parse(value);
    if (value is int) return value;
    if (value is num) return value.toInt();
    throw FormatException('Expected integer value, got $value');
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
    final sideString = json['side'] as String;
    final side = switch (sideString.toLowerCase()) {
      'buy' => TradeSide.buy,
      'sell' => TradeSide.sell,
      _ => throw FormatException('Unknown trade side: $sideString'),
    };
    final price = double.parse(json['price'] as String);
    final amount = double.parse(json['size'] as String);
    if (price < 0 || amount < 0) {
      throw FormatException(
        'Expected non-negative price and size, got price=$price size=$amount',
      );
    }
    return Trade(
      price: price,
      amount: amount,
      side: side,
      timestamp: DateTime.parse(json['time'] as String).toUtc(),
      tradeId: json['trade_id']?.toString(),
    );
  }

  int _granularity(Timeframe timeframe) {
    return switch (timeframe) {
      Timeframe.m1 => 60,
      Timeframe.m5 => 300,
      Timeframe.m15 => 900,
      Timeframe.h1 => 3600,
      Timeframe.h4 => 14400,
      Timeframe.d1 => 86400,
      Timeframe.w1 => 604800,
    };
  }
}
