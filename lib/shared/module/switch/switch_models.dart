import 'package:flutter/material.dart';

import '../../../core/animations/animation_presets.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import 'theme/switch_theme.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

const kSwitchDefaultWidth = 60.0;
const kSwitchDefaultHeight = 32.0;
const kSwitchDefaultThumbPadding = 4.0;
const kSwitchDefaultAnimDuration = AppDurations.normal;
const kSwitchDefaultElevation = 2.0;
const kSwitchDefaultThumbShadowBlur = 4.0;
const kSwitchDefaultThumbShadowAlpha = 0.15;
const kSwitchDefaultTrackShadowAlpha = 0.2;
const kSwitchDefaultDisabledOpacity = 0.5;
const kSwitchLabelSpacing = 8.0;
const kSwitchDefaultLabelFontSize = 14.0;
const kSwitchDefaultLabelFontWeight = FontWeight.w500;
const kSwitchInactiveLabelOpacity = 0.5;
const kSwitchDebounceDuration = AppDurations.normal;
const kSwitchM3ThumbGrowth = 4.0;
const kSwitchPulseScale = 1.15;
const kSwitchPulseDuration = Duration(milliseconds: 800);
const kSwitchHoverOpacity = 0.08;
const kSwitchFocusOpacity = 0.12;
const kSwitchDragThreshold = 0.5;
const kSwitchThumbTextFontSizeFactor = 0.35;

// ---------------------------------------------------------------------------
// SwitchSize — preset sizes
// ---------------------------------------------------------------------------

enum SwitchSize {
  small(width: 40, height: 22, thumbSize: 16),
  medium(width: 56, height: 30, thumbSize: 24),
  large(width: 72, height: 40, thumbSize: 32);

  const SwitchSize({
    required this.width,
    required this.height,
    required this.thumbSize,
  });
  final double width;
  final double height;
  final double thumbSize;
}

// ---------------------------------------------------------------------------
// ThumbShape
// ---------------------------------------------------------------------------

enum ThumbShape {
  circle,
  roundedRect,
  squircle,
}

// ---------------------------------------------------------------------------
// TrackShape
// ---------------------------------------------------------------------------

enum TrackShape {
  /// Default pill shape (borderRadius = height/2).
  pill,

  /// Rounded rectangle with smaller radius.
  roundedRect,

  /// Stadium/rectangle with very small radius.
  rectangle,
}

// ---------------------------------------------------------------------------
// SwitchStyle — themeable bag
// ---------------------------------------------------------------------------

/// Themeable visuals for `GlobalSwitch` — the analogue of
/// `CheckboxStyle` / `TextFieldStyle`.
///
/// Every field nullable; resolution stacks
/// `caller > GlobalSwitchTheme.style > defaults`, then fills color
/// fallbacks from `context.<group>Colors`. See [resolve]. Content
/// (icons, labels, thumb text) and behavior (drag, debounce, loading)
/// stay widget-side — this bag owns only how the switch LOOKS.
@immutable
class SwitchStyle {
  const SwitchStyle({
    // Dimensions
    this.width,
    this.height,
    this.thumbSize,
    this.padding,
    this.borderRadius,
    this.trackShape,
    this.customTrackBorderRadius,
    this.thumbShape,
    this.customThumbBorderRadius,
    // Track colors / gradients
    this.activeColor,
    this.inactiveColor,
    this.gradient,
    this.activeGradient,
    this.inactiveGradient,
    // Thumb colors / gradients
    this.thumbColor,
    this.activeThumbColor,
    this.inactiveThumbColor,
    this.thumbGradient,
    this.activeThumbGradient,
    this.inactiveThumbGradient,
    // Border
    this.borderWidth,
    this.borderColor,
    this.activeBorderColor,
    this.inactiveBorderColor,
    this.borderGradient,
    this.activeBorderGradient,
    this.inactiveBorderGradient,
    // Elevation & shadows
    this.elevation,
    this.shadowColor,
    this.thumbShadow,
    // Animation
    this.animationDuration,
    this.animationCurve,
    this.animateThumbSize,
    // Icon / text styling
    this.iconSize,
    this.iconColor,
    this.activeIconColor,
    this.inactiveIconColor,
    this.labelStyle,
    this.trackLabelStyle,
    this.thumbTextStyle,
    // Interaction visuals
    this.enableHaptic,
    this.hoverColor,
    this.focusColor,
    this.pulseColor,
  });

  // ─── Dimensions ────────────────────────────────────────────

  final double? width;
  final double? height;

  /// Null → `height - 2 * thumb padding`.
  final double? thumbSize;
  final EdgeInsets? padding;

  /// Legacy circular track radius shortcut. Wins over [trackShape];
  /// [customTrackBorderRadius] wins over both.
  final double? borderRadius;
  final TrackShape? trackShape;
  final BorderRadius? customTrackBorderRadius;
  final ThumbShape? thumbShape;

  /// Overrides [thumbShape] when set (asymmetric shapes).
  final BorderRadius? customThumbBorderRadius;

  // ─── Track colors ──────────────────────────────────────────

  /// Default: `context.primaryColors.primary`.
  final Color? activeColor;

  /// Default: outline at 30%.
  final Color? inactiveColor;
  final Gradient? gradient;
  final Gradient? activeGradient;
  final Gradient? inactiveGradient;

  // ─── Thumb colors ──────────────────────────────────────────

  /// State-independent thumb color — wins over the per-state pair.
  /// Default: `context.textColors.onPrimary`.
  final Color? thumbColor;
  final Color? activeThumbColor;
  final Color? inactiveThumbColor;
  final Gradient? thumbGradient;
  final Gradient? activeThumbGradient;
  final Gradient? inactiveThumbGradient;

  // ─── Border ────────────────────────────────────────────────

  final double? borderWidth;
  final Color? borderColor;
  final Color? activeBorderColor;
  final Color? inactiveBorderColor;
  final Gradient? borderGradient;
  final Gradient? activeBorderGradient;
  final Gradient? inactiveBorderGradient;

  // ─── Elevation & shadows ───────────────────────────────────

  final double? elevation;
  final Color? shadowColor;
  final bool? thumbShadow;

  // ─── Animation ─────────────────────────────────────────────

  /// Reduced motion collapses it to zero regardless.
  final Duration? animationDuration;
  final Curve? animationCurve;

  /// Thumb slightly grows when active (Material 3 style).
  final bool? animateThumbSize;

  // ─── Icon / text styling ───────────────────────────────────

  final double? iconSize;
  final Color? iconColor;
  final Color? activeIconColor;
  final Color? inactiveIconColor;
  final TextStyle? labelStyle;
  final TextStyle? trackLabelStyle;
  final TextStyle? thumbTextStyle;

  // ─── Interaction visuals ───────────────────────────────────

  /// Haptic on toggle. Default `true`.
  final bool? enableHaptic;

  /// Hover overlay (web/desktop). Null → active color at 8%.
  final Color? hoverColor;

  /// Focus ring overlay. Null → active color at 12%.
  final Color? focusColor;

  /// Pulse-on-mount ring color. Null → the active color.
  final Color? pulseColor;

  /// Compile-time floor (colors excepted — they resolve from context).
  static const SwitchStyle defaults = SwitchStyle(
    width: kSwitchDefaultWidth,
    height: kSwitchDefaultHeight,
    padding: EdgeInsets.all(kSwitchDefaultThumbPadding),
    trackShape: TrackShape.pill,
    thumbShape: ThumbShape.circle,
    borderWidth: 0,
    elevation: kSwitchDefaultElevation,
    thumbShadow: true,
    animationDuration: kSwitchDefaultAnimDuration,
    animationCurve: Curves.easeInOut,
    animateThumbSize: false,
    enableHaptic: true,
  );

  /// Field-by-field overlay: `other` wins where non-null.
  SwitchStyle mergedWith(SwitchStyle? other) {
    if (other == null) return this;
    return SwitchStyle(
      width: other.width ?? width,
      height: other.height ?? height,
      thumbSize: other.thumbSize ?? thumbSize,
      padding: other.padding ?? padding,
      borderRadius: other.borderRadius ?? borderRadius,
      trackShape: other.trackShape ?? trackShape,
      customTrackBorderRadius:
          other.customTrackBorderRadius ?? customTrackBorderRadius,
      thumbShape: other.thumbShape ?? thumbShape,
      customThumbBorderRadius:
          other.customThumbBorderRadius ?? customThumbBorderRadius,
      activeColor: other.activeColor ?? activeColor,
      inactiveColor: other.inactiveColor ?? inactiveColor,
      gradient: other.gradient ?? gradient,
      activeGradient: other.activeGradient ?? activeGradient,
      inactiveGradient: other.inactiveGradient ?? inactiveGradient,
      thumbColor: other.thumbColor ?? thumbColor,
      activeThumbColor: other.activeThumbColor ?? activeThumbColor,
      inactiveThumbColor: other.inactiveThumbColor ?? inactiveThumbColor,
      thumbGradient: other.thumbGradient ?? thumbGradient,
      activeThumbGradient: other.activeThumbGradient ?? activeThumbGradient,
      inactiveThumbGradient:
          other.inactiveThumbGradient ?? inactiveThumbGradient,
      borderWidth: other.borderWidth ?? borderWidth,
      borderColor: other.borderColor ?? borderColor,
      activeBorderColor: other.activeBorderColor ?? activeBorderColor,
      inactiveBorderColor: other.inactiveBorderColor ?? inactiveBorderColor,
      borderGradient: other.borderGradient ?? borderGradient,
      activeBorderGradient: other.activeBorderGradient ?? activeBorderGradient,
      inactiveBorderGradient:
          other.inactiveBorderGradient ?? inactiveBorderGradient,
      elevation: other.elevation ?? elevation,
      shadowColor: other.shadowColor ?? shadowColor,
      thumbShadow: other.thumbShadow ?? thumbShadow,
      animationDuration: other.animationDuration ?? animationDuration,
      animationCurve: other.animationCurve ?? animationCurve,
      animateThumbSize: other.animateThumbSize ?? animateThumbSize,
      iconSize: other.iconSize ?? iconSize,
      iconColor: other.iconColor ?? iconColor,
      activeIconColor: other.activeIconColor ?? activeIconColor,
      inactiveIconColor: other.inactiveIconColor ?? inactiveIconColor,
      labelStyle: other.labelStyle ?? labelStyle,
      trackLabelStyle: other.trackLabelStyle ?? trackLabelStyle,
      thumbTextStyle: other.thumbTextStyle ?? thumbTextStyle,
      enableHaptic: other.enableHaptic ?? enableHaptic,
      hoverColor: other.hoverColor ?? hoverColor,
      focusColor: other.focusColor ?? focusColor,
      pulseColor: other.pulseColor ?? pulseColor,
    );
  }

  /// Creates a copy with the given fields replaced.
  SwitchStyle copyWith({
    double? width,
    double? height,
    double? thumbSize,
    EdgeInsets? padding,
    double? borderRadius,
    TrackShape? trackShape,
    BorderRadius? customTrackBorderRadius,
    ThumbShape? thumbShape,
    BorderRadius? customThumbBorderRadius,
    Color? activeColor,
    Color? inactiveColor,
    Gradient? gradient,
    Gradient? activeGradient,
    Gradient? inactiveGradient,
    Color? thumbColor,
    Color? activeThumbColor,
    Color? inactiveThumbColor,
    Gradient? thumbGradient,
    Gradient? activeThumbGradient,
    Gradient? inactiveThumbGradient,
    double? borderWidth,
    Color? borderColor,
    Color? activeBorderColor,
    Color? inactiveBorderColor,
    Gradient? borderGradient,
    Gradient? activeBorderGradient,
    Gradient? inactiveBorderGradient,
    double? elevation,
    Color? shadowColor,
    bool? thumbShadow,
    Duration? animationDuration,
    Curve? animationCurve,
    bool? animateThumbSize,
    double? iconSize,
    Color? iconColor,
    Color? activeIconColor,
    Color? inactiveIconColor,
    TextStyle? labelStyle,
    TextStyle? trackLabelStyle,
    TextStyle? thumbTextStyle,
    bool? enableHaptic,
    Color? hoverColor,
    Color? focusColor,
    Color? pulseColor,
  }) {
    return mergedWith(
      SwitchStyle(
        width: width,
        height: height,
        thumbSize: thumbSize,
        padding: padding,
        borderRadius: borderRadius,
        trackShape: trackShape,
        customTrackBorderRadius: customTrackBorderRadius,
        thumbShape: thumbShape,
        customThumbBorderRadius: customThumbBorderRadius,
        activeColor: activeColor,
        inactiveColor: inactiveColor,
        gradient: gradient,
        activeGradient: activeGradient,
        inactiveGradient: inactiveGradient,
        thumbColor: thumbColor,
        activeThumbColor: activeThumbColor,
        inactiveThumbColor: inactiveThumbColor,
        thumbGradient: thumbGradient,
        activeThumbGradient: activeThumbGradient,
        inactiveThumbGradient: inactiveThumbGradient,
        borderWidth: borderWidth,
        borderColor: borderColor,
        activeBorderColor: activeBorderColor,
        inactiveBorderColor: inactiveBorderColor,
        borderGradient: borderGradient,
        activeBorderGradient: activeBorderGradient,
        inactiveBorderGradient: inactiveBorderGradient,
        elevation: elevation,
        shadowColor: shadowColor,
        thumbShadow: thumbShadow,
        animationDuration: animationDuration,
        animationCurve: animationCurve,
        animateThumbSize: animateThumbSize,
        iconSize: iconSize,
        iconColor: iconColor,
        activeIconColor: activeIconColor,
        inactiveIconColor: inactiveIconColor,
        labelStyle: labelStyle,
        trackLabelStyle: trackLabelStyle,
        thumbTextStyle: thumbTextStyle,
        enableHaptic: enableHaptic,
        hoverColor: hoverColor,
        focusColor: focusColor,
        pulseColor: pulseColor,
      ),
    );
  }

  /// Materialize: `defaults → GlobalSwitchTheme → this`, then context
  /// color fallbacks. [size] (the widget's preset) wins over the bag's
  /// dimensions. Call once per build.
  ResolvedSwitchStyle resolve(BuildContext context, {SwitchSize? size}) {
    final theme = GlobalSwitchTheme.maybeOf(context);
    final s = defaults.mergedWith(theme?.style).mergedWith(this);
    final active = s.activeColor ?? context.primaryColors.primary;
    final height = size?.height ?? s.height!;
    return ResolvedSwitchStyle._(
      width: size?.width ?? s.width!,
      height: height,
      thumbSize:
          size?.thumbSize ??
          s.thumbSize ??
          (height - kSwitchDefaultThumbPadding * 2),
      padding: s.padding!,
      borderRadius: s.borderRadius,
      trackShape: s.trackShape!,
      customTrackBorderRadius: s.customTrackBorderRadius,
      thumbShape: s.thumbShape!,
      customThumbBorderRadius: s.customThumbBorderRadius,
      activeColor: active,
      inactiveColor:
          s.inactiveColor ??
          context.backgroundColors.outline.withValues(alpha: 0.3),
      gradient: s.gradient,
      activeGradient: s.activeGradient,
      inactiveGradient: s.inactiveGradient,
      thumbColor: s.thumbColor,
      activeThumbColor: s.activeThumbColor,
      inactiveThumbColor: s.inactiveThumbColor,
      defaultThumbColor: context.textColors.onPrimary,
      thumbGradient: s.thumbGradient,
      activeThumbGradient: s.activeThumbGradient,
      inactiveThumbGradient: s.inactiveThumbGradient,
      borderWidth: s.borderWidth!,
      borderColor: s.borderColor,
      activeBorderColor: s.activeBorderColor,
      inactiveBorderColor: s.inactiveBorderColor,
      borderGradient: s.borderGradient,
      activeBorderGradient: s.activeBorderGradient,
      inactiveBorderGradient: s.inactiveBorderGradient,
      elevation: s.elevation!,
      shadowColor: s.shadowColor,
      thumbShadow: s.thumbShadow!,
      animationDuration: s.animationDuration!,
      animationCurve: s.animationCurve!,
      animateThumbSize: s.animateThumbSize!,
      iconSize: s.iconSize,
      iconColor: s.iconColor,
      activeIconColor: s.activeIconColor,
      inactiveIconColor: s.inactiveIconColor,
      labelStyle: s.labelStyle,
      trackLabelStyle: s.trackLabelStyle,
      thumbTextStyle: s.thumbTextStyle,
      enableHaptic: s.enableHaptic!,
      hoverColor: s.hoverColor ?? active.withValues(alpha: kSwitchHoverOpacity),
      focusColor: s.focusColor ?? active.withValues(alpha: kSwitchFocusOpacity),
      pulseColor: s.pulseColor ?? active,
      onPrimary: context.textColors.onPrimary,
      secondaryText: context.textColors.secondary,
    );
  }
}

/// Non-null snapshot of [SwitchStyle] after [SwitchStyle.resolve]
/// (genuinely opt-in fields — gradients, per-state overrides, custom
/// radii, text styles — stay nullable).
@immutable
class ResolvedSwitchStyle {
  const ResolvedSwitchStyle._({
    required this.width,
    required this.height,
    required this.thumbSize,
    required this.padding,
    required this.borderRadius,
    required this.trackShape,
    required this.customTrackBorderRadius,
    required this.thumbShape,
    required this.customThumbBorderRadius,
    required this.activeColor,
    required this.inactiveColor,
    required this.gradient,
    required this.activeGradient,
    required this.inactiveGradient,
    required this.thumbColor,
    required this.activeThumbColor,
    required this.inactiveThumbColor,
    required this.defaultThumbColor,
    required this.thumbGradient,
    required this.activeThumbGradient,
    required this.inactiveThumbGradient,
    required this.borderWidth,
    required this.borderColor,
    required this.activeBorderColor,
    required this.inactiveBorderColor,
    required this.borderGradient,
    required this.activeBorderGradient,
    required this.inactiveBorderGradient,
    required this.elevation,
    required this.shadowColor,
    required this.thumbShadow,
    required this.animationDuration,
    required this.animationCurve,
    required this.animateThumbSize,
    required this.iconSize,
    required this.iconColor,
    required this.activeIconColor,
    required this.inactiveIconColor,
    required this.labelStyle,
    required this.trackLabelStyle,
    required this.thumbTextStyle,
    required this.enableHaptic,
    required this.hoverColor,
    required this.focusColor,
    required this.pulseColor,
    required this.onPrimary,
    required this.secondaryText,
  });

  final double width;
  final double height;
  final double thumbSize;
  final EdgeInsets padding;
  final double? borderRadius;
  final TrackShape trackShape;
  final BorderRadius? customTrackBorderRadius;
  final ThumbShape thumbShape;
  final BorderRadius? customThumbBorderRadius;
  final Color activeColor;
  final Color inactiveColor;
  final Gradient? gradient;
  final Gradient? activeGradient;
  final Gradient? inactiveGradient;
  final Color? thumbColor;
  final Color? activeThumbColor;
  final Color? inactiveThumbColor;

  /// Context fallback when no thumb color override is set.
  final Color defaultThumbColor;
  final Gradient? thumbGradient;
  final Gradient? activeThumbGradient;
  final Gradient? inactiveThumbGradient;
  final double borderWidth;
  final Color? borderColor;
  final Color? activeBorderColor;
  final Color? inactiveBorderColor;
  final Gradient? borderGradient;
  final Gradient? activeBorderGradient;
  final Gradient? inactiveBorderGradient;
  final double elevation;
  final Color? shadowColor;
  final bool thumbShadow;
  final Duration animationDuration;
  final Curve animationCurve;
  final bool animateThumbSize;
  final double? iconSize;
  final Color? iconColor;
  final Color? activeIconColor;
  final Color? inactiveIconColor;
  final TextStyle? labelStyle;
  final TextStyle? trackLabelStyle;
  final TextStyle? thumbTextStyle;
  final bool enableHaptic;
  final Color hoverColor;
  final Color focusColor;
  final Color pulseColor;

  /// `context.textColors.onPrimary` — track-label / thumb fallbacks.
  final Color onPrimary;

  /// `context.textColors.secondary` — inactive thumb-text fallback.
  final Color secondaryText;
}
