import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../module/text_field/global_text_field.dart';

/// Plain single-line text field — the default pick when no
/// specialized variant (email, password, phone…) applies.
///
/// Canonical contract: `controller` / `onChanged` / `label` /
/// `identifier` / `hint` / `enabled` / `readOnly` / `errorText` /
/// `validator` / `focusNode` / `textInputAction` / `prefixIcon` /
/// `suffixWidget` on top of `GlobalTextFormField`'s full surface.
class SimpleTextField extends StatelessWidget {
  const SimpleTextField({
    super.key,
    required this.controller,
    this.label,
    this.identifier,
    this.required = false,
    this.hint,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.errorText,
    this.enabled = true,
    this.readOnly = false,
    this.focusNode,
    this.textInputAction,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.prefixIcon,
    this.suffixWidget,
    this.suffix,
    this.style,
    this.sizing,
    this.validationMode = ValidationMode.onInteraction,
    this.maxLength,
    this.showClearButton = false,
  });

  final TextEditingController controller;
  final String? label;
  final String? identifier;

  /// Appends a `*` to the identifier (or hint) — see
  /// [GlobalTextFormField.required].
  final bool required;
  final String? hint;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final String? Function(String?)? validator;
  final String? errorText;
  final bool enabled;
  final bool readOnly;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? prefixIcon;

  /// Bare trailing widget — kept for convenience; the structured
  /// [suffix] wins when both are set.
  final Widget? suffixWidget;

  /// Structured trailing slot (`TextFieldSuffix.icon` / `.loading` /
  /// `.widget`) — wins over [suffixWidget].
  final TextFieldSuffix? suffix;

  /// Per-call visual override (wins over the app-wide theme).
  final TextFieldStyle? style;

  /// Box geometry (height / width / fit-to-content / density).
  final TextFieldSizing? sizing;

  final ValidationMode validationMode;
  final int? maxLength;
  final bool showClearButton;

  @override
  Widget build(BuildContext context) {
    return GlobalTextFormField(
      controller: controller,
      label: label,
      identifier: identifier,
      required: required,
      hint: hint ?? '',
      focusNode: focusNode,
      style: style ?? const TextFieldStyle(),
      sizing: sizing ?? const TextFieldSizing(),
      behavior: TextFieldBehavior(
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        inputFormatters: inputFormatters,
        maxLength: maxLength,
        enabled: enabled,
        readOnly: readOnly,
      ),
      validation: TextFieldValidation(
        validator: validator,
        errorText: errorText,
        mode: validationMode,
      ),
      slots: TextFieldSlots(
        prefixIcon: prefixIcon,
        suffix:
            suffix ??
            (suffixWidget == null
                ? null
                : TextFieldSuffix.widget(suffixWidget!)),
      ),
      features: TextFieldFeatures(showClearButton: showClearButton),
      callbacks: TextFieldCallbacks(
        onChanged: onChanged,
        onSubmitted: onSubmitted,
      ),
    );
  }
}
