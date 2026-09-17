import 'package:flutter/material.dart';

import '../../../core/localization/strings/module_strings.dart';
import '../../module/buttons/global_filled_button.dart';
import '../../module/buttons/global_outlined_button.dart';
import '../../module/sheet/global_sheet.dart';

/// How a [showFilterSheet] session ended. `null` from the future
/// means dismissed — treat like cancel.
enum FilterSheetResult { applied, reset }

/// Filter chrome only — localized "Filters" title + Reset/Apply row;
/// the caller supplies [content] (selection_fields wrappers slot in)
/// and OWNS the filter state (hoist it — the sheet never mutates).
///
/// ```dart
/// final result = await showFilterSheet(
///   context: context,
///   content: StatefulBuilder(builder: (_, setSheet) => Column(...)),
/// );
/// if (result == FilterSheetResult.reset) resetFilters();
/// if (result == FilterSheetResult.applied) applyFilters();
/// ```
Future<FilterSheetResult?> showFilterSheet({
  BuildContext? context,
  String? title,
  required Widget content,
  String? applyLabel,
  String? resetLabel,
  SheetStyle style = const SheetStyle(),
}) {
  return GlobalBottomSheet.show<FilterSheetResult>(
    context: context,
    title: title ?? SheetStrings.filters,
    icon: Icons.filter_list_rounded,
    style: style,
    content: content,
    actions: [
      Builder(
        builder: (ctx) => GlobalOutlinedButton(
          text: resetLabel ?? SheetStrings.reset,
          onPressed: () => Navigator.of(ctx).pop(FilterSheetResult.reset),
        ),
      ),
      Builder(
        builder: (ctx) => GlobalFilledButton(
          text: applyLabel ?? SheetStrings.apply,
          onPressed: () => Navigator.of(ctx).pop(FilterSheetResult.applied),
        ),
      ),
    ],
  );
}
