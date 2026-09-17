import 'package:flutter/material.dart';

import '../../../../core/localization/strings/module_strings.dart';
import '../../../module/toggle_group/global_toggle_group.dart';

/// Any / 1 / 2 / 3 / 4+ minimum-count filter — real-estate bedrooms,
/// baths, guests, seats. Single-select; `null` value = Any. The last
/// button reads "N+" (open-ended upper bucket).
class CountFilterToggle extends StatelessWidget {
  const CountFilterToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.max = 4,
    this.style = const ToggleGroupStyle(),
    this.enabled = true,
  }) : assert(max >= 2 && max <= 6, 'max must be 2–6');

  /// Selected minimum count; `null` = Any.
  final int? value;

  final ValueChanged<int?> onChanged;

  /// Highest bucket — rendered "max+".
  final int max;

  final ToggleGroupStyle style;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    // Locale dependency — the Any label resolves via Tr/S.
    Localizations.maybeLocaleOf(context);
    // 0 stands in for Any — GlobalToggleGroup wants non-null values.
    return GlobalToggleGroup<int>.single(
      items: [
        ToggleGroupItem(value: 0, label: ToggleGroupStrings.countAny),
        for (var i = 1; i <= max; i++)
          ToggleGroupItem(value: i, label: i == max ? '$i+' : '$i'),
      ],
      value: value ?? 0,
      onChanged: (v) => onChanged(v == 0 ? null : v),
      // Dense — up to seven buttons stay comfortable on a phone.
      style: const ToggleGroupStyle(
        itemPadding: EdgeInsets.symmetric(horizontal: 8),
      ).mergedWith(style),
      enabled: enabled,
    );
  }
}
