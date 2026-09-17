import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/animations/animation_presets.dart';
import '../../../core/constants/colors/text_colors.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/theme/widget_themes/global_app_bar_theme.dart';
import '../../../shared/module/app_bar/global_app_bar.dart';
import '../../../shared/module/buttons/global_icon_button.dart';
import '../../../shared/module/in_page_hero/global_in_page_hero.dart';
import '../../../shared/module/preferences_pickers/quick_preference_actions.dart';
import '../../_shared/page_bar_title.dart';
import '../../_shared/shared_hero.dart';
import '../../_shared/terracotta_bell_action.dart';
import '../../_shared/terracotta_cart_action.dart';

/// The shell's app bar: it shows one thing at the top of a page and the
/// page's NAME once that page has moved.
///
/// Home puts its greeting at the top: a welcome that stayed pinned to a
/// page scrolled halfway down would stop being one. The gallery puts
/// nothing there, because its own heading is drawn into the page and a
/// second copy in the bar would be the same words twice.
///
/// The bar itself keeps its place either way — the bell and the
/// language toggle are wanted wherever the reader has got to — and only
/// the WORDS change.
///
/// ## Why it watches a controller rather than hiding itself
///
/// `HideOnScrollAppBar` exists and does something different: it retreats
/// the whole bar, actions included. Here the bar must stay and its title
/// must swap, so this listens to the same scroll and drives one boolean.
class TerracottaAppBar extends StatefulWidget implements PreferredSizeWidget {
  const TerracottaAppBar({
    required this.controller,
    required this.collapsedTitle,
    this.expanded,
    this.unread,
    this.transparent = false,
    this.collapsedAction,
    this.forceExpanded = false,
    this.hideOnScroll = true,
    this.alwaysShowTitle = false,
    this.titleMorph,
    this.actionMorph,
    super.key,
  });

  /// Whether the bar RETREATS as the page scrolls down.
  ///
  /// True by default, which is the module's own behaviour: on a short
  /// window the axis the bar costs is the one there is least of. The
  /// browse tabs turn it off — their headers are drawn artwork the bar
  /// floats over, and a bar that comes and goes over a picture reads
  /// as the picture flickering.
  final bool hideOnScroll;

  /// The page's own scroll position. Passed in rather than found,
  /// because the bar is built by the `Scaffold` and the body it must
  /// watch is built after it.
  final ScrollController controller;

  /// The words that arrive once the page has moved — the name of where
  /// you are.
  final String collapsedTitle;

  /// What stands in their place at the TOP of the page.
  ///
  /// Home puts its greeting here. The gallery puts nothing: its own
  /// heading is drawn into the page below, so a second copy in the bar
  /// would be the same words twice until the first scrolled away.
  final Widget? expanded;

  /// No surface, for a page whose own artwork runs up behind the bar.
  final bool transparent;

  /// A control shown in the actions row ONLY while the bar is
  /// collapsed — the shop's search glyph, which stands in for the field
  /// that scrolled away.
  final Widget? collapsedAction;

  /// Show [expanded] whatever the scroll offset says.
  ///
  /// The shop's search reopens from its collapsed glyph, and it has to
  /// win over the offset: the reader is at the bottom of a long page
  /// when they tap it, and the bar would otherwise swap straight back
  /// to the title under their thumb.
  final bool forceExpanded;

  /// Show the title from the TOP of the page rather than only once it
  /// has moved.
  ///
  /// The swap exists because home puts its greeting where the title
  /// goes and needs the name of the page back when that scrolls away.
  /// A page with nothing in [expanded] has no such thing to give way
  /// to — it just showed an empty bar until the reader scrolled, which
  /// is where the account tab left its own name.
  final bool alwaysShowTitle;

  /// Flies this bar's title in FROM the page's own heading as the page
  /// collapses, instead of swapping one for the other.
  ///
  /// Three tabs open on a big centred heading and then put a small
  /// start-aligned one up here, and those were two unrelated events:
  /// the reader's title scrolled away, and a different title appeared
  /// above it. Given a controller they are one thing moving — the
  /// page's heading is endpoint 0, this is endpoint 1.
  ///
  /// `InPageHero`, not `Hero`: nothing is PUSHED when a page scrolls,
  /// so the framework's flight — which watches the navigator — has
  /// nothing to fire on. See `shared/module/in_page_hero`.
  final InPageHeroController? titleMorph;

  /// The same for [collapsedAction] and whatever it stands in for: the
  /// shop's search FIELD is endpoint 0, the glyph up here is 1.
  final InPageHeroController? actionMorph;

  /// The tags those two controllers fly under.
  static const titleMorphTag = 'bar-title-morph';
  static const actionMorphTag = 'bar-action-morph';

  /// Unread notifications. From `GET /api/notifications`' own count —
  /// never from counting rows, which paginate.
  ///
  /// **NULL means the LIVE count**, which is what every screen in the
  /// app wants. It used to default to `0`, and since nothing ever
  /// passed one the tab bars handed the bell a fixed zero — so the
  /// badge was absent on the home screen however full the inbox was,
  /// while the pushed pages' bar, which passes nothing, showed it.
  /// A number here is for a test or a preview.
  final int? unread;

  /// The pill behind each action, and the glyph on it.
  ///
  /// Named here rather than taken from the palette because the design
  /// gives this pair explicitly: the cream is lighter than the page's
  /// own container colour, and the brown is the app's chrome rather
  /// than the ambient icon colour, which was picked to read on the page
  /// and not on a tinted pill.
  /// The action pills' fill and glyph. Public because a page can add
  /// an action of its own — the shop's search glyph — and it has to be
  /// the same pill as the bell beside it.
  static const buttonBackground = MyGlobalAppBarTheme.lightButtonPlate;

  /// The same pair, resolved for the theme on screen.
  ///
  /// **The two constants above are LIGHT-ONLY**, and they were used
  /// everywhere: a cream plate and a dark-brown glyph, painted onto a
  /// dark app bar, put a bright blob on every screen in dark mode. The
  /// cream is the design's, so it stays the light answer; dark takes
  /// the ground one step up and the page's own ink, which is the same
  /// relationship — a plate slightly lifted off the bar, with the
  /// ambient glyph on it.
  static Color plate(BuildContext context) => context.isDarkMode
      ? context.backgroundColors.container
      : buttonBackground;

  static Color glyph(BuildContext context) =>
      context.isDarkMode ? context.textColors.primary : buttonGlyph;

  /// Breathing room BEFORE each action, so two of them do not touch.
  ///
  /// Only at the start: the module owns the inset off the bar's edge
  /// (`AppBarDefaults.actionEndPad`), and padding both sides added to
  /// it — which is how the tab bar came to sit 8dp out while a plain
  /// bar's back arrow sat at 4.
  ///
  /// DERIVED, not chosen. Every action paints 40 inside a 48-point
  /// touch box, so each already carries [_touchSlack] of invisible
  /// space on both sides. A gap equal to the edge inset therefore
  /// PAINTS as twice it where two buttons meet — measured at 16 between
  /// the plates against 12 at the edge, which is the crowding this
  /// subtracts. What is left is one edge inset's worth of gap wherever
  /// you look.
  ///
  /// Public for the same reason the two colours are: a page adding an
  /// action of its own has to space it exactly as the bar does.
  static const actionGap = AppBarDefaults.actionEndPad - _touchSlack;

  /// Half the difference between the painted plate and the touch box
  /// it is centred in — the space an action brings with it.
  static const _touchSlack = (kMinInteractiveDimension - _actionPaintSize) / 2;

  /// What a `ButtonSize.small` icon button actually paints.
  static const _actionPaintSize = 40.0;
  static const buttonGlyph = Color(0xFF81341A);

  /// How far the page moves before the greeting gives way.
  ///
  /// Deliberately short: this should read as a response to scrolling
  /// rather than a threshold the reader has to hunt for. Anything under
  /// a line of text and it flickers on the smallest nudge, which is
  /// what the [_hysteresis] below also guards.
  static const collapseAt = 24.0;

  /// The gap between collapsing and expanding again.
  ///
  /// Without it a position resting exactly on the threshold flips the
  /// title on every pixel of overscroll wobble.
  static const _hysteresis = 8.0;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  State<TerracottaAppBar> createState() => _TerracottaAppBarState();
}

class _TerracottaAppBarState extends State<TerracottaAppBar> {
  bool _collapsed = false;

  /// Whether the bar is showing its TITLE right now.
  ///
  /// `forceExpanded` overrides the scroll offset — see the field.
  bool get _showingTitle =>
      widget.alwaysShowTitle || (_collapsed && !widget.forceExpanded);

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onScroll);
    // A flight requested MID-AIR is IGNORED by the module, not queued —
    // interrupting one leaves the source collapsed and the target
    // expanded with nothing between them. So the ask has to be made
    // again when the air clears, and the controller's own notification
    // is the only thing that knows when that is. Without this, a tap
    // on the shop's search glyph during the collapse flight was
    // dropped and the field never came back.
    widget.titleMorph?.addListener(_syncMorph);
    widget.actionMorph?.addListener(_syncMorph);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onScroll);
    widget.titleMorph?.removeListener(_syncMorph);
    widget.actionMorph?.removeListener(_syncMorph);
    super.dispose();
  }

  void _onScroll() {
    if (!widget.controller.hasClients) return;
    final offset = widget.controller.offset;
    final next = _collapsed
        ? offset > TerracottaAppBar.collapseAt - TerracottaAppBar._hysteresis
        : offset > TerracottaAppBar.collapseAt;
    if (next == _collapsed) return;
    setState(() => _collapsed = next);
  }

  /// Sends both morphs to whichever end the bar is now showing.
  ///
  /// Driven off `_showingTitle` rather than off the scroll offset,
  /// because the offset is not the only thing that opens the bar back
  /// up: tapping the shop's search glyph does too (`forceExpanded`),
  /// and a morph that only listened to scrolling left the field hidden
  /// behind a glyph the reader had just asked to replace.
  ///
  /// AFTER the frame, because the flight measures both ends and one of
  /// them may only have been built by the rebuild that called this —
  /// asked for in the same breath the module finds no endpoint and
  /// aborts rather than guessing.
  void _syncMorph() {
    final title = widget.titleMorph;
    final action = widget.actionMorph;
    if (title == null && action == null) return;

    final index = _showingTitle ? 1 : 0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (title != null && title.activeIndex != index) {
        unawaited(title.flyTo(index, tag: TerracottaAppBar.titleMorphTag));
      }
      if (action != null && action.activeIndex != index) {
        unawaited(action.flyTo(index, tag: TerracottaAppBar.actionMorphTag));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final text = context.textColors;
    final surface = context.backgroundColors.scaffoldBackground;

    // Every build, because anything that changes what the bar is
    // showing has to move the flights with it. It is a no-op unless
    // the two disagree.
    _syncMorph();

    // The background ARRIVES with the title, rather than being there
    // or not.
    //
    // A transparent bar over a drawn header is right at the top of the
    // page and wrong the moment anything scrolls under it: the words
    // ride over the artwork and neither is legible. Snapping the
    // surface on at the collapse point reads as a flash, so it fades
    // across the same duration and curve the title switch uses — one
    // change, not two.
    return TweenAnimationBuilder<double>(
      duration: AppDurations.normal,
      curve: Curves.easeOutCubic,
      tween: Tween<double>(end: _collapsed ? 1 : 0),
      builder: (context, t, _) => _bar(context, text, surface, t),
    );
  }

  /// The title slot on a page whose heading FLIES into the bar.
  ///
  /// Both endpoints have to be laid out for a flight to have two rects,
  /// so the title is built here whether it is showing or not —
  /// `InPageHero` collapses the inactive one — and the expanded
  /// content (the shop's search field) sits in the same slot as its
  /// own hero's endpoint. Only one of them paints at a time, so a
  /// `Stack` is the arrangement rather than a switcher: there is
  /// nothing to switch, and the module owns the change.
  Widget _morphSlot(BuildContext context, TextColors text) => Stack(
    alignment: AlignmentDirectional.centerStart,
    children: [
      // The expanded content comes and goes as it always did — only
      // the TITLE has to stay laid out, because it is one end of a
      // flight and a flight needs a rect at both.
      //
      // `actionMorph` exists for a field that flies into its glyph,
      // and this line is what would have to change for it: both ends
      // laid out, the module owning which is painted. See
      // `ShopHomePage._openSearch` for why that is not enough.
      if (widget.expanded case final expanded? when !_showingTitle) expanded,
      InPageHero(
        tag: TerracottaAppBar.titleMorphTag,
        controller: widget.titleMorph!,
        index: 1,
        // The ROUTE hero lives in here, so it can appear and disappear
        // with `_showingTitle` without taking the endpoint with it.
        child: _titleHero(
          child: PageBarTitle(
            text: widget.collapsedTitle,
            style: context.textTheme.titleMedium?.copyWith(
              color: text.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    ],
  );

  /// The title slot, flown when there is a title in it. See `_bar`.
  Widget _titleHero({required Widget child}) => _showingTitle
      ? SharedHero(
          tag: HeroTag.pageTitle,
          flightShuttleBuilder: pageTitleShuttle,
          child: child,
        )
      : child;

  /// [t] is how far the surface has faded in: 0 at the top of the
  /// page, 1 once the title has taken over.
  Widget _bar(BuildContext context, TextColors text, Color surface, double t) {
    return GlobalAppBar(
      // The first tab of the shell either way. There is nowhere behind
      // it, so no back arrow.
      showBack: false,
      variant: widget.transparent
          ? AppBarVariant.transparent
          : AppBarVariant.standard,
      // FLOWN, like the trailing actions beside it — but ONLY when
      // there is a title in the slot to fly.
      //
      // A push out of a tab used to take the title with it and slide
      // the next page's in from the side, so half the bar travelled
      // and half of it — the pill, the bell, the cart — held still.
      // Now the whole bar holds still and only the WORDS change, which
      // is the thing that actually changed. See [HeroTag.pageTitle].
      //
      // The gallery and «ورشاتنا» put NOTHING in that slot until the
      // reader scrolls, and there are only two ways to fly out of an
      // empty slot: from a 0×0 rect, which scales the next page's
      // title up out of the corner, or from an invisible copy of the
      // title, which is the same words in the tree twice — read out
      // loud by a screen reader, and caught by the gallery's own guard
      // that the bar says nothing at the top. So it does not fly, and
      // the title arrives with its page as it always did.
      // The morph slot is NOT wrapped by `_titleHero`: that wrapper
      // appears and disappears with `_showingTitle`, and a wrapper
      // appearing above an `InPageHero` endpoint rebuilds it from
      // scratch — which is a whole endpoint replaced in the middle of
      // deciding to fly. The route hero goes INSIDE the endpoint
      // instead, where it can come and go without moving it.
      titleWidget: widget.titleMorph != null
          ? _morphSlot(context, text)
          : _titleHero(
              child: AnimatedSwitcher(
                duration: AppDurations.normal,
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                // `AnimatedSwitcher` stacks the outgoing and incoming children
                // and CENTRES them by default, so the short title appeared
                // centred and slid to the start as the long greeting left —
                // one visible jog on every collapse. Both are pinned to the
                // reading start instead, which is where each of them lives.
                layoutBuilder: (current, previous) => Stack(
                  alignment: AlignmentDirectional.centerStart,
                  children: [...previous, if (current != null) current],
                ),
                // The greeting leaves upward as the title rises to replace it,
                // which reads as the page pushing it out of the way — the thing
                // that actually happened.
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.6),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: _showingTitle
                    ? PageBarTitle(
                        key: const ValueKey('title'),
                        text: widget.collapsedTitle,
                        style: context.textTheme.titleMedium?.copyWith(
                          color: text.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    // A `SizedBox` rather than null: `AnimatedSwitcher`
                    // needs something to cross-fade FROM, and a null child
                    // makes the title appear rather than arrive.
                    : widget.expanded ??
                          const SizedBox.shrink(key: ValueKey('none')),
              ),
            ),
      // The PHONE's status bar, not the app's.
      //
      // `GlobalAppBar` resolves this itself, and for a transparent bar
      // it assumes dark media behind it and asks for WHITE glyphs — a
      // fair default for a photo header, and exactly wrong here: every
      // one of the 83 frames is opaque white, so the clock and the
      // battery disappear into the page. Named rather than inherited,
      // for the same reason `auth_scaffold` names it.
      //
      // Read from the theme rather than pinned to `dark`: the design is
      // light-only, but the derived dark ramp exists and white glyphs
      // are right there.
      systemOverlayStyle: context.isDarkMode
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      style: AppBarStyle(
        // Only the transparent bar fades: the standard one has a
        // surface of its own at every offset.
        backgroundColor: widget.transparent
            ? surface.withValues(alpha: t)
            : null,
        foregroundColor: text.primary,
        buttonBackgroundColor: TerracottaAppBar.buttonBackground,
        // Against the reading start: the greeting is addressed to
        // someone, not a caption over the page.
        centerTitle: false,
        // The module's own retreat. The title swap is still worth
        // having: the bar comes back the moment the reader scrolls up,
        // and it should say where they are rather than greet them
        // again halfway down the page.
        hideOnScroll: widget.hideOnScroll,
      ),
      // The bell sits LAST, after the language toggle — nearest the
      // edge, where the thumb reaches.
      // Padded HERE rather than through the module: `actionsPadding`
      // only sets the END inset, so it can space the row off the edge
      // but not the buttons off each other.
      actions: [
        // ONLY while the title is showing: it stands in for whatever
        // scrolled away, so it has nothing to do while that thing is on
        // screen.
        // WITH A MORPH the endpoint is built whether or not it is
        // showing: a flight needs a rect at both ends, and an endpoint
        // that only exists once it is visible has none to fly to.
        // `InPageHero` collapses the inactive one itself.
        if (widget.collapsedAction != null &&
            (widget.actionMorph != null || _showingTitle))
          Padding(
            padding: const EdgeInsetsDirectional.only(
              start: TerracottaAppBar.actionGap,
            ),
            child: widget.actionMorph == null
                ? widget.collapsedAction
                : InPageHero(
                    tag: TerracottaAppBar.actionMorphTag,
                    controller: widget.actionMorph!,
                    index: 1,
                    child: widget.collapsedAction!,
                  ),
          ),
        // The SAME three, flown as one — see `HeroTag.barActions`.
        //
        // The TAB bar has to carry it as well as the page bar, or the
        // flight has only one end: every push out of a tab goes from
        // this bar to a `TerracottaPageBar`, and a hero with nothing to
        // fly from simply does not fly. Which is exactly what happened.
        SharedHero(
          tag: HeroTag.barActions,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Language only — the design is light-only, so a theme toggle
              // would offer a brightness nobody drew. Same call the auth
              // screens make.
              const Padding(
                padding: EdgeInsetsDirectional.only(
                  start: TerracottaAppBar.actionGap,
                ),
                child: QuickPreferenceActions(
                  showTheme: false,
                  buttonSize: ButtonSize.small,
                  buttonBackgroundColor: TerracottaAppBar.buttonBackground,
                  buttonIconColor: TerracottaAppBar.buttonGlyph,
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.only(
                  start: TerracottaAppBar.actionGap,
                ),
                child: TerracottaBellAction(unread: widget.unread),
              ),
              // The CART travels with the other two. It is the one control a
              // customer looks for from anywhere in a shop, and having it on
              // the product screen alone meant leaving the page you were
              // buying from to find what you had already picked up.
              const Padding(
                padding: EdgeInsetsDirectional.only(
                  start: TerracottaAppBar.actionGap,
                ),
                child: TerracottaCartAction(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
