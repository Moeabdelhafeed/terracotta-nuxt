import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/localization/strings/preferences_strings.dart';
import '../../../core/theme/reveal_theme_switcher.dart';
import '../../../data/blocs/preferences/preferences_cubit.dart';
import '../../../data/blocs/preferences/preferences_state.dart';
import 'picker_item.dart';
import 'picker_options.dart';
import 'picker_shell.dart';

/// The SHAPE the theme reveal takes.
///
/// Neither this nor [RevealDirectionPicker] had one: the settings page
/// owned both, in two private `Wrap`s of hand-rolled pills, so the two
/// settings that decide how every other preference animates were the
/// only ones a screen could not offer.
///
/// Picking a shape PREVIEWS it — the reveal runs with the new strategy
/// and changes nothing else. A setting whose whole subject is an
/// animation should show the animation.
class RevealShapePicker extends StatefulWidget {
  const RevealShapePicker({
    this.options,
    this.style = const PickerStyle(),
    this.preview = true,
    super.key,
  });

  final PickerOptions? options;
  final PickerStyle style;

  /// Whether choosing a shape runs it once.
  final bool preview;

  static PickerOptions get _defaults => PickerOptions(
    title: PreferencesStrings.revealShapeTitle,
    subtitle: PreferencesStrings.revealShapeSubtitle,
    icon: Icons.animation_rounded,
  );

  @override
  State<RevealShapePicker> createState() => _RevealShapePickerState();
}

class _RevealShapePickerState extends State<RevealShapePicker> {
  Offset _origin() {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return Offset.zero;
    return box.localToGlobal(box.size.center(Offset.zero));
  }

  void _apply(String key) {
    final cubit = context.read<PreferencesCubit>();
    final strategy = RevealStrategy.fromKey(key);

    // A shape does not understand every direction. Snap the stored one
    // to something this shape supports, or the direction picker beside
    // it would show a selection that is not in its own options.
    final stored = RevealDirection.fromName(cubit.state.revealDirectionName);
    final resolved = strategy.resolveDirection(stored);

    void commit() {
      cubit.setRevealShapeKey(key);
      if (resolved != stored) cubit.setRevealDirectionName(resolved.name);
    }

    if (!widget.preview || RevealThemeSwitcher.isAnimating(context)) {
      commit();
      return;
    }
    // The preview changes nothing but the setting itself — the reveal
    // animates over a screen that comes back identical.
    RevealThemeSwitcher.reveal(
      context,
      origin: _origin(),
      strategy: strategy,
      direction: resolved,
      action: commit,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PreferencesCubit, PreferencesState>(
      buildWhen: (a, b) =>
          a.revealShapeKey != b.revealShapeKey ||
          a.language.locale != b.language.locale,
      builder: (context, prefs) => PickerShell<String>(
        items: [
          for (final s in RevealStrategy.values)
            PickerItem<String>(value: s.key, label: s.label),
        ],
        value: RevealStrategy.fromKey(prefs.revealShapeKey).key,
        onChanged: _apply,
        options: (widget.options ?? const PickerOptions()).mergedOver(
          RevealShapePicker._defaults,
        ),
        style: widget.style,
      ),
    );
  }
}

/// Which way the reveal moves.
///
/// The options are the ones the CURRENT shape understands — a circle
/// expands or collapses and nothing else — so the list changes when
/// the shape does.
class RevealDirectionPicker extends StatefulWidget {
  const RevealDirectionPicker({
    this.options,
    this.style = const PickerStyle(),
    this.preview = true,
    super.key,
  });

  final PickerOptions? options;
  final PickerStyle style;
  final bool preview;

  static PickerOptions get _defaults => PickerOptions(
    title: PreferencesStrings.revealDirectionTitle,
    subtitle: PreferencesStrings.revealDirectionSubtitle,
    icon: Icons.swap_calls_rounded,
  );

  @override
  State<RevealDirectionPicker> createState() => _RevealDirectionPickerState();
}

class _RevealDirectionPickerState extends State<RevealDirectionPicker> {
  Offset _origin() {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return Offset.zero;
    return box.localToGlobal(box.size.center(Offset.zero));
  }

  void _apply(String name, RevealStrategy strategy) {
    final cubit = context.read<PreferencesCubit>();
    void commit() => cubit.setRevealDirectionName(name);

    if (!widget.preview || RevealThemeSwitcher.isAnimating(context)) {
      commit();
      return;
    }
    RevealThemeSwitcher.reveal(
      context,
      origin: _origin(),
      strategy: strategy,
      direction: RevealDirection.fromName(name),
      action: commit,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PreferencesCubit, PreferencesState>(
      buildWhen: (a, b) =>
          a.revealDirectionName != b.revealDirectionName ||
          a.revealShapeKey != b.revealShapeKey ||
          a.language.locale != b.language.locale,
      builder: (context, prefs) {
        final strategy = RevealStrategy.fromKey(prefs.revealShapeKey);
        final selected = strategy.resolveDirection(
          RevealDirection.fromName(prefs.revealDirectionName),
        );
        return PickerShell<String>(
          items: [
            for (final d in strategy.supportedDirections)
              PickerItem<String>(value: d.name, label: d.label),
          ],
          value: selected.name,
          onChanged: (name) => _apply(name, strategy),
          options: (widget.options ?? const PickerOptions()).mergedOver(
            RevealDirectionPicker._defaults,
          ),
          style: widget.style,
        );
      },
    );
  }
}
