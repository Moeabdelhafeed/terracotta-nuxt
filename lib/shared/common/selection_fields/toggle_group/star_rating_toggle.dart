import 'package:flutter/material.dart';

import '../../../module/toggle_group/global_toggle_group.dart';

/// 1★–5★ rating filter — hotel class, review filters. Sibling of
/// `PriceTierToggle`: labels are "n★" tokens — locale-agnostic by
/// design. Multi-select by default (filter several classes at once).
class StarRatingToggle extends StatelessWidget {
  const StarRatingToggle({
    super.key,
    required this.selected,
    required this.onChanged,
    this.maxStars = 5,
    this.multiSelect = true,
    this.style = const ToggleGroupStyle(),
    this.enabled = true,
  }) : assert(maxStars >= 3 && maxStars <= 5, 'maxStars must be 3–5');

  /// Selected star counts (1-based).
  final List<int> selected;

  final ValueChanged<List<int>> onChanged;

  /// Number of buckets offered.
  final int maxStars;

  /// Filters usually allow several classes; `false` = single pick.
  final bool multiSelect;

  final ToggleGroupStyle style;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return GlobalToggleGroup<int>(
      items: [
        for (var n = 1; n <= maxStars; n++)
          ToggleGroupItem(value: n, label: '$n★'),
      ],
      selectedValues: selected,
      onChanged: onChanged,
      multiSelect: multiSelect,
      // Dense — five buttons stay comfortable on a phone.
      style: const ToggleGroupStyle(
        itemPadding: EdgeInsets.symmetric(horizontal: 4),
      ).mergedWith(style),
      enabled: enabled,
    );
  }
}
