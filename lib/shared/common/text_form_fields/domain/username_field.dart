import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/extensions/theme_colors_extension.dart';
import '../../../../core/localization/strings/field_strings.dart';
import '../../../../core/utils/validators/validators.dart';
import '../../../module/text_field/global_text_field.dart';

/// Username / handle input — lowercases as typed ([lowercaseInput]),
/// restricts keystrokes to the handle charset (`a–z 0–9 . _ -`, matching
/// [Validators.usernamePattern]) and validates 3–20 chars by default.
///
/// Uniqueness is a server question — pass an [asyncValidator]
/// (`"already taken"`), debounced and gated behind the sync check, with
/// a suffix spinner while in flight:
///
/// ```dart
/// UsernameField(
///   controller: username,
///   asyncValidator: (v) async =>
///       await api.usernameTaken(v) ? 'Already taken' : null,
///   showSuccess: true,
/// )
/// ```
class UsernameField extends StatelessWidget {
  const UsernameField({
    super.key,
    required this.controller,
    this.onChanged,
    this.onSubmitted,
    this.label,
    this.identifier,
    this.required = true,
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
    this.maxLength = Validators.maxUsernameLength,
    this.lowercaseInput = true,
    this.autofillHints = const [AutofillHints.username],
  });

  final TextEditingController controller;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final String? label;
  final String? identifier;

  /// Default true (the field is usually mandatory): shows the `*` marker
  /// on the identifier header (or the hint when there is none).
  final bool required;

  /// Null → localized default.
  final String? hint;
  final bool enabled;
  final bool readOnly;
  final String? errorText;

  /// Sync check. Null → [Validators.validateUsername] (3–20 chars,
  /// handle charset).
  final String? Function(String?)? validator;

  /// Server-side check (the uniqueness lookup). Runs only after the sync
  /// [validator] passes; debounced by [asyncDebounce].
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

  /// Typing cap. Defaults to the validator's ceiling so the field can't
  /// accept text the default validator rejects.
  final int maxLength;

  /// Lower-case as the user types — handles are case-insensitive on
  /// every major platform. Off keeps the typed casing (validation still
  /// accepts both).
  final bool lowercaseInput;

  /// Platform autofill. Defaults to `[AutofillHints.username]`; pass
  /// `[AutofillHints.newUsername]` on sign-up forms, or `null` to disable.
  final List<String>? autofillHints;

  /// Keystroke filter — mirrors [Validators.usernamePattern]'s charset
  /// (uppercase admitted, then lowercased by the case formatter).
  static final _allowed = RegExp(r'[a-zA-Z0-9._-]');

  @override
  Widget build(BuildContext context) {
    return GlobalTextFormField(
      controller: controller,
      label: label,
      identifier: identifier,
      required: required,
      hint: hint ?? FieldStrings.usernameHint,
      focusNode: focusNode,
      style: style ?? const TextFieldStyle(),
      sizing: sizing ?? const TextFieldSizing(),
      messages: messages,
      behavior: TextFieldBehavior(
        keyboardType: TextInputType.text,
        textInputAction: textInputAction,
        maxLength: maxLength,
        inputFormatters: [
          FilteringTextInputFormatter.allow(_allowed),
          if (lowercaseInput) LowerCaseInputFormatter(),
        ],
        enabled: enabled,
        readOnly: readOnly,
        autoDetectDirection: false,
        autofillHints: autofillHints,
      ),
      validation: TextFieldValidation(
        validator: validator ?? Validators.validateUsername,
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
                  Icons.alternate_email_rounded,
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
