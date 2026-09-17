import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/theme_colors_extension.dart';
import '../divider_models.dart';

/// App-wide defaults for `GlobalDivider`.
///
/// The rebrand hook: set the weight, colour and inset of every rule in
/// the app once here.
@immutable
class GlobalDividerTheme extends ThemeExtension<GlobalDividerTheme> {
  const GlobalDividerTheme({this.style});

  final DividerStyle? style;

  static GlobalDividerTheme? maybeOf(BuildContext context) =>
      Theme.of(context).extension<GlobalDividerTheme>();

  @override
  GlobalDividerTheme copyWith({DividerStyle? style}) =>
      GlobalDividerTheme(style: style ?? this.style);

  @override
  GlobalDividerTheme lerp(ThemeExtension<GlobalDividerTheme>? other, double t) {
    if (other is! GlobalDividerTheme) return this;
    return GlobalDividerTheme(style: _lerpStyle(style, other.style, t));
  }

  /// Continuous fields interpolate; discrete ones snap at the midpoint.
  static DividerStyle? _lerpStyle(DividerStyle? a, DividerStyle? b, double t) {
    if (a == null && b == null) return null;
    final pick = t < 0.5 ? a : b;
    return DividerStyle(
      thickness: lerpDouble(a?.thickness, b?.thickness, t),
      color: Color.lerp(a?.color, b?.color, t),
      gradient: Gradient.lerp(a?.gradient, b?.gradient, t),
      indent: lerpDouble(a?.indent, b?.indent, t),
      endIndent: lerpDouble(a?.endIndent, b?.endIndent, t),
      spacing: lerpDouble(a?.spacing, b?.spacing, t),
      dashWidth: lerpDouble(a?.dashWidth, b?.dashWidth, t),
      dashGap: lerpDouble(a?.dashGap, b?.dashGap, t),
      textStyle: TextStyle.lerp(a?.textStyle, b?.textStyle, t),
      textPadding: EdgeInsetsGeometry.lerp(a?.textPadding, b?.textPadding, t),
      iconSize: lerpDouble(a?.iconSize, b?.iconSize, t),
      iconColor: Color.lerp(a?.iconColor, b?.iconColor, t),
      verticalHeight: lerpDouble(a?.verticalHeight, b?.verticalHeight, t),
      doubleLineGap: lerpDouble(a?.doubleLineGap, b?.doubleLineGap, t),
      shadow: BoxShadow.lerp(a?.shadow, b?.shadow, t),
      waveAmplitude: lerpDouble(a?.waveAmplitude, b?.waveAmplitude, t),
      waveFrequency: lerpDouble(a?.waveFrequency, b?.waveFrequency, t),
      tapPadding: lerpDouble(a?.tapPadding, b?.tapPadding, t),
      roundedCaps: pick?.roundedCaps,
      animationDuration: pick?.animationDuration,
    );
  }
}

extension DividerStyleResolve on DividerStyle {
  /// Stacks `caller > theme > defaults`, then fills colours from
  /// `context.<group>Colors`.
  ///
  /// [disableAnimations] collapses the entrance to zero rather than
  /// shortening it — a rule that simply IS there is still the right
  /// rule.
  ResolvedDividerStyle resolve(
    BuildContext context, {
    bool disableAnimations = false,
  }) {
    final merged = DividerStyle.defaults
        .mergedWith(GlobalDividerTheme.maybeOf(context)?.style)
        .mergedWith(this);
    const floor = DividerStyle.defaults;

    // A rule is quieter than the text it separates, so it takes the
    // SECONDARY text colour at half strength rather than the outline —
    // which is the border of a control, and reads heavier.
    final color =
        merged.color ??
        context.textColors.secondary.withValues(
          alpha: DividerDefaults.colorOpacity,
        );

    return ResolvedDividerStyle(
      thickness: merged.thickness ?? floor.thickness!,
      color: color,
      gradient: merged.gradient,
      indent: merged.indent ?? floor.indent!,
      endIndent: merged.endIndent ?? floor.endIndent!,
      spacing: merged.spacing ?? floor.spacing!,
      dashWidth: merged.dashWidth ?? floor.dashWidth!,
      dashGap: merged.dashGap ?? floor.dashGap!,
      roundedCaps: merged.roundedCaps ?? floor.roundedCaps!,
      // The label sits ON the rule's own line, so it takes the rule's
      // colour by default and reads as part of it.
      textStyle:
          merged.textStyle ??
          (context.textTheme.bodySmall ?? const TextStyle()).copyWith(
            color: color,
            fontWeight: FontWeight.w500,
          ),
      textPadding: merged.textPadding ?? floor.textPadding!,
      iconSize: merged.iconSize ?? floor.iconSize!,
      iconColor: merged.iconColor ?? color,
      verticalHeight: merged.verticalHeight ?? floor.verticalHeight!,
      doubleLineGap: merged.doubleLineGap ?? floor.doubleLineGap!,
      animationDuration: disableAnimations
          ? Duration.zero
          : merged.animationDuration ?? floor.animationDuration!,
      shadow: merged.shadow,
      waveAmplitude: merged.waveAmplitude ?? floor.waveAmplitude!,
      waveFrequency: merged.waveFrequency ?? floor.waveFrequency!,
      tapPadding: merged.tapPadding ?? floor.tapPadding!,
    );
  }
}
