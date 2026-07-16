import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:youtrade/data/datasources/remote/bybit/bybit_account_client.dart';
import 'package:youtrade/presentation/providers/portfolio_data_provider.dart';
import 'package:youtrade/presentation/theme/app_theme.dart';
import 'package:youtrade/presentation/theme/theme_mode.dart';
import 'package:youtrade/ui/screens/orders_history_screen.dart';
import 'package:youtrade/ui/widgets/orders/history_order_tile.dart';
import 'package:youtrade/ui/widgets/orders/order_list_tile.dart';
import 'package:youtrade/ui/widgets/orders/position_list_tile.dart';

void main() {
  BybitAccountClient mockClient({
    List<Map<String, dynamic>> openOrders = const [],
    List<Map<String, dynamic>> historyOrders = const [],
    List<Map<String, dynamic>> positions = const [],
    double totalEquity = 50000.0,
    List<Map<String, dynamic>> coins = const [
      {'coin': 'USDT', 'walletBalance': '50000', 'equity': '50000'},
    ],
    bool cancelSucceeds = true,
    void Function(String body)? onCancelRequest,
  }) {
    return BybitAccountClient(
      apiKey: 'test-key',
      apiSecret: 'test-secret',
      httpClient: MockClient((request) async {
        final path = request.url.path;
        if (path.contains('/v5/order/cancel')) {
          if (onCancelRequest != null) onCancelRequest(request.body);
          if (!cancelSucceeds) {
            return http.Response(
              jsonEncode({
                'retCode': 10001,
                'retMsg': 'order not found',
                'result': {},
              }),
              200,
            );
          }
          return http.Response(
            jsonEncode({
              'retCode': 0,
              'retMsg': 'OK',
              'result': {'orderId': 'cancelled'},
            }),
            200,
          );
        }
        if (path.contains('/v5/order/realtime')) {
          return http.Response(
            jsonEncode({
              'retCode': 0,
              'retMsg': 'OK',
              'result': {'category': 'linear', 'list': openOrders},
            }),
            200,
          );
        }
        if (path.contains('/v5/order/history')) {
          return http.Response(
            jsonEncode({
              'retCode': 0,
              'retMsg': 'OK',
              'result': {'category': 'linear', 'list': historyOrders},
            }),
            200,
          );
        }
        if (path.contains('/v5/position/list')) {
          return http.Response(
            jsonEncode({
              'retCode': 0,
              'retMsg': 'OK',
              'result': {'category': 'linear', 'list': positions},
            }),
            200,
          );
        }
        if (path.contains('/v5/account/wallet-balance')) {
          return http.Response(
            jsonEncode({
              'retCode': 0,
              'retMsg': 'OK',
              'result': {
                'list': [
                  {
                    'accountType': 'UNIFIED',
                    'totalEquity': totalEquity.toString(),
                    'coin': coins,
                  },
                ],
              },
            }),
            200,
          );
        }
        return http.Response('{"retCode":1,"retMsg":"unknown"}', 200);
      }),
    );
  }

  final defaultOpenOrders = [
    {
      'orderId': 'open-1',
      'symbol': 'BTCUSDT',
      'side': 'Buy',
      'orderType': 'Limit',
      'price': '58400.0',
      'qty': '0.5',
      'orderStatus': 'New',
      'createdTime': '1705309920000',
    },
    {
      'orderId': 'open-2',
      'symbol': 'ETHUSDT',
      'side': 'Sell',
      'orderType': 'Limit',
      'price': '3050.0',
      'qty': '8.0',
      'orderStatus': 'New',
    },
  ];

  final defaultHistoryOrders = [
    {
      'orderId': 'hist-1',
      'symbol': 'BTCUSDT',
      'side': 'Buy',
      'orderType': 'Market',
      'price': '56820.0',
      'qty': '1.34',
      'orderStatus': 'Filled',
      'createdTime': '1705309920000',
    },
    {
      'orderId': 'hist-2',
      'symbol': 'ETHUSDT',
      'side': 'Sell',
      'orderType': 'Limit',
      'price': '2910.0',
      'qty': '14.5',
      'orderStatus': 'Cancelled',
      'createdTime': '1705306000000',
    },
  ];

  final defaultPositions = [
    {
      'symbol': 'BTCUSDT',
      'side': 'Buy',
      'size': '0.5',
      'unrealisedPnl': '1200.0',
    },
  ];

  Future<void> pumpScreen(
    WidgetTester tester, {
    List<Override> overrides = const [],
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: MaterialApp(
          theme: AppTheme.dark(AppVisualDirection.flux),
          home: const OrdersHistoryScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  List<Override> credentialsOverrides(BybitAccountClient client) => [
    bybitHasCredentialsProvider.overrideWithValue(true),
    bybitAccountClientProvider.overrideWithValue(client),
  ];

  group('OrdersHistoryScreen', () {
    testWidgets('renders title "Orders" with mockup typography', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        overrides: credentialsOverrides(
          mockClient(openOrders: defaultOpenOrders),
        ),
      );

      final title = tester.widget<Text>(find.text('Orders'));
      expect(title.style?.fontFamily, 'Space Grotesk');
      expect(title.style?.fontSize, 18);
      expect(title.style?.fontWeight, FontWeight.w600);
      expect(title.style?.letterSpacing, closeTo(-0.02 * 18, 0.01));
      expect(title.style?.color, const Color(0xFFF2F5FA));
    });

    testWidgets('renders Open / History / Positions tabs', (tester) async {
      await pumpScreen(
        tester,
        overrides: credentialsOverrides(
          mockClient(openOrders: defaultOpenOrders),
        ),
      );

      expect(find.text('Open'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);
      expect(find.text('Positions'), findsOneWidget);
    });

    testWidgets('active tab uses fg and accent underline', (tester) async {
      await pumpScreen(
        tester,
        overrides: credentialsOverrides(
          mockClient(openOrders: defaultOpenOrders),
        ),
      );

      final activeContainer = tester.widget<Container>(
        find
            .ancestor(of: find.text('Open'), matching: find.byType(Container))
            .first,
      );
      final decoration = activeContainer.decoration! as BoxDecoration;
      final border = decoration.border! as Border;
      expect(border.bottom.color, const Color(0xFF00E6D2));
      expect(border.bottom.width, 2);
    });

    testWidgets('Open tab shows real open orders from Bybit API', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        overrides: credentialsOverrides(
          mockClient(openOrders: defaultOpenOrders),
        ),
      );

      expect(find.byType(OrderListTile), findsNWidgets(2));
      expect(find.text('BTCUSDT'), findsWidgets);
      expect(find.text('ETHUSDT'), findsWidgets);
      expect(find.text('Cancel'), findsNWidgets(2));
      expect(find.textContaining('58,400.00'), findsOneWidget);
      expect(find.textContaining('3,050.00'), findsOneWidget);
    });

    testWidgets('open order card shows side badge and type', (tester) async {
      await pumpScreen(
        tester,
        overrides: credentialsOverrides(
          mockClient(openOrders: defaultOpenOrders),
        ),
      );

      final tile = tester.widget<OrderListTile>(
        find.byType(OrderListTile).first,
      );
      expect(tile.order.symbol, 'BTCUSDT');
      expect(tile.order.side, 'BUY');
      expect(tile.order.type, 'Limit');
      expect(tile.order.venue, 'Bybit');

      final symbol = tester.widget<Text>(find.text('BTCUSDT').first);
      expect(symbol.style?.fontSize, 13);
      expect(symbol.style?.fontWeight, FontWeight.w600);
    });

    testWidgets('cancel shows confirmation dialog', (tester) async {
      await pumpScreen(
        tester,
        overrides: credentialsOverrides(
          mockClient(openOrders: defaultOpenOrders),
        ),
      );

      await tester.tap(find.text('Cancel').first);
      await tester.pumpAndSettle();

      expect(find.text('Cancel this order?'), findsOneWidget);
      expect(find.text('Cancel Order'), findsOneWidget);
      expect(find.text('Keep Order'), findsOneWidget);
      expect(find.textContaining('BTCUSDT'), findsWidgets);
    });

    testWidgets('cancel confirm calls cancelOrder with correct parameters', (
      tester,
    ) async {
      String? capturedBody;
      await pumpScreen(
        tester,
        overrides: credentialsOverrides(
          mockClient(
            openOrders: defaultOpenOrders,
            onCancelRequest: (body) => capturedBody = body,
          ),
        ),
      );

      await tester.tap(find.text('Cancel').first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel Order'));
      await tester.pumpAndSettle();

      expect(capturedBody, isNotNull);
      final decoded = jsonDecode(capturedBody!) as Map<String, dynamic>;
      expect(decoded['category'], 'linear');
      expect(decoded['symbol'], 'BTCUSDT');
      expect(decoded['orderId'], 'open-1');
    });

    testWidgets('cancel success removes order and shows snackbar', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        overrides: credentialsOverrides(
          mockClient(openOrders: defaultOpenOrders),
        ),
      );

      expect(find.byType(OrderListTile), findsNWidgets(2));

      await tester.tap(find.text('Cancel').first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel Order'));
      await tester.pumpAndSettle();

      expect(find.byType(OrderListTile), findsNWidgets(1));
      expect(find.text('Order cancelled'), findsOneWidget);
    });

    testWidgets('cancel error keeps order and shows error message', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        overrides: credentialsOverrides(
          mockClient(openOrders: defaultOpenOrders, cancelSucceeds: false),
        ),
      );

      expect(find.byType(OrderListTile), findsNWidgets(2));

      await tester.tap(find.text('Cancel').first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel Order'));
      await tester.pumpAndSettle();

      expect(find.byType(OrderListTile), findsNWidgets(2));
      expect(find.textContaining('order not found'), findsOneWidget);
      expect(find.text('Cancel Order'), findsOneWidget);
    });

    testWidgets('History tab shows real history orders from Bybit API', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        overrides: credentialsOverrides(
          mockClient(
            openOrders: defaultOpenOrders,
            historyOrders: defaultHistoryOrders,
          ),
        ),
      );

      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();

      expect(find.byType(HistoryOrderTile), findsNWidgets(2));
      expect(find.textContaining('Filled'), findsWidgets);
      expect(find.textContaining('Cancelled'), findsWidgets);
      expect(find.textContaining('09:12'), findsOneWidget);
    });

    testWidgets('Positions tab shows real positions from portfolio provider', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        overrides: credentialsOverrides(
          mockClient(
            openOrders: defaultOpenOrders,
            positions: defaultPositions,
          ),
        ),
      );

      await tester.tap(find.text('Positions'));
      await tester.pumpAndSettle();

      expect(find.byType(PositionListTile), findsNWidgets(1));
      expect(find.text('BTCUSDT'), findsWidgets);
      expect(find.text('LONG'), findsWidgets);
    });

    testWidgets('empty Positions shows empty state', (tester) async {
      await pumpScreen(
        tester,
        overrides: credentialsOverrides(
          mockClient(openOrders: defaultOpenOrders, positions: const []),
        ),
      );

      await tester.tap(find.text('Positions'));
      await tester.pumpAndSettle();

      expect(find.byType(PositionListTile), findsNothing);
      expect(find.text('No open positions'), findsOneWidget);
    });

    testWidgets('shows Connect API Key when credentials missing', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        overrides: [bybitHasCredentialsProvider.overrideWithValue(false)],
      );

      expect(find.text('Connect API Key'), findsOneWidget);
      expect(find.byIcon(Icons.key_off), findsOneWidget);
    });

    testWidgets('shows error state with retry when API fails', (tester) async {
      final errorClient = BybitAccountClient(
        apiKey: 'test-key',
        apiSecret: 'test-secret',
        httpClient: MockClient((request) async {
          return http.Response(
            jsonEncode({'retCode': 10001, 'retMsg': 'invalid'}),
            200,
          );
        }),
      );

      await pumpScreen(tester, overrides: credentialsOverrides(errorClient));

      expect(find.text('Failed to load orders'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('empty open orders shows empty state', (tester) async {
      await pumpScreen(
        tester,
        overrides: credentialsOverrides(mockClient(openOrders: const [])),
      );

      expect(find.text('No open orders'), findsOneWidget);
      expect(find.byType(OrderListTile), findsNothing);
    });

    testWidgets('empty history shows empty state', (tester) async {
      await pumpScreen(
        tester,
        overrides: credentialsOverrides(
          mockClient(openOrders: defaultOpenOrders, historyOrders: const []),
        ),
      );

      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();

      expect(find.text('No order history'), findsOneWidget);
      expect(find.byType(HistoryOrderTile), findsNothing);
    });

    testWidgets('screen does not overflow on iPhone 17 frame', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await pumpScreen(
        tester,
        overrides: credentialsOverrides(
          mockClient(
            openOrders: defaultOpenOrders,
            historyOrders: defaultHistoryOrders,
            positions: defaultPositions,
          ),
        ),
      );

      expect(find.byType(OrdersHistoryScreen), findsOneWidget);
      await tester.binding.setSurfaceSize(null);
    });
  });
}
