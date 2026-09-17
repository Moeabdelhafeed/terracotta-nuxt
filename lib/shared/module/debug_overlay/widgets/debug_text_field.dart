import 'package:flutter/material.dart';

import '../../text_field/text_field.dart';
import '../debug_overlay_models.dart';

/// Error red shared by the overlay's field surfaces (mirrors
/// [DebugOverlayTheme.levelColor] for `error`).
const kDebugFieldErrorColor = Color(0xFFEF5350);

/// The pinned console [TextFieldStyle] every debug-overlay field rides —
/// ONE definition instead of the nine hand-rolled [InputDecoration]s the
/// views used to copy-paste (and drift: 6px vs 8px radius between the
/// two sim views).
///
/// Not a `const`: [DebugOverlayTheme.accent] resolves the flavor color
/// at runtime.
TextFieldStyle debugTextFieldStyle({
  Color fillColor = DebugOverlayTheme.bg,
  bool showBorder = true,
  double radius = 8,
  double fontSize = 12,
  EdgeInsetsGeometry contentPadding = const EdgeInsets.symmetric(
    horizontal: 10,
    vertical: 10,
  ),
}) {
  return TextFieldStyle(
    borderRadius: BorderRadius.circular(radius),
    contentPadding: contentPadding,
    fillColor: fillColor,
    textColor: DebugOverlayTheme.text,
    iconColor: DebugOverlayTheme.textDim,
    hintStyle: DebugOverlayTheme.mono.copyWith(
      fontSize: fontSize,
      color: DebugOverlayTheme.textDimmer,
    ),
    enableHaptic: false,
    border: TextFieldBorderStyle(
      base: showBorder
          ? const TextFieldBorderSide(color: DebugOverlayTheme.border, width: 1)
          : const TextFieldBorderSide(color: Colors.transparent, width: 0),
      focused: TextFieldBorderSide(color: DebugOverlayTheme.accent, width: 1),
      error: const TextFieldBorderSide(color: kDebugFieldErrorColor, width: 1),
      focusedError: const TextFieldBorderSide(
        color: kDebugFieldErrorColor,
        width: 1,
      ),
    ),
  );
}

/// Pins the console typography + accent selection colors for any
/// text-field-based primitive (fields, dropdown triggers) inside the
/// overlay. [GlobalTextFormField] reads its editor style from
/// `textTheme.bodyMedium`, which this override points at the overlay's
/// mono face — the style bag has no full-TextStyle slot for the editor.
class DebugConsoleTheme extends StatelessWidget {
  const DebugConsoleTheme({
    super.key,
    required this.child,
    this.fontSize = 12,
  });

  final Widget child;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = DebugOverlayTheme.accent;
    return Theme(
      data: theme.copyWith(
        textTheme: theme.textTheme.copyWith(
          bodyMedium: DebugOverlayTheme.mono.copyWith(fontSize: fontSize),
        ),
        colorScheme: theme.colorScheme.copyWith(primary: accent),
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: accent,
          selectionColor: accent.withValues(alpha: 0.3),
          selectionHandleColor: accent,
        ),
      ),
      child: child,
    );
  }
}

/// THE text input for debug-overlay views — a [GlobalTextFormField]
/// wearing the pinned console style ([debugTextFieldStyle]) so the nine
/// previously hand-rolled fields share one look and one implementation.
///
/// * `showBorder: false` gives the borderless filled variant (sim value
///   rows, scenario name, clipboard editor); the accent focus stroke
///   stays.
/// * [errorText] renders through the module's message column (icon +
///   red border) — replaces the hand-built error rows.
/// * Multiline via [minLines]/[maxLines] (the former `_MonoTextArea`).
class DebugTextField extends StatelessWidget {
  const DebugTextField({
    super.key,
    required this.controller,
    this.hint = '',
    this.onChanged,
    this.onSubmitted,
    this.keyboardType,
    this.minLines,
    this.maxLines = 1,
    this.enabled = true,
    this.autofocus = false,
    this.focusNode,
    this.showBorder = true,
    this.fillColor = DebugOverlayTheme.bg,
    this.radius = 8,
    this.fontSize = 12,
    this.contentPadding,
    this.prefixIcon,
    this.prefixIconConstraints,
    this.suffix,
    this.suffixIconConstraints,
    this.errorText,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputType? keyboardType;
  final int? minLines;
  final int? maxLines;
  final bool enabled;
  final bool autofocus;
  final FocusNode? focusNode;

  /// `false` → borderless filled variant (accent focus stroke kept).
  final bool showBorder;

  final Color fillColor;
  final double radius;
  final double fontSize;
  final EdgeInsetsGeometry? contentPadding;

  final Widget? prefixIcon;
  final BoxConstraints? prefixIconConstraints;
  final TextFieldSuffix? suffix;
  final BoxConstraints? suffixIconConstraints;

  /// Non-null → error row below the field + red border.
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return DebugConsoleTheme(
      fontSize: fontSize,
      child: GlobalTextFormField(
        controller: controller,
        hint: hint,
        focusNode: focusNode,
        style: debugTextFieldStyle(
          fillColor: fillColor,
          showBorder: showBorder,
          radius: radius,
          fontSize: fontSize,
          contentPadding:
              contentPadding ??
              const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        ),
        behavior: TextFieldBehavior(
          keyboardType: keyboardType ?? TextInputType.text,
          minLines: minLines,
          maxLines: maxLines,
          enabled: enabled,
          autofocus: autofocus,
        ),
        sizing: const TextFieldSizing(isDense: true),
        slots: TextFieldSlots(
          prefixIcon: prefixIcon,
          prefixIconConstraints: prefixIconConstraints,
          suffix: suffix,
          suffixIconConstraints: suffixIconConstraints,
        ),
        callbacks: TextFieldCallbacks(
          onChanged: onChanged,
          onSubmitted: onSubmitted,
        ),
        messages: [if (errorText != null) FieldMessage.error(errorText!)],
      ),
    );
  }
}
