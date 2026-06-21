import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:youtrade/core/result.dart';
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
import 'package:youtrade/presentation/providers/repository_provider.dart';

import '../test/fakes/fake_pin_auth_service.dart';

class MockLocalAuthService extends Mock implements LocalAuthService {}

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
    return Success(candles.reversed.toList());
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
    ],
  );

  await tester.pumpAndSettle(const Duration(seconds: 5));
}
