import 'package:flutter/material.dart';

import '../../../core/animations/animation_presets.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import 'theme/dialog_theme.dart';

/// Type/purpose of the dialog — determines default icon and color.
enum DialogType { info, success, warning, error, custom }

/// Entrance animation for the dialog.
enum DialogAnimation { scale, slideUp, slideDown, fade, none }

/// How the auto-dismiss countdown is displayed.
enum DismissIndicatorStyle {
  /// Linear progress bar at the bottom.
  progressBar,

  /// Animated border that traces the dialog outline.
  borderTrace,
}

/// Styling for [GlobalDialog].
///
/// Every field is nullable — the THEMEABLE bag. Resolution order per
/// field: caller `style:` > [GlobalDialogTheme.style] > [defaults] >
/// `context.<group>Colors`. Materialize once per build via [resolve];
/// widget code reads the [ResolvedDialogStyle] only.
class DialogStyle {
  const DialogStyle({
    this.backgroundColor,
    this.backgroundGradient,
    this.borderRadius,
    this.border,
    this.borderGradient,
    this.borderWidth,
    this.maxWidth,
    this.maxHeight,
    this.padding,
    this.titleStyle,
    this.messageStyle,
    this.shadow,
    this.barrierColor,
    this.animation,
    this.animationDuration,
    this.animationCurve,
    this.dismissIndicator,
    this.enableHaptic,
  });

  /// Non-color scalar defaults. Colors stay null here — they resolve
  /// from `context` in [resolve] (role + saturation aware).
  static const defaults = DialogStyle(
    borderRadius: BorderRadius.all(Radius.circular(20)),
    borderWidth: 1.5,
    maxWidth: 400,
    animation: DialogAnimation.scale,
    animationDuration: AppDurations.quick,
    animationCurve: AppCurves.emphasized,
    dismissIndicator: DismissIndicatorStyle.progressBar,
    enableHaptic: true,
  );

  /// Solid background color. Overridden by [backgroundGradient].
  final Color? backgroundColor;

  /// Gradient background.
  final Gradient? backgroundGradient;

  /// Corner radius.
  final BorderRadius? borderRadius;

  /// Solid border.
  final Border? border;

  /// Gradient border. Takes priority over [border].
  final Gradient? borderGradient;

  /// Width of the gradient border.
  final double? borderWidth;

  final double? maxWidth;
  final double? maxHeight;
  final EdgeInsets? padding;
  final TextStyle? titleStyle;
  final TextStyle? messageStyle;
  final List<BoxShadow>? shadow;

  /// Modal barrier color behind the dialog.
  final Color? barrierColor;

  final DialogAnimation? animation;

  /// Entrance transition length. Reduced motion collapses it to zero
  /// regardless of this value.
  final Duration? animationDuration;

  final Curve? animationCurve;

  /// How the auto-dismiss countdown is displayed.
  final DismissIndicatorStyle? dismissIndicator;

  /// Gates every haptic the dialog emits (close tap).
  final bool? enableHaptic;

  /// Field-wise merge — [other]'s non-null fields win.
  DialogStyle mergedWith(DialogStyle? other) {
    if (other == null) return this;
    return DialogStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      backgroundGradient: other.backgroundGradient ?? backgroundGradient,
      borderRadius: other.borderRadius ?? borderRadius,
      border: other.border ?? border,
      borderGradient: other.borderGradient ?? borderGradient,
      borderWidth: other.borderWidth ?? borderWidth,
      maxWidth: other.maxWidth ?? maxWidth,
      maxHeight: other.maxHeight ?? maxHeight,
      padding: other.padding ?? padding,
      titleStyle: other.titleStyle ?? titleStyle,
      messageStyle: other.messageStyle ?? messageStyle,
      shadow: other.shadow ?? shadow,
      barrierColor: other.barrierColor ?? barrierColor,
      animation: other.animation ?? animation,
      animationDuration: other.animationDuration ?? animationDuration,
      animationCurve: other.animationCurve ?? animationCurve,
      dismissIndicator: other.dismissIndicator ?? dismissIndicator,
      enableHaptic: other.enableHaptic ?? enableHaptic,
    );
  }

  /// Convenience copy — identical field semantics to [mergedWith]
  /// with per-field overrides.
  DialogStyle copyWith({
    Color? backgroundColor,
    Gradient? backgroundGradient,
    BorderRadius? borderRadius,
    Border? border,
    Gradient? borderGradient,
    double? borderWidth,
    double? maxWidth,
    double? maxHeight,
    EdgeInsets? padding,
    TextStyle? titleStyle,
    TextStyle? messageStyle,
    List<BoxShadow>? shadow,
    Color? barrierColor,
    DialogAnimation? animation,
    Duration? animationDuration,
    Curve? animationCurve,
    DismissIndicatorStyle? dismissIndicator,
    bool? enableHaptic,
  }) => mergedWith(
    DialogStyle(
      backgroundColor: backgroundColor,
      backgroundGradient: backgroundGradient,
      borderRadius: borderRadius,
      border: border,
      borderGradient: borderGradient,
      borderWidth: borderWidth,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      padding: padding,
      titleStyle: titleStyle,
      messageStyle: messageStyle,
      shadow: shadow,
      barrierColor: barrierColor,
      animation: animation,
      animationDuration: animationDuration,
      animationCurve: animationCurve,
      dismissIndicator: dismissIndicator,
      enableHaptic: enableHaptic,
    ),
  );

  /// Materializes the final values: caller > theme > defaults >
  /// context colors. Call once per build / show.
  ResolvedDialogStyle resolve(BuildContext context) {
    final themed = GlobalDialogTheme.maybeOf(context)?.style;
    final s = DialogStyle.defaults.mergedWith(themed).mergedWith(this);
    return ResolvedDialogStyle(
      backgroundColor: s.backgroundColor ?? context.backgroundColors.surface,
      backgroundGradient: s.backgroundGradient,
      borderRadius: s.borderRadius!,
      border: s.border,
      borderGradient: s.borderGradient,
      borderWidth: s.borderWidth!,
      maxWidth: s.maxWidth!,
      maxHeight: s.maxHeight,
      padding: s.padding,
      titleStyle: s.titleStyle,
      messageStyle: s.messageStyle,
      shadow: s.shadow,
      barrierColor: s.barrierColor ?? context.overlayColors.barrier,
      animation: MediaQuery.disableAnimationsOf(context)
          ? DialogAnimation.none
          : s.animation!,
      animationDuration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : s.animationDuration!,
      animationCurve: s.animationCurve!,
      dismissIndicator: s.dismissIndicator!,
      enableHaptic: s.enableHaptic!,
      isDark: context.isDarkMode,
    );
  }
}

/// Fully materialized [DialogStyle]. [shadow] stays nullable — use
/// [resolveShadow] for the theme-aware default.
@immutable
class ResolvedDialogStyle {
  const ResolvedDialogStyle({
    required this.backgroundColor,
    required this.backgroundGradient,
    required this.borderRadius,
    required this.border,
    required this.borderGradient,
    required this.borderWidth,
    required this.maxWidth,
    required this.maxHeight,
    required this.padding,
    required this.titleStyle,
    required this.messageStyle,
    required this.shadow,
    required this.barrierColor,
    required this.animation,
    required this.animationDuration,
    required this.animationCurve,
    required this.dismissIndicator,
    required this.enableHaptic,
    required this.isDark,
  });

  final Color backgroundColor;
  final Gradient? backgroundGradient;
  final BorderRadius borderRadius;
  final Border? border;
  final Gradient? borderGradient;
  final double borderWidth;
  final double maxWidth;
  final double? maxHeight;
  final EdgeInsets? padding;
  final TextStyle? titleStyle;
  final TextStyle? messageStyle;
  final List<BoxShadow>? shadow;
  final Color barrierColor;
  final DialogAnimation animation;
  final Duration animationDuration;
  final Curve animationCurve;
  final DismissIndicatorStyle dismissIndicator;
  final bool enableHaptic;
  final bool isDark;

  /// Caller shadow, or the theme-aware default. Shadows are
  /// physically black in both themes; only the opacity varies.
  List<BoxShadow> resolveShadow() =>
      shadow ??
      [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.15),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];
}
