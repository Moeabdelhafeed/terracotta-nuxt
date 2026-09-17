import 'package:flutter/material.dart';

import '../../../../core/localization/strings/module_strings.dart';
import '../../../module/segmented_control/global_segmented_control.dart';

/// The classic list filter states.
enum StatusFilter { all, active, archived }

/// All / Active / Archived filter — the list-screen staple (tasks,
/// orders, projects). Localized labels baked in.
class StatusFilterSegmented extends StatelessWidget {
  const StatusFilterSegmented({
    super.key,
    required this.value,
    required this.onChanged,
    this.variant = SegmentedVariant.filled,
    this.style = const SegmentedStyle(),
    this.enabled = true,
  });

  final StatusFilter value;
  final ValueChanged<StatusFilter>? onChanged;
  final SegmentedVariant variant;
  final SegmentedStyle style;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    // Locale dependency — labels resolve via Tr/S (static reads).
    Localizations.maybeLocaleOf(context);
    return GlobalSegmentedControl<StatusFilter>(
      segments: [
        SegmentItem(
          value: StatusFilter.all,
          label: SegmentedControlStrings.statusAll,
        ),
        SegmentItem(
          value: StatusFilter.active,
          label: SegmentedControlStrings.statusActive,
        ),
        SegmentItem(
          value: StatusFilter.archived,
          label: SegmentedControlStrings.statusArchived,
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
