import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:youtrade/data/datasources/local/secure_credentials_store.dart';
import 'package:youtrade/domain/auth/exchange_credentials.dart';
import 'package:youtrade/domain/entities/venue.dart';

class _FakeSecureStorage extends FlutterSecureStorage {
  final Map<String, String?> _store = {};

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _store[key] = value;
  }

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => _store[key];

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _store.remove(key);
  }

  @override
  Future<Map<String, String>> readAll({
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return Map.fromEntries(
      _store.entries
          .where((e) => e.value != null)
          .map((e) => MapEntry(e.key, e.value!)),
    );
  }
}

class _ThrowingReadStorage extends _FakeSecureStorage {
  _ThrowingReadStorage(this.exception);

  final Exception exception;

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    throw exception;
  }
}

class _ThrowingWriteStorage extends _FakeSecureStorage {
  _ThrowingWriteStorage(this.exception);

  final Exception exception;

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    throw exception;
  }
}

void main() {
  group('SecureCredentialsStoreImpl', () {
    late _FakeSecureStorage storage;
    late SecureCredentialsStoreImpl store;

    setUp(() {
      storage = _FakeSecureStorage();
      store = SecureCredentialsStoreImpl(storage: storage);
    });

    final binanceCredentials = ExchangeCredentials(
      venue: Venue.binance,
      apiKey: 'binance-api-key',
      secret: 'binance-secret',
      isEnabled: true,
    );

    final bybitCredentials = ExchangeCredentials(
      venue: Venue.bybit,
      apiKey: 'bybit-api-key',
      secret: 'bybit-secret',
      isEnabled: false,
    );

    test('saves and loads credentials for a venue', () async {
      await store.save(binanceCredentials);
      final loaded = await store.load(Venue.binance);

      expect(loaded, equals(binanceCredentials));
    });

    test('returns null when no credentials are stored', () async {
      final loaded = await store.load(Venue.okx);

      expect(loaded, isNull);
    });

    test('deletes credentials for a venue', () async {
      await store.save(binanceCredentials);
      await store.delete(Venue.binance);
      final loaded = await store.load(Venue.binance);

      expect(loaded, isNull);
    });

    test('loadAll returns all stored credentials', () async {
      await store.save(binanceCredentials);
      await store.save(bybitCredentials);
      final all = await store.loadAll();

      expect(all.length, 2);
      expect(all, contains(binanceCredentials));
      expect(all, contains(bybitCredentials));
    });

    test('loadAll ignores keys that do not belong to credentials', () async {
      await storage.write(key: 'other_key', value: 'other_value');
      await store.save(binanceCredentials);
      final all = await store.loadAll();

      expect(all.length, 1);
      expect(all.single, binanceCredentials);
    });

    test('loadAll skips malformed entries', () async {
      await storage.write(
        key: 'exchange_credentials_okx',
        value: 'not-valid-json',
      );
      await store.save(binanceCredentials);
      final all = await store.loadAll();

      expect(all.length, 1);
      expect(all.single, binanceCredentials);
    });

    test('returns null when stored value is empty string', () async {
      await storage.write(key: 'exchange_credentials_binance', value: '');
      final loaded = await store.load(Venue.binance);

      expect(loaded, isNull);
    });

    test('returns null when JSON is missing fields', () async {
      await storage.write(
        key: 'exchange_credentials_binance',
        value: '{"venue":"binance","secret":"secret"}',
      );
      final loaded = await store.load(Venue.binance);

      expect(loaded, isNull);
    });

    test('returns null when JSON contains unknown venue id', () async {
      await storage.write(
        key: 'exchange_credentials_bybit',
        value: '{"venue":"fakevenue","apiKey":"key","secret":"secret"}',
      );
      final loaded = await store.load(Venue.bybit);

      expect(loaded, isNull);
    });

    test('loadAll skips entries with unknown venue id', () async {
      await storage.write(
        key: 'exchange_credentials_fakevenue',
        value: '{"venue":"fakevenue","apiKey":"key","secret":"secret"}',
      );
      await store.save(binanceCredentials);
      final all = await store.loadAll();

      expect(all.length, 1);
      expect(all.single, binanceCredentials);
    });

    test('propagates storage read exception', () async {
      final exception = Exception('secure storage read failed');
      final throwingStore = SecureCredentialsStoreImpl(
        storage: _ThrowingReadStorage(exception),
      );

      expect(
        () async => throwingStore.load(Venue.binance),
        throwsA(predicate((e) => e == exception)),
      );
    });

    test('propagates storage write exception', () async {
      final exception = Exception('secure storage write failed');
      final throwingStore = SecureCredentialsStoreImpl(
        storage: _ThrowingWriteStorage(exception),
      );

      expect(
        () async => throwingStore.save(binanceCredentials),
        throwsA(predicate((e) => e == exception)),
      );
    });

    test('handles concurrent reads and writes without corruption', () async {
      await Future.wait([
        store.save(binanceCredentials),
        store.save(bybitCredentials),
        store.load(Venue.binance),
        store.loadAll(),
      ]);

      final all = await store.loadAll();
      expect(all.length, 2);
      expect(all, contains(binanceCredentials));
      expect(all, contains(bybitCredentials));
    });

    test('toString masks sensitive values', () {
      final text = binanceCredentials.toString();

      expect(text, isNot(contains('binance-api-key')));
      expect(text, isNot(contains('binance-secret')));
      expect(text, contains('bina...-key'));
      expect(text, contains('bina...cret'));
    });
  });
}
