import 'package:flutter/material.dart';

import '../../../core/localization/strings/common_strings.dart';
import '../../module/buttons/global_filled_button.dart';
import '../../module/sheet/global_sheet.dart';
import '../../module/text_field/global_text_field.dart' show ValidationMode;
import '../text_form_fields/generic/simple_text_field.dart';

/// One-field prompt — rename, report reason, add note. Resolves with
/// the trimmed text on submit, or `null` on dismiss. [validator]
/// gates submission (standard `FormField` contract).
Future<String?> showInputSheet({
  BuildContext? context,
  required String title,
  String? subtitle,
  String? hint,
  String? label,
  String? initialValue,
  String? submitLabel,
  int maxLines = 1,
  int? maxLength,
  TextInputType keyboardType = TextInputType.text,
  String? Function(String?)? validator,
  SheetStyle style = const SheetStyle(),
}) {
  return GlobalBottomSheet.show<String>(
    context: context,
    title: title,
    subtitle: subtitle,
    style: style,
    content: _InputSheetContent(
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

class _InputSheetContent extends StatefulWidget {
  const _InputSheetContent({
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
  State<_InputSheetContent> createState() => _InputSheetContentState();
}

class _InputSheetContentState extends State<_InputSheetContent> {
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
    // Lift the field above the keyboard — modal sheets don't get the
    // scaffold's automatic inset handling.
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Form(
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
      ),
    );
  }
}
