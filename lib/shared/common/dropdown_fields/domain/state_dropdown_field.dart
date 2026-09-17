import 'package:flutter/material.dart';

import '../../../../core/constants/address_schemas.dart';
import '../../../../core/localization/strings/drop_down_strings.dart';
import '../../../module/drop_down/global_drop_down.dart';
import '../generic/searchable_dropdown_field.dart';

/// Governorate / region / emirate picker for [countryIso], backed by
/// the same `AddressSchemas` data the `AddressForm` uses (JO / EG / SA
/// / AE curated, en + ar). Emits the subdivision CODE ('AM', 'DXB'…).
///
/// [StateDropdownField.hasDataFor] tells you whether a country carries
/// a curated list — render a free-text field for the rest, exactly
/// like `AddressForm` does.
class StateDropdownField extends StatelessWidget {
  const StateDropdownField({
    super.key,
    required this.countryIso,
    required this.value,
    required this.onChanged,
    this.label,
    this.hint,
    this.enabled = true,
    this.errorText,
    this.infoLabel,
    this.onInfoLabelTap,
  });

  /// ISO 3166 alpha-2 of the country whose subdivisions to list.
  final String countryIso;

  /// Selected subdivision code (`AddressSubdivision.$1`).
  final String? value;
  final ValueChanged<String?>? onChanged;
  final String? label;
  final String? hint;
  final bool enabled;
  final String? errorText;
  final String? infoLabel;
  final VoidCallback? onInfoLabelTap;

  /// Whether [iso] has a curated subdivision list.
  static bool hasDataFor(String iso) =>
      AddressSchemas.schemaFor(iso)?.subdivisions != null;

  /// Canonical subdivision row — localized label (en/ar), searchable by
  /// both names + code. Shared with `AddressForm`'s governorate
  /// dropdown. [isArabic] is passed in (not read from context) so each
  /// consumer keeps its own locale source: this field uses
  /// `Localizations.localeOf(context)`, `AddressForm` uses
  /// `Intl.getCurrentLocale()`.
  static DropdownItem<String> itemFor(
    AddressSubdivision s, {
    required bool isArabic,
  }) => DropdownItem<String>(
    value: s.$1,
    label: isArabic ? s.$3 : s.$2,
    searchText: '${s.$2} ${s.$3} ${s.$1}',
  );

  @override
  Widget build(BuildContext context) {
    final subdivisions =
        AddressSchemas.schemaFor(countryIso)?.subdivisions ?? const [];
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final items = [
      for (final s in subdivisions) itemFor(s, isArabic: isAr),
    ];
    return SearchableDropdownField<String>(
      items: items,
      value: value,
      onChanged: onChanged,
      label: label,
      hint: hint ?? DropDownStrings.stateHint,
      enabled: enabled && items.isNotEmpty,
      errorText: errorText,
      infoLabel: infoLabel,
      onInfoLabelTap: onInfoLabelTap,
    );
  }
}
