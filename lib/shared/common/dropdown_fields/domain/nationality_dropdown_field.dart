import 'package:flutter/material.dart';

import '../../../../core/constants/country_codes.dart';
import '../../../../core/extensions/country_code_extensions.dart';
import '../../../../core/localization/strings/drop_down_strings.dart';
import '../../../../data/models/common/country_code/country_code.dart';
import '../../../module/drop_down/global_drop_down.dart';
import '../../country_flag_image.dart';
import '../generic/searchable_dropdown_field.dart';

/// NATIONALITY picker — the demonym ("Jordanian" / "أردني") instead of
/// the country name, the KYC / registration staple. Emits the
/// [CountryCode] so the same model flows through nationality, country
/// and dial-code pickers.
///
/// Names come from `translatedNationality` (ARB-backed, en + ar,
/// remote-overridable, falls back to the country name when a demonym
/// key is missing). Searchable by demonym, localized/English country
/// name and ISO code.
class NationalityDropdownField extends StatelessWidget {
  const NationalityDropdownField({
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

  /// Canonical nationality row — `flag <demonym>`, searchable by the
  /// demonym AND the country's names so "Jordan" still finds
  /// "Jordanian".
  static DropdownItem<CountryCode> itemFor(CountryCode c) =>
      DropdownItem<CountryCode>(
        value: c,
        label: c.translatedNationality,
        leading: CountryFlagImage(country: c),
        searchText:
            '${c.translatedNationality} ${c.translatedName} '
            '${c.name ?? ''} ${c.code}',
      );

  @override
  Widget build(BuildContext context) {
    final items = CountryCodes.countryCodes.map(itemFor).toList();

    return SearchableDropdownField<CountryCode>(
      items: items,
      value: value,
      onChanged: onChanged,
      label: label,
      hint: hint ?? DropDownStrings.nationalityHint,
      enabled: enabled,
      errorText: errorText,
      infoLabel: infoLabel,
      onInfoLabelTap: onInfoLabelTap,
      showClearButton: showClearButton,
    );
  }
}
