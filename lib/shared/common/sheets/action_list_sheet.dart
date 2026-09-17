import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/tokens/extensions.dart';
import '../../module/sheet/global_sheet.dart';

/// One row in [showActionListSheet].
@immutable
class SheetAction<T> {
  const SheetAction({
    required this.value,
    required this.label,
    this.icon,
    this.destructive = false,
    this.enabled = true,
  });

  /// Returned from the sheet future when this row is picked.
  final T value;

  final String label;
  final IconData? icon;

  /// Renders label + icon in the error color (delete, remove…).
  final bool destructive;

  final bool enabled;
}

/// iOS-action-sheet equivalent — a list of tappable rows; resolves
/// with the picked [SheetAction.value], or `null` on dismiss.
///
/// ```dart
/// final choice = await showActionListSheet<String>(
///   context: context,
///   title: 'Attachment',
///   actions: [
///     SheetAction(value: 'camera', label: 'Take photo', icon: Icons.photo_camera_outlined),
///     SheetAction(value: 'delete', label: 'Delete', icon: Icons.delete_outline, destructive: true),
///   ],
/// );
/// ```
Future<T?> showActionListSheet<T>({
  BuildContext? context,
  String? title,
  String? subtitle,
  required List<SheetAction<T>> actions,
  bool showCloseButton = true,
  SheetStyle style = const SheetStyle(),
}) {
  return GlobalBottomSheet.show<T>(
    context: context,
    title: title,
    subtitle: subtitle,
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
