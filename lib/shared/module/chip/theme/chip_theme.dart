import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/theme_colors_extension.dart';
import '../chip_models.dart';

/// App-wide defaults for `GlobalChip`.
///
/// The rebrand hook: set the chip's shape, weight and ink once here and
/// every filter, tag and category row in the app follows.
@immutable
class GlobalChipTheme extends ThemeExtension<GlobalChipTheme> {
  const GlobalChipTheme({this.style});

  final ChipStyle? style;

  static GlobalChipTheme? maybeOf(BuildContext context) =>
      Theme.of(context).extension<GlobalChipTheme>();

  @override
  GlobalChipTheme copyWith({ChipStyle? style}) =>
      GlobalChipTheme(style: style ?? this.style);

  @override
  GlobalChipTheme lerp(ThemeExtension<GlobalChipTheme>? other, double t) {
    if (other is! GlobalChipTheme) return this;
    return GlobalChipTheme(style: _lerpStyle(style, other.style, t));
  }

  /// Continuous fields interpolate; discrete ones snap at the midpoint.
  static ChipStyle? _lerpStyle(ChipStyle? a, ChipStyle? b, double t) {
    if (a == null && b == null) return null;
    final pick = t < 0.5 ? a : b;
    return ChipStyle(
      backgroundColor: Color.lerp(a?.backgroundColor, b?.backgroundColor, t),
      selectedColor: Color.lerp(a?.selectedColor, b?.selectedColor, t),
      disabledColor: Color.lerp(a?.disabledColor, b?.disabledColor, t),
      labelColor: Color.lerp(a?.labelColor, b?.labelColor, t),
      selectedLabelColor: Color.lerp(
        a?.selectedLabelColor,
        b?.selectedLabelColor,
        t,
      ),
      disabledLabelColor: Color.lerp(
        a?.disabledLabelColor,
        b?.disabledLabelColor,
        t,
      ),
      borderColor: Color.lerp(a?.borderColor, b?.borderColor, t),
      selectedBorderColor: Color.lerp(
        a?.selectedBorderColor,
        b?.selectedBorderColor,
        t,
      ),
      backgroundGradient: Gradient.lerp(
        a?.backgroundGradient,
        b?.backgroundGradient,
        t,
      ),
      selectedBackgroundGradient: Gradient.lerp(
        a?.selectedBackgroundGradient,
        b?.selectedBackgroundGradient,
        t,
      ),
      borderGradient: Gradient.lerp(a?.borderGradient, b?.borderGradient, t),
      selectedBorderGradient: Gradient.lerp(
        a?.selectedBorderGradient,
        b?.selectedBorderGradient,
        t,
      ),
      shadowColor: Color.lerp(a?.shadowColor, b?.shadowColor, t),
      selectedShadowColor: Color.lerp(
        a?.selectedShadowColor,
        b?.selectedShadowColor,
        t,
      ),
      labelStyle: TextStyle.lerp(a?.labelStyle, b?.labelStyle, t),
      labelPadding: EdgeInsetsGeometry.lerp(
        a?.labelPadding,
        b?.labelPadding,
        t,
      ),
      padding: EdgeInsetsGeometry.lerp(a?.padding, b?.padding, t),
      borderRadius: BorderRadius.lerp(a?.borderRadius, b?.borderRadius, t),
      borderWidth: lerpDouble(a?.borderWidth, b?.borderWidth, t),
      elevation: lerpDouble(a?.elevation, b?.elevation, t),
      selectedElevation: lerpDouble(
        a?.selectedElevation,
        b?.selectedElevation,
        t,
      ),
      checkmarkColor: Color.lerp(a?.checkmarkColor, b?.checkmarkColor, t),
      deleteIconColor: Color.lerp(a?.deleteIconColor, b?.deleteIconColor, t),
      animationDuration: pick?.animationDuration,
      animationCurve: pick?.animationCurve,
      deleteAnimationDuration: pick?.deleteAnimationDuration,
      animateCheckmark: pick?.animateCheckmark,
      enableHaptic: pick?.enableHaptic,
    );
  }
}

extension ChipStyleResolve on ChipStyle {
  /// Stacks `caller > theme > defaults`, then fills colours from
  /// `context.<group>Colors` for ONE state of ONE variant.
  ///
  /// [selected], [enabled] and [variant] are arguments rather than
  /// fields because a chip's colours are a function of all three: the
  /// same bag paints a resting outlined chip and a selected tonal one
  /// differently, and Material needs both fills at once so it can
  /// cross-fade them itself.
  ///
  /// [disableAnimations] collapses the transitions to zero rather than
  /// shortening them.
  ResolvedChipStyle resolve(
    BuildContext context, {
    required ChipVariant variant,
    bool selected = false,
    bool enabled = true,
    bool disableAnimations = false,
  }) {
    final merged = ChipStyle.defaults
        .mergedWith(GlobalChipTheme.maybeOf(context)?.style)
        .mergedWith(this);
    const floor = ChipStyle.defaults;

    final primary = context.primaryColors.primary;
    final text = context.textColors;
    final outline = context.backgroundColors.outline;
    final surface = context.backgroundColors.inputBackground;

    final disabledFill =
        merged.disabledColor ??
        surface.withValues(alpha: ChipDefaults.disabledOpacity);

    // Which fills the variant uses at rest and when selected. The
    // gradient path paints its own box, so it only needs these as the
    // fallback colour behind a gradient that has not loaded a shader.
    final (Color rest, Color chosen) = switch (variant) {
      ChipVariant.filled => (
        merged.backgroundColor ?? surface,
        merged.selectedColor ?? primary,
      ),
      ChipVariant.outlined => (
        merged.backgroundColor ?? Colors.transparent,
        merged.selectedColor ??
            primary.withValues(alpha: ChipDefaults.outlinedSelectedOpacity),
      ),
      ChipVariant.tonal => (
        merged.backgroundColor ??
            primary.withValues(alpha: ChipDefaults.tonalOpacity),
        merged.selectedColor ??
            primary.withValues(alpha: ChipDefaults.tonalSelectedOpacity),
      ),
    };

    // A selected FILLED chip sits on the brand colour, so its label
    // takes on-primary; outlined and tonal keep a tinted surface, so
    // they take the brand colour itself.
    final selectedLabel =
        merged.selectedLabelColor ??
        (variant == ChipVariant.filled ? text.onPrimary : primary);

    final foreground = !enabled
        ? (merged.disabledLabelColor ?? text.disabled)
        : (selected ? selectedLabel : (merged.labelColor ?? text.primary));

    final borderWidth = merged.borderWidth ?? floor.borderWidth!;
    final border = !enabled
        ? BorderSide(
            color: outline.withValues(
              alpha: ChipDefaults.disabledBorderOpacity,
            ),
          )
        : switch (variant) {
            // A selected filled chip has no border: the fill IS the
            // shape, and an outline on top of it reads as a second
            // control.
            ChipVariant.filled =>
              selected
                  ? BorderSide.none
                  : BorderSide(
                      color:
                          merged.borderColor ??
                          outline.withValues(
                            alpha: ChipDefaults.restingBorderOpacity,
                          ),
                      width: borderWidth,
                    ),
            ChipVariant.outlined => BorderSide(
              color: selected
                  ? (merged.selectedBorderColor ?? primary)
                  : (merged.borderColor ??
                        outline.withValues(
                          alpha: ChipDefaults.outlinedBorderOpacity,
                        )),
              width: borderWidth,
            ),
            ChipVariant.tonal => BorderSide.none,
          };

    final duration = disableAnimations
        ? Duration.zero
        : merged.animationDuration ?? floor.animationDuration!;

    return ResolvedChipStyle(
      background: enabled ? rest : disabledFill,
      selectedBackground: enabled ? chosen : disabledFill,
      disabledBackground: disabledFill,
      foreground: foreground,
      border: border,
      labelStyle:
          (merged.labelStyle ??
                  context.textTheme.bodyMedium ??
                  const TextStyle())
              .copyWith(
                color: foreground,
                // Weight, not colour, is what makes a selected chip read
                // as chosen on a tonal or outlined variant, where the
                // fill barely changes.
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
      labelPadding: merged.labelPadding ?? floor.labelPadding!,
      padding: merged.padding,
      borderRadius: merged.borderRadius ?? floor.borderRadius!,
      borderWidth: borderWidth,
      elevation: selected
          ? (merged.selectedElevation ?? floor.selectedElevation!)
          : (merged.elevation ?? floor.elevation!),
      checkmarkColor: merged.checkmarkColor ?? foreground,
      deleteIconColor: merged.deleteIconColor ?? foreground,
      countBackground: foreground.withValues(
        alpha: ChipDefaults.countBackgroundOpacity,
      ),
      animationDuration: duration,
      animationCurve: merged.animationCurve ?? floor.animationCurve!,
      deleteAnimationDuration: disableAnimations
          ? Duration.zero
          : merged.deleteAnimationDuration ?? floor.deleteAnimationDuration!,
      // Under reduced motion the checkmark still appears; it just does
      // not spring in.
      animateCheckmark:
          !disableAnimations &&
          (merged.animateCheckmark ?? floor.animateCheckmark!),
      enableHaptic: merged.enableHaptic ?? floor.enableHaptic!,
      hasGradient: merged.hasGradient,
      backgroundGradient: selected
          ? (merged.selectedBackgroundGradient ?? merged.backgroundGradient)
          : merged.backgroundGradient,
      borderGradient: selected
          ? (merged.selectedBorderGradient ?? merged.borderGradient)
          : merged.borderGradient,
      shadowColor: selected
          ? (merged.selectedShadowColor ?? merged.shadowColor)
          : merged.shadowColor,
    );
  }
}
