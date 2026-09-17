import 'package:flutter/material.dart';

import '../../../../core/localization/strings/module_strings.dart';
import '../../../module/segmented_control/global_segmented_control.dart';

/// Aggregation window for charts/analytics.
enum ChartPeriod { day, week, month, year }

/// The D/W/M/Y period picker — analytics/chart screens' staple.
/// Localized labels baked in; [periods] trims the set.
class ChartPeriodSegmented extends StatelessWidget {
  const ChartPeriodSegmented({
    super.key,
    required this.value,
    required this.onChanged,
    this.periods = ChartPeriod.values,
    this.variant = SegmentedVariant.filled,
    this.style = const SegmentedStyle(),
    this.enabled = true,
  });

  final ChartPeriod value;
  final ValueChanged<ChartPeriod>? onChanged;

  /// Periods offered (defaults to all four).
  final List<ChartPeriod> periods;

  final SegmentedVariant variant;
  final SegmentedStyle style;
  final bool enabled;

  static String _labelFor(ChartPeriod p) => switch (p) {
    ChartPeriod.day => SegmentedControlStrings.periodDay,
    ChartPeriod.week => SegmentedControlStrings.periodWeek,
    ChartPeriod.month => SegmentedControlStrings.periodMonth,
    ChartPeriod.year => SegmentedControlStrings.periodYear,
  };

  @override
  Widget build(BuildContext context) {
    // Locale dependency — labels resolve via Tr/S (static reads).
    Localizations.maybeLocaleOf(context);
    return GlobalSegmentedControl<ChartPeriod>(
      segments: [
        for (final p in periods) SegmentItem(value: p, label: _labelFor(p)),
      ],
      value: value,
      onChanged: onChanged,
      variant: variant,
      style: style,
      enabled: enabled,
    );
  }
}
