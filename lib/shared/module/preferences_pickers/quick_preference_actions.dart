import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/localization/strings/preferences_strings.dart';
import '../../../core/theme/reveal_theme_switcher.dart';
import '../../../data/blocs/preferences/preferences_cubit.dart';
import '../../../data/blocs/preferences/preferences_state.dart';
import '../../../data/models/common/language/language.dart';
import '../../../data/services/languages_service.dart';
import '../buttons/global_icon_button.dart';
import '../dialog/global_dialog.dart';
import 'language_picker.dart';

/// Compact theme + language controls for an `AppBar.actions` slot.
///
/// Built for the system pages (404 / coming-soon / error): those can be
/// the FIRST thing a user sees — a deep link into a dead route, or a
/// crash before they ever reached settings — so the two preferences that
/// make the page readable at all have to be reachable from the page
/// itself.
///
/// - **Theme** is a binary light ↔ dark switch (a `system` preference
///   resolves through the platform first, so the first tap always lands
///   on the visible opposite). The change rides
///   `RevealThemeSwitcher` — a circular clip growing out of the button
///   when going dark and shrinking back into it when returning to light.
///   Deliberately NOT `toggleTheme`: that cycles through `system`, which
///   has no obvious glyph and makes a two-state control feel broken. The
///   full three-way choice stays in settings (`ThemeModePicker`).
/// - **Language** adapts to how many locales the app actually ships:
///   one → the button is hidden entirely, two → a straight toggle, three
///   or more → the full [LanguagePicker] in a dialog.
///
/// Lives in `preferences_pickers/` because, like its siblings, it reads
/// the language catalog from DI — that carve-out is documented in the
/// module README rather than widened to `system_pages/`.
class QuickPreferenceActions extends StatelessWidget {
  const QuickPreferenceActions({
    this.showLanguage = true,
    this.showTheme = true,
    this.buttonBackgroundColor,
    this.buttonIconColor,
    this.buttonSize,
    super.key,
  });

  /// Plate behind each control, for a bar with no surface of its own —
  /// see `AppBarStyle.buttonBackgroundColor`. Null leaves them bare.
  final Color? buttonBackgroundColor;

  /// The button's box, when the ambient default is the wrong size for
  /// where it is being placed — an app bar wants a smaller one than a
  /// settings row.
  final ButtonSize? buttonSize;

  /// The glyph's own colour.
  ///
  /// Separate from [buttonBackgroundColor] because a caller giving the
  /// button a surface almost always has to say what reads on it — the
  /// ambient foreground was picked against the page, not against a
  /// tinted pill.
  final Color? buttonIconColor;

  /// Drop the language control.
  final bool showLanguage;

  /// Drop the theme control.
  ///
  /// For a screen an app deliberately ships in ONE brightness: offering
  /// a toggle there hands the reader a control whose other position
  /// nobody designed.
  final bool showTheme;

  @override
  Widget build(BuildContext context) {
    // These ride on the SYSTEM pages — one of which is the crash page,
    // reachable when bootstrap died before DI or the root providers came
    // up. A missing dependency must degrade to "no buttons", never to a
    // second exception thrown by the screen that reports the first one.
    final cubit = _maybePreferences(context);
    if (cubit == null) return const SizedBox.shrink();

    final languages = getIt.isRegistered<LanguagesService>()
        ? getIt<LanguagesService>().languages
        : const <Language>[];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showLanguage && languages.length > 1)
          _LanguageAction(
            languages: languages,
            backgroundColor: buttonBackgroundColor,
            iconColor: buttonIconColor,
            size: buttonSize,
          ),
        if (showTheme)
          _ThemeAction(
            backgroundColor: buttonBackgroundColor,
            iconColor: buttonIconColor,
            size: buttonSize,
          ),
      ],
    );
  }

  static PreferencesCubit? _maybePreferences(BuildContext context) {
    try {
      return BlocProvider.of<PreferencesCubit>(context);
      // BlocProvider.of rewrites provider's own miss as a FlutterError, so
      // that is the only way "no provider" can surface. Catching an Error
      // is deliberate here and narrowly scoped: these actions sit on the
      // CRASH page, which must stay renderable when the app never fully
      // came up — and it keeps the system pages mountable in tests without
      // standing up hydrated storage just to draw an app bar.
      // ignore: avoid_catching_errors
    } on FlutterError {
      return null;
    }
  }
}

class _ThemeAction extends StatefulWidget {
  const _ThemeAction({this.backgroundColor, this.iconColor, this.size});

  final Color? backgroundColor;
  final Color? iconColor;
  final ButtonSize? size;

  @override
  State<_ThemeAction> createState() => _ThemeActionState();
}

class _ThemeActionState extends State<_ThemeAction> {
  /// Anchors the reveal: the circle has to grow out of the BUTTON, so we
  /// need its centre in global coordinates at tap time.
  final GlobalKey _anchorKey = GlobalKey();

  Offset _origin() {
    final box = _anchorKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) {
      // Fall back to the screen centre rather than skipping the reveal.
      final size = MediaQuery.sizeOf(context);
      return Offset(size.width / 2, size.height / 2);
    }
    return box.localToGlobal(box.size.center(Offset.zero));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PreferencesCubit, PreferencesState>(
      buildWhen: (a, b) =>
          a.themeMode != b.themeMode || a.language.locale != b.language.locale,
      builder: (context, prefs) {
        // Binary switch: `system` resolves through the platform so the
        // first tap always lands on the visible opposite.
        final isDark = switch (prefs.themeMode) {
          ThemeMode.dark => true,
          ThemeMode.light => false,
          ThemeMode.system =>
            MediaQuery.platformBrightnessOf(context) == Brightness.dark,
        };
        // Name + draw the DESTINATION, matching the language toggle: on a
        // two-state switch what matters is where the tap lands.
        final label = isDark
            ? PreferencesStrings.themeLight
            : PreferencesStrings.themeDark;

        return GlobalIconButton(
          key: _anchorKey,
          iconData: isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
          tooltip: label,
          semanticLabel: label,
          style: ButtonStateStyle(backgroundColor: widget.backgroundColor),
          onPressed: () {
            // Ignore taps mid-reveal: re-entering would capture a
            // snapshot of the outgoing animation.
            if (RevealThemeSwitcher.isAnimating(context)) return;
            final cubit = context.read<PreferencesCubit>();
            RevealThemeSwitcher.reveal(
              context,
              origin: _origin(),
              // Going dark grows out of the button; coming back to light
              // shrinks into it, so the motion reads as reversible.
              direction: isDark
                  ? RevealDirection.collapse
                  : RevealDirection.expand,
              action: () => cubit.setThemeMode(
                isDark ? ThemeMode.light : ThemeMode.dark,
              ),
            );
          },
        );
      },
    );
  }
}

class _LanguageAction extends StatelessWidget {
  const _LanguageAction({
    required this.languages,
    this.backgroundColor,
    this.iconColor,
    this.size,
  });

  final List<Language> languages;
  final Color? backgroundColor;
  final Color? iconColor;
  final ButtonSize? size;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PreferencesCubit, PreferencesState>(
      buildWhen: (a, b) => a.language.locale != b.language.locale,
      builder: (context, prefs) {
        final isPair = languages.length == 2;
        final other = isPair
            ? languages.firstWhere(
                (l) => l.locale != prefs.language.locale,
                orElse: () => prefs.language,
              )
            : null;
        // With exactly two locales a picker is ceremony for a coin flip:
        // show where the tap LANDS, not a generic globe.
        final label = isPair
            ? (other!.name ?? other.locale.toUpperCase())
            : PreferencesStrings.languageTitle;

        return GlobalIconButton(
          iconData: Icons.translate_rounded,
          tooltip: label,
          semanticLabel: label,
          size: size,
          style: ButtonStateStyle(
            backgroundColor: backgroundColor,
            foregroundColor: iconColor,
          ),
          onPressed: () {
            if (isPair) {
              context.read<PreferencesCubit>().setLanguage(other!);
            } else {
              _openPicker(context);
            }
          },
        );
      },
    );
  }

  Future<void> _openPicker(BuildContext context) {
    // The cubit is looked up here and re-provided inside the dialog: the
    // dialog mounts under the root navigator, off this page's subtree.
    final cubit = context.read<PreferencesCubit>();
    return GlobalDialog.builder<void>(
      context,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: const LanguagePicker(),
      ),
    );
  }
}
