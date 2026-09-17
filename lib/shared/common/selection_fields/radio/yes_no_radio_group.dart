import 'package:flutter/material.dart';

import '../../../../core/localization/strings/module_strings.dart';
import '../../../module/radio/global_radio.dart';

/// The survey staple — a localized Yes/No single-select (horizontal by
/// default). Emits the bool; null [value] renders nothing selected.
class YesNoRadioGroup extends StatelessWidget {
  const YesNoRadioGroup({
    super.key,
    required this.value,
    required this.onChanged,
    this.direction = Axis.horizontal,
    this.variant = RadioVariant.dot,
    this.style = const RadioStyle(),
    this.enabled = true,
  });

  final bool? value;
  final ValueChanged<bool> onChanged;
  final Axis direction;
  final RadioVariant variant;
  final RadioStyle style;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    // Locale dependency — labels resolve via Tr/S (static reads).
    Localizations.maybeLocaleOf(context);
    return GlobalRadioGroup<bool>(
      items: [
        RadioGroupItem(value: true, label: RadioStrings.yes),
        RadioGroupItem(value: false, label: RadioStrings.no),
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
