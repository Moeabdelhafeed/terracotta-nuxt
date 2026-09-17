import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/strings/common_strings.dart';
import '../../../core/tokens/extensions.dart';
import '../../module/dialog/global_dialog.dart';
import '../sheets/selection_sheet.dart' show SelectionSheetItem;
import '../text_form_fields/generic/search_text_field.dart';

export '../sheets/selection_sheet.dart' show SelectionSheetItem;

/// Single-select option dialog — counterpart of `showSelectionSheet`.
/// Resolves with the picked value, or `null` on dismiss. [selected]
/// renders a trailing check mark; [enableSearch] adds a filter field.
Future<T?> showSelectionDialog<T>({
  BuildContext? context,
  required String title,
  required List<SelectionSheetItem<T>> items,
  T? selected,
  bool enableSearch = false,
  String? searchHint,
  DialogStyle style = const DialogStyle(),
}) {
  return GlobalDialog.show<T>(
    context: context,
    title: title,
    style: style,
    content: _SelectionDialogContent<T>(
      items: items,
      selected: selected,
      enableSearch: enableSearch,
      searchHint: searchHint,
    ),
  );
}

class _SelectionDialogContent<T> extends StatefulWidget {
  const _SelectionDialogContent({
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
  State<_SelectionDialogContent<T>> createState() =>
      _SelectionDialogContentState<T>();
}

class _SelectionDialogContentState<T>
    extends State<_SelectionDialogContent<T>> {
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
          Semantics(
            button: true,
            selected: item.value == widget.selected,
            enabled: item.enabled,
            child: InkWell(
              onTap: item.enabled
                  ? () => Navigator.of(context).pop(item.value)
                  : null,
              borderRadius: BorderRadius.circular(context.radii.sm),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: context.spacing.sm,
                  vertical: context.spacing.md,
                ),
                child: Row(
                  children: [
                    if (item.icon != null) ...[
                      Icon(
                        item.icon,
                        size: 22,
                        color: item.enabled
                            ? context.textColors.primary
                            : context.textColors.disabled,
                      ),
                      SizedBox(width: context.spacing.md),
                    ],
                    Expanded(
                      child: Text(
                        item.label,
                        style: context.textTheme.bodyLarge?.copyWith(
                          color: item.enabled
                              ? context.textColors.primary
                              : context.textColors.disabled,
                        ),
                      ),
                    ),
                    if (item.value == widget.selected)
                      Icon(
                        Icons.check_rounded,
                        size: 22,
                        color: context.primaryColors.primary,
                      ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
