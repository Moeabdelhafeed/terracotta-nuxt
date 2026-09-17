import 'package:flutter/material.dart';

import '../../../core/animations/animation_presets.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import 'theme/sheet_theme.dart';

/// Styling for bottom / top / combined / responsive sheets.
///
/// Every field is nullable — the THEMEABLE bag. Resolution order per
/// field: caller `style:` > [GlobalSheetTheme.style] > [defaults] >
/// `context.<group>Colors`. Materialize once per build via [resolve];
/// widget code reads the [ResolvedSheetStyle] only.
class SheetStyle {
  const SheetStyle({
    this.backgroundColor,
    this.backgroundGradient,
    this.borderRadius,
    this.border,
    this.borderGradient,
    this.borderWidth,
    this.shadow,
    this.handleColor,
    this.showHandle,
    this.handleWidth,
    this.handleHeight,
    this.floating,
    this.floatingMargin,
    this.useDeviceRadius,
    this.hideBottomBorder,
    this.barrierColor,
    this.contentPadding,
    this.animationDuration,
    this.animationCurve,
    this.enableHaptic,
  });

  /// Non-color scalar defaults. Colors stay null here — they resolve
  /// from `context` in [resolve] (role + saturation aware).
  static const defaults = SheetStyle(
    borderWidth: 2,
    showHandle: true,
    handleWidth: 40,
    handleHeight: 4,
    floating: false,
    floatingMargin: EdgeInsets.all(12),
    useDeviceRadius: true,
    hideBottomBorder: false,
    contentPadding: EdgeInsets.all(20),
    animationDuration: AppDurations.normal,
    animationCurve: AppCurves.emphasized,
    enableHaptic: true,
  );

  final Color? backgroundColor;
  final Gradient? backgroundGradient;
  final BorderRadius? borderRadius;
  final Border? border;
  final Gradient? borderGradient;
  final double? borderWidth;
  final List<BoxShadow>? shadow;
  final Color? handleColor;
  final bool? showHandle;
  final double? handleWidth;
  final double? handleHeight;

  /// When true, the sheet floats with margin from screen edges
  /// (rounded on all sides).
  final bool? floating;

  /// Margin around the floating sheet.
  final EdgeInsets? floatingMargin;

  /// When true and [borderRadius] is null, uses the device's physical
  /// screen corner radius. Falls back to standard radius when the
  /// device reports square corners.
  final bool? useDeviceRadius;

  /// When true, hides the bottom border in non-floating mode (sheet
  /// sits flush at the screen edge).
  final bool? hideBottomBorder;

  /// Modal barrier color behind the sheet.
  final Color? barrierColor;

  /// Padding around the scrollable content slot.
  final EdgeInsets? contentPadding;

  /// Entry / exit transition length. Reduced motion collapses it to
  /// zero regardless of this value.
  final Duration? animationDuration;

  final Curve? animationCurve;

  /// Gates every haptic the sheet emits (close tap, drag dismiss).
  final bool? enableHaptic;

  /// Field-wise merge — [other]'s non-null fields win.
  SheetStyle mergedWith(SheetStyle? other) {
    if (other == null) return this;
    return SheetStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      backgroundGradient: other.backgroundGradient ?? backgroundGradient,
      borderRadius: other.borderRadius ?? borderRadius,
      border: other.border ?? border,
      borderGradient: other.borderGradient ?? borderGradient,
      borderWidth: other.borderWidth ?? borderWidth,
      shadow: other.shadow ?? shadow,
      handleColor: other.handleColor ?? handleColor,
      showHandle: other.showHandle ?? showHandle,
      handleWidth: other.handleWidth ?? handleWidth,
      handleHeight: other.handleHeight ?? handleHeight,
      floating: other.floating ?? floating,
      floatingMargin: other.floatingMargin ?? floatingMargin,
      useDeviceRadius: other.useDeviceRadius ?? useDeviceRadius,
      hideBottomBorder: other.hideBottomBorder ?? hideBottomBorder,
      barrierColor: other.barrierColor ?? barrierColor,
      contentPadding: other.contentPadding ?? contentPadding,
      animationDuration: other.animationDuration ?? animationDuration,
      animationCurve: other.animationCurve ?? animationCurve,
      enableHaptic: other.enableHaptic ?? enableHaptic,
    );
  }

  /// Convenience copy — identical field semantics to [mergedWith]
  /// with per-field overrides.
  SheetStyle copyWith({
    Color? backgroundColor,
    Gradient? backgroundGradient,
    BorderRadius? borderRadius,
    Border? border,
    Gradient? borderGradient,
    double? borderWidth,
    List<BoxShadow>? shadow,
    Color? handleColor,
    bool? showHandle,
    double? handleWidth,
    double? handleHeight,
    bool? floating,
    EdgeInsets? floatingMargin,
    bool? useDeviceRadius,
    bool? hideBottomBorder,
    Color? barrierColor,
    EdgeInsets? contentPadding,
    Duration? animationDuration,
    Curve? animationCurve,
    bool? enableHaptic,
  }) => mergedWith(
    SheetStyle(
      backgroundColor: backgroundColor,
      backgroundGradient: backgroundGradient,
      borderRadius: borderRadius,
      border: border,
      borderGradient: borderGradient,
      borderWidth: borderWidth,
      shadow: shadow,
      handleColor: handleColor,
      showHandle: showHandle,
      handleWidth: handleWidth,
      handleHeight: handleHeight,
      floating: floating,
      floatingMargin: floatingMargin,
      useDeviceRadius: useDeviceRadius,
      hideBottomBorder: hideBottomBorder,
      barrierColor: barrierColor,
      contentPadding: contentPadding,
      animationDuration: animationDuration,
      animationCurve: animationCurve,
      enableHaptic: enableHaptic,
    ),
  );

  /// Materializes the final values: caller > theme > defaults >
  /// context colors. Call once per build / show.
  ResolvedSheetStyle resolve(BuildContext context) {
    final themed = GlobalSheetTheme.maybeOf(context)?.style;
    final s = SheetStyle.defaults.mergedWith(themed).mergedWith(this);
    final bg = context.backgroundColors;
    return ResolvedSheetStyle(
      backgroundColor: s.backgroundColor ?? bg.scaffoldBackground,
      backgroundGradient: s.backgroundGradient,
      borderRadius: s.borderRadius,
      border: s.border,
      borderGradient: s.borderGradient,
      borderWidth: s.borderWidth!,
      shadow: s.shadow,
      handleColor: s.handleColor ?? bg.outline.withValues(alpha: 0.3),
      showHandle: s.showHandle!,
      handleWidth: s.handleWidth!,
      handleHeight: s.handleHeight!,
      floating: s.floating!,
      floatingMargin: s.floatingMargin!,
      useDeviceRadius: s.useDeviceRadius!,
      hideBottomBorder: s.hideBottomBorder!,
      barrierColor: s.barrierColor ?? context.overlayColors.barrier,
      contentPadding: s.contentPadding!,
      animationDuration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : s.animationDuration!,
      animationCurve: s.animationCurve!,
      enableHaptic: s.enableHaptic!,
      isDark: context.isDarkMode,
    );
  }
}

/// Fully materialized [SheetStyle]. [shadow] stays nullable — the
/// default depends on the sheet's anchored edge; use [resolveShadow].
@immutable
class ResolvedSheetStyle {
  const ResolvedSheetStyle({
    required this.backgroundColor,
    required this.backgroundGradient,
    required this.borderRadius,
    required this.border,
    required this.borderGradient,
    required this.borderWidth,
    required this.shadow,
    required this.handleColor,
    required this.showHandle,
    required this.handleWidth,
    required this.handleHeight,
    required this.floating,
    required this.floatingMargin,
    required this.useDeviceRadius,
    required this.hideBottomBorder,
    required this.barrierColor,
    required this.contentPadding,
    required this.animationDuration,
    required this.animationCurve,
    required this.enableHaptic,
    required this.isDark,
  });

  final Color backgroundColor;
  final Gradient? backgroundGradient;
  final BorderRadius? borderRadius;
  final Border? border;
  final Gradient? borderGradient;
  final double borderWidth;
  final List<BoxShadow>? shadow;
  final Color handleColor;
  final bool showHandle;
  final double handleWidth;
  final double handleHeight;
  final bool floating;
  final EdgeInsets floatingMargin;
  final bool useDeviceRadius;
  final bool hideBottomBorder;
  final Color barrierColor;
  final EdgeInsets contentPadding;
  final Duration animationDuration;
  final Curve animationCurve;
  final bool enableHaptic;
  final bool isDark;

  /// Caller shadow, or the edge-aware default (bottom sheets throw
  /// upward, top sheets downward).
  List<BoxShadow> resolveShadow({required bool isTop}) =>
      shadow ??
      [
        BoxShadow(
          // Shadows are physically black in both themes; only the
          // opacity is theme-aware.
          color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
          blurRadius: 20,
          offset: Offset(0, isTop ? 4 : -4),
        ),
      ];
}

/// Per-call sizing + cross-axis alignment for sheets.
///
/// **Bottom / Top sheets** — read [width], [maxWidth], [adaptiveWidth]
/// and [horizontalAlignment]. The cross-axis is the screen's
/// horizontal axis since the sheet pins to the bottom (or top) edge.
///
/// **Side sheets** (responsive surface, medium+ bucket) — read
/// [height], [maxHeight], [adaptiveHeight] and [verticalAlignment].
/// The cross-axis is the screen's vertical axis since the sheet pins
/// to the trailing edge.
///
/// Sizing rules:
///
/// * [width] / [height] — explicit dimension. Takes precedence over
///   adaptive sizing on the same axis.
/// * [adaptiveWidth] / [adaptiveHeight] — shrink-to-content along the
///   cross-axis. Capped by [maxWidth] / [maxHeight] when set.
/// * [maxWidth] / [maxHeight] alone (no fixed + no adaptive) — caps
///   the default fill-the-axis behaviour without changing alignment.
///
/// Asserts trip if [width] and [adaptiveWidth] (or [height] and
/// [adaptiveHeight]) are combined — they describe the same axis.
@immutable
class SheetSizing {
  const SheetSizing({
    this.width,
    this.maxWidth,
    this.adaptiveWidth = false,
    this.height,
    this.maxHeight,
    this.adaptiveHeight = false,
    this.horizontalAlignment,
    this.verticalAlignment,
  }) : assert(
         width == null || !adaptiveWidth,
         'Use width OR adaptiveWidth, not both.',
       ),
       assert(
         height == null || !adaptiveHeight,
         'Use height OR adaptiveHeight, not both.',
       );

  /// Explicit width for bottom / top sheets. Wins over [adaptiveWidth].
  final double? width;

  /// Upper bound for [width] (when set) or [adaptiveWidth] resolution.
  final double? maxWidth;

  /// When true and [width] is null, the sheet shrinks to fit the
  /// content's intrinsic width, capped by [maxWidth].
  final bool adaptiveWidth;

  /// Explicit height for side sheets. Wins over [adaptiveHeight].
  final double? height;

  /// Upper bound for [height] (when set) or [adaptiveHeight] resolution.
  final double? maxHeight;

  /// When true and [height] is null, the side sheet shrinks to fit
  /// the content's intrinsic height, capped by [maxHeight].
  final bool adaptiveHeight;

  /// Horizontal alignment for bottom / top sheets when narrower than
  /// the screen. Defaults to center.
  final SheetCrossAlign? horizontalAlignment;

  /// Vertical alignment for side sheets when shorter than the
  /// screen. Defaults to center.
  final SheetCrossAlign? verticalAlignment;
}

/// Cross-axis alignment for [SheetSizing]. Reused by both horizontal
/// and vertical axes — the axis is implied by which field on
/// [SheetSizing] the value is assigned to.
enum SheetCrossAlign { start, center, end }
