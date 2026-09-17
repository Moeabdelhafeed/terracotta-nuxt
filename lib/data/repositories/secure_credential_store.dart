import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/auth/user/user.dart';

/// Encrypted-storage-backed store for auth credentials + user
/// identity. Owns the `flutter_secure_storage` instance — only place
/// in the app that talks to Keychain / EncryptedSharedPreferences
/// directly.
///
/// Not a true repository (no network / multi-source). Consumed by
/// [AuthBloc] (state) and injected into other services that need raw
/// credential access (e.g. `ApiService` reading the bearer token on
/// each request).
///
/// Persisted: `authToken`, `fcmToken`, `user`.
/// Not persisted here: temporary/OTP tokens — those live in
/// [AuthBloc] memory state only.
///
/// Uses the plugin's direct `AES_GCM_NoPadding` cipher path (the
/// default when `encryptedSharedPreferences: false`) instead of the
/// `androidx.security.crypto.EncryptedSharedPreferences` / Tink
/// integration. The Tink path fails permanently when the Android
/// KeyStore master key rotates (factory reset, OS upgrade,
/// backup-restore mixing ciphertexts) — `AEADBadTagException` fires
/// on every launch + the plugin then runs its full algorithm-change
/// migration each time because the bad Tink keyset isn't cleared.
/// The direct AES_GCM path doesn't depend on Tink, so a rotated
/// master key gets handled by `resetOnError: true` (wipe + fresh
/// AES key) instead of looping the migration noise.
///
/// `migrateOnAlgorithmChange: true` covers the one-time path for
/// installs that previously ran with `encryptedSharedPreferences:
/// true` so existing tokens survive the switch.
class SecureCredentialStore {
  SecureCredentialStore({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(resetOnError: true),
          );

  static const _keyAuthToken = 'authToken';
  static const _keyFcmToken = 'fcmToken';
  static const _keyUser = 'user';

  /// Whether the stored session belongs to FRONT-DESK STAFF.
  ///
  /// Kept beside the token because `is_scanner` arrives only on the
  /// sign-in response — it is not on `GET /api/user`, and the roles
  /// that decide it live on the server. Without it a cold start could
  /// not tell staff from a customer, so a scanner reopening the app
  /// landed on the shop with a session that answers 403 to every
  /// request it makes.
  static const _keyIsScanner = 'isScanner';

  final FlutterSecureStorage _storage;

  // ─── Auth token ──────────────────────────────────────────────────

  Future<String?> readAuthToken() async {
    final v = await _storage.read(key: _keyAuthToken);
    return (v == null || v.isEmpty) ? null : v;
  }

  Future<void> writeAuthToken(String token) =>
      _storage.write(key: _keyAuthToken, value: token);

  Future<void> clearAuthToken() => _storage.delete(key: _keyAuthToken);

  // ─── FCM token ───────────────────────────────────────────────────

  Future<String?> readFcmToken() async {
    final v = await _storage.read(key: _keyFcmToken);
    return (v == null || v.isEmpty) ? null : v;
  }

  Future<void> writeFcmToken(String token) =>
      _storage.write(key: _keyFcmToken, value: token);

  Future<void> clearFcmToken() => _storage.delete(key: _keyFcmToken);

  // ─── User ────────────────────────────────────────────────────────

  Future<User?> readUser() async {
    final raw = await _storage.read(key: _keyUser);
    if (raw == null || raw.isEmpty) return null;
    try {
      return User.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> writeUser(User user) =>
      _storage.write(key: _keyUser, value: jsonEncode(user.toJson()));

  Future<void> clearUser() => _storage.delete(key: _keyUser);

  /// Whether the stored session is staff's. False when nothing was
  /// written — a customer, which is the safe reading: it lands them on
  /// the shop, where a customer belongs, rather than on a desk they
  /// cannot use.
  Future<bool> readIsScanner() async {
    final raw = await _storage.read(key: _keyIsScanner);
    return raw == 'true';
  }

  Future<void> writeIsScanner(bool value) =>
      _storage.write(key: _keyIsScanner, value: '$value');

  Future<void> clearIsScanner() => _storage.delete(key: _keyIsScanner);

  // ─── Bulk ────────────────────────────────────────────────────────

  /// Wipe every credential the repository owns. Use on logout /
  /// "forget this device" flows.
  Future<void> clearAll() => _storage.deleteAll();
}
