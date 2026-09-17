import 'package:flutter/material.dart';

import '../../../../core/localization/strings/drop_down_strings.dart';
import '../../../../core/utils/color_codec.dart';
import '../../../module/drop_down/global_drop_down.dart';
import '../generic/simple_dropdown_field.dart';

export '../../../../core/utils/color_codec.dart' show ColorFormat;

/// Picker for [ColorFormat] — HEX / RGB / HSL / … notation. Row labels
/// are the enum's technical, locale-agnostic tags (`ColorFormat.label`);
/// only the field chrome (label / hint) localizes.
///
/// The same rows power the joined format pickers inside `ColorField` and
/// `SegmentedColorField` via [itemFor] — one source for how a format
/// renders.
class ColorFormatDropdownField extends StatelessWidget {
  const ColorFormatDropdownField({
    super.key,
    required this.value,
    required this.onChanged,
    this.formats = ColorFormat.values,
    this.label,
    this.hint,
    this.enabled = true,
    this.errorText,
  });

  final ColorFormat? value;
  final ValueChanged<ColorFormat?>? onChanged;

  /// Formats offered (defaults to all).
  final List<ColorFormat> formats;

  final String? label;
  final String? hint;
  final bool enabled;
  final String? errorText;

  /// Canonical format row — the technical label doubles as search text.
  static DropdownItem<ColorFormat> itemFor(ColorFormat f) =>
      DropdownItem(value: f, label: f.label, searchText: f.label);

  @override
  Widget build(BuildContext context) {
    return SimpleDropdownField<ColorFormat>(
      items: formats.map(itemFor).toList(),
      value: value,
      onChanged: onChanged,
      label: label ?? DropDownStrings.colorFormatLabel,
      hint: hint ?? DropDownStrings.colorFormatHint,
      enabled: enabled,
      errorText: errorText,
    );
  }
}
