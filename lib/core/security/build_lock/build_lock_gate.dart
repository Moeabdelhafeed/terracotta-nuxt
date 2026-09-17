// Dart imports:
import 'dart:convert';
import 'dart:io';

// Package imports:
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Project imports:
import '../../flavor/flavor.dart';
import '../../flavor/flavor_config.dart';

/// Outcome of a [BuildLockGate.tryUnlock] attempt.
enum UnlockResult { unlocked, invalid }

/// Gate for non-prod build distribution. Compares an entered password
/// against a SHA-256 hash baked into the binary at build time
/// (`BUILD_LOCK_HASH` / `BUILD_LOCK_SALT` from `config/<flavor>.json`)
/// and persists an unlock token bound to the device id so subsequent
/// launches skip the prompt.
///
/// Threat model: deters opportunistic leak of staging/uat APKs. Does
/// **not** protect against an attacker with reverse-engineering tools
/// who can extract the hash and brute-force offline. Use a strong
/// password and treat backend auth as the real security boundary.
class BuildLockGate {
  /// Emergency dev bypass — set with `--dart-define=BUILD_LOCK_BYPASS=true`.
  /// Skips the lock entirely. Never ship a build with this flag flipped.
  static const bool _bypass = bool.fromEnvironment(
    'BUILD_LOCK_BYPASS',
  );

  static const String _storageKey = 'build_lock_unlock_token_v1';

  final FlutterSecureStorage _storage;
  final DeviceInfoPlugin _deviceInfo;

  BuildLockGate({
    FlutterSecureStorage? storage,
    DeviceInfoPlugin? deviceInfo,
  }) : _storage = storage ?? const FlutterSecureStorage(),
       _deviceInfo = deviceInfo ?? DeviceInfoPlugin();

  Flavor get _flavor => FlavorConfig.instance.flavor;

  /// `true` when this build must be unlocked before the app can run.
  bool get isRequired => !_bypass && _flavor.requiresBuildLock;

  /// Whether the user has already unlocked this device. Returns `true`
  /// for flavors that don't require the lock and for misconfigured
  /// builds (missing hash/salt) — bootstrap already logged the warning.
  Future<bool> isUnlocked() async {
    if (!isRequired) return true;
    final cfg = FlavorConfig.instance;
    if (cfg.buildLockHash.isEmpty || cfg.buildLockSalt.isEmpty) return true;

    final stored = await _storage.read(key: _storageKey);
    if (stored == null || stored.isEmpty) return false;

    final expected = await _expectedToken();
    return _constantTimeEquals(stored, expected);
  }

  /// Compare [password] against the build-time hash. On match, persist
  /// the device-bound unlock token so future launches skip the prompt.
  Future<UnlockResult> tryUnlock(String password) async {
    final cfg = FlavorConfig.instance;
    if (cfg.buildLockHash.isEmpty || cfg.buildLockSalt.isEmpty) {
      return UnlockResult.invalid;
    }

    final attempted = sha256
        .convert(utf8.encode('${cfg.buildLockSalt}$password'))
        .toString();

    if (!_constantTimeEquals(attempted, cfg.buildLockHash)) {
      return UnlockResult.invalid;
    }

    await _storage.write(key: _storageKey, value: await _expectedToken());
    return UnlockResult.unlocked;
  }

  /// Wipe the persisted unlock token. Used by the dev reset gesture
  /// (long-press logo on lock screen) and in tests.
  Future<void> reset() => _storage.delete(key: _storageKey);

  /// Token persisted in secure storage on successful unlock.
  /// Mixes the build-time hash with a device id so a stolen secure-storage
  /// dump cannot be replayed on a different device.
  Future<String> _expectedToken() async {
    final cfg = FlavorConfig.instance;
    final deviceId = await _deviceId();
    return sha256
        .convert(utf8.encode('${cfg.buildLockHash}:$deviceId'))
        .toString();
  }

  Future<String> _deviceId() async {
    if (Platform.isAndroid) {
      final a = await _deviceInfo.androidInfo;
      return 'android:${a.id}';
    }
    if (Platform.isIOS) {
      final i = await _deviceInfo.iosInfo;
      return 'ios:${i.identifierForVendor ?? 'unknown'}';
    }
    return 'platform:${Platform.operatingSystem}';
  }

  /// Avoid timing leaks when comparing hex digests of different inputs.
  bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }
}
