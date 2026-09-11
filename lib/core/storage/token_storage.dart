import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the backend JWT (see `AuthTokenEntity`) in platform secure
/// storage (Keychain on iOS, Keystore-backed `EncryptedSharedPreferences` on
/// Android) rather than `shared_preferences` — a JWT is a bearer credential
/// and shouldn't sit in unencrypted storage.
class TokenStorage {
  static const _accessTokenKey = 'access_token';

  final FlutterSecureStorage _storage;

  TokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  Future<void> saveToken(String accessToken) =>
      _storage.write(key: _accessTokenKey, value: accessToken);

  Future<String?> readAccessToken() => _storage.read(key: _accessTokenKey);

  Future<void> clear() => _storage.delete(key: _accessTokenKey);
}
