import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/theme_colors_extension.dart';
import '../../../../core/tokens/extensions.dart';
import '../../../module/slider/global_slider.dart';

/// The settings-page staple: a leading icon, a title, an optional
/// description, and a slider under them — the slider counterpart of
/// [SettingsSwitchRow].
///
/// `GlobalSlider` already draws a label and a value badge, so this adds
/// only what the module has no business knowing: the icon that goes
/// beside the title, the second line under it, and the fact that a
/// settings row is bare rather than a card of its own (the list it
/// sits in is the card).
class SettingsSliderRow extends StatelessWidget {
  const SettingsSliderRow({
    super.key,
    required this.value,
    required this.onChanged,
    required this.title,
    required this.min,
    required this.max,
    this.description,
    this.leading,
    this.divisions,
    this.stepLabels,
    this.valueFormatter,
    this.semanticFormatter,
    this.minLabel,
    this.maxLabel,
    this.segments = const [],
    this.enabled = true,
    this.dense = false,
    this.showValue = true,
    this.showMinMaxLabels = false,
    this.onChangeEnd,
    this.style,
    this.contentPadding,
  });

  final double value;
  final ValueChanged<double>? onChanged;
  final String title;
  final double min;
  final double max;

  /// The second line under the title.
  final String? description;

  /// Tinted to the icon palette, like every other settings row.
  final IconData? leading;

  final int? divisions;
  final List<String>? stepLabels;
  final String Function(double)? valueFormatter;
  final String Function(double)? semanticFormatter;
  final String? minLabel;
  final String? maxLabel;
  final List<double> segments;

  final bool enabled;
  final bool dense;
  final bool showValue;

  /// Off by default: a settings row usually carries a value badge and
  /// end labels would say the same range twice.
  final bool showMinMaxLabels;

  /// Where a preference is COMMITTED. Writing on every frame of a drag
  /// is a write per pixel.
  final ValueChanged<double>? onChangeEnd;

  final SliderStyle? style;
  final EdgeInsetsGeometry? contentPadding;

  @override
  Widget build(BuildContext context) {
    final isDisabled = !enabled || onChanged == null;

    return Padding(
      padding:
          contentPadding ??
          EdgeInsets.symmetric(
            vertical: dense ? context.spacing.xs : context.spacing.sm,
            horizontal: context.spacing.md,
          ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          GlobalSlider(
            label: title,
            // Before the LABEL, in the same row. On its own line it
            // floated above the title with nothing beside it whenever
            // there was no description to share the row with.
            leading: leading == null
                ? null
                : Icon(
                    leading,
                    color: isDisabled
                        ? context.iconColors.secondary
                        : context.iconColors.primary,
                    size: context.iconSizes.md,
                  ),
            min: min,
            max: max,
            value: value.clamp(min, max),
            divisions: divisions,
            stepLabels: stepLabels,
            segments: segments,
            enabled: !isDisabled,
            showValue: showValue,
            showMinMaxLabels: showMinMaxLabels,
            valueFormatter: valueFormatter,
            semanticFormatter: semanticFormatter,
            minLabel: minLabel,
            maxLabel: maxLabel,
            onChanged: onChanged ?? (_) {},
            onChangeEnd: onChangeEnd,
            // A settings row is bare: the list it sits in is the card,
            // and a card inside a card is a frame within a frame.
            style: SliderStyle.bare.mergedWith(style),
          ),
          if (description != null)
            Padding(
              // Under the header, indented past nothing: it explains
              // the whole row, not the icon.
              padding: EdgeInsets.only(top: context.spacing.xs),
              child: Text(
                description!,
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.textColors.secondary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
