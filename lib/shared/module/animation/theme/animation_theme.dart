import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../../../core/extensions/theme_colors_extension.dart';
import '../animation_models.dart';

/// App-wide defaults for `GlobalAnimation`.
///
/// The rebrand hook: set the corner, the transport tint and whether a
/// player offers controls at all, once, for every animation in the app.
@immutable
class GlobalAnimationTheme extends ThemeExtension<GlobalAnimationTheme> {
  const GlobalAnimationTheme({this.style});

  final GlobalAnimationStyle? style;

  static GlobalAnimationTheme? maybeOf(BuildContext context) =>
      Theme.of(context).extension<GlobalAnimationTheme>();

  @override
  GlobalAnimationTheme copyWith({GlobalAnimationStyle? style}) =>
      GlobalAnimationTheme(style: style ?? this.style);

  @override
  GlobalAnimationTheme lerp(
    ThemeExtension<GlobalAnimationTheme>? other,
    double t,
  ) {
    if (other is! GlobalAnimationTheme) return this;
    return GlobalAnimationTheme(style: _lerpStyle(style, other.style, t));
  }

  /// Continuous fields interpolate; discrete ones snap at the midpoint.
  static GlobalAnimationStyle? _lerpStyle(
    GlobalAnimationStyle? a,
    GlobalAnimationStyle? b,
    double t,
  ) {
    if (a == null && b == null) return null;
    final pick = t < 0.5 ? a : b;
    return GlobalAnimationStyle(
      backgroundColor: Color.lerp(a?.backgroundColor, b?.backgroundColor, t),
      borderRadius: BorderRadius.lerp(a?.borderRadius, b?.borderRadius, t),
      border: Border.lerp(a?.border, b?.border, t),
      controlsColor: Color.lerp(a?.controlsColor, b?.controlsColor, t),
      controlsBackgroundColor: Color.lerp(
        a?.controlsBackgroundColor,
        b?.controlsBackgroundColor,
        t,
      ),
      controlsIconSize: lerpDouble(
        a?.controlsIconSize,
        b?.controlsIconSize,
        t,
      ),
      progressBarColor: Color.lerp(a?.progressBarColor, b?.progressBarColor, t),
      progressBarBackgroundColor: Color.lerp(
        a?.progressBarBackgroundColor,
        b?.progressBarBackgroundColor,
        t,
      ),
      progressBarHeight: lerpDouble(
        a?.progressBarHeight,
        b?.progressBarHeight,
        t,
      ),
      // A shadow list and two widgets have no midpoint worth computing,
      // and neither does "are there controls" — a transport row half
      // present is a row that is there or is not.
      boxShadow: pick?.boxShadow,
      showControls: pick?.showControls,
      showProgressBar: pick?.showProgressBar,
      errorWidget: pick?.errorWidget,
      loadingWidget: pick?.loadingWidget,
      respectReducedMotion: pick?.respectReducedMotion,
    );
  }
}

extension AnimationStyleResolve on GlobalAnimationStyle {
  /// Stacks `caller > theme > defaults`, then fills colours from the
  /// palette.
  ///
  /// The transport row read `Theme.of(context).colorScheme.primary` and
  /// painted itself `Colors.black12` — Material's scheme and a constant,
  /// rather than the app's palette, so a rebrand left every player's
  /// controls behind and dark mode got a black wash on a dark surface.
  ResolvedAnimationStyle resolve(BuildContext context) {
    final merged = GlobalAnimationStyle.defaults
        .mergedWith(GlobalAnimationTheme.maybeOf(context)?.style)
        .mergedWith(this);
    const floor = GlobalAnimationStyle.defaults;

    final controls = merged.controlsColor ?? context.primaryColors.primary;

    return ResolvedAnimationStyle(
      // Deliberately NOT defaulted to a surface colour: an animation
      // brings its own background and a box behind it is the exception,
      // not the rule.
      backgroundColor: merged.backgroundColor,
      borderRadius: merged.borderRadius,
      border: merged.border,
      boxShadow: merged.boxShadow,
      showControls: merged.showControls ?? floor.showControls!,
      controlsColor: controls,
      // Washed, because the row sits OVER the animation, whose colours
      // nothing here controls.
      controlsBackgroundColor:
          merged.controlsBackgroundColor ??
          context.backgroundColors.surface.withValues(
            alpha: AnimationDefaults.controlsScrimOpacity,
          ),
      controlsIconSize: merged.controlsIconSize ?? floor.controlsIconSize!,
      showProgressBar: merged.showProgressBar ?? floor.showProgressBar!,
      progressBarColor: merged.progressBarColor ?? controls,
      progressBarBackgroundColor: merged.progressBarBackgroundColor,
      progressBarHeight: merged.progressBarHeight ?? floor.progressBarHeight!,
      errorWidget: merged.errorWidget,
      loadingWidget: merged.loadingWidget,
      respectReducedMotion:
          merged.respectReducedMotion ?? floor.respectReducedMotion!,
    );
  }
}
