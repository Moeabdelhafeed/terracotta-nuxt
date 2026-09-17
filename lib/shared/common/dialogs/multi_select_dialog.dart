import 'package:flutter/material.dart';

import '../../../core/localization/strings/module_strings.dart';
import '../../module/buttons/global_filled_button.dart';
import '../../module/buttons/global_text_button.dart';
import '../../module/checkbox/global_checkbox.dart';
import '../../module/dialog/global_dialog.dart';
import '../sheets/selection_sheet.dart' show SelectionSheetItem;

export '../sheets/selection_sheet.dart' show SelectionSheetItem;

/// Checkbox list + Apply/Reset dialog — counterpart of
/// `showMultiSelectSheet`. Resolves with the applied selection, or
/// `null` on dismiss. Reset clears the working set without closing.
Future<List<T>?> showMultiSelectDialog<T>({
  BuildContext? context,
  required String title,
  required List<SelectionSheetItem<T>> items,
  List<T> initialSelected = const [],
  String? applyLabel,
  String? resetLabel,
  DialogStyle style = const DialogStyle(),
}) {
  return GlobalDialog.show<List<T>>(
    context: context,
    title: title,
    style: style,
    content: _MultiSelectDialogContent<T>(
      items: items,
      initialSelected: initialSelected,
      applyLabel: applyLabel ?? SheetStrings.apply,
      resetLabel: resetLabel ?? SheetStrings.reset,
    ),
  );
}

class _MultiSelectDialogContent<T> extends StatefulWidget {
  const _MultiSelectDialogContent({
    required this.items,
    required this.initialSelected,
    required this.applyLabel,
    required this.resetLabel,
  });

  final List<SelectionSheetItem<T>> items;
  final List<T> initialSelected;
  final String applyLabel;
  final String resetLabel;

  @override
  State<_MultiSelectDialogContent<T>> createState() =>
      _MultiSelectDialogContentState<T>();
}

class _MultiSelectDialogContentState<T>
    extends State<_MultiSelectDialogContent<T>> {
  late final Set<T> _selected = {...widget.initialSelected};

  void _toggle(T value) {
    setState(() {
      if (!_selected.remove(value)) _selected.add(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final item in widget.items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: GlobalCheckbox(
              value: _selected.contains(item.value)
                  ? CheckboxValue.checked
                  : CheckboxValue.unchecked,
              onChanged: item.enabled ? (_) => _toggle(item.value) : (_) {},
              enabled: item.enabled,
              label: item.label,
            ),
          ),
        const SizedBox(height: 16),
        Row(
          children: [
            GlobalTextButton(
              text: widget.resetLabel,
              shrinkWidth: true,
              onPressed: () => setState(_selected.clear),
            ),
            const Spacer(),
            GlobalFilledButton(
              text: widget.applyLabel,
              shrinkWidth: true,
              onPressed: () => Navigator.of(context).pop(_selected.toList()),
            ),
          ],
        ),
      ],
    );
  }
}
