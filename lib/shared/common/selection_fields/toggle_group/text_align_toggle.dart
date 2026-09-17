import 'package:flutter/material.dart';

import '../../../../core/localization/strings/module_strings.dart';
import '../../../module/toggle_group/global_toggle_group.dart';

/// Logical text alignment — start/end, not left/right, so the picker
/// means the same thing under RTL.
enum TextAlignOption { start, center, end, justify }

/// Start / center / end / justify alignment picker — editor toolbar
/// companion to [TextFormatToggle]. Icon-only, single-select. Icons
/// are physical (Material has no logical align glyphs), so start/end
/// swap under RTL to keep the arrow pointing at the writing edge.
class TextAlignToggle extends StatelessWidget {
  const TextAlignToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.style = const ToggleGroupStyle(),
    this.enabled = true,
  });

  final TextAlignOption value;
  final ValueChanged<TextAlignOption>? onChanged;
  final ToggleGroupStyle style;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    // Locale dependency — tooltips resolve via Tr/S (static reads).
    Localizations.maybeLocaleOf(context);
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return GlobalToggleGroup<TextAlignOption>.single(
      items: [
        ToggleGroupItem(
          value: TextAlignOption.start,
          label: ToggleGroupStrings.alignStart,
          icon: isRtl
              ? Icons.format_align_right_rounded
              : Icons.format_align_left_rounded,
          tooltip: ToggleGroupStrings.alignStart,
        ),
        ToggleGroupItem(
          value: TextAlignOption.center,
          label: ToggleGroupStrings.alignCenter,
          icon: Icons.format_align_center_rounded,
          tooltip: ToggleGroupStrings.alignCenter,
        ),
        ToggleGroupItem(
          value: TextAlignOption.end,
          label: ToggleGroupStrings.alignEnd,
          icon: isRtl
              ? Icons.format_align_left_rounded
              : Icons.format_align_right_rounded,
          tooltip: ToggleGroupStrings.alignEnd,
        ),
        ToggleGroupItem(
          value: TextAlignOption.justify,
          label: ToggleGroupStrings.alignJustify,
          icon: Icons.format_align_justify_rounded,
          tooltip: ToggleGroupStrings.alignJustify,
        ),
      ],
      value: value,
      onChanged: onChanged ?? (_) {},
      variant: ToggleGroupVariant.iconOnly,
      style: style.copyWith(expandEqual: false),
      enabled: enabled && onChanged != null,
    );
  }
}
