import 'package:flutter/material.dart';

import '../../../../core/localization/number_formatter.dart';
import '../../../../core/localization/strings/module_strings.dart';
import 'settings_range_row.dart';

/// The price filter every shop and marketplace has.
///
/// Localized (en + ar) preset over [SettingsRangeRow].
class PriceRangeSlider extends StatelessWidget {
  const PriceRangeSlider({
    super.key,
    required this.values,
    required this.onChanged,
    required this.max,
    this.min = 0,
    this.currencyCode,
    this.currencySymbol,
    this.divisions,
    this.onChangeEnd,
    this.enabled = true,
    this.dense = false,
    this.showIcon = true,
  });

  final RangeValues values;
  final ValueChanged<RangeValues>? onChanged;
  final double min;
  final double max;

  /// ISO code (`USD`), or a bare [currencySymbol]. Both null falls
  /// back to the locale's own currency.
  final String? currencyCode;
  final String? currencySymbol;

  final int? divisions;
  final ValueChanged<double>? onChangeEnd;
  final bool enabled;
  final bool dense;
  final bool showIcon;

  String _money(double v) => AppNumbers.currency(
    v,
    code: currencyCode,
    symbol: currencySymbol,
    // A price filter in whole units — cents on a slider that steps in
    // tens is noise.
    fractionDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    Localizations.maybeLocaleOf(context);

    return SettingsRangeRow(
      title: SliderStrings.priceRange,
      leading: showIcon ? Icons.sell_outlined : null,
      min: min,
      max: max,
      values: values,
      divisions: divisions,
      enabled: enabled,
      dense: dense,
      onChanged: onChanged,
      onChangeEnd: onChangeEnd,
      valueFormatter: _money,
    );
  }
}
