// Dart imports:
import 'dart:async';
import 'dart:convert';

// Package imports:
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

// Project imports:
import '../../core/constants/remote_config_constants.dart';
import '../../core/env/env.dart';
import '../../core/flavor/flavor_config.dart';
import '../../core/utils/loggers/logger.dart';

/// Thin static wrapper over [FirebaseRemoteConfig]. Sets defaults +
/// fetch settings once on boot, then exposes typed getters for each
/// key. All accessors are safe before [init] — they fall back to the
/// default string.
/// Which layer in the resolution chain supplied a given key. Surfaced
/// to the diagnostics page so QA can see whether a value came from
/// Firebase, the bundled `.env`, or the inline default.
enum EnvSource {
  /// Debug-only runtime override (set via the dev overlay).
  /// Wins over every real source until cleared.
  override,

  /// Firebase Remote Config returned a non-empty value.
  remoteConfig,

  /// The FLAVOR's own `--dart-define`, from `config/<flavor>.json`.
  ///
  /// Above `.env` on purpose. `.env` is ONE file that
  /// `make env-sync-<flavor>` overwrites per build, so whichever
  /// flavor was built last leaves its values behind — and the next
  /// `flutter run` from an IDE, which syncs nothing, compiles them
  /// in. `config/<flavor>.json` travels with the build being made and
  /// cannot be stale.
  flavorConfig,

  /// `.env` constant via `envied` won the fallback.
  dotenv,

  /// Hardcoded inline default — last resort. Means neither RC nor
  /// `.env` had a usable value.
  hardcoded,
}

class RemoteConfigService {
  RemoteConfigService._();

  static final _remoteConfig = FirebaseRemoteConfig.instance;
  static bool _initialized = false;

  /// Tracks which layer supplied the most recent read of each key.
  /// The diagnostics page reads this to render the source badges.
  static final Map<String, EnvSource> _lastSource = {};

  /// Snapshot of the source map for diagnostics. Returns a copy so
  /// callers can't mutate internal state.
  static Map<String, EnvSource> get lastSourceSnapshot =>
      Map.unmodifiable(_lastSource);

  // ─── Debug-only runtime overrides ──────────────────────────
  // Lets the dev overlay flip any RC value at runtime without a
  // Firebase round-trip. Wins ahead of the real RC → .env → hardcoded
  // chain. Cleared on app restart (in-memory only). Type erasure here
  // is fine because resolvers cast on read, and write paths route
  // through type-specific helpers below.

  static final Map<String, Object?> _overrides = {};

  static final StreamController<void> _overrideChanges =
      StreamController<void>.broadcast();

  /// Snapshot of all active overrides. Mutating the returned map has
  /// no effect on the underlying state.
  static Map<String, Object?> get overrides => Map.unmodifiable(_overrides);

  /// Fires whenever an override is set / cleared. Diagnostics views
  /// subscribe to repaint without polling.
  static Stream<void> get overrideChanges => _overrideChanges.stream;

  /// Set a debug override for [key]. Triggers a refresh signal so
  /// listening UIs re-render. The value's runtime type drives which
  /// resolver consumes it: `String` for string keys, `bool` for bool,
  /// `int` for int, etc.
  static void setOverride(String key, Object? value) {
    _overrides[key] = value;
    _overrideChanges.add(null);
  }

  static void clearOverride(String key) {
    if (_overrides.remove(key) != null) _overrideChanges.add(null);
  }

  static void clearAllOverrides() {
    if (_overrides.isEmpty) return;
    _overrides.clear();
    _overrideChanges.add(null);
  }

  /// Layered resolver: RC → the FLAVOR's dart-define → `.env` →
  /// hardcoded. Records the winning layer in [_lastSource] under
  /// [rcKey].
  ///
  /// RC is treated as "won" only when it returns a non-empty string —
  /// an empty RC value falls through. Tweak this rule per key if you
  /// need empty-as-intentional somewhere.
  static String _resolveString(
    String rcKey, {
    required String envFallback,
    required String hardcoded,
    String flavorFallback = '',
  }) {
    final override = _overrides[rcKey];
    if (override != null) {
      _lastSource[rcKey] = EnvSource.override;
      return override.toString();
    }
    if (!kIsWeb && _initialized) {
      try {
        final v = _remoteConfig.getString(rcKey);
        if (v.isNotEmpty) {
          _lastSource[rcKey] = EnvSource.remoteConfig;
          return v;
        }
      } catch (_) {
        // Fall through to .env
      }
    }
    // THE FLAVOR BEING BUILT, before the one `.env` file on disk.
    //
    // `make build-prod-apk` runs `env-sync-prod`, which copies
    // `.env.prod` over `.env` and regenerates `env.g.dart` — so a prod
    // build leaves the machine holding prod's values, and the next
    // `flutter run` straight from an IDE compiles THOSE in while
    // `config/dev.json` says something else. That is how every request
    // went to the template's `api.example.com` while the bootstrap
    // line printed the real host: two sources of truth, and the app
    // read the wrong one.
    if (flavorFallback.isNotEmpty) {
      _lastSource[rcKey] = EnvSource.flavorConfig;
      return flavorFallback;
    }
    if (envFallback.isNotEmpty) {
      _lastSource[rcKey] = EnvSource.dotenv;
      return envFallback;
    }
    _lastSource[rcKey] = EnvSource.hardcoded;
    return hardcoded;
  }

  static Future<bool> init() async {
    try {
      if (_initialized) return true;

      // Web Remote Config needs a separately-configured Firebase web
      // project with the Remote Config API enabled. Until wired up,
      // skip on web instead of spamming init errors — `apiToken` and
      // `baseUrl` fall back to the inline defaults below.
      if (kIsWeb) {
        _initialized = true;
        Logger.m.d('Remote Config skipped on web (using fallback values).');
        return true;
      }

      // Use the central defaults manifest so the resolvers' fallbacks
      // match Firebase's pre-publish behaviour. Critical for bool keys
      // — Firebase RC returns `false` for any unset bool, so feature
      // flags would silently disable themselves without these.
      await _remoteConfig.setDefaults(RemoteConfigConstants.defaults);

      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: kDebugMode
              ? const Duration(minutes: 1)
              : const Duration(hours: 1),
        ),
      );

      final updated = await _remoteConfig.fetchAndActivate();
      _initialized = true;

      if (kDebugMode) {
        // Never log raw tokens in release builds — debug only.
        Logger.m.d('Remote Config initialized. Updated: $updated');
        Logger.m.d(
          'Remote Config values → baseUrl: ${_remoteConfig.getString('base_url')}',
        );
      }

      return true;
    } catch (e, stackTrace) {
      Logger.m.e(
        'Failed to initialize Remote Config',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  static String get apiToken => _resolveString(
    'x_api_token',
    envFallback: Env.apiXToken,
    hardcoded: 'fallback-token',
  );

  /// The API host every call goes to.
  ///
  /// The flavor's own `API_BASE_URL` outranks `.env` — see
  /// [EnvSource.flavorConfig]. `FlavorConfig` is not set in a plain
  /// `dart test`, so the read is guarded.
  static String get baseUrl => _resolveString(
    'base_url',
    flavorFallback: _flavorApiBaseUrl,
    envFallback: Env.apiBaseUrl,
    hardcoded: 'https://api.example.com',
  );

  /// `maybeInstance`, not `instance`: the latter THROWS before
  /// `bootstrap` sets it, which is every unit test that touches an API
  /// constant.
  static String get _flavorApiBaseUrl =>
      FlavorConfig.maybeInstance?.apiBaseUrl ?? '';

  /// Maps HTTP API key — used by Dart Dio callers (Directions,
  /// Geocoding, etc.). Live-flippable via RC.
  static String get mapsHttpApiKey => _resolveString(
    'maps_http_api_key',
    envFallback: Env.mapsHttpApiKey,
    hardcoded: '',
  );

  // ─── Store URLs ──────────────────────────────────────────

  static String get appStoreUrl {
    try {
      return _remoteConfig.getString('app_store_url');
    } catch (_) {
      return '';
    }
  }

  static String get playStoreUrl {
    try {
      return _remoteConfig.getString('play_store_url');
    } catch (_) {
      return '';
    }
  }

  // ─── Version Control ─────────────────────────────────────
  // Each platform reads its own RC key. Web returns empty (gate
  // skips itself when min is empty).

  static String get minAppVersion {
    if (kIsWeb) return '';
    return defaultTargetPlatform == TargetPlatform.iOS
        ? _safeString('min_app_version_ios')
        : defaultTargetPlatform == TargetPlatform.android
        ? _safeString('min_app_version_android')
        : '';
  }

  static String get latestAppVersion {
    if (kIsWeb) return '';
    return defaultTargetPlatform == TargetPlatform.iOS
        ? _safeString('latest_app_version_ios')
        : defaultTargetPlatform == TargetPlatform.android
        ? _safeString('latest_app_version_android')
        : '';
  }

  /// Platform-resolved store URL — App Store on iOS, Play on Android.
  /// Empty on web / desktop / unset.
  static String get currentStoreUrl {
    if (kIsWeb) return '';
    return defaultTargetPlatform == TargetPlatform.iOS
        ? appStoreUrl
        : defaultTargetPlatform == TargetPlatform.android
        ? playStoreUrl
        : '';
  }

  static String _safeString(String key) {
    try {
      return _remoteConfig.getString(key);
    } catch (_) {
      return '';
    }
  }

  // ─── Maintenance ─────────────────────────────────────────

  /// Bool resolver matching the same RC → fallback chain as
  /// `_resolveString`. Web returns [fallback] directly because RC
  /// init is skipped there — `_remoteConfig.getBool` would silently
  /// return `false` for any missing key, which is the wrong default
  /// for flags like `feedback_enabled` / `onboarding_enabled`.
  static bool _resolveBool(String key, {required bool fallback}) {
    final override = _overrides[key];
    if (override is bool) {
      _lastSource[key] = EnvSource.override;
      return override;
    }
    if (kIsWeb || !_initialized) {
      _lastSource[key] = EnvSource.hardcoded;
      return fallback;
    }
    try {
      _lastSource[key] = EnvSource.remoteConfig;
      return _remoteConfig.getBool(key);
    } catch (_) {
      _lastSource[key] = EnvSource.hardcoded;
      return fallback;
    }
  }

  static bool get maintenanceMode =>
      _resolveBool('maintenance_mode', fallback: false);

  static String get maintenanceTitle {
    try {
      return _remoteConfig.getString('maintenance_title');
    } catch (_) {
      return '';
    }
  }

  static String get maintenanceMessage {
    try {
      return _remoteConfig.getString('maintenance_message');
    } catch (_) {
      return '';
    }
  }

  /// Parses `maintenance_eta` as ISO-8601. Empty / invalid → null.
  static DateTime? get maintenanceEta {
    try {
      final raw = _remoteConfig.getString('maintenance_eta');
      if (raw.isEmpty) return null;
      return DateTime.tryParse(raw);
    } catch (_) {
      return null;
    }
  }

  static String get maintenanceSupportUrl {
    try {
      return _remoteConfig.getString('maintenance_support_url');
    } catch (_) {
      return '';
    }
  }

  /// Parses `maintenance_allow_list` as a JSON array of strings.
  /// Returns `[]` on empty / invalid payload — every route blocked
  /// during an outage.
  static List<String> get maintenanceAllowList {
    try {
      final raw = _remoteConfig.getString('maintenance_allow_list');
      if (raw.isEmpty) return const [];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded.whereType<String>().toList(growable: false);
    } catch (e) {
      Logger.m.e('Error parsing maintenanceAllowList', error: e);
      return const [];
    }
  }

  // ─── Feedback ────────────────────────────────────────────

  static bool get feedbackEnabled =>
      _resolveBool('feedback_enabled', fallback: true);

  static String get feedbackEndpoint => _resolveString(
    'feedback_endpoint',
    envFallback: Env.feedbackEndpoint,
    hardcoded: '',
  );

  static String get feedbackSupportEmail => _resolveString(
    'feedback_support_email',
    envFallback: Env.supportEmail,
    hardcoded: 'support@example.com',
  );

  static bool get feedbackAttachDiagnosticsDefault => _resolveBool(
    'feedback_attach_diagnostics_default',
    fallback: true,
  );

  /// Int resolver mirroring [_resolveBool] — checks debug overrides
  /// first, falls through to RC, then a [fallback]. Validation
  /// (`>= 0` etc) belongs to callers since each key has its own rule.
  static int _resolveInt(String key, {required int fallback}) {
    final override = _overrides[key];
    if (override is int) {
      _lastSource[key] = EnvSource.override;
      return override;
    }
    if (kIsWeb || !_initialized) {
      _lastSource[key] = EnvSource.hardcoded;
      return fallback;
    }
    try {
      _lastSource[key] = EnvSource.remoteConfig;
      return _remoteConfig.getInt(key);
    } catch (_) {
      _lastSource[key] = EnvSource.hardcoded;
      return fallback;
    }
  }

  static int get feedbackCooldownSeconds {
    final v = _resolveInt('feedback_cooldown_seconds', fallback: 60);
    return v < 0 ? 60 : v;
  }

  /// Zero or less means "the caller's own limit stands" — the same
  /// contract the cooldown has, so a config that never sets the key
  /// changes nothing.
  static int get feedbackMaxAttachments =>
      _resolveInt('feedback_max_attachments', fallback: 0);

  // ─── Onboarding ──────────────────────────────────────────

  static bool get onboardingEnabled =>
      _resolveBool('onboarding_enabled', fallback: true);

  static String get onboardingPagesJson {
    try {
      return _remoteConfig.getString('onboarding_pages_json');
    } catch (_) {
      return '';
    }
  }

  // ─── Connectivity ────────────────────────────────────────

  static String get connectivityProbeUrl {
    try {
      final v = _remoteConfig.getString('connectivity_probe_url');
      return v.isEmpty ? 'https://www.gstatic.com/generate_204' : v;
    } catch (_) {
      return 'https://www.gstatic.com/generate_204';
    }
  }

  static int get connectivityProbeIntervalSeconds {
    final v = _resolveInt('connectivity_probe_interval_seconds', fallback: 30);
    return v <= 0 ? 30 : v;
  }

  static int get connectivityMaxProbeFailures {
    final v = _resolveInt('connectivity_max_probe_failures', fallback: 3);
    return v <= 0 ? 3 : v;
  }

  static String get connectivityVpnPolicy {
    try {
      return _remoteConfig.getString('connectivity_vpn_policy');
    } catch (_) {
      return 'allow';
    }
  }

  // ─── Legal / About ───────────────────────────────────────

  /// `'backend'` = prefer backend HTML endpoint; anything else falls
  /// to the remote-markdown chain.
  static String get legalSourceMode {
    try {
      return _remoteConfig.getString('legal_source_mode');
    } catch (_) {
      return 'remote_md';
    }
  }

  /// Whether [slug]'s page is enabled. Defaults to `true` so a
  /// missing key doesn't accidentally hide a required legal page.
  static bool legalEnabled(String slug) =>
      _resolveBool('legal_${slug}_enabled', fallback: true);

  static String legalUrlMd(String slug) {
    try {
      return _remoteConfig.getString('legal_${slug}_url_md');
    } catch (_) {
      return '';
    }
  }

  static String legalEndpointHtml(String slug) {
    try {
      return _remoteConfig.getString('legal_${slug}_endpoint_html');
    } catch (_) {
      return '';
    }
  }

  // Force a refresh of the remote config
  static Future<bool> refresh() async {
    // Web has no native FRC pipeline wired in this template — `init`
    // already short-circuits on web. Mirror that here so the watcher's
    // periodic poll doesn't spam errors on every tick.
    if (kIsWeb) return true;
    try {
      await _remoteConfig.fetch();
      return await _remoteConfig.activate();
    } catch (e) {
      Logger.m.e('Error refreshing Remote Config', error: e);
      return false;
    }
  }
}
