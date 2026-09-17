import 'package:flutter/material.dart';

import '../../../../core/constants/country_codes.dart';
import '../../../../core/extensions/country_code_extensions.dart';
import '../../../../core/localization/strings/drop_down_strings.dart';
import '../../../../data/models/common/country_code/country_code.dart';
import '../../../module/drop_down/global_drop_down.dart';
import '../../country_flag_image.dart';
import '../generic/searchable_dropdown_field.dart';

/// Full COUNTRY picker — the trigger shows `flag Name` (localized via
/// the ARB-backed `translatedName`, en + ar). For a dial-code-focused
/// trigger (`flag +962`) use `CountryCodeDropdownField` instead;
/// both emit the same [CountryCode].
///
/// Searchable by localized or English name, ISO code and dial code.
class CountryDropdownField extends StatelessWidget {
  const CountryDropdownField({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.hint,
    this.enabled = true,
    this.errorText,
    this.infoLabel,
    this.onInfoLabelTap,
    this.showClearButton = false,
  });

  final CountryCode? value;
  final ValueChanged<CountryCode?>? onChanged;
  final String? label;
  final String? hint;
  final bool enabled;
  final String? errorText;
  final String? infoLabel;
  final VoidCallback? onInfoLabelTap;
  final bool showClearButton;

  /// Canonical country-name row — `flag <localized name>`, searchable
  /// by localized/English name + ISO code. Shared with `AddressForm`'s
  /// country picker so both render identically. [withDialCode] adds the
  /// dial code as the overlay-row trailing + search token — wanted here,
  /// not in the address form.
  static DropdownItem<CountryCode> itemFor(
    CountryCode c, {
    bool withDialCode = true,
  }) => DropdownItem<CountryCode>(
    value: c,
    label: c.translatedName,
    leading: CountryFlagImage(country: c),
    searchText: withDialCode
        ? '${c.translatedName} ${c.name ?? ''} ${c.code} ${c.dialCode ?? ''}'
        : '${c.translatedName} ${c.name ?? ''} ${c.code}',
    dropdownOverride: withDialCode
        ? DropdownItemOverride(trailing: Text(c.dialCode ?? ''))
        : null,
  );

  @override
  Widget build(BuildContext context) {
    final items = CountryCodes.countryCodes.map(itemFor).toList();

    return SearchableDropdownField<CountryCode>(
      items: items,
      value: value,
      onChanged: onChanged,
      label: label,
      hint: hint ?? DropDownStrings.countryHint,
      enabled: enabled,
      errorText: errorText,
      infoLabel: infoLabel,
      onInfoLabelTap: onInfoLabelTap,
      showClearButton: showClearButton,
    );
  }
}
