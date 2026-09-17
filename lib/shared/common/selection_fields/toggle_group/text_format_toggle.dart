import 'package:flutter/material.dart';

import '../../../../core/localization/strings/module_strings.dart';
import '../../../module/toggle_group/global_toggle_group.dart';

/// Text formatting flags.
enum TextFormatOption { bold, italic, underline, strikethrough }

/// Bold / italic / underline / strikethrough — editor and notes
/// toolbar staple. Icon-only, multi-select, localized tooltips.
class TextFormatToggle extends StatelessWidget {
  const TextFormatToggle({
    super.key,
    required this.selected,
    required this.onChanged,
    this.style = const ToggleGroupStyle(),
    this.enabled = true,
  });

  final List<TextFormatOption> selected;
  final ValueChanged<List<TextFormatOption>> onChanged;
  final ToggleGroupStyle style;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    // Locale dependency — tooltips resolve via Tr/S (static reads).
    Localizations.maybeLocaleOf(context);
    return GlobalToggleGroup<TextFormatOption>(
      items: [
        ToggleGroupItem(
          value: TextFormatOption.bold,
          label: ToggleGroupStrings.formatBold,
          icon: Icons.format_bold_rounded,
          tooltip: ToggleGroupStrings.formatBold,
        ),
        ToggleGroupItem(
          value: TextFormatOption.italic,
          label: ToggleGroupStrings.formatItalic,
          icon: Icons.format_italic_rounded,
          tooltip: ToggleGroupStrings.formatItalic,
        ),
        ToggleGroupItem(
          value: TextFormatOption.underline,
          label: ToggleGroupStrings.formatUnderline,
          icon: Icons.format_underlined_rounded,
          tooltip: ToggleGroupStrings.formatUnderline,
        ),
        ToggleGroupItem(
          value: TextFormatOption.strikethrough,
          label: ToggleGroupStrings.formatStrikethrough,
          icon: Icons.format_strikethrough_rounded,
          tooltip: ToggleGroupStrings.formatStrikethrough,
        ),
      ],
      selectedValues: selected,
      onChanged: onChanged,
      multiSelect: true,
      variant: ToggleGroupVariant.iconOnly,
      style: style.copyWith(expandEqual: false),
      enabled: enabled,
    );
  }
}
