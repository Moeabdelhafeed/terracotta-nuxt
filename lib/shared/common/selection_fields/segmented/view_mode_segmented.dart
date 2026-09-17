import 'package:flutter/material.dart';

import '../../../../core/localization/strings/module_strings.dart';
import '../../../module/segmented_control/global_segmented_control.dart';

/// How a collection screen renders its items.
enum ViewMode { list, grid }

/// The list/grid view toggle — every collection screen's staple.
/// Localized labels + icons baked in; pair with `GlobalList` /
/// `GlobalGrid`.
class ViewModeSegmented extends StatelessWidget {
  const ViewModeSegmented({
    super.key,
    required this.value,
    required this.onChanged,
    this.variant = SegmentedVariant.filled,
    this.style = const SegmentedStyle(),
    this.enabled = true,
  });

  final ViewMode value;
  final ValueChanged<ViewMode>? onChanged;
  final SegmentedVariant variant;
  final SegmentedStyle style;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    // Locale dependency — labels resolve via Tr/S (static reads).
    Localizations.maybeLocaleOf(context);
    return GlobalSegmentedControl<ViewMode>(
      segments: [
        SegmentItem(
          value: ViewMode.list,
          label: SegmentedControlStrings.viewList,
          icon: Icons.view_list_outlined,
        ),
        SegmentItem(
          value: ViewMode.grid,
          label: SegmentedControlStrings.viewGrid,
          icon: Icons.grid_view_outlined,
        ),
      ],
      value: value,
      onChanged: onChanged,
      variant: variant,
      style: style,
      enabled: enabled,
    );
  }
}
