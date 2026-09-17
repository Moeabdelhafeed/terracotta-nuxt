import 'package:flutter/material.dart';

import '../../../../core/constants/timezones.dart';
import '../../../../core/localization/strings/drop_down_strings.dart';
import '../../../module/drop_down/global_drop_down.dart';
import '../generic/searchable_dropdown_field.dart';

export '../../../../core/constants/timezones.dart' show TimezoneInfo, Timezones;

/// Timezone picker — profile/settings staple. Rows show the localized
/// city with the standard UTC offset trailing ("Amman  UTC+03:00"),
/// searchable by city (en + ar), IANA id and offset. Emits the
/// [TimezoneInfo] (IANA id + offset).
///
/// Offsets are the standard (winter wall-clock) offsets from the
/// curated [Timezones] catalog — display-grade, not scheduling-grade.
/// For DST-correct wall-clock math feed the emitted IANA id to
/// `package:timezone` (already a dependency) — load the FULL database
/// (`import 'package:timezone/data/latest_all.dart'` +
/// `initializeTimeZones()`): the catalog keeps user-recognizable Link
/// ids (`Asia/Kuwait`) that the default canonical-only `latest.dart`
/// database can't resolve.
class TimezoneDropdownField extends StatelessWidget {
  const TimezoneDropdownField({
    super.key,
    required this.value,
    required this.onChanged,
    this.timezones = Timezones.all,
    this.label,
    this.hint,
    this.enabled = true,
    this.errorText,
    this.infoLabel,
    this.onInfoLabelTap,
    this.showClearButton = false,
  });

  final TimezoneInfo? value;
  final ValueChanged<TimezoneInfo?>? onChanged;

  /// Zones offered (defaults to the full curated catalog,
  /// offset-sorted). Shrinking this after a pick doesn't clear an
  /// already-seeded selection — the parent owns clearing its stored
  /// value.
  final List<TimezoneInfo> timezones;

  final String? label;
  final String? hint;
  final bool enabled;
  final String? errorText;
  final String? infoLabel;
  final VoidCallback? onInfoLabelTap;
  final bool showClearButton;

  /// Canonical timezone row — trigger shows the localized city, overlay
  /// rows add the offset as trailing.
  static DropdownItem<TimezoneInfo> itemFor(
    TimezoneInfo z,
  ) => DropdownItem<TimezoneInfo>(
    value: z,
    label: z.displayCity,
    // Localized + English names in the haystack (country-picker
    // pattern); offsetSearchText adds keyboard-typable variants —
    // the display label's U+2212 minus and zero-padding never match
    // typed "UTC-5".
    searchText:
        '${z.displayCity} ${z.city} ${z.id} ${z.offsetLabel} ${z.offsetSearchText}',
    dropdownOverride: DropdownItemOverride(
      trailing: Text(z.offsetLabel),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return SearchableDropdownField<TimezoneInfo>(
      items: timezones.map(itemFor).toList(),
      value: value,
      onChanged: onChanged,
      label: label,
      hint: hint ?? DropDownStrings.timezoneHint,
      enabled: enabled,
      errorText: errorText,
      infoLabel: infoLabel,
      onInfoLabelTap: onInfoLabelTap,
      showClearButton: showClearButton,
    );
  }
}
