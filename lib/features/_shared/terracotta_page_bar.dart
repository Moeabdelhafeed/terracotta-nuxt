import 'package:flutter/material.dart';

import '../../core/extensions/context_extensions.dart';
import '../../core/extensions/theme_colors_extension.dart';
import '../../shared/module/app_bar/global_app_bar.dart';
import '../../shared/module/buttons/button_models.dart';
import '../../shared/module/preferences_pickers/quick_preference_actions.dart';
import '../shell/widgets/terracotta_app_bar.dart';
import 'page_bar_title.dart';
import 'shared_hero.dart';
import 'terracotta_bell_action.dart';
import 'terracotta_cart_action.dart';

/// The bar every SECONDARY page wears — the ones reached from a tab
/// rather than being one.
///
/// `GlobalAppBar` with the app's own title treatment and the language
/// toggle, in one widget instead of at each call site: the title is
/// against the reading START and bold, the same `titleMedium` w700 the
/// tab bar uses when it swaps its greeting for a name, and the toggle
/// wears the same pill as the tabs' own actions.
///
/// The title shows from the top of the page. Only a TAB bar swaps its
/// title in as the page moves, because only a tab puts something else
/// in that place to begin with.
class TerracottaPageBar extends StatelessWidget implements PreferredSizeWidget {
  const TerracottaPageBar({
    required this.title,
    this.actions = const [],
    this.bottom,
    this.cartKey,
    this.pinned = true,
    this.showBack = true,
    this.showShopActions = true,
    super.key,
  });

  final String title;

  /// Where a piece added on this page FLIES to.
  ///
  /// The product detail page needs the cart button it can animate into,
  /// and used to hand-roll the whole trailing block to get one — which
  /// is how its title ended up on the module's default style instead of
  /// the house one. The key belongs to the shared action; nothing else
  /// about the bar changes.
  final GlobalKey? cartKey;

  /// Whether the bar stays put while the page scrolls.
  ///
  /// **TRUE by default, and that is the app's rule.** Only the two TAB
  /// pages that open on something to look at — home and the account —
  /// let their bar retreat, because there the bar is chrome over a
  /// page the reader is scrolling through. Everywhere else it carries
  /// the way BACK, and often a control as well: a bar that retreats
  /// takes both away exactly when the reader has scrolled far enough
  /// to want them.
  ///
  /// It used to default to false, so every pushed page hid its own
  /// back button on the way down.
  final bool pinned;

  /// Whether the bell and the basket are carried.
  ///
  /// FALSE on the front desk. Both belong to a CUSTOMER: the bell
  /// opens a customer's notification inbox and the basket a customer's
  /// cart, and a scanner account has neither — its routes are
  /// mutually exclusive with the shop's, so both would answer 403.
  /// Drawing a basket for someone who cannot own one is offering a
  /// door into another app.
  final bool showShopActions;

  /// Whether the chevron is drawn.
  ///
  /// FALSE for a screen that is a root rather than a step — the front
  /// desk, where staff land from sign-in and leaving means signing
  /// out. A back arrow there points at the login screen they just came
  /// through, which is not a place to return to with a live session.
  final bool showBack;

  /// Anything this page adds BEFORE the language toggle, which stays
  /// nearest the edge where the thumb reaches.
  final List<Widget> actions;

  final PreferredSizeWidget? bottom;

  @override
  Widget build(BuildContext context) => GlobalAppBar(
    title: title,
    showBack: showBack,
    // FLOWN, like the title and the trailing controls. See
    // [HeroTag.back] — it is also what decides when the chevron
    // arrives rather than being there.
    wrapBack: (back) => SharedHero(
      tag: HeroTag.back,
      // IN FROM THE START EDGE on the one screen where it does not
      // fly. See [SharedHero.entranceDriftFrom].
      entranceDriftFrom: const Offset(-3.5, 0),
      // And OUT the same way, at the speed of the pop.
      exitsWithRoute: true,
      child: back,
    ),
    // MARQUEE, through `titleWidget`: a workshop's name is the studio's
    // to write and «ورشة صناعة كوبك مع احتفال» does not fit a bar that
    // also holds a back arrow and three actions. `GlobalMarquee` only
    // moves when the content actually overflows, so a short title costs
    // nothing. `title` stays set for the semantics.
    // FLOWN, so a push reads as the title CHANGING rather than one
    // page's words being replaced by another's. Cross-faded because
    // the words are what differ — see [HeroTag.pageTitle].
    titleWidget: SharedHero(
      tag: HeroTag.pageTitle,
      flightShuttleBuilder: pageTitleShuttle,
      child: PageBarTitle(text: title),
    ),
    bottom: bottom,
    style: AppBarStyle(
      // `centerTitle: false` is what makes `start` mean the RIGHT in
      // Arabic — a centred title is not a start-aligned one that
      // happens to be in the middle.
      centerTitle: false,
      hideOnScroll: !pinned,
      titleStyle: context.textTheme.titleMedium?.copyWith(
        color: context.textColors.primary,
        fontWeight: FontWeight.w700,
      ),
    ),
    actions: [
      // ONE GAP, everywhere along the row.
      //
      // The caller's own actions were spread raw while the language
      // button carried a leading [TerracottaAppBar.actionGap] — so the
      // last of them sat further from the language button than from
      // each other, and a row of four pills read as two groups of two.
      // Every pill gets the same gap in front of it.
      for (final action in actions)
        Padding(
          padding: const EdgeInsetsDirectional.only(
            start: TerracottaAppBar.actionGap,
          ),
          child: action,
        ),
      // The three that are on EVERY screen, flown as one.
      //
      // They are the same boxes in the same place on every route, so
      // holding them still while the page travels underneath is what
      // makes a push read as the content changing rather than the whole
      // app sliding. One hero around the row, not three: they move
      // together and a tag each would be three flights doing one job.
      // Language only — the design is light-only, so a theme toggle
      // would offer a brightness nobody drew.
      SharedHero(
        tag: HeroTag.barActions,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.only(
                start: TerracottaAppBar.actionGap,
              ),
              child: QuickPreferenceActions(
                showTheme: false,
                buttonSize: ButtonSize.small,
                buttonBackgroundColor: TerracottaAppBar.plate(context),
                buttonIconColor: TerracottaAppBar.glyph(context),
              ),
            ),
            // The bell and the cart, as every other bar in the app carries
            // them — the three travel together or a screen looks like a
            // different app.
            //
            // EXCEPT where the reader has neither. See [showShopActions].
            if (showShopActions) ...[
              const Padding(
                padding: EdgeInsetsDirectional.only(
                  start: TerracottaAppBar.actionGap,
                ),
                child: TerracottaBellAction(),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.only(
                  start: TerracottaAppBar.actionGap,
                ),
                child: TerracottaCartAction(key: cartKey),
              ),
            ],
          ],
        ),
      ),
    ],
  );

  @override
  Size get preferredSize => Size.fromHeight(
    kToolbarHeight + (bottom?.preferredSize.height ?? 0),
  );
}
