import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/candle.dart';
import '../../domain/entities/order_book.dart';
import '../../domain/entities/symbol.dart';
import '../../domain/entities/ticker.dart';
import '../../domain/entities/timeframe.dart';
import '../../domain/entities/trade.dart';
import 'repository_provider.dart';

final tickerStreamProvider = StreamProvider.family<Ticker, TradingSymbol>((
  ref,
  symbol,
) {
  final repository = ref.watch(marketDataRepositoryProvider);
  return repository
      .watchTicker(symbol)
      .map(
        (result) => result.fold((failure) => throw failure, (value) => value),
      );
});

final candlesProvider = FutureProvider.family<List<Candle>, TradingSymbol>((
  ref,
  symbol,
) async {
  final repository = ref.watch(marketDataRepositoryProvider);
  const timeframe = Timeframe.h1;
  final result = await repository.getCandles(symbol, timeframe);
  return result.fold((failure) => throw failure, (value) => value);
});

final orderBookStreamProvider = StreamProvider.family<OrderBook, TradingSymbol>(
  (ref, symbol) {
    final repository = ref.watch(marketDataRepositoryProvider);
    return repository
        .watchOrderBook(symbol)
        .map(
          (result) => result.fold((failure) => throw failure, (value) => value),
        );
  },
);

final tradesStreamProvider = StreamProvider.family<List<Trade>, TradingSymbol>((
  ref,
  symbol,
) {
  final repository = ref.watch(marketDataRepositoryProvider);
  return repository
      .watchTrades(symbol)
      .map(
        (result) => result.fold((failure) => throw failure, (value) => value),
      );
});
