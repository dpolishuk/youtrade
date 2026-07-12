import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';
import 'package:youtrade/core/result.dart';
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

Future<void> pumpLockedApp(
  WidgetTester tester, {
  bool online = true,
  String initialPin = '1234',
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
    ],
  );

  await tester.pumpAndSettle(const Duration(seconds: 5));
}

Future<void> pumpAuthenticatedApp(
  WidgetTester tester, {
  bool online = true,
}) async {
  await pumpLockedApp(tester, online: online);
  await authenticateWithPin(tester);
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
    ],
  );

  await tester.pumpAndSettle(const Duration(seconds: 5));
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
    ],
  );

  await tester.pumpAndSettle(const Duration(seconds: 5));
}
