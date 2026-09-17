// Flutter imports:
import 'package:flutter/material.dart';

/// The build flavor the app was compiled with.
///
/// Set once at startup via the entrypoint (`lib/main_<flavor>.dart`)
/// and stored in `FlavorConfig.instance`. Read the active flavor anywhere
/// with `FlavorConfig.instance.flavor`.
enum Flavor {
  /// Local development. Mock data acceptable, hot reload, no signing.
  /// Distributed via `flutter run`.
  dev,

  /// Internal QA. Real staging backend, full feature set, build-lock gated.
  /// Distributed via Firebase App Distribution / Play internal track.
  staging,

  /// Client sandbox. Prod-like environment, isolated per-client data,
  /// build-lock gated. Distributed via Firebase App Distribution / TestFlight.
  uat,

  /// Real users. Live backend, signed with release keys, no debug overlays.
  /// Distributed via Play Store / App Store.
  prod;

  /// Human-readable label shown in debug banner / lock screen.
  String get displayName => switch (this) {
    Flavor.dev => 'DEV',
    Flavor.staging => 'STAGING',
    Flavor.uat => 'UAT',
    Flavor.prod => 'PROD',
  };

  /// Color used for the flavor banner overlay (debug ribbon, app icon badge).
  Color get bannerColor => switch (this) {
    Flavor.dev => const Color(0xFFE53935), // red 600
    Flavor.staging => const Color(0xFFFB8C00), // orange 600
    Flavor.uat => const Color(0xFFFDD835), // yellow 600
    Flavor.prod => const Color(0x00000000), // transparent (no banner)
  };

  /// Bundle ID suffix appended to the base package name. Empty for prod
  /// so the production bundle ID stays clean and immutable.
  String get bundleSuffix => switch (this) {
    Flavor.dev => '.dev',
    Flavor.staging => '.staging',
    Flavor.uat => '.uat',
    Flavor.prod => '',
  };

  /// `true` when the flavor must show the build-lock screen before app loads.
  /// Protects leaked APKs of internal builds. Prod / dev skip the lock.
  bool get requiresBuildLock => this == Flavor.staging || this == Flavor.uat;

  /// `true` for production builds. Use to gate debug overlays, dev-only
  /// menus, verbose logging, and DevicePreview.
  bool get isProduction => this == Flavor.prod;

  /// `true` when the debug overlay's pill should be reachable, even in
  /// a RELEASE build.
  ///
  /// The overlay defaults to `kDebugMode`, which is right for a
  /// template and wrong for the builds that actually get handed to
  /// testers: a release APK is what they install, and the tool that
  /// answers "which flavor, which server, what did the last request
  /// say" is the first thing they need. Every non-production flavor
  /// gets it — the same line [showBanner] draws, for the same reason.
  bool get showDebugOverlay => this != Flavor.prod;

  /// `true` when the flavor banner should be visible. Hidden in prod.
  bool get showBanner => this != Flavor.prod;

  /// `true` when DevicePreview should mount. Off in dev (real device
  /// iteration) and prod (release). On for staging + uat QA passes.
  bool get useDevicePreview => this == Flavor.staging || this == Flavor.uat;
}
