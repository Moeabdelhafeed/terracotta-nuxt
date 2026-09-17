import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/tokens/extensions.dart';
import '../../module/dialog/global_dialog.dart';
import '../sheets/action_list_sheet.dart' show SheetAction;

export '../sheets/action_list_sheet.dart' show SheetAction;

/// Dialog counterpart of `showActionListSheet` — tappable rows,
/// resolves with the picked [SheetAction.value] or `null` on dismiss.
/// Prefer the sheet on phones; the dialog reads better on desktop.
Future<T?> showActionListDialog<T>({
  BuildContext? context,
  required String title,
  String? message,
  required List<SheetAction<T>> actions,
  bool showCloseButton = true,
  DialogStyle style = const DialogStyle(),
}) {
  return GlobalDialog.show<T>(
    context: context,
    title: title,
    message: message,
    showCloseButton: showCloseButton,
    style: style,
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [for (final a in actions) _ActionRow<T>(action: a)],
    ),
  );
}

class _ActionRow<T> extends StatelessWidget {
  const _ActionRow({required this.action});

  final SheetAction<T> action;

  @override
  Widget build(BuildContext context) {
    final Color fg;
    if (!action.enabled) {
      fg = context.textColors.disabled;
    } else if (action.destructive) {
      fg = context.statusColors.error;
    } else {
      fg = context.textColors.primary;
    }
    return Semantics(
      button: true,
      enabled: action.enabled,
      child: InkWell(
        onTap: action.enabled
            ? () => Navigator.of(context).pop(action.value)
            : null,
        borderRadius: BorderRadius.circular(context.radii.sm),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.spacing.sm,
            vertical: context.spacing.md,
          ),
          child: Row(
            children: [
              if (action.icon != null) ...[
                Icon(action.icon, size: 22, color: fg),
                SizedBox(width: context.spacing.md),
              ],
              Expanded(
                child: Text(
                  action.label,
                  style: context.textTheme.bodyLarge?.copyWith(color: fg),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
