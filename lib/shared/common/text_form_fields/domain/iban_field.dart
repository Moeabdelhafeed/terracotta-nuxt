import 'package:flutter/material.dart';

import '../../../../core/extensions/theme_colors_extension.dart';
import '../../../../core/utils/validators/validators.dart';
import '../../../module/text_field/global_text_field.dart';

/// IBAN field — uppercases + groups the account number live and
/// validates the mod-97 checksum via [Validators.validateIban]. Defaults
/// to [ValidationMode.onFocusLoss] so the checksum only fires once entry
/// is complete.
class IbanField extends StatelessWidget {
  const IbanField({
    super.key,
    required this.controller,
    this.onChanged,
    this.onSubmitted,
    this.label,
    this.identifier,
    this.hint = 'XX00 0000 0000 0000 0000 00',
    this.enabled = true,
    this.readOnly = false,
    this.errorText,
    this.validator,
    this.asyncValidator,
    this.asyncDebounce,
    this.focusNode,
    this.textInputAction = TextInputAction.next,
    this.validationMode = ValidationMode.onFocusLoss,
    this.deferToParentForm = true,
    this.errorIcon,
    this.errorBuilder,
    this.messages = const [],
    this.showSuccess = false,
    this.successText,
    this.showPrefixIcon = true,
    this.suffix,
    this.style,
    this.sizing,
    this.autofillHints,
  });

  final TextEditingController controller;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final String? label;
  final String? identifier;
  final String hint;
  final bool enabled;
  final bool readOnly;
  final String? errorText;

  /// Sync check. Null → [Validators.validateIban] (mod-97 checksum).
  final String? Function(String?)? validator;

  /// Server-side check (e.g. account ownership lookup). Runs after the
  /// sync validator passes.
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

  final bool showPrefixIcon;

  /// Trailing slot.
  final TextFieldSuffix? suffix;

  /// Per-call visual override (wins over the app-wide theme).
  final TextFieldStyle? style;

  /// Box geometry (height / width / fit-to-content / density).
  final TextFieldSizing? sizing;

  /// Platform autofill (no standard IBAN hint exists — null by default).
  final List<String>? autofillHints;

  @override
  Widget build(BuildContext context) {
    return GlobalTextFormField(
      controller: controller,
      label: label,
      identifier: identifier,
      hint: hint,
      focusNode: focusNode,
      style: style ?? const TextFieldStyle(),
      sizing: sizing ?? const TextFieldSizing(),
      messages: messages,
      behavior: TextFieldBehavior(
        textInputAction: textInputAction,
        // The formatter uppercases anyway — this keys the soft keyboard
        // into caps from the start.
        textCapitalization: TextCapitalization.characters,
        inputFormatters: [IbanInputFormatter()],
        maxLength: 42,
        enabled: enabled,
        readOnly: readOnly,
        autoDetectDirection: false,
        autofillHints: autofillHints,
      ),
      validation: TextFieldValidation(
        validator: validator ?? Validators.validateIban,
        asyncValidator: asyncValidator,
        asyncDebounce:
            asyncDebounce ?? TextFieldDefaults.asyncValidatorDebounce,
        errorText: errorText,
        mode: validationMode,
        deferToParentForm: deferToParentForm,
        errorIcon: errorIcon,
        errorBuilder: errorBuilder,
      ),
      features: TextFieldFeatures(
        showSuccess: showSuccess,
        successText: successText,
      ),
      slots: TextFieldSlots(
        prefixIcon: showPrefixIcon
            ? Padding(
                padding: const EdgeInsetsDirectional.only(start: 12, end: 8),
                child: Icon(
                  Icons.account_balance_outlined,
                  color: context.iconColors.primary,
                ),
              )
            : null,
        suffix: suffix,
      ),
      callbacks: TextFieldCallbacks(
        onChanged: onChanged,
        onSubmitted: onSubmitted,
      ),
    );
  }
}
