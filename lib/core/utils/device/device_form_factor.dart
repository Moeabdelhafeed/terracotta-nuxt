/// Physical device class for **diagnostics and showcase display only**.
///
/// **DO NOT use for layout decisions.** Layout uses [WindowSizeClass]
/// (Material 3 spec) — see `lib/core/responsive/window_size_class.dart`.
///
/// This enum exists so debug screens can show "Tablet" or "Desktop"
/// instead of the M3 layout bucket "Compact" / "Expanded", which is
/// more meaningful for telemetry and developer-facing diagnostics.
enum DeviceFormFactor {
  mobileSmall,
  mobileMedium,
  mobileLarge,
  tablet,
  laptopSmall,
  laptopMedium,
  desktop,
  desktopLarge,
  ;

  double get deviceWidth => switch (this) {
    .mobileSmall => 320.0,
    .mobileMedium => 375.0,
    .mobileLarge => 425.0,
    .tablet => 768.0,
    .laptopSmall => 1024.0,
    .laptopMedium => 1280.0,
    .desktop => 1440.0,
    .desktopLarge => 1920.0,
  };

  /// Material Design breakpoints — `< 600` is always mobile (phones up to large
  /// phablets), `< 905` is tablet portrait, then progressively wider.
  static DeviceFormFactor fromWidth(double value) => switch (value) {
    < 320 => .mobileSmall,
    < 375 => .mobileMedium,
    < 600 => .mobileLarge,
    < 905 => .tablet,
    < 1240 => .laptopSmall,
    < 1440 => .laptopMedium,
    < 1920 => .desktop,
    _ => .desktopLarge,
  };
}
