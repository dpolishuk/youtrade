import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:youtrade/core/result.dart';
import 'package:youtrade/domain/entities/candle.dart';
import 'package:youtrade/domain/entities/order_book.dart';
import 'package:youtrade/domain/entities/symbol.dart';
import 'package:youtrade/domain/entities/ticker.dart';
import 'package:youtrade/domain/entities/timeframe.dart';
import 'package:youtrade/domain/entities/trade.dart';
import 'package:youtrade/domain/repositories/market_data_repository.dart';
import 'package:youtrade/presentation/providers/repository_provider.dart';
import 'package:youtrade/presentation/theme/app_theme.dart';
import 'package:youtrade/presentation/theme/theme_mode.dart';
import 'package:youtrade/ui/screens/trading_terminal_screen.dart';
import 'package:youtrade/ui/widgets/trading_terminal/candlestick_chart.dart';
import 'package:youtrade/ui/widgets/trading_terminal/trade_ticket.dart';

final _timestamp = DateTime.utc(2026, 1, 1);

Ticker _ticker(TradingSymbol symbol) => Ticker(
  symbol: symbol,
  lastPrice: 100000,
  bid: 99900,
  ask: 100100,
  change24h: 1200,
  change24hPercent: 0.0123,
  volume: 50000,
  timestamp: _timestamp,
);

List<Candle> _candles() => [
  for (var i = 30; i >= 0; i--)
    Candle(
      open: 99000 + i * 100,
      high: 100500 + i * 100,
      low: 98500 + i * 100,
      close: 100000 + i * 50,
      volume: 1000 + i * 10,
      timestamp: _timestamp.subtract(Duration(hours: i)),
    ),
];

OrderBook _orderBook() => OrderBook(
  bids: const [
    OrderBookLevel(price: 99900, amount: 1.5),
    OrderBookLevel(price: 99800, amount: 2.0),
    OrderBookLevel(price: 99700, amount: 0.8),
  ],
  asks: const [
    OrderBookLevel(price: 100100, amount: 1.2),
    OrderBookLevel(price: 100200, amount: 3.0),
    OrderBookLevel(price: 100300, amount: 0.5),
  ],
  timestamp: _timestamp,
);

List<Trade> _trades() => [
  Trade(
    price: 100000,
    amount: 0.5,
    side: TradeSide.buy,
    timestamp: _timestamp,
    tradeId: 't1',
  ),
  Trade(
    price: 99950,
    amount: 0.25,
    side: TradeSide.sell,
    timestamp: _timestamp.subtract(const Duration(seconds: 1)),
    tradeId: 't2',
  ),
];

final class _FakeRepository implements MarketDataRepository {
  @override
  Future<Result<Ticker>> getTicker(TradingSymbol symbol) async =>
      Success(_ticker(symbol));

  @override
  Future<Result<List<Candle>>> getCandles(
    TradingSymbol symbol,
    Timeframe timeframe, {
    int? limit,
  }) async => Success(_candles());

  @override
  Future<Result<OrderBook>> getOrderBook(
    TradingSymbol symbol, {
    int? depth,
  }) async => Success(_orderBook());

  @override
  Future<Result<List<Trade>>> getTrades(
    TradingSymbol symbol, {
    int? limit,
  }) async => Success(_trades());

  @override
  Stream<Result<Ticker>> watchTicker(TradingSymbol symbol) =>
      Stream.value(Success(_ticker(symbol)));

  @override
  Stream<Result<OrderBook>> watchOrderBook(TradingSymbol symbol) =>
      Stream.value(Success(_orderBook()));

  @override
  Stream<Result<List<Trade>>> watchTrades(TradingSymbol symbol) =>
      Stream.value(Success(_trades()));
}

void main() {
  Widget buildApp() {
    return ProviderScope(
      overrides: [
        marketDataRepositoryProvider.overrideWithValue(_FakeRepository()),
      ],
      child: MaterialApp(
        theme: AppTheme.dark(AppVisualDirection.flux),
        home: const TradingTerminalScreen(),
      ),
    );
  }

  group('TradingTerminalScreen', () {
    testWidgets('renders without overflow and shows chart, ticket and tabs', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(CandlestickChart), findsOneWidget);
      expect(find.byType(TradeTicket), findsOneWidget);
      expect(find.text('Trade'), findsOneWidget);
      expect(find.text('Book'), findsOneWidget);
      expect(find.text('Info'), findsOneWidget);
      expect(find.text('Signals'), findsOneWidget);
      expect(find.textContaining('BTC'), findsWidgets);
    });

    testWidgets('switches to Book tab and shows order book', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Book'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Price'), findsOneWidget);
      expect(find.textContaining('spread'), findsOneWidget);
    });
  });
}
