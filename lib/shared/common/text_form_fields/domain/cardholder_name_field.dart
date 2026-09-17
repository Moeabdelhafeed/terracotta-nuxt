import 'package:flutter/material.dart';

import '../../../../core/localization/strings/field_strings.dart';
import '../../../module/text_field/global_text_field.dart';
import 'name_field.dart';

/// Name-on-card preset over [NameField] — full name, Latin letters only
/// (embossed names are), `creditCardName` autofill (the one hint nothing
/// else uses). Completes the checkout set next to [PaymentCardForm].
class CardholderNameField extends StatelessWidget {
  const CardholderNameField({
    super.key,
    required this.controller,
    this.onChanged,
    this.onSubmitted,
    this.identifier,
    this.hint,
    this.enabled = true,
    this.readOnly = false,
    this.errorText,
    this.validator,
    this.focusNode,
    this.textInputAction = TextInputAction.next,
    this.validationMode = ValidationMode.onInteraction,
    this.deferToParentForm = true,
    this.messages = const [],
    this.showPrefixIcon = true,
    this.style,
    this.sizing,
  });

  final TextEditingController controller;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final String? identifier;

  /// Null → localized default.
  final String? hint;
  final bool enabled;
  final bool readOnly;
  final String? errorText;
  final String? Function(String?)? validator;
  final FocusNode? focusNode;
  final TextInputAction textInputAction;
  final ValidationMode validationMode;
  final bool deferToParentForm;
  final List<FieldMessage> messages;
  final bool showPrefixIcon;
  final TextFieldStyle? style;
  final TextFieldSizing? sizing;

  @override
  Widget build(BuildContext context) {
    return NameField(
      controller: controller,
      mode: NameFieldMode.full,
      script: NameScript.latin,
      showPartsProgress: false,
      autofillHints: const [AutofillHints.creditCardName],
      hint: hint ?? FieldStrings.cardholderHint,
      identifier: identifier,
      enabled: enabled,
      readOnly: readOnly,
      errorText: errorText,
      validator: validator,
      focusNode: focusNode,
      textInputAction: textInputAction,
      validationMode: validationMode,
      deferToParentForm: deferToParentForm,
      messages: messages,
      showPrefixIcon: showPrefixIcon,
      style: style,
      sizing: sizing,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
    );
  }
}
