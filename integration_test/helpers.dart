import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';
import 'package:youtrade/core/result.dart';
import 'package:youtrade/data/datasources/remote/bybit/bybit_account_client.dart';
import 'package:youtrade/data/datasources/remote/bybit/bybit_rest_client.dart';
import 'package:youtrade/domain/auth/auth_failure.dart';
import 'package:youtrade/domain/auth/local_auth_service.dart';

import 'package:youtrade/domain/entities/candle.dart';
import 'package:youtrade/domain/entities/order_book.dart';
import 'package:youtrade/domain/entities/symbol.dart';
import 'package:youtrade/domain/entities/ticker.dart';
import 'package:youtrade/domain/entities/timeframe.dart';
import 'package:youtrade/domain/entities/trade.dart';
import 'package:youtrade/domain/repositories/market_data_repository.dart';
import 'package:youtrade/main.dart' as app;
import 'package:youtrade/presentation/auth/auth_guard_provider.dart';
import 'package:youtrade/presentation/providers/connectivity_provider.dart';
import 'package:youtrade/presentation/providers/market_screener_provider.dart';
import 'package:youtrade/presentation/providers/portfolio_data_provider.dart';
import 'package:youtrade/presentation/providers/repository_provider.dart';

import '../test/fakes/fake_pin_auth_service.dart';

class MockLocalAuthService extends Mock implements LocalAuthService {}

/// Deterministic mock Bybit screener client for integration tests. Returns
/// a small set of tickers (including BTCUSDT) so tests don't depend on the
/// live demo API.
BybitRestClient _mockScreenerClient() {
  return BybitRestClient(
    httpClient: MockClient((request) async {
      final category = request.url.queryParameters['category'] ?? '';
      return http.Response(
        jsonEncode({
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
        }),
        200,
      );
    }),
  );
}

/// Deterministic mock Bybit account client for integration tests. Returns
/// fixed wallet balance, positions, open orders, and order history so tests
/// don't depend on the live demo API or configured credentials.
BybitAccountClient _mockAccountClient() {
  return BybitAccountClient(
    httpClient: MockClient((request) async {
      final path = request.url.path;
      return http.Response(_mockAccountResponse(path), 200);
    }),
    apiKey: 'test-key',
    apiSecret: 'test-secret',
  );
}

String _mockAccountResponse(String path) {
  if (path.contains('/v5/account/wallet-balance')) {
    return jsonEncode({
      'retCode': 0,
      'retMsg': 'OK',
      'result': {
        'list': [
          {
            'accountType': 'UNIFIED',
            'totalEquity': '50000.00',
            'coin': [
              {'coin': 'USDT', 'walletBalance': '48000', 'equity': '48000'},
              {'coin': 'BTC', 'walletBalance': '0.5', 'equity': '2000'},
            ],
          },
        ],
      },
    });
  }
  if (path.contains('/v5/position/list')) {
    return jsonEncode({
      'retCode': 0,
      'retMsg': 'OK',
      'result': {
        'list': [
          {
            'symbol': 'BTCUSDT',
            'side': 'Buy',
            'size': '0.1',
            'unrealisedPnl': '150.0',
          },
        ],
      },
    });
  }
  if (path.contains('/v5/order/realtime')) {
    return jsonEncode({
      'retCode': 0,
      'retMsg': 'OK',
      'result': {
        'list': [
          {
            'orderId': 'ord-1',
            'symbol': 'BTCUSDT',
            'side': 'Buy',
            'orderType': 'Limit',
            'price': '64000',
            'qty': '0.1',
            'orderStatus': 'New',
            'createdTime': '1718952000000',
          },
          {
            'orderId': 'ord-2',
            'symbol': 'ETHUSDT',
            'side': 'Sell',
            'orderType': 'Limit',
            'price': '3100',
            'qty': '2',
            'orderStatus': 'New',
            'createdTime': '1718952000000',
          },
          {
            'orderId': 'ord-3',
            'symbol': 'SOLUSDT',
            'side': 'Buy',
            'orderType': 'Limit',
            'price': '140',
            'qty': '10',
            'orderStatus': 'New',
            'createdTime': '1718952000000',
          },
          {
            'orderId': 'ord-4',
            'symbol': 'XRPUSDT',
            'side': 'Sell',
            'orderType': 'Limit',
            'price': '0.6',
            'qty': '500',
            'orderStatus': 'New',
            'createdTime': '1718952000000',
          },
        ],
      },
    });
  }
  return jsonEncode({
    'retCode': 0,
    'retMsg': 'OK',
    'result': {
      'list': [
        {
          'orderId': 'hist-1',
          'symbol': 'BTCUSDT',
          'side': 'Buy',
          'orderType': 'Market',
          'price': '60000',
          'qty': '0.1',
          'orderStatus': 'Filled',
          'createdTime': '1718952000000',
        },
        {
          'orderId': 'hist-2',
          'symbol': 'ETHUSDT',
          'side': 'Sell',
          'orderType': 'Limit',
          'price': '3300',
          'qty': '2',
          'orderStatus': 'Cancelled',
          'createdTime': '1718952000000',
        },
      ],
    },
  });
}

/// Mock Bybit account client that returns an empty wallet (zero equity, no
/// coins, no positions). Used to test the portfolio's zero-balance state.
BybitAccountClient emptyWalletAccountClient() {
  return BybitAccountClient(
    httpClient: MockClient((request) async {
      final path = request.url.path;
      return http.Response(_emptyWalletResponse(path), 200);
    }),
    apiKey: 'test-key',
    apiSecret: 'test-secret',
  );
}

String _emptyWalletResponse(String path) {
  if (path.contains('/v5/account/wallet-balance')) {
    return jsonEncode({
      'retCode': 0,
      'retMsg': 'OK',
      'result': {
        'list': [
          {'accountType': 'UNIFIED', 'totalEquity': '0', 'coin': []},
        ],
      },
    });
  }
  return jsonEncode({
    'retCode': 0,
    'retMsg': 'OK',
    'result': {'list': []},
  });
}

/// Mock Bybit account client that throws on every request. Used to test the
/// portfolio's error/retry state.
BybitAccountClient errorAccountClient() {
  return BybitAccountClient(
    httpClient: MockClient((request) async {
      throw Exception('Network error');
    }),
    apiKey: 'test-key',
    apiSecret: 'test-secret',
  );
}

/// Mock Bybit account client that returns a wallet with three coins (USDT,
/// BTC, ETH). Used to test multi-coin portfolio rendering.
BybitAccountClient multiCoinAccountClient() {
  return BybitAccountClient(
    httpClient: MockClient((request) async {
      final path = request.url.path;
      return http.Response(_multiCoinResponse(path), 200);
    }),
    apiKey: 'test-key',
    apiSecret: 'test-secret',
  );
}

String _multiCoinResponse(String path) {
  if (path.contains('/v5/account/wallet-balance')) {
    return jsonEncode({
      'retCode': 0,
      'retMsg': 'OK',
      'result': {
        'list': [
          {
            'accountType': 'UNIFIED',
            'totalEquity': '50300.00',
            'coin': [
              {'coin': 'USDT', 'walletBalance': '48000', 'equity': '48000'},
              {'coin': 'BTC', 'walletBalance': '0.5', 'equity': '2000'},
              {'coin': 'ETH', 'walletBalance': '3.0', 'equity': '300'},
            ],
          },
        ],
      },
    });
  }
  return jsonEncode({
    'retCode': 0,
    'retMsg': 'OK',
    'result': {'list': []},
  });
}

/// Mock account client that returns empty open orders but some order history.
/// Used to test the orders screen's "No open orders" empty state.
BybitAccountClient emptyOpenOrdersAccountClient() {
  return BybitAccountClient(
    httpClient: MockClient((request) async {
      final path = request.url.path;
      return http.Response(_emptyOpenOrdersResponse(path), 200);
    }),
    apiKey: 'test-key',
    apiSecret: 'test-secret',
  );
}

String _emptyOpenOrdersResponse(String path) {
  if (path.contains('/v5/account/wallet-balance')) {
    return jsonEncode({
      'retCode': 0,
      'retMsg': 'OK',
      'result': {
        'list': [
          {
            'accountType': 'UNIFIED',
            'totalEquity': '50000.00',
            'coin': [
              {'coin': 'USDT', 'walletBalance': '48000', 'equity': '48000'},
            ],
          },
        ],
      },
    });
  }
  if (path.contains('/v5/position/list')) {
    return jsonEncode({
      'retCode': 0,
      'retMsg': 'OK',
      'result': {'list': []},
    });
  }
  if (path.contains('/v5/order/realtime')) {
    return jsonEncode({
      'retCode': 0,
      'retMsg': 'OK',
      'result': {'list': []},
    });
  }
  return jsonEncode({
    'retCode': 0,
    'retMsg': 'OK',
    'result': {
      'list': [
        {
          'orderId': 'hist-1',
          'symbol': 'BTCUSDT',
          'side': 'Buy',
          'orderType': 'Market',
          'price': '60000',
          'qty': '0.1',
          'orderStatus': 'Filled',
          'createdTime': '1718952000000',
        },
      ],
    },
  });
}

/// Mock account client that returns some open orders but empty order history.
/// Used to test the orders screen's "No order history" empty state.
BybitAccountClient emptyHistoryOrdersAccountClient() {
  return BybitAccountClient(
    httpClient: MockClient((request) async {
      final path = request.url.path;
      return http.Response(_emptyHistoryOrdersResponse(path), 200);
    }),
    apiKey: 'test-key',
    apiSecret: 'test-secret',
  );
}

String _emptyHistoryOrdersResponse(String path) {
  if (path.contains('/v5/account/wallet-balance')) {
    return jsonEncode({
      'retCode': 0,
      'retMsg': 'OK',
      'result': {
        'list': [
          {
            'accountType': 'UNIFIED',
            'totalEquity': '50000.00',
            'coin': [
              {'coin': 'USDT', 'walletBalance': '48000', 'equity': '48000'},
            ],
          },
        ],
      },
    });
  }
  if (path.contains('/v5/position/list')) {
    return jsonEncode({
      'retCode': 0,
      'retMsg': 'OK',
      'result': {'list': []},
    });
  }
  if (path.contains('/v5/order/realtime')) {
    return jsonEncode({
      'retCode': 0,
      'retMsg': 'OK',
      'result': {
        'list': [
          {
            'orderId': 'ord-1',
            'symbol': 'BTCUSDT',
            'side': 'Buy',
            'orderType': 'Limit',
            'price': '64000',
            'qty': '0.1',
            'orderStatus': 'New',
            'createdTime': '1718952000000',
          },
        ],
      },
    });
  }
  return jsonEncode({
    'retCode': 0,
    'retMsg': 'OK',
    'result': {'list': []},
  });
}

/// Mock account client that returns HTTP 429 (rate limited) on every request.
/// Used to test the app's rate-limit error handling.
BybitAccountClient rateLimitAccountClient() {
  return BybitAccountClient(
    httpClient: MockClient(
      (request) async =>
          http.Response('{"retCode":429,"retMsg":"Rate limit"}', 429),
    ),
    apiKey: 'test-key',
    apiSecret: 'test-secret',
  );
}

/// Mock account client that throws a TimeoutException on every request.
/// Used to test the app's timeout error handling.
BybitAccountClient timeoutAccountClient() {
  return BybitAccountClient(
    httpClient: MockClient(
      (request) async => throw TimeoutException('Request timed out'),
    ),
    apiKey: 'test-key',
    apiSecret: 'test-secret',
  );
}

/// Mock screener client that returns HTTP 429 on every request.
BybitRestClient rateLimitScreenerClient() {
  return BybitRestClient(
    httpClient: MockClient(
      (request) async =>
          http.Response('{"retCode":429,"retMsg":"Rate limit"}', 429),
    ),
  );
}

/// Mock screener client that throws a TimeoutException on every request.
BybitRestClient timeoutScreenerClient() {
  return BybitRestClient(
    httpClient: MockClient(
      (request) async => throw TimeoutException('Request timed out'),
    ),
  );
}

class FakeMarketDataRepository implements MarketDataRepository {
  DateTime get _now => DateTime.now().toUtc();

  @override
  Future<Result<Ticker>> getTicker(TradingSymbol symbol) async => Success(
    Ticker(
      symbol: symbol,
      lastPrice: 68421.35,
      bid: 68420.0,
      ask: 68422.0,
      change24h: 1234.56,
      change24hPercent: 0.018,
      volume: 1234567.89,
      timestamp: _now,
    ),
  );

  @override
  Future<Result<List<Candle>>> getCandles(
    TradingSymbol symbol,
    Timeframe timeframe, {
    int? limit,
  }) async {
    final count = limit ?? 20;
    final basePrice = 65000.0;
    final candles = <Candle>[];
    var price = basePrice;
    final now = _now;
    for (var i = count - 1; i >= 0; i--) {
      final open = price;
      final close = open * (1 + (i % 3 - 1) * 0.01);
      final high = open > close ? open * 1.01 : close * 1.01;
      final low = open < close ? open * 0.99 : close * 0.99;
      price = close;
      candles.add(
        Candle(
          open: open,
          high: high,
          low: low,
          close: close,
          volume: 100 + i * 10.0,
          timestamp: now.subtract(Duration(seconds: timeframe.seconds * i)),
        ),
      );
    }
    return Success(candles);
  }

  @override
  Future<Result<OrderBook>> getOrderBook(
    TradingSymbol symbol, {
    int? depth,
  }) async => Success(
    OrderBook(
      bids: [
        OrderBookLevel(price: 68420.0, amount: 1.5),
        OrderBookLevel(price: 68419.0, amount: 2.0),
      ],
      asks: [
        OrderBookLevel(price: 68422.0, amount: 1.2),
        OrderBookLevel(price: 68423.0, amount: 2.5),
      ],
      timestamp: _now,
    ),
  );

  @override
  Future<Result<List<Trade>>> getTrades(
    TradingSymbol symbol, {
    int? limit,
  }) async => Success([
    Trade(
      price: 68421.0,
      amount: 0.5,
      side: TradeSide.buy,
      timestamp: _now,
      tradeId: 't1',
    ),
    Trade(
      price: 68420.0,
      amount: 0.3,
      side: TradeSide.sell,
      timestamp: _now.subtract(const Duration(seconds: 1)),
      tradeId: 't2',
    ),
  ]);

  @override
  Stream<Result<Ticker>> watchTicker(TradingSymbol symbol) async* {
    yield await getTicker(symbol);
  }

  @override
  Stream<Result<OrderBook>> watchOrderBook(TradingSymbol symbol) async* {
    yield await getOrderBook(symbol);
  }

  @override
  Stream<Result<List<Trade>>> watchTrades(TradingSymbol symbol) async* {
    yield await getTrades(symbol);
  }
}

Future<void> authenticateWithPin(WidgetTester tester) async {
  expect(find.text('YouTrade is locked'), findsOneWidget);
  await tester.enterText(find.byType(TextField), '1234');
  await tester.tap(find.text('Unlock with PIN'));
  await tester.pumpAndSettle(const Duration(seconds: 5));
}

Future<void> enterPin(WidgetTester tester, String pin) async {
  await tester.enterText(find.byType(TextField), pin);
  await tester.tap(find.text('Unlock with PIN'));
  await tester.pumpAndSettle(const Duration(seconds: 5));
}

/// Enters a PIN and taps the submit button by type (works for both
/// "Unlock with PIN" and "Set PIN" button labels).
Future<void> submitPinForm(WidgetTester tester, String pin) async {
  await tester.enterText(find.byType(TextField), pin);
  await tester.tap(find.byType(ElevatedButton));
  await tester.pumpAndSettle(const Duration(seconds: 5));
}

/// Sets the PIN text directly on the controller, bypassing the TextField's
/// maxLength formatter. Used to test validation of pins that exceed 4 digits.
Future<void> enterPinBypassingFormatter(WidgetTester tester, String pin) async {
  final textField = tester.widget<TextField>(find.byType(TextField));
  textField.controller?.text = pin;
  await tester.tap(find.byType(ElevatedButton));
  await tester.pumpAndSettle(const Duration(seconds: 5));
}

Future<void> pumpLockedApp(
  WidgetTester tester, {
  bool online = true,
  String? initialPin = '1234',
}) async {
  final mockAuth = MockLocalAuthService();
  when(() => mockAuth.canCheckBiometrics()).thenAnswer((_) async => false);

  app.main(
    overrides: [
      localAuthServiceProvider.overrideWithValue(mockAuth),
      pinAuthServiceProvider.overrideWithValue(
        FakePinAuthService(initialPin: initialPin),
      ),
      marketDataRepositoryProvider.overrideWithValue(
        FakeMarketDataRepository(),
      ),
      connectivityProvider.overrideWith((ref) => Stream.value(online)),
      marketScreenerBybitClientProvider.overrideWithValue(
        _mockScreenerClient(),
      ),
      bybitAccountClientProvider.overrideWithValue(_mockAccountClient()),
      bybitHasCredentialsProvider.overrideWithValue(true),
    ],
  );

  await tester.pumpAndSettle(const Duration(seconds: 10));
}

Future<void> pumpAuthenticatedApp(
  WidgetTester tester, {
  bool online = true,
}) async {
  await pumpLockedApp(tester, online: online);
  await authenticateWithPin(tester);
}

/// Pumps the app with a custom [BybitAccountClient] and credentials flag,
/// then authenticates with the default PIN. Used for portfolio edge-case
/// tests that need to override the account data source.
Future<void> pumpAuthenticatedAppWithAccountClient(
  WidgetTester tester, {
  required BybitAccountClient accountClient,
  bool hasCredentials = true,
  bool online = true,
}) async {
  final mockAuth = MockLocalAuthService();
  when(() => mockAuth.canCheckBiometrics()).thenAnswer((_) async => false);

  app.main(
    overrides: [
      localAuthServiceProvider.overrideWithValue(mockAuth),
      pinAuthServiceProvider.overrideWithValue(
        FakePinAuthService(initialPin: '1234'),
      ),
      marketDataRepositoryProvider.overrideWithValue(
        FakeMarketDataRepository(),
      ),
      connectivityProvider.overrideWith((ref) => Stream.value(online)),
      marketScreenerBybitClientProvider.overrideWithValue(
        _mockScreenerClient(),
      ),
      bybitAccountClientProvider.overrideWithValue(accountClient),
      bybitHasCredentialsProvider.overrideWithValue(hasCredentials),
    ],
  );

  await tester.pumpAndSettle(const Duration(seconds: 10));
  await authenticateWithPin(tester);
  await tester.pumpAndSettle(const Duration(seconds: 5));
}

Future<void> pumpAuthenticatedAppWithMockStore(
  WidgetTester tester, {
  bool online = false,
}) async {
  final mockAuth = MockLocalAuthService();
  when(() => mockAuth.canCheckBiometrics()).thenAnswer((_) async => false);

  app.main(
    overrides: [
      localAuthServiceProvider.overrideWithValue(mockAuth),
      pinAuthServiceProvider.overrideWithValue(
        FakePinAuthService(initialPin: '1234'),
      ),
      connectivityProvider.overrideWith((ref) => Stream.value(online)),
      marketScreenerBybitClientProvider.overrideWithValue(
        _mockScreenerClient(),
      ),
      bybitAccountClientProvider.overrideWithValue(_mockAccountClient()),
      bybitHasCredentialsProvider.overrideWithValue(true),
    ],
  );

  await tester.pumpAndSettle(const Duration(seconds: 10));
  await authenticateWithPin(tester);
}

Future<void> pumpAppWithBiometricCancellation(WidgetTester tester) async {
  final mockAuth = MockLocalAuthService();
  when(() => mockAuth.canCheckBiometrics()).thenAnswer((_) async => true);
  when(
    () => mockAuth.authenticate(),
  ).thenAnswer((_) async => const Err<bool>(AuthCancelledFailure()));

  app.main(
    overrides: [
      localAuthServiceProvider.overrideWithValue(mockAuth),
      pinAuthServiceProvider.overrideWithValue(
        FakePinAuthService(initialPin: '1234'),
      ),
      marketDataRepositoryProvider.overrideWithValue(
        FakeMarketDataRepository(),
      ),
      marketScreenerBybitClientProvider.overrideWithValue(
        _mockScreenerClient(),
      ),
      bybitAccountClientProvider.overrideWithValue(_mockAccountClient()),
      bybitHasCredentialsProvider.overrideWithValue(true),
    ],
  );

  await tester.pumpAndSettle(const Duration(seconds: 10));
}

/// Pumps the app with a controllable [StreamController] for connectivity,
/// allowing tests to emit online/offline transitions after the app is running.
/// Returns the controller so callers can emit new connectivity values.
Future<StreamController<bool>> pumpAuthenticatedAppWithConnectivityController(
  WidgetTester tester, {
  bool initialOnline = true,
}) async {
  final controller = StreamController<bool>.broadcast();
  controller.add(initialOnline);

  final mockAuth = MockLocalAuthService();
  when(() => mockAuth.canCheckBiometrics()).thenAnswer((_) async => false);

  app.main(
    overrides: [
      localAuthServiceProvider.overrideWithValue(mockAuth),
      pinAuthServiceProvider.overrideWithValue(
        FakePinAuthService(initialPin: '1234'),
      ),
      marketDataRepositoryProvider.overrideWithValue(
        FakeMarketDataRepository(),
      ),
      connectivityProvider.overrideWith((ref) => controller.stream),
      marketScreenerBybitClientProvider.overrideWithValue(
        _mockScreenerClient(),
      ),
      bybitAccountClientProvider.overrideWithValue(_mockAccountClient()),
      bybitHasCredentialsProvider.overrideWithValue(true),
    ],
  );

  await tester.pumpAndSettle(const Duration(seconds: 10));
  await authenticateWithPin(tester);
  await tester.pumpAndSettle(const Duration(seconds: 3));
  return controller;
}

/// Pumps the app with a custom screener [BybitRestClient] for testing API
/// error states on the markets screen.
Future<void> pumpAuthenticatedAppWithScreenerClient(
  WidgetTester tester, {
  required BybitRestClient screenerClient,
  bool online = true,
}) async {
  final mockAuth = MockLocalAuthService();
  when(() => mockAuth.canCheckBiometrics()).thenAnswer((_) async => false);

  app.main(
    overrides: [
      localAuthServiceProvider.overrideWithValue(mockAuth),
      pinAuthServiceProvider.overrideWithValue(
        FakePinAuthService(initialPin: '1234'),
      ),
      marketDataRepositoryProvider.overrideWithValue(
        FakeMarketDataRepository(),
      ),
      connectivityProvider.overrideWith((ref) => Stream.value(online)),
      marketScreenerBybitClientProvider.overrideWithValue(screenerClient),
      bybitAccountClientProvider.overrideWithValue(_mockAccountClient()),
      bybitHasCredentialsProvider.overrideWithValue(true),
    ],
  );

  await tester.pumpAndSettle(const Duration(seconds: 10));
  await authenticateWithPin(tester);
}
