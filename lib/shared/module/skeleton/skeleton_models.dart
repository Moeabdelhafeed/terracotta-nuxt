import 'package:flutter/material.dart';

import '../../../core/animations/animation_presets.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

const kSkeletonAnimDuration = AppDurations.normal;
const kSkeletonDefaultRadius = 8.0;
const kSkeletonTitleHeight = 16.0;
const kSkeletonBodyHeight = 12.0;
const kSkeletonAvatarSize = 40.0;
const kSkeletonImageHeight = 180.0;
const kSkeletonCardHeight = 120.0;
const kSkeletonSpacing = 12.0;

// ---------------------------------------------------------------------------
// SkeletonStyle
// ---------------------------------------------------------------------------

/// Themeable styling bag for [GlobalSkeleton] — EVERY field nullable.
///
/// Resolution order, materialized once per build by `resolve`:
/// `caller > GlobalSkeletonTheme.style > SkeletonStyle.defaults`.
@immutable
class SkeletonStyle {
  const SkeletonStyle({
    this.borderRadius,
    this.fadeDuration,
    this.fadeCurve,
  });

  /// Compile-time floor.
  static const SkeletonStyle defaults = SkeletonStyle(
    fadeDuration: kSkeletonAnimDuration,
    fadeCurve: Curves.easeOut,
  );

  /// Null lets each factory pick its own.
  final BorderRadius? borderRadius;

  /// How long the swap from skeleton to real content takes. Collapsed to
  /// zero under reduced motion — the content still arrives, it just does
  /// not travel.
  final Duration? fadeDuration;

  final Curve? fadeCurve;

  /// Field-by-field override — [other]'s non-null fields win.
  SkeletonStyle mergedWith(SkeletonStyle? other) {
    if (other == null) return this;
    return SkeletonStyle(
      borderRadius: other.borderRadius ?? borderRadius,
      fadeDuration: other.fadeDuration ?? fadeDuration,
      fadeCurve: other.fadeCurve ?? fadeCurve,
    );
  }

  SkeletonStyle copyWith({
    BorderRadius? borderRadius,
    Duration? fadeDuration,
    Curve? fadeCurve,
  }) => SkeletonStyle(
    borderRadius: borderRadius ?? this.borderRadius,
    fadeDuration: fadeDuration ?? this.fadeDuration,
    fadeCurve: fadeCurve ?? this.fadeCurve,
  );
}

/// Materialized [SkeletonStyle] — every themed field non-null.
@immutable
class ResolvedSkeletonStyle {
  const ResolvedSkeletonStyle({
    required this.fadeDuration,
    required this.fadeCurve,
    this.borderRadius,
  });

  final Duration fadeDuration;
  final Curve fadeCurve;
  final BorderRadius? borderRadius;
}
