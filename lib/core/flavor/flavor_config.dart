// Flutter imports:
import 'package:flutter/foundation.dart';

// Project imports:
import 'flavor.dart';

/// Runtime configuration carrying the active [Flavor] and per-flavor
/// values resolved at startup from `--dart-define-from-file=config/<flavor>.json`.
///
/// Set once at the top of `bootstrap()` via [FlavorConfig.set] and read
/// anywhere via [FlavorConfig.instance].
///
/// All fields default to safe sentinels when a key is missing from the
/// JSON file — code that requires a value should validate at startup
/// (see [missingRequiredFields]).
@immutable
class FlavorConfig {
  const FlavorConfig({
    required this.flavor,
    required this.apiBaseUrl,
    required this.apiTimeoutSeconds,
    required this.buildLockHash,
    required this.buildLockSalt,
    required this.enableLogs,
    required this.useRemoteTranslations,
    required this.supportEmail,
    required this.defaultLocale,
  });

  /// Build a config from compile-time `--dart-define` values. Each
  /// `lib/main_<flavor>.dart` calls this with the right [flavor].
  factory FlavorConfig.fromEnvironment(Flavor flavor) => FlavorConfig(
    flavor: flavor,
    apiBaseUrl: const String.fromEnvironment('API_BASE_URL'),
    apiTimeoutSeconds: const int.fromEnvironment(
      'API_TIMEOUT_SECONDS',
      defaultValue: 30,
    ),
    buildLockHash: const String.fromEnvironment('BUILD_LOCK_HASH'),
    buildLockSalt: const String.fromEnvironment('BUILD_LOCK_SALT'),
    enableLogs: const bool.fromEnvironment(
      'ENABLE_LOGS',
      defaultValue: true,
    ),
    useRemoteTranslations: const bool.fromEnvironment(
      'USE_REMOTE_TRANSLATIONS',
    ),
    supportEmail: const String.fromEnvironment('SUPPORT_EMAIL'),
    defaultLocale: const String.fromEnvironment(
      'DEFAULT_LOCALE',
      defaultValue: 'ar',
    ),
  );

  /// The active flavor for this build.
  final Flavor flavor;

  /// Base URL for the backend API. Empty in dev when mocking locally.
  final String apiBaseUrl;

  /// Default request timeout, in seconds.
  final int apiTimeoutSeconds;

  /// SHA-256 of `salt + buildLockPassword`, computed at build time.
  /// Empty when the flavor does not require a lock screen.
  ///
  /// Validated at boot: a non-prod flavor that [Flavor.requiresBuildLock]
  /// must ship with a non-empty hash, otherwise the lock screen never gates.
  final String buildLockHash;

  /// Random salt mixed into the build-lock hash, base64-encoded.
  /// Empty when the flavor does not require a lock screen.
  final String buildLockSalt;

  /// Verbose logging toggle. Disabled in prod by convention.
  final bool enableLogs;

  /// Toggle the remote-translation layer. When `false`, the app skips
  /// `RemoteTranslations.init()` and `Tr.t(...)` falls back to the
  /// ARB-generated local strings.
  final bool useRemoteTranslations;

  /// Support email surfaced by fatal-error screens, feedback, and any
  /// "contact us" entry. Empty falls back to a hard-coded sentinel —
  /// adopters set this in `config/<flavor>.json`.
  final String supportEmail;

  /// The locale the app opens in on a FIRST launch, before the customer
  /// has chosen one.
  ///
  /// Terracotta is an Arabic-first app for Saudi Arabia, so prod and uat
  /// open in `ar`. Dev and staging open in `en`, because that is what
  /// the people building it read — a per-flavor default, not a
  /// per-build one, so a staging tester still reaches the Arabic layout
  /// by switching in settings.
  ///
  /// This is only the DEFAULT. `PreferencesCubit` overrides it the
  /// moment the customer picks a language, and that choice is what
  /// persists.
  final String defaultLocale;

  /// Names of required fields that are missing for the current flavor.
  /// Used by `bootstrap()` to log a warning and (in release) abort.
  List<String> get missingRequiredFields {
    final missing = <String>[];
    if (flavor != Flavor.dev && apiBaseUrl.isEmpty) {
      missing.add('API_BASE_URL');
    }
    if (flavor.requiresBuildLock) {
      if (buildLockHash.isEmpty) missing.add('BUILD_LOCK_HASH');
      if (buildLockSalt.isEmpty) missing.add('BUILD_LOCK_SALT');
    }
    return missing;
  }

  static FlavorConfig? _instance;

  /// Non-throwing accessor. `null` until [set] is called. Use this from
  /// code that may run before bootstrap (e.g. an early-mounted theme
  /// helper that wants flavor color but must tolerate boot-time absence).
  static FlavorConfig? get maybeInstance => _instance;

  /// The active config. Throws if accessed before [set] is called —
  /// catching cases where flavor-dependent code runs before bootstrap.
  static FlavorConfig get instance {
    final i = _instance;
    if (i == null) {
      throw StateError(
        'FlavorConfig accessed before bootstrap. '
        'Ensure bootstrap(Flavor) ran before this code path.',
      );
    }
    return i;
  }

  /// Initialize the singleton. Call exactly once from `bootstrap()`.
  static void set(FlavorConfig config) {
    if (_instance != null) {
      throw StateError(
        'FlavorConfig.set called twice. '
        'Bootstrap should only run once per process.',
      );
    }
    _instance = config;
  }

  /// Test-only reset. Never call from production code.
  @visibleForTesting
  static void debugReset() {
    _instance = null;
  }
}
