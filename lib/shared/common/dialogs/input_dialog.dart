import 'package:flutter/material.dart';

import '../../../core/localization/strings/common_strings.dart';
import '../../module/buttons/global_filled_button.dart';
import '../../module/dialog/global_dialog.dart';
import '../../module/text_field/global_text_field.dart' show ValidationMode;
import '../text_form_fields/generic/simple_text_field.dart';

/// One-field prompt dialog — counterpart of `showInputSheet` (and the
/// validated replacement for `GlobalDialog.input`, whose raw TextField
/// never runs its validator). Resolves with the trimmed text on
/// submit, or `null` on dismiss.
Future<String?> showInputDialog({
  BuildContext? context,
  required String title,
  String? message,
  String? hint,
  String? label,
  String? initialValue,
  String? submitLabel,
  int maxLines = 1,
  int? maxLength,
  TextInputType keyboardType = TextInputType.text,
  String? Function(String?)? validator,
  DialogStyle style = const DialogStyle(),
}) {
  return GlobalDialog.show<String>(
    context: context,
    title: title,
    message: message,
    style: style,
    content: _InputDialogContent(
      hint: hint,
      label: label,
      initialValue: initialValue,
      submitLabel: submitLabel ?? CommonStrings.done,
      maxLines: maxLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      validator: validator,
    ),
  );
}

class _InputDialogContent extends StatefulWidget {
  const _InputDialogContent({
    required this.hint,
    required this.label,
    required this.initialValue,
    required this.submitLabel,
    required this.maxLines,
    required this.maxLength,
    required this.keyboardType,
    required this.validator,
  });

  final String? hint;
  final String? label;
  final String? initialValue;
  final String submitLabel;
  final int maxLines;
  final int? maxLength;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  @override
  State<_InputDialogContent> createState() => _InputDialogContentState();
}

class _InputDialogContentState extends State<_InputDialogContent> {
  final _formKey = GlobalKey<FormState>();
  late final _controller = TextEditingController(text: widget.initialValue);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SimpleTextField(
            controller: _controller,
            label: widget.label,
            hint: widget.hint,
            keyboardType: widget.keyboardType,
            validator: widget.validator,
            maxLength: widget.maxLength,
            // onSubmit: Form.validate() always runs the validator —
            // onInteraction would let an untouched empty field pass.
            validationMode: ValidationMode.onSubmit,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 16),
          GlobalFilledButton(
            text: widget.submitLabel,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
