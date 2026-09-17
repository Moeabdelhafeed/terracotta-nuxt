import 'package:flutter/material.dart';

import '../skeleton_models.dart';

/// App-wide defaults for [GlobalSkeleton].
@immutable
class GlobalSkeletonTheme extends ThemeExtension<GlobalSkeletonTheme> {
  const GlobalSkeletonTheme({this.style});

  final SkeletonStyle? style;

  static GlobalSkeletonTheme? maybeOf(BuildContext context) =>
      Theme.of(context).extension<GlobalSkeletonTheme>();

  @override
  GlobalSkeletonTheme copyWith({SkeletonStyle? style}) =>
      GlobalSkeletonTheme(style: style ?? this.style);

  @override
  GlobalSkeletonTheme lerp(
    ThemeExtension<GlobalSkeletonTheme>? other,
    double t,
  ) {
    if (other is! GlobalSkeletonTheme) return this;
    final a = style;
    final b = other.style;
    if (a == null && b == null) return this;
    final pick = t < 0.5 ? a : b;
    return GlobalSkeletonTheme(
      style: SkeletonStyle(
        borderRadius: BorderRadius.lerp(a?.borderRadius, b?.borderRadius, t),
        // Half a duration mid-swap would restart the crossfade.
        fadeDuration: pick?.fadeDuration,
        fadeCurve: pick?.fadeCurve,
      ),
    );
  }
}

extension SkeletonStyleResolve on SkeletonStyle {
  /// Stacks `caller > theme > defaults`.
  ///
  /// Reduced motion collapses the swap to instant: the real content
  /// still replaces the placeholder, it just does not travel to get
  /// there.
  ResolvedSkeletonStyle resolve(BuildContext context) {
    final merged = SkeletonStyle.defaults
        .mergedWith(GlobalSkeletonTheme.maybeOf(context)?.style)
        .mergedWith(this);
    const floor = SkeletonStyle.defaults;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return ResolvedSkeletonStyle(
      fadeDuration: reduceMotion
          ? Duration.zero
          : (merged.fadeDuration ?? floor.fadeDuration!),
      fadeCurve: merged.fadeCurve ?? floor.fadeCurve!,
      borderRadius: merged.borderRadius,
    );
  }
}
