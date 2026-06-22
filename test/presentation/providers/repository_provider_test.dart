import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:youtrade/data/datasources/local/app_database.dart';
import 'package:youtrade/data/datasources/remote/binance/binance_websocket_client.dart';
import 'package:youtrade/data/datasources/remote/bybit/bybit_websocket_client.dart';
import 'package:youtrade/data/datasources/remote/coinbase/coinbase_websocket_client.dart';
import 'package:youtrade/data/datasources/remote/okx/okx_websocket_client.dart';
import 'package:youtrade/data/repositories/market_data_repository_impl.dart';
import 'package:youtrade/presentation/providers/connectivity_provider.dart';
import 'package:youtrade/presentation/providers/repository_provider.dart';

class _SpyBinanceWebSocketClient extends BinanceWebSocketClient {
  var closeAllCallCount = 0;

  @override
  void closeAll() => closeAllCallCount++;
}

class _SpyBybitWebSocketClient extends BybitWebSocketClient {
  var closeAllCallCount = 0;

  @override
  void closeAll() => closeAllCallCount++;
}

class _SpyOkxWebSocketClient extends OKXWebSocketClient {
  var closeAllCallCount = 0;

  @override
  void closeAll() => closeAllCallCount++;
}

class _SpyCoinbaseWebSocketClient extends CoinbaseWebSocketClient {
  var closeAllCallCount = 0;

  @override
  void closeAll() => closeAllCallCount++;
}

void main() {
  group('marketDataRepositoryProvider', () {
    late AppDatabase database;

    setUp(() {
      database = AppDatabase(database: NativeDatabase.memory());
    });

    tearDown(() async {
      await database.close();
    });

    test(
      'returns MarketDataRepositoryImpl and disposes websocket clients',
      () async {
        final binanceWs = _SpyBinanceWebSocketClient();
        final bybitWs = _SpyBybitWebSocketClient();
        final okxWs = _SpyOkxWebSocketClient();
        final coinbaseWs = _SpyCoinbaseWebSocketClient();

        final container = ProviderContainer(
          overrides: [
            appDatabaseProvider.overrideWithValue(database),
            connectivityProvider.overrideWith((ref) => Stream.value(true)),
            binanceWebSocketClientProvider.overrideWith((ref) {
              final client = binanceWs;
              ref.onDispose(client.closeAll);
              return client;
            }),
            bybitWebSocketClientProvider.overrideWith((ref) {
              final client = bybitWs;
              ref.onDispose(client.closeAll);
              return client;
            }),
            okxWebSocketClientProvider.overrideWith((ref) {
              final client = okxWs;
              ref.onDispose(client.closeAll);
              return client;
            }),
            coinbaseWebSocketClientProvider.overrideWith((ref) {
              final client = coinbaseWs;
              ref.onDispose(client.closeAll);
              return client;
            }),
          ],
        );
        addTearDown(container.dispose);

        final repository = container.read(marketDataRepositoryProvider);

        expect(repository, isA<MarketDataRepositoryImpl>());

        container.dispose();
        await pumpEventQueue();

        expect(binanceWs.closeAllCallCount, 1);
        expect(bybitWs.closeAllCallCount, 1);
        expect(okxWs.closeAllCallCount, 1);
        expect(coinbaseWs.closeAllCallCount, 1);
      },
    );

    test('updates repository isOnline when connectivity changes', () async {
      final controller = StreamController<bool>.broadcast();
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          connectivityProvider.overrideWith((ref) => controller.stream),
          binanceWebSocketClientProvider.overrideWith((ref) {
            final client = _SpyBinanceWebSocketClient();
            ref.onDispose(client.closeAll);
            return client;
          }),
          bybitWebSocketClientProvider.overrideWith((ref) {
            final client = _SpyBybitWebSocketClient();
            ref.onDispose(client.closeAll);
            return client;
          }),
          okxWebSocketClientProvider.overrideWith((ref) {
            final client = _SpyOkxWebSocketClient();
            ref.onDispose(client.closeAll);
            return client;
          }),
          coinbaseWebSocketClientProvider.overrideWith((ref) {
            final client = _SpyCoinbaseWebSocketClient();
            ref.onDispose(client.closeAll);
            return client;
          }),
        ],
      );
      addTearDown(() {
        controller.close();
        container.dispose();
      });

      final repository =
          container.read(marketDataRepositoryProvider)
              as MarketDataRepositoryImpl;

      controller.add(false);
      await container.read(connectivityProvider.future);
      expect(repository.isOnline, isFalse);

      controller.add(true);
      await container.read(connectivityProvider.future);
      expect(repository.isOnline, isTrue);
    });
  });
}
