import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/theme_colors_extension.dart';
import '../stepper_models.dart';
import '../stepper_style.dart';

/// App-wide defaults for [GlobalStepper].
///
/// The rebrand hook: set the indicator's size, the connector's weight
/// and the type once, here, and every stepper in the app follows —
/// including the ones `GlobalWizard` builds for its `numbered` and
/// `vertical` variants.
@immutable
class GlobalStepperTheme extends ThemeExtension<GlobalStepperTheme> {
  const GlobalStepperTheme({this.style});

  final StepperStyle? style;

  static GlobalStepperTheme? maybeOf(BuildContext context) =>
      Theme.of(context).extension<GlobalStepperTheme>();

  @override
  GlobalStepperTheme copyWith({StepperStyle? style}) =>
      GlobalStepperTheme(style: style ?? this.style);

  @override
  GlobalStepperTheme lerp(ThemeExtension<GlobalStepperTheme>? other, double t) {
    if (other is! GlobalStepperTheme) return this;
    // A style is a bag of independent decisions, not a value with a
    // midpoint — half a `filledIndicator` means nothing. It SNAPS at
    // the halfway mark, which is what every other bag in this app does.
    return t < 0.5 ? this : other;
  }
}

/// Turns a caller's bag into one with every question answered.
extension StepperStyleResolve on StepperStyle {
  /// `caller > GlobalStepperTheme.style > StepperStyle.defaults`, then
  /// the colours from the palette.
  ///
  /// It read `Theme.of(context).colorScheme` for every colour, wrote
  /// `Colors.white` inside a filled indicator, and took the interior
  /// from `scaffoldBackgroundColor` — so a rebrand moved the app and
  /// left the stepper where it was, and a pale brand accent put white
  /// glyphs on a white circle.
  ResolvedStepperStyle resolve(BuildContext context) {
    final merged = StepperStyle.defaults
        .mergedWith(GlobalStepperTheme.maybeOf(context)?.style)
        .mergedWith(this);

    final primary = context.primaryColors.primary;
    final text = context.textColors;
    final bg = context.backgroundColors;
    final status = context.statusColors;
    final textTheme = context.textTheme;

    final active = merged.activeColor ?? primary;
    final completed = merged.completedColor ?? primary;

    return ResolvedStepperStyle(
      // ─── Colours ───────────────────────────────────────────
      activeColor: active,
      completedColor: completed,
      inactiveColor:
          merged.inactiveColor ??
          text.primary.withValues(alpha: StepperDefaults.inactiveOpacity),
      errorColor: merged.errorColor ?? status.error,
      disabledColor:
          merged.disabledColor ??
          text.primary.withValues(alpha: StepperDefaults.disabledColorOpacity),
      // The PAGE, not the card: the connector runs behind the
      // indicator, and an interior that does not match what is behind
      // it draws the line straight through the circle.
      surfaceColor: merged.surfaceColor ?? bg.scaffoldBackground,

      // ─── Indicator ─────────────────────────────────────────
      indicatorSize: merged.indicatorSize ?? StepperDefaults.indicatorSize,
      indicatorBorderWidth:
          merged.indicatorBorderWidth ?? StepperDefaults.indicatorBorderWidth,
      indicatorGradient: merged.indicatorGradient,
      // No colour here: a filled indicator takes what reads ON the
      // step's colour and an outlined one takes the step's colour
      // itself, and only the widget knows which a given step is.
      indicatorTextStyle:
          merged.indicatorTextStyle ??
          (textTheme.labelSmall ?? const TextStyle()).copyWith(
            fontSize: StepperDefaults.indicatorFontSize,
            fontWeight: FontWeight.w700,
          ),
      filledIndicator: merged.filledIndicator ?? false,
      showCheckmark: merged.showCheckmark ?? true,
      showStepNumber: merged.showStepNumber ?? true,

      // ─── Connector ─────────────────────────────────────────
      connectorStyle: merged.connectorStyle ?? StepperConnectorStyle.solid,
      connectorThickness:
          merged.connectorThickness ?? StepperDefaults.connectorThickness,
      connectorColor: merged.connectorColor,
      connectorGradient: merged.connectorGradient,
      connectorInset: merged.connectorInset ?? StepperDefaults.connectorInset,
      connectorDashWidth:
          merged.connectorDashWidth ?? StepperDefaults.connectorDashWidth,
      connectorDashGap:
          merged.connectorDashGap ?? StepperDefaults.connectorDashGap,
      connectorProgress: merged.connectorProgress,
      connectorLabelStyle:
          merged.connectorLabelStyle ??
          (textTheme.labelSmall ?? const TextStyle()).copyWith(
            fontSize: StepperDefaults.connectorLabelFontSize,
            fontWeight: FontWeight.w500,
            color: text.secondary,
          ),
      connectorBuilder: merged.connectorBuilder,

      // ─── Type ──────────────────────────────────────────────
      // No colour on either title style: it comes from the STEP's
      // state, which changes as the reader moves. A caller who sets
      // one wins, per step, in the widget.
      titleStyle:
          merged.titleStyle ??
          (textTheme.bodySmall ?? const TextStyle()).copyWith(
            fontSize: StepperDefaults.titleFontSize,
            fontWeight: FontWeight.w400,
          ),
      activeTitleStyle:
          merged.activeTitleStyle ??
          merged.titleStyle ??
          (textTheme.bodySmall ?? const TextStyle()).copyWith(
            fontSize: StepperDefaults.titleFontSize,
            fontWeight: FontWeight.w600,
          ),
      subtitleStyle:
          merged.subtitleStyle ??
          (textTheme.labelSmall ?? const TextStyle()).copyWith(
            fontSize: StepperDefaults.subtitleFontSize,
          ),
      timestampStyle:
          merged.timestampStyle ??
          (textTheme.labelSmall ?? const TextStyle()).copyWith(
            fontSize: StepperDefaults.timestampFontSize,
            color: text.secondary.withValues(
              alpha: StepperDefaults.timestampOpacity,
            ),
          ),

      // ─── Motion ────────────────────────────────────────────
      animated: merged.animated ?? true,
      animationDuration:
          merged.animationDuration ?? StepperDefaults.animationDuration,
      sequentialAnimation: merged.sequentialAnimation ?? true,
      contentTransition:
          merged.contentTransition ?? StepContentTransition.fadeSlide,

      // ─── Layout ────────────────────────────────────────────
      spacing: merged.spacing ?? 0,
      contentPadding:
          merged.contentPadding ??
          const EdgeInsets.only(top: StepperDefaults.contentPadTop),
      collapsible: merged.collapsible ?? false,
      scrollable: merged.scrollable ?? false,
      scrollableStepWidth:
          merged.scrollableStepWidth ?? StepperDefaults.scrollableStepWidth,

      // ─── Focus ─────────────────────────────────────────────
      // The accent, so the ring reads against a filled indicator and
      // an outlined one alike.
      focusColor: merged.focusColor ?? active,
      focusRingWidth: merged.focusRingWidth ?? StepperDefaults.focusRingWidth,

      // ─── Behaviour ─────────────────────────────────────────
      enableHaptic: merged.enableHaptic ?? true,
      disabledOpacity:
          merged.disabledOpacity ?? StepperDefaults.disabledOpacity,
    );
  }
}
