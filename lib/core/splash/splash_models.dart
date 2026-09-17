import 'dart:async';

import 'package:flutter/material.dart';

import '../constants/assets/asset_ref.dart';

// ─────────────────────────────────────────────────────────────
// Hero — sealed union over the supported splash visuals
// ─────────────────────────────────────────────────────────────

/// Visual content shown while the splash holds. Each variant exposes
/// enough metadata for the screen orchestrator to know **when it's
/// done** (so navigation timing isn't a hand-rolled `Future.delayed`).
@immutable
sealed class SplashHero {
  const SplashHero();

  /// Solid static widget held for [display]. The orchestrator's
  /// `minDuration` floor still applies; readiness completes once
  /// [display] elapses.
  const factory SplashHero.staticContent({
    required Widget child,
    Duration display,
  }) = SplashStaticHero;

  /// Icon centered on the splash bg. Cheapest variant — no asset
  /// load.
  const factory SplashHero.icon({
    required IconData icon,
    Color? color,
    double size,
    Duration display,
  }) = SplashIconHero;

  /// Image asset (PNG / SVG via [AssetRef]) centered. Held for
  /// [display]. Precache before splash mounts via
  /// [SplashWarmer.precacheImage] to avoid first-frame stutter.
  const factory SplashHero.image({
    required AssetRef ref,
    Duration display,
    double? width,
    double? height,
    BoxFit fit,
  }) = SplashImageHero;

  /// Lottie animation. Readiness completes when the controller
  /// reports the animation finished. When [loop] is true, completes
  /// after [repeatCount] full cycles.
  const factory SplashHero.lottie({
    required String asset,
    bool loop,
    int repeatCount,
    double? width,
    double? height,
    BoxFit fit,
  }) = SplashLottieHero;

  /// External video. **Pre-warm via [SplashWarmer.warmupVideo] in
  /// `bootstrap()` before the splash mounts** — otherwise the first
  /// frame stutters while the codec spins up.
  ///
  /// When [loop] is false, readiness completes on end-of-stream.
  /// When [loop] is true, readiness completes after [minLoops] full
  /// plays. Poster widget is shown while the player buffers; cross-
  /// fades to video once `streams.buffer` reports playable.
  const factory SplashHero.video({
    required SplashVideoSource source,
    bool loop,
    int minLoops,
    bool muted,
    BoxFit fit,
    Widget? poster,
    Duration posterMinDisplay,
  }) = SplashVideoHero;

  /// Escape hatch — caller renders anything, caller signals
  /// readiness. Use when none of the canonical variants fit.
  const factory SplashHero.builder({
    required WidgetBuilder builder,
    required Future<void> Function(BuildContext) readiness,
  }) = SplashBuilderHero;
}

class SplashStaticHero extends SplashHero {
  const SplashStaticHero({
    required this.child,
    this.display = const Duration(milliseconds: 800),
  });
  final Widget child;
  final Duration display;
}

class SplashIconHero extends SplashHero {
  const SplashIconHero({
    required this.icon,
    this.color,
    this.size = 96,
    this.display = const Duration(milliseconds: 800),
  });
  final IconData icon;
  final Color? color;
  final double size;
  final Duration display;
}

class SplashImageHero extends SplashHero {
  const SplashImageHero({
    required this.ref,
    this.display = const Duration(milliseconds: 800),
    this.width,
    this.height,
    this.fit = BoxFit.contain,
  });
  final AssetRef ref;
  final Duration display;
  final double? width;
  final double? height;
  final BoxFit fit;
}

class SplashLottieHero extends SplashHero {
  const SplashLottieHero({
    required this.asset,
    this.loop = false,
    this.repeatCount = 1,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
  }) : assert(repeatCount >= 1, 'repeatCount must be >= 1');
  final String asset;
  final bool loop;
  final int repeatCount;
  final double? width;
  final double? height;
  final BoxFit fit;
}

class SplashVideoHero extends SplashHero {
  const SplashVideoHero({
    required this.source,
    this.loop = false,
    this.minLoops = 1,
    this.muted = true,
    this.fit = BoxFit.cover,
    this.poster,
    this.posterMinDisplay = const Duration(milliseconds: 150),
  }) : assert(minLoops >= 1, 'minLoops must be >= 1');
  final SplashVideoSource source;
  final bool loop;
  final int minLoops;
  final bool muted;
  final BoxFit fit;
  final Widget? poster;
  final Duration posterMinDisplay;
}

class SplashBuilderHero extends SplashHero {
  const SplashBuilderHero({
    required this.builder,
    required this.readiness,
  });
  final WidgetBuilder builder;
  final Future<void> Function(BuildContext) readiness;
}

// ─────────────────────────────────────────────────────────────
// Video source
// ─────────────────────────────────────────────────────────────

@immutable
sealed class SplashVideoSource {
  const SplashVideoSource();

  /// Asset bundled in `pubspec.yaml`. Path must start with `assets/`.
  const factory SplashVideoSource.asset(String path) = SplashVideoAsset;

  /// Local file path (e.g. cached download).
  const factory SplashVideoSource.file(String path) = SplashVideoFile;

  /// Remote URL. **Recommend caching the first download** — see
  /// `SplashWarmer.warmupVideo` for the cache-then-play helper.
  const factory SplashVideoSource.network(String url) = SplashVideoNetwork;
}

class SplashVideoAsset extends SplashVideoSource {
  const SplashVideoAsset(this.path);
  final String path;
}

class SplashVideoFile extends SplashVideoSource {
  const SplashVideoFile(this.path);
  final String path;
}

class SplashVideoNetwork extends SplashVideoSource {
  const SplashVideoNetwork(this.url);
  final String url;
}

// ─────────────────────────────────────────────────────────────
// Destination + push mode
// ─────────────────────────────────────────────────────────────

enum SplashPushMode {
  /// `GoRouter.go` — resets the stack to this location.
  go,

  /// `GoRouter.pushReplacement` — swaps current entry.
  replace,

  /// `GoRouter.push` — stacks; back button returns to splash. Rare.
  push,
}

@immutable
class SplashDestination {
  const SplashDestination({
    required this.location,
    this.extra,
    this.mode = SplashPushMode.go,
  });

  final String location;
  final Object? extra;
  final SplashPushMode mode;
}

/// Decides where to go once the splash holds + bootstrap settle.
/// The default decider (`defaultSplashNext`) replicates the prior
/// hardcoded logic — onboarding redirect → auth → home. Adopters
/// swap for app-specific gating (e.g. paywall, kids-mode pin, etc).
typedef SplashNextDecider =
    Future<SplashDestination> Function(
      BuildContext context,
    );

// ─────────────────────────────────────────────────────────────
// Options
// ─────────────────────────────────────────────────────────────

@immutable
class SplashOptions {
  const SplashOptions({
    required this.hero,
    required this.nextDecider,
    this.backgroundColor,
    this.minDuration = const Duration(milliseconds: 800),
    this.maxDuration = const Duration(seconds: 8),
    this.extraDelay = Duration.zero,
    this.tapToSkip = false,
    this.waitForBootstrap = true,
    this.respectReduceMotion = true,
    this.footerBuilder,
    this.onAnalyticsEvent,
  });

  /// Visual hero rendered above the bg color.
  final SplashHero hero;

  /// Bg color — also drives [Scaffold.backgroundColor]. **Must match
  /// the iOS LaunchScreen + Android `@color/launch_background`** so
  /// the native → Flutter handoff is flash-free.
  ///
  /// `null` defers to the active theme's `scaffoldBackgroundColor`.
  final Color? backgroundColor;

  /// Floor — splash stays at least this long even if the hero
  /// finishes faster (a too-quick splash feels jittery).
  final Duration minDuration;

  /// Hard ceiling — bails out and navigates regardless of hero /
  /// bootstrap state. Last-resort guard so a hung video / broken
  /// asset can never trap the user on splash forever.
  final Duration maxDuration;

  /// Post-hero pause before [nextDecider] fires. Useful when the
  /// hero ends abruptly and a beat of silence reads better.
  final Duration extraDelay;

  /// Tap anywhere → navigate immediately (still respects bootstrap
  /// gates — won't bypass `await bootstrapPending`).
  final bool tapToSkip;

  /// When true, also gates navigation on `SplashWarmer.bootstrapDone`.
  /// Lets bootstrap-deferred async work (RC fetch, language preload,
  /// auth refresh) overlap the splash hold.
  final bool waitForBootstrap;

  /// When `MediaQuery.disableAnimationsOf` is true and the hero is
  /// a video, downgrade to the poster + `minDuration` so reduce-
  /// motion users aren't pelted with motion.
  final bool respectReduceMotion;

  /// Optional footer painted under the hero. Receives a `progress`
  /// value in `[0, 1]` derived from `elapsed / max(minDuration,
  /// estimatedHeroDuration)`. Useful for a thin progress bar or
  /// "Skip" hint.
  final Widget Function(BuildContext context, double progress)? footerBuilder;

  /// Forwarded to your analytics adapter. Names emitted:
  /// `splash_mounted` / `splash_hero_ready` / `splash_navigated` /
  /// `splash_skipped` / `splash_max_duration_exceeded`.
  final void Function(String name, Map<String, Object?> params)?
  onAnalyticsEvent;

  SplashOptions copyWith({
    SplashHero? hero,
    SplashNextDecider? nextDecider,
    Color? backgroundColor,
    Duration? minDuration,
    Duration? maxDuration,
    Duration? extraDelay,
    bool? tapToSkip,
    bool? waitForBootstrap,
    bool? respectReduceMotion,
    Widget Function(BuildContext, double)? footerBuilder,
    void Function(String, Map<String, Object?>)? onAnalyticsEvent,
  }) {
    return SplashOptions(
      hero: hero ?? this.hero,
      nextDecider: nextDecider ?? this.nextDecider,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      minDuration: minDuration ?? this.minDuration,
      maxDuration: maxDuration ?? this.maxDuration,
      extraDelay: extraDelay ?? this.extraDelay,
      tapToSkip: tapToSkip ?? this.tapToSkip,
      waitForBootstrap: waitForBootstrap ?? this.waitForBootstrap,
      respectReduceMotion: respectReduceMotion ?? this.respectReduceMotion,
      footerBuilder: footerBuilder ?? this.footerBuilder,
      onAnalyticsEvent: onAnalyticsEvent ?? this.onAnalyticsEvent,
    );
  }

  final SplashNextDecider nextDecider;
}
