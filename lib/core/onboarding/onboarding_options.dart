import 'package:flutter/material.dart';

import 'onboarding_page.dart';
import 'onboarding_strings.dart';

/// Indicator variants. [none] hides the indicator entirely; [custom]
/// delegates rendering to [OnboardingOptions.indicatorBuilder].
enum OnboardingIndicatorKind { dots, bar, numbered, none, custom }

/// Master switch + customization surface for [OnboardingScreen].
///
/// All opt-in features default OFF (skip button is on by default —
/// most apps want it). The screen still shows when [enabled] is true
/// and `seenOnboarding` is false. Set [enabled] false to disable
/// onboarding entirely (caller code can still mount the route, but
/// the redirect helper will skip).
@immutable
class OnboardingOptions {
  const OnboardingOptions({
    this.enabled = true,
    this.indicator = OnboardingIndicatorKind.dots,
    this.showSkip = true,
    this.skipFlagsAsSeen = true,
    this.transitionDuration = const Duration(milliseconds: 320),
    this.transitionCurve = Curves.easeInOutCubic,
    this.autoAdvance,
    this.respectReduceMotion = true,
    this.strings = const OnboardingStrings(),
    this.indicatorBuilder,
    this.heroBuilder,
    this.bottomBarBuilder,
    this.contentBuilder,
    this.onPermissionRequest,
    this.onPageChanged,
    this.onAnalyticsEvent,
  });

  /// Master switch. False = onboarding never shows, regardless of
  /// `seenOnboarding` flag and RC setting.
  final bool enabled;

  final OnboardingIndicatorKind indicator;

  /// Show the "Skip" button in the bottom bar.
  final bool showSkip;

  /// Treat skip the same as finish — sets `seenOnboarding = true`.
  /// Some apps want skip to keep the flag false so users see it next
  /// launch; flip this to false for that flow.
  final bool skipFlagsAsSeen;

  final Duration transitionDuration;
  final Curve transitionCurve;

  /// When non-null, auto-advances pages on this interval. Hidden when
  /// the user manually swipes / taps. Null = manual only.
  final Duration? autoAdvance;

  /// Honor `MediaQuery.disableAnimations` — swap slide transition
  /// for fade when the OS asks to reduce motion.
  final bool respectReduceMotion;

  final OnboardingStrings strings;

  /// Replace the indicator widget when [indicator] is
  /// [OnboardingIndicatorKind.custom].
  final Widget Function(BuildContext context, int index, int count)?
  indicatorBuilder;

  /// Per-page hero override. Wins over the page's own hero settings.
  /// Useful for app-wide animation tweaks that all pages share.
  final Widget Function(BuildContext context, OnboardingPage page, int index)?
  heroBuilder;

  /// Replace the bottom bar (skip · indicator · next/finish).
  /// Receives helper callbacks so the override can still drive nav.
  final Widget Function(
    BuildContext context,
    OnboardingBottomBarApi api,
  )?
  bottomBarBuilder;

  /// Total override. Receives the resolved page list + controller.
  /// When set, every other rendering field is ignored.
  final Widget Function(
    BuildContext context,
    List<OnboardingPage> pages,
    PageController controller,
    OnboardingBottomBarApi api,
  )?
  contentBuilder;

  /// Called when a page's primary CTA targets a permission. Default
  /// implementation no-ops (returns true / continues). Wire your
  /// `permission_handler` calls here.
  final Future<bool> Function(OnboardingPermission permission)?
  onPermissionRequest;

  /// Fires whenever the visible page changes. Use for analytics or
  /// custom progress UI.
  final void Function(int index)? onPageChanged;

  /// Generic analytics hook — `step_seen`, `cta_tapped`, `skipped`,
  /// `finished`, `permission_granted`, `permission_denied`.
  final void Function(String name, Map<String, Object?> params)?
  onAnalyticsEvent;

  OnboardingOptions copyWith({
    bool? enabled,
    OnboardingIndicatorKind? indicator,
    bool? showSkip,
    bool? skipFlagsAsSeen,
    Duration? transitionDuration,
    Curve? transitionCurve,
    Duration? autoAdvance,
    bool? respectReduceMotion,
    OnboardingStrings? strings,
  }) {
    return OnboardingOptions(
      enabled: enabled ?? this.enabled,
      indicator: indicator ?? this.indicator,
      showSkip: showSkip ?? this.showSkip,
      skipFlagsAsSeen: skipFlagsAsSeen ?? this.skipFlagsAsSeen,
      transitionDuration: transitionDuration ?? this.transitionDuration,
      transitionCurve: transitionCurve ?? this.transitionCurve,
      autoAdvance: autoAdvance ?? this.autoAdvance,
      respectReduceMotion: respectReduceMotion ?? this.respectReduceMotion,
      strings: strings ?? this.strings,
      indicatorBuilder: indicatorBuilder,
      heroBuilder: heroBuilder,
      bottomBarBuilder: bottomBarBuilder,
      contentBuilder: contentBuilder,
      onPermissionRequest: onPermissionRequest,
      onPageChanged: onPageChanged,
      onAnalyticsEvent: onAnalyticsEvent,
    );
  }
}

/// Hooks exposed to bottom-bar / content overrides so callers can
/// drive navigation without re-implementing it.
class OnboardingBottomBarApi {
  const OnboardingBottomBarApi({
    required this.currentIndex,
    required this.pageCount,
    required this.next,
    required this.previous,
    required this.skip,
    required this.finish,
    required this.goTo,
  });

  final int currentIndex;
  final int pageCount;

  /// Advance to the next page or call `finish()` on the last page.
  final VoidCallback next;
  final VoidCallback previous;
  final VoidCallback skip;
  final VoidCallback finish;
  final void Function(int index) goTo;

  bool get isLast => currentIndex >= pageCount - 1;
}
