import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/animations/animation_presets.dart';

// ---------------------------------------------------------------------------
// Defaults — every number a flight draws with
// ---------------------------------------------------------------------------

/// The compile-time floor under [InPageHeroStyle].
///
/// Sizes a token can express are NOT here — they come from
/// `MyGlobalInPageHeroTheme.build`. What is here is what a token cannot
/// say: the shape of the flight itself.
abstract final class InPageHeroDefaults {
  static const duration = AppDurations.slow;
  static const curve = Curves.easeInOutCubic;

  /// Where the crossfade between the two children STARTS, as a fraction
  /// of the flight, and how long it lasts.
  ///
  /// In the middle third: at the ends the flying box is the size of one
  /// endpoint or the other, and swapping the content there is the swap
  /// the flight exists to hide.
  static const crossfadeStart = 0.35;
  static const crossfadeSpan = 0.3;

  /// A collapsed endpoint keeps this much of its space.
  static const collapsedFactor = 0.0;
}

// ---------------------------------------------------------------------------
// The bag
// ---------------------------------------------------------------------------

/// Every knob a flight has, all of it optional.
///
/// Resolution order is `caller > GlobalInPageHeroTheme.style >
/// InPageHeroStyle.defaults`, and the resolve is where reduced motion
/// is applied.
@immutable
class InPageHeroStyle {
  const InPageHeroStyle({
    this.duration,
    this.curve,
    this.flightShadow,
    this.crossfadeStart,
    this.crossfadeSpan,
    this.respectReducedMotion,
    this.collapseAlignment,
  });

  final Duration? duration;
  final Curve? curve;

  /// Lifts the flying box off the page while it travels.
  final List<BoxShadow>? flightShadow;

  /// Where the crossfade between the two children starts, and how long
  /// it runs. See [InPageHeroDefaults.crossfadeStart].
  final double? crossfadeStart;
  final double? crossfadeSpan;

  /// Whether the reader's reduce-motion setting turns the flight into
  /// an instant swap.
  final bool? respectReducedMotion;

  /// Which corner a collapsing endpoint folds toward.
  final AlignmentGeometry? collapseAlignment;

  /// Nothing answered. The floor lives in [InPageHeroDefaults].
  static const InPageHeroStyle defaults = InPageHeroStyle();

  /// A quick, flat swap — for two endpoints close together.
  static const InPageHeroStyle snappy = InPageHeroStyle(
    duration: AppDurations.quick,
    curve: Curves.easeOutCubic,
  );

  /// It LIFTS: a shadow while it travels, so the box reads as being
  /// above the page rather than sliding along it.
  static InPageHeroStyle lifted({Color? shadowColor}) => InPageHeroStyle(
    flightShadow: [
      BoxShadow(
        color: (shadowColor ?? const Color(0xFF000000)).withValues(
          alpha: 0.28,
        ),
        blurRadius: 24,
        offset: const Offset(0, 10),
      ),
    ],
  );

  /// `other` wins field by field; `null` on `other` keeps ours.
  InPageHeroStyle mergedWith(InPageHeroStyle? other) {
    if (other == null) return this;
    return InPageHeroStyle(
      duration: other.duration ?? duration,
      curve: other.curve ?? curve,
      flightShadow: other.flightShadow ?? flightShadow,
      crossfadeStart: other.crossfadeStart ?? crossfadeStart,
      crossfadeSpan: other.crossfadeSpan ?? crossfadeSpan,
      respectReducedMotion: other.respectReducedMotion ?? respectReducedMotion,
      collapseAlignment: other.collapseAlignment ?? collapseAlignment,
    );
  }

  InPageHeroStyle copyWith({
    Duration? duration,
    Curve? curve,
    List<BoxShadow>? flightShadow,
    double? crossfadeStart,
    double? crossfadeSpan,
    bool? respectReducedMotion,
    AlignmentGeometry? collapseAlignment,
  }) => InPageHeroStyle(
    duration: duration ?? this.duration,
    curve: curve ?? this.curve,
    flightShadow: flightShadow ?? this.flightShadow,
    crossfadeStart: crossfadeStart ?? this.crossfadeStart,
    crossfadeSpan: crossfadeSpan ?? this.crossfadeSpan,
    respectReducedMotion: respectReducedMotion ?? this.respectReducedMotion,
    collapseAlignment: collapseAlignment ?? this.collapseAlignment,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InPageHeroStyle &&
          other.duration == duration &&
          other.curve == curve &&
          listEquals(other.flightShadow, flightShadow) &&
          other.crossfadeStart == crossfadeStart &&
          other.crossfadeSpan == crossfadeSpan &&
          other.respectReducedMotion == respectReducedMotion &&
          other.collapseAlignment == collapseAlignment;

  @override
  int get hashCode => Object.hash(
    duration,
    curve,
    flightShadow == null ? null : Object.hashAll(flightShadow!),
    crossfadeStart,
    crossfadeSpan,
    respectReducedMotion,
    collapseAlignment,
  );
}

// ---------------------------------------------------------------------------
// The bag with every question answered
// ---------------------------------------------------------------------------

/// What a flight actually runs with.
@immutable
class ResolvedInPageHeroStyle {
  const ResolvedInPageHeroStyle({
    required this.duration,
    required this.curve,
    required this.crossfadeStart,
    required this.crossfadeSpan,
    required this.collapseAlignment,
    this.flightShadow,
  });

  final Duration duration;
  final Curve curve;
  final double crossfadeStart;
  final double crossfadeSpan;
  final AlignmentGeometry collapseAlignment;
  final List<BoxShadow>? flightShadow;

  /// Whether there is a flight at all.
  ///
  /// Reduced motion resolves to a zero duration, and the whole overlay
  /// is then skipped rather than run for no frames — an overlay that
  /// inserts and removes itself in one frame still flickers.
  bool get isInstant => duration == Duration.zero;

  /// How far through the crossfade the flight is at [t].
  double crossfadeAt(double t) =>
      ((t - crossfadeStart) / crossfadeSpan).clamp(0.0, 1.0);
}
