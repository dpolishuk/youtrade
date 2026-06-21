import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../domain/auth/exchange_credentials.dart';
import '../../../domain/entities/venue.dart';

abstract interface class SecureCredentialsStore {
  Future<void> save(ExchangeCredentials credentials);

  Future<ExchangeCredentials?> load(Venue venue);

  Future<void> delete(Venue venue);

  Future<List<ExchangeCredentials>> loadAll();
}

final class SecureCredentialsStoreImpl implements SecureCredentialsStore {
  SecureCredentialsStoreImpl({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const String _keyPrefix = 'exchange_credentials_';

  String _key(Venue venue) => '$_keyPrefix${venue.id}';

  @override
  Future<void> save(ExchangeCredentials credentials) async {
    final json = jsonEncode(credentials.toJson());
    await _storage.write(key: _key(credentials.venue), value: json);
  }

  @override
  Future<ExchangeCredentials?> load(Venue venue) async {
    final json = await _storage.read(key: _key(venue));
    if (json == null || json.isEmpty) return null;

    final map = jsonDecode(json) as Map<String, dynamic>;
    return ExchangeCredentials.fromJson(map);
  }

  @override
  Future<void> delete(Venue venue) async {
    await _storage.delete(key: _key(venue));
  }

  @override
  Future<List<ExchangeCredentials>> loadAll() async {
    final all = await _storage.readAll();
    final credentials = <ExchangeCredentials>[];

    for (final entry in all.entries) {
      if (!entry.key.startsWith(_keyPrefix)) continue;
      if (entry.value.isEmpty) continue;

      try {
        final map = jsonDecode(entry.value) as Map<String, dynamic>;
        credentials.add(ExchangeCredentials.fromJson(map));
      } on FormatException {
        continue;
      } on TypeError {
        continue;
      }
    }

    return credentials;
  }
}
