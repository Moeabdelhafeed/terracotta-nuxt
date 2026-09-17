import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/animations/animation_presets.dart';
import 'shared_hero.dart';

/// The house entrance for a row of an auth screen: it rises a little
/// and fades in, one row after another, as its page arrives.
///
/// ## Its own clock, gated by the route
///
/// Two things have to be true at once, and each rules out the obvious
/// way of getting the other.
///
/// **It has to outlast the page transition to be visible at all.** The
/// first version rode `ModalRoute.animation` directly, which sounds
/// tidy and is useless: the page moves for 400ms, so the whole column
/// was compressed into that, giving a 24ms gap between one row and the
/// next and a fade running underneath the page's own. Every element was
/// animating and none of it could be seen. A stagger has to be slower
/// than the page to read as a stagger.
///
/// **But it must not play when the element FLEW in.** A hero does not
/// build its destination child while a flight is in the air — the
/// element is a placeholder for the whole trip and is built only once
/// the shuttle lands. An entrance that simply starts on mount therefore
/// starts when the flight ENDS: measured at the stagger a sign-up
/// button sits at, the page settled around 400ms and the button then
/// sat at zero opacity until 900ms before fading up. It flew in
/// beautifully and then vanished.
///
/// So the clock is this widget's own, and the ROUTE decides whether to
/// start it: one frame after mounting, [_arrivalThreshold] asks how far
/// the page has already travelled.
///
/// - Near the start — the page is arriving and this element came with
///   it. Play.
/// - Near the end — the page got here a while ago and this element is
///   only being built now, which is what a landed flight looks like.
///   Do nothing; it has already been animated, by the flight.
///
/// That also covers the arrival this exists for. A hero flies only when
/// BOTH ends exist, so opening the app onto sign-in from the splash
/// carries none of these tags and nothing flies — every shared element
/// on the first screen anyone sees would otherwise simply appear.
///
/// ## Why the wait paints the child rather than hiding it
///
/// The decision needs a frame, and the frame before it has to paint
/// something. It paints the child at FULL strength, which is right in
/// both directions: on a landed flight that is the final answer, and on
/// an arrival the page itself is still transparent or offscreen for
/// that frame, so nothing of it reaches the screen.
///
/// ## It must sit INSIDE a hero, never above one
///
/// Above a hero it breaks the flight: Flutter measures the hero's own
/// render box, and an entrance translating an ancestor moves that box
/// out from under the shuttle mid-air. Inside it cannot — slide, fade
/// and scale are PAINT-time transforms, so the box is identical whether
/// the entrance is mid-play or finished. Measured both ways, mid-flight
/// and at rest: the same rect to the pixel.
///
/// ## What counts as "arriving" — the route, or the widget
///
/// The route gate above is right for an element that is BUILT WITH ITS
/// PAGE. It is silently wrong for one that is not, and most of this app
/// is not: a screen bound to an API renders a spinner first and builds
/// its real column only when the response lands, by which time the page
/// transition finished long ago. The gate then reads 1.0 and refuses —
/// so every staged list in the app decided not to play. Proved by
/// measuring opacity across frames, which the source-scanning tests
/// that "covered" this could never have caught.
///
/// [EntranceArrival] is the choice:
///
///   * [EntranceArrival.route] — the page's own arrival is the cue.
///     What a hero destination needs, because a landed flight looks
///     exactly like a late build and must not be re-animated.
///   * [EntranceArrival.mount] — being built IS the arrival. What
///     content gated on a response needs, and the default for
///     [ScreenEntrance.stage], which is how pages compose their lists.
///
/// A mount arrival needs no frame to decide, so it decides in
/// `didChangeDependencies` and is already at zero on its first paint —
/// deferring it would flash the finished content for one frame on a
/// page that is fully visible.
///
/// `screen_entrance_test.dart` holds all of it.
/// What an entrance actually DOES, which is not a style choice on a
/// page that flies things.
///
/// A `SlideTransition` and a `ScaleTransition` both move the render box
/// Flutter measures a hero against. That is harmless when the entrance
/// sits INSIDE the hero, which is where [SharedHero] puts it — but a
/// page composing a column cannot reach inside a section to place one
/// per element, so its entrance lands ABOVE whatever heroes that
/// section holds. [EntranceMotion.fade] is the version that can: pure
/// opacity leaves the rect identical to the pixel, so a flight measured
/// mid-entrance measures the right box.
enum EntranceMotion {
  /// Rises and fades. The default, and the one that reads best — for a
  /// column with nothing flying in it.
  rise,

  /// Fades and settles from slightly small, with no rise.
  ///
  /// A `SlideTransition` travels a fraction of the widget's OWN height,
  /// so the offset that reads as a nudge under a 56pt field is a lurch
  /// under a 200pt illustration. A drawing gets scale instead, which is
  /// proportional by construction.
  art,

  /// Opacity ONLY. Hero-safe, and the reason it exists.
  fade,

  /// In from a named direction, by a fraction of the widget's own size.
  ///
  /// For a piece of ARTWORK that belongs to a corner. The three browse
  /// headers are drawings pinned to the edges of a band — a camera at
  /// the top end, a pot at the bottom start — and they read best coming
  /// in from the side they are anchored to, as if they had just been
  /// laid down there. A uniform rise says nothing about where anything
  /// belongs; [ScreenEntrance.drift] takes the offset.
  drift,
}

enum EntranceArrival {
  /// Play only if the ROUTE is still arriving. Hero-safe.
  route,

  /// Play whenever this widget is built. For content that appears after
  /// its page did.
  mount,
}

class ScreenEntrance extends StatefulWidget {
  /// A form row: rises [_rise] of its own height and fades in.
  const ScreenEntrance({
    required this.child,
    this.step = 0,
    this.arrival = EntranceArrival.route,
    this.exitsWithRoute = false,
    super.key,
  }) : motion = EntranceMotion.rise,
       driftFrom = Offset.zero,
       logicalDrift = false;

  /// A drawing: fades and settles from slightly small, with no rise.
  /// See [EntranceMotion.art].
  const ScreenEntrance.art({
    required this.child,
    this.step = 0,
    this.arrival = EntranceArrival.route,
    super.key,
  }) : motion = EntranceMotion.art,
       driftFrom = Offset.zero,
       logicalDrift = false,
       exitsWithRoute = false;

  /// Opacity only — for a section that has HEROES under it.
  /// See [EntranceMotion.fade].
  const ScreenEntrance.fade({
    required this.child,
    this.step = 0,
    this.arrival = EntranceArrival.route,
    super.key,
  }) : motion = EntranceMotion.fade,
       driftFrom = Offset.zero,
       logicalDrift = false,
       exitsWithRoute = false;

  /// In from [from], a fraction of the widget's OWN size — so
  /// `Offset(1, -1)` is one width to the right and one height above.
  /// See [EntranceMotion.drift].
  ///
  /// PHYSICAL by default, which is what a mirrored layer wants: the
  /// headers put their drawings inside a `Transform.flip`, so an offset
  /// toward `right` there already travels toward the reading start in
  /// both languages and resolving it again would undo that.
  ///
  /// Pass `logical: true` for an element that is NOT inside such a
  /// layer, and a negative `dx` then means "from the reading START" —
  /// the left in English, the right in Arabic. The back chevron is the
  /// case: it lives at the start edge of the bar and comes in from off
  /// the page, whichever edge that is.
  const ScreenEntrance.drift({
    required this.child,
    required Offset from,
    this.step = 0,
    this.arrival = EntranceArrival.route,
    bool logical = false,
    this.exitsWithRoute = false,
    super.key,
  }) : motion = EntranceMotion.drift,
       logicalDrift = logical,
       driftFrom = from;

  final Widget child;

  /// Position in the stagger — 0 first, then one [_stagger] apart, up
  /// to [_maxStep].
  final int step;

  /// What it does. See [EntranceMotion].
  final EntranceMotion motion;

  /// Where a [EntranceMotion.drift] starts, as a fraction of the
  /// widget's own size. Zero for every other motion.
  final Offset driftFrom;

  /// Whether [driftFrom]'s `dx` is a READING direction rather than a
  /// physical one. See [ScreenEntrance.drift].
  final bool logicalDrift;

  /// Whether it LEAVES the way it came, on the route's own clock.
  ///
  /// An arrival is a one-shot: it plays and it is spent, and the
  /// element then sits still while its page is dragged off the screen.
  /// For most content that is right — the page transition is carrying
  /// it, and a second movement inside a moving page is noise.
  ///
  /// The back chevron is the exception. It came IN from the start edge
  /// because there was suddenly somewhere to go back to, so it should
  /// go back out the same way when there is not — and it has to do
  /// that at the speed of the POP, not at its own, because a
  /// back-SWIPE is a finger the reader is still holding. Riding
  /// `ModalRoute.animation` is what makes it follow the drag, stop
  /// when the drag stops, and come back if the drag is abandoned.
  final bool exitsWithRoute;

  /// What this element treats as its arrival. See [EntranceArrival].
  final EntranceArrival arrival;

  /// How far a row travels, as a fraction of its own height. Small on
  /// purpose: the page is already moving underneath it.
  static const _rise = 0.35;

  /// The gap between one row and the next.
  static const _stagger = Duration(milliseconds: 55);

  /// Where the stagger STOPS growing.
  ///
  /// A full sign-up screen is eleven elements deep once the header, five
  /// rows, the bar and the footer are counted. Left uncapped the last of
  /// them would begin most of a second after the first, which stops
  /// reading as one movement and starts reading as a slow page. Past
  /// this they all arrive together.
  ///
  /// A LIST is the case this cap has to be counted against rather than
  /// assumed for: cards starting at four hit it on the fourth card, so
  /// half a page of orders arrived in one block. The fix was the
  /// starting step, not a bigger cap — the cap is still what keeps the
  /// eighth row from being a second late.
  static const _maxStep = 7;

  /// How far into its transition a page may be for an element built now
  /// to count as having arrived WITH it.
  ///
  /// Anything past this was built onto a page that is already here — a
  /// hero that has just landed, or a rebuild — and gets no entrance.
  static const _arrivalThreshold = 0.5;

  /// The step a screen's FORM starts at, after the header has taken the
  /// artwork, the title, the subtitle and the mark.
  static const formStep = 4;

  /// The composed child, without its entrance.
  ///
  /// A flight shuttle needs this: `SharedHero` puts the entrance inside
  /// the hero, so a shuttle built from `hero.child` would otherwise
  /// mount a second one in the Overlay.
  static Widget unwrap(Widget widget) =>
      widget is ScreenEntrance ? widget.child : widget;

  /// Gives [child] its place in the stagger, wherever the entrance has
  /// to go for that particular child.
  ///
  /// Callers hand a scaffold a flat list and the scaffold numbers it, so
  /// nobody has to renumber a column by hand after inserting a row —
  /// which is how the inside/above rule would eventually get broken.
  static Widget staged(
    Widget child,
    int step, {
    EntranceArrival arrival = EntranceArrival.mount,
    EntranceMotion motion = EntranceMotion.rise,
  }) {
    // ignore: parameter_assignments — the wrapped child overrides it;
    // see below.
    // A spacer is not content. Numbering it would leave a hole in the
    // stagger and a pause with nothing arriving in it.
    if (child is SizedBox) return child;

    // A child that ARRIVED WRAPPED has already said what it wants.
    //
    // `heroSafe` is a statement about the column as a whole — a tab
    // page cannot reach inside a section to place an entrance per
    // element, so it drops the rise for all of them. But it knows
    // perfectly well which of its own sections hold nothing that
    // flies: a heading, a row of shortcuts, an illustration. Those are
    // wrapped at the call site and keep the rise, and everything else
    // fades.
    final inner = child is ScreenEntrance ? child.child : child;
    if (child is ScreenEntrance) motion = child.motion;

    return switch (motion) {
      EntranceMotion.rise => ScreenEntrance(
        step: step,
        arrival: arrival,
        child: inner,
      ),
      EntranceMotion.art => ScreenEntrance.art(
        step: step,
        arrival: arrival,
        child: inner,
      ),
      EntranceMotion.fade => ScreenEntrance.fade(
        step: step,
        arrival: arrival,
        child: inner,
      ),
      EntranceMotion.drift => ScreenEntrance.drift(
        step: step,
        arrival: arrival,
        from: child is ScreenEntrance ? child.driftFrom : Offset.zero,
        logical: child is ScreenEntrance && child.logicalDrift,
        child: inner,
      ),
    };
  }

  /// Number a COLUMN of children, one after another.
  ///
  /// Hoisted out of `AuthScaffold`, which is where it was proved: a
  /// page hands over its children and gets them back staged, so
  /// inserting a row cannot silently leave a hole in the stagger — or
  /// put an entrance ABOVE a hero, which breaks the flight.
  ///
  /// Three kinds of child, three answers:
  ///
  ///   * a SPACER is not content. Numbering it leaves a pause with
  ///     nothing arriving in it.
  ///   * an [EntranceSkip] is a section that stages ITSELF — the shop's
  ///     rails and the workshops header both do, because their own
  ///     headings and cards are what the reader is watching arrive, not
  ///     the block that holds them. Wrapping it again would fade the
  ///     block over its own contents' stagger.
  ///   * a HERO carries its own step, applied INSIDE the flight — an
  ///     entrance above a hero moves the box the shuttle is measured
  ///     against.
  ///   * anything else is wrapped.
  /// The arrival is [EntranceArrival.mount] by default, because the
  /// caller is a page composing a list it only has once its data
  /// arrived. A HERO in that list keeps the route gate regardless —
  /// `withEntranceStep` builds the entrance inside the flight, and that
  /// one must not replay what the flight already did.
  ///
  /// And so is where the stagger STARTS. [formStep] exists because an
  /// auth screen's header — artwork, title, subtitle, mark — has
  /// already used the first four slots, and the form falls in behind
  /// it. A list of order cards has nothing ahead of it, and starting at
  /// four bought 220ms in which the page sat finished and empty before
  /// the first card moved. Printed frame by frame in
  /// `entrance_stagger_demo_test.dart`, which is how it was found.
  /// Pass `heroSafe: true` for a column whose SECTIONS hold heroes —
  /// a tab page's rails, the live strips. It drops the rise, which is
  /// the part that would move a shuttle's measured box. See
  /// [EntranceMotion.fade].
  static List<Widget> stage(
    List<Widget> children, {
    int? from,
    EntranceArrival arrival = EntranceArrival.mount,
    bool heroSafe = false,
  }) {
    final out = <Widget>[];
    var step = from ?? (arrival == EntranceArrival.mount ? 0 : formStep);
    for (final child in children) {
      if (child is SizedBox) {
        out.add(child);
      } else if (child is EntranceSkip) {
        out.add(child.child);
      } else if (child is SharedHero) {
        out.add(child.withEntranceStep(step++));
      } else {
        out.add(
          staged(
            child,
            step++,
            arrival: arrival,
            motion: heroSafe ? EntranceMotion.fade : EntranceMotion.rise,
          ),
        );
      }
    }
    return out;
  }

  @override
  State<ScreenEntrance> createState() => _ScreenEntranceState();
}

class _ScreenEntranceState extends State<ScreenEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  /// The stagger's own wait, held so it can be CANCELLED. A bare
  /// `Future.delayed` outlives the widget: the tree is torn down and the
  /// timer is still pending, which a test binding reports and a real app
  /// pays for.
  Timer? _wait;

  bool _decided = false;
  bool _playing = false;

  /// Whether this element's page has finished arriving at least once.
  /// See the exit branch in `build`.
  bool _settled = false;

  /// Drops the route listener that answers it.
  VoidCallback? _unwatchRoute;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      // ARTWORK takes longer. A drawing settling is the page's own
      // arrival; a form row is furniture behind it.
      duration:
          widget.motion == EntranceMotion.art ||
              widget.motion == EntranceMotion.drift
          ? AppDurations.slow
          : AppDurations.normal,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_decided) return;
    _decided = true;
    if (MediaQuery.disableAnimationsOf(context)) return;

    // NOW, with nothing to ask. Being built is the whole cue, so there
    // is no reason to wait a frame — and waiting would paint the
    // finished child once, at full strength, on a page the reader is
    // already looking at. That flash is exactly what the route-gated
    // path gets away with only because its page is not on screen yet.
    if (widget.arrival == EntranceArrival.mount) {
      _start();
      return;
    }

    // After the frame, because the answer is not available during the
    // route's first build: `ModalRoute.animation` is a `ProxyAnimation`
    // whose parent is attached afterwards, and until then it reads 1.0
    // whatever the page is really doing. Deciding synchronously here
    // would skip the entrance on every arrival.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final route = ModalRoute.of(context)?.animation;
      final progress = route?.value ?? 1;

      // WHEN THE PAGE IS ACTUALLY HERE, watched rather than asked.
      //
      // `ModalRoute.animation` is a `ProxyAnimation` whose parent is
      // attached after the first build, and until then it reads 1.0
      // whatever the page is doing — so "is it completed?" answers yes
      // on a page that has not started arriving. Asked in `build` that
      // put the exit on screen during the entrance: the chevron slid
      // OUT while its page slid in, and then appeared.
      if (widget.exitsWithRoute && route != null) {
        void watch() {
          if (route.isCompleted) _settled = true;
        }

        route.addListener(watch);
        _unwatchRoute = () => route.removeListener(watch);
        watch();
      }

      if (progress > ScreenEntrance._arrivalThreshold) return;
      setState(_start);
    });
  }

  /// Where the drift starts, with the reading direction applied if the
  /// offset asked for one.
  Offset _drift(BuildContext context) {
    final from = widget.driftFrom;
    if (!widget.logicalDrift) return from;
    return Directionality.of(context) == TextDirection.rtl
        ? Offset(-from.dx, from.dy)
        : from;
  }

  /// Where it goes on the way OUT — back the way it came in.
  ///
  /// A rise leaves downward, a drift leaves toward the corner it
  /// arrived from. A drawing that SCALED in has no direction to leave
  /// by, so it fades where it stands rather than being sent somewhere
  /// it never was.
  Offset _exitFrom(BuildContext context) => switch (widget.motion) {
    EntranceMotion.drift => _drift(context),
    EntranceMotion.rise => const Offset(0, ScreenEntrance._rise),
    EntranceMotion.art || EntranceMotion.fade => Offset.zero,
  };

  /// Zero, then forward when this element's turn comes round.
  void _start() {
    _playing = true;
    final step = widget.step < ScreenEntrance._maxStep
        ? widget.step
        : ScreenEntrance._maxStep;
    _wait = Timer(ScreenEntrance._stagger * step, () {
      if (mounted) _controller.forward(from: 0);
    });
  }

  @override
  void dispose() {
    _unwatchRoute?.call();
    _wait?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;

    // THE WAY OUT, on the route's clock — see `exitsWithRoute`.
    //
    // Wrapped whether or not the arrival ever played: a chevron that
    // FLEW in still has to leave, and the pop is the only thing that
    // knows how fast the reader is dragging.
    if (widget.exitsWithRoute) {
      final route = ModalRoute.of(context)?.animation;
      if (route != null) {
        return AnimatedBuilder(
          animation: route,
          builder: (context, _) {
            // ARRIVED ONCE, then anything short of 1 is leaving.
            //
            // NOT the status. An interactive pop — the iOS back swipe,
            // and the predictive gesture with it — drives the route's
            // controller by SETTING ITS VALUE from the drag, and
            // `AnimationController.value =` reports `forward` while it
            // does, not `reverse`. Reading the status therefore said
            // "still arriving" for the whole of a drag and only
            // admitted the truth once the finger let go, which is
            // exactly the lag: the chevron sat still under the reader's
            // thumb and then jumped.
            final leaving = _settled && route.value < 1;
            if (!leaving) return _arrival(context);
            return SlideTransition(
              position: AlwaysStoppedAnimation(
                _exitFrom(context) * (1 - route.value),
              ),
              child: Opacity(opacity: route.value, child: widget.child),
            );
          },
        );
      }
    }

    return _arrival(context);
  }

  /// The arrival itself.
  Widget _arrival(BuildContext context) {
    // Either the decision has not been made yet, or it was "no". Both
    // want the child exactly as it is.
    if (!_playing) return widget.child;

    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    final faded = FadeTransition(opacity: curved, child: widget.child);

    return switch (widget.motion) {
      // Nothing but the fade — see [EntranceMotion.fade].
      EntranceMotion.fade => faded,
      EntranceMotion.art => ScaleTransition(
        scale: Tween<double>(begin: 0.94, end: 1).animate(curved),
        child: faded,
      ),
      EntranceMotion.rise => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, ScreenEntrance._rise),
          end: Offset.zero,
        ).animate(curved),
        child: faded,
      ),
      EntranceMotion.drift => SlideTransition(
        position: Tween<Offset>(
          begin: _drift(context),
          end: Offset.zero,
        ).animate(curved),
        child: faded,
      ),
    };
  }
}

/// A section that stages its OWN children, and must not be staged again
/// as one block.
///
/// The shop's rails and the workshops header are both like this: what
/// the reader watches arrive is the headings and the cards inside them,
/// not the container. Left to [ScreenEntrance.stage] the container
/// would fade as a unit ON TOP of its contents' stagger — two clocks
/// over the same pixels, and the first one wins.
///
/// It is a marker, not a wrapper: it builds its child and nothing else.
class EntranceSkip extends StatelessWidget {
  const EntranceSkip({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}
