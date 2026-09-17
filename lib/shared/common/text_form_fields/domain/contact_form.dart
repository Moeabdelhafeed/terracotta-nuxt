import 'package:flutter/material.dart';

import '../../../../core/localization/strings/contact_form_strings.dart';
import '../../../../core/tokens/extensions.dart';
import '../../../../core/utils/validators/validators.dart';
import '../../../module/text_field/global_text_field.dart';
import '../generic/multiline_text_field.dart';
import 'email_field.dart';
import 'name_field.dart';
import 'phone_number_field.dart';

/// The value a [ContactForm] emits.
@immutable
class ContactFormData {
  const ContactFormData({
    this.name = '',
    this.email = '',
    this.phone,
    this.message = '',
    required this.isValid,
  });

  final String name;
  final String email;

  /// Parsed phone — null when hidden or empty.
  final PhoneNumber? phone;

  final String message;

  /// Every shown required field passes; optional phone is empty-or-valid.
  final bool isValid;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContactFormData &&
          other.name == name &&
          other.email == email &&
          other.phone == phone &&
          other.message == message &&
          other.isValid == isValid;

  @override
  int get hashCode => Object.hash(name, email, phone, message, isValid);

  @override
  String toString() => 'ContactFormData($email, valid: $isValid)';
}

/// The contact / feedback composite — name + email + optional phone +
/// message:
///
///  * Name is a full-name [NameField], email required, phone SHOWN but
///    optional by default (empty passes, half-typed fails).
///  * Message is a [MultilineTextField] with a character counter
///    ([messageMaxLength]) and a required validator.
///  * One [AutofillGroup] (name / email / phone hints).
///  * Focus chains name → email → phone; the multiline message takes
///    newline, so submission is the CALLER's button — gate it on
///    [ContactFormData.isValid].
///
/// ```dart
/// ContactForm(onChanged: (d) => setState(() => data = d)),
/// GlobalFilledButton(
///   text: 'Send',
///   enabled: data?.isValid ?? false,
///   onPressed: () => cubit.send(data!),
/// )
/// ```
class ContactForm extends StatefulWidget {
  const ContactForm({
    super.key,
    this.showPhone = true,
    this.phoneRequired = false,
    this.messageMaxLength = 500,
    this.messageMinLines = 4,
    this.nameController,
    this.emailController,
    this.phoneController,
    this.messageController,
    this.onChanged,
    this.enabled = true,
    this.deferToParentForm = true,
    this.validationMode = ValidationMode.onInteraction,
    this.allowedCountries,
    this.preferredCountries = const [],
    this.style,
  });

  final bool showPhone;

  /// Phone is contact-me-back convenience — optional by default.
  final bool phoneRequired;

  /// Counter cap on the message (null → uncapped, no counter).
  final int? messageMaxLength;

  final int messageMinLines;

  /// Controllers are optional — the form owns them when absent.
  final TextEditingController? nameController;
  final TextEditingController? emailController;
  final TextEditingController? phoneController;
  final TextEditingController? messageController;

  /// Parsed state on every change — gate your send button on `isValid`.
  final ValueChanged<ContactFormData>? onChanged;

  final bool enabled;

  /// Keep `true` inside a `Form`; `false` for standalone screens.
  final bool deferToParentForm;

  final ValidationMode validationMode;

  /// Phone picker whitelist / pins.
  final List<String>? allowedCountries;
  final List<String> preferredCountries;

  /// Visual override applied to every field.
  final TextFieldStyle? style;

  @override
  State<ContactForm> createState() => _ContactFormState();
}

class _ContactFormState extends State<ContactForm> {
  TextEditingController? _ownedName, _ownedEmail, _ownedPhone, _ownedMessage;
  final _emailFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _messageFocus = FocusNode();

  PhoneNumber? _phone;

  TextEditingController get _name =>
      widget.nameController ?? (_ownedName ??= TextEditingController());
  TextEditingController get _email =>
      widget.emailController ?? (_ownedEmail ??= TextEditingController());
  TextEditingController get _phoneCtrl =>
      widget.phoneController ?? (_ownedPhone ??= TextEditingController());
  TextEditingController get _message =>
      widget.messageController ?? (_ownedMessage ??= TextEditingController());

  @override
  void dispose() {
    _ownedName?.dispose();
    _ownedEmail?.dispose();
    _ownedPhone?.dispose();
    _ownedMessage?.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    _messageFocus.dispose();
    super.dispose();
  }

  String? _messageValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return ContactFormStrings.messageRequired;
    }
    return null;
  }

  bool get _isValid {
    final nameOk = Validators.validateFullName(_name.text) == null;
    final emailOk = Validators.validateEmail(_email.text) == null;
    final phoneOk =
        !widget.showPhone ||
        (_phoneCtrl.text.trim().isEmpty
            ? !widget.phoneRequired
            : (_phone?.isValid ?? false));
    final messageOk = _messageValidator(_message.text) == null;
    return nameOk && emailOk && phoneOk && messageOk;
  }

  ContactFormData _current() => ContactFormData(
    name: _name.text.trim(),
    email: _email.text.trim(),
    phone: widget.showPhone ? _phone : null,
    message: _message.text.trim(),
    isValid: _isValid,
  );

  void _emit() => widget.onChanged?.call(_current());

  @override
  Widget build(BuildContext context) {
    final gap = SizedBox(height: context.spacing.md);
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          NameField(
            controller: _name,
            mode: NameFieldMode.full,
            required: true,
            enabled: widget.enabled,
            deferToParentForm: widget.deferToParentForm,
            validationMode: widget.validationMode,
            style: widget.style,
            onChanged: (_) => _emit(),
            onSubmitted: (_) => _emailFocus.requestFocus(),
          ),
          gap,
          EmailField(
            controller: _email,
            focusNode: _emailFocus,
            enabled: widget.enabled,
            deferToParentForm: widget.deferToParentForm,
            validationMode: widget.validationMode,
            autofillHints: const [AutofillHints.email],
            style: widget.style,
            onChanged: (_) => _emit(),
            onSubmitted: (_) =>
                (widget.showPhone ? _phoneFocus : _messageFocus).requestFocus(),
          ),
          if (widget.showPhone) ...[
            gap,
            PhoneNumberField(
              controller: _phoneCtrl,
              focusNode: _phoneFocus,
              required: widget.phoneRequired,
              enabled: widget.enabled,
              deferToParentForm: widget.deferToParentForm,
              validationMode: widget.validationMode,
              allowedCountries: widget.allowedCountries,
              preferredCountries: widget.preferredCountries,
              style: widget.style,
              onNumberChanged: (n) {
                _phone = n;
                _emit();
              },
              onSubmitted: (_) => _messageFocus.requestFocus(),
            ),
          ],
          gap,
          MultilineTextField(
            controller: _message,
            focusNode: _messageFocus,
            identifier: ContactFormStrings.messageLabel,
            required: true,
            hint: ContactFormStrings.messageHint,
            validator: _messageValidator,
            minLines: widget.messageMinLines,
            maxLength: widget.messageMaxLength,
            enabled: widget.enabled,
            deferToParentForm: widget.deferToParentForm,
            validationMode: widget.validationMode,
            onChanged: (_) => _emit(),
          ),
        ],
      ),
    );
  }
}
