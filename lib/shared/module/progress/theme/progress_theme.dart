import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/theme_colors_extension.dart';
import '../progress_models.dart';

/// App-wide defaults for `GlobalProgress`.
///
/// The rebrand hook: set the weight, the corner and the motion of every
/// progress indicator in the app once here.
@immutable
class GlobalProgressTheme extends ThemeExtension<GlobalProgressTheme> {
  const GlobalProgressTheme({this.style});

  final ProgressStyle? style;

  static GlobalProgressTheme? maybeOf(BuildContext context) =>
      Theme.of(context).extension<GlobalProgressTheme>();

  @override
  GlobalProgressTheme copyWith({ProgressStyle? style}) =>
      GlobalProgressTheme(style: style ?? this.style);

  @override
  GlobalProgressTheme lerp(
    ThemeExtension<GlobalProgressTheme>? other,
    double t,
  ) {
    if (other is! GlobalProgressTheme) return this;
    return GlobalProgressTheme(style: _lerpStyle(style, other.style, t));
  }

  /// Continuous fields interpolate; discrete ones snap at the midpoint.
  static ProgressStyle? _lerpStyle(
    ProgressStyle? a,
    ProgressStyle? b,
    double t,
  ) {
    if (a == null && b == null) return null;
    final pick = t < 0.5 ? a : b;
    return ProgressStyle(
      color: Color.lerp(a?.color, b?.color, t),
      trackColor: Color.lerp(a?.trackColor, b?.trackColor, t),
      trackOpacity: lerpDouble(a?.trackOpacity, b?.trackOpacity, t),
      size: lerpDouble(a?.size, b?.size, t),
      thickness: lerpDouble(a?.thickness, b?.thickness, t),
      borderRadius: BorderRadius.lerp(a?.borderRadius, b?.borderRadius, t),
      labelStyle: TextStyle.lerp(a?.labelStyle, b?.labelStyle, t),
      sublabelStyle: TextStyle.lerp(a?.sublabelStyle, b?.sublabelStyle, t),
      stepLabelStyle: TextStyle.lerp(a?.stepLabelStyle, b?.stepLabelStyle, t),
      bufferColor: Color.lerp(a?.bufferColor, b?.bufferColor, t),
      tickColor: Color.lerp(a?.tickColor, b?.tickColor, t),
      tickWidth: lerpDouble(a?.tickWidth, b?.tickWidth, t),
      stepGap: lerpDouble(a?.stepGap, b?.stepGap, t),
      shadow: BoxShadow.lerpList(a?.shadow, b?.shadow, t),
      animationDuration: _lerpDuration(
        a?.animationDuration,
        b?.animationDuration,
        t,
      ),
      indeterminateDuration: _lerpDuration(
        a?.indeterminateDuration,
        b?.indeterminateDuration,
        t,
      ),
      // Gradients, curves, flags and a colour MAP do not interpolate
      // between two different specs — snap.
      gradient: pick?.gradient,
      trackGradient: pick?.trackGradient,
      capStyle: pick?.capStyle,
      showLabel: pick?.showLabel,
      labelPosition: pick?.labelPosition,
      labelFormatter: pick?.labelFormatter,
      animated: pick?.animated,
      animationCurve: pick?.animationCurve,
      indeterminate: pick?.indeterminate,
      innerShadow: pick?.innerShadow,
      showTickMarks: pick?.showTickMarks,
      tickCount: pick?.tickCount,
      pulse: pick?.pulse,
      colorThresholds: pick?.colorThresholds,
      followTextDirection: pick?.followTextDirection,
      appearAfter: _lerpDuration(a?.appearAfter, b?.appearAfter, t),
    );
  }

  /// Null-tolerant duration lerp — `lerpDuration` requires both sides.
  static Duration? _lerpDuration(Duration? a, Duration? b, double t) {
    if (a == null && b == null) return null;
    if (a == null || b == null) return t < 0.5 ? a : b;
    return Duration(
      microseconds:
          (a.inMicroseconds + (b.inMicroseconds - a.inMicroseconds) * t)
              .round(),
    );
  }
}

extension ProgressStyleResolve on ProgressStyle {
  /// Stacks `caller > theme > defaults`, then fills colours from the
  /// palette and the natural size from the [type].
  ///
  /// The type is an argument because a bar, a ring, a gauge, a dial and
  /// a droplet have five different natural sizes and the bag cannot
  /// know which one it is being read for. That is also why `defaults`
  /// carries no `size`.
  ///
  /// [disableAnimations] stops the value TRANSITION, the pulse and the
  /// wave — but NOT an indeterminate sweep. Everything else here is
  /// decoration; the sweep is the only thing saying work is happening,
  /// and a still one says the app has hung.
  ResolvedProgressStyle resolve(
    BuildContext context, {
    required ProgressType type,
    bool disableAnimations = false,
  }) {
    final merged = ProgressStyle.defaults
        .mergedWith(GlobalProgressTheme.maybeOf(context)?.style)
        .mergedWith(this);
    const floor = ProgressStyle.defaults;

    final text = context.textColors;
    final fill = merged.color ?? context.primaryColors.primary;
    final trackOpacity = merged.trackOpacity ?? floor.trackOpacity!;

    final labelBase = (context.textTheme.labelMedium ?? const TextStyle())
        .copyWith(
          fontSize: ProgressDefaults.labelFontSize,
          fontWeight: ProgressDefaults.labelFontWeight,
          color: fill,
        );

    return ResolvedProgressStyle(
      color: fill,
      gradient: merged.gradient,
      // Derived unless named — `trackFollowsFill` is what lets a
      // threshold colour drag the track along with it.
      trackColor: merged.trackColor ?? fill.withValues(alpha: trackOpacity),
      trackFollowsFill: merged.trackColor == null,
      trackGradient: merged.trackGradient,
      trackOpacity: trackOpacity,
      size: merged.size ?? _naturalSize(type),
      thickness: merged.thickness ?? floor.thickness!,
      capStyle: merged.capStyle ?? floor.capStyle!,
      borderRadius: merged.borderRadius,
      showLabel: merged.showLabel ?? floor.showLabel!,
      labelPosition: merged.labelPosition ?? floor.labelPosition!,
      labelFormatter: merged.labelFormatter,
      labelStyle: merged.labelStyle ?? labelBase,
      sublabelStyle:
          merged.sublabelStyle ??
          labelBase.copyWith(
            fontSize: ProgressDefaults.gaugeLabelSubSize,
            fontWeight: FontWeight.w400,
            color: text.primary.withValues(
              alpha: ProgressDefaults.gaugeLabelSubOpacity,
            ),
          ),
      stepLabelStyle:
          merged.stepLabelStyle ??
          labelBase.copyWith(
            fontSize: ProgressDefaults.stepLabelFontSize,
            fontWeight: FontWeight.w400,
            color: text.primary.withValues(
              alpha: ProgressDefaults.stepLabelOpacity,
            ),
          ),
      animated: disableAnimations ? false : merged.animated ?? floor.animated!,
      animationDuration: merged.animationDuration ?? floor.animationDuration!,
      animationCurve: merged.animationCurve ?? floor.animationCurve!,
      indeterminate: merged.indeterminate ?? floor.indeterminate!,
      indeterminateDuration:
          merged.indeterminateDuration ?? floor.indeterminateDuration!,
      shadow: merged.shadow,
      innerShadow: merged.innerShadow ?? floor.innerShadow!,
      bufferColor:
          merged.bufferColor ??
          fill.withValues(alpha: ProgressDefaults.bufferOpacity),
      showTickMarks: merged.showTickMarks ?? floor.showTickMarks!,
      tickCount: merged.tickCount ?? floor.tickCount!,
      tickColor:
          merged.tickColor ??
          text.primary.withValues(alpha: ProgressDefaults.tickOpacity),
      tickWidth: merged.tickWidth ?? floor.tickWidth!,
      // A permanently glowing bar is exactly what `disableAnimations`
      // is for, and unlike the sweep it carries no information.
      pulse: disableAnimations ? false : merged.pulse ?? floor.pulse!,
      colorThresholds: merged.colorThresholds,
      followTextDirection:
          merged.followTextDirection ?? floor.followTextDirection!,
      appearAfter: merged.appearAfter ?? floor.appearAfter!,
      stepGap: merged.stepGap ?? floor.stepGap!,
    );
  }

  /// What each shape is when nobody says. A linear bar has no natural
  /// size — it fills the width it is handed.
  double? _naturalSize(ProgressType type) => switch (type) {
    ProgressType.linear ||
    ProgressType.stepped ||
    ProgressType.multiSegment => null,
    ProgressType.circular => ProgressDefaults.circularSize,
    ProgressType.gauge => ProgressDefaults.gaugeSize,
    ProgressType.waveFill => ProgressDefaults.waveSize,
  };
}
