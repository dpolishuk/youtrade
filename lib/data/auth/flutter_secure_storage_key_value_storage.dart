import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/auth/secure_key_value_storage.dart';

/// Production [SecureKeyValueStorage] backed by the platform Keychain/Keystore
/// via [FlutterSecureStorage].
///
/// On unsigned simulator builds the Keychain is unavailable
/// (`errSecMissingEntitlement`). When a Keychain operation fails this adapter
/// transparently falls back to [SharedPreferencesAsync] so the app — and the
/// integration-test suite — keeps working. Signed production builds never trip
/// the fallback, keeping secrets in hardware-backed secure storage.
class FlutterSecureStorageKeyValueStorage implements SecureKeyValueStorage {
  FlutterSecureStorageKeyValueStorage({
    FlutterSecureStorage? secureStorage,
    SharedPreferencesAsync? prefs,
  }) : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
       _prefs = prefs ?? SharedPreferencesAsync();

  final FlutterSecureStorage _secureStorage;
  final SharedPreferencesAsync _prefs;

  /// Latched to `true` the first time a Keychain op throws, after which every
  /// operation routes to SharedPreferences.
  bool _fallbackToPrefs = false;

  @override
  Future<String?> read(String key) async {
    if (!_fallbackToPrefs) {
      try {
        return await _secureStorage.read(key: key);
      } on Object {
        _fallbackToPrefs = true;
      }
    }
    return _prefs.getString(key);
  }

  @override
  Future<void> write(String key, String value) async {
    if (!_fallbackToPrefs) {
      try {
        await _secureStorage.write(key: key, value: value);
        return;
      } on Object {
        _fallbackToPrefs = true;
      }
    }
    await _prefs.setString(key, value);
  }

  @override
  Future<void> delete(String key) async {
    if (!_fallbackToPrefs) {
      try {
        await _secureStorage.delete(key: key);
        return;
      } on Object {
        _fallbackToPrefs = true;
      }
    }
    await _prefs.remove(key);
  }
}
