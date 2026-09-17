import 'package:flutter/material.dart';

import '../../../../core/extensions/theme_colors_extension.dart';
import '../../../../core/localization/strings/text_field_strings.dart';
import '../../../../core/localization/strings/validator_strings.dart';
import '../../../../core/utils/password_strength_estimator.dart';
import '../../../../core/utils/validators/validators.dart';
import '../../../../data/services/breached_password_verifier.dart';
import '../../../../data/services/screen_capture_service.dart';
import '../../../module/text_field/global_text_field.dart';

/// What the password field is being used FOR — drives the default hint,
/// validator, autofill hint and keyboard action.
enum PasswordFieldMode {
  /// Entering an existing password (sign-in). Light validation,
  /// `AutofillHints.password` so managers offer to FILL.
  login,

  /// Setting a new password (sign-up / change-password). Complexity
  /// validation, `AutofillHints.newPassword` so managers offer to GENERATE.
  /// Pair with [PasswordField.requirements] + strength bar.
  create,

  /// Re-entering the new password — must match [PasswordField.matchController].
  confirm,
}

/// Password input — one widget, three modes ([PasswordFieldMode]).
///
/// Presets per mode (all overridable): hint, validator, autofill,
/// keyboard action. Always: `visiblePassword` keyboard, obscured text with
/// the module's built-in visibility toggle, lock prefix icon, LTR-only.
/// Never trims — spaces are legal in passwords.
///
/// ```dart
/// // Sign-in
/// PasswordField(controller: pass)
///
/// // Sign-up pair
/// PasswordField(
///   controller: pass,
///   mode: PasswordFieldMode.create,
///   requirements: PasswordField.createRequirements(),
///   showStrengthBar: true,
///   hideErrorWhenRequirements: true,
/// )
/// PasswordField(
///   controller: confirm,
///   mode: PasswordFieldMode.confirm,
///   matchController: pass,
/// )
/// ```
///
/// Confirm-mode note: inside a `Form` (default `deferToParentForm: true`,
/// live [validationMode]) editing the ORIGINAL password re-validates the
/// confirm field automatically (Form auto-validation covers every field).
/// Standalone confirm fields re-check only on their own triggers.
class PasswordField extends StatelessWidget {
  const PasswordField({
    super.key,
    required this.controller,
    this.mode = PasswordFieldMode.login,
    this.matchController,
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
    this.textInputAction,
    this.validationMode = ValidationMode.onInteraction,
    this.deferToParentForm = true,
    this.requirements,
    this.hidePassedRequirements = false,
    this.sortPassedRequirements = false,
    this.hideErrorWhenRequirements = false,
    this.requirementsTextOnly = false,
    this.showStrengthBar = false,
    this.errorIcon,
    this.errorBuilder,
    this.messages = const [],
    this.showSuccess = false,
    this.successText,
    this.showPrefixIcon = false,
    this.obscured,
    this.onObscureToggled,
    this.suffix,
    this.style,
    this.sizing,
    this.autofillHints,
    this.detectScreenCapture = false,
    this.showGenerateButton,
    this.passwordGenerator,
    this.confirmController,
    this.checkBreached = false,
    this.warnCapsLock = true,
    this.revealMode = TextFieldRevealMode.toggle,
    this.revealTimeout,
    this.strengthEstimator,
    this.onStrengthChanged,
    this.enableCopy = true,
    this.enablePaste = true,
    this.animations = const AnimationsConfig(),
  }) : assert(
         mode != PasswordFieldMode.confirm || matchController != null,
         'PasswordFieldMode.confirm requires matchController '
         '(the original password field\'s controller).',
       );

  /// Sensible default checklist for [PasswordFieldMode.create] — the same
  /// rules as `Validators.validateCreatePassword` (upper / lower / digit /
  /// special) with a length floor of [minLength]. When requirements are
  /// set they double as the validator, so checklist and error can't
  /// drift apart.
  static List<FieldRequirement> createRequirements({int minLength = 8}) => [
    FieldRequirement.minLength(minLength),
    FieldRequirement.uppercase(),
    FieldRequirement.lowercase(),
    FieldRequirement.digit(),
    FieldRequirement.specialChar(),
  ];

  final TextEditingController controller;

  /// See [PasswordFieldMode].
  final PasswordFieldMode mode;

  /// The ORIGINAL password controller to match against —
  /// required in [PasswordFieldMode.confirm].
  final TextEditingController? matchController;

  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final String? label;
  final String? identifier;

  /// Default true (the field is usually mandatory): shows the `*` marker
  /// on the identifier header (or the hint when there is none).
  final bool required;

  /// Null → per-mode default ('Enter your password' / 'Create a password' /
  /// 'Confirm your password').
  final String? hint;

  final bool enabled;
  final bool readOnly;
  final String? errorText;

  /// Sync check. Null → per-mode default: `validatePassword` (login),
  /// `validateCreatePassword` (create), match-check (confirm).
  final String? Function(String?)? validator;

  /// Server-side check (e.g. a breached-password lookup). Runs only after
  /// the sync [validator] passes; debounced by [asyncDebounce].
  final Future<String?> Function(String value)? asyncValidator;

  /// Defaults to [TextFieldDefaults.asyncValidatorDebounce].
  final Duration? asyncDebounce;

  final FocusNode? focusNode;

  /// Null → `next` in create mode (a confirm field follows), else `done`.
  final TextInputAction? textInputAction;

  final ValidationMode validationMode;

  /// Keep `true` inside a `Form`; set `false` for standalone fields so the
  /// internal triggers (focus loss / submit / live) drive validation.
  final bool deferToParentForm;

  /// Live requirements checklist below the field — see [createRequirements]
  /// for the standard create-mode set.
  final List<FieldRequirement>? requirements;

  /// Hide a requirement row once it passes (animated).
  final bool hidePassedRequirements;

  /// Slide passed requirements to the bottom (animated reorder) so unmet
  /// ones stay prominent. Ignored with [hidePassedRequirements].
  final bool sortPassedRequirements;

  /// Let the checklist report failure instead of the red error row.
  final bool hideErrorWhenRequirements;

  /// Checklist without the check/circle icons.
  final bool requirementsTextOnly;

  /// Red → orange → green bar driven by the passed-requirements ratio.
  /// Requires [requirements].
  final bool showStrengthBar;

  /// Icon shown before the error message row.
  final IconData? errorIcon;

  /// Full control over the error row.
  final Widget Function(BuildContext context, String message)? errorBuilder;

  /// Status rows below the field (sorted by severity).
  final List<FieldMessage> messages;

  /// Show a success row when the field is valid (with optional [successText]).
  final bool showSuccess;
  final String? successText;

  /// Whether the text starts hidden. Null → hidden.
  ///
  /// Exists so a CALLER can keep the choice across screens: the module
  /// owns the toggle, and without a way in, every field starts hidden
  /// again however the last one was left.
  final bool? obscured;

  /// Fires whenever the reader flips the eye — including the automatic
  /// re-hide after `revealTimeout`.
  final ValueChanged<bool>? onObscureToggled;

  /// Padlock ahead of the dots.
  ///
  /// Off by default: the design draws the box with the eye toggle
  /// alone. A field already labelled "كلمة السر" with its content
  /// masked does not need a second glyph saying the same thing, and the
  /// padlock reads as a security claim the field is not making.
  final bool showPrefixIcon;

  /// Trailing slot — NOTE: an explicit suffix REPLACES the built-in
  /// visibility toggle.
  final TextFieldSuffix? suffix;

  /// Per-call visual override (wins over the app-wide theme).
  final TextFieldStyle? style;

  /// Box geometry (height / width / fit-to-content / density).
  final TextFieldSizing? sizing;

  /// Platform autofill. Null → per-mode default (`password` for login,
  /// `newPassword` for create/confirm); pass `const []` to disable.
  final List<String>? autofillHints;

  /// React to screen recording / sharing ([ScreenCaptureService]): while the
  /// screen is captured, a warning row appears under the field and the input
  /// obscures INSTANTLY (no last-character peek). iOS 11+ and Android 15+;
  /// silently inactive elsewhere.
  final bool detectScreenCapture;

  /// Generate button (✨) next to the visibility toggle — fills the field
  /// with a secure random password, reveals it (unless the screen is
  /// captured) and validates. Null → on in [PasswordFieldMode.create],
  /// off otherwise.
  final bool? showGenerateButton;

  /// Custom generator (default: `PasswordGenerator.generate` — 16 chars,
  /// guaranteed upper/lower/digit/symbol, no ambiguous glyphs).
  final String Function()? passwordGenerator;

  /// Linked confirm field's controller (create mode): the generate button
  /// also fills it — what password managers do.
  final TextEditingController? confirmController;

  /// Check against Have-I-Been-Pwned (k-anonymity — the password never
  /// leaves the device). Runs after the sync validator, BEFORE any caller
  /// [asyncValidator]. Fail-open offline. See [BreachedPasswordVerifier].
  final bool checkBreached;

  /// Warning row while focused with Caps Lock on (hardware keyboards).
  /// Default true — inert without a hardware keyboard.
  final bool warnCapsLock;

  /// Tap-to-toggle (default) or press-and-hold reveal.
  final TextFieldRevealMode revealMode;

  /// Auto re-obscure this long after a toggle/generate reveal.
  final Duration? revealTimeout;

  /// Real strength estimation (0–1, e.g. zxcvbn-style) — drives the bar +
  /// [onStrengthChanged] instead of the requirements ratio.
  final double Function(String value)? strengthEstimator;

  /// Fired when the computed strength changes — e.g. gate the submit button.
  final ValueChanged<double>? onStrengthChanged;

  /// Set false to block copying the password out of the field.
  final bool enableCopy;

  /// Set false to block pasting INTO the field (e.g. force retyping on a
  /// confirm field).
  final bool enablePaste;

  /// Animation config — shake-on-error, input pulse, and the message-row
  /// entrance animation/direction (`messageAnimation` / `messageSlideFrom`).
  final AnimationsConfig animations;

  /// Chained async check: breach lookup (when [checkBreached]) gates the
  /// caller's [asyncValidator].
  Future<String?> _effectiveAsyncValidator(String value) async {
    if (checkBreached) {
      final err = await BreachedPasswordVerifier.instance.validateNotBreached(
        value,
      );
      if (err != null) return err;
    }
    return asyncValidator?.call(value);
  }

  String get _effectiveHint =>
      hint ??
      switch (mode) {
        PasswordFieldMode.login => TextFieldStrings.passwordHint,
        PasswordFieldMode.create => TextFieldStrings.passwordCreateHint,
        PasswordFieldMode.confirm => TextFieldStrings.passwordConfirmHint,
      };

  /// When a checklist is shown, IT is the policy — the validator passes
  /// iff every requirement passes (error = the first unmet label). This
  /// keeps the checklist and the red error from ever contradicting each
  /// other (e.g. a checklist without a special-char rule while the
  /// generic validator demands one).
  String? _requirementsValidator(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return ValidatorStrings.passwordCannotBeEmpty;
    for (final req in requirements!) {
      if (!req.test(v)) return req.label;
    }
    return null;
  }

  String? Function(String?) get _effectiveValidator {
    if (validator != null) return validator!;
    if (requirements != null &&
        requirements!.isNotEmpty &&
        mode != PasswordFieldMode.confirm) {
      return _requirementsValidator;
    }
    return switch (mode) {
      PasswordFieldMode.login => Validators.validatePassword,
      PasswordFieldMode.create => Validators.validateCreatePassword,
      PasswordFieldMode.confirm => (v) => Validators.validateConfirmPassword(
        matchController!.text,
        v,
      ),
    };
  }

  List<String>? get _effectiveAutofill {
    final hints =
        autofillHints ??
        [
          mode == PasswordFieldMode.login
              ? AutofillHints.password
              : AutofillHints.newPassword,
        ];
    return hints.isEmpty ? null : hints;
  }

  @override
  Widget build(BuildContext context) {
    if (!detectScreenCapture) return _buildField(context, captured: false);
    return ListenableBuilder(
      listenable: ScreenCaptureService.instance,
      builder: (context, _) => _buildField(
        context,
        captured: ScreenCaptureService.instance.isCaptured,
      ),
    );
  }

  Widget _buildField(BuildContext context, {required bool captured}) {
    return GlobalTextFormField(
      controller: controller,
      label: label,
      identifier: identifier,
      required: required,
      hint: _effectiveHint,
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
        keyboardType: TextInputType.visiblePassword,
        textInputAction:
            textInputAction ??
            (mode == PasswordFieldMode.create
                ? TextInputAction.next
                : TextInputAction.done),
        // The module renders its own visibility toggle (with tooltip) for
        // obscured fields when no explicit suffix is set.
        // ALWAYS true: this declares the field a password field, which
        // is what puts the eye there. Whether the text is showing is
        // `revealed` — turning this off hid the toggle along with the
        // masking, which is how the eye vanished the moment the
        // password was revealed.
        // ALWAYS true: this declares the field a password field, which
        // is what puts the eye there. Whether the text is showing is
        // `revealed` — turning this off hid the toggle along with the
        // masking, which is how the eye vanished the moment the
        // password was revealed.
        obscureText: true,
        revealed: obscured == null ? null : !obscured!,
        // While captured, never reveal the just-typed character.
        instantObscure: captured,
        enabled: enabled,
        readOnly: readOnly,
        autoDetectDirection: false,
        autofillHints: _effectiveAutofill,
        enableCopy: enableCopy,
        enablePaste: enablePaste,
        revealMode: revealMode,
        revealTimeout: revealTimeout,
      ),
      validation: TextFieldValidation(
        validator: _effectiveValidator,
        asyncValidator: (checkBreached || asyncValidator != null)
            ? _effectiveAsyncValidator
            : null,
        asyncDebounce:
            asyncDebounce ?? TextFieldDefaults.asyncValidatorDebounce,
        errorText: errorText,
        mode: validationMode,
        deferToParentForm: deferToParentForm,
        requirements: requirements,
        hidePassedRequirements: hidePassedRequirements,
        sortPassedRequirements: sortPassedRequirements,
        hideErrorWhenRequirements: hideErrorWhenRequirements,
        requirementsTextOnly: requirementsTextOnly,
        showStrengthBar: showStrengthBar,
        // Bar without a checklist → default to the built-in zxcvbn-inspired
        // estimator (catches Password1!-style weakness).
        strengthEstimator:
            strengthEstimator ??
            (showStrengthBar && requirements == null
                ? PasswordStrengthEstimator.estimate
                : null),
        onStrengthChanged: onStrengthChanged,
        errorIcon: errorIcon,
        errorBuilder: errorBuilder,
      ),
      features: TextFieldFeatures(
        showSuccess: showSuccess,
        successText: successText,
        animations: animations,
        showPasswordGenerate:
            showGenerateButton ?? mode == PasswordFieldMode.create,
        passwordGenerator: passwordGenerator,
        warnCapsLock: warnCapsLock,
        // Generating also fills the linked confirm field (what password
        // managers do).
        onPasswordGenerated: confirmController == null
            ? null
            : (password) => confirmController!.text = password,
      ),
      slots: TextFieldSlots(
        prefixIcon: showPrefixIcon
            ? Padding(
                padding: const EdgeInsetsDirectional.only(start: 12, end: 8),
                child: Icon(
                  Icons.lock_outline_rounded,
                  color: context.iconColors.primary,
                ),
              )
            : null,
        suffix: suffix,
      ),
      callbacks: TextFieldCallbacks(
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        onObscureToggled: onObscureToggled,
      ),
    );
  }
}
