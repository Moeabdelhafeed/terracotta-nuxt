import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Shared durations for app-wide animations. Use these instead of
/// inlining `Duration(milliseconds: X)` — one knob to turn when a
/// designer wants everything snappier.
///
/// Loosely aligned with Material 3 motion tokens:
///  - `short2..short4`  ≈ micro / fast / normal (150–250 ms)
///  - `medium1..medium4` ≈ slow (300–400 ms)
///  - `long1..long4`     ≈ slowest (450–600 ms)
class AppDurations {
  const AppDurations._();

  /// 0 ms — use for state setters where a `Duration` argument is
  /// required but no animation should occur.
  static const Duration instant = Duration.zero;

  /// 100 ms — hover / press feedback, ripple fades.
  static const Duration micro = Duration(milliseconds: 100);

  /// 150 ms — small UI changes (chip flips, subtle color swaps).
  static const Duration fast = Duration(milliseconds: 150);

  /// 200 ms — component-level morphs (button state, switch slide).
  static const Duration quick = Duration(milliseconds: 200);

  /// 300 ms — default — page transitions, dialogs, most motion.
  static const Duration normal = Duration(milliseconds: 300);

  /// 400 ms — hero transitions, multi-element reveals.
  static const Duration slow = Duration(milliseconds: 400);

  /// 500 ms — expressive entrances (onboarding, splash → home).
  static const Duration deliberate = Duration(milliseconds: 500);

  /// 700 ms — first-run / marketing moments only. Too long for
  /// routine UI.
  static const Duration slowest = Duration(milliseconds: 700);

  // ─── Purpose-named aliases ──────────────────────────────────────

  /// Snackbar / toast show duration.
  static const Duration snackbar = Duration(seconds: 4);

  /// Shimmer sweep period.
  static const Duration shimmer = Duration(milliseconds: 1500);

  /// Debounce window for text-field search inputs.
  static const Duration debounceShort = Duration(milliseconds: 250);
  static const Duration debounceLong = Duration(milliseconds: 500);
}

/// Curated curves — same Flutter built-ins, but named by role so call
/// sites read like intent (`AppCurves.emphasized`) rather than flavor
/// (`Curves.easeOutCubic`).
class AppCurves {
  const AppCurves._();

  // ─── Material 3 motion scheme ───────────────────────────────────

  /// Default for most on-screen motion. Eased symmetrically.
  static const Curve standard = Curves.easeInOut;

  /// "Emphasized" — Material 3's signature spring-ish easeOut. Use for
  /// the primary motion in a scene (the thing the user is tracking).
  static const Curve emphasized = Curves.easeOutCubic;

  /// Entering content — decelerates as it arrives. Pair with [exit].
  static const Curve enter = Curves.easeOut;

  /// Leaving content — accelerates as it departs.
  static const Curve exit = Curves.easeIn;

  /// Elements already on screen that morph in place (size, color,
  /// position) without entering or exiting.
  static const Curve morph = Curves.easeInOutCubicEmphasized;

  // ─── Expressive ─────────────────────────────────────────────────

  /// Small overshoot at the end — playful entrances (FAB reveal,
  /// confetti-style pop-ins).
  static const Curve overshoot = Curves.easeOutBack;

  /// Full bounce at the end. Use sparingly; reads as toy-like.
  static const Curve bounce = Curves.bounceOut;

  /// Elastic spring. Only for "wow" moments.
  static const Curve elastic = Curves.elasticOut;

  /// Flat linear — for shimmers, progress sweeps, and anything with
  /// no start / end emphasis.
  static const Curve linear = Curves.linear;
}

/// Preset [PageTransitionsTheme]s — plug directly into
/// `ThemeData(pageTransitionsTheme: ...)`. Picks the right built-in
/// [PageTransitionsBuilder] per platform so iOS keeps its parallax
/// swipe-back while Android gets Material motion.
///
/// For feature-level page transitions, prefer `RouteTransition` from
/// `core/navigation/transitions/` — this theme only affects routes
/// that don't specify their own `pageBuilder`.
class AppPageTransitions {
  const AppPageTransitions._();

  /// Modern Material 3 — `ZoomPageTransitionsBuilder` on Android,
  /// `CupertinoPageTransitionsBuilder` on iOS/macOS, fade elsewhere.
  /// Recommended default.
  static const PageTransitionsTheme material = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: ZoomPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
      TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
      TargetPlatform.fuchsia: FadeForwardsPageTransitionsBuilder(),
    },
  );

  /// Cupertino everywhere — slide-from-right with parallax on all
  /// platforms. Use when the app is explicitly iOS-styled.
  static const PageTransitionsTheme cupertino = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: CupertinoPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
      TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
      TargetPlatform.fuchsia: CupertinoPageTransitionsBuilder(),
    },
  );

  /// Fade on every platform. Use for web or when consistency across
  /// form factors matters more than platform feel.
  static const PageTransitionsTheme fade = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
      TargetPlatform.iOS: FadeForwardsPageTransitionsBuilder(),
      TargetPlatform.macOS: FadeForwardsPageTransitionsBuilder(),
      TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
      TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
      TargetPlatform.fuchsia: FadeForwardsPageTransitionsBuilder(),
    },
  );

  /// Material zoom on every platform — the Android-flavored shared-axis
  /// transition. Feels wrong on iOS; use [material] unless you know you
  /// want this.
  static const PageTransitionsTheme zoom = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: ZoomPageTransitionsBuilder(),
      TargetPlatform.iOS: ZoomPageTransitionsBuilder(),
      TargetPlatform.macOS: ZoomPageTransitionsBuilder(),
      TargetPlatform.linux: ZoomPageTransitionsBuilder(),
      TargetPlatform.windows: ZoomPageTransitionsBuilder(),
      TargetPlatform.fuchsia: ZoomPageTransitionsBuilder(),
    },
  );

  /// Instant — no transition, pages just swap. Useful for flows where
  /// motion would be a distraction (kiosk mode, POS apps).
  static const PageTransitionsTheme none = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: _NoTransitionsBuilder(),
      TargetPlatform.iOS: _NoTransitionsBuilder(),
      TargetPlatform.macOS: _NoTransitionsBuilder(),
      TargetPlatform.linux: _NoTransitionsBuilder(),
      TargetPlatform.windows: _NoTransitionsBuilder(),
      TargetPlatform.fuchsia: _NoTransitionsBuilder(),
    },
  );
}

class _NoTransitionsBuilder extends PageTransitionsBuilder {
  const _NoTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => child;
}
