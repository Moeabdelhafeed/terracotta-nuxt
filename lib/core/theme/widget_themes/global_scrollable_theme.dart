import '../../../shared/module/scrollable/global_scrollable.dart';
import '../../tokens/app_tokens.dart';

/// Project-tuned defaults for the scroll shell.
///
/// The app-wide rebrand hook: every page body, every list and every
/// grid resolves its edge fade, its progress strip and its way back to
/// the top through here.
///
/// It also carries the scroll-in bag, which is how a house sets the
/// rhythm of every list and grid entrance at once.
///
/// No colours: the progress strip and the buttons resolve from
/// `context.primaryColors` at build time, so they track role,
/// brightness and saturation. The fade's `scrim` takes the page
/// colour and its `innerShadow` the palette scrim — both used to be
/// `Theme.of(context).colorScheme.surface` and a raw `Colors.black`.
class MyGlobalScrollableTheme {
  MyGlobalScrollableTheme._();

  static GlobalScrollableTheme build({required AppTokens tokens}) =>
      GlobalScrollableTheme(
        style: ScrollableStyle(
          // How far a floating button sits off the corner is a
          // spacing decision like any other, so it grows with the
          // window rather than staying at 12 forever.
          fabMargin: tokens.spacing.md,
          progressThickness: ScrollableDefaults.progressThickness,
        ),
        // How a row ARRIVES is a house decision — the list and the
        // grid each carried their own copy of these numbers, so a
        // house that wanted a calmer entrance had to say so at every
        // call site. `animation` is deliberately left unset: it is the
        // switch, and a theme must not turn an entrance on for a list
        // that never asked for one.
        scrollInStyle: const ScrollInStyle(
          duration: ScrollInDefaults.duration,
          stagger: ScrollInDefaults.stagger,
        ),
      );
}
