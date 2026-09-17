import 'package:flutter/material.dart';

import '../../../core/localization/strings/module_strings.dart';
import '../../module/buttons/global_filled_button.dart';
import '../../module/buttons/global_text_button.dart';
import '../../module/checkbox/global_checkbox.dart';
import '../../module/sheet/global_sheet.dart';
import 'selection_sheet.dart';

export 'selection_sheet.dart' show SelectionSheetItem;

/// Checkbox list + Apply/Reset — the filter staple. Resolves with the
/// applied selection, or `null` on dismiss (caller keeps its previous
/// state). Reset clears the working set without closing.
Future<List<T>?> showMultiSelectSheet<T>({
  BuildContext? context,
  required String title,
  required List<SelectionSheetItem<T>> items,
  List<T> initialSelected = const [],
  String? applyLabel,
  String? resetLabel,
  SheetStyle style = const SheetStyle(),
}) {
  return GlobalBottomSheet.show<List<T>>(
    context: context,
    title: title,
    style: style,
    content: _MultiSelectContent<T>(
      items: items,
      initialSelected: initialSelected,
      applyLabel: applyLabel ?? SheetStrings.apply,
      resetLabel: resetLabel ?? SheetStrings.reset,
    ),
  );
}

class _MultiSelectContent<T> extends StatefulWidget {
  const _MultiSelectContent({
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
  State<_MultiSelectContent<T>> createState() => _MultiSelectContentState<T>();
}

class _MultiSelectContentState<T> extends State<_MultiSelectContent<T>> {
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
