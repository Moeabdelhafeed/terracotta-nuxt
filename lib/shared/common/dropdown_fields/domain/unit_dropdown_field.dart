import 'package:flutter/material.dart';

import '../../../../core/localization/strings/drop_down_strings.dart';
import '../../../../core/localization/strings/misc_field_strings.dart';
import '../../../module/drop_down/global_drop_down.dart';
import '../../text_form_fields/domain/measurement_field.dart'
    show MeasurementUnits;

/// Measurement-unit picker over a unit set (use the [MeasurementUnits]
/// presets — `MeasurementUnits.weight`, `.length`, `.volume`… — or any
/// custom symbol list). Labels localize per the active locale
/// (`kg` → `كغم`); the emitted value is ALWAYS the canonical symbol.
///
/// The same rows power `MeasurementField`'s joined unit picker via
/// [itemFor] — one source for how a unit renders.
class UnitDropdownField extends StatelessWidget {
  const UnitDropdownField({
    super.key,
    required this.units,
    required this.value,
    required this.onChanged,
    this.label,
    this.hint,
    this.enabled = true,
    this.errorText,
    this.infoLabel,
    this.onInfoLabelTap,
    this.preferredUnits = const [],
  });

  /// Canonical unit symbols to list (a [MeasurementUnits] preset or a
  /// custom list).
  final List<String> units;

  /// Selected canonical symbol.
  final String? value;
  final ValueChanged<String?>? onChanged;
  final String? label;
  final String? hint;
  final bool enabled;
  final String? errorText;
  final String? infoLabel;
  final VoidCallback? onInfoLabelTap;

  /// Symbols pinned in a "Common" group above the rest.
  final List<String> preferredUnits;

  /// Canonical unit row — value = symbol (emitted / stored), label =
  /// localized display, search still hits the raw symbol.
  static DropdownItem<String> itemFor(String u) => DropdownItem(
    value: u,
    label: MeasurementUnits.localize(u),
    searchText: u,
  );

  @override
  Widget build(BuildContext context) {
    final preferred = preferredUnits.where(units.contains).toList();
    final groups = preferred.isEmpty
        ? null
        : [
            DropdownGroup(
              label: MeasurementFieldStrings.preferredUnits,
              items: [for (final u in preferred) itemFor(u)],
            ),
            DropdownGroup(
              label: MeasurementFieldStrings.allUnits,
              items: [
                for (final u in units)
                  if (!preferred.contains(u)) itemFor(u),
              ],
            ),
          ];

    return GlobalDropdown<String>(
      items: groups != null ? const [] : [for (final u in units) itemFor(u)],
      groups: groups,
      selectedValue: value,
      onChanged: onChanged,
      identifier: label,
      hint: hint ?? DropDownStrings.unitHint,
      enabled: enabled,
      errorText: errorText,
      behavior: const DropdownBehavior(enableSearch: true),
      slots: DropdownSlots(
        infoLabel: infoLabel,
        onInfoLabelTap: onInfoLabelTap,
      ),
    );
  }
}
