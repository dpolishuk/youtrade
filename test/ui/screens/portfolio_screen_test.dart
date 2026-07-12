import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:youtrade/data/datasources/remote/bybit/bybit_account_client.dart';
import 'package:youtrade/presentation/providers/portfolio_data_provider.dart';
import 'package:youtrade/presentation/theme/theme_provider.dart';
import 'package:youtrade/ui/screens/portfolio_screen.dart';
import 'package:youtrade/ui/widgets/portfolio/allocation_bar.dart';
import 'package:youtrade/ui/widgets/portfolio/exchange_card.dart';
import 'package:youtrade/ui/widgets/portfolio/position_tile.dart';

void main() {
  BybitAccountClient mockClient({
    required double totalEquity,
    List<Map<String, dynamic>> coins = const [],
    List<Map<String, dynamic>> positions = const [],
  }) {
    return BybitAccountClient(
      apiKey: 'test-key',
      apiSecret: 'test-secret',
      httpClient: MockClient((request) async {
        final path = request.url.path;
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
        return http.Response('{"retCode":1,"retMsg":"unknown"}', 200);
      }),
    );
  }

  GoRouter buildRouter() {
    return GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const PortfolioScreen(),
        ),
        GoRoute(
          path: '/orders',
          builder: (context, state) => const Scaffold(body: Text('Orders')),
        ),
        GoRoute(
          path: '/markets/exchange/:id',
          builder: (context, state) {
            return Scaffold(
              body: Text('Exchange ${state.pathParameters['id']}'),
            );
          },
        ),
        GoRoute(
          path: '/trading',
          builder: (context, state) {
            return Scaffold(
              body: Text('Trading ${state.uri.queryParameters['symbol']}'),
            );
          },
        ),
      ],
    );
  }

  Widget buildScreen({List<Override> overrides = const []}) {
    return ProviderScope(
      overrides: overrides,
      child: Consumer(
        builder: (context, ref, child) {
          final theme = ref.watch(appThemeProvider);
          return MaterialApp.router(theme: theme, routerConfig: buildRouter());
        },
      ),
    );
  }

  group('PortfolioScreen', () {
    final defaultCoins = [
      {'coin': 'USDT', 'walletBalance': '8000.0', 'equity': '8000.0'},
      {'coin': 'BTC', 'walletBalance': '0.03', 'equity': '2000.0'},
    ];
    final defaultPositions = [
      {
        'symbol': 'BTCUSDT',
        'side': 'Buy',
        'size': '0.5',
        'unrealisedPnl': '1200.0',
      },
    ];

    testWidgets('shows Connect API key when credentials missing', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildScreen(
          overrides: [bybitHasCredentialsProvider.overrideWithValue(false)],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Connect API Key'), findsOneWidget);
      expect(find.byIcon(Icons.key_off), findsOneWidget);
    });

    testWidgets('renders total equity and allocation with real data', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      final client = mockClient(
        totalEquity: 10000,
        coins: defaultCoins,
        positions: defaultPositions,
      );
      await tester.pumpWidget(
        buildScreen(
          overrides: [
            bybitHasCredentialsProvider.overrideWithValue(true),
            bybitAccountClientProvider.overrideWithValue(client),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining(r'$10,000.00'), findsOneWidget);
      expect(find.byType(AllocationBar), findsOneWidget);
      expect(find.byType(ExchangeCard), findsNWidgets(2));

      expect(find.text('USDT'), findsWidgets);
      expect(find.text('BTC'), findsWidgets);
      expect(find.text(r'$8,000'), findsOneWidget);
      expect(find.text(r'$2,000'), findsOneWidget);

      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('shows open positions from real data', (tester) async {
      await tester.pumpWidget(
        buildScreen(
          overrides: [
            bybitHasCredentialsProvider.overrideWithValue(true),
            bybitAccountClientProvider.overrideWithValue(
              mockClient(
                totalEquity: 50000,
                coins: [
                  {'coin': 'USDT', 'walletBalance': '50000', 'equity': '50000'},
                ],
                positions: [
                  {
                    'symbol': 'BTCUSDT',
                    'side': 'Buy',
                    'size': '0.5',
                    'unrealisedPnl': '1200.0',
                  },
                  {
                    'symbol': 'ETHUSDT',
                    'side': 'Sell',
                    'size': '3.0',
                    'unrealisedPnl': '-500.0',
                  },
                ],
              ),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PositionTile), findsNWidgets(2));
      expect(find.text('BTCUSDT'), findsOneWidget);
      expect(find.text('ETHUSDT'), findsOneWidget);
      expect(find.text('LONG'), findsOneWidget);
      expect(find.text('SHORT'), findsOneWidget);
    });

    testWidgets('shows no-open-positions message when positions empty', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildScreen(
          overrides: [
            bybitHasCredentialsProvider.overrideWithValue(true),
            bybitAccountClientProvider.overrideWithValue(
              mockClient(
                totalEquity: 5000,
                coins: [
                  {'coin': 'USDT', 'walletBalance': '5000', 'equity': '5000'},
                ],
                positions: const [],
              ),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No open positions'), findsOneWidget);
      expect(find.byType(PositionTile), findsNothing);
    });

    testWidgets('shows zero balance gracefully when wallet is empty', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildScreen(
          overrides: [
            bybitHasCredentialsProvider.overrideWithValue(true),
            bybitAccountClientProvider.overrideWithValue(
              mockClient(totalEquity: 0, coins: const []),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining('AGGREGATED NET WORTH · 0 VENUES'),
        findsOneWidget,
      );
      expect(find.byType(ExchangeCard), findsNothing);
    });

    testWidgets('shows error state with retry when API fails', (tester) async {
      final errorClient = BybitAccountClient(
        apiKey: 'test-key',
        apiSecret: 'test-secret',
        httpClient: MockClient((request) async {
          return http.Response(
            jsonEncode({'retCode': 10001, 'retMsg': 'error', 'result': {}}),
            200,
          );
        }),
      );
      await tester.pumpWidget(
        buildScreen(
          overrides: [
            bybitHasCredentialsProvider.overrideWithValue(true),
            bybitAccountClientProvider.overrideWithValue(errorClient),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Failed to load portfolio'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('navigates to exchange detail when exchange card tapped', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(
        buildScreen(
          overrides: [
            bybitHasCredentialsProvider.overrideWithValue(true),
            bybitAccountClientProvider.overrideWithValue(
              mockClient(totalEquity: 10000, coins: defaultCoins),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('USDT').first);
      await tester.pumpAndSettle();

      expect(find.text('Exchange bybit'), findsOneWidget);
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('navigates to trading terminal when position tile tapped', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(
        buildScreen(
          overrides: [
            bybitHasCredentialsProvider.overrideWithValue(true),
            bybitAccountClientProvider.overrideWithValue(
              mockClient(
                totalEquity: 50000,
                coins: [
                  {'coin': 'USDT', 'walletBalance': '50000', 'equity': '50000'},
                ],
                positions: defaultPositions,
              ),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('BTCUSDT'));
      await tester.tap(find.text('BTCUSDT'));
      await tester.pumpAndSettle();

      expect(find.text('Trading BTCUSDT'), findsOneWidget);
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('renders without overflow in landscape orientation', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(844, 390));
      await tester.pumpWidget(
        buildScreen(
          overrides: [
            bybitHasCredentialsProvider.overrideWithValue(true),
            bybitAccountClientProvider.overrideWithValue(
              mockClient(totalEquity: 10000, coins: defaultCoins),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PortfolioScreen), findsOneWidget);
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('renders without overflow at 2x text scale', (tester) async {
      tester.binding.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(
        () => tester.binding.platformDispatcher.textScaleFactorTestValue = 1.0,
      );

      await tester.pumpWidget(
        buildScreen(
          overrides: [
            bybitHasCredentialsProvider.overrideWithValue(true),
            bybitAccountClientProvider.overrideWithValue(
              mockClient(totalEquity: 10000, coins: defaultCoins),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PortfolioScreen), findsOneWidget);
    });
  });
}
