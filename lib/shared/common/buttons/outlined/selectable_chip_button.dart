import 'package:flutter/material.dart';

import '../../../../core/extensions/theme_colors_extension.dart';
import '../../../module/buttons/global_outlined_button.dart';

/// Filter-chip-style toggle. Caller owns [selected] + flips in
/// [onPressed]. Selected state fills with primary color; idle stays
/// outlined.
///
/// ```dart
/// Wrap(
///   spacing: 8,
///   children: tags.map((t) => SelectableChipButton(
///     text: t.name,
///     selected: state.selected.contains(t),
///     onPressed: () => cubit.toggle(t),
///   )).toList(),
/// );
/// ```
class SelectableChipButton extends StatelessWidget {
  const SelectableChipButton({
    super.key,
    required this.text,
    required this.selected,
    required this.onPressed,
    this.icon,
    this.enabled = true,
    this.tooltip,
  });

  final String text;
  final bool selected;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool enabled;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final primary = context.primaryColors.primary;
    return GlobalOutlinedButton(
      text: text,
      onPressed: onPressed,
      enabled: enabled,
      tooltip: tooltip,
      shrinkWidth: true,
      style: ButtonStateStyle(
        backgroundColor: selected ? primary : Colors.transparent,
        foregroundColor: selected ? context.textColors.onPrimary : primary,
        border: BorderSide(color: primary),
        borderRadius: BorderRadius.circular(100),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: icon,
      ),
    );
  }
}
