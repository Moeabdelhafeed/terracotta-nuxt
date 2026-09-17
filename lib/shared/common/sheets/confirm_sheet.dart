import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/strings/common_strings.dart';
import '../../../core/localization/strings/module_strings.dart';
import '../../module/buttons/global_filled_button.dart';
import '../../module/buttons/global_outlined_button.dart';
import '../../module/sheet/global_sheet.dart';

/// Confirm/cancel bottom sheet — resolves `true` on confirm, `false`
/// on cancel OR dismiss (barrier tap, drag, close button), so callers
/// can `if (await showConfirmSheet(...))` without null-handling.
///
/// [isDanger] paints the confirm button in the error color — use for
/// destructive actions (or reach for [showDeleteConfirmSheet]).
Future<bool> showConfirmSheet({
  BuildContext? context,
  String? title,
  String? message,
  String? confirmLabel,
  String? cancelLabel,
  bool isDanger = false,
  IconData? icon,
  SheetStyle style = const SheetStyle(),
}) {
  return GlobalBottomSheet.show<bool>(
    context: context,
    title: title ?? SheetStrings.confirmTitle,
    icon: icon,
    showCloseButton: false,
    style: style,
    content: _ConfirmContent(
      message: message,
      confirmLabel: confirmLabel ?? SheetStrings.confirm,
      cancelLabel: cancelLabel ?? CommonStrings.cancel,
      isDanger: isDanger,
    ),
  ).then((v) => v ?? false);
}

/// Delete preset — danger styling + localized irreversibility copy.
Future<bool> showDeleteConfirmSheet({
  BuildContext? context,
  String? title,
  String? message,
  SheetStyle style = const SheetStyle(),
}) => showConfirmSheet(
  context: context,
  title: title ?? SheetStrings.deleteTitle,
  message: message ?? SheetStrings.deleteMessage,
  confirmLabel: CommonStrings.delete,
  isDanger: true,
  icon: Icons.delete_outline_rounded,
  style: style,
);

/// Logout preset.
Future<bool> showLogoutConfirmSheet({
  BuildContext? context,
  SheetStyle style = const SheetStyle(),
}) => showConfirmSheet(
  context: context,
  title: SheetStrings.logoutTitle,
  message: SheetStrings.logoutMessage,
  confirmLabel: SheetStrings.logoutConfirm,
  icon: Icons.logout_rounded,
  style: style,
);

/// Discard-unsaved-changes preset — the back-navigation guard.
Future<bool> showDiscardChangesSheet({
  BuildContext? context,
  SheetStyle style = const SheetStyle(),
}) => showConfirmSheet(
  context: context,
  title: SheetStrings.discardTitle,
  message: SheetStrings.discardMessage,
  confirmLabel: SheetStrings.discardConfirm,
  isDanger: true,
  icon: Icons.undo_rounded,
  style: style,
);

class _ConfirmContent extends StatelessWidget {
  const _ConfirmContent({
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.isDanger,
  });

  final String? message;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDanger;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (message != null) ...[
          Text(
            message!,
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.textColors.secondary,
            ),
          ),
          const SizedBox(height: 20),
        ],
        Row(
          children: [
            Expanded(
              child: GlobalOutlinedButton(
                text: cancelLabel,
                onPressed: () => Navigator.of(context).pop(false),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GlobalFilledButton(
                text: confirmLabel,
                style: isDanger
                    ? ButtonStateStyle(
                        backgroundColor: context.statusColors.error,
                      )
                    : null,
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
