import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/candle.dart';
import '../../domain/entities/order_book.dart';
import '../../domain/entities/symbol.dart';
import '../../domain/entities/ticker.dart';
import '../../domain/entities/timeframe.dart';
import '../../domain/entities/trade.dart';
import '../../domain/usecases/market_data_use_cases.dart';
import 'repository_provider.dart';

final getTickerUseCaseProvider = Provider<GetTickerUseCase>((ref) {
  final repository = ref.watch(marketDataRepositoryProvider);
  return GetTickerUseCase(repository);
});

final getCandlesUseCaseProvider = Provider<GetCandlesUseCase>((ref) {
  final repository = ref.watch(marketDataRepositoryProvider);
  return GetCandlesUseCase(repository);
});

final watchOrderBookUseCaseProvider = Provider<WatchOrderBookUseCase>((ref) {
  final repository = ref.watch(marketDataRepositoryProvider);
  return WatchOrderBookUseCase(repository);
});

final getTradesUseCaseProvider = Provider<GetTradesUseCase>((ref) {
  final repository = ref.watch(marketDataRepositoryProvider);
  return GetTradesUseCase(repository);
});

final watchTickerUseCaseProvider = Provider<WatchTickerUseCase>((ref) {
  final repository = ref.watch(marketDataRepositoryProvider);
  return WatchTickerUseCase(repository);
});

final watchTradesUseCaseProvider = Provider<WatchTradesUseCase>((ref) {
  final repository = ref.watch(marketDataRepositoryProvider);
  return WatchTradesUseCase(repository);
});

final tickerStreamProvider = StreamProvider.family<Ticker, TradingSymbol>((
  ref,
  symbol,
) {
  final useCase = ref.watch(watchTickerUseCaseProvider);
  return useCase
      .call(symbol)
      .map(
        (result) => result.fold((failure) => throw failure, (value) => value),
      );
});

final candlesProvider =
    FutureProvider.family<List<Candle>, (TradingSymbol, Timeframe)>((
      ref,
      params,
    ) async {
      final (symbol, timeframe) = params;
      final useCase = ref.watch(getCandlesUseCaseProvider);
      final result = await useCase.call(symbol, timeframe);
      return result.fold((failure) => throw failure, (value) => value);
    });

final orderBookStreamProvider = StreamProvider.family<OrderBook, TradingSymbol>(
  (ref, symbol) {
    final useCase = ref.watch(watchOrderBookUseCaseProvider);
    return useCase
        .call(symbol)
        .map(
          (result) => result.fold((failure) => throw failure, (value) => value),
        );
  },
);

final tradesStreamProvider = StreamProvider.family<List<Trade>, TradingSymbol>((
  ref,
  symbol,
) {
  final useCase = ref.watch(watchTradesUseCaseProvider);
  return useCase
      .call(symbol)
      .map(
        (result) => result.fold((failure) => throw failure, (value) => value),
      );
});
