import 'package:flutter/material.dart';

import '../../../module/toggle_group/global_toggle_group.dart';

/// The standard clothing-size ladder, cheapest-to-largest.
const kSizeTokens = ['XS', 'S', 'M', 'L', 'XL', 'XXL'];

/// XS–XXL size filter — e-commerce listing staple. Labels are the
/// international size tokens — locale-agnostic by design, like
/// `TimeFormatSegmented`'s 12h/24h. Multi-select; pass [sizes] to
/// trim the ladder (`['S', 'M', 'L']`).
class SizeFilterToggle extends StatelessWidget {
  const SizeFilterToggle({
    super.key,
    required this.selected,
    required this.onChanged,
    this.sizes = kSizeTokens,
    this.multiSelect = true,
    this.style = const ToggleGroupStyle(),
    this.enabled = true,
  }) : assert(sizes.length >= 2, 'need at least two sizes');

  /// Selected size tokens (subset of [sizes]).
  final List<String> selected;

  final ValueChanged<List<String>> onChanged;

  /// The tokens offered, in display order.
  final List<String> sizes;

  /// Filters usually allow several sizes; `false` = single pick.
  final bool multiSelect;

  final ToggleGroupStyle style;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return GlobalToggleGroup<String>(
      items: [
        for (final s in sizes) ToggleGroupItem(value: s, label: s),
      ],
      selectedValues: selected,
      onChanged: onChanged,
      multiSelect: multiSelect,
      // Dense — six buttons stay comfortable on a phone.
      style: const ToggleGroupStyle(
        itemPadding: EdgeInsets.symmetric(horizontal: 4),
      ).mergedWith(style),
      enabled: enabled,
    );
  }
}
