import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure token storage backed by the iOS/macOS Keychain via [FlutterSecureStorage].
///
/// Tokens MUST be stored here — NOT in [SharedPreferences] (NSUserDefaults),
/// which is not Keychain-backed and does not satisfy the security requirement (AC #2).
///
/// iOS: Uses [KeychainAccessibility.first_unlock] so tokens survive device reboot
/// without requiring the user to unlock their device first.
/// macOS: Uses the macOS Keychain automatically — same API, different backing store.
class TokenStorage {
  const TokenStorage();

  static const _storage = FlutterSecureStorage(
    // iOS Keychain access policy: accessible after first device unlock.
    // This allows background token refresh without an interactive unlock.
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  /// Persists both tokens atomically.
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  /// Returns the stored access token, or [null] if none exists.
  Future<String?> getAccessToken() => _storage.read(key: _accessTokenKey);

  /// Returns the stored refresh token, or [null] if none exists.
  Future<String?> getRefreshToken() => _storage.read(key: _refreshTokenKey);

  /// Removes both tokens — call on sign-out.
  Future<void> clearTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }
}
