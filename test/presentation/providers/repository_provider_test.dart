import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtrade/core/result.dart';
import 'package:youtrade/data/datasources/local/app_database.dart';
import 'package:youtrade/data/datasources/mock/deterministic_market_data_store.dart';
import 'package:youtrade/domain/entities/symbol.dart';
import 'package:youtrade/domain/entities/ticker.dart';
import 'package:youtrade/domain/entities/venue.dart';
import 'package:youtrade/presentation/providers/connectivity_provider.dart';
import 'package:youtrade/presentation/providers/repository_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('marketDataRepositoryProvider offline wiring', () {
    final symbol = TradingSymbol(
      base: 'BTC',
      quote: 'USDT',
      venue: Venue.binance,
      rawSymbol: 'BTCUSDT',
    );

    ProviderContainer createContainer({required bool online}) {
      return ProviderContainer(
        overrides: [
          connectivityProvider.overrideWith((ref) => Stream.value(online)),
          appDatabaseProvider.overrideWith((ref) {
            final db = AppDatabase(database: NativeDatabase.memory());
            ref.onDispose(() => db.close());
            return db;
          }),
        ],
      );
    }

    test('returns deterministic fallback data when offline', () async {
      final container = createContainer(online: false);
      addTearDown(container.dispose);

      await container.read(connectivityProvider.future);
      final repository = container.read(marketDataRepositoryProvider);

      final result = await repository.getTicker(symbol);

      expect(result, isA<Success<Ticker>>());
      const expectedStore = DeterministicMarketDataStore();
      final expected = await expectedStore.getTicker(symbol);
      expect((result as Success<Ticker>).value.lastPrice, expected.lastPrice);
    });

    test('constructs without error when online', () {
      final container = createContainer(online: true);
      addTearDown(container.dispose);

      final repository = container.read(marketDataRepositoryProvider);
      expect(repository, isNotNull);
    });
  });
}
