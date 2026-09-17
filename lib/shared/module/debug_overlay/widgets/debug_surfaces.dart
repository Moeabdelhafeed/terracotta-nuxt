import 'package:flutter/material.dart';

import '../../../../core/localization/strings/common_strings.dart';
import '../../dialog/global_dialog.dart';
import '../../sheet/global_sheet.dart';
import '../debug_overlay_models.dart';

/// Console-styled modal surfaces for the overlay — the pinned
/// [DialogStyle] / [SheetStyle] overrides plus the shared confirm
/// helper that replaces the three hand-rolled `AlertDialog` clones
/// (storage / crash injector / cache nuker).

/// The overlay's pinned console [DialogStyle].
DialogStyle debugDialogStyle() => DialogStyle(
  backgroundColor: DebugOverlayTheme.bg,
  borderRadius: BorderRadius.circular(12),
  border: Border.all(color: DebugOverlayTheme.border),
  titleStyle: DebugOverlayTheme.ui.copyWith(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: DebugOverlayTheme.text,
  ),
  messageStyle: DebugOverlayTheme.ui.copyWith(
    fontSize: 12,
    color: DebugOverlayTheme.textDim,
    height: 1.4,
  ),
);

/// The overlay's pinned console [SheetStyle] — dark surface, hairline
/// border, theme-independent handle. Centralizes the drag-handle
/// double-configuration the raw `showModalBottomSheet` calls had to
/// dodge by hand.
SheetStyle debugSheetStyle() => SheetStyle(
  backgroundColor: DebugOverlayTheme.surface,
  borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
  border: Border.all(color: DebugOverlayTheme.border),
  borderWidth: 1,
  handleColor: DebugOverlayTheme.border,
  useDeviceRadius: false,
  contentPadding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
  enableHaptic: false,
);

/// Console-styled confirm dialog — [GlobalDialog] machinery under the
/// overlay's hermetic look. Resolves `true` on confirm, `false` on
/// cancel OR dismiss.
Future<bool> debugConfirmDialog(
  BuildContext context, {
  required String title,
  required String confirmLabel,
  String? body,
  bool destructive = false,
}) async {
  var confirmed = false;
  await GlobalDialog.show<void>(
    context: context,
    title: title,
    message: body,
    style: debugDialogStyle(),
    confirmText: confirmLabel,
    cancelText: CommonStrings.cancel,
    isDestructive: destructive,
    showCloseButton: false,
    onConfirm: () => confirmed = true,
  );
  return confirmed;
}
