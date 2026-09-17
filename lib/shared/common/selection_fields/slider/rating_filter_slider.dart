import 'package:flutter/material.dart';

import '../../../../core/localization/number_formatter.dart';
import '../../../../core/localization/strings/module_strings.dart';
import 'settings_slider_row.dart';

/// "★ 3 and up" — the minimum-rating filter.
///
/// Zero is not a rating, it is NO filter, so the bottom step says
/// "Any" rather than "0★". A list that silently required at least one
/// star would hide everything unrated.
///
/// Localized (en + ar) preset over [SettingsSliderRow].
class RatingFilterSlider extends StatelessWidget {
  const RatingFilterSlider({
    super.key,
    required this.minRating,
    required this.onChanged,
    this.maxStars = 5,
    this.onChangeEnd,
    this.enabled = true,
    this.dense = false,
    this.showIcon = true,
  });

  /// 0 = no filter, 1–[maxStars] = that many stars and up.
  final int minRating;
  final ValueChanged<int>? onChanged;
  final int maxStars;
  final ValueChanged<int>? onChangeEnd;
  final bool enabled;
  final bool dense;
  final bool showIcon;

  String _label(double v) {
    final stars = v.round();
    if (stars <= 0) return SliderStrings.any;
    return '${AppNumbers.decimal(stars, fractionDigits: 0)}★+';
  }

  @override
  Widget build(BuildContext context) {
    Localizations.maybeLocaleOf(context);

    return SettingsSliderRow(
      title: SliderStrings.minRating,
      leading: showIcon ? Icons.star_rounded : null,
      min: 0,
      max: maxStars.toDouble(),
      value: minRating.toDouble(),
      divisions: maxStars,
      enabled: enabled,
      dense: dense,
      onChanged: onChanged == null ? null : (v) => onChanged!(v.round()),
      onChangeEnd: onChangeEnd == null ? null : (v) => onChangeEnd!(v.round()),
      valueFormatter: _label,
      // A star glyph is not a word; the announcement spells it out.
      semanticFormatter: (v) => v.round() <= 0
          ? SliderStrings.any
          : '${AppNumbers.decimal(v.round(), fractionDigits: 0)} '
                '${SliderStrings.minRating}',
    );
  }
}
