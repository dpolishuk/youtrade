import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import '../../../../core/bybit_config.dart';
import '../../../../core/failures.dart';
import '../../../../core/result.dart';
import '../../../../domain/entities/account_order.dart';
import '../../../../domain/entities/account_position.dart';
import '../../../../domain/entities/account_wallet_balance.dart';

final class BybitAccountClient {
  BybitAccountClient({
    http.Client? httpClient,
    String? baseUrl,
    String? apiKey,
    String? apiSecret,
  }) : _httpClient = httpClient ?? http.Client(),
       _baseUrl = baseUrl ?? BybitConfig.baseUrl,
       _apiKey = apiKey ?? BybitConfig.apiKey,
       _apiSecret = apiSecret ?? BybitConfig.apiSecret;

  static const String _recvWindow = '5000';

  final http.Client _httpClient;
  final String _baseUrl;
  final String _apiKey;
  final String _apiSecret;

  void close() => _httpClient.close();

  Future<Result<WalletBalance>> getWalletBalance() {
    return _signedGet(
      '/v5/account/wallet-balance',
      {'accountType': 'UNIFIED'},
      _parseWalletBalance,
      'wallet balance',
    );
  }

  Future<Result<List<AccountPosition>>> getPositions({
    String settleCoin = 'USDT',
  }) {
    return _signedGet(
      '/v5/position/list',
      {'category': 'linear', 'settleCoin': settleCoin},
      _parsePositions,
      'positions',
    );
  }

  Future<Result<List<AccountOrder>>> getOpenOrders() {
    return _signedGet(
      '/v5/order/realtime',
      {'category': 'linear'},
      _parseOrders,
      'open orders',
    );
  }

  Future<Result<List<AccountOrder>>> getOrderHistory() {
    return _signedGet(
      '/v5/order/history',
      {'category': 'linear', 'limit': '50'},
      _parseOrders,
      'order history',
    );
  }

  Future<Result<T>> _signedGet<T>(
    String path,
    Map<String, String> params,
    T Function(Map<String, dynamic> result) parse,
    String context,
  ) async {
    if (_apiKey.isEmpty || _apiSecret.isEmpty) {
      return Err(ConfigFailure('Bybit $context credentials not configured'));
    }
    try {
      final queryString = _buildQueryString(params);
      final timestamp = DateTime.now()
          .toUtc()
          .millisecondsSinceEpoch
          .toString();
      final response = await _httpClient
          .get(
            Uri.parse('$_baseUrl$path?$queryString'),
            headers: {
              'X-BAPI-API-KEY': _apiKey,
              'X-BAPI-TIMESTAMP': timestamp,
              'X-BAPI-RECV-WINDOW': _recvWindow,
              'X-BAPI-SIGN': _sign(timestamp, queryString),
            },
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        return Err(NetworkFailure('Bybit $context ${response.statusCode}'));
      }
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final apiError = _apiErrorMessage(json, context);
      if (apiError.isNotEmpty) {
        return Err(NetworkFailure(apiError));
      }
      final result = json['result'] as Map<String, dynamic>;
      return Success(parse(result));
    } on TimeoutException {
      return Err(NetworkFailure('Bybit $context request timed out'));
    } on FormatException catch (e) {
      return Err(ParseFailure('Bybit $context parse failed: $e'));
    } on TypeError catch (e) {
      return Err(ParseFailure('Bybit $context parse failed: $e'));
    } on StateError catch (e) {
      return Err(ParseFailure('Bybit $context parse failed: $e'));
    } on RangeError catch (e) {
      return Err(ParseFailure('Bybit $context parse failed: $e'));
    } on Exception catch (e) {
      return Err(NetworkFailure('Bybit $context request failed: $e'));
    }
  }

  String _buildQueryString(Map<String, String> params) {
    final sortedKeys = params.keys.toList()..sort();
    return sortedKeys.map((key) => '$key=${params[key]}').join('&');
  }

  String _sign(String timestamp, String queryString) {
    final payload = '$timestamp$_apiKey$_recvWindow$queryString';
    return Hmac(
      sha256,
      utf8.encode(_apiSecret),
    ).convert(utf8.encode(payload)).toString();
  }

  String _apiErrorMessage(Map<String, dynamic> json, String context) {
    final retCode = json['retCode'] as int?;
    if (retCode == null || retCode == 0) return '';
    final retMsg = json['retMsg'] as String? ?? '';
    return 'Bybit $context API error: $retCode $retMsg';
  }

  WalletBalance _parseWalletBalance(Map<String, dynamic> result) {
    final list = result['list'] as List<dynamic>;
    final account = list.first as Map<String, dynamic>;
    final coinsRaw = account['coin'] as List<dynamic>? ?? [];
    return WalletBalance(
      accountType: account['accountType'] as String,
      totalEquity: double.parse(account['totalEquity'] as String),
      coins: coinsRaw
          .map((coin) => _parseWalletCoin(coin as Map<String, dynamic>))
          .toList(),
    );
  }

  WalletCoin _parseWalletCoin(Map<String, dynamic> json) {
    return WalletCoin(
      coin: json['coin'] as String,
      walletBalance: double.parse(json['walletBalance'] as String),
      equity: double.parse(json['equity'] as String),
    );
  }

  List<AccountPosition> _parsePositions(Map<String, dynamic> result) {
    final list = result['list'] as List<dynamic>;
    return list
        .map((item) => _parsePosition(item as Map<String, dynamic>))
        .toList();
  }

  AccountPosition _parsePosition(Map<String, dynamic> json) {
    return AccountPosition(
      symbol: json['symbol'] as String,
      side: json['side'] as String,
      size: double.parse(json['size'] as String),
      unrealisedPnl: double.parse(json['unrealisedPnl'] as String),
    );
  }

  List<AccountOrder> _parseOrders(Map<String, dynamic> result) {
    final list = result['list'] as List<dynamic>;
    return list
        .map((item) => _parseOrder(item as Map<String, dynamic>))
        .toList();
  }

  AccountOrder _parseOrder(Map<String, dynamic> json) {
    return AccountOrder(
      orderId: json['orderId'] as String,
      symbol: json['symbol'] as String,
      side: json['side'] as String,
      orderType: json['orderType'] as String,
      price: double.parse(json['price'] as String),
      qty: double.parse(json['qty'] as String),
      orderStatus: json['orderStatus'] as String,
      createdTime: json['createdTime']?.toString(),
    );
  }
}
