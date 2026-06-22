import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtrade/data/datasources/mock/demo_market_data_store.dart';
import 'package:youtrade/data/repositories/market_data_repository_impl.dart';
import 'package:youtrade/domain/entities/venue.dart';
import 'package:youtrade/presentation/providers/connectivity_provider.dart';
import 'package:youtrade/presentation/providers/repository_provider.dart';

void main() {
  group('marketDataRepositoryProvider offline wiring', () {
    test(
      'uses empty venue sources and DemoMarketDataStore fallback when offline',
      () async {
        final container = ProviderContainer(
          overrides: [
            connectivityProvider.overrideWith((ref) => Stream.value(false)),
          ],
        );
        addTearDown(container.dispose);

        await container.read(connectivityProvider.future);
        final repository = container.read(marketDataRepositoryProvider);
        expect(repository, isA<MarketDataRepositoryImpl>());

        final impl = repository as MarketDataRepositoryImpl;
        final sources = impl.venueSources;
        expect(sources, isEmpty);
        expect(impl.fallbackStore, isA<DemoMarketDataStore>());
      },
    );

    test('uses venue sources for all exchanges when online', () {
      final container = ProviderContainer(
        overrides: [
          connectivityProvider.overrideWith((ref) => Stream.value(true)),
        ],
      );
      addTearDown(container.dispose);

      final repository = container.read(marketDataRepositoryProvider);
      final impl = repository as MarketDataRepositoryImpl;
      final sources = impl.venueSources;

      expect(sources, isNotEmpty);
      expect(
        sources.keys,
        containsAll(const [
          Venue.binance,
          Venue.bybit,
          Venue.okx,
          Venue.coinbase,
        ]),
      );
    });
  });
}
