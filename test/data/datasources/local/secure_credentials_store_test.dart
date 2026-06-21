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
          .cast<MapEntry<String, String>>(),
    );
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

    test('toString masks sensitive values', () {
      final text = binanceCredentials.toString();

      expect(text, isNot(contains('binance-api-key')));
      expect(text, isNot(contains('binance-secret')));
      expect(text, contains('bina...-key'));
      expect(text, contains('bina...cret'));
    });
  });
}
