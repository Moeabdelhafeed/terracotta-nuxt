import 'package:flutter/foundation.dart'; // ignore: unnecessary_import
import 'package:flutter/material.dart';

/// Visual styling for any [GlobalPopupSurface] (menu / panel / tooltip).
///
/// All fields are nullable so theme + per-call instances can be merged
/// field-by-field via [mergedWith]. Resolved against [defaults] before
/// paint.
///
/// Resolution order at render time (the controller materializes options
/// once at `show()`, surfaces materialize style once at `build()`):
/// 1. Per-instance `surfaceStyle` (passed to [GlobalPopupOptions] or a
///    surface widget directly)
/// 2. `GlobalPopupTheme.surface` if registered via `ThemeData.extensions`
/// 3. [GlobalPopupSurfaceStyle.defaults]
@immutable
class GlobalPopupSurfaceStyle extends DiagnosticableTree {
  const GlobalPopupSurfaceStyle({
    this.color,
    this.darkColor,
    this.gradient,
    this.elevation,
    this.borderRadius,
    this.border,
    this.borderColor,
    this.borderGradient,
    this.borderWidth,
    this.padding,
    this.shadow,
    this.shadowColor,
    this.clipBehavior,
    this.minWidth,
    this.intrinsicWidth,
    this.hoverColor,
    this.selectedColor,
  });

  /// Surface fill. Null → `theme.colorScheme.surface` at paint time.
  final Color? color;

  /// Dark-mode override fill. Null → uses [color] / theme surface.
  final Color? darkColor;

  /// Gradient fill — overrides [color] when set.
  final Gradient? gradient;

  final double? elevation;

  final BorderRadius? borderRadius;

  /// Pre-built border (takes precedence over [borderColor] / [borderGradient]).
  final BoxBorder? border;

  /// Solid border color. Ignored if [border] or [borderGradient] set.
  final Color? borderColor;

  /// Gradient border (CustomPaint stroked). Highest priority.
  final Gradient? borderGradient;

  final double? borderWidth;

  /// Padding around content. Null → none.
  final EdgeInsetsGeometry? padding;

  /// Custom shadow list. Overrides [elevation] when set.
  final List<BoxShadow>? shadow;

  final Color? shadowColor;

  final Clip? clipBehavior;

  /// Minimum surface width hint. Surface won't render narrower than this.
  final double? minWidth;

  /// When true, surface wraps `IntrinsicWidth` so it auto-shrinks to
  /// content width rather than fill the available constraints.
  final bool? intrinsicWidth;

  /// Item hover highlight (menu surfaces).
  final Color? hoverColor;

  /// Background fill for toggled / selected items.
  final Color? selectedColor;

  /// Hard-coded fallback values applied when neither the per-instance
  /// style nor the active [GlobalPopupTheme.surface] supplied a value
  /// for a given field. Used as the last layer in [mergedWith]'s
  /// resolution stack + read by surfaces consuming a merged instance.
  static const GlobalPopupSurfaceStyle defaults = GlobalPopupSurfaceStyle(
    elevation: 10,
    borderWidth: 1,
    clipBehavior: Clip.antiAlias,
    intrinsicWidth: false,
  );

  /// Stack resolution: [other] > this for every field. Pass the
  /// per-call style as `other` and the theme/defaults as `this` so
  /// caller's non-null fields override.
  GlobalPopupSurfaceStyle mergedWith(GlobalPopupSurfaceStyle? other) {
    if (other == null) return this;
    return GlobalPopupSurfaceStyle(
      color: other.color ?? color,
      darkColor: other.darkColor ?? darkColor,
      gradient: other.gradient ?? gradient,
      elevation: other.elevation ?? elevation,
      borderRadius: other.borderRadius ?? borderRadius,
      border: other.border ?? border,
      borderColor: other.borderColor ?? borderColor,
      borderGradient: other.borderGradient ?? borderGradient,
      borderWidth: other.borderWidth ?? borderWidth,
      padding: other.padding ?? padding,
      shadow: other.shadow ?? shadow,
      shadowColor: other.shadowColor ?? shadowColor,
      clipBehavior: other.clipBehavior ?? clipBehavior,
      minWidth: other.minWidth ?? minWidth,
      intrinsicWidth: other.intrinsicWidth ?? intrinsicWidth,
      hoverColor: other.hoverColor ?? hoverColor,
      selectedColor: other.selectedColor ?? selectedColor,
    );
  }

  /// Materialize against [defaults] so the non-null-themed fields
  /// (elevation, borderWidth, clipBehavior, intrinsicWidth) are
  /// guaranteed non-null. Color/border/padding stay nullable since
  /// they're consumed via `?? Theme.of(context).colorScheme.X`.
  GlobalPopupSurfaceStyle resolved() => defaults.mergedWith(this);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(ColorProperty('color', color, defaultValue: null))
      ..add(ColorProperty('darkColor', darkColor, defaultValue: null))
      ..add(
        DiagnosticsProperty<Gradient>('gradient', gradient, defaultValue: null),
      )
      ..add(DoubleProperty('elevation', elevation, defaultValue: null))
      ..add(
        DiagnosticsProperty<BorderRadius>(
          'borderRadius',
          borderRadius,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<BoxBorder>('border', border, defaultValue: null),
      )
      ..add(ColorProperty('borderColor', borderColor, defaultValue: null))
      ..add(
        DiagnosticsProperty<Gradient>(
          'borderGradient',
          borderGradient,
          defaultValue: null,
        ),
      )
      ..add(DoubleProperty('borderWidth', borderWidth, defaultValue: null))
      ..add(
        DiagnosticsProperty<EdgeInsetsGeometry>(
          'padding',
          padding,
          defaultValue: null,
        ),
      )
      ..add(IterableProperty<BoxShadow>('shadow', shadow, defaultValue: null))
      ..add(ColorProperty('shadowColor', shadowColor, defaultValue: null))
      ..add(
        EnumProperty<Clip>('clipBehavior', clipBehavior, defaultValue: null),
      )
      ..add(DoubleProperty('minWidth', minWidth, defaultValue: null))
      ..add(
        FlagProperty(
          'intrinsicWidth',
          value: intrinsicWidth,
          ifTrue: 'intrinsicWidth',
          defaultValue: null,
        ),
      )
      ..add(ColorProperty('hoverColor', hoverColor, defaultValue: null))
      ..add(ColorProperty('selectedColor', selectedColor, defaultValue: null));
  }
}
