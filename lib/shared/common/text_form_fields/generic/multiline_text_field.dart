import 'package:flutter/material.dart';

import '../../../module/text_field/global_text_field.dart';

/// Multi-line text field — notes, descriptions, comments, bio.
/// Grows up to [maxLines] rows; shows a character counter when
/// [maxLength] is set.
class MultilineTextField extends StatelessWidget {
  const MultilineTextField({
    super.key,
    required this.controller,
    this.label,
    this.identifier,
    this.required = false,
    this.hint,
    this.onChanged,
    this.validator,
    this.errorText,
    this.enabled = true,
    this.readOnly = false,
    this.focusNode,
    this.minLines = 3,
    this.maxLines = 6,
    this.maxLength,
    this.showCharCount = true,
    this.validationMode = ValidationMode.onInteraction,
    this.deferToParentForm = true,
  });

  final TextEditingController controller;
  final String? label;
  final String? identifier;

  /// Shows the `*` marker on the identifier header (or the hint when
  /// there is none). Pair with a [validator] that rejects empty.
  final bool required;

  final String? hint;
  final void Function(String)? onChanged;
  final String? Function(String?)? validator;
  final String? errorText;
  final bool enabled;
  final bool readOnly;
  final FocusNode? focusNode;
  final int minLines;
  final int maxLines;
  final int? maxLength;
  final bool showCharCount;
  final ValidationMode validationMode;

  /// Keep `true` inside a `Form`; `false` for standalone fields.
  final bool deferToParentForm;

  @override
  Widget build(BuildContext context) {
    return GlobalTextFormField(
      controller: controller,
      label: label,
      identifier: identifier,
      required: required,
      hint: hint ?? '',
      focusNode: focusNode,
      behavior: TextFieldBehavior(
        keyboardType: TextInputType.multiline,
        textInputAction: TextInputAction.newline,
        minLines: minLines,
        maxLines: maxLines,
        maxLength: maxLength,
        enabled: enabled,
        readOnly: readOnly,
      ),
      validation: TextFieldValidation(
        validator: validator,
        errorText: errorText,
        mode: validationMode,
        deferToParentForm: deferToParentForm,
      ),
      features: TextFieldFeatures(
        counters: CountersConfig(
          showCharCount: showCharCount && maxLength != null,
        ),
      ),
      callbacks: TextFieldCallbacks(onChanged: onChanged),
    );
  }
}
