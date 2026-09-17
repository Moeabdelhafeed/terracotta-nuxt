import 'package:flutter/material.dart';

import '../../../../core/localization/strings/drop_down_strings.dart';
import '../../../module/drop_down/global_drop_down.dart';

/// Dropdown backed by a remote search — items load from
/// [itemsLoader] whenever the user types. Debounced internally by
/// `GlobalDropdown`.
///
/// ```dart
/// AsyncDropdownField<User>(
///   value: selected,
///   onChanged: (u) => cubit.select(u),
///   itemsLoader: (q) async {
///     final users = await api.searchUsers(q);
///     return users.map((u) => DropdownItem(value: u, label: u.name)).toList();
///   },
/// );
/// ```
class AsyncDropdownField<T> extends StatelessWidget {
  const AsyncDropdownField({
    super.key,
    required this.itemsLoader,
    required this.value,
    required this.onChanged,
    this.label,
    this.hint,
    this.enabled = true,
    this.errorText,
    this.infoLabel,
    this.onInfoLabelTap,
    this.showClearButton = true,
    this.maxHeight = 300,
  });

  /// Called with the current search query. Return matching items.
  final Future<List<DropdownItem<T>>> Function(String query) itemsLoader;

  final T? value;
  final ValueChanged<T?>? onChanged;
  final String? label;
  final String? hint;
  final bool enabled;
  final String? errorText;
  final String? infoLabel;
  final VoidCallback? onInfoLabelTap;
  final bool showClearButton;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    return GlobalDropdown<T>(
      items: const [],
      asyncItemsLoader: itemsLoader,
      selectedValue: value,
      onChanged: onChanged,
      identifier: label,
      hint: hint ?? DropDownStrings.search,
      enabled: enabled,
      errorText: errorText,
      behavior: DropdownBehavior(
        enableSearch: true,
        showClearButton: showClearButton,
        maxHeight: maxHeight,
      ),
      slots: DropdownSlots(
        infoLabel: infoLabel,
        onInfoLabelTap: onInfoLabelTap,
      ),
    );
  }
}
