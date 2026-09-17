import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/extensions/theme_colors_extension.dart';
import '../../../../core/localization/strings/text_field_strings.dart';
import '../../../../core/localization/strings/validator_strings.dart';
import '../../../../core/utils/validators/validators.dart';
import '../../../../data/services/screen_capture_service.dart';
import '../../../module/text_field/global_text_field.dart';

/// Card security-code field (CVV / CVC / CID) — digits only, exact
/// [length] (3, or 4 for Amex: wire `CreditCardField.onBrandChanged` →
/// `brand.cvvLength`). [obscure] renders bullets with the module's eye
/// toggle for shoulder-surfing-sensitive flows.
class CvvField extends StatelessWidget {
  const CvvField({
    super.key,
    required this.controller,
    this.length = 3,
    this.obscure = true,
    this.detectScreenCapture = false,
    this.onCompleted,
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
    this.showPrefixIcon = true,
    this.suffix,
    this.style,
    this.sizing,
    this.autofillHints = const [AutofillHints.creditCardSecurityCode],
  }) : assert(length == 3 || length == 4, 'CVV is 3 or 4 digits.');

  final TextEditingController controller;

  /// Exact digit count — 3 for most networks, 4 for Amex.
  final int length;

  /// Bullets + eye toggle instead of plain digits (default — the CVV is
  /// the card's secret).
  final bool obscure;

  /// While the screen is recorded / shared ([ScreenCaptureService]) the
  /// digits obscure INSTANTLY, a warning row shows, and the reveal
  /// toggle asks for confirmation — same treatment as `PasswordField`.
  final bool detectScreenCapture;

  /// Fires once when [length] valid digits are in — e.g. submit or
  /// close the keyboard.
  final ValueChanged<String>? onCompleted;

  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final String? label;
  final String? identifier;

  /// Null → `•` per expected digit.
  final String? hint;

  final bool enabled;
  final bool readOnly;
  final String? errorText;

  /// Sync check. Null → exactly [length] digits.
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

  final bool showPrefixIcon;

  /// Trailing slot — NOTE: with [obscure] an explicit suffix REPLACES
  /// the built-in visibility toggle.
  final TextFieldSuffix? suffix;

  /// Per-call visual override (wins over the app-wide theme).
  final TextFieldStyle? style;

  /// Box geometry (height / width / fit-to-content / density).
  final TextFieldSizing? sizing;

  /// Platform autofill. Defaults to
  /// `[AutofillHints.creditCardSecurityCode]`; pass `null` to disable.
  final List<String>? autofillHints;

  String? _defaultValidator(String? value) {
    if (value == null || value.isEmpty) {
      return ValidatorStrings.cardCvvCannotBeEmpty;
    }
    if (value.length != length || !Validators.digitsOnly.hasMatch(value)) {
      // Exact wording — the field only ACCEPTS [length] digits, so the
      // generic "3 or 4" would promise room that isn't there.
      return ValidatorStrings.cardCvvMustBeNDigits(length);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (!detectScreenCapture) return _buildField(context, false);
    return ListenableBuilder(
      listenable: ScreenCaptureService.instance,
      builder: (context, _) =>
          _buildField(context, ScreenCaptureService.instance.isCaptured),
    );
  }

  Widget _buildField(BuildContext context, bool captured) {
    final effectiveValidator = validator ?? _defaultValidator;
    return GlobalTextFormField(
      controller: controller,
      label: label,
      identifier: identifier,
      hint: hint ?? '•' * length,
      focusNode: focusNode,
      style: style ?? const TextFieldStyle(),
      sizing: sizing ?? const TextFieldSizing(),
      messages: [
        if (captured)
          FieldMessage.warning(
            TextFieldStrings.screenCaptureWarning,
            icon: Icons.screen_share_outlined,
          ),
        ...messages,
      ],
      behavior: TextFieldBehavior(
        keyboardType: TextInputType.number,
        textInputAction: textInputAction,
        obscureText: obscure || captured,
        instantObscure: captured,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(length),
        ],
        maxLength: length,
        enabled: enabled,
        readOnly: readOnly,
        autoDetectDirection: false,
        autofillHints: autofillHints,
      ),
      validation: TextFieldValidation(
        validator: effectiveValidator,
        asyncValidator: asyncValidator,
        asyncDebounce:
            asyncDebounce ?? TextFieldDefaults.asyncValidatorDebounce,
        errorText: errorText,
        mode: validationMode,
        deferToParentForm: deferToParentForm,
        errorIcon: errorIcon,
        errorBuilder: errorBuilder,
        // Amex flips the expected length at runtime (brand-linked CVV).
        revalidateKey: length,
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
                  Icons.shield_outlined,
                  color: context.iconColors.primary,
                ),
              )
            : null,
        suffix: suffix,
      ),
      callbacks: TextFieldCallbacks(
        onChanged: (value) {
          onChanged?.call(value);
          if (value.length == length && effectiveValidator(value) == null) {
            onCompleted?.call(value);
          }
        },
        onSubmitted: onSubmitted,
      ),
    );
  }
}
