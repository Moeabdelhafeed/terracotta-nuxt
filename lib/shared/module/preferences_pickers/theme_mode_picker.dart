import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/localization/strings/preferences_strings.dart';
import '../../../core/theme/reveal_theme_switcher.dart';
import '../../../data/blocs/preferences/preferences_cubit.dart';
import '../../../data/blocs/preferences/preferences_state.dart';
import 'picker_item.dart';
import 'picker_options.dart';
import 'picker_shell.dart';

/// Embeddable theme mode picker. Drop anywhere in the tree — reads
/// + writes the global `PreferencesCubit` directly.
///
/// ```dart
/// ThemeModePicker()                                       // list
/// ThemeModePicker(options: PickerOptions(variant: PickerVariant.pillRow))
/// ThemeModePicker(options: PickerOptions(variant: PickerVariant.segmented))
/// ```
class ThemeModePicker extends StatefulWidget {
  const ThemeModePicker({
    this.options,
    this.style = const PickerStyle(),
    this.revealOnChange = true,
    super.key,
  });

  /// Whether the change rides the circular reveal.
  ///
  /// The quick action in the app bar has always done this; the PICKER
  /// set the mode outright, so the same change animated from one
  /// control and hard-cut from the other. Off for a picker whose
  /// surface is about to be torn down anyway, or one that is not on
  /// screen when it fires.
  final bool revealOnChange;

  static PickerOptions get _defaults => PickerOptions(
    title: PreferencesStrings.themeTitle,
    subtitle: PreferencesStrings.themeSubtitle,
    icon: Icons.brightness_6_outlined,
  );

  /// `null` renders the localized defaults. What a caller DOES set is
  /// laid over them, so asking for a variant keeps the heading.
  final PickerOptions? options;

  /// How the picker LOOKS — spacing, whether rows are ruled. The
  /// controls it draws carry their own bags; this one is thin.
  final PickerStyle style;

  static List<PickerItem<ThemeMode>> get _items => [
    PickerItem<ThemeMode>(
      value: ThemeMode.light,
      label: PreferencesStrings.themeLight,
      icon: Icons.light_mode_outlined,
    ),
    PickerItem<ThemeMode>(
      value: ThemeMode.dark,
      label: PreferencesStrings.themeDark,
      icon: Icons.dark_mode_outlined,
    ),
    PickerItem<ThemeMode>(
      value: ThemeMode.system,
      label: PreferencesStrings.themeSystem,
      icon: Icons.brightness_auto_outlined,
    ),
  ];

  @override
  State<ThemeModePicker> createState() => _ThemeModePickerState();
}

class _ThemeModePickerState extends State<ThemeModePicker> {
  /// Where the reveal grows from: the middle of the picker itself.
  ///
  /// The app-bar button can use its own centre because it IS the
  /// control; a list of three rows has no single point, and the
  /// picker's middle is the honest answer — the reader's eye is on it.
  Offset _origin() {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return Offset.zero;
    return box.localToGlobal(box.size.center(Offset.zero));
  }

  /// True when [mode] will paint DARK, resolving `system` through the
  /// platform — the same question the quick action asks.
  bool _isDark(BuildContext context, ThemeMode mode) => switch (mode) {
    ThemeMode.dark => true,
    ThemeMode.light => false,
    ThemeMode.system =>
      MediaQuery.platformBrightnessOf(context) == Brightness.dark,
  };

  void _apply(ThemeMode next) {
    final cubit = context.read<PreferencesCubit>();
    final wasDark = _isDark(context, cubit.state.themeMode);
    final willBeDark = _isDark(context, next);

    // Nothing to reveal when the painted brightness does not change —
    // light → system on a light phone is a preference change with no
    // visible one, and a 600ms wipe over an identical screen reads as
    // a stutter.
    if (!widget.revealOnChange ||
        wasDark == willBeDark ||
        RevealThemeSwitcher.isAnimating(context)) {
      cubit.setThemeMode(next);
      return;
    }
    // The reader's OWN reveal preference, not the default circle. The
    // settings page has always read these two; the picker did not, so
    // the same change animated one way from one control and another
    // way from the other.
    final strategy = RevealStrategy.fromKey(cubit.state.revealShapeKey);
    final stored = strategy.resolveDirection(
      RevealDirection.fromName(cubit.state.revealDirectionName),
    );
    RevealThemeSwitcher.reveal(
      context,
      origin: _origin(),
      strategy: strategy,
      // A CIRCLE gets the reversible affordance — it grows out of the
      // picker going dark and shrinks back into it returning to light.
      // Every other shape keeps the direction the reader picked, since
      // choosing one is what that setting is for.
      direction: strategy.key == 'circle'
          ? (willBeDark ? RevealDirection.expand : RevealDirection.collapse)
          : stored,
      action: () => cubit.setThemeMode(next),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PreferencesCubit, PreferencesState>(
      // The LANGUAGE is in the condition too, and has to be: every
      // label this builds comes from `PreferencesStrings`, so a
      // locale change rewrites all of them — and a `buildWhen` that
      // only watched its own field filtered that rebuild out. The
      // options stayed in the old language until something unrelated
      // moved, or the app was hot-reloaded.
      buildWhen: (a, b) =>
          a.themeMode != b.themeMode || a.language.locale != b.language.locale,
      builder: (context, prefs) {
        return PickerShell<ThemeMode>(
          items: ThemeModePicker._items,
          value: prefs.themeMode,
          onChanged: _apply,
          options: (widget.options ?? const PickerOptions()).mergedOver(
            ThemeModePicker._defaults,
          ),
          style: widget.style,
        );
      },
    );
  }
}
