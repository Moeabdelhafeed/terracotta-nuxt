import 'package:flutter/material.dart';

import '../../../../core/constants/country_codes.dart';
import '../../../../core/extensions/country_code_extensions.dart';
import '../../../../core/extensions/theme_colors_extension.dart';
import '../../../../core/localization/strings/drop_down_strings.dart';
import '../../../../core/tokens/extensions.dart';
import '../../../../data/models/common/country_code/country_code.dart';
import '../../../module/drop_down/global_drop_down.dart';
import '../../country_flag_image.dart';
import '../generic/searchable_dropdown_field.dart';

/// Which code the TRIGGER shows beside the flag — echoed as the overlay
/// row's trailing.
enum CountryItemLabel { dialCode, isoCode }

/// Country code picker — shows `flag  +dial` in the trigger and
/// `flag  Name (+dial)` inside the overlay. Searchable by localized OR
/// English country name, ISO code and dial code.
///
/// Names come from `translatedName` (ARB-backed, en + ar, remote-
/// overridable) and flags are [CountryFlagImage]s (emoji flags render
/// as tofu on several newer iOS models) — same treatment as the
/// phone / national-ID pickers.
///
/// Pair with a phone-number field: this dropdown emits the
/// selected [CountryCode]; the phone field stays free-text.
class CountryCodeDropdownField extends StatelessWidget {
  const CountryCodeDropdownField({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.hint,
    this.enabled = true,
    this.errorText,
  });

  final CountryCode? value;
  final ValueChanged<CountryCode?>? onChanged;
  final String? label;
  final String? hint;
  final bool enabled;
  final String? errorText;

  /// Canonical country-code row — one source for how a country renders
  /// across the phone / national-ID / standalone pickers. Trigger shows
  /// `[icon] flag <label>`, overlay rows `flag <localized name>` +
  /// trailing code (or a single `Name (+962)` label when
  /// [inlineDialInOverlayLabel]).
  static DropdownItem<CountryCode> itemFor(
    BuildContext context,
    CountryCode c, {
    CountryItemLabel labelKind = CountryItemLabel.dialCode,
    IconData? triggerIcon,
    bool inlineDialInOverlayLabel = false,
    bool searchDialCode = true,
    bool showFlag = true,
  }) {
    final label = switch (labelKind) {
      CountryItemLabel.dialCode => c.dialCode ?? '',
      CountryItemLabel.isoCode => c.code,
    };
    return DropdownItem<CountryCode>(
      value: c,
      label: label,
      // Trigger leading: optional prefix icon + flag, spaced like every
      // other field's prefix icon. Overlay rows (override below) show
      // the bare flag. Image flags — emoji flags don't render on newer
      // iOS models.
      // `showFlag: false` leaves the dial code to speak for itself,
      // which is how the Terracotta design draws it — the studio sells
      // in one country, so a flag beside every number is decoration
      // that costs width the number needs.
      leading: switch ((triggerIcon, showFlag)) {
        (null, false) => null,
        (null, true) => CountryFlagImage(country: c),
        (final IconData icon, false) => Icon(
          icon,
          color: context.iconColors.primary,
        ),
        (final IconData icon, true) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: context.iconColors.primary),
            SizedBox(width: context.spacing.sm),
            CountryFlagImage(country: c),
          ],
        ),
      },
      // Localized + English names in the haystack — an Arabic UI still
      // matches a Latin query (and vice versa). Token order (name, en
      // name, dial, ISO) is harmonized across all consumers; empty
      // tokens are dropped so a dial-less country can't leave a double
      // space in the contains() haystack.
      searchText: [
        c.translatedName,
        c.name ?? '',
        if (searchDialCode) c.dialCode ?? '',
        c.code,
      ].where((s) => s.isNotEmpty).join(' '),
      dropdownOverride: inlineDialInOverlayLabel
          ? DropdownItemOverride(
              label: '${c.translatedName} (${c.dialCode ?? ''})',
              leading: CountryFlagImage(country: c),
            )
          : DropdownItemOverride(
              label: c.translatedName,
              leading: CountryFlagImage(country: c),
              trailing: Text(label),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      for (final c in CountryCodes.countryCodes)
        itemFor(context, c, inlineDialInOverlayLabel: true),
    ];

    return SearchableDropdownField<CountryCode>(
      items: items,
      value: value,
      onChanged: onChanged,
      label: label,
      hint: hint ?? DropDownStrings.countryHint,
      enabled: enabled,
      errorText: errorText,
    );
  }
}
