import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:youtrade/data/datasources/remote/bybit/bybit_account_client.dart';
import 'package:youtrade/domain/entities/account_order.dart';
import 'package:youtrade/presentation/providers/orders_provider.dart';
import 'package:youtrade/presentation/providers/portfolio_data_provider.dart';

void main() {
  group('formatOrderTime', () {
    test('formats epoch-millis into HH:mm UTC', () {
      // 2024-01-15T09:12:00Z = 1705309920000 ms
      expect(formatOrderTime('1705309920000'), '09:12');
    });

    test('returns null for missing input', () {
      expect(formatOrderTime(null), isNull);
    });

    test('returns null for empty input', () {
      expect(formatOrderTime(''), isNull);
    });

    test('returns null for non-numeric input', () {
      expect(formatOrderTime('not-a-number'), isNull);
    });
  });

  group('accountOrderToOrder', () {
    test('maps Buy side to BUY', () {
      final order = accountOrderToOrder(
        const AccountOrder(
          orderId: 'order-1',
          symbol: 'BTCUSDT',
          side: 'Buy',
          orderType: 'Limit',
          price: 58400.0,
          qty: 0.5,
          orderStatus: 'New',
        ),
      );

      expect(order.orderId, 'order-1');
      expect(order.symbol, 'BTCUSDT');
      expect(order.side, 'BUY');
      expect(order.type, 'Limit');
      expect(order.venue, 'Bybit');
      expect(order.price, '58,400.00');
      expect(order.qty, '0.5000');
      expect(order.filled, '0%');
      expect(order.status, 'New');
    });

    test('maps Sell side to SELL', () {
      final order = accountOrderToOrder(
        const AccountOrder(
          orderId: 'order-2',
          symbol: 'ETHUSDT',
          side: 'Sell',
          orderType: 'Market',
          price: 3050.0,
          qty: 8.0,
          orderStatus: 'Filled',
        ),
      );

      expect(order.side, 'SELL');
      expect(order.type, 'Market');
      expect(order.price, '3,050.00');
      expect(order.qty, '8.00');
      expect(order.status, 'Filled');
    });

    test('formats large-integer qty with 2 decimals', () {
      final order = accountOrderToOrder(
        const AccountOrder(
          orderId: 'order-3',
          symbol: 'SOLUSDT',
          side: 'Buy',
          orderType: 'Limit',
          price: 150.0,
          qty: 120.0,
          orderStatus: 'PartiallyFilled',
        ),
      );

      expect(order.qty, '120.00');
    });

    test('maps createdTime to HH:mm', () {
      final order = accountOrderToOrder(
        const AccountOrder(
          orderId: 'order-4',
          symbol: 'BTCUSDT',
          side: 'Buy',
          orderType: 'Limit',
          price: 100.0,
          qty: 1.0,
          orderStatus: 'New',
          createdTime: '1705309920000',
        ),
      );

      expect(order.time, '09:12');
    });

    test('leaves time null when createdTime absent', () {
      final order = accountOrderToOrder(
        const AccountOrder(
          orderId: 'order-5',
          symbol: 'BTCUSDT',
          side: 'Buy',
          orderType: 'Limit',
          price: 100.0,
          qty: 1.0,
          orderStatus: 'New',
        ),
      );

      expect(order.time, isNull);
    });
  });

  group('ordersProvider', () {
    BybitAccountClient clientWithResponses({
      required Map<String, dynamic> openResponse,
      required Map<String, dynamic> historyResponse,
    }) {
      return BybitAccountClient(
        apiKey: 'test-key',
        apiSecret: 'test-secret',
        httpClient: MockClient((request) async {
          final path = request.url.path;
          if (path.contains('/v5/order/realtime')) {
            return http.Response(jsonEncode(openResponse), 200);
          }
          if (path.contains('/v5/order/history')) {
            return http.Response(jsonEncode(historyResponse), 200);
          }
          return http.Response('{"retCode":1,"retMsg":"unknown"}', 200);
        }),
      );
    }

    Map<String, dynamic> ordersJson(List<Map<String, dynamic>> orders) {
      return {
        'retCode': 0,
        'retMsg': 'OK',
        'result': {'category': 'linear', 'list': orders},
      };
    }

    test('is in loading state initially', () async {
      final pendingClient = BybitAccountClient(
        apiKey: 'test-key',
        apiSecret: 'test-secret',
        httpClient: MockClient((request) => Completer<http.Response>().future),
      );
      final container = ProviderContainer(
        overrides: [
          bybitHasCredentialsProvider.overrideWithValue(true),
          bybitAccountClientProvider.overrideWithValue(pendingClient),
        ],
      );
      addTearDown(container.dispose);

      final asyncValue = container.read(ordersProvider);
      expect(asyncValue.isLoading, isTrue);
    });

    test('returns needsCredentials state when credentials missing', () async {
      final container = ProviderContainer(
        overrides: [bybitHasCredentialsProvider.overrideWithValue(false)],
      );
      addTearDown(container.dispose);

      final data = await container.read(ordersProvider.future);

      expect(data.needsCredentials, isTrue);
      expect(data.openOrders, isEmpty);
      expect(data.historyOrders, isEmpty);
    });

    test('fetches open orders and history and maps them to Order', () async {
      final client = clientWithResponses(
        openResponse: ordersJson([
          {
            'orderId': 'open-1',
            'symbol': 'BTCUSDT',
            'side': 'Buy',
            'orderType': 'Limit',
            'price': '58400.0',
            'qty': '0.5',
            'orderStatus': 'New',
            'createdTime': '1705307520000',
          },
        ]),
        historyResponse: ordersJson([
          {
            'orderId': 'hist-1',
            'symbol': 'ETHUSDT',
            'side': 'Sell',
            'orderType': 'Market',
            'price': '3050.0',
            'qty': '8.0',
            'orderStatus': 'Filled',
            'createdTime': '1705307000000',
          },
        ]),
      );

      final container = ProviderContainer(
        overrides: [
          bybitHasCredentialsProvider.overrideWithValue(true),
          bybitAccountClientProvider.overrideWithValue(client),
        ],
      );
      addTearDown(container.dispose);

      final data = await container.read(ordersProvider.future);

      expect(data.needsCredentials, isFalse);
      expect(data.openOrders.length, 1);
      expect(data.openOrders.first.orderId, 'open-1');
      expect(data.openOrders.first.side, 'BUY');
      expect(data.historyOrders.length, 1);
      expect(data.historyOrders.first.orderId, 'hist-1');
      expect(data.historyOrders.first.side, 'SELL');
      expect(data.historyOrders.first.status, 'Filled');
    });

    test('handles empty order lists gracefully', () async {
      final client = clientWithResponses(
        openResponse: ordersJson(const []),
        historyResponse: ordersJson(const []),
      );

      final container = ProviderContainer(
        overrides: [
          bybitHasCredentialsProvider.overrideWithValue(true),
          bybitAccountClientProvider.overrideWithValue(client),
        ],
      );
      addTearDown(container.dispose);

      final data = await container.read(ordersProvider.future);

      expect(data.needsCredentials, isFalse);
      expect(data.openOrders, isEmpty);
      expect(data.historyOrders, isEmpty);
    });

    test('throws when open orders API returns an error', () async {
      final client = clientWithResponses(
        openResponse: {'retCode': 10001, 'retMsg': 'error', 'result': {}},
        historyResponse: ordersJson(const []),
      );

      final container = ProviderContainer(
        overrides: [
          bybitHasCredentialsProvider.overrideWithValue(true),
          bybitAccountClientProvider.overrideWithValue(client),
        ],
      );
      addTearDown(container.dispose);

      expect(() => container.read(ordersProvider.future), throwsException);
    });

    test('throws when history API returns an error', () async {
      final client = clientWithResponses(
        openResponse: ordersJson(const []),
        historyResponse: {'retCode': 10001, 'retMsg': 'error', 'result': {}},
      );

      final container = ProviderContainer(
        overrides: [
          bybitHasCredentialsProvider.overrideWithValue(true),
          bybitAccountClientProvider.overrideWithValue(client),
        ],
      );
      addTearDown(container.dispose);

      expect(() => container.read(ordersProvider.future), throwsException);
    });
  });
}
