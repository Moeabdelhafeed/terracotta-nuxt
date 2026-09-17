import 'package:flutter/material.dart';

import '../../../../core/localization/strings/address_field_strings.dart';
import '../../../module/radio/global_radio.dart';
import '../../text_form_fields/domain/address_form.dart' show AddressType;

export '../../text_form_fields/domain/address_form.dart' show AddressType;

/// Home / Work / Other tag picker — the same [AddressType] enum +
/// localized labels `AddressForm` uses, for saved-address screens that
/// tag outside the composite. Horizontal by default.
class AddressTypeRadioGroup extends StatelessWidget {
  const AddressTypeRadioGroup({
    super.key,
    required this.value,
    required this.onChanged,
    this.direction = Axis.horizontal,
    this.variant = RadioVariant.dot,
    this.style = const RadioStyle(),
    this.enabled = true,
  });

  final AddressType? value;
  final ValueChanged<AddressType> onChanged;
  final Axis direction;
  final RadioVariant variant;
  final RadioStyle style;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    // Locale dependency — labels resolve via Tr/S (static reads).
    Localizations.maybeLocaleOf(context);
    return GlobalRadioGroup<AddressType>(
      items: [
        RadioGroupItem(
          value: AddressType.home,
          label: AddressFieldStrings.typeHome,
        ),
        RadioGroupItem(
          value: AddressType.work,
          label: AddressFieldStrings.typeWork,
        ),
        RadioGroupItem(
          value: AddressType.other,
          label: AddressFieldStrings.typeOther,
        ),
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
