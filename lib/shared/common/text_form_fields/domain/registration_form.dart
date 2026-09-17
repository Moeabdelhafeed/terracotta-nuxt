import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show TextInput;

import '../../../../core/localization/strings/consent_strings.dart';
import '../../../../core/tokens/extensions.dart';
import '../../../../core/utils/validators/validators.dart';
import '../../../module/checkbox/checkbox_models.dart' show CheckboxValidation;
import '../../../module/text_field/global_text_field.dart';
import '../../selection_fields/checkbox/consent_checkbox_field.dart';
import '../../selection_fields/checkbox/marketing_opt_in_checkbox.dart';
import 'email_field.dart';
import 'password_field.dart';
import 'phone_number_field.dart';

/// How a [RegistrationForm] collects the password.
enum RegPasswordMode {
  /// Passwordless sign-up (OTP / magic-link verification).
  none,

  /// Create only (no confirm re-entry).
  create,

  /// Create + confirm-matches pair.
  createConfirm,
}

/// The parsed value a [RegistrationForm] emits.
@immutable
class RegistrationFormData {
  const RegistrationFormData({
    this.email = '',
    this.phone,
    this.password = '',
    this.consentAccepted = true,
    this.marketingOptIn = false,
    required this.isValid,
  });

  /// Trimmed email — empty when [RegistrationForm.showEmail] is off.
  final String email;

  /// Parsed phone — null when [RegistrationForm.showPhone] is off.
  final PhoneNumber? phone;

  /// Empty under [RegPasswordMode.none].
  final String password;

  /// True when the consent checkbox is checked — or when the form shows
  /// no consent (no link handlers passed), so it never blocks.
  final bool consentAccepted;

  /// Marketing opt-in — always false when
  /// [RegistrationForm.showMarketingOptIn] is off.
  final bool marketingOptIn;

  /// Every shown identifier valid + password rules (incl. confirm match)
  /// pass.
  final bool isValid;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RegistrationFormData &&
          other.email == email &&
          other.phone == phone &&
          other.password == password &&
          other.consentAccepted == consentAccepted &&
          other.marketingOptIn == marketingOptIn &&
          other.isValid == isValid;

  @override
  int get hashCode => Object.hash(
    email,
    phone,
    password,
    consentAccepted,
    marketingOptIn,
    isValid,
  );

  @override
  String toString() =>
      'RegistrationFormData(email: $email, phone: ${phone?.e164}, valid: $isValid)';
}

/// The sign-up composite — identifiers × password policy in two knobs:
///
/// | showEmail | showPhone | passwordMode | flow |
/// |---|---|---|---|
/// | ✓ | ✓ | createConfirm | classic full registration |
/// | ✓ | — | create | email + password, no re-entry |
/// | — | ✓ | none | phone-first, OTP verify |
/// | ✓ | — | none | email-first, magic link |
///
/// The create password uses [PasswordField.mode] `create` (strength bar +
/// requirements); the confirm field live-matches it. Wrapped in an
/// [AutofillGroup] with `newPassword` hints so password managers offer
/// generation; call [RegistrationForm.finishAutofill] after a successful
/// sign-up. Focus chains email → phone → password → confirm; done on the
/// last field fires [onSubmit].
///
/// ```dart
/// RegistrationForm(
///   showEmail: true,
///   showPhone: true,
///   passwordMode: RegPasswordMode.createConfirm,
///   onSubmit: (d) => cubit.register(d),
/// )
/// ```
class RegistrationForm extends StatefulWidget {
  const RegistrationForm({
    super.key,
    this.showEmail = true,
    this.showPhone = false,
    this.emailRequired = true,
    this.phoneRequired = true,
    this.passwordMode = RegPasswordMode.createConfirm,
    this.emailController,
    this.phoneController,
    this.passwordController,
    this.confirmController,
    this.onChanged,
    this.onSubmit,
    this.enabled = true,
    this.deferToParentForm = true,
    this.validationMode = ValidationMode.onInteraction,
    this.allowedCountries,
    this.preferredCountries = const [],
    this.showStrengthBar = true,
    this.onTermsTap,
    this.onPrivacyTap,
    this.showMarketingOptIn = false,
    this.initialMarketingOptIn = false,
    this.style,
  }) : assert(showEmail || showPhone, 'Show at least one identifier.'),
       assert(
         (showEmail && emailRequired) || (showPhone && phoneRequired),
         'At least one shown identifier must be required — an all-optional '
         'form would validate empty.',
       );

  final bool showEmail;
  final bool showPhone;

  /// Per-identifier requiredness — e.g. phone SHOWN but optional beside
  /// a required email. An optional field passes when empty; a non-empty
  /// value still runs its full rules. At least one shown identifier must
  /// stay required.
  final bool emailRequired;
  final bool phoneRequired;

  final RegPasswordMode passwordMode;

  /// Controllers are optional — the form owns them when absent.
  final TextEditingController? emailController;
  final TextEditingController? phoneController;
  final TextEditingController? passwordController;
  final TextEditingController? confirmController;

  /// Parsed state on every change.
  final ValueChanged<RegistrationFormData>? onChanged;

  /// Keyboard done on the LAST field.
  final ValueChanged<RegistrationFormData>? onSubmit;

  final bool enabled;

  /// Keep `true` inside a `Form`; `false` for standalone screens.
  final bool deferToParentForm;

  final ValidationMode validationMode;

  /// Phone picker whitelist / pins.
  final List<String>? allowedCountries;
  final List<String> preferredCountries;

  /// Strength bar under the create password.
  final bool showStrengthBar;

  /// Passing either handler shows a `ConsentCheckboxField` under the
  /// last field (both → "Terms and Privacy", one → that link only) and
  /// gates [RegistrationFormData.isValid] on acceptance.
  final VoidCallback? onTermsTap;
  final VoidCallback? onPrivacyTap;

  /// Whether the consent checkbox is shown.
  bool get consentShown => onTermsTap != null || onPrivacyTap != null;

  /// Localized `MarketingOptInCheckbox` at the bottom — never gates
  /// validity; rides [RegistrationFormData.marketingOptIn].
  final bool showMarketingOptIn;
  final bool initialMarketingOptIn;

  /// Visual override applied to every field.
  final TextFieldStyle? style;

  /// After a SUCCESSFUL sign-up: commits the autofill context so the OS
  /// offers to save the new credentials.
  static void finishAutofill() => TextInput.finishAutofillContext();

  @override
  State<RegistrationForm> createState() => _RegistrationFormState();
}

class _RegistrationFormState extends State<RegistrationForm> {
  TextEditingController? _ownedEmail,
      _ownedPhone,
      _ownedPassword,
      _ownedConfirm;
  final _phoneFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  PhoneNumber? _phone;
  bool _consent = false;
  late bool _marketing = widget.initialMarketingOptIn;

  TextEditingController get _email =>
      widget.emailController ?? (_ownedEmail ??= TextEditingController());
  TextEditingController get _phoneCtrl =>
      widget.phoneController ?? (_ownedPhone ??= TextEditingController());
  TextEditingController get _password =>
      widget.passwordController ?? (_ownedPassword ??= TextEditingController());
  TextEditingController get _confirm =>
      widget.confirmController ?? (_ownedConfirm ??= TextEditingController());

  @override
  void dispose() {
    _ownedEmail?.dispose();
    _ownedPhone?.dispose();
    _ownedPassword?.dispose();
    _ownedConfirm?.dispose();
    _phoneFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  bool get _passwordValid => switch (widget.passwordMode) {
    RegPasswordMode.none => true,
    RegPasswordMode.create =>
      Validators.validateCreatePassword(_password.text) == null,
    RegPasswordMode.createConfirm =>
      Validators.validateCreatePassword(_password.text) == null &&
          _confirm.text == _password.text &&
          _password.text.isNotEmpty,
  };

  RegistrationFormData _current() {
    // Optional identifiers pass when EMPTY; non-empty runs full rules.
    final emailOk =
        !widget.showEmail ||
        (_email.text.trim().isEmpty
            ? !widget.emailRequired
            : Validators.validateEmail(_email.text) == null);
    final phoneOk =
        !widget.showPhone ||
        (_phoneCtrl.text.trim().isEmpty
            ? !widget.phoneRequired
            : (_phone?.isValid ?? false));
    final consentOk = !widget.consentShown || _consent;
    return RegistrationFormData(
      email: widget.showEmail ? _email.text.trim() : '',
      phone: widget.showPhone ? _phone : null,
      password: widget.passwordMode == RegPasswordMode.none
          ? ''
          : _password.text,
      consentAccepted: consentOk,
      marketingOptIn: widget.showMarketingOptIn && _marketing,
      isValid: emailOk && phoneOk && _passwordValid && consentOk,
    );
  }

  void _emit() => widget.onChanged?.call(_current());

  /// The focus target after [current], or null when it's the last field.
  FocusNode? _next(int current) {
    final chain = <FocusNode?>[
      null, // email has no node of its own (first field)
      widget.showPhone ? _phoneFocus : null,
      widget.passwordMode != RegPasswordMode.none ? _passwordFocus : null,
      widget.passwordMode == RegPasswordMode.createConfirm
          ? _confirmFocus
          : null,
    ];
    for (var i = current + 1; i < chain.length; i++) {
      if (chain[i] != null) return chain[i];
    }
    return null;
  }

  void _advance(int from) {
    final next = _next(from);
    if (next != null) {
      next.requestFocus();
    } else {
      widget.onSubmit?.call(_current());
    }
  }

  TextInputAction _actionFor(int position) =>
      _next(position) == null ? TextInputAction.done : TextInputAction.next;

  @override
  Widget build(BuildContext context) {
    final gap = SizedBox(height: context.spacing.md);
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.showEmail)
            EmailField(
              controller: _email,
              required: widget.emailRequired,
              enabled: widget.enabled,
              deferToParentForm: widget.deferToParentForm,
              validationMode: widget.validationMode,
              textInputAction: _actionFor(0),
              autofillHints: const [AutofillHints.email],
              style: widget.style,
              onChanged: (_) => _emit(),
              onSubmitted: (_) => _advance(0),
            ),
          if (widget.showPhone) ...[
            if (widget.showEmail) gap,
            PhoneNumberField(
              controller: _phoneCtrl,
              focusNode: _phoneFocus,
              required: widget.phoneRequired,
              enabled: widget.enabled,
              deferToParentForm: widget.deferToParentForm,
              validationMode: widget.validationMode,
              allowedCountries: widget.allowedCountries,
              preferredCountries: widget.preferredCountries,
              textInputAction: _actionFor(1),
              style: widget.style,
              onNumberChanged: (n) {
                _phone = n;
                _emit();
              },
              onSubmitted: (_) => _advance(1),
            ),
          ],
          if (widget.passwordMode != RegPasswordMode.none) ...[
            gap,
            PasswordField(
              controller: _password,
              focusNode: _passwordFocus,
              mode: PasswordFieldMode.create,
              showStrengthBar: widget.showStrengthBar,
              enabled: widget.enabled,
              deferToParentForm: widget.deferToParentForm,
              validationMode: widget.validationMode,
              textInputAction: _actionFor(2),
              style: widget.style,
              onChanged: (_) => _emit(),
              onSubmitted: (_) => _advance(2),
            ),
          ],
          if (widget.passwordMode == RegPasswordMode.createConfirm) ...[
            gap,
            PasswordField(
              controller: _confirm,
              focusNode: _confirmFocus,
              mode: PasswordFieldMode.confirm,
              matchController: _password,
              enabled: widget.enabled,
              deferToParentForm: widget.deferToParentForm,
              validationMode: widget.validationMode,
              textInputAction: TextInputAction.done,
              style: widget.style,
              onChanged: (_) => _emit(),
              onSubmitted: (_) => widget.onSubmit?.call(_current()),
            ),
          ],
          if (widget.consentShown) ...[
            gap,
            ConsentCheckboxField(
              onTermsTap: widget.onTermsTap,
              onPrivacyTap: widget.onPrivacyTap,
              enabled: widget.enabled,
              validation: CheckboxValidation<bool>(
                validator: (v) => v == true ? null : ConsentStrings.required,
                mode: widget.validationMode,
                deferToParentForm: widget.deferToParentForm,
              ),
              onChanged: (v) {
                setState(() => _consent = v);
                _emit();
              },
            ),
          ],
          if (widget.showMarketingOptIn) ...[
            gap,
            MarketingOptInCheckbox(
              value: _marketing,
              enabled: widget.enabled,
              onChanged: (v) {
                setState(() => _marketing = v);
                _emit();
              },
            ),
          ],
        ],
      ),
    );
  }
}
