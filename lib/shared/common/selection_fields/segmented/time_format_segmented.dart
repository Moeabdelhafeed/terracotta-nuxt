import 'package:flutter/material.dart';

import '../../../../core/localization/strings/module_strings.dart';
import '../../../module/segmented_control/global_segmented_control.dart';

/// Clock notation preference.
enum ClockFormat { h12, h24 }

/// 12h/24h clock picker — settings staple, pairs with `TimeField`'s
/// format handling. Localized labels ("12h" / "12 ساعة").
class TimeFormatSegmented extends StatelessWidget {
  const TimeFormatSegmented({
    super.key,
    required this.value,
    required this.onChanged,
    this.variant = SegmentedVariant.filled,
    this.style = const SegmentedStyle(),
    this.enabled = true,
  });

  final ClockFormat value;
  final ValueChanged<ClockFormat>? onChanged;
  final SegmentedVariant variant;
  final SegmentedStyle style;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    // Locale dependency — labels resolve via Tr/S (static reads).
    Localizations.maybeLocaleOf(context);
    return GlobalSegmentedControl<ClockFormat>(
      segments: [
        SegmentItem(
          value: ClockFormat.h12,
          label: SegmentedControlStrings.time12h,
        ),
        SegmentItem(
          value: ClockFormat.h24,
          label: SegmentedControlStrings.time24h,
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
