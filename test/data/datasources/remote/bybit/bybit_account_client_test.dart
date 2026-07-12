import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:youtrade/core/failures.dart';
import 'package:youtrade/core/result.dart';
import 'package:youtrade/data/datasources/remote/bybit/bybit_account_client.dart';
import 'package:youtrade/domain/entities/account_order.dart';
import 'package:youtrade/domain/entities/account_position.dart';
import 'package:youtrade/domain/entities/account_wallet_balance.dart';

void main() {
  const apiKey = 'test-api-key';
  const apiSecret = 'test-api-secret';

  BybitAccountClient clientWith(
    http.Client httpClient, {
    String? apiKeyOverride,
    String? apiSecretOverride,
  }) {
    return BybitAccountClient(
      httpClient: httpClient,
      apiKey: apiKeyOverride ?? apiKey,
      apiSecret: apiSecretOverride ?? apiSecret,
    );
  }

  String expectedSignature(
    String timestamp,
    String apiKey,
    String queryString,
  ) {
    return Hmac(
      sha256,
      utf8.encode(apiSecret),
    ).convert(utf8.encode('$timestamp${apiKey}5000$queryString')).toString();
  }

  group('BybitAccountClient', () {
    test('default base URL is demo endpoint', () async {
      String? capturedHost;
      final client = clientWith(
        MockClient((request) async {
          capturedHost = request.url.host;
          return http.Response(_walletBalanceBody(), 200);
        }),
      );
      await client.getWalletBalance();
      expect(capturedHost, 'api-demo.bybit.com');
    });

    test('getWalletBalance signs request with HMAC-SHA256 headers', () async {
      Map<String, String>? capturedHeaders;
      Uri? capturedUri;
      final client = clientWith(
        MockClient((request) async {
          capturedHeaders = request.headers;
          capturedUri = request.url;
          return http.Response(_walletBalanceBody(), 200);
        }),
      );

      await client.getWalletBalance();

      expect(capturedUri!.path, '/v5/account/wallet-balance');
      expect(capturedUri!.query, 'accountType=UNIFIED');

      expect(capturedHeaders!['X-BAPI-API-KEY'], apiKey);
      final timestamp = capturedHeaders!['X-BAPI-TIMESTAMP']!;
      expect(int.tryParse(timestamp), isNotNull);
      expect(capturedHeaders!['X-BAPI-RECV-WINDOW'], '5000');
      final sign = capturedHeaders!['X-BAPI-SIGN']!;
      expect(sign, isNotEmpty);

      expect(sign, expectedSignature(timestamp, apiKey, 'accountType=UNIFIED'));
    });

    test('getWalletBalance parses equity and coins', () async {
      final client = clientWith(
        MockClient((_) async => http.Response(_walletBalanceBody(), 200)),
      );

      final result = await client.getWalletBalance();
      expect(result, isA<Success<WalletBalance>>());
      result.when(
        success: (balance) {
          expect(balance.accountType, 'UNIFIED');
          expect(balance.totalEquity, 10000.5);
          expect(balance.coins.length, 2);
          expect(balance.coins.first.coin, 'USDT');
          expect(balance.coins.first.walletBalance, 5000.0);
          expect(balance.coins.first.equity, 5000.0);
          expect(balance.coins.last.coin, 'BTC');
          expect(balance.coins.last.equity, 5000.5);
        },
        failure: (_) => fail('expected success'),
      );
    });

    test('getPositions parses symbol, side, size and unrealisedPnl', () async {
      Uri? capturedUri;
      final client = clientWith(
        MockClient((request) async {
          capturedUri = request.url;
          return http.Response(
            '{"retCode":0,"retMsg":"OK","result":{"category":"linear","list":['
            '{"symbol":"BTCUSDT","side":"Buy","size":"0.5","unrealisedPnl":"120.25"},'
            '{"symbol":"ETHUSDT","side":"Sell","size":"2.0","unrealisedPnl":"-10.0"}'
            ']}}',
            200,
          );
        }),
      );

      final result = await client.getPositions();
      expect(result, isA<Success<List<AccountPosition>>>());
      expect(capturedUri!.path, '/v5/position/list');
      expect(capturedUri!.queryParameters['settleCoin'], 'USDT');
      expect(capturedUri!.queryParameters['category'], 'linear');
      result.when(
        success: (positions) {
          expect(positions.length, 2);
          expect(positions.first.symbol, 'BTCUSDT');
          expect(positions.first.side, 'Buy');
          expect(positions.first.size, 0.5);
          expect(positions.first.unrealisedPnl, 120.25);
          expect(positions.first.isLong, isTrue);
          expect(positions.last.unrealisedPnl, -10.0);
          expect(positions.last.isLong, isFalse);
        },
        failure: (_) => fail('expected success'),
      );
    });

    test('getOpenOrders parses order fields', () async {
      Uri? capturedUri;
      final client = clientWith(
        MockClient((request) async {
          capturedUri = request.url;
          return http.Response(
            '{"retCode":0,"retMsg":"OK","result":{"category":"linear","list":['
            '{"orderId":"a1","symbol":"BTCUSDT","side":"Buy","orderType":"Limit",'
            '"price":"50000","qty":"0.1","orderStatus":"New","createdTime":"1700000000000"}'
            ']}}',
            200,
          );
        }),
      );

      final result = await client.getOpenOrders();
      expect(result, isA<Success<List<AccountOrder>>>());
      expect(capturedUri!.path, '/v5/order/realtime');
      expect(capturedUri!.query, 'category=linear');
      result.when(
        success: (orders) {
          expect(orders.length, 1);
          expect(orders.first.orderId, 'a1');
          expect(orders.first.symbol, 'BTCUSDT');
          expect(orders.first.side, 'Buy');
          expect(orders.first.orderType, 'Limit');
          expect(orders.first.price, 50000.0);
          expect(orders.first.qty, 0.1);
          expect(orders.first.orderStatus, 'New');
          expect(orders.first.createdTime, '1700000000000');
          expect(orders.first.isBuy, isTrue);
        },
        failure: (_) => fail('expected success'),
      );
    });

    test('getOrderHistory parses order fields', () async {
      Uri? capturedUri;
      final client = clientWith(
        MockClient((request) async {
          capturedUri = request.url;
          return http.Response(
            '{"retCode":0,"retMsg":"OK","result":{"category":"linear","list":['
            '{"orderId":"h1","symbol":"ETHUSDT","side":"Sell","orderType":"Market",'
            '"price":"3000","qty":"1.5","orderStatus":"Filled","createdTime":"1700000001000"}'
            ']}}',
            200,
          );
        }),
      );

      final result = await client.getOrderHistory();
      expect(result, isA<Success<List<AccountOrder>>>());
      expect(capturedUri!.path, '/v5/order/history');
      expect(capturedUri!.queryParameters['limit'], '50');
      result.when(
        success: (orders) {
          expect(orders.first.orderId, 'h1');
          expect(orders.first.orderStatus, 'Filled');
          expect(orders.first.isBuy, isFalse);
        },
        failure: (_) => fail('expected success'),
      );
    });

    test('missing credentials returns Err gracefully', () async {
      final client = clientWith(
        MockClient((_) async => http.Response(_walletBalanceBody(), 200)),
        apiKeyOverride: '',
        apiSecretOverride: '',
      );

      final result = await client.getWalletBalance();
      expect(result, isA<Err<WalletBalance>>());
      result.when(
        success: (_) => fail('expected failure'),
        failure: (failure) {
          expect(failure, isA<ConfigFailure>());
          expect(failure.message, contains('credentials'));
        },
      );
    });

    test('http error returns NetworkFailure', () async {
      final client = clientWith(
        MockClient((_) async => http.Response('Unauthorized', 401)),
      );

      final result = await client.getWalletBalance();
      expect(result, isA<Err<WalletBalance>>());
      result.when(
        success: (_) => fail('expected failure'),
        failure: (failure) {
          expect(failure, isA<NetworkFailure>());
          expect(failure.message, 'Bybit wallet balance 401');
        },
      );
    });

    test('malformed json returns ParseFailure', () async {
      final client = clientWith(
        MockClient((_) async => http.Response('not-json', 200)),
      );

      final result = await client.getPositions();
      expect(result, isA<Err<List<AccountPosition>>>());
      result.when(
        success: (_) => fail('expected failure'),
        failure: (failure) {
          expect(failure, isA<ParseFailure>());
          expect(
            failure.message,
            startsWith('Bybit positions parse failed: FormatException'),
          );
        },
      );
    });

    test('retCode != 0 returns NetworkFailure', () async {
      final client = clientWith(
        MockClient(
          (_) async => http.Response(
            '{"retCode":10001,"retMsg":"Invalid apiKey","result":{}}',
            200,
          ),
        ),
      );

      final result = await client.getOpenOrders();
      expect(result, isA<Err<List<AccountOrder>>>());
      result.when(
        success: (_) => fail('expected failure'),
        failure: (failure) {
          expect(failure, isA<NetworkFailure>());
          expect(
            failure.message,
            'Bybit open orders API error: 10001 Invalid apiKey',
          );
        },
      );
    });

    test('request exception returns NetworkFailure', () async {
      final client = clientWith(
        MockClient((_) async => throw Exception('network down')),
      );

      final result = await client.getOrderHistory();
      expect(result, isA<Err<List<AccountOrder>>>());
      result.when(
        success: (_) => fail('expected failure'),
        failure: (failure) {
          expect(failure, isA<NetworkFailure>());
          expect(
            failure.message,
            'Bybit order history request failed: Exception: network down',
          );
        },
      );
    });
  });
}

String _walletBalanceBody() {
  return '{"retCode":0,"retMsg":"OK","result":{"list":['
      '{"accountType":"UNIFIED","totalEquity":"10000.5","coin":['
      '{"coin":"USDT","walletBalance":"5000.0","equity":"5000.0"},'
      '{"coin":"BTC","walletBalance":"0.5","equity":"5000.5"}'
      ']}]}}';
}
