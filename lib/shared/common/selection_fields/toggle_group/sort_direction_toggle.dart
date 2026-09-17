import 'package:flutter/material.dart';

import '../../../../core/localization/strings/module_strings.dart';
import '../../../module/toggle_group/global_toggle_group.dart';

/// Sort direction.
enum SortDirection { ascending, descending }

/// Ascending/descending toggle — pairs with `CommonSortDropdownField`
/// on list screens. Icon-only with localized tooltips.
class SortDirectionToggle extends StatelessWidget {
  const SortDirectionToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.style = const ToggleGroupStyle(),
    this.enabled = true,
  });

  final SortDirection value;
  final ValueChanged<SortDirection>? onChanged;
  final ToggleGroupStyle style;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    // Locale dependency — tooltips resolve via Tr/S (static reads).
    Localizations.maybeLocaleOf(context);
    return GlobalToggleGroup<SortDirection>.single(
      items: [
        ToggleGroupItem(
          value: SortDirection.ascending,
          label: ToggleGroupStrings.sortAsc,
          icon: Icons.arrow_upward_rounded,
          tooltip: ToggleGroupStrings.sortAsc,
        ),
        ToggleGroupItem(
          value: SortDirection.descending,
          label: ToggleGroupStrings.sortDesc,
          icon: Icons.arrow_downward_rounded,
          tooltip: ToggleGroupStrings.sortDesc,
        ),
      ],
      value: value,
      onChanged: onChanged ?? (_) {},
      variant: ToggleGroupVariant.iconOnly,
      style: style.copyWith(expandEqual: false),
      enabled: enabled && onChanged != null,
    );
  }
}
