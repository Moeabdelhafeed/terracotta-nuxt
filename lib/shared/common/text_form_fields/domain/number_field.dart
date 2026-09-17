import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/localization/strings/validator_strings.dart';
import '../../../module/text_field/global_text_field.dart';

/// Integer / decimal number field. Flip [allowDecimal] for decimal input
/// (single `.`), [allowNegative] for a leading `-`. [min] / [max] bound
/// the value with localized errors; [onValueChanged] emits the parsed
/// number (null while empty / mid-entry like `-` or `1.`).
class NumberField extends StatelessWidget {
  const NumberField({
    super.key,
    required this.controller,
    this.onValueChanged,
    this.onChanged,
    this.onSubmitted,
    this.label,
    this.identifier,
    this.hint,
    this.enabled = true,
    this.readOnly = false,
    this.errorText,
    this.validator,
    this.asyncValidator,
    this.asyncDebounce,
    this.focusNode,
    this.textInputAction = TextInputAction.done,
    this.validationMode = ValidationMode.onInteraction,
    this.deferToParentForm = true,
    this.errorIcon,
    this.errorBuilder,
    this.messages = const [],
    this.showSuccess = false,
    this.successText,
    this.allowDecimal = false,
    this.allowNegative = false,
    this.required = false,
    this.min,
    this.max,
    this.maxLength,
    this.textAlign,
    this.prefixIcon,
    this.suffixWidget,
    this.suffix,
    this.style,
    this.sizing,
  });

  final TextEditingController controller;

  /// Parsed value on every change — null while empty or not yet a
  /// number (`-`, `1.`).
  final ValueChanged<num?>? onValueChanged;

  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final String? label;
  final String? identifier;
  final String? hint;
  final bool enabled;
  final bool readOnly;
  final String? errorText;

  /// Sync check. Null → [required] + parseability + [min] / [max]
  /// (localized "must be at least/most N").
  final String? Function(String?)? validator;

  /// Server-side check. Runs after the sync validator passes.
  final Future<String?> Function(String value)? asyncValidator;

  /// Defaults to [TextFieldDefaults.asyncValidatorDebounce].
  final Duration? asyncDebounce;

  final FocusNode? focusNode;
  final TextInputAction textInputAction;
  final ValidationMode validationMode;

  /// Keep `true` inside a `Form`; `false` for standalone fields.
  final bool deferToParentForm;

  /// Icon shown before the error message row.
  final IconData? errorIcon;

  /// Full control over the error row.
  final Widget Function(BuildContext context, String message)? errorBuilder;

  /// Status rows below the field (sorted by severity).
  final List<FieldMessage> messages;

  /// Show a success row when the field is valid (with optional [successText]).
  final bool showSuccess;
  final String? successText;

  final bool allowDecimal;
  final bool allowNegative;

  /// Empty input fails validation ("Number cannot be empty"). When
  /// `false` an empty field is valid — pair with [min]/[max] for
  /// optional bounded inputs.
  final bool required;

  /// Inclusive bounds — violations get localized range errors.
  final num? min;
  final num? max;

  final int? maxLength;

  /// Text alignment inside the box (steppers center it).
  final TextAlign? textAlign;

  final Widget? prefixIcon;
  final Widget? suffixWidget;

  /// Structured trailing slot — wins over [suffixWidget].
  final TextFieldSuffix? suffix;

  /// Per-call visual override (wins over the app-wide theme).
  final TextFieldStyle? style;

  /// Box geometry (height / width / fit-to-content / density).
  final TextFieldSizing? sizing;

  String? _defaultValidator(String? value) {
    final text = (value ?? '').replaceAll(',', '');
    if (text.isEmpty) {
      return required ? ValidatorStrings.numberCannotBeEmpty : null;
    }
    final parsed = num.tryParse(text);
    if (parsed == null) return ValidatorStrings.mustBeAValidNumber;
    if (min != null && parsed < min!) {
      return ValidatorStrings.mustBeAtLeastN(min!);
    }
    if (max != null && parsed > max!) {
      return ValidatorStrings.mustBeAtMostN(max!);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // Anchored patterns (like the old `GlobalTextFormField.number`
    // factory) so a second `.` or a mid-string `-` is rejected —
    // a plain character class would let `1.2.3` / `1-2` through.
    final TextInputFormatter formatter;
    if (allowDecimal) {
      formatter = FilteringTextInputFormatter.allow(
        allowNegative ? RegExp(r'^-?\d*\.?\d*$') : RegExp(r'^\d*\.?\d*$'),
      );
    } else {
      formatter = allowNegative
          ? FilteringTextInputFormatter.allow(RegExp(r'^-?\d*$'))
          : FilteringTextInputFormatter.digitsOnly;
    }

    return GlobalTextFormField(
      controller: controller,
      label: label,
      identifier: identifier,
      hint: hint ?? '',
      focusNode: focusNode,
      style: style ?? const TextFieldStyle(),
      sizing: sizing ?? const TextFieldSizing(),
      messages: messages,
      behavior: TextFieldBehavior(
        keyboardType: TextInputType.numberWithOptions(
          decimal: allowDecimal,
          signed: allowNegative,
        ),
        textInputAction: textInputAction,
        inputFormatters: [formatter],
        maxLength: maxLength,
        enabled: enabled,
        readOnly: readOnly,
        autoDetectDirection: false,
        textAlign: textAlign,
      ),
      validation: TextFieldValidation(
        validator: validator ?? _defaultValidator,
        asyncValidator: asyncValidator,
        asyncDebounce:
            asyncDebounce ?? TextFieldDefaults.asyncValidatorDebounce,
        errorText: errorText,
        mode: validationMode,
        deferToParentForm: deferToParentForm,
        errorIcon: errorIcon,
        errorBuilder: errorBuilder,
        // Bounds / requiredness can flip at runtime.
        revalidateKey: (required, min, max),
      ),
      features: TextFieldFeatures(
        showSuccess: showSuccess,
        successText: successText,
      ),
      slots: TextFieldSlots(
        prefixIcon: prefixIcon,
        suffix:
            suffix ??
            (suffixWidget == null
                ? null
                : TextFieldSuffix.widget(suffixWidget!)),
      ),
      callbacks: TextFieldCallbacks(
        onChanged: (value) {
          onChanged?.call(value);
          onValueChanged?.call(num.tryParse(value.replaceAll(',', '')));
        },
        onSubmitted: onSubmitted,
      ),
    );
  }
}
