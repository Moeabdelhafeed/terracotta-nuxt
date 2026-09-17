import 'package:flutter/foundation.dart';

/// Dev-overlay override for the splash gate. Wins over real timing.
/// Lets developers iterate on the splash hero without restarting:
///  * `auto` — normal behaviour
///  * `forceHold` — splash never auto-navigates; tap-to-skip still
///    works
///  * `forceSkip` — splash navigates on first frame (still respects
///    `waitForBootstrap` so the app doesn't crash mid-init)
///
/// Release builds always read `auto`.
enum SplashDevOverride {
  auto(label: 'Auto', description: 'Normal timing'),
  forceHold(label: 'Force hold', description: 'Never auto-navigate'),
  forceSkip(label: 'Force skip', description: 'Navigate ASAP');

  const SplashDevOverride({required this.label, required this.description});
  final String label;
  final String description;
}

class SplashRedirect {
  const SplashRedirect._();

  static final ValueNotifier<SplashDevOverride> devOverride =
      ValueNotifier<SplashDevOverride>(SplashDevOverride.auto);

  /// True when [devOverride] currently dictates a force-* mode and
  /// the build is debug/profile. Release ignores the override.
  static bool get isOverridden {
    if (!(kDebugMode || kProfileMode)) return false;
    return devOverride.value != SplashDevOverride.auto;
  }
}
