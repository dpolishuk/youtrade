import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:youtrade/data/datasources/remote/bybit/bybit_rest_client.dart';
import 'package:youtrade/presentation/providers/market_screener_provider.dart';
import 'package:youtrade/presentation/theme/app_theme.dart';
import 'package:youtrade/presentation/theme/theme_mode.dart';
import 'package:youtrade/ui/screens/markets_screen.dart';
import 'package:youtrade/ui/widgets/markets/market_list_tile.dart';

BybitRestClient _mockScreenerClient({
  String Function(String category)? responseBody,
  int statusCode = 200,
}) {
  return BybitRestClient(
    httpClient: MockClient((request) async {
      final category = request.url.queryParameters['category'] ?? '';
      if (responseBody != null) {
        return http.Response(responseBody(category), statusCode);
      }
      return http.Response(_defaultBody(category), statusCode);
    }),
  );
}

String _defaultBody(String category) {
  return jsonEncode({
    'retCode': 0,
    'retMsg': 'OK',
    'result': {
      'category': category,
      'list': category == 'linear'
          ? [
              {
                'symbol': 'BTCUSDT',
                'lastPrice': '65000.0',
                'price24hPcnt': '0.0523',
                'volume24h': '1000000.0',
              },
              {
                'symbol': 'ETHUSDT',
                'lastPrice': '3200.0',
                'price24hPcnt': '-0.0234',
                'volume24h': '500000.0',
              },
            ]
          : [
              {
                'symbol': 'SOLUSDT',
                'lastPrice': '150.0',
                'price24hPcnt': '0.0312',
                'volume24h': '200000.0',
              },
            ],
    },
  });
}

Widget buildApp({List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      theme: AppTheme.dark(AppVisualDirection.carbon),
      home: const MarketsScreen(),
    ),
  );
}

void main() {
  group('MarketsScreen', () {
    testWidgets('shows loading indicator then market rows', (tester) async {
      await tester.pumpWidget(
        buildApp(
          overrides: [
            marketScreenerBybitClientProvider.overrideWithValue(
              _mockScreenerClient(),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MarketsScreen), findsOneWidget);
      expect(
        find.byKey(const ValueKey('markets_search_field')),
        findsOneWidget,
      );
      expect(find.byType(MarketListTile), findsWidgets);
      expect(find.text('BTC'), findsOneWidget);
      expect(find.text('ETH'), findsOneWidget);
      expect(find.text('SOL'), findsOneWidget);
    });

    testWidgets('shows filter chips', (tester) async {
      await tester.pumpWidget(
        buildApp(
          overrides: [
            marketScreenerBybitClientProvider.overrideWithValue(
              _mockScreenerClient(),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('All'), findsOneWidget);
      expect(find.text('Crypto'), findsOneWidget);
      expect(find.text('Stocks'), findsOneWidget);
      expect(find.text('Futures'), findsOneWidget);
      expect(find.text('Options'), findsOneWidget);
    });

    testWidgets('shows header row', (tester) async {
      await tester.pumpWidget(
        buildApp(
          overrides: [
            marketScreenerBybitClientProvider.overrideWithValue(
              _mockScreenerClient(),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('SYMBOL'), findsOneWidget);
      expect(find.text('LAST · 24H'), findsOneWidget);
    });

    testWidgets('renders real price and 24h change from API data', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildApp(
          overrides: [
            marketScreenerBybitClientProvider.overrideWithValue(
              _mockScreenerClient(),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('65,000.0'), findsOneWidget);
      expect(find.text('+5.23%'), findsOneWidget);
    });

    testWidgets('filters market list by search query', (tester) async {
      await tester.pumpWidget(
        buildApp(
          overrides: [
            marketScreenerBybitClientProvider.overrideWithValue(
              _mockScreenerClient(),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('BTC'), findsOneWidget);
      expect(find.text('ETH'), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('markets_search_field')),
        'btc',
      );
      await tester.pumpAndSettle();

      expect(find.text('BTC'), findsOneWidget);
      expect(find.text('ETH'), findsNothing);
    });

    testWidgets('filters market list by chip selection', (tester) async {
      await tester.pumpWidget(
        buildApp(
          overrides: [
            marketScreenerBybitClientProvider.overrideWithValue(
              _mockScreenerClient(),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MarketListTile), findsWidgets);

      await tester.tap(find.text('Stocks'));
      await tester.pumpAndSettle();

      expect(find.text('No markets found'), findsOneWidget);
      expect(find.byType(MarketListTile), findsNothing);

      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();
      expect(find.byType(MarketListTile), findsWidgets);
    });

    testWidgets('empty state when no markets match search', (tester) async {
      await tester.pumpWidget(
        buildApp(
          overrides: [
            marketScreenerBybitClientProvider.overrideWithValue(
              _mockScreenerClient(),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('markets_search_field')),
        'zzzzzz',
      );
      await tester.pumpAndSettle();

      expect(find.text('No markets found'), findsOneWidget);
      expect(find.byType(MarketListTile), findsNothing);
    });

    testWidgets('shows error state with retry when fetch fails', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildApp(
          overrides: [
            marketScreenerBybitClientProvider.overrideWithValue(
              _mockScreenerClient(
                responseBody: (_) =>
                    '{"retCode":10001,"retMsg":"error","result":{}}',
              ),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Failed to load markets'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.byType(MarketListTile), findsNothing);
    });

    testWidgets('shows loading indicator before data arrives', (tester) async {
      final slowClient = BybitRestClient(
        httpClient: MockClient((request) async {
          await Future.delayed(const Duration(milliseconds: 500));
          final category = request.url.queryParameters['category'] ?? '';
          return http.Response(_defaultBody(category), 200);
        }),
      );

      await tester.pumpWidget(
        buildApp(
          overrides: [
            marketScreenerBybitClientProvider.overrideWithValue(slowClient),
          ],
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.byType(MarketListTile), findsWidgets);
    });

    testWidgets('does not crash on unicode or special chars in search', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildApp(
          overrides: [
            marketScreenerBybitClientProvider.overrideWithValue(
              _mockScreenerClient(),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('markets_search_field')),
        '🚀',
      );
      await tester.pumpAndSettle();

      expect(find.text('No markets found'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
