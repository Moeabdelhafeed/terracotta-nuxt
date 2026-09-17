import 'package:flutter/material.dart';

import '../../../module/toggle_group/global_toggle_group.dart';

/// Price-tier filter ($ … $$$$) — restaurants, hotels, marketplaces.
/// Multi-select by default (filter several tiers at once); labels are
/// currency-symbol tokens — locale-agnostic by design. Pass a
/// different [symbol] for non-dollar markets ('€', '£', 'د.أ').
class PriceTierToggle extends StatelessWidget {
  const PriceTierToggle({
    super.key,
    required this.selected,
    required this.onChanged,
    this.tiers = 4,
    this.symbol = r'$',
    this.multiSelect = true,
    this.style = const ToggleGroupStyle(),
    this.enabled = true,
  }) : assert(tiers >= 2 && tiers <= 5, 'tiers must be 2–5');

  /// Selected tier levels (1-based: 1 = cheapest).
  final List<int> selected;

  final ValueChanged<List<int>> onChanged;

  /// Number of tiers offered.
  final int tiers;

  /// The repeated symbol ('$' → $, $$, $$$…).
  final String symbol;

  /// Filters usually allow several tiers; `false` = single pick.
  final bool multiSelect;

  final ToggleGroupStyle style;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return GlobalToggleGroup<int>(
      items: [
        for (var t = 1; t <= tiers; t++)
          ToggleGroupItem(value: t, label: symbol * t),
      ],
      selectedValues: selected,
      onChanged: onChanged,
      multiSelect: multiSelect,
      // Dense padding — up to 5 buttons stay comfortable on a phone.
      style: const ToggleGroupStyle(
        itemPadding: EdgeInsets.symmetric(horizontal: 8),
      ).mergedWith(style),
      enabled: enabled,
    );
  }
}
