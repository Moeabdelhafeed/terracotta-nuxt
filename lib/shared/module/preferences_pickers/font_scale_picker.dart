import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/number_formatter.dart';
import '../../../core/localization/strings/module_strings.dart';
import '../../../core/localization/strings/preferences_strings.dart';
import '../../../core/tokens/extensions.dart';
import '../../../data/blocs/preferences/preferences_cubit.dart';
import '../../../data/blocs/preferences/preferences_state.dart';
import '../container/global_container.dart';
import '../slider/global_slider.dart';
import '../text/global_text.dart';
import 'picker_item.dart';
import 'picker_options.dart';
import 'picker_shell.dart';

/// Five canonical accessibility presets used by the picker. Mapped
/// to numeric scale factors that compose with the OS scaler.
enum FontScalePreset {
  small(0.85),
  defaultPreset(1.0),
  large(1.15),
  extraLarge(1.30),
  huge(1.50);

  const FontScalePreset(this.factor);
  final double factor;

  /// Localized display label — resolved at read time via
  /// [PreferencesStrings] (enum entries are const, so it can't be a
  /// stored field).
  String get label => switch (this) {
    FontScalePreset.small => PreferencesStrings.fontScaleSmall,
    FontScalePreset.defaultPreset => PreferencesStrings.fontScaleDefault,
    FontScalePreset.large => PreferencesStrings.fontScaleLarge,
    FontScalePreset.extraLarge => PreferencesStrings.fontScaleExtraLarge,
    FontScalePreset.huge => PreferencesStrings.fontScaleHuge,
  };

  static FontScalePreset closest(double scale) {
    var best = FontScalePreset.defaultPreset;
    var bestDelta = double.infinity;
    for (final p in FontScalePreset.values) {
      final delta = (p.factor - scale).abs();
      if (delta < bestDelta) {
        bestDelta = delta;
        best = p;
      }
    }
    return best;
  }
}

/// Font-scale picker with presets, slider, and live preview.
///
/// Two layouts:
/// - **Preset list/pill** — preset chips, no slider. Use in compact
///   surfaces.
/// - **Slider mode** — set [showSlider] true to surface a fine-grain
///   slider beneath the presets + a live "Aa Bb 12" preview tile.
class FontScalePicker extends StatelessWidget {
  const FontScalePicker({
    this.options,
    this.showSlider = true,
    this.showPreview = true,
    super.key,
    this.style = const PickerStyle(),
  });

  static PickerOptions get _defaults => PickerOptions(
    title: PreferencesStrings.fontSizeTitle,
    subtitle: PreferencesStrings.fontSizeSubtitle,
    icon: Icons.format_size_rounded,
  );

  /// `null` renders the localized defaults.
  final PickerOptions? options;

  /// How the picker LOOKS — spacing, whether rows are ruled. The
  /// controls it draws carry their own bags; this one is thin.
  final PickerStyle style;

  /// Render a slider beneath the presets for fine-grained control.
  final bool showSlider;

  /// Render a live preview tile that demos the current scale.
  final bool showPreview;

  static List<PickerItem<FontScalePreset>> get _items => [
    for (final p in FontScalePreset.values)
      PickerItem<FontScalePreset>(value: p, label: p.label),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PreferencesCubit, PreferencesState>(
      buildWhen: (a, b) =>
          a.fontScale != b.fontScale || a.language.locale != b.language.locale,
      builder: (context, prefs) {
        final cubit = context.read<PreferencesCubit>();
        final preset = FontScalePreset.closest(prefs.fontScale);
        return PickerShell<FontScalePreset>(
          items: _items,
          value: preset,
          onChanged: (p) => cubit.setFontScale(p.factor),
          options: (options ?? const PickerOptions()).mergedOver(_defaults),
          style: style,
          previewBuilder: showPreview
              ? (ctx) => _Preview(scale: prefs.fontScale)
              : null,
        );
      },
    );
  }
}

/// Standalone slider — composes with [FontScalePicker] when both are
/// shown. Available as a separate widget so callers can render only
/// the slider where presets aren't needed.
///
/// It was a bare `Slider` over a hand-rolled min / value / max row —
/// which is `GlobalSlider`'s header and end labels, drawn again. That
/// copy had no `Semantics` (a reader heard the raw factor "1.15"),
/// wrote its own `fontSize: 11`, and hard-coded the strings `'70%'`
/// and `'200%'`, so an Arabic reader got ASCII digits under an Arabic
/// page.
///
/// It builds `GlobalSlider` rather than the commons' `TextScaleSlider`
/// — which is the same control — because a MODULE reaching into
/// `shared/common/` inverts the layering: the commons wrap the
/// modules, not the other way round.
class FontScaleSlider extends StatelessWidget {
  const FontScaleSlider({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PreferencesCubit, PreferencesState>(
      // The slider's own label and its percentage formatter are
      // localized too.
      buildWhen: (a, b) =>
          a.fontScale != b.fontScale || a.language.locale != b.language.locale,
      builder: (context, prefs) => GlobalSlider(
        // The picker above it already names the setting, and the
        // preview under it already shows the result.
        label: SliderStrings.textSize,
        min: PreferencesCubit.minFontScale,
        max: PreferencesCubit.maxFontScale,
        value: prefs.fontScale,
        // 5% a step.
        divisions: 26,
        onChanged: context.read<PreferencesCubit>().setFontScale,
        // The factor is meaningless to a reader; the ENLARGEMENT is
        // not — and through `AppNumbers` it is in the page's own
        // digits, where `'70%'` was ASCII in every language.
        valueFormatter: (v) => AppNumbers.percent(v, fractionDigits: 0),
        style: SliderStyle.bare,
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    final tx = context.textColors;
    final bg = context.backgroundColors;
    return GlobalContainer(
      style: ContainerStyle(
        margin: EdgeInsets.only(bottom: context.spacing.sm),
        padding: EdgeInsets.all(context.spacing.md),
        backgroundColor: bg.cardBackground,
        borderRadius: BorderRadius.circular(context.radii.md),
        borderColor: bg.outlineVariant,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(scale),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GlobalText(
                  'Aa Bb 12',
                  preset: TextPreset.titleLarge,
                  textStyle: GlobalTextStyle(
                    color: tx.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: context.spacing.xs),
                GlobalText(
                  PreferencesStrings.fontPreviewSample,
                  preset: TextPreset.bodySmall,
                  textStyle: GlobalTextStyle(color: tx.secondary),
                ),
              ],
            ),
          ),
          SizedBox(height: context.spacing.xs),
          GlobalText(
            'Scale: ${AppNumbers.percent(scale, fractionDigits: 0)}',
            preset: TextPreset.labelSmall,
            textStyle: GlobalTextStyle(
              color: tx.secondary,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
