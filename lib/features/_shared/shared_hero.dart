import 'package:flutter/material.dart';

import 'page_bar_title.dart';
import 'screen_entrance.dart';

/// A `Hero` that respects reduced motion.
///
/// Named for the APP rather than for a flow: the auth screens proved
/// it, and the three properties it adds — collapsing under reduced
/// motion, flying on the back SWIPE as well as a programmatic pop, and
/// falling back to an entrance when only one end exists — are what
/// every shared element in Terracotta needs.
///
/// Flutter's `Hero` has no equivalent of the collapse the rest of this
/// codebase does — the page transitions resolve to `none`, the
/// nav-aware animations cancel outright, and a flight would keep
/// running regardless. Worse, under that setting the page transition it
/// rides on is a ZERO duration, so the flights would have no clock at
/// all: the worst of both.
///
/// So the tag only exists when motion is welcome. Off, this is the bare
/// child and there is no `Hero` in the tree to find.
///
/// ## Tags are a contract between two screens
///
/// A tag may appear at most ONCE per route — two `Hero`s sharing one
/// throws. [AuthHeroTag] is the whole vocabulary for the flow, so a
/// duplicate is visible in one file rather than discovered at runtime
/// on a screen the customer is already looking at.
class SharedHero extends StatelessWidget {
  const SharedHero({
    required this.tag,
    required this.child,
    this.entranceStep = 0,
    this.flightShuttleBuilder,
    this.entranceDriftFrom,
    this.exitsWithRoute = false,
    super.key,
  });

  final String tag;
  final Widget child;

  /// Where this element sits in its screen's entrance stagger, for the
  /// arrivals where nothing flies — see [ScreenEntrance].
  final int entranceStep;

  /// What paints DURING the flight. Null uses the destination's child,
  /// which is right whenever the two endpoints look the same.
  final HeroFlightShuttleBuilder? flightShuttleBuilder;

  /// How this element ARRIVES on the screens where it does not fly, as
  /// a fraction of its own size and in READING terms — negative `dx`
  /// is in from the start. Null takes the house rise.
  ///
  /// The back chevron is why this exists. A rise of a third of a 40pt
  /// button is 13pt of movement in the corner of a bar, which is not
  /// something anyone notices; coming in from off the start edge is
  /// the same distance the control is FROM, and reads as the way back
  /// appearing because there is now somewhere to go.
  final Offset? entranceDriftFrom;

  /// Whether it also LEAVES the way it came, on the route's own clock.
  ///
  /// For PINNED chrome — a bar at the foot of the screen, the chevron
  /// at the head of it. Those arrive on a clock of their own while the
  /// page is arriving, so they should leave on one too. Page CONTENT
  /// is the opposite case: the transition is already carrying it off,
  /// and a second movement inside a moving page reads as mush rather
  /// than as depth. See [ScreenEntrance.exitsWithRoute].
  final bool exitsWithRoute;

  /// The same hero, renumbered. Lets a scaffold stage a column it was
  /// handed without the call site having to count its own rows.
  SharedHero withEntranceStep(int step) => SharedHero(
    tag: tag,
    entranceStep: step,
    flightShuttleBuilder: flightShuttleBuilder,
    entranceDriftFrom: entranceDriftFrom,
    exitsWithRoute: exitsWithRoute,
    key: key,
    child: child,
  );

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return Hero(
      tag: tag,
      // Fly during the BACK SWIPE too, not only a programmatic pop.
      //
      // Flutter defaults this to false, so a drag-back moved the page
      // and left every shared element behind — the flights worked on the
      // way in and simply were not there on the way out. Both ends have
      // to opt in, which is another reason this wrapper exists rather
      // than a bare `Hero` per call site.
      //
      // The route being revealed also needs `maintainState: true` for a
      // gesture flight to have somewhere to land; `_SwipeablePageRoute`
      // already sets it.
      transitionOnUserGestures: true,
      flightShuttleBuilder: flightShuttleBuilder,
      // INSIDE the hero, deliberately.
      //
      // A hero only flies when BOTH ends exist. Opening the app lands on
      // sign-in from the splash, which carries none of these tags, so
      // every shared element on the first screen anyone sees would just
      // appear. The entrance covers that arrival.
      //
      // It cannot disturb a real flight from here: slide, fade and scale
      // are paint-time only, so the hero's measured box is the same
      // whether the entrance is mid-play or finished. When a flight does
      // happen this plays offstage behind the shuttle and is spent by
      // the time the child is shown.
      child: entranceDriftFrom == null
          ? ScreenEntrance(
              step: entranceStep,
              exitsWithRoute: exitsWithRoute,
              child: child,
            )
          : ScreenEntrance.drift(
              step: entranceStep,
              from: entranceDriftFrom!,
              logical: true,
              // OUT the way it came, at the speed of the pop — see
              // `ScreenEntrance.exitsWithRoute`.
              exitsWithRoute: exitsWithRoute,
              child: child,
            ),
    );
  }
}

/// Every shared element in the auth flow, in one place.
///
/// Strings rather than an enum because `Hero.tag` is an `Object` and the
/// value has to be stable across two route builds — but kept together
/// so the uniqueness rule can be read, and tested, at a glance.
abstract final class AuthHeroTag {
  /// The brown CTA bar. On all seven screens, same box every time.
  static const cta = 'auth-cta';

  /// The phone field and its dial-code picker, as one box.
  /// Sign-in → register → forgot-password.
  static const phone = 'auth-phone';

  /// The vessel mark. Splash draws it at 105 × 148 dead centre; the auth
  /// header draws the same silhouette at 27 × 38 under the subtitle —
  /// the same object, two very different rects.
  static const mark = 'terracotta-mark';

  /// The sweep behind the heading, shared by sign-in and register.
  static const art = 'auth-art';

  /// The password box. Sign-in ↔ register only.
  ///
  /// Register draws TWO password fields; only the first carries this.
  /// A tag may appear once per route, and a confirm box is a different
  /// thing anyway — nothing on sign-in corresponds to it.
  static const password = 'auth-password';

  /// The heading. Its TEXT changes on every screen, so it flies with
  /// the cross-fading shuttle rather than swapping mid-air.
  static const title = 'auth-title';

  /// The line under the heading. Same treatment — and only present on
  /// screens that have one.
  static const subtitle = 'auth-subtitle';

  /// "Don't have an account?" / "Already have one?" — the row that
  /// swaps between sign-in and register.
  static const footer = 'auth-footer';

  /// Every tag, for the guard that proves they are unique per screen.
  static const all = <String>[
    cta,
    phone,
    password,
    mark,
    art,
    title,
    subtitle,
    footer,
  ];
}

/// Flies the REAL field, on a `Material` the Overlay does not provide.
///
/// ## What is actually on screen during a flight
///
/// Both heroes hide their content for the duration — the destination
/// keeps its child `Offstage` (laid out, unpainted), the source becomes
/// a bare `SizedBox`. The shuttle is therefore the ONLY thing visible.
///
/// That is why a hand-drawn replica does not work here: the field's
/// content — the dial code, the hint, anything typed — lives in its
/// STATE, which a shuttle has no way to read. A replica can only ever
/// paint the box, and the box is the whole picture, so the flight reads
/// as a blank panel sliding across the screen.
///
/// ## The cost of flying the real one
///
/// The shuttle builds a SECOND `PhoneNumberField` — its own state,
/// controllers, focus nodes and dropdown — created when the flight
/// starts and destroyed when it ends. Each boundary costs a layout pass
/// before it paints, which is a single rough frame on arrival and
/// another on departure.
///
/// That is a known, bounded cost and it is the better trade: correct
/// content for two frames of roughness, rather than a smooth flight of
/// something that does not look like the field.
///
/// `MaterialType.transparency` supplies the ancestor `TextField`
/// asserts on without painting a surface, so the field looks the same
/// in the air as it does at either end.
/// A field, an input, anything that needs a `Material` under it.
///
/// The Overlay is OUTSIDE the `Scaffold` the two ends live in, so a
/// `TextField` handed no `Material` ancestor there throws "No Material
/// widget found" mid-flight — which is a crash on a screen the
/// customer is already looking at, not a visual glitch.
Widget fieldShuttle(
  BuildContext flightContext,
  Animation<double> animation,
  HeroFlightDirection direction,
  BuildContext fromContext,
  BuildContext toContext,
) {
  final hero =
      (direction == HeroFlightDirection.push ? toContext : fromContext).widget
          as Hero;
  // Strip the entrance: it belongs to an ARRIVAL, and this element is
  // arriving by flight instead. Left on, the shuttle would mount a
  // fresh one in the overlay and fade the field up from nothing while
  // it travels.
  return Material(
    type: MaterialType.transparency,
    child: ScreenEntrance.unwrap(hero.child),
  );
}

/// Cross-fades the two ends of a flight instead of showing the
/// destination's child for the whole of it.
///
/// The CTA is the case this exists for: the bar is the same box on
/// every screen but its LABEL changes — تحقق on the code step, تغيير on
/// the last one. The default shuttle paints the destination's child
/// from the first frame, so the word swaps instantly while the box is
/// still travelling, which reads as a glitch rather than a change.
///
/// The page bar's TITLE is the same problem one level up, and the
/// reason this is no longer named for the auth flow: «طلباتي» flying to
/// «تفاصيل الطلب» is two different words in one box, and swapping them
/// on frame one is exactly the glitch described above.
Widget crossFadeShuttle(
  BuildContext flightContext,
  Animation<double> animation,
  HeroFlightDirection direction,
  BuildContext fromContext,
  BuildContext toContext,
) {
  // Both ends stripped of their entrances — this element is arriving by
  // flight, not by entrance, and a second one in the overlay would fade
  // the label up from nothing mid-air.
  final from = ScreenEntrance.unwrap((fromContext.widget as Hero).child);
  final to = ScreenEntrance.unwrap((toContext.widget as Hero).child);

  return _crossFade(animation, direction, from, to);
}

/// The cross-fade itself, shared by both shuttles above.
Widget _crossFade(
  Animation<double> animation,
  HeroFlightDirection direction,
  Widget from,
  Widget to,
) => AnimatedBuilder(
  animation: animation,
  builder: (context, _) {
    // `fromHero` and `toHero` arrive in that order for BOTH
    // directions — only the clock differs. Flutter drives a push off
    // `toRoute.animation` (0 → 1) and a pop off `fromRoute.animation`
    // (1 → 0), so inverting the value is enough; swapping the pair as
    // well would cancel it out and fade the wrong way home.
    final t = direction == HeroFlightDirection.push
        ? animation.value
        : 1 - animation.value;
    // TRANSPARENT MATERIAL around the pair: the shuttle is built in
    // the Overlay, outside the `Scaffold` the two ends live in, and
    // text handed no `Material` ancestor there paints on nothing.
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          Opacity(opacity: 1 - t, child: from),
          Opacity(opacity: t, child: to),
        ],
      ),
    );
  },
);

/// The page bar's title, cross-faded and HELD STILL.
///
/// [crossFadeShuttle] with one extra job: every marquee in the air is
/// switched off. A hero's box is interpolated between its two ends, so
/// a title flying from a short word to a long one spends the flight in
/// a box narrower than either — the text really does overflow, the
/// marquee really is right to scroll, and the reader watches a title
/// that fits perfectly well scroll itself and then stop. See
/// [PageBarTitle].
///
/// It has to reach through two wrappers to find the words:
///
///   * a TAB's title slot is an `AnimatedSwitcher` — the greeting and
///     the title swap in it as the page scrolls;
///   * a tab with nothing in that slot yet holds an invisible box the
///     size of a title, so the flight has a rect to start from rather
///     than a 0×0 corner.
Widget pageTitleShuttle(
  BuildContext flightContext,
  Animation<double> animation,
  HeroFlightDirection direction,
  BuildContext fromContext,
  BuildContext toContext,
) => _crossFade(
  animation,
  direction,
  _stillTitle((fromContext.widget as Hero).child),
  _stillTitle((toContext.widget as Hero).child),
);

/// Whatever is in a title slot, with its marquee off.
Widget _stillTitle(Widget widget) {
  final child = ScreenEntrance.unwrap(widget);
  return switch (child) {
    PageBarTitle() => child.still,
    // The tab bar's greeting/title swap. Its CURRENT child is what is
    // on screen and therefore what is flying.
    AnimatedSwitcher(child: final inner?) => _stillTitle(inner),
    // The invisible stand-in on a tab that has not scrolled yet. Kept
    // invisible, but its marquee stops too — it is still a running
    // animation for something nobody can see.
    Opacity() => Opacity(
      opacity: child.opacity,
      child: child.child == null ? null : _stillTitle(child.child!),
    ),
    _ => child,
  };
}

/// Every shared element OUTSIDE the auth flow.
///
/// Kept together for the same reason [AuthHeroTag] is: a tag may appear
/// at most ONCE per route, and two `Hero`s sharing one throws on a
/// screen the customer is already looking at. One file is where that
/// rule can be read — and tested — at a glance.
abstract final class HeroTag {
  /// The "happening now" strips, which sit in the same place on the
  /// home, workshops and shop tabs.
  ///
  /// Flying them makes them hold STILL while three different pages
  /// change under them, which is exactly what a thing that is true
  /// right now should do.
  static const liveOrder = 'live-order';
  static const liveWorkshop = 'live-workshop';

  /// «ورشتك القادمة» — the seat already booked, drawn above the home
  /// and workshops pages in the same place and the same shape.
  ///
  /// Its own tag rather than riding [liveWorkshop]: both strips can be
  /// on screen at once — a customer sitting in one session with
  /// another booked — and two of them sharing a tag would throw.
  static const nextBooking = 'next-booking';

  /// The booking flow's pinned CTA. Schedule → pieces → checkout is
  /// three consecutive `slideFromEnd` routes with the same bar at the
  /// foot of each — the same case the auth CTA already proved.
  static const bookingCta = 'booking-cta';

  /// The page bar's TITLE.
  ///
  /// One tag for every secondary page, because the box is the same box
  /// — the same place, the same weight — and only the words in it
  /// change. It flies with [crossFadeShuttle] for that reason: the
  /// default shuttle would swap «طلباتي» for «تفاصيل الطلب» on the
  /// first frame of a flight that has not started travelling yet.
  ///
  /// **Secondary pages only.** A TAB's bar puts its greeting in that
  /// place and swaps the title in on scroll, through an
  /// `AnimatedSwitcher` that owns those pixels already — a hero there
  /// would be two things animating one box. So a push OUT of a tab has
  /// one end and does not fly, which is the right answer rather than a
  /// gap: there is nothing on the tab for the title to have come from.
  static const pageTitle = 'page-title';

  /// The BACK chevron.
  ///
  /// The one control that is in the same place on every pushed screen,
  /// so flying it holds it still while the page travels underneath —
  /// the same job [barActions] does on the other side of the bar.
  ///
  /// It also answers the question of when the chevron should ARRIVE,
  /// without anyone having to ask it. A tab's bar has no back button,
  /// so a push out of a tab has one end and no flight — and
  /// [SharedHero] falls back to an entrance exactly then, because the
  /// route is still arriving when the child is built. A push from one
  /// pushed page to another flies instead, and the entrance inside the
  /// hero stands down because a landed flight builds its child onto a
  /// route that is already here. First chevron rises in; every one
  /// after it holds still.
  static const back = 'bar-back';

  /// One PHOTOGRAPH, flying from a thumbnail into the full-screen
  /// viewer.
  ///
  /// Keyed by the image's own url rather than by a row id: the album
  /// sheet and the product gallery both draw pictures that have no id
  /// of their own, and the url is what makes this one this one. Two
  /// thumbnails of the same file on one screen would collide, which is
  /// why `HeroScope` hands these out rather than the call site.
  static String photo(String url) => 'photo-$url';

  /// The SEARCH box.
  ///
  /// The shop tab carries one in its bar and the browse screen it opens
  /// carries the same one under its own — the same control, in the same
  /// place, doing the same job. Flying it is what says so; without it
  /// the field the reader was typing in vanished and an identical one
  /// appeared, which reads as having been thrown away.
  static const searchField = 'search-field';

  /// The bar's trailing controls — the language pill, the bell and the
  /// cart — which are the same three boxes on every screen in the app.
  ///
  /// Flying them holds them still while the page travels underneath,
  /// which is what makes a push read as the CONTENT changing rather
  /// than the whole app sliding.
  static const barActions = 'bar-actions';

  /// One product's photograph, flying from a card into the detail
  /// page's gallery.
  ///
  /// **Built per product, and only ONCE per route.** The home page
  /// draws a featured rail and an offers rail, and the live payload
  /// puts products 1 and 13 in BOTH — a tag per id alone would put two
  /// heroes with one tag on that screen and throw. [HeroScope] is what
  /// hands the tag out.
  static String product(int id) => 'product-$id';

  /// The product's NAME and its PRICE, which are on the card and on the
  /// detail page both.
  ///
  /// Separate tags rather than one around the whole card: the card and
  /// the detail page do not hold the same object — the card is a tile,
  /// the detail is a gallery over a title block — so a single hero
  /// would morph one into the other. Three elements flying to their own
  /// counterparts reads as the card coming apart and reassembling,
  /// which is what actually happens.
  ///
  /// All three are claimed TOGETHER: a duplicate card must fly none of
  /// them, or its title would fly while its picture did not.
  static String productTitle(int id) => 'product-title-$id';
  static String productPrice(int id) => 'product-price-$id';

  /// «مميز», and the heart.
  ///
  /// The badge exists on BOTH ends only for a featured product, and the
  /// heart only where one is drawn — a hero with one end missing does
  /// not fly, which is the right outcome rather than a failure.
  static String productFeatured(int id) => 'product-featured-$id';

  /// «-٢٣٪», the saving on a piece that is on offer.
  ///
  /// Its own tag rather than riding the featured one: a product can be
  /// featured, on offer, both or neither, and two badges sharing a tag
  /// would fly the wrong one whenever only one of them existed.
  static String productDiscount(int id) => 'product-discount-$id';
  static String productFavourite(int id) => 'product-favourite-$id';

  /// «نفدت الكمية» / «بقي ٣ قطع».
  ///
  /// Its own tag for the same reason the saving has one: stock is a
  /// third independent fact about a piece, and a label that only
  /// appears when something is running out must not borrow a tag that
  /// exists on cards where it does not.
  static String productStock(int id) => 'product-stock-$id';

  /// A shop CATEGORY's cut-out and its name.
  ///
  /// The home page and the shop page draw the same rail from two
  /// different payloads, so a category holds still while the reader
  /// moves between the two tabs.
  static String category(int id) => 'category-$id';
  static String categoryTitle(int id) => 'category-title-$id';

  /// A booking's card, flying into its own detail page.
  static String booking(int id) => 'booking-$id';

  /// Every fixed tag, for the guard that proves they are unique.
  static const all = <String>[
    liveOrder,
    liveWorkshop,
    nextBooking,
    bookingCta,
    barActions,
    pageTitle,
    back,
    searchField,
  ];
}

/// Hands out a hero tag at most ONCE per route.
///
/// A `Hero` tag has to be unique within a route, and the shop rails
/// break that on their own: the home payload's featured and offers
/// lists overlap — products 1 and 13 are in both, verified against the
/// live server — so a card that tagged itself by product id would put
/// two identical tags on one screen and Flutter would throw.
///
/// ## The claim is a LIFETIME, not a call
///
/// It was written as `claim(context, tag)` called straight from an
/// `itemBuilder`, and that was wrong in a way that looked like the
/// heroes were simply broken: a builder runs on every REBUILD, so the
/// first build took the tag and every rebuild after it was refused —
/// the tile lost its hero the moment anything above it changed. A
/// category rail rebuilds on selection, on locale, on scroll, so its
/// flights never worked at all; the product rails worked or not
/// depending on which build happened to be first.
///
/// So a claim is held by a WIDGET, for as long as that widget is in the
/// tree, and released when it leaves. [HeroTagClaim] is the only way to
/// take one.
class HeroScope extends StatefulWidget {
  const HeroScope({required this.child, super.key});

  final Widget child;

  static _HeroScopeState? _of(BuildContext context) =>
      context.findAncestorStateOfType<_HeroScopeState>();

  /// Take a tag OUT of circulation for the life of this scope.
  ///
  /// The product detail page is the case: its own gallery, title and
  /// price already wear this product's tags, and it also draws a
  /// related-products rail underneath. If that rail happened to hold
  /// the same product, its card would claim tags that are already on
  /// screen — two heroes, one tag, and Flutter asserts.
  static void reserve(BuildContext context, String tag) =>
      _of(context)?._take(tag, _reserved);

  /// The sentinel owner for [reserve], which never releases.
  static const _reserved = Object();

  /// Hand every tag in [group] to that group's own claims, taking them
  /// off whoever holds them.
  ///
  /// ## Why first-come is not good enough
  ///
  /// A claim stops two heroes sharing a tag, which is what THROWS. It
  /// does not decide which of them should fly, and on the home page
  /// that is visible: the live payload puts the same product in both
  /// the featured rail and the offers rail, the featured one claims
  /// the tag because it is built first, and tapping the OFFERS card
  /// flew the featured card's picture — an image sliding out of a row
  /// the reader was not touching.
  ///
  /// Called from a card's own tap, just before it pushes, this makes
  /// the thing that flies the thing that was pressed. [reserve]'s
  /// sentinel is never taken: those tags are worn by the page itself.
  static void promote(BuildContext context, Object group) =>
      _of(context)?._promote(group);

  @override
  State<HeroScope> createState() => _HeroScopeState();
}

class _HeroScopeState extends State<HeroScope> {
  /// Tag → whoever holds it. Not a `Set`: the holder is what makes a
  /// re-ask by the SAME widget idempotent.
  final _held = <String, Object>{};

  /// Every claim alive under this scope, so [promote] can find the
  /// ones belonging to a group without walking the tree.
  final _claims = <_HeroTagClaimState>{};

  void _promote(Object group) {
    for (final claim in _claims) {
      if (claim.widget.group != group) continue;

      final tag = claim.widget.tag;
      final current = _held[tag];
      if (identical(current, claim)) continue;
      // The page's own tags. See `HeroScope.reserve`.
      if (identical(current, HeroScope._reserved)) continue;

      _held[tag] = claim;
      if (current is _HeroTagClaimState) current._holdChanged(holds: false);
      claim._holdChanged(holds: true);
    }
  }

  /// Whether [owner] holds [tag] after this call.
  bool _take(String tag, Object owner) {
    final current = _held[tag];
    if (current == null) {
      _held[tag] = owner;
      return true;
    }
    return identical(current, owner);
  }

  void _release(String tag, Object owner) {
    if (identical(_held[tag], owner)) _held.remove(tag);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Wears [tag] as a hero — but only if nothing else on this screen
/// already does.
///
/// Holds the claim for as long as it is in the tree and gives it back
/// on the way out, so a rebuild keeps the tag and a recycled list tile
/// hands it to whoever takes its place.
///
/// Outside a [HeroScope] nothing flies, which is safer than a tag
/// nobody is counting.
class HeroTagClaim extends StatefulWidget {
  const HeroTagClaim({
    required this.tag,
    required this.child,
    this.group,
    this.flightShuttleBuilder,
    super.key,
  });

  final String tag;
  final Widget child;

  /// What this claim belongs to — a card, a row, one occurrence of a
  /// product. `HeroScope.promote(context, group)` hands every tag in a
  /// group to it at once, which is how a card that was TAPPED takes
  /// the tags a duplicate claimed first.
  ///
  /// Null opts out: the claim is then first-come and stays there.
  final Object? group;

  final HeroFlightShuttleBuilder? flightShuttleBuilder;

  @override
  State<HeroTagClaim> createState() => _HeroTagClaimState();
}

class _HeroTagClaimState extends State<HeroTagClaim> {
  _HeroScopeState? _scope;
  bool _holds = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Not `initState`: an ancestor lookup is only legal from here on.
    final scope = _scope ??= HeroScope._of(context);
    scope?._claims.add(this);
    if (!_holds) _holds = scope?._take(widget.tag, this) ?? false;
  }

  /// The scope moved this tag. Rebuild so the hero appears or goes.
  void _holdChanged({required bool holds}) {
    if (!mounted || _holds == holds) return;
    setState(() => _holds = holds);
  }

  @override
  void didUpdateWidget(HeroTagClaim old) {
    super.didUpdateWidget(old);
    if (old.tag == widget.tag) return;
    // A recycled tile, now standing for a different product.
    if (_holds) _scope?._release(old.tag, this);
    _holds = _scope?._take(widget.tag, this) ?? false;
  }

  @override
  void dispose() {
    _scope?._claims.remove(this);
    if (_holds) _scope?._release(widget.tag, this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _holds
      ? SharedHero(
          tag: widget.tag,
          flightShuttleBuilder: widget.flightShuttleBuilder,
          child: widget.child,
        )
      : widget.child;
}
