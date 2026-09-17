import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/strings/module_strings.dart';
import '../../module/buttons/global_filled_button.dart';
import '../../module/sheet/global_sheet.dart';

/// Read-only info/help sheet — feature explainer, onboarding tip.
/// One localized "Got it" button; [body] wins over [message] when
/// both are given.
Future<void> showInfoSheet({
  BuildContext? context,
  required String title,
  String? message,
  Widget? body,
  IconData icon = Icons.info_outline_rounded,
  String? buttonLabel,
  SheetStyle style = const SheetStyle(),
}) {
  assert(message != null || body != null, 'Provide message or body.');
  return GlobalBottomSheet.show<void>(
    context: context,
    title: title,
    icon: icon,
    style: style,
    content: _InfoSheetContent(
      message: message,
      body: body,
      buttonLabel: buttonLabel ?? SheetStrings.gotIt,
    ),
  );
}

class _InfoSheetContent extends StatelessWidget {
  const _InfoSheetContent({
    required this.message,
    required this.body,
    required this.buttonLabel,
  });

  final String? message;
  final Widget? body;
  final String buttonLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        body ??
            Text(
              message!,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.textColors.secondary,
              ),
            ),
        const SizedBox(height: 20),
        GlobalFilledButton(
          text: buttonLabel,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
