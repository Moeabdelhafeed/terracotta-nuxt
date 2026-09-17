import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/strings/common_strings.dart';
import '../../../core/responsive/responsive_layout.dart';
import '../../../core/tokens/extensions.dart';
import '../../../data/blocs/preferences/preferences_cubit.dart';
import '../../../data/blocs/preferences/preferences_state.dart';
import '../../../shared/module/app_bar/global_app_bar.dart';
import '../../../shared/module/container/global_container.dart';
import '../../../shared/module/preferences_pickers/preferences_pickers.dart';
import '../../../shared/module/scrollable/global_scrollable.dart';

/// The app's real settings screen.
///
/// **Every section is a picker from `preferences_pickers/`.** It used
/// to hand-roll its own: a private `_Section` card, a private
/// `_PillRow` — a THIRD pill implementation, after the one inside
/// `PickerShell` — and a private section class per preference, for
/// theme, role, saturation, reveal shape, reveal direction and
/// language. Only font size, dynamic colour and reset came from the
/// module.
///
/// So the folder that exists to be the one place for preference UI was
/// bypassed by the one screen that matters, and every fix landing in
/// it — the radio semantics, the ink on a row, the rebuild on a locale
/// change, the reveal — stopped at this file's door. Four hundred
/// lines went with the sweep.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final bg = context.backgroundColors;
    final spacing = context.spacing;

    return Scaffold(
      backgroundColor: bg.scaffoldBackground,
      appBar: GlobalAppBar(
        title: CommonStrings.settings,
        style: AppBarStyle(backgroundColor: bg.scaffoldBackground),
      ),
      body: BlocBuilder<PreferencesCubit, PreferencesState>(
        // The page itself needs no state — every picker watches the
        // field it owns. It rebuilds on a LOCALE change so the cards
        // re-read their headings, which is the one thing they share.
        buildWhen: (a, b) => a.language.locale != b.language.locale,
        builder: (context, _) {
          // Each picker draws its own localized heading, so a section
          // is a card and nothing more.
          const sections = <Widget>[
            _Card(child: ThemeModePicker()),
            _Card(child: AppRolePicker()),
            _Card(child: SaturationPicker()),
            _Card(child: RevealShapePicker()),
            _Card(child: RevealDirectionPicker()),
            _Card(child: LanguagePicker()),
            _Card(child: _FontSize()),
            _Card(child: DynamicColorToggle()),
            _Card(
              child: SizedBox(
                width: double.infinity,
                child: ResetPreferencesButton(),
              ),
            ),
          ];
          return GlobalContainer.shell(
            padding: EdgeInsetsDirectional.fromSTEB(
              spacing.md,
              spacing.sm,
              spacing.md,
              spacing.xl,
            ),
            child: ResponsiveLayout(
              compact: (_) =>
                  _SingleColumn(sections: sections, gap: spacing.md),
              medium: (_) => _SingleColumn(sections: sections, gap: spacing.md),
              expanded: (_) => _TwoColumn(sections: sections, gap: spacing.md),
              large: (_) => _TwoColumn(sections: sections, gap: spacing.lg),
            ),
          );
        },
      ),
    );
  }
}

/// The card a section sits in.
///
/// `GlobalContainer`, where it was a hand-rolled `Container` with its
/// own fill, corner and border — and its own header row, which is what
/// every picker already draws from its localized `PickerOptions`.
class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => GlobalContainer(child: child);
}

/// The presets and the slider together — the one section that is two
/// controls rather than one.
class _FontSize extends StatelessWidget {
  const _FontSize();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const FontScalePicker(
        options: PickerOptions(variant: PickerVariant.pillRow),
        showPreview: false,
      ),
      SizedBox(height: context.spacing.sm),
      const FontScaleSlider(),
    ],
  );
}

/// Single-column scrollable layout — used on compact + medium buckets
/// where a side-by-side split would make each section too narrow.
class _SingleColumn extends StatelessWidget {
  const _SingleColumn({required this.sections, required this.gap});

  final List<Widget> sections;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: sections.length,
      separatorBuilder: (_, _) => SizedBox(height: gap),
      itemBuilder: (_, i) => sections[i],
    );
  }
}

/// Two-column staggered layout — sections distributed by index parity
/// so the columns stay balanced even with varying section heights.
class _TwoColumn extends StatelessWidget {
  const _TwoColumn({required this.sections, required this.gap});

  final List<Widget> sections;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final left = <Widget>[];
    final right = <Widget>[];
    for (var i = 0; i < sections.length; i++) {
      (i.isEven ? left : right).add(sections[i]);
    }
    return GlobalScrollable(
      padding: EdgeInsets.zero,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _Column(gap: gap, children: left),
          ),
          SizedBox(width: gap),
          Expanded(
            child: _Column(gap: gap, children: right),
          ),
        ],
      ),
    );
  }
}

class _Column extends StatelessWidget {
  const _Column({required this.gap, required this.children});

  final double gap;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) SizedBox(height: gap),
          children[i],
        ],
      ],
    );
  }
}
