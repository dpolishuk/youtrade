/// A tamper-resistant key-value store for secrets such as credential hashes
/// and lockout counters.
///
/// Production implementations back this with the platform Keychain/Keystore
/// (see [FlutterSecureStorageKeyValueStorage]). Tests use an in-memory
/// implementation. This indirection keeps [PinAuthService] free of any
/// concrete storage technology (dependency inversion) and lets unsigned
/// simulator builds fall back to a less-secure store when the Keychain is
/// unavailable.
abstract interface class SecureKeyValueStorage {
  /// Returns the stored value for [key], or `null` when absent.
  Future<String?> read(String key);

  /// Persists [value] under [key].
  Future<void> write(String key, String value);

  /// Removes the value stored under [key], if any.
  Future<void> delete(String key);
}
