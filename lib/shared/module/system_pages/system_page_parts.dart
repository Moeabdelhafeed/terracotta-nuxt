import 'package:flutter/material.dart';

import '../../../core/animations/animation_presets.dart';
import '../../../core/tokens/extensions.dart';
import '../app_bar/global_app_bar.dart';
import '../preferences_pickers/preferences_pickers.dart';

/// Shared furniture for the system pages (404 / coming-soon / error).
///
/// These were private near-duplicates on each page and had already
/// drifted apart (badge gradients at 0.20 vs 0.18 alpha). One copy keeps
/// the family visually identical.

/// The app bar every system page wears.
///
/// Not a styling shortcut — a RULE. A system page can be the first
/// screen someone ever sees: a dead deep link opens the 404, a failed
/// boot opens the error page, a pre-launch build opens coming-soon. In
/// all three the user has not reached settings yet, so the bar has to
/// offer language and theme itself or they are stuck with whatever the
/// device guessed.
///
/// The three pages carried that rule as an identical three-line literal
/// with the reasoning written down on only one of them. A fourth page
/// would have copied the shape and lost the reason.
///
/// `showBack` is deliberately not passed: [GlobalAppBar] already drops
/// the leading widget when the route cannot pop, so
/// `showBack: Navigator.of(context).canPop()` — which all three pages
/// wrote — said exactly what the default already does.
class SystemPageAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SystemPageAppBar({required this.title, super.key});

  final String title;

  @override
  Size get preferredSize => GlobalAppBar(title: title).preferredSize;

  @override
  Widget build(BuildContext context) {
    return GlobalAppBar(
      title: title,
      actions: const [QuickPreferenceActions()],
    );
  }
}

/// Large tinted glyph plate that heads every system page.
///
/// Purely decorative: the heading underneath always states the same
/// thing in words, so the plate is hidden from the semantics tree.
class SystemPageBadge extends StatelessWidget {
  const SystemPageBadge({required this.icon, required this.color, super.key});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final size = context.iconSizes.xxl * 2;
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.20),
              color.withValues(alpha: 0.06),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(context.radii.xl),
        ),
        child: Icon(icon, size: context.iconSizes.xxl, color: color),
      ),
    );
  }
}

/// One-shot fade + rise so a system page arrives instead of snapping in.
///
/// Pass `enabled: !MediaQuery.disableAnimationsOf(context)` — under
/// reduced motion the child is returned untouched.
class SystemPageEntrance extends StatelessWidget {
  const SystemPageEntrance({
    required this.child,
    required this.enabled,
    super.key,
  });

  final Widget child;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppDurations.deliberate,
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, (1 - t) * 16),
          child: child,
        ),
      ),
      child: child,
    );
  }
}
