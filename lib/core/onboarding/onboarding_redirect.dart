import 'package:flutter/foundation.dart';

import '../../data/blocs/preferences/preferences_cubit.dart';
import '../../data/services/remote_config_service.dart';
import '../di/service_locator.dart';

/// Decides whether onboarding should surface for the current launch.
///
/// Truth table (highest precedence first):
/// 1. **Dev override** ([OnboardingDevOverride] via [devOverride]) —
///    debug-overlay knob that forces `show` / `skip` / leaves the
///    real flow untouched (`auto`). Wins over everything below so
///    developers can replay the screen without wiping persisted
///    state.
/// 2. `OnboardingOptions.enabled` — compile-time master switch.
/// 3. RC `onboarding_enabled` — operator-flipped fleet kill switch.
/// 4. Deep-link arrival — non-root URL bypasses onboarding (and
///    marks it seen so it doesn't reappear next launch).
/// 5. `seenOnboarding` flag.
class OnboardingRedirect {
  const OnboardingRedirect._();

  /// Dev-overlay override. Read on every `shouldShow` call so the
  /// notifier listener in the splash route reacts mid-session. The
  /// override is **debug-only** — release builds always read `auto`.
  static final ValueNotifier<OnboardingDevOverride> devOverride =
      ValueNotifier<OnboardingDevOverride>(OnboardingDevOverride.auto);

  /// True when the splash / startup logic should push the onboarding
  /// route. Caller still owns the actual navigation.
  static bool shouldShow({
    bool arrivedViaDeepLink = false,
    bool? compileTimeEnabledOverride,
  }) {
    if (kDebugMode || kProfileMode) {
      switch (devOverride.value) {
        case OnboardingDevOverride.forceShow:
          return true;
        case OnboardingDevOverride.forceSkip:
          return false;
        case OnboardingDevOverride.auto:
          break;
      }
    }
    final compileEnabled = compileTimeEnabledOverride ?? true;
    if (!compileEnabled) return false;
    if (!RemoteConfigService.onboardingEnabled) return false;
    if (arrivedViaDeepLink) {
      // Deep-linked users get bumped past onboarding. Mark seen so
      // they don't see it on their next normal launch either —
      // they've effectively "started using the app".
      _markSeen();
      return false;
    }
    if (!getIt.isRegistered<PreferencesCubit>()) return false;
    final prefs = getIt<PreferencesCubit>().state;
    return !prefs.seenOnboarding;
  }

  /// Programmatic reset — used by settings page / QA.
  static void reset() {
    if (!getIt.isRegistered<PreferencesCubit>()) return;
    getIt<PreferencesCubit>().markOnboardingUnseen();
  }

  static void _markSeen() {
    if (!getIt.isRegistered<PreferencesCubit>()) return;
    getIt<PreferencesCubit>().markOnboardingSeen();
  }
}

/// Dev-only override mode. `auto` defers to persisted state +
/// RC + deep-link arrival as usual. `forceShow` always returns
/// true from [OnboardingRedirect.shouldShow]; `forceSkip` always
/// returns false. Release builds ignore the override.
enum OnboardingDevOverride {
  auto(label: 'Auto', description: 'Use real onboarding state'),
  forceShow(label: 'Force show', description: 'Always show onboarding'),
  forceSkip(label: 'Force skip', description: 'Always skip onboarding');

  const OnboardingDevOverride({
    required this.label,
    required this.description,
  });

  final String label;
  final String description;
}
