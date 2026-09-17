import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/strings/common_strings.dart';
import '../../../core/tokens/extensions.dart';
import '../../module/sheet/global_sheet.dart';
import '../text_form_fields/generic/search_text_field.dart';

/// One option in [showSelectionSheet] / [showMultiSelectSheet].
@immutable
class SelectionSheetItem<T> {
  const SelectionSheetItem({
    required this.value,
    required this.label,
    this.icon,
    this.enabled = true,
  });

  final T value;
  final String label;
  final IconData? icon;
  final bool enabled;
}

/// Single-select option list — the mobile counterpart to a dropdown.
/// Resolves with the picked value, or `null` on dismiss. [selected]
/// renders a trailing check mark. [enableSearch] adds a filter field
/// (case-insensitive label match).
Future<T?> showSelectionSheet<T>({
  BuildContext? context,
  required String title,
  required List<SelectionSheetItem<T>> items,
  T? selected,
  bool enableSearch = false,
  String? searchHint,
  SheetStyle style = const SheetStyle(),
}) {
  return GlobalBottomSheet.show<T>(
    context: context,
    title: title,
    style: style,
    content: _SelectionSheetContent<T>(
      items: items,
      selected: selected,
      enableSearch: enableSearch,
      searchHint: searchHint,
    ),
  );
}

class _SelectionSheetContent<T> extends StatefulWidget {
  const _SelectionSheetContent({
    required this.items,
    required this.selected,
    required this.enableSearch,
    required this.searchHint,
  });

  final List<SelectionSheetItem<T>> items;
  final T? selected;
  final bool enableSearch;
  final String? searchHint;

  @override
  State<_SelectionSheetContent<T>> createState() =>
      _SelectionSheetContentState<T>();
}

class _SelectionSheetContentState<T> extends State<_SelectionSheetContent<T>> {
  final _searchCtrl = TextEditingController();
  var _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final visible = q.isEmpty
        ? widget.items
        : widget.items.where((i) => i.label.toLowerCase().contains(q)).toList();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.enableSearch) ...[
          SearchTextField(
            controller: _searchCtrl,
            hint: widget.searchHint ?? CommonStrings.search,
            onChanged: (v) => setState(() => _query = v),
          ),
          SizedBox(height: context.spacing.sm),
        ],
        if (visible.isEmpty)
          Padding(
            padding: EdgeInsets.all(context.spacing.md),
            child: Text(
              CommonStrings.noResults,
              textAlign: TextAlign.center,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.textColors.secondary,
              ),
            ),
          ),
        for (final item in visible)
          _OptionRow<T>(
            item: item,
            isSelected: item.value == widget.selected,
            onTap: () => Navigator.of(context).pop(item.value),
          ),
      ],
    );
  }
}

class _OptionRow<T> extends StatelessWidget {
  const _OptionRow({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final SelectionSheetItem<T> item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = item.enabled
        ? context.textColors.primary
        : context.textColors.disabled;
    return Semantics(
      button: true,
      selected: isSelected,
      enabled: item.enabled,
      child: InkWell(
        onTap: item.enabled ? onTap : null,
        borderRadius: BorderRadius.circular(context.radii.sm),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.spacing.sm,
            vertical: context.spacing.md,
          ),
          child: Row(
            children: [
              if (item.icon != null) ...[
                Icon(item.icon, size: 22, color: fg),
                SizedBox(width: context.spacing.md),
              ],
              Expanded(
                child: Text(
                  item.label,
                  style: context.textTheme.bodyLarge?.copyWith(color: fg),
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_rounded,
                  size: 22,
                  color: context.primaryColors.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
