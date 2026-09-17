import 'package:flutter/material.dart';

import '../../../../core/flavor/flavor_config.dart';

/// The look every piece of debug chrome shares.
///
/// The pill got here first: a near-black capsule with a thin
/// flavour-tinted stroke and a soft drop shadow, white content inside.
/// It reads as "this is the harness, not the app" at a glance, and it
/// does that WITHOUT touching the app's palette — which matters, because
/// debug chrome has to stay legible over whatever the app happens to be
/// painting, including a half-finished theme.
///
/// The widget inspector's own buttons did not follow it. They were a
/// Material `FloatingActionButton` in `colorScheme.primary` and two
/// `GlobalIconButton`s reading `Theme.of(context).colorScheme` — app
/// theming, on the one surface that is supposed to sit outside it, so a
/// purple FAB landed next to a black pill and neither looked deliberate.
///
/// These are the tokens, in one place, so the two cannot drift apart
/// again.
abstract final class DebugChrome {
  /// Capsule fill. Deliberately translucent: chrome that sits over the
  /// app should let a little of it through, so it never reads as a hole
  /// punched in the page.
  static const Color surface = Color(0xC7000000);

  /// How strongly the flavour tint shows in the stroke at rest.
  static const double strokeOpacity = 0.6;

  /// Everything inside a capsule.
  static const Color foreground = Color(0xFFFFFFFF);

  /// The pill's own height, and the diameter of a round button, so a
  /// button next to the pill matches it.
  static const double height = 28.0;

  /// Round buttons stand a little taller than the pill — they are the
  /// touch targets, and 28 is under any reasonable minimum.
  static const double buttonSize = 40.0;

  static const List<BoxShadow> shadow = [
    BoxShadow(color: Color(0x59000000), blurRadius: 8, offset: Offset(0, 2)),
  ];

  /// The gap between stacked buttons.
  static const double gap = 8.0;

  /// What every stroke is tinted with, so dev / staging / uat / prod
  /// stay tellable apart on the one surface that exists to say where
  /// you are.
  ///
  /// `maybeInstance`, NOT `instance`. Debug chrome renders over a
  /// half-started app by definition — the widget inspector can be turned
  /// on before `bootstrap` has set the flavour, and the boot-error
  /// screen runs when bootstrap did not finish at all. `instance` throws
  /// there, and a piece of chrome that crashes the frame it was meant to
  /// help you debug is worse than one with no tint.
  static Color get accent =>
      FlavorConfig.maybeInstance?.flavor.bannerColor ?? _fallbackAccent;

  /// Neutral, and deliberately not a flavour colour: no flavour is the
  /// honest answer when there is no flavour.
  static const Color _fallbackAccent = Color(0xFF9E9E9E);
}

/// A round button in the debug chrome's own language.
///
/// [selected] is for a TOGGLE: on, the flavour colour fills the capsule
/// instead of merely edging it, which is a state change you can see from
/// the corner of your eye. The framework's inspector toggle flipped an
/// `isSelected` flag whose only effect was a faint tint, and that reads
/// as a button that did not react.
///
/// No `Tooltip` anywhere. These render ABOVE the `Navigator`, so there is
/// no `Overlay` ancestor and `Tooltip` asserts. The label goes to
/// `Semantics`, which is what the framework's own buttons do.
class DebugChromeButton extends StatelessWidget {
  const DebugChromeButton({
    required this.icon,
    required this.onPressed,
    required this.semanticsLabel,
    super.key,
    this.selected,
    this.size,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String semanticsLabel;

  /// Null is a plain button; true / false is a toggle, and reports
  /// itself as one to a screen reader.
  final bool? selected;

  final double? size;

  @override
  Widget build(BuildContext context) {
    final accent = DebugChrome.accent;
    final on = selected ?? false;
    final diameter = size ?? DebugChrome.buttonSize;

    return Semantics(
      label: semanticsLabel,
      button: true,
      toggled: selected,
      child: SizedBox(
        width: diameter,
        height: diameter,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: on ? accent : DebugChrome.surface,
            shape: BoxShape.circle,
            border: Border.all(
              color: accent.withValues(
                alpha: on ? 1 : DebugChrome.strokeOpacity,
              ),
            ),
            boxShadow: DebugChrome.shadow,
          ),
          // Transparent, so the capsule's own fill stays the fill and
          // the ink still lands on top of it.
          child: Material(
            type: MaterialType.transparency,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onPressed,
              customBorder: const CircleBorder(),
              child: Center(
                child: Icon(
                  icon,
                  size: diameter * 0.5,
                  color: DebugChrome.foreground,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
