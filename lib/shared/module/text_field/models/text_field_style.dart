import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/extensions/theme_colors_extension.dart';
import '../theme/text_field_theme.dart';
import 'text_field_border.dart';
import 'text_field_defaults.dart';

export 'text_field_border.dart';

// Constants live in [TextFieldDefaults] (text_field_defaults.dart) — the
// single source for every hard-coded module value.

// ---------------------------------------------------------------------------
// TextFieldStyle — visual (the themeable bag)
// ---------------------------------------------------------------------------

/// Visual configuration for [GlobalTextFormField].
///
/// This is the text-field analogue of `GlobalPopupSurfaceStyle`: **every
/// field is nullable** so a per-call style, the app-wide
/// [GlobalTextFieldTheme], and the hard-coded fallbacks can be merged
/// field-by-field. Effective value resolution at build time:
///
/// 1. Per-instance value (this object's field, if non-null)
/// 2. [GlobalTextFieldTheme] field of the same name (if registered + non-null)
/// 3. Context-derived fallback (`context.<group>Colors.<role>`) or
///    [defaults] hard-coded constant.
///
/// Borders live in the structured [border] bag ([TextFieldBorderStyle]) —
/// a base default + per-state overrides, with gradient support. Call
/// [resolve] (the materialize point) to flatten everything into a
/// [ResolvedTextFieldStyle] whose themed fields are guaranteed non-null.
@immutable
class TextFieldStyle extends DiagnosticableTree {
  const TextFieldStyle({
    this.borderRadius,
    this.height,
    this.contentPadding,
    this.fillColor,
    this.textColor,
    this.iconColor,
    this.border,
    this.enableBlur,
    this.blurSigma,
    this.hintStyle,
    this.charCountStyle,
    this.successColor,
    this.strengthWeakColor,
    this.strengthMediumColor,
    this.strengthStrongColor,
    this.counterWarningColor,
    this.requirementPassedColor,
    this.enableHaptic,
  });

  final BorderRadius? borderRadius;
  final double? height;
  final EdgeInsetsGeometry? contentPadding;

  /// Field background fill. Null → `context.backgroundColors.inputBackground`.
  final Color? fillColor;

  /// Input text color. Null → `theme.textTheme.bodyMedium?.color`.
  final Color? textColor;

  /// Icon tint (prefix/suffix). Null → `context.iconColors.primary`.
  final Color? iconColor;

  /// Per-state border strokes (base + enabled / focused / error /
  /// focusedError / disabled). Supports gradient strokes.
  final TextFieldBorderStyle? border;

  /// Frosted-glass background. Null → `false`.
  final bool? enableBlur;

  /// Null → [TextFieldDefaults.blurSigma].
  final double? blurSigma;

  final TextStyle? hintStyle;
  final TextStyle? charCountStyle;

  /// Success row + check tint. Null → `context.statusColors.success`.
  final Color? successColor;

  /// Strength-bar low end. Null → `context.statusColors.error`.
  final Color? strengthWeakColor;

  /// Strength-bar mid. Null → `context.statusColors.warning`.
  final Color? strengthMediumColor;

  /// Strength-bar high end + passed-requirement tint default.
  /// Null → `context.statusColors.success`.
  final Color? strengthStrongColor;

  /// Char-counter "near limit" (≥80%) tint. Null → `context.statusColors.warning`.
  final Color? counterWarningColor;

  /// Passed-requirement checklist tint. Null → `context.statusColors.success`.
  final Color? requirementPassedColor;

  /// Haptic feedback on interactive affordances (dropdown select / chip
  /// delete / clear). Null → `true`. Consumed by composing widgets
  /// (`GlobalDropdown`); the base field itself is haptic-free.
  final bool? enableHaptic;

  /// Hard-coded fallbacks for the const-able scalar fields. Colors +
  /// radius + text styles resolve against `context` instead (they can't
  /// be `const`).
  static const TextFieldStyle defaults = TextFieldStyle(
    border: TextFieldBorderStyle(
      // The RESTING width, and the floor every state inherits. It was
      // 0, which made an idle field edgeless — it only announced itself
      // once you focused it, so an empty form read as a page of labels
      // with nothing to type into. `focused` and `error` below set
      // their own widths, so only the resting and disabled states move.
      base: TextFieldBorderSide(width: TextFieldDefaults.restingBorderWidth),
      focused: TextFieldBorderSide(width: TextFieldDefaults.focusedBorderWidth),
      error: TextFieldBorderSide(width: TextFieldDefaults.errorBorderWidth),
    ),
    enableBlur: false,
    blurSigma: TextFieldDefaults.blurSigma,
    enableHaptic: true,
  );

  /// Stack resolution: [other] > this for every field. Pass the per-call
  /// style as `other` and theme/defaults as `this`.
  TextFieldStyle mergedWith(TextFieldStyle? other) {
    if (other == null) return this;
    return TextFieldStyle(
      borderRadius: other.borderRadius ?? borderRadius,
      height: other.height ?? height,
      contentPadding: other.contentPadding ?? contentPadding,
      fillColor: other.fillColor ?? fillColor,
      textColor: other.textColor ?? textColor,
      iconColor: other.iconColor ?? iconColor,
      border: border == null ? other.border : border!.mergedWith(other.border),
      enableBlur: other.enableBlur ?? enableBlur,
      blurSigma: other.blurSigma ?? blurSigma,
      hintStyle: other.hintStyle ?? hintStyle,
      charCountStyle: other.charCountStyle ?? charCountStyle,
      successColor: other.successColor ?? successColor,
      strengthWeakColor: other.strengthWeakColor ?? strengthWeakColor,
      strengthMediumColor: other.strengthMediumColor ?? strengthMediumColor,
      strengthStrongColor: other.strengthStrongColor ?? strengthStrongColor,
      counterWarningColor: other.counterWarningColor ?? counterWarningColor,
      requirementPassedColor:
          other.requirementPassedColor ?? requirementPassedColor,
      enableHaptic: other.enableHaptic ?? enableHaptic,
    );
  }

  /// Materialize point. Stacks `this (caller) > theme > defaults`, then
  /// fills color/radius/text-style fallbacks from `context`. The returned
  /// [ResolvedTextFieldStyle] guarantees every themed field is non-null.
  ResolvedTextFieldStyle resolve(BuildContext context) {
    final theme = GlobalTextFieldTheme.maybeOf(context);
    final s = defaults.mergedWith(theme?.style).mergedWith(this);
    return ResolvedTextFieldStyle._(context, s);
  }

  TextFieldStyle copyWith({
    BorderRadius? borderRadius,
    double? height,
    EdgeInsetsGeometry? contentPadding,
    Color? fillColor,
    Color? textColor,
    Color? iconColor,
    TextFieldBorderStyle? border,
    bool? enableBlur,
    double? blurSigma,
    TextStyle? hintStyle,
    TextStyle? charCountStyle,
    Color? successColor,
    Color? strengthWeakColor,
    Color? strengthMediumColor,
    Color? strengthStrongColor,
    Color? counterWarningColor,
    Color? requirementPassedColor,
    bool? enableHaptic,
  }) {
    return TextFieldStyle(
      borderRadius: borderRadius ?? this.borderRadius,
      height: height ?? this.height,
      contentPadding: contentPadding ?? this.contentPadding,
      fillColor: fillColor ?? this.fillColor,
      textColor: textColor ?? this.textColor,
      iconColor: iconColor ?? this.iconColor,
      border: border ?? this.border,
      enableBlur: enableBlur ?? this.enableBlur,
      blurSigma: blurSigma ?? this.blurSigma,
      hintStyle: hintStyle ?? this.hintStyle,
      charCountStyle: charCountStyle ?? this.charCountStyle,
      successColor: successColor ?? this.successColor,
      strengthWeakColor: strengthWeakColor ?? this.strengthWeakColor,
      strengthMediumColor: strengthMediumColor ?? this.strengthMediumColor,
      strengthStrongColor: strengthStrongColor ?? this.strengthStrongColor,
      counterWarningColor: counterWarningColor ?? this.counterWarningColor,
      requirementPassedColor:
          requirementPassedColor ?? this.requirementPassedColor,
      enableHaptic: enableHaptic ?? this.enableHaptic,
    );
  }
}

// ---------------------------------------------------------------------------
// ResolvedTextFieldStyle — post-materialize snapshot
// ---------------------------------------------------------------------------

/// Post-[TextFieldStyle.resolve] snapshot where every themed field is
/// non-null. Build + surface code read these directly instead of
/// `style.x ?? context...` ladders. Mirrors `ResolvedPopupOptions`.
@immutable
class ResolvedTextFieldStyle {
  ResolvedTextFieldStyle._(BuildContext context, TextFieldStyle s)
    : assert(
        s.border != null && s.enableBlur != null && s.blurSigma != null,
        'TextFieldStyle.resolve must run on a defaults-merged style — '
        'every const-able themed field (border, enableBlur, blurSigma) '
        'must be non-null. Did you bypass TextFieldStyle.defaults?',
      ),
      borderRadius =
          s.borderRadius ??
          BorderRadius.circular(TextFieldDefaults.borderRadius),
      height = s.height,
      contentPadding = s.contentPadding,
      fillColor = s.fillColor ?? context.backgroundColors.inputBackground,
      textColor = s.textColor,
      iconColor = s.iconColor ?? context.iconColors.primary,
      enableBlur = s.enableBlur ?? false,
      blurSigma = s.blurSigma ?? TextFieldDefaults.blurSigma,
      hintStyle = s.hintStyle,
      charCountStyle = s.charCountStyle,
      successColor = s.successColor ?? context.statusColors.success,
      strengthWeakColor = s.strengthWeakColor ?? context.statusColors.error,
      strengthMediumColor =
          s.strengthMediumColor ?? context.statusColors.warning,
      strengthStrongColor =
          s.strengthStrongColor ?? context.statusColors.success,
      counterWarningColor =
          s.counterWarningColor ?? context.statusColors.warning,
      requirementPassedColor =
          s.requirementPassedColor ?? context.statusColors.success,
      enableHaptic = s.enableHaptic ?? true,
      // A field at rest carries a hairline, as the design draws it.
      // The width normally arrives from `TextFieldStyle.defaults.base`;
      // this fallback only covers a style that dropped the base side
      // entirely.
      //
      // Asking for no resting border is still possible, and still
      // explicit: `enabled: TextFieldBorderSide(width: 0)`, which the
      // `width > 0` test below rejects.
      enabledBorder = _resolveSide(
        s.border!,
        TextFieldBorderState.enabled,
        context.backgroundColors.outline,
        TextFieldDefaults.restingBorderWidth,
      ),
      focusedBorder = _resolveSide(
        s.border!,
        TextFieldBorderState.focused,
        context.primaryColors.primary,
        TextFieldDefaults.focusedBorderWidth,
      ),
      errorBorder = _resolveSide(
        s.border!,
        TextFieldBorderState.error,
        context.statusColors.error,
        TextFieldDefaults.errorBorderWidth,
      ),
      focusedErrorBorder = _resolveSide(
        s.border!,
        TextFieldBorderState.focusedError,
        context.statusColors.error,
        TextFieldDefaults.focusedBorderWidth,
      ),
      disabledBorder = _resolveSide(
        s.border!,
        TextFieldBorderState.disabled,
        context.backgroundColors.outline.withValues(alpha: 0.3),
        0,
      );

  final BorderRadius borderRadius;
  final double? height;
  final EdgeInsetsGeometry? contentPadding;
  final Color fillColor;
  final Color? textColor;
  final Color iconColor;
  final bool enableBlur;
  final double blurSigma;
  final TextStyle? hintStyle;
  final TextStyle? charCountStyle;
  final Color successColor;
  final Color strengthWeakColor;
  final Color strengthMediumColor;
  final Color strengthStrongColor;
  final Color counterWarningColor;
  final Color requirementPassedColor;
  final bool enableHaptic;

  // ─── Per-state resolved border strokes ──────────────────────
  final ResolvedBorderSide enabledBorder;
  final ResolvedBorderSide focusedBorder;
  final ResolvedBorderSide errorBorder;
  final ResolvedBorderSide focusedErrorBorder;
  final ResolvedBorderSide disabledBorder;

  /// True when any state draws a gradient stroke — selects the
  /// custom-paint border path in the widget.
  bool get hasGradientBorder =>
      enabledBorder.hasGradient ||
      focusedBorder.hasGradient ||
      errorBorder.hasGradient ||
      focusedErrorBorder.hasGradient ||
      disabledBorder.hasGradient;

  static ResolvedBorderSide _resolveSide(
    TextFieldBorderStyle border,
    TextFieldBorderState state,
    Color fallbackColor,
    double fallbackWidth, {
    bool restingTransparent = false,
  }) {
    final side = border.sideFor(state);
    final width = side.width ?? fallbackWidth;
    // A ZERO-WIDTH side is no side. It used to paint anyway for every
    // state but the resting one, so `focused: TextFieldBorderSide(
    // width: 0)` — the only way to ask for a field with no focus
    // ring — still drew one.
    final paints =
        width > 0 &&
        (restingTransparent
            ? (side.color != null || side.gradient != null)
            : true);
    return ResolvedBorderSide(
      color: side.color ?? fallbackColor,
      width: width,
      gradient: side.gradient,
      paints: paints,
    );
  }
}
