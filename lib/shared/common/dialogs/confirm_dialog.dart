import 'package:flutter/material.dart';

import '../../../core/localization/strings/common_strings.dart';
import '../../../core/localization/strings/module_strings.dart';
import '../../module/dialog/global_dialog.dart';

/// Confirm/cancel dialog — resolves `true` on confirm, `false` on
/// cancel OR dismiss. Dialog counterpart of `showConfirmSheet`; the
/// copy rides the same `SheetStrings` keys (it is surface-agnostic).
Future<bool> showConfirmDialog({
  BuildContext? context,
  String? title,
  String? message,
  String? confirmLabel,
  String? cancelLabel,
  bool isDanger = false,
  IconData? icon,
  DialogStyle style = const DialogStyle(),
}) {
  return GlobalDialog.confirm(
    context: context,
    title: title ?? SheetStrings.confirmTitle,
    message: message,
    confirmText: confirmLabel ?? SheetStrings.confirm,
    cancelText: cancelLabel ?? CommonStrings.cancel,
    isDestructive: isDanger,
    icon: icon,
  );
}

/// Delete preset — danger styling + localized irreversibility copy.
Future<bool> showDeleteConfirmDialog({
  BuildContext? context,
  String? title,
  String? message,
}) => showConfirmDialog(
  context: context,
  title: title ?? SheetStrings.deleteTitle,
  message: message ?? SheetStrings.deleteMessage,
  confirmLabel: CommonStrings.delete,
  isDanger: true,
  icon: Icons.delete_outline_rounded,
);

/// Logout preset.
Future<bool> showLogoutConfirmDialog({BuildContext? context}) =>
    showConfirmDialog(
      context: context,
      title: SheetStrings.logoutTitle,
      message: SheetStrings.logoutMessage,
      confirmLabel: SheetStrings.logoutConfirm,
      icon: Icons.logout_rounded,
    );

/// Discard-unsaved-changes preset — the back-navigation guard.
Future<bool> showDiscardChangesDialog({BuildContext? context}) =>
    showConfirmDialog(
      context: context,
      title: SheetStrings.discardTitle,
      message: SheetStrings.discardMessage,
      confirmLabel: SheetStrings.discardConfirm,
      isDanger: true,
      icon: Icons.undo_rounded,
    );
