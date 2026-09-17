import 'package:flutter/material.dart';

import '../../../core/localization/strings/module_strings.dart';
import '../../module/dialog/global_dialog.dart';

/// Read-only info/help dialog — counterpart of `showInfoSheet`.
/// One localized "Got it" button.
Future<void> showInfoDialog({
  BuildContext? context,
  required String title,
  String? message,
  Widget? body,
  DialogType type = DialogType.info,
  String? buttonLabel,
  DialogStyle style = const DialogStyle(),
}) {
  assert(message != null || body != null, 'Provide message or body.');
  return GlobalDialog.show<void>(
    context: context,
    title: title,
    message: message,
    content: body,
    type: type,
    confirmText: buttonLabel ?? SheetStrings.gotIt,
    showCloseButton: false,
    style: style,
  );
}
