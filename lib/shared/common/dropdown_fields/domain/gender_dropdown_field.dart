import 'package:flutter/material.dart';

import '../../../../core/localization/strings/drop_down_strings.dart';
import '../../../../core/localization/strings/gender_strings.dart';
import '../../../module/drop_down/global_drop_down.dart';
import '../generic/simple_dropdown_field.dart';

/// Standard set of gender options. Replace or extend [Gender] if
/// your product surveys additional categories.
enum Gender { male, female, other, preferNotToSay }

extension GenderLabel on Gender {
  String get label => switch (this) {
    Gender.male => GenderStrings.male,
    Gender.female => GenderStrings.female,
    Gender.other => GenderStrings.other,
    Gender.preferNotToSay => GenderStrings.preferNotToSay,
  };

  IconData get icon => switch (this) {
    Gender.male => Icons.male_rounded,
    Gender.female => Icons.female_rounded,
    Gender.other => Icons.transgender_rounded,
    Gender.preferNotToSay => Icons.visibility_off_outlined,
  };
}

/// Gender picker with per-option icons. Labels are localized
/// (`GenderStrings`, en + ar).
///
/// [includeOther] / [includePreferNotToSay] trim the option set —
/// some markets/locales only survey male/female.
class GenderDropdownField extends StatelessWidget {
  const GenderDropdownField({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.hint,
    this.enabled = true,
    this.errorText,
    this.includeOther = true,
    this.includePreferNotToSay = true,
  });

  final Gender? value;
  final ValueChanged<Gender?>? onChanged;
  final String? label;
  final String? hint;
  final bool enabled;
  final String? errorText;

  /// Include [Gender.other]. Off for markets where the option doesn't
  /// translate.
  final bool includeOther;

  /// Include [Gender.preferNotToSay].
  final bool includePreferNotToSay;

  @override
  Widget build(BuildContext context) {
    final values = [
      for (final g in Gender.values)
        if ((g != Gender.other || includeOther) &&
            (g != Gender.preferNotToSay || includePreferNotToSay))
          g,
    ];
    final items = [
      for (final g in values)
        DropdownItem<Gender>(
          value: g,
          label: g.label,
          leading: Icon(g.icon, size: 20),
        ),
    ];
    return SimpleDropdownField<Gender>(
      items: items,
      value: value,
      onChanged: onChanged,
      label: label ?? DropDownStrings.genderLabel,
      hint: hint ?? DropDownStrings.genderHint,
      enabled: enabled,
      errorText: errorText,
    );
  }
}
