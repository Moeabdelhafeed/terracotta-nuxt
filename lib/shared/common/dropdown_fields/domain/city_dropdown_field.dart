import 'package:flutter/material.dart';

import '../../../../core/constants/address_schemas.dart';
import '../../../../core/localization/strings/drop_down_strings.dart';
import '../../../module/drop_down/global_drop_down.dart';
import '../generic/searchable_dropdown_field.dart';
import 'state_dropdown_field.dart';

/// City / area picker scoped to a governorate — backed by the curated
/// district lists `AddressForm` uses (JO Amman / EG Cairo…, en + ar).
/// Emits the area CODE.
///
/// [CityDropdownField.hasDataFor] tells you whether the (country,
/// state) pair carries a curated list — fall back to free text
/// otherwise, exactly like `AddressForm` does.
class CityDropdownField extends StatelessWidget {
  const CityDropdownField({
    super.key,
    required this.countryIso,
    required this.stateCode,
    required this.value,
    required this.onChanged,
    this.label,
    this.hint,
    this.enabled = true,
    this.errorText,
    this.infoLabel,
    this.onInfoLabelTap,
  });

  /// ISO 3166 alpha-2 of the country.
  final String countryIso;

  /// Subdivision code the areas are scoped to (from
  /// `StateDropdownField` / `AddressForm`).
  final String? stateCode;

  /// Selected area code.
  final String? value;
  final ValueChanged<String?>? onChanged;
  final String? label;
  final String? hint;
  final bool enabled;
  final String? errorText;
  final String? infoLabel;
  final VoidCallback? onInfoLabelTap;

  /// Whether ([iso], [stateCode]) has a curated area list.
  static bool hasDataFor(String iso, String? stateCode) =>
      AddressSchemas.schemaFor(iso)?.areasFor(stateCode) != null;

  /// Canonical area row — identical shape to the subdivision row;
  /// delegates so a future divergence has exactly one place to happen.
  static DropdownItem<String> itemFor(
    AddressSubdivision a, {
    required bool isArabic,
  }) => StateDropdownField.itemFor(a, isArabic: isArabic);

  @override
  Widget build(BuildContext context) {
    final areas =
        AddressSchemas.schemaFor(countryIso)?.areasFor(stateCode) ?? const [];
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final items = [
      for (final a in areas) itemFor(a, isArabic: isAr),
    ];
    return SearchableDropdownField<String>(
      items: items,
      value: value,
      onChanged: onChanged,
      label: label,
      hint: hint ?? DropDownStrings.cityHint,
      enabled: enabled && items.isNotEmpty,
      errorText: errorText,
      infoLabel: infoLabel,
      onInfoLabelTap: onInfoLabelTap,
    );
  }
}
