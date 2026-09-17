import 'package:flutter/material.dart';

import '../../../../core/constants/currencies.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/localization/strings/drop_down_strings.dart';
import '../../../../core/localization/strings/misc_field_strings.dart';
import '../../../../data/models/common/country_code/country_code.dart';
import '../../../module/drop_down/global_drop_down.dart';
import '../../country_flag_image.dart';

/// Currency picker over the [Currencies] dictionary — flag (or symbol
/// badge), localized display name and `symbol · code` per row,
/// searchable by code / en+ar name / symbol.
///
/// The same rows power `AmountField`'s joined currency picker via
/// [itemFor] — one source for how a currency renders.
class CurrencyDropdownField extends StatelessWidget {
  const CurrencyDropdownField({
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
    this.allowedCurrencies,
    this.preferredCurrencies = const [],
  });

  final Currency? value;
  final ValueChanged<Currency?>? onChanged;
  final String? label;
  final String? hint;
  final bool enabled;
  final String? errorText;
  final String? infoLabel;
  final VoidCallback? onInfoLabelTap;
  final bool showClearButton;

  /// ISO codes to restrict the list to (null = all).
  final List<String>? allowedCurrencies;

  /// ISO codes pinned in a "Preferred" group above the rest.
  final List<String> preferredCurrencies;

  /// Flag image keyed by the currency's country; falls back to the
  /// symbol for supranational currencies with no single flag.
  static Widget badgeFor(BuildContext context, Currency c) {
    final cc = c.countryCode;
    if (cc == null) {
      return Text(
        c.symbol,
        style: context.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      );
    }
    return CountryFlagImage(country: CountryCode(code: cc));
  }

  /// Canonical currency row — trigger shows `flag code`, overlay rows
  /// show `flag <localized name>  symbol · code`.
  static DropdownItem<Currency> itemFor(BuildContext context, Currency c) =>
      DropdownItem<Currency>(
        value: c,
        label: c.code,
        leading: badgeFor(context, c),
        searchText: '${c.code} ${c.name} ${c.nameAr} ${c.symbol}',
        dropdownOverride: DropdownItemOverride(
          label: c.displayName,
          leading: badgeFor(context, c),
          trailing: Text('${c.symbol} · ${c.code}'),
        ),
      );

  List<Currency> get _selectable {
    final allowed = allowedCurrencies?.map((c) => c.toUpperCase()).toSet();
    return Currencies.all
        .where((c) => allowed == null || allowed.contains(c.code))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final selectable = _selectable;
    final preferred = preferredCurrencies
        .map(Currencies.byCode)
        .whereType<Currency>()
        .where(selectable.contains)
        .toList();
    final groups = preferred.isEmpty
        ? null
        : [
            DropdownGroup(
              label: AmountFieldStrings.preferredCurrencies,
              items: [for (final c in preferred) itemFor(context, c)],
            ),
            DropdownGroup(
              label: AmountFieldStrings.allCurrencies,
              items: [
                for (final c in selectable)
                  if (!preferred.contains(c)) itemFor(context, c),
              ],
            ),
          ];

    return GlobalDropdown<Currency>(
      items: groups != null
          ? const []
          : [for (final c in selectable) itemFor(context, c)],
      groups: groups,
      selectedValue: value,
      onChanged: onChanged,
      identifier: label,
      hint: hint ?? DropDownStrings.currencyHint,
      enabled: enabled,
      errorText: errorText,
      behavior: DropdownBehavior(
        enableSearch: true,
        showClearButton: showClearButton,
        maxHeight: 300,
      ),
      slots: DropdownSlots(
        infoLabel: infoLabel,
        onInfoLabelTap: onInfoLabelTap,
      ),
    );
  }
}
