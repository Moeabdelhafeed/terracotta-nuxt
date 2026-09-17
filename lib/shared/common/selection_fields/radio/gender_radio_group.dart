import 'package:flutter/material.dart';

import '../../../module/radio/global_radio.dart';
import '../../dropdown_fields/domain/gender_dropdown_field.dart'
    show Gender, GenderLabel;

export '../../dropdown_fields/domain/gender_dropdown_field.dart'
    show Gender, GenderLabel;

/// Radio-group face of the gender picker — same [Gender] enum +
/// localized labels as `GenderDropdownField`, for forms that show the
/// options inline instead of behind a dropdown. [includeOther] /
/// [includePreferNotToSay] trim the set exactly like the dropdown.
class GenderRadioGroup extends StatelessWidget {
  const GenderRadioGroup({
    super.key,
    required this.value,
    required this.onChanged,
    this.includeOther = true,
    this.includePreferNotToSay = true,
    this.direction = Axis.vertical,
    this.variant = RadioVariant.dot,
    this.style = const RadioStyle(),
    this.enabled = true,
  });

  final Gender? value;
  final ValueChanged<Gender> onChanged;
  final bool includeOther;
  final bool includePreferNotToSay;
  final Axis direction;
  final RadioVariant variant;
  final RadioStyle style;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    // Locale dependency — labels resolve via Tr/S (static reads).
    Localizations.maybeLocaleOf(context);
    final options = [
      for (final g in Gender.values)
        if ((includeOther || g != Gender.other) &&
            (includePreferNotToSay || g != Gender.preferNotToSay))
          g,
    ];
    return GlobalRadioGroup<Gender>(
      items: [
        for (final g in options) RadioGroupItem(value: g, label: g.label),
      ],
      groupValue: value,
      onChanged: onChanged,
      direction: direction,
      variant: variant,
      style: style,
      enabled: enabled,
    );
  }
}
