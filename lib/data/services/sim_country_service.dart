import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// SIM-based country detection — reads the SIM's ISO-3166-1 alpha-2
/// country code over a MethodChannel (`terracotta/sim_country`).
///
/// Detection layers on the native side:
/// - **Android** — `TelephonyManager.simCountryIso` with
///   `networkCountryIso` fallback. No permission needed.
/// - **iOS** — `CTTelephonyNetworkInfo` carrier ISO. Apple gutted
///   CoreTelephony on iOS 16.4+: it returns `"--"` placeholders, so on
///   modern iPhones this resolves to null and callers MUST fall back
///   (device locale → app default — `PhoneNumberField` does).
///
/// FAIL-OPEN utility singleton (not in getIt — same pattern as
/// `EmailDomainVerifier`): any channel error resolves to null, never
/// throws. The first real answer is cached for the app session (SIMs
/// don't hot-swap mid-session in any flow we care about).
class SimCountryService {
  SimCountryService._();

  static final SimCountryService instance = SimCountryService._();

  static const _channel = MethodChannel('terracotta/sim_country');

  /// Placeholders the platforms return instead of a real ISO code.
  static const _junk = {'', '--', 'ZZ', '65535'};

  static final _iso = RegExp(r'^[A-Z]{2}$');

  String? _cached;
  bool _resolved = false;

  /// Test/demo hook — non-null short-circuits the channel.
  @visibleForTesting
  String? debugOverride;

  /// The SIM's country as an UPPERCASE ISO code (`'JO'`), or null when
  /// there's no SIM, the platform can't say (iOS 16.4+, web/desktop), or
  /// the channel fails.
  Future<String?> countryIso() async {
    final override = debugOverride;
    if (override != null) return override;
    if (_resolved) return _cached;
    try {
      final raw = await _channel.invokeMethod<String>('getSimCountryIso');
      final iso = (raw ?? '').trim().toUpperCase();
      _cached = (_junk.contains(iso) || !_iso.hasMatch(iso)) ? null : iso;
    } on Exception {
      _cached = null;
    }
    _resolved = true;
    return _cached;
  }

  @visibleForTesting
  void resetForTest() {
    _cached = null;
    _resolved = false;
    debugOverride = null;
  }
}
