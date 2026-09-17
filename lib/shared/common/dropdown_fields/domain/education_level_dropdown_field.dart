import 'package:flutter/material.dart';

import '../../../../core/localization/strings/drop_down_strings.dart';
import '../../../../core/localization/strings/education_strings.dart';
import '../../../module/drop_down/global_drop_down.dart';
import '../generic/simple_dropdown_field.dart';

/// Education attainment ladder, ascending. Trim with
/// [EducationLevelDropdownField.levels] when a form only cares about
/// e.g. degree-level entries.
///
/// Arabic labels use Levant/Egypt school terms (`إعدادي` for middle
/// school) — Gulf/Iraq adopters say `متوسط`; override per market via
/// the ARB or a `Tr` remote override.
enum EducationLevel {
  primary,
  middle,
  secondary,
  diploma,
  bachelor,
  master,
  doctorate,
}

extension EducationLevelLabel on EducationLevel {
  String get label => switch (this) {
    EducationLevel.primary => EducationStrings.primary,
    EducationLevel.middle => EducationStrings.middle,
    EducationLevel.secondary => EducationStrings.secondary,
    EducationLevel.diploma => EducationStrings.diploma,
    EducationLevel.bachelor => EducationStrings.bachelor,
    EducationLevel.master => EducationStrings.master,
    EducationLevel.doctorate => EducationStrings.doctorate,
  };
}

/// Education-level picker. Labels are localized (`EducationStrings`,
/// en + ar); order is the enum's ascending ladder.
class EducationLevelDropdownField extends StatelessWidget {
  const EducationLevelDropdownField({
    super.key,
    required this.value,
    required this.onChanged,
    this.levels = EducationLevel.values,
    this.label,
    this.hint,
    this.enabled = true,
    this.errorText,
  });

  final EducationLevel? value;
  final ValueChanged<EducationLevel?>? onChanged;

  /// Levels offered (defaults to the full ladder). Shrinking this
  /// after a pick doesn't clear an already-seeded selection — the
  /// parent owns clearing its stored value.
  final List<EducationLevel> levels;

  final String? label;
  final String? hint;
  final bool enabled;
  final String? errorText;

  /// Canonical education-level row.
  static DropdownItem<EducationLevel> itemFor(EducationLevel l) =>
      DropdownItem(value: l, label: l.label);

  @override
  Widget build(BuildContext context) {
    return SimpleDropdownField<EducationLevel>(
      items: levels.map(itemFor).toList(),
      value: value,
      onChanged: onChanged,
      label: label ?? DropDownStrings.educationLabel,
      hint: hint ?? DropDownStrings.educationHint,
      enabled: enabled,
      errorText: errorText,
    );
  }
}
