import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../models/popup_arrow_backdrop.dart';
import '../models/popup_enums.dart';
import '../models/popup_geometry.dart';
import '../models/popup_surface_style.dart';

/// App-wide defaults for [GlobalPopup].
///
/// Register on `ThemeData.extensions`:
/// ```dart
/// ThemeData(extensions: [
///   GlobalPopupTheme(
///     surface: const GlobalPopupSurfaceStyle(elevation: 8),
///     animation: GlobalPopupAnimation.scale,
///     gap: 6,
///   ),
/// ]);
/// ```
///
/// Resolution order at open time:
/// 1. Per-instance `GlobalPopupOptions` value (if non-null)
/// 2. This theme's value (if non-null)
/// 3. `GlobalPopupOptions.defaults`
///
/// Every UI-affecting field on [GlobalPopupOptions] is mirrored here so
/// adopters can rebrand the popup module at the theme layer instead of
/// passing the same overrides at every call site.
@immutable
class GlobalPopupTheme extends ThemeExtension<GlobalPopupTheme> {
  const GlobalPopupTheme({
    this.surface,
    this.animation,
    this.animationDuration,
    this.flipAnimationDuration,
    this.animationCurve,
    this.gap,
    this.arrow,
    this.backdrop,
    this.closeOnScroll,
    this.closeOnTapOutside,
    this.closeOnRouteChange,
    this.minHeight,
    this.maxHeight,
    this.preferAboveThreshold,
    this.dynamicResizeOnKeyboard,
    this.preserveStateOnFlip,
    this.screenPadding,
    this.placement,
    this.width,
    this.hoverCloseDelay,
    this.hoverOpenDelay,
    this.autoDismissAfter,
    this.respectReduceMotion,
    this.animateContentSize,
    this.contentSizeAnimationDuration,
    this.contentSizeAnimationCurve,
    this.openSemanticLabel,
    this.closeSemanticLabel,
    this.closeOthersOnOpen,
  });

  final GlobalPopupSurfaceStyle? surface;
  final GlobalPopupAnimation? animation;
  final Duration? animationDuration;
  final Duration? flipAnimationDuration;
  final Curve? animationCurve;
  final double? gap;
  final GlobalPopupArrow? arrow;
  final GlobalPopupBackdrop? backdrop;
  final bool? closeOnScroll;
  final bool? closeOnTapOutside;
  final bool? closeOnRouteChange;
  final double? minHeight;
  final double? maxHeight;
  final double? preferAboveThreshold;
  final bool? dynamicResizeOnKeyboard;
  final bool? preserveStateOnFlip;
  final double? screenPadding;
  final GlobalPopupPlacement? placement;
  final GlobalPopupWidth? width;
  final Duration? hoverCloseDelay;

  /// See `GlobalPopupOptions.hoverOpenDelay`.
  final Duration? hoverOpenDelay;

  /// See `GlobalPopupOptions.autoDismissAfter`.
  final Duration? autoDismissAfter;
  final bool? respectReduceMotion;
  final bool? animateContentSize;
  final Duration? contentSizeAnimationDuration;
  final Curve? contentSizeAnimationCurve;
  final String? openSemanticLabel;
  final String? closeSemanticLabel;
  final bool? closeOthersOnOpen;

  static GlobalPopupTheme? maybeOf(BuildContext context) {
    return Theme.of(context).extension<GlobalPopupTheme>();
  }

  @override
  GlobalPopupTheme copyWith({
    GlobalPopupSurfaceStyle? surface,
    GlobalPopupAnimation? animation,
    Duration? animationDuration,
    Duration? flipAnimationDuration,
    Curve? animationCurve,
    double? gap,
    GlobalPopupArrow? arrow,
    GlobalPopupBackdrop? backdrop,
    bool? closeOnScroll,
    bool? closeOnTapOutside,
    bool? closeOnRouteChange,
    double? minHeight,
    double? maxHeight,
    double? preferAboveThreshold,
    bool? dynamicResizeOnKeyboard,
    bool? preserveStateOnFlip,
    double? screenPadding,
    GlobalPopupPlacement? placement,
    GlobalPopupWidth? width,
    Duration? hoverCloseDelay,
    Duration? hoverOpenDelay,
    Duration? autoDismissAfter,
    bool? respectReduceMotion,
    bool? animateContentSize,
    Duration? contentSizeAnimationDuration,
    Curve? contentSizeAnimationCurve,
    String? openSemanticLabel,
    String? closeSemanticLabel,
    bool? closeOthersOnOpen,
  }) {
    return GlobalPopupTheme(
      surface: surface ?? this.surface,
      animation: animation ?? this.animation,
      animationDuration: animationDuration ?? this.animationDuration,
      flipAnimationDuration:
          flipAnimationDuration ?? this.flipAnimationDuration,
      animationCurve: animationCurve ?? this.animationCurve,
      gap: gap ?? this.gap,
      arrow: arrow ?? this.arrow,
      backdrop: backdrop ?? this.backdrop,
      closeOnScroll: closeOnScroll ?? this.closeOnScroll,
      closeOnTapOutside: closeOnTapOutside ?? this.closeOnTapOutside,
      closeOnRouteChange: closeOnRouteChange ?? this.closeOnRouteChange,
      minHeight: minHeight ?? this.minHeight,
      maxHeight: maxHeight ?? this.maxHeight,
      preferAboveThreshold: preferAboveThreshold ?? this.preferAboveThreshold,
      dynamicResizeOnKeyboard:
          dynamicResizeOnKeyboard ?? this.dynamicResizeOnKeyboard,
      preserveStateOnFlip: preserveStateOnFlip ?? this.preserveStateOnFlip,
      screenPadding: screenPadding ?? this.screenPadding,
      placement: placement ?? this.placement,
      width: width ?? this.width,
      hoverCloseDelay: hoverCloseDelay ?? this.hoverCloseDelay,
      hoverOpenDelay: hoverOpenDelay ?? this.hoverOpenDelay,
      autoDismissAfter: autoDismissAfter ?? this.autoDismissAfter,
      respectReduceMotion: respectReduceMotion ?? this.respectReduceMotion,
      animateContentSize: animateContentSize ?? this.animateContentSize,
      contentSizeAnimationDuration:
          contentSizeAnimationDuration ?? this.contentSizeAnimationDuration,
      contentSizeAnimationCurve:
          contentSizeAnimationCurve ?? this.contentSizeAnimationCurve,
      openSemanticLabel: openSemanticLabel ?? this.openSemanticLabel,
      closeSemanticLabel: closeSemanticLabel ?? this.closeSemanticLabel,
      closeOthersOnOpen: closeOthersOnOpen ?? this.closeOthersOnOpen,
    );
  }

  @override
  GlobalPopupTheme lerp(ThemeExtension<GlobalPopupTheme>? other, double t) {
    if (other is! GlobalPopupTheme) return this;
    return GlobalPopupTheme(
      // Numeric + Duration fields interpolate smoothly.
      animationDuration: _lerpDuration(
        animationDuration,
        other.animationDuration,
        t,
      ),
      flipAnimationDuration: _lerpDuration(
        flipAnimationDuration,
        other.flipAnimationDuration,
        t,
      ),
      hoverCloseDelay: _lerpDuration(hoverCloseDelay, other.hoverCloseDelay, t),
      hoverOpenDelay: _lerpDuration(hoverOpenDelay, other.hoverOpenDelay, t),
      autoDismissAfter: _lerpDuration(
        autoDismissAfter,
        other.autoDismissAfter,
        t,
      ),
      contentSizeAnimationDuration: _lerpDuration(
        contentSizeAnimationDuration,
        other.contentSizeAnimationDuration,
        t,
      ),
      gap: lerpDouble(gap, other.gap, t),
      minHeight: lerpDouble(minHeight, other.minHeight, t),
      maxHeight: lerpDouble(maxHeight, other.maxHeight, t),
      preferAboveThreshold: lerpDouble(
        preferAboveThreshold,
        other.preferAboveThreshold,
        t,
      ),
      screenPadding: lerpDouble(screenPadding, other.screenPadding, t),
      // Compound objects with their own lerp.
      surface: _lerpSurface(surface, other.surface, t),
      // Configs without natural interpolation switch at t=0.5. This
      // is correct semantically — there's no meaningful "half-scale,
      // half-reveal" entrance animation. Open popups aren't affected
      // either: they materialize options once at `show()` and don't
      // re-read theme mid-life. The visible "pop" only shows up in
      // live theme-toggle UIs where the dev is watching configs
      // change in DevTools.
      animation: t < 0.5 ? animation : other.animation,
      animationCurve: t < 0.5 ? animationCurve : other.animationCurve,
      arrow: t < 0.5 ? arrow : other.arrow,
      backdrop: t < 0.5 ? backdrop : other.backdrop,
      closeOnScroll: t < 0.5 ? closeOnScroll : other.closeOnScroll,
      closeOnTapOutside: t < 0.5 ? closeOnTapOutside : other.closeOnTapOutside,
      closeOnRouteChange: t < 0.5
          ? closeOnRouteChange
          : other.closeOnRouteChange,
      dynamicResizeOnKeyboard: t < 0.5
          ? dynamicResizeOnKeyboard
          : other.dynamicResizeOnKeyboard,
      preserveStateOnFlip: t < 0.5
          ? preserveStateOnFlip
          : other.preserveStateOnFlip,
      placement: t < 0.5 ? placement : other.placement,
      width: t < 0.5 ? width : other.width,
      respectReduceMotion: t < 0.5
          ? respectReduceMotion
          : other.respectReduceMotion,
      animateContentSize: t < 0.5
          ? animateContentSize
          : other.animateContentSize,
      contentSizeAnimationCurve: t < 0.5
          ? contentSizeAnimationCurve
          : other.contentSizeAnimationCurve,
      openSemanticLabel: t < 0.5 ? openSemanticLabel : other.openSemanticLabel,
      closeSemanticLabel: t < 0.5
          ? closeSemanticLabel
          : other.closeSemanticLabel,
      closeOthersOnOpen: t < 0.5 ? closeOthersOnOpen : other.closeOthersOnOpen,
    );
  }

  static Duration? _lerpDuration(Duration? a, Duration? b, double t) {
    if (a == null && b == null) return null;
    final aMicros = a?.inMicroseconds ?? b!.inMicroseconds;
    final bMicros = b?.inMicroseconds ?? a!.inMicroseconds;
    return Duration(
      microseconds: (lerpDouble(aMicros.toDouble(), bMicros.toDouble(), t) ?? 0)
          .round(),
    );
  }

  static GlobalPopupSurfaceStyle? _lerpSurface(
    GlobalPopupSurfaceStyle? a,
    GlobalPopupSurfaceStyle? b,
    double t,
  ) {
    if (a == null && b == null) return null;
    if (a == null) return b;
    if (b == null) return a;
    return GlobalPopupSurfaceStyle(
      color: Color.lerp(a.color, b.color, t),
      darkColor: Color.lerp(a.darkColor, b.darkColor, t),
      elevation: lerpDouble(a.elevation, b.elevation, t),
      borderRadius: BorderRadius.lerp(a.borderRadius, b.borderRadius, t),
      border: BoxBorder.lerp(a.border, b.border, t),
      borderColor: Color.lerp(a.borderColor, b.borderColor, t),
      borderWidth: lerpDouble(a.borderWidth, b.borderWidth, t),
      padding: EdgeInsetsGeometry.lerp(a.padding, b.padding, t),
      shadowColor: Color.lerp(a.shadowColor, b.shadowColor, t),
      clipBehavior: t < 0.5 ? a.clipBehavior : b.clipBehavior,
      minWidth: lerpDouble(a.minWidth, b.minWidth, t),
      intrinsicWidth: t < 0.5 ? a.intrinsicWidth : b.intrinsicWidth,
      hoverColor: Color.lerp(a.hoverColor, b.hoverColor, t),
      selectedColor: Color.lerp(a.selectedColor, b.selectedColor, t),
      // Gradients + custom shadow lists snap.
      gradient: t < 0.5 ? a.gradient : b.gradient,
      borderGradient: t < 0.5 ? a.borderGradient : b.borderGradient,
      shadow: t < 0.5 ? a.shadow : b.shadow,
    );
  }
}
