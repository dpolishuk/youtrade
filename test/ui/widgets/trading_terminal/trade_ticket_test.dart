import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:youtrade/data/datasources/remote/bybit/bybit_account_client.dart';
import 'package:youtrade/domain/entities/symbol.dart';
import 'package:youtrade/domain/entities/ticker.dart';
import 'package:youtrade/domain/entities/venue.dart';
import 'package:youtrade/presentation/providers/portfolio_data_provider.dart';
import 'package:youtrade/presentation/theme/app_theme.dart';
import 'package:youtrade/presentation/theme/theme_mode.dart';
import 'package:youtrade/ui/widgets/trading_terminal/trade_ticket.dart';

final _symbol = TradingSymbol(
  base: 'BTC',
  quote: 'USDT',
  venue: Venue.bybit,
  rawSymbol: 'BTCUSDT',
);

final _ticker = Ticker(
  symbol: _symbol,
  lastPrice: 60000,
  bid: 59900,
  ask: 60100,
  change24h: 1200,
  change24hPercent: 0.02,
  volume: 1000,
  timestamp: DateTime.utc(2026, 1, 1),
);

BybitAccountClient _successClient({String orderId = 'order-abc'}) {
  return BybitAccountClient(
    apiKey: 'test-key',
    apiSecret: 'test-secret',
    httpClient: MockClient((request) async {
      if (request.url.path.contains('/v5/order/create')) {
        return http.Response(
          jsonEncode({
            'retCode': 0,
            'retMsg': 'OK',
            'result': {'orderId': orderId, 'orderLinkId': 'link-1'},
          }),
          200,
        );
      }
      return http.Response('{"retCode":1,"retMsg":"unknown"}', 200);
    }),
  );
}

BybitAccountClient _errorClient() {
  return BybitAccountClient(
    apiKey: 'test-key',
    apiSecret: 'test-secret',
    httpClient: MockClient((request) async {
      if (request.url.path.contains('/v5/order/create')) {
        return http.Response(
          jsonEncode({
            'retCode': 10001,
            'retMsg': 'insufficient balance',
            'result': {},
          }),
          200,
        );
      }
      return http.Response('{"retCode":1,"retMsg":"unknown"}', 200);
    }),
  );
}

BybitAccountClient _capturingClient(void Function(String body) onPlaceOrder) {
  return BybitAccountClient(
    apiKey: 'test-key',
    apiSecret: 'test-secret',
    httpClient: MockClient((request) async {
      if (request.url.path.contains('/v5/order/create')) {
        onPlaceOrder(request.body);
        return http.Response(
          jsonEncode({
            'retCode': 0,
            'retMsg': 'OK',
            'result': {'orderId': 'order-captured', 'orderLinkId': 'link-x'},
          }),
          200,
        );
      }
      return http.Response('{"retCode":1,"retMsg":"unknown"}', 200);
    }),
  );
}

void main() {
  group('TradeTicket', () {
    Widget buildTicket({List<Override> overrides = const []}) {
      return ProviderScope(
        overrides: overrides,
        child: MaterialApp(
          theme: AppTheme.dark(AppVisualDirection.flux),
          home: Scaffold(
            body: SingleChildScrollView(
              child: TradeTicket(
                symbol: _symbol,
                tickerAsync: AsyncValue.data(_ticker),
              ),
            ),
          ),
        ),
      );
    }

    List<Override> credentialsOverrides(BybitAccountClient client) => [
      bybitHasCredentialsProvider.overrideWithValue(true),
      bybitAccountClientProvider.overrideWithValue(client),
    ];

    testWidgets('renders uppercase trade ticket labels', (tester) async {
      await tester.pumpWidget(buildTicket());
      await tester.pumpAndSettle();

      expect(find.text('PRICE'), findsOneWidget);
      expect(find.text('LEVERAGE'), findsOneWidget);
      expect(find.text('ORDER SIZE'), findsOneWidget);
    });

    testWidgets('submit shows confirmation dialog with order details', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTicket(overrides: credentialsOverrides(_successClient())),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Buy / Long BTC'));
      await tester.pumpAndSettle();

      // sizeQty = 4.2 * 25 / 100 = 1.05 → "1.050"
      // price = 60000, decimals = 1 → "60,000.0"
      expect(find.text('Buy 1.050 BTC @ 60,000.0'), findsOneWidget);
      expect(find.text('Confirm'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('confirm calls placeOrder with correct parameters', (
      tester,
    ) async {
      String? capturedBody;
      final client = _capturingClient((body) => capturedBody = body);

      await tester.pumpWidget(
        buildTicket(overrides: credentialsOverrides(client)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Buy / Long BTC'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      expect(capturedBody, isNotNull);
      final decoded = jsonDecode(capturedBody!) as Map<String, dynamic>;
      expect(decoded['category'], 'linear');
      expect(decoded['symbol'], 'BTCUSDT');
      expect(decoded['side'], 'Buy');
      expect(decoded['orderType'], 'Limit');
      expect(decoded['qty'], '1.050');
      expect(decoded['price'], isNotNull);
    });

    testWidgets('order success shows snackbar and invalidates orders', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTicket(
          overrides: credentialsOverrides(_successClient(orderId: 'ord-xyz')),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Buy / Long BTC'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      expect(find.text('Confirm'), findsNothing);
      expect(find.text('Order placed: ord-xyz'), findsOneWidget);
    });

    testWidgets('order error shows error message in dialog', (tester) async {
      await tester.pumpWidget(
        buildTicket(overrides: credentialsOverrides(_errorClient())),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Buy / Long BTC'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      expect(
        find.text('Bybit place order API error: 10001 insufficient balance'),
        findsOneWidget,
      );
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('missing credentials shows error in dialog', (tester) async {
      await tester.pumpWidget(
        buildTicket(
          overrides: [
            bybitHasCredentialsProvider.overrideWithValue(false),
            bybitAccountClientProvider.overrideWithValue(_successClient()),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Buy / Long BTC'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      expect(find.text('API keys required'), findsOneWidget);
      expect(find.text('Order placed: order-abc'), findsNothing);
    });
  });
}
