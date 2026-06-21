import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:youtrade/core/failures.dart';
import 'package:youtrade/core/result.dart';
import 'package:youtrade/domain/auth/exchange_credentials.dart';
import 'package:youtrade/domain/entities/venue.dart';
import 'package:youtrade/domain/repositories/exchange_credentials_repository.dart';
import 'package:youtrade/presentation/exchange/exchange_credentials_provider.dart';
import 'package:youtrade/presentation/exchange/exchange_credentials_state.dart';

class MockExchangeCredentialsRepository extends Mock
    implements ExchangeCredentialsRepository {}

void main() {
  late MockExchangeCredentialsRepository mockRepository;

  setUp(() {
    mockRepository = MockExchangeCredentialsRepository();
  });

  ProviderContainer makeContainer() {
    return ProviderContainer(
      overrides: [
        exchangeCredentialsRepositoryProvider.overrideWithValue(mockRepository),
      ],
    );
  }

  final binanceCredentials = ExchangeCredentials(
    venue: Venue.binance,
    apiKey: 'api-key',
    secret: 'secret',
    isEnabled: true,
  );

  final bybitCredentials = ExchangeCredentials(
    venue: Venue.bybit,
    apiKey: 'bybit-api-key',
    secret: 'bybit-secret',
    isEnabled: true,
  );

  group('ExchangeCredentialsNotifier', () {
    test('initial state is loading', () {
      final container = makeContainer();
      addTearDown(container.dispose);

      expect(
        container.read(exchangeCredentialsNotifierProvider),
        isA<ExchangeCredentialsLoading>(),
      );
    });

    test('loadAll emits loaded state with credentials', () async {
      when(
        () => mockRepository.list(),
      ).thenAnswer((_) async => Success([binanceCredentials]));

      final container = makeContainer();
      addTearDown(container.dispose);
      final states = <ExchangeCredentialsState>[];
      container.listen(
        exchangeCredentialsNotifierProvider,
        (_, state) => states.add(state),
      );

      await container
          .read(exchangeCredentialsNotifierProvider.notifier)
          .loadAll();

      expect(states.length, 1);
      expect(states.single, isA<ExchangeCredentialsLoaded>());
      final loaded = states.single as ExchangeCredentialsLoaded;
      expect(loaded.credentials, [binanceCredentials]);
    });

    test('loadAll emits error when repository fails', () async {
      when(() => mockRepository.list()).thenAnswer(
        (_) async =>
            const Err<List<ExchangeCredentials>>(UnknownFailure('load failed')),
      );

      final container = makeContainer();
      addTearDown(container.dispose);
      final states = <ExchangeCredentialsState>[];
      container.listen(
        exchangeCredentialsNotifierProvider,
        (_, state) => states.add(state),
      );

      await container
          .read(exchangeCredentialsNotifierProvider.notifier)
          .loadAll();

      expect(states.single, isA<ExchangeCredentialsError>());
      final error = states.single as ExchangeCredentialsError;
      expect(error.failure, isA<UnknownFailure>());
    });

    test('save reloads credentials on success', () async {
      when(
        () => mockRepository.save(binanceCredentials),
      ).thenAnswer((_) async => const Success<void>(null));
      when(
        () => mockRepository.list(),
      ).thenAnswer((_) async => Success([binanceCredentials]));

      final container = makeContainer();
      addTearDown(container.dispose);
      final states = <ExchangeCredentialsState>[];
      container.listen(
        exchangeCredentialsNotifierProvider,
        (_, state) => states.add(state),
      );

      await container
          .read(exchangeCredentialsNotifierProvider.notifier)
          .save(binanceCredentials);

      // Catches bug where save succeeds but the credentials list is not reloaded.
      expect(states.length, 1);
      final loaded = states.single as ExchangeCredentialsLoaded;
      expect(loaded.credentials, [binanceCredentials]);
    });

    test('save emits error when repository fails', () async {
      when(
        () => mockRepository.save(binanceCredentials),
      ).thenAnswer((_) async => const Err<void>(UnknownFailure('save failed')));

      final container = makeContainer();
      addTearDown(container.dispose);
      final states = <ExchangeCredentialsState>[];
      container.listen(
        exchangeCredentialsNotifierProvider,
        (_, state) => states.add(state),
      );

      await container
          .read(exchangeCredentialsNotifierProvider.notifier)
          .save(binanceCredentials);

      expect(states.single, isA<ExchangeCredentialsError>());
    });

    test('delete reloads credentials on success', () async {
      when(
        () => mockRepository.delete(Venue.binance),
      ).thenAnswer((_) async => const Success<void>(null));
      when(
        () => mockRepository.list(),
      ).thenAnswer((_) async => const Success<List<ExchangeCredentials>>([]));

      final container = makeContainer();
      addTearDown(container.dispose);
      final states = <ExchangeCredentialsState>[];
      container.listen(
        exchangeCredentialsNotifierProvider,
        (_, state) => states.add(state),
      );

      await container
          .read(exchangeCredentialsNotifierProvider.notifier)
          .delete(Venue.binance);

      // Catches bug where delete succeeds but the removed credential still appears.
      expect(states.length, 1);
      final loaded = states.single as ExchangeCredentialsLoaded;
      expect(loaded.credentials, isEmpty);
    });

    test('testConnection emits testing then success', () async {
      when(
        () => mockRepository.testConnection(binanceCredentials),
      ).thenAnswer((_) async => const Success<bool>(true));

      final container = makeContainer();
      addTearDown(container.dispose);
      final states = <ExchangeCredentialsState>[];
      container.listen(
        exchangeCredentialsNotifierProvider,
        (_, state) => states.add(state),
      );

      await container
          .read(exchangeCredentialsNotifierProvider.notifier)
          .testConnection(binanceCredentials);

      expect(states.length, 2);
      expect(states.first, isA<ExchangeCredentialsTesting>());
      expect(states.last, isA<ExchangeCredentialsTestSuccess>());
      final success = states.last as ExchangeCredentialsTestSuccess;
      expect(success.venue, Venue.binance.displayName);
    });

    test('testConnection emits testing then failure', () async {
      when(() => mockRepository.testConnection(binanceCredentials)).thenAnswer(
        (_) async => const Err<bool>(NetworkFailure('unauthorized')),
      );

      final container = makeContainer();
      addTearDown(container.dispose);
      final states = <ExchangeCredentialsState>[];
      container.listen(
        exchangeCredentialsNotifierProvider,
        (_, state) => states.add(state),
      );

      await container
          .read(exchangeCredentialsNotifierProvider.notifier)
          .testConnection(binanceCredentials);

      expect(states.length, 2);
      expect(states.first, isA<ExchangeCredentialsTesting>());
      expect(states.last, isA<ExchangeCredentialsTestFailure>());
      final failure = states.last as ExchangeCredentialsTestFailure;
      expect(failure.venue, Venue.binance.displayName);
      expect(failure.failure, isA<NetworkFailure>());
    });

    test(
      'clearTestResult transitions from test success to loaded credentials',
      () async {
        when(
          () => mockRepository.testConnection(binanceCredentials),
        ).thenAnswer((_) async => const Success<bool>(true));
        when(() => mockRepository.list()).thenAnswer(
          (_) async => Success([binanceCredentials, bybitCredentials]),
        );

        final container = makeContainer();
        addTearDown(container.dispose);
        final states = <ExchangeCredentialsState>[];
        container.listen(
          exchangeCredentialsNotifierProvider,
          (_, state) => states.add(state),
        );

        await container
            .read(exchangeCredentialsNotifierProvider.notifier)
            .testConnection(binanceCredentials);
        container
            .read(exchangeCredentialsNotifierProvider.notifier)
            .clearTestResult();
        await Future<void>.delayed(Duration.zero);

        expect(states.length, 4);
        expect(states[0], isA<ExchangeCredentialsTesting>());
        expect(states[1], isA<ExchangeCredentialsTestSuccess>());
        expect(states[2], isA<ExchangeCredentialsLoading>());
        expect(states[3], isA<ExchangeCredentialsLoaded>());
        final loaded = states.last as ExchangeCredentialsLoaded;
        expect(loaded.credentials, [binanceCredentials, bybitCredentials]);
      },
    );

    test('save success reloads correct filtered list', () async {
      when(
        () => mockRepository.save(bybitCredentials),
      ).thenAnswer((_) async => const Success<void>(null));
      when(() => mockRepository.list()).thenAnswer(
        (_) async => Success([binanceCredentials, bybitCredentials]),
      );

      final container = makeContainer();
      addTearDown(container.dispose);
      final states = <ExchangeCredentialsState>[];
      container.listen(
        exchangeCredentialsNotifierProvider,
        (_, state) => states.add(state),
      );

      await container
          .read(exchangeCredentialsNotifierProvider.notifier)
          .save(bybitCredentials);

      expect(states.length, 1);
      final loaded = states.single as ExchangeCredentialsLoaded;
      expect(loaded.credentials, [binanceCredentials, bybitCredentials]);
    });

    test('delete non-existent venue emits repository error', () async {
      when(() => mockRepository.delete(Venue.okx)).thenAnswer(
        (_) async => const Err<void>(UnknownFailure('Venue not found')),
      );

      final container = makeContainer();
      addTearDown(container.dispose);
      final states = <ExchangeCredentialsState>[];
      container.listen(
        exchangeCredentialsNotifierProvider,
        (_, state) => states.add(state),
      );

      await container
          .read(exchangeCredentialsNotifierProvider.notifier)
          .delete(Venue.okx);

      expect(states.length, 1);
      final error = states.single as ExchangeCredentialsError;
      expect(error.failure, isA<UnknownFailure>());
      expect(error.failure.message, 'Venue not found');
    });
  });
}
