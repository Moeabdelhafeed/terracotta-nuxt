import 'package:flutter/material.dart';

import '../../../core/localization/strings/module_strings.dart';
import '../../module/buttons/global_filled_button.dart';
import '../../module/buttons/global_outlined_button.dart';
import '../../module/dialog/global_dialog.dart';
import '../sheets/filter_sheet.dart' show FilterSheetResult;

export '../sheets/filter_sheet.dart' show FilterSheetResult;

/// Filter chrome dialog — counterpart of `showFilterSheet` for
/// desktop-sized windows. Caller supplies [content] and OWNS the
/// filter state. `null` from the future means dismissed.
Future<FilterSheetResult?> showFilterDialog({
  BuildContext? context,
  String? title,
  required Widget content,
  String? applyLabel,
  String? resetLabel,
  DialogStyle style = const DialogStyle(),
}) {
  return GlobalDialog.show<FilterSheetResult>(
    context: context,
    title: title ?? SheetStrings.filters,
    icon: Icons.filter_list_rounded,
    style: style,
    content: content,
    customActions: [
      Builder(
        builder: (ctx) => GlobalOutlinedButton(
          text: resetLabel ?? SheetStrings.reset,
          shrinkWidth: true,
          onPressed: () => Navigator.of(ctx).pop(FilterSheetResult.reset),
        ),
      ),
      const SizedBox(width: 12),
      Builder(
        builder: (ctx) => GlobalFilledButton(
          text: applyLabel ?? SheetStrings.apply,
          shrinkWidth: true,
          onPressed: () => Navigator.of(ctx).pop(FilterSheetResult.applied),
        ),
      ),
    ],
  );
}
