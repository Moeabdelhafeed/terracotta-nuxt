import 'package:local_auth/local_auth.dart';

import '../device_services.dart';

/// Biometric authentication (FaceID, TouchID, fingerprint, Windows
/// Hello).
///
/// ```dart
/// if (await BiometricUtils.isAvailable()) {
///   final ok = await BiometricUtils.authenticate(reason: 'Unlock wallet');
/// }
/// ```
class BiometricUtils {
  BiometricUtils._();

  static final LocalAuthentication _auth = LocalAuthentication();

  static DeviceCapability get _cap => DeviceServices.capability('biometrics');

  /// True if the device has biometric hardware AND something enrolled.
  static Future<bool> isAvailable() => _cap.guard(() async {
    final canCheck = await _auth.canCheckBiometrics;
    final isSupported = await _auth.isDeviceSupported();
    return canCheck && isSupported;
  }, fallback: false);

  /// Which biometrics are enrolled (face, fingerprint, iris).
  static Future<List<BiometricType>> getAvailableBiometrics() =>
      _cap.guard(_auth.getAvailableBiometrics, fallback: const []);

  /// Prompt for authentication.
  ///
  /// [reason] is shown in the system prompt. [biometricOnly] refuses
  /// the device PIN / pattern fallback. [sticky] keeps the prompt
  /// alive across a trip to the background.
  ///
  /// **`biometricOnly` used to do nothing.** The call read
  /// `biometricOnly: sticky` — the wrong variable — and the caller's
  /// own `biometricOnly` was dropped on the floor. So a screen asking
  /// for biometrics ONLY, which is a wallet or a vault or anything
  /// where a shoulder-surfed PIN is the threat, got a prompt that
  /// accepted that PIN; and `sticky: true` silently imposed the
  /// restriction on callers who had asked for something else
  /// entirely. Two parameters, each doing the other's job badly.
  static Future<bool> authenticate({
    required String reason,
    bool biometricOnly = false,
    bool sticky = false,
  }) => deviceGuard(
    'biometric.authenticate',
    () => _auth.authenticate(
      localizedReason: reason,
      biometricOnly: biometricOnly,
      persistAcrossBackgrounding: sticky,
    ),
    fallback: false,
  );

  /// Stop an in-progress prompt.
  static Future<bool> stopAuthentication() => deviceGuard(
    'biometric.stopAuthentication',
    _auth.stopAuthentication,
    fallback: false,
  );
}
