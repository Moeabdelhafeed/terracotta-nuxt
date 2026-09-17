import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/theme_colors_extension.dart';
import '../../../../core/tokens/extensions.dart';
import '../../../module/slider/global_slider.dart';

/// A [GlobalSlider] inside a `Form`.
///
/// Every other selection control in this folder has one and the slider
/// did not, so a "budget must be at least 100" rule had to live in the
/// submit handler, where the reader finds out about it after pressing
/// the button rather than while dragging.
///
/// The error row is the same shape the text fields draw, because a
/// form with two kinds of error row reads as two forms.
class SliderFormField extends FormField<double> {
  SliderFormField({
    super.key,
    required double initialValue,
    required this.min,
    required this.max,
    this.label,
    this.helperText,
    this.divisions,
    this.stepLabels,
    this.segments = const [],
    this.valueFormatter,
    this.semanticFormatter,
    this.minLabel,
    this.maxLabel,
    this.showValue = true,
    this.showMinMaxLabels = true,
    this.style,
    ValueChanged<double>? onChanged,
    ValueChanged<double>? onChangeEnd,
    super.enabled,
    super.validator,
    super.autovalidateMode,
    super.restorationId,
  }) : super(
         initialValue: initialValue.clamp(min, max),
         builder: (field) {
           final context = field.context;
           // The strings a validator returns are resolved when it runs
           // and CACHED in the field's state, so a language flip
           // leaves a showing error in the old one.
           Localizations.maybeLocaleOf(context);

           return Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             mainAxisSize: MainAxisSize.min,
             children: [
               GlobalSlider(
                 label: label,
                 min: min,
                 max: max,
                 value: (field.value ?? initialValue).clamp(min, max),
                 divisions: divisions,
                 stepLabels: stepLabels,
                 segments: segments,
                 enabled: field.widget.enabled,
                 showValue: showValue,
                 showMinMaxLabels: showMinMaxLabels,
                 valueFormatter: valueFormatter,
                 semanticFormatter: semanticFormatter,
                 minLabel: minLabel,
                 maxLabel: maxLabel,
                 onChanged: (v) {
                   field.didChange(v);
                   onChanged?.call(v);
                 },
                 onChangeEnd: onChangeEnd,
                 style: style,
               ),
               if (field.hasError || helperText != null)
                 Padding(
                   padding: EdgeInsets.only(
                     top: context.spacing.xs,
                     left: context.spacing.sm,
                     right: context.spacing.sm,
                   ),
                   child: Text(
                     field.errorText ?? helperText!,
                     style: context.textTheme.bodySmall?.copyWith(
                       color: field.hasError
                           ? context.statusColors.error
                           : context.textColors.secondary,
                     ),
                   ),
                 ),
             ],
           );
         },
       );

  final double min;
  final double max;
  final String? label;
  final String? helperText;
  final int? divisions;
  final List<String>? stepLabels;
  final List<double> segments;
  final String Function(double)? valueFormatter;
  final String Function(double)? semanticFormatter;
  final String? minLabel;
  final String? maxLabel;
  final bool showValue;
  final bool showMinMaxLabels;
  final SliderStyle? style;
}
