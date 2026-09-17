import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show TextInput;

import '../../../../core/tokens/extensions.dart';
import '../../../../core/utils/validators/validators.dart';
import '../../../module/text_field/global_text_field.dart';
import '../../selection_fields/checkbox/remember_me_checkbox.dart';
import 'email_field.dart';
import 'email_or_phone_field.dart';
import 'password_field.dart';
import 'phone_number_field.dart';
import 'username_field.dart';

/// Which identifier a [LoginForm] collects.
enum LoginIdentifierType { email, phone, emailOrPhone, username }

/// The parsed value a [LoginForm] emits — whichever identifier the form
/// collects plus the password (empty for passwordless flows).
@immutable
class LoginFormData {
  const LoginFormData({
    this.email = '',
    this.phone,
    this.username = '',
    this.password = '',
    this.rememberMe = false,
    required this.isValid,
  });

  /// Trimmed email — set by [LoginIdentifierType.email] and by
  /// [LoginIdentifierType.emailOrPhone] when the input read as email.
  final String email;

  /// Parsed phone — set by [LoginIdentifierType.phone] and by
  /// [LoginIdentifierType.emailOrPhone] when the input read as a number.
  final PhoneNumber? phone;

  final String username;

  /// Empty when [LoginForm.showPassword] is off (magic link / OTP).
  final String password;

  /// The remember-me checkbox — always false when
  /// [LoginForm.showRememberMe] is off.
  final bool rememberMe;

  /// Identifier valid + (when shown) password non-empty.
  final bool isValid;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LoginFormData &&
          other.email == email &&
          other.phone == phone &&
          other.username == username &&
          other.password == password &&
          other.rememberMe == rememberMe &&
          other.isValid == isValid;

  @override
  int get hashCode =>
      Object.hash(email, phone, username, password, rememberMe, isValid);

  @override
  String toString() =>
      'LoginFormData(email: $email, phone: ${phone?.e164}, username: $username, valid: $isValid)';
}

/// The sign-in composite — ONE widget covering every login shape via two
/// knobs:
///
/// | identifierType | showPassword | flow |
/// |---|---|---|
/// | email | true | classic email + password |
/// | phone | true | phone + password |
/// | emailOrPhone | true | MENA either-way + password |
/// | username | true | username + password |
/// | email | false | magic link |
/// | phone | false | OTP |
///
/// Wrapped in an [AutofillGroup] (username + password hints) so password
/// managers offer saved credentials; call [LoginForm.finishAutofill]
/// after a SUCCESSFUL sign-in so the OS prompts to save. Focus chains
/// identifier → password; keyboard done on the last field fires
/// [onSubmit].
///
/// ```dart
/// LoginForm(
///   identifierType: LoginIdentifierType.emailOrPhone,
///   onSubmit: (d) => cubit.login(d),
/// )
/// ```
class LoginForm extends StatefulWidget {
  const LoginForm({
    super.key,
    this.identifierType = LoginIdentifierType.emailOrPhone,
    this.showPassword = true,
    this.showRememberMe = false,
    this.initialRememberMe = false,
    this.identifierController,
    this.passwordController,
    this.onChanged,
    this.onSubmit,
    this.identifierLabel,
    this.passwordLabel,
    this.enabled = true,
    this.deferToParentForm = true,
    this.validationMode = ValidationMode.onInteraction,
    this.allowedCountries,
    this.preferredCountries = const [],
    this.style,
  });

  final LoginIdentifierType identifierType;

  /// `false` → identifier only (magic link / OTP).
  final bool showPassword;

  /// Localized `RememberMeCheckbox` under the last field — state rides
  /// [LoginFormData.rememberMe].
  final bool showRememberMe;
  final bool initialRememberMe;

  /// Controllers are optional — the form owns them when absent.
  final TextEditingController? identifierController;
  final TextEditingController? passwordController;

  /// Parsed state on every change.
  final ValueChanged<LoginFormData>? onChanged;

  /// Keyboard done on the LAST field (password, or the identifier when
  /// passwordless).
  final ValueChanged<LoginFormData>? onSubmit;

  /// Header overrides (null → each field's default).
  final String? identifierLabel;
  final String? passwordLabel;

  final bool enabled;

  /// Keep `true` inside a `Form`; `false` for standalone screens.
  final bool deferToParentForm;

  final ValidationMode validationMode;

  /// Phone-mode picker whitelist / pins.
  final List<String>? allowedCountries;
  final List<String> preferredCountries;

  /// Visual override applied to every field.
  final TextFieldStyle? style;

  /// After a SUCCESSFUL sign-in: commits the autofill context so the OS
  /// offers to save the credentials.
  static void finishAutofill() => TextInput.finishAutofillContext();

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  TextEditingController? _ownedIdentifier, _ownedPassword;
  final _passwordFocus = FocusNode();

  /// EmailOrPhone-mode live parse.
  LoginIdentifier? _eop;

  late bool _rememberMe = widget.initialRememberMe;

  /// Phone-mode live parse.
  PhoneNumber? _phone;

  TextEditingController get _identifier =>
      widget.identifierController ??
      (_ownedIdentifier ??= TextEditingController());
  TextEditingController get _password =>
      widget.passwordController ?? (_ownedPassword ??= TextEditingController());

  @override
  void dispose() {
    _ownedIdentifier?.dispose();
    _ownedPassword?.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  bool get _identifierValid => switch (widget.identifierType) {
    LoginIdentifierType.email =>
      Validators.validateEmail(_identifier.text) == null,
    LoginIdentifierType.username => _identifier.text.trim().isNotEmpty,
    LoginIdentifierType.phone => _phone?.isValid ?? false,
    LoginIdentifierType.emailOrPhone => _eop?.isValid ?? false,
  };

  LoginFormData _current() {
    final valid =
        _identifierValid && (!widget.showPassword || _password.text.isNotEmpty);
    return switch (widget.identifierType) {
      LoginIdentifierType.email => LoginFormData(
        email: _identifier.text.trim(),
        password: _password.text,
        rememberMe: _rememberMe,
        isValid: valid,
      ),
      LoginIdentifierType.username => LoginFormData(
        username: _identifier.text.trim(),
        password: _password.text,
        rememberMe: _rememberMe,
        isValid: valid,
      ),
      LoginIdentifierType.phone => LoginFormData(
        phone: _phone,
        password: _password.text,
        rememberMe: _rememberMe,
        isValid: valid,
      ),
      LoginIdentifierType.emailOrPhone => switch (_eop) {
        EmailLoginIdentifier(:final email) => LoginFormData(
          email: email,
          password: _password.text,
          rememberMe: _rememberMe,
          isValid: valid,
        ),
        PhoneLoginIdentifier(:final phone) => LoginFormData(
          phone: phone,
          password: _password.text,
          rememberMe: _rememberMe,
          isValid: valid,
        ),
        null => LoginFormData(
          password: _password.text,
          rememberMe: _rememberMe,
          isValid: false,
        ),
      },
    };
  }

  void _emit() => widget.onChanged?.call(_current());

  void _advanceOrSubmit() {
    if (widget.showPassword) {
      _passwordFocus.requestFocus();
    } else {
      widget.onSubmit?.call(_current());
    }
  }

  Widget _identifierField() {
    switch (widget.identifierType) {
      case LoginIdentifierType.email:
        return EmailField(
          controller: _identifier,
          identifier: widget.identifierLabel,
          enabled: widget.enabled,
          deferToParentForm: widget.deferToParentForm,
          validationMode: widget.validationMode,
          textInputAction: widget.showPassword
              ? TextInputAction.next
              : TextInputAction.done,
          autofillHints: const [AutofillHints.username, AutofillHints.email],
          style: widget.style,
          onChanged: (_) => _emit(),
          onSubmitted: (_) => _advanceOrSubmit(),
        );
      case LoginIdentifierType.username:
        return UsernameField(
          controller: _identifier,
          identifier: widget.identifierLabel,
          enabled: widget.enabled,
          deferToParentForm: widget.deferToParentForm,
          validationMode: widget.validationMode,
          style: widget.style,
          onChanged: (_) => _emit(),
          onSubmitted: (_) => _advanceOrSubmit(),
        );
      case LoginIdentifierType.phone:
        return PhoneNumberField(
          controller: _identifier,
          identifier: widget.identifierLabel,
          enabled: widget.enabled,
          deferToParentForm: widget.deferToParentForm,
          validationMode: widget.validationMode,
          allowedCountries: widget.allowedCountries,
          preferredCountries: widget.preferredCountries,
          textInputAction: widget.showPassword
              ? TextInputAction.next
              : TextInputAction.done,
          style: widget.style,
          onNumberChanged: (n) {
            _phone = n;
            _emit();
          },
          onSubmitted: (_) => _advanceOrSubmit(),
        );
      case LoginIdentifierType.emailOrPhone:
        return EmailOrPhoneField(
          controller: _identifier,
          identifier: widget.identifierLabel,
          enabled: widget.enabled,
          deferToParentForm: widget.deferToParentForm,
          validationMode: widget.validationMode,
          allowedCountries: widget.allowedCountries,
          preferredCountries: widget.preferredCountries,
          textInputAction: widget.showPassword
              ? TextInputAction.next
              : TextInputAction.done,
          style: widget.style,
          onIdentifierChanged: (id) {
            _eop = id;
            _emit();
          },
          onSubmitted: (_) => _advanceOrSubmit(),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _identifierField(),
          if (widget.showPassword) ...[
            SizedBox(height: context.spacing.md),
            PasswordField(
              controller: _password,
              focusNode: _passwordFocus,
              identifier: widget.passwordLabel,
              enabled: widget.enabled,
              deferToParentForm: widget.deferToParentForm,
              validationMode: widget.validationMode,
              textInputAction: TextInputAction.done,
              style: widget.style,
              onChanged: (_) => _emit(),
              onSubmitted: (_) => widget.onSubmit?.call(_current()),
            ),
          ],
          if (widget.showRememberMe) ...[
            SizedBox(height: context.spacing.md),
            RememberMeCheckbox(
              value: _rememberMe,
              enabled: widget.enabled,
              onChanged: (v) {
                setState(() => _rememberMe = v);
                _emit();
              },
            ),
          ],
        ],
      ),
    );
  }
}
