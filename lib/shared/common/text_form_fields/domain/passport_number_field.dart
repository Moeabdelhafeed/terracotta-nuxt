import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/extensions/theme_colors_extension.dart';
import '../../../../core/localization/strings/field_strings.dart';
import '../../../../core/utils/validators/validators.dart';
import '../../../module/text_field/global_text_field.dart';

/// Passport-number input — uppercased as typed (ICAO 9303 documents are
/// canonical in uppercase), `A–Z 0–9` only, capped at [maxLength]
/// (9 = the ICAO machine-readable-zone width).
///
/// KYC flows usually pair this with a server-side document check — pass
/// it as [asyncValidator] (debounced, gated behind the sync check).
class PassportNumberField extends StatelessWidget {
  const PassportNumberField({
    super.key,
    required this.controller,
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
    this.textInputAction = TextInputAction.next,
    this.validationMode = ValidationMode.onInteraction,
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
    this.maxLength = 9,
    this.autofillHints,
  });

  final TextEditingController controller;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final String? label;
  final String? identifier;

  /// Null → localized default.
  final String? hint;
  final bool enabled;
  final bool readOnly;
  final String? errorText;

  /// Sync check. Null → [Validators.validatePassportNumber].
  final String? Function(String?)? validator;

  /// Server-side check (e.g. a KYC document lookup). Runs after the sync
  /// validator passes; debounced by [asyncDebounce].
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

  /// Typing cap — 9 covers the ICAO MRZ document-number field; raise it
  /// for booklet numbers that run longer.
  final int maxLength;

  /// Platform autofill (no standard passport hint exists — null by
  /// default).
  final List<String>? autofillHints;

  @override
  Widget build(BuildContext context) {
    return GlobalTextFormField(
      controller: controller,
      label: label,
      identifier: identifier,
      hint: hint ?? FieldStrings.passportHint,
      focusNode: focusNode,
      style: style ?? const TextFieldStyle(),
      sizing: sizing ?? const TextFieldSizing(),
      messages: messages,
      behavior: TextFieldBehavior(
        // visiblePassword keeps autocorrect/suggestions off the document
        // number while still showing what's typed.
        keyboardType: TextInputType.visiblePassword,
        textInputAction: textInputAction,
        textCapitalization: TextCapitalization.characters,
        inputFormatters: [
          UpperCaseInputFormatter(),
          FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
          LengthLimitingTextInputFormatter(maxLength),
        ],
        enabled: enabled,
        readOnly: readOnly,
        autoDetectDirection: false,
        autofillHints: autofillHints,
      ),
      validation: TextFieldValidation(
        validator: validator ?? Validators.validatePassportNumber,
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
                  Icons.badge_outlined,
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
