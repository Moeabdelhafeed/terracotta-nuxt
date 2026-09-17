import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/theme_colors_extension.dart';
import '../../../../core/tokens/extensions.dart';
import '../slider_models.dart';
import '../slider_style.dart';

/// App-wide defaults for [GlobalSlider].
///
/// The rebrand hook: set the track's weight, the thumb's size and the
/// card the slider sits on once, here, and every slider in the app
/// follows.
@immutable
class GlobalSliderTheme extends ThemeExtension<GlobalSliderTheme> {
  const GlobalSliderTheme({this.style});

  final SliderStyle? style;

  static GlobalSliderTheme? maybeOf(BuildContext context) =>
      Theme.of(context).extension<GlobalSliderTheme>();

  @override
  GlobalSliderTheme copyWith({SliderStyle? style}) =>
      GlobalSliderTheme(style: style ?? this.style);

  @override
  GlobalSliderTheme lerp(ThemeExtension<GlobalSliderTheme>? other, double t) {
    if (other is! GlobalSliderTheme) return this;
    // A style is a bag of independent decisions, not a value with a
    // midpoint — half a `showTicks` means nothing. It SNAPS at the
    // halfway mark, which is what every other bag in this app does.
    return t < 0.5 ? this : other;
  }
}

/// Turns a caller's bag into one with every question answered.
extension SliderStyleResolve on SliderStyle {
  /// `caller > GlobalSliderTheme.style > SliderStyle.defaults`, then the
  /// colours from the palette.
  ///
  /// It read `Theme.of(context).colorScheme` for every colour and wrote
  /// `Colors.white`, `Colors.black` and `Colors.grey` in five places —
  /// so a rebrand moved the app and left the slider where it was, and a
  /// gradient thumb's inner ring stayed white on a white card.
  ResolvedSliderStyle resolve(BuildContext context) {
    final merged = SliderStyle.defaults
        .mergedWith(GlobalSliderTheme.maybeOf(context)?.style)
        .mergedWith(this);

    final primary = context.primaryColors.primary;
    final text = context.textColors;
    final bg = context.backgroundColors;
    final spacing = context.spacing;
    final radii = context.radii;
    final textTheme = context.textTheme;

    final accent = merged.activeColor ?? primary;
    final trackHeight = merged.trackHeight ?? SliderDefaults.trackHeight;

    return ResolvedSliderStyle(
      // ─── Track ─────────────────────────────────────────────
      activeColor: accent,
      inactiveColor:
          merged.inactiveColor ??
          bg.outline.withValues(alpha: SliderDefaults.inactiveTrackOpacity),
      trackGradient: merged.trackGradient,
      trackHeight: trackHeight,
      trackRadius:
          merged.trackRadius ?? trackHeight * SliderDefaults.trackRadiusFactor,
      // NOTHING by default: the track runs the full width it is given
      // and the thumb overhangs into whatever the slider sits in.
      trackEndInset: merged.trackEndInset ?? SliderDefaults.trackEndInset,

      // ─── Thumb ─────────────────────────────────────────────
      // The thumb sits ON the track, so it takes the page's own
      // surface rather than the container's — a thumb the colour of
      // the card it is on disappears the moment the card is tinted.
      thumbColor: merged.thumbColor ?? bg.surface,
      thumbBorderColor: merged.thumbBorderColor ?? text.onPrimary,
      thumbGradient: merged.thumbGradient,
      thumbRadius: merged.thumbRadius ?? SliderDefaults.thumbRadius,
      thumbElevation: merged.thumbElevation ?? SliderDefaults.thumbElevation,
      overlayRadius: merged.overlayRadius ?? SliderDefaults.overlayRadius,

      // ─── Segments ──────────────────────────────────────────
      segmentGap: merged.segmentGap ?? SliderDefaults.segmentGap,
      secondaryColor:
          merged.secondaryColor ??
          accent.withValues(alpha: SliderDefaults.secondaryTrackOpacity),

      // ─── Circular ──────────────────────────────────────────
      ringThickness: merged.ringThickness ?? SliderDefaults.ringThickness,
      ringDiameter: merged.ringDiameter ?? SliderDefaults.ringDiameter,
      ringThumbRadius: merged.ringThumbRadius ?? SliderDefaults.ringThumbRadius,
      ringCapped: merged.ringCapped ?? true,
      // The band a finger may land in: never less than the floor, and
      // always at least the ring plus its thumb — a thick ring has a
      // bigger target and should accept one.
      ringTouchSlop:
          merged.ringTouchSlop ??
          math.max(
            SliderDefaults.ringTouchSlop,
            (merged.ringThickness ?? SliderDefaults.ringThickness) / 2 +
                (merged.ringThumbRadius ?? SliderDefaults.ringThumbRadius),
          ),

      // ─── Trim ──────────────────────────────────────────────
      trimHandleWidth: merged.trimHandleWidth ?? SliderDefaults.trimHandleWidth,
      trimHandleTouchSlop:
          merged.trimHandleTouchSlop ?? SliderDefaults.trimHandleTouchSlop,
      trimRailHeight: merged.trimRailHeight ?? SliderDefaults.trimRailHeight,
      trimPlayheadWidth:
          merged.trimPlayheadWidth ?? SliderDefaults.trimPlayheadWidth,
      // The playhead and the grips sit ON the accent, so they take
      // what reads on it — not `Colors.white`, which vanishes the
      // moment a brand's accent is pale.
      trimPlayheadColor: merged.trimPlayheadColor ?? text.onPrimary,
      trimGripColor: merged.trimGripColor ?? text.onPrimary,
      // The scrim covers CONTENT — a filmstrip, a waveform — so it is
      // the overlay palette's, not the page's.
      trimScrimColor:
          merged.trimScrimColor ??
          context.overlayColors.scrim.withValues(
            alpha: SliderDefaults.trimScrimOpacity,
          ),

      // ─── Step labels ───────────────────────────────────────
      stepLabelStyle:
          merged.stepLabelStyle ??
          (textTheme.labelSmall ?? const TextStyle()).copyWith(
            color: text.secondary,
          ),
      stepLabelGap: merged.stepLabelGap ?? spacing.xs,

      // ─── Ticks and indicator ───────────────────────────────
      // A caller who styles ticks gets ticks; a THEME that styles them
      // can still be turned off per call, which `tickStyle: null` alone
      // could not say.
      showTicks: merged.showTicks ?? (merged.tickStyle != null),
      tickStyle: ResolvedSliderTickStyle(
        color: merged.tickStyle?.color ?? bg.outline.withValues(alpha: 0.3),
        // Active ticks sit on the accent, so they take what reads on it.
        activeColor: merged.tickStyle?.activeColor ?? text.onPrimary,
        radius: merged.tickStyle?.radius ?? SliderDefaults.tickRadius,
        shape: merged.tickStyle?.shape ?? SliderTickShape.circle,
      ),
      showValueIndicator: merged.showValueIndicator ?? true,
      indicatorStyle: ResolvedSliderIndicatorStyle(
        shape: merged.indicatorStyle?.shape ?? SliderIndicatorShape.paddle,
        color: merged.indicatorStyle?.color ?? accent,
        gradient: merged.indicatorStyle?.gradient,
        textStyle:
            merged.indicatorStyle?.textStyle ??
            (textTheme.labelSmall ?? const TextStyle()).copyWith(
              color: text.onPrimary,
              fontWeight: FontWeight.w600,
            ),
        borderRadius:
            merged.indicatorStyle?.borderRadius ??
            SliderDefaults.indicatorRadius,
        padding:
            merged.indicatorStyle?.padding ?? SliderDefaults.indicatorPadding,
        arrowSize:
            merged.indicatorStyle?.arrowSize ??
            SliderDefaults.indicatorArrowSize,
        verticalOffset:
            merged.indicatorStyle?.verticalOffset ??
            SliderDefaults.indicatorVerticalOffset,
      ),

      // ─── The box ───────────────────────────────────────────
      showContainer: merged.showContainer ?? true,
      containerDecoration: merged.containerDecoration,
      containerPadding:
          merged.containerPadding ??
          EdgeInsets.symmetric(
            horizontal: spacing.sm,
            vertical: spacing.sm,
          ),
      // A slider's card sits ABOVE the page, the same argument
      // `GlobalContainer` makes for its own fill. It was
      // `isDark ? surfaceContainerHigh : Colors.white`.
      containerColor: merged.containerColor ?? bg.container,
      containerBorderColor: merged.containerBorderColor ?? bg.outlineVariant,
      containerRadius: merged.containerRadius ?? radii.md,
      containerShadow:
          merged.containerShadow ??
          <BoxShadow>[
            BoxShadow(
              color: bg.outline.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],

      // ─── Type ──────────────────────────────────────────────
      labelStyle:
          merged.labelStyle ??
          (textTheme.bodyMedium ?? const TextStyle()).copyWith(
            fontWeight: FontWeight.w600,
            color: text.primary,
          ),
      valueStyle:
          merged.valueStyle ??
          (textTheme.labelSmall ?? const TextStyle()).copyWith(
            fontWeight: FontWeight.w700,
            color: accent,
            // Digits that do not shift the badge as they change — a
            // proportional `1` is narrower than a `0`, and the number
            // jittered under a dragging finger.
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
      minMaxStyle:
          merged.minMaxStyle ??
          (textTheme.labelSmall ?? const TextStyle()).copyWith(
            fontWeight: FontWeight.w500,
            color: text.secondary,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
      valueBadgeColor:
          merged.valueBadgeColor ??
          accent.withValues(alpha: SliderDefaults.badgeFillOpacity),
      valueBadgeBorderColor:
          merged.valueBadgeBorderColor ??
          accent.withValues(alpha: SliderDefaults.badgeBorderOpacity),
      valueBadgeRadius: merged.valueBadgeRadius ?? radii.sm,
      valueBadgePadding:
          merged.valueBadgePadding ??
          EdgeInsets.symmetric(horizontal: spacing.sm, vertical: 3),
      endChipColor:
          merged.endChipColor ??
          bg.outlineVariant.withValues(alpha: SliderDefaults.endChipOpacity),
      endChipRadius: merged.endChipRadius ?? radii.xs,
      endChipPadding:
          merged.endChipPadding ??
          EdgeInsets.symmetric(horizontal: spacing.xs, vertical: 2),

      // ─── Behaviour ─────────────────────────────────────────
      enableHaptic: merged.enableHaptic ?? true,
      disabledOpacity: merged.disabledOpacity ?? SliderDefaults.disabledOpacity,
    );
  }
}
