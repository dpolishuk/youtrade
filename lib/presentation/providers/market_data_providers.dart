import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/candle.dart';
import '../../domain/entities/order_book.dart';
import '../../domain/entities/symbol.dart';
import '../../domain/entities/ticker.dart';
import '../../domain/entities/timeframe.dart';
import '../../domain/entities/trade.dart';
import '../../domain/repositories/market_data_repository.dart';
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

final getOrderBookUseCaseProvider = Provider<MarketDataRepository>((ref) {
  return ref.watch(marketDataRepositoryProvider);
});

final getTradesUseCaseProvider = Provider<GetTradesUseCase>((ref) {
  final repository = ref.watch(marketDataRepositoryProvider);
  return GetTradesUseCase(repository);
});

/// Polls the REST ticker endpoint every 5 seconds.
/// Falls back to mock data automatically when offline.
final tickerStreamProvider = StreamProvider.family<Ticker, TradingSymbol>((
  ref,
  symbol,
) {
  final useCase = ref.watch(getTickerUseCaseProvider);
  final controller = StreamController<Ticker>();

  Future<void> fetch() async {
    final result = await useCase.call(symbol);
    result.fold(
      (_) {
        // Silently skip failed polls — don't crash the stream
      },
      (ticker) {
        if (!controller.isClosed) controller.add(ticker);
      },
    );
  }

  // Initial fetch immediately
  fetch();

  // Poll every 5 seconds
  final timer = Timer.periodic(const Duration(seconds: 5), (_) => fetch());

  ref.onDispose(() {
    timer.cancel();
    controller.close();
  });

  return controller.stream;
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

/// Polls the REST order book endpoint every 5 seconds.
final orderBookStreamProvider = StreamProvider.family<OrderBook, TradingSymbol>(
  (ref, symbol) {
    final repository = ref.watch(getOrderBookUseCaseProvider);
    final controller = StreamController<OrderBook>();

    Future<void> fetch() async {
      final result = await repository.getOrderBook(symbol);
      result.fold((_) {}, (orderBook) {
        if (!controller.isClosed) controller.add(orderBook);
      });
    }

    fetch();
    final timer = Timer.periodic(const Duration(seconds: 5), (_) => fetch());

    ref.onDispose(() {
      timer.cancel();
      controller.close();
    });

    return controller.stream;
  },
);

/// Polls the REST recent trades endpoint every 5 seconds.
final tradesStreamProvider = StreamProvider.family<List<Trade>, TradingSymbol>((
  ref,
  symbol,
) {
  final useCase = ref.watch(getTradesUseCaseProvider);
  final controller = StreamController<List<Trade>>();

  Future<void> fetch() async {
    final result = await useCase.call(symbol);
    result.fold((_) {}, (trades) {
      if (!controller.isClosed) controller.add(trades);
    });
  }

  fetch();
  final timer = Timer.periodic(const Duration(seconds: 5), (_) => fetch());

  ref.onDispose(() {
    timer.cancel();
    controller.close();
  });

  return controller.stream;
});
