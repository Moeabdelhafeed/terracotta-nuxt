import 'dart:async';
import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'in_page_hero_style.dart';
import 'theme/in_page_hero_theme.dart';

export 'in_page_hero_style.dart';
export 'theme/in_page_hero_theme.dart';

// ---------------------------------------------------------------------------
// InPageHeroController
// ---------------------------------------------------------------------------

/// Controls flights between [InPageHero] widgets sharing the same [tag].
///
/// Supports 2+ endpoints — each identified by an [index].
///
/// ```dart
/// final controller = InPageHeroController();
///
/// InPageHero(tag: 'item', controller: controller, index: 0, child: A())
/// InPageHero(tag: 'item', controller: controller, index: 1, child: B())
/// InPageHero(tag: 'item', controller: controller, index: 2, child: C())
///
/// controller.flyTo(1);  // 0 → 1
/// controller.flyTo(2);  // 1 → 2
/// controller.flyTo(0);  // 2 → 0
/// ```
class InPageHeroController extends ChangeNotifier {
  InPageHeroController({int initialIndex = 0}) : _activeIndex = initialIndex;

  int _activeIndex;
  bool _isFlying = false;
  OverlayEntry? _overlayEntry;

  int get activeIndex => _activeIndex;
  bool get isFlying => _isFlying;

  final Map<String, Map<int, _HeroEntry>> _entries = {};

  /// Completes when the flight in progress lands.
  Completer<void>? _landed;

  /// Fly to [index].
  ///
  /// The future completes when the box ARRIVES, so a caller can chain
  /// something onto the landing — a form focus, a scroll, a second
  /// flight. It used to return nothing, and callers guessed with a
  /// `Future.delayed` of the duration they hoped was in force.
  ///
  /// A call while a flight is running is IGNORED and completes at once:
  /// interrupting mid-air would leave the source collapsed and the
  /// target expanded with nothing between them.
  Future<void> flyTo(int index, {String? tag}) {
    if (_isFlying) return Future<void>.value();

    final effectiveTag = tag ?? _entries.keys.firstOrNull;
    if (effectiveTag == null) return Future<void>.value();

    final entries = _entries[effectiveTag];
    if (entries == null) return Future<void>.value();

    final from = entries[_activeIndex];
    final to = entries[index];
    if (from == null || to == null || _activeIndex == index) {
      return Future<void>.value();
    }

    // Step 1: measure the SOURCE where the reader can currently see it
    // — BEFORE anything else moves.
    //
    // Expanding the target takes space, which reflows whatever the two
    // endpoints share a row or column with, and the source moves with
    // it. Measuring after that started the flight from a place the box
    // had never been: it jumped sideways and only then flew, which
    // reads as the thing going backwards before it sets off.
    final overlayBoxAtLaunch = _overlayBox(from.overlayState);
    final fromRect = _rectIn(from.key, overlayBoxAtLaunch);
    if (fromRect == null) {
      return Future<void>.value();
    }

    // Its parts, measured in the same breath and for the same reason:
    // a rect taken after the target expands is a rect from a layout the
    // reader never saw.
    final fromPartRects = <String, Rect>{
      for (final entry in from.parts.entries)
        if (entry.value.rectIn(overlayBoxAtLaunch) case final rect?)
          entry.key: rect,
    };

    final overlay = from.overlayState;
    if (overlay == null) return Future<void>.value();

    // Reduced motion: no overlay at all. Running one for zero frames
    // still inserts and removes an entry, which flickers.
    if (from.style.isInstant) {
      from.setMode(_LayoutMode.collapsed, animate: false);
      _activeIndex = index;
      notifyListeners();
      return Future<void>.value();
    }

    _isFlying = true;
    _landed = Completer<void>();
    notifyListeners();

    // Step 2: put the overlay up NOW, showing the source's own child at
    // the rect just measured, and stop the source painting — both in
    // this frame.
    //
    // The overlay used to go up a frame LATER, and in the frame between
    // them the source was still painted while the target's expansion
    // had already reflowed the row: the box visibly jumped sideways,
    // then reappeared where it had been, and only then flew. That is
    // the stutter, and the flash is the same frame.
    final target = ValueNotifier<_FlightPlan?>(null);
    _overlayEntry = OverlayEntry(
      builder: (_) => _FlyingWidget(
        fromRect: fromRect,
        toKey: to.key,
        overlay: overlay,
        target: target,
        fromChild: from.captureChild(),
        toChild: to.captureChild(),
        fromDecoration: from.decoration,
        toDecoration: to.decoration,
        themeData: from.themeData,
        style: from.style,
        onComplete: () {
          _overlayEntry?.remove();
          _overlayEntry = null;
          target.dispose();
          _activeIndex = index;
          _isFlying = false;
          notifyListeners();
          _completeFlight();
        },
      ),
    );
    overlay.insert(_overlayEntry!);

    // Invisible, but still holding its space — the row must not reflow
    // twice.
    from.setMode(_LayoutMode.measuring, animate: false);

    // Step 3: expand the target INSTANTLY, so its rect is stable while
    // the overlay travels. Nothing paints there yet, and the overlay is
    // already covering the place the reader is looking at.
    to.setMode(_LayoutMode.measuring, animate: false);

    // Step 4: one frame for that to lay out, then measure the target
    // and let the flight go.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!_isFlying) return;
      _launchFlight(from, to, index, effectiveTag, target, fromPartRects);
    });

    return _landed!.future;
  }

  void _completeFlight() {
    if (_landed?.isCompleted ?? true) return;
    _landed!.complete();
    _landed = null;
  }

  void _launchFlight(
    _HeroEntry from,
    _HeroEntry to,
    int targetIndex,
    String tag,
    ValueNotifier<_FlightPlan?> target,
    Map<String, Rect> fromPartRects,
  ) {
    final overlayBox = _overlayBox(from.overlayState);
    final toRect = _rectIn(to.key, overlayBox);
    if (toRect == null) {
      _abort(tag);
      return;
    }

    // Only ids that exist at BOTH ends fly. One that appears in a
    // single child has nowhere to travel from or to, and stays in the
    // crossfade.
    final parts = <String, _PartFlight>{};
    for (final entry in fromPartRects.entries) {
      final toPart = to.parts[entry.key];
      final toPartRect = toPart?.rectIn(overlayBox);
      if (toPart == null || toPartRect == null) continue;
      final fromPart = from.parts[entry.key]!;
      // A builder on BOTH ends is a morph; one facing a plain part has
      // no second value to travel to, so it crossfades like any other.
      final morph = fromPart.builder != null && toPart.builder != null
          ? fromPart.builder
          : null;

      parts[entry.key] = _PartFlight(
        fromRect: entry.value,
        toRect: toPartRect,
        fromChild: fromPart.child,
        toState: toPart,
        morph: morph,
        fromT: fromPart.restingT,
        toT: toPart.restingT,
      );
    }

    // Releases the flight: the overlay has been up since the previous
    // frame, holding still at the source's rect.
    target.value = _FlightPlan(rect: toRect, parts: parts);

    // And the source gives up its space, smoothly — the only layout
    // animation during the flight. The overlay tracks the target's live
    // rect, so what moves underneath is followed rather than fought.
    // Source collapses smoothly — the only layout animation during flight.
    // Target position is stable (already at full size), so no drift.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      from.setMode(_LayoutMode.collapsed, animate: true);
    });
  }

  /// A flight that could not be measured — an endpoint that scrolled
  /// out of the tree between the request and the frame after it.
  ///
  /// Notifying puts every endpoint back where the active index says it
  /// belongs, and the future completes so a caller is not left waiting
  /// for a landing that will never happen.
  void _abort(String tag) {
    _isFlying = false;
    notifyListeners();
    _completeFlight();
  }

  Future<void> flyToNext({String? tag}) {
    final effectiveTag = tag ?? _entries.keys.firstOrNull;
    if (effectiveTag == null) return Future<void>.value();
    final maxIndex =
        _entries[effectiveTag]?.keys.reduce((a, b) => a > b ? a : b) ?? 0;
    return flyTo(
      (_activeIndex + 1) > maxIndex ? 0 : _activeIndex + 1,
      tag: tag,
    );
  }

  Future<void> flyToPrevious({String? tag}) {
    final effectiveTag = tag ?? _entries.keys.firstOrNull;
    if (effectiveTag == null) return Future<void>.value();
    final maxIndex =
        _entries[effectiveTag]?.keys.reduce((a, b) => a > b ? a : b) ?? 0;
    return flyTo(
      (_activeIndex - 1) < 0 ? maxIndex : _activeIndex - 1,
      tag: tag,
    );
  }

  void _register(String tag, int index, _HeroEntry entry) {
    _entries.putIfAbsent(tag, () => {})[index] = entry;
  }

  void _unregister(String tag, int index) {
    _entries[tag]?.remove(index);
    if (_entries[tag]?.isEmpty ?? false) _entries.remove(tag);
  }

  /// An endpoint's rect, in the OVERLAY's coordinate space.
  ///
  /// Not the screen's: the flying entry is positioned inside the
  /// overlay, and an overlay is not always at the screen's origin — one
  /// inside a `Scaffold` body starts below the app bar. Measuring
  /// globally offset every flight by exactly that much.
  static Rect? _rectIn(GlobalKey key, RenderBox? overlayBox) {
    final renderObject = key.currentContext?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.attached) return null;
    return renderObject.localToGlobal(Offset.zero, ancestor: overlayBox) &
        renderObject.size;
  }

  /// The box every rect above is measured against.
  static RenderBox? _overlayBox(OverlayState? overlay) {
    final box = overlay?.context.findRenderObject();
    return box is RenderBox && box.attached ? box : null;
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    // Anything waiting on a landing is released rather than left
    // hanging on a controller that no longer exists.
    _completeFlight();
    super.dispose();
  }
}

// ---------------------------------------------------------------------------
// Internal types
// ---------------------------------------------------------------------------

enum _LayoutMode { visible, measuring, collapsed }

class _HeroEntry {
  _HeroEntry({
    required this.key,
    required this.style,
    required this.parts,
    required this.captureChild,
    required this.setMode,
    required this.overlayState,
    required this.themeData,
    this.decoration,
  });

  final GlobalKey key;
  final ResolvedInPageHeroStyle style;

  /// Live: the endpoint's own map, so a part that arrives after
  /// registration is still found at launch.
  final Map<String, _InPageHeroPartState> parts;
  final Widget Function() captureChild;
  final void Function(_LayoutMode mode, {bool animate}) setMode;
  final OverlayState? overlayState;
  final ThemeData themeData;
  final BoxDecoration? decoration;
}

/// Marks the subtree the flying overlay renders.
///
/// The overlay draws COPIES of both endpoints' children, and a copy is
/// a whole second element tree: an [InPageHero] inside one would
/// register itself with the controller under the same tag and index as
/// the real endpoint, overwrite it, and then unregister on the way out
/// — leaving the real endpoint unregistered and its controller silently
/// inert. A nested hero used to stop working after one flight of the
/// hero around it.
///
/// A copy therefore registers nothing, listens to nothing, and paints
/// its child plainly.
class _HeroFlightScope extends InheritedWidget {
  const _HeroFlightScope({required this.flownParts, required super.child});

  /// The ids the overlay is drawing ITSELF, on top of the box.
  ///
  /// A part in that set must not also paint inside the crossfading
  /// children, or the reader sees it twice.
  final Set<String> flownParts;

  static _HeroFlightScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_HeroFlightScope>();

  static bool isCopy(BuildContext context) => maybeOf(context) != null;

  @override
  bool updateShouldNotify(_HeroFlightScope oldWidget) =>
      !setEquals(oldWidget.flownParts, flownParts);
}

// ---------------------------------------------------------------------------
// InPageHeroPart
// ---------------------------------------------------------------------------

/// Registry an [InPageHero] hands down to the parts inside its child.
class _PartScope extends InheritedWidget {
  const _PartScope({required this.parts, required super.child});

  /// Mutable, and owned by the endpoint's `State` — a part adds itself
  /// on the way in and removes itself on the way out.
  final Map<String, _InPageHeroPartState> parts;

  static Map<String, _InPageHeroPartState>? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_PartScope>()?.parts;

  @override
  bool updateShouldNotify(_PartScope oldWidget) => false;
}

/// A piece INSIDE an [InPageHero] that flies on its own.
///
/// By default the flight crossfades the two endpoints' children whole:
/// the small card's icon dissolves where it is while the large card's
/// icon appears where it will be. That reads fine when the two layouts
/// are close and reads as a blink when a piece has to move a long way.
///
/// Mark the same piece in BOTH children with the same [id] and it
/// becomes one continuous object instead — measured at both ends, drawn
/// on top of the flying box, travelling and scaling its own way across
/// it:
///
/// ```dart
/// InPageHero(
///   tag: 'card', controller: c, index: 0,
///   child: Row(children: [
///     InPageHeroPart(id: 'icon', child: Icon(Icons.image, size: 40)),
///     InPageHeroPart(id: 'title', child: Text('Mountain View')),
///   ]),
/// )
/// ```
///
/// Worth it for a piece that is recognisably the SAME thing at both
/// ends — an icon, an avatar, a thumbnail. An id whose two sides are
/// different content is better left to the crossfade, and so is text
/// that changes size a lot: a flown part is scaled, and scaled text
/// softens.
///
/// An id present in only one of the two children is ignored, and stays
/// in the crossfade.
class InPageHeroPart extends StatefulWidget {
  const InPageHeroPart({
    required this.id,
    required Widget this.child,
    super.key,
  }) : builder = null,
       restingT = 0;

  /// A part built from the flight's PROGRESS, rather than crossfaded
  /// between two finished widgets.
  ///
  /// The crossfade cannot morph: two icon glyphs are filled outlines
  /// with no correspondence between them, so there is nothing to
  /// interpolate — which is why Flutter ships a handful of
  /// pre-authored pairs (`AnimatedIcons.play_pause` and thirteen
  /// others) instead of morphing any icon into any other. A builder
  /// hands the problem to the caller, who knows what their two ends
  /// have in common:
  ///
  /// ```dart
  /// // A REAL morph — the triangle folds into the bars.
  /// InPageHeroPart.morph(
  ///   id: 'play',
  ///   restingT: 0,                       // and 1 at the other end
  ///   builder: (context, t) => AnimatedIcon(
  ///     icon: AnimatedIcons.play_pause,
  ///     progress: AlwaysStoppedAnimation(t),
  ///     size: lerpDouble(32, 96, t),
  ///   ),
  /// )
  ///
  /// // Text at its TRUE size every frame, so it never softens.
  /// InPageHeroPart.morph(
  ///   id: 'title',
  ///   restingT: 0,
  ///   builder: (context, t) => Text(
  ///     'Summit',
  ///     style: TextStyle(fontSize: lerpDouble(16, 34, t)),
  ///   ),
  /// )
  /// ```
  ///
  /// [restingT] is what this END looks like — `0` at one, `1` at the
  /// other, and anything in between for a middle stop. The flight lerps
  /// between the two ends' values, so the same builder serves both.
  ///
  /// A built part is NOT scaled and NOT crossfaded: it is laid out at
  /// whatever size the builder asks for, every frame. Both ends must
  /// use `.morph` for it to apply; a `.morph` facing a plain part falls
  /// back to the crossfade.
  const InPageHeroPart.morph({
    required this.id,
    required this.restingT,
    required Widget Function(BuildContext context, double t) this.builder,
    super.key,
  }) : child = null;

  /// Matched against the same id in the other endpoint.
  final String id;

  final Widget? child;

  /// See [InPageHeroPart.morph].
  final Widget Function(BuildContext context, double t)? builder;

  /// What this end's [builder] is drawn at when nothing is flying.
  final double restingT;

  @override
  State<InPageHeroPart> createState() => _InPageHeroPartState();
}

class _InPageHeroPartState extends State<InPageHeroPart> {
  final GlobalKey _key = GlobalKey();

  /// The endpoint's registry, when this is a real part rather than a
  /// copy inside the overlay.
  Map<String, _InPageHeroPartState>? _scope;

  /// Whether the overlay is drawing this part itself right now.
  bool _flownByOverlay = false;

  /// What the flight draws — the caller's widget, not this wrapper.
  Widget get child => widget.child ?? widget.builder!(context, widget.restingT);

  /// The builder, when this end asked to be built from progress.
  Widget Function(BuildContext, double)? get builder => widget.builder;

  double get restingT => widget.restingT;

  /// Where this part is, in the overlay's coordinate space.
  Rect? rectIn(RenderBox? overlayBox) =>
      InPageHeroController._rectIn(_key, overlayBox);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final flight = _HeroFlightScope.maybeOf(context);
    if (flight != null) {
      // A copy inside the flying box: it registers nothing, and hides
      // itself for exactly as long as the overlay is drawing it.
      _flownByOverlay = flight.flownParts.contains(widget.id);
      return;
    }

    final scope = _PartScope.of(context);
    if (scope != _scope) {
      _scope?.remove(widget.id);
      _scope = scope;
    }
    _scope?[widget.id] = this;
  }

  @override
  void didUpdateWidget(InPageHeroPart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id) {
      _scope?.remove(oldWidget.id);
      _scope?[widget.id] = this;
    }
  }

  @override
  void dispose() {
    // Only if it is still OURS: a rebuilt endpoint may have replaced it.
    if (_scope?[widget.id] == this) _scope?.remove(widget.id);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => KeyedSubtree(
    key: _key,
    // Hidden but still SIZED: the layout around it must not close up
    // while the overlay carries it.
    child: Visibility(
      visible: !_flownByOverlay,
      maintainSize: true,
      maintainAnimation: true,
      maintainState: true,
      child: child,
    ),
  );
}

/// What the overlay is waiting for: where the box is going, and which
/// parts it is carrying separately.
@immutable
class _FlightPlan {
  const _FlightPlan({required this.rect, required this.parts});

  final Rect rect;
  final Map<String, _PartFlight> parts;
}

/// One part's journey, measured at both ends.
@immutable
class _PartFlight {
  const _PartFlight({
    required this.fromRect,
    required this.toRect,
    required this.fromChild,
    required this.toState,
    this.morph,
    this.fromT = 0,
    this.toT = 1,
  });

  /// Set when BOTH ends asked to be built from progress — then there is
  /// no crossfade and no scaling: the builder is called every frame
  /// with the value between the two ends.
  final Widget Function(BuildContext, double)? morph;

  final double fromT;
  final double toT;

  final Rect fromRect;

  /// Where the target part was when the flight was planned — the
  /// fallback for [liveToRect].
  final Rect toRect;

  final Widget fromChild;

  /// The target part itself, so its rect can be read EVERY FRAME.
  ///
  /// The source is giving up its space underneath, so everything below
  /// it moves while the flight runs — including the endpoint this part
  /// is flying into. Flying to the rect measured at launch landed the
  /// part exactly one source-height low and then snapped it into place;
  /// and only in one direction, because collapsing the source only
  /// moves what is BELOW it.
  final _InPageHeroPartState toState;

  Widget get toChild => toState.child;

  Rect liveToRect(RenderBox? overlayBox) =>
      toState.rectIn(overlayBox) ?? toRect;
}

// ---------------------------------------------------------------------------
// InPageHero widget
// ---------------------------------------------------------------------------

/// Marks a widget as an endpoint for an in-page hero flight.
///
/// The [decoration] is lerped during flight for smooth color/radius transitions.
/// Inactive endpoints smoothly collapse their space via [AnimatedSize].
class InPageHero extends StatefulWidget {
  const InPageHero({
    super.key,
    required this.tag,
    required this.controller,
    required this.child,
    this.index = 0,
    this.style,
    this.decoration,
    this.maintainSpace = false,
  });

  final String tag;
  final InPageHeroController controller;
  final Widget child;
  final int index;

  /// The caller's half of `caller > GlobalInPageHeroTheme.style >
  /// InPageHeroStyle.defaults`.
  final InPageHeroStyle? style;
  final BoxDecoration? decoration;

  /// When true, this endpoint keeps its layout space even when inactive
  /// (invisible but sized). When false (default), inactive endpoints
  /// smoothly collapse via [AnimatedSize].
  final bool maintainSpace;

  @override
  State<InPageHero> createState() => _InPageHeroState();
}

class _InPageHeroState extends State<InPageHero>
    with SingleTickerProviderStateMixin {
  final GlobalKey _heroKey = GlobalKey();
  late _LayoutMode _mode;
  bool _registered = false;

  /// The `InPageHeroPart`s inside this endpoint's child, by id.
  final Map<String, _InPageHeroPartState> _parts = {};

  /// Resolved in `didChangeDependencies`, never in `initState`: the
  /// theme and the reader's reduce-motion setting are inherited reads,
  /// and the size controller's duration comes from them.
  late ResolvedInPageHeroStyle _style;

  /// The space collapse, driven by hand rather than by `AnimatedSize` —
  /// which mutates layout during the flight and throws.
  /// Whether this endpoint holds its space right now.
  ///
  /// `maintainSpace` keeps it whether or not it is the active one —
  /// and it has to be answered HERE as well as in `_setMode`, or the
  /// flag is ignored until something moves: the first build collapsed
  /// the inactive endpoint anyway, and a grid meant to keep its cells
  /// closed up until its first flight.
  bool get _holdsSpace =>
      widget.maintainSpace || widget.controller.activeIndex == widget.index;

  late final AnimationController _sizeCtrl = AnimationController(
    vsync: this,
    value: _holdsSpace ? 1.0 : 0.0,
  );

  late final Animation<double> _sizeFactor = CurvedAnimation(
    parent: _sizeCtrl,
    curve: Curves.linear,
  );

  @override
  void initState() {
    super.initState();
    // A copy detaches in `didChangeDependencies`, which runs before the
    // first build — the listener here is harmless until then.
    widget.controller.addListener(_onControllerChanged);
    _mode = widget.controller.activeIndex == widget.index
        ? _LayoutMode.visible
        // Sized but unpainted, rather than gone.
        : (widget.maintainSpace
              ? _LayoutMode.measuring
              : _LayoutMode.collapsed);
  }

  /// Whether this is the copy the flying overlay is drawing.
  bool _isCopy = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _style = (widget.style ?? const InPageHeroStyle()).resolve(context);
    _sizeCtrl.duration = _style.duration;

    _isCopy = _HeroFlightScope.isCopy(context);
    if (_isCopy) return;

    if (!_registered) {
      _registered = true;
      _register();
    }
  }

  @override
  void didUpdateWidget(InPageHero oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tag != widget.tag ||
        oldWidget.index != widget.index ||
        oldWidget.style != widget.style ||
        oldWidget.controller != widget.controller) {
      _unregister(oldWidget);
      if (oldWidget.controller != widget.controller) {
        oldWidget.controller.removeListener(_onControllerChanged);
        widget.controller.addListener(_onControllerChanged);
      }
      _register();
    }
  }

  @override
  void dispose() {
    _sizeCtrl.dispose();
    if (!_isCopy) {
      _unregister(widget);
      widget.controller.removeListener(_onControllerChanged);
    }
    super.dispose();
  }

  void _setMode(_LayoutMode mode, {bool animate = true}) {
    if (!mounted) return;

    final effectiveMode =
        (widget.maintainSpace && mode == _LayoutMode.collapsed)
        ? _LayoutMode.measuring
        : mode;

    final shouldExpand = effectiveMode != _LayoutMode.collapsed;

    if (animate) {
      if (shouldExpand) {
        _sizeCtrl.forward();
      } else {
        _sizeCtrl.reverse();
      }
    } else {
      // Instant — jump to target value
      _sizeCtrl.value = shouldExpand ? 1.0 : 0.0;
    }

    if (_mode != effectiveMode) {
      setState(() => _mode = effectiveMode);
    }
  }

  void _register() {
    widget.controller._register(
      widget.tag,
      widget.index,
      _HeroEntry(
        key: _heroKey,
        style: _style,
        parts: _parts,
        captureChild: () => widget.child,
        setMode: _setMode,
        overlayState: Overlay.maybeOf(context),
        themeData: Theme.of(context),
        decoration: widget.decoration,
      ),
    );
  }

  void _unregister(InPageHero w) {
    w.controller._unregister(w.tag, w.index);
  }

  void _onControllerChanged() {
    if (!mounted || _isCopy) return;
    if (widget.controller.isFlying) return;

    final isActive = widget.controller.activeIndex == widget.index;
    final newMode = isActive
        ? _LayoutMode.visible
        : (widget.maintainSpace
              ? _LayoutMode.measuring
              : _LayoutMode.collapsed);

    _setMode(newMode, animate: true);
  }

  Widget _buildChild() {
    final child = widget.decoration != null
        ? DecoratedBox(decoration: widget.decoration!, child: widget.child)
        : widget.child;
    // The parts inside register into THIS endpoint's map. A copy in the
    // overlay provides no scope, so its parts find none and register
    // nowhere.
    return _isCopy ? child : _PartScope(parts: _parts, child: child);
  }

  @override
  Widget build(BuildContext context) {
    // A copy is already inside the box that is flying: it has no space
    // to collapse and nothing to measure, so it just draws.
    if (_isCopy) return _buildChild();

    // Child is ALWAYS laid out at full natural size (for GlobalKey measurement).
    // Visibility controls whether it's painted.
    // The Align+ClipRect wrapper controls how much space it takes in the parent.
    final isVisible = _mode == _LayoutMode.visible;

    final child = KeyedSubtree(
      key: _heroKey,
      child: Visibility(
        visible: isVisible,
        maintainSize: true,
        maintainAnimation: true,
        maintainState: true,
        child: _buildChild(),
      ),
    );

    // Animated space collapse/expand in BOTH dimensions.
    // sizeFactor 1.0 = full space, 0.0 = zero space.
    // Child is always full-size inside (for measurement), just clipped.
    return AnimatedBuilder(
      animation: _sizeFactor,
      child: child,
      builder: (_, child) {
        // The curve is applied HERE rather than in a `CurvedAnimation`
        // built in `initState`: the bag it comes from is a theme read,
        // which `initState` cannot make.
        final factor = _style.curve
            .transform(_sizeFactor.value.clamp(0.0, 1.0))
            .clamp(0.0, 1.0);
        return ClipRect(
          child: Align(
            alignment: _style.collapseAlignment,
            widthFactor: factor,
            heightFactor: factor,
            child: child,
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// _FlyingWidget — the animated overlay during flight
// ---------------------------------------------------------------------------

class _FlyingWidget extends StatefulWidget {
  const _FlyingWidget({
    required this.fromRect,
    required this.toKey,
    required this.overlay,
    required this.target,
    required this.fromChild,
    required this.toChild,
    required this.fromDecoration,
    required this.toDecoration,
    required this.themeData,
    required this.style,
    required this.onComplete,
  });

  /// Fixed starting rect (measured before flight).
  final Rect fromRect;

  /// Live key to track the target's position as layout shifts.
  final GlobalKey toKey;

  /// What both rects are measured against — the overlay this entry
  /// lives in, which is not necessarily at the screen's origin.
  final OverlayState overlay;

  /// Where it is going, and what it is carrying, once that is known.
  ///
  /// The overlay goes up a frame BEFORE the target has been measured —
  /// it has to, or the source is left painting on its own through a
  /// reflow — so it holds still at [fromRect] until this is set.
  final ValueNotifier<_FlightPlan?> target;

  final Widget fromChild;
  final Widget toChild;
  final BoxDecoration? fromDecoration;
  final BoxDecoration? toDecoration;
  final ThemeData themeData;
  final ResolvedInPageHeroStyle style;
  final VoidCallback onComplete;

  @override
  State<_FlyingWidget> createState() => _FlyingWidgetState();
}

class _FlyingWidgetState extends State<_FlyingWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.style.duration,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: widget.style.curve,
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete();
      }
    });

    widget.target.addListener(_onTargetKnown);
    // It may already be known: a rebuild can arrive after the measure.
    if (widget.target.value != null) _onTargetKnown();
  }

  void _onTargetKnown() {
    if (widget.target.value == null || _controller.isAnimating) return;
    setState(() {});
    _controller.forward();
  }

  @override
  void dispose() {
    widget.target.removeListener(_onTargetKnown);
    _controller.dispose();
    super.dispose();
  }

  /// A circle, expressed as the radius that DRAWS one at [size].
  ///
  /// `BoxDecoration.lerp` cannot cross a `shape` and a `borderRadius` —
  /// the result would carry both, which asserts — so a circle has to
  /// become a radius first. It used to become a huge fixed number, and
  /// that made the morph look instant: a radius is CLAMPED to half the
  /// box when painted, so anything above 36 on a 72-point box draws the
  /// same circle. Lerping 9999 → 0 stays above the clamp for nine
  /// tenths of the flight and then squares off in a frame or two.
  ///
  /// Half the shortest side is the radius that means "circle" at the
  /// size being drawn, so the lerp is linear in what the reader sees.
  BoxDecoration _asRadius(BoxDecoration? dec, Size size) {
    if (dec == null) return const BoxDecoration();
    if (dec.shape != BoxShape.circle) return dec;
    return dec.copyWith(
      shape: BoxShape.rectangle,
      borderRadius: BorderRadius.circular(size.shortestSide / 2),
    );
  }

  /// Where it is heading THIS frame.
  ///
  /// Live, because the source is giving up its space underneath and
  /// everything below it moves while the flight runs. Before the target
  /// is known it is the source's own rect, which is what keeps the
  /// overlay still for the one frame it is up early.
  Rect _getLiveToRect() {
    final plan = widget.target.value;
    if (plan == null) return widget.fromRect;
    return InPageHeroController._rectIn(
          widget.toKey,
          InPageHeroController._overlayBox(widget.overlay),
        ) ??
        plan.rect;
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: widget.themeData,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, _) {
          final t = _animation.value;

          // Track the target's LIVE position (layout shifts as AnimatedSize runs)
          final toRect = _getLiveToRect();

          // Lerp from fixed start to live target
          final rect = Rect.lerp(widget.fromRect, toRect, t)!;

          // Both ends are expressed at the size being DRAWN, so a
          // circle stays a circle while the box resizes and a
          // circle-to-square morph is linear in what is seen.
          final fromDec = _asRadius(widget.fromDecoration, rect.size);
          final toDec = _asRadius(widget.toDecoration, rect.size);
          var decoration = BoxDecoration.lerp(fromDec, toDec, t);

          // Add flight shadow
          if (widget.style.flightShadow != null) {
            decoration = decoration?.copyWith(
              boxShadow: widget.style.flightShadow,
            );
          }

          // The content swaps in the MIDDLE of the flight, where the
          // box is neither endpoint's size and the swap is hidden.
          final crossfadeT = widget.style.crossfadeAt(t);

          final parts = widget.target.value?.parts ?? const {};

          final box = Positioned(
            left: rect.left,
            top: rect.top,
            width: rect.width,
            height: rect.height,
            child: Material(
              type: MaterialType.transparency,
              child: DecoratedBox(
                decoration: decoration ?? const BoxDecoration(),
                child: ClipRect(
                  child: Stack(
                    clipBehavior: Clip.hardEdge,
                    children: [
                      // Each child rendered at its natural measured size,
                      // aligned top-center. ClipRect clips overflow.
                      // KEYED, so the outgoing and incoming children
                      // never share an element slot: without this the
                      // second inherits the first's State the moment
                      // the first is dropped — and a nested hero
                      // arrives at `didUpdateWidget` with a changed
                      // index, un-registering the real endpoint.
                      if (crossfadeT < 1.0)
                        Positioned.fill(
                          key: const ValueKey('from'),
                          child: Opacity(
                            opacity: 1.0 - crossfadeT,
                            child: Align(
                              alignment: widget.style.collapseAlignment,
                              child: UnconstrainedBox(
                                clipBehavior: Clip.hardEdge,
                                alignment: Alignment.topCenter,
                                child: SizedBox(
                                  width: widget.fromRect.width,
                                  height: widget.fromRect.height,
                                  child: widget.fromChild,
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (crossfadeT > 0.0)
                        Positioned.fill(
                          key: const ValueKey('to'),
                          child: Opacity(
                            opacity: crossfadeT,
                            child: Align(
                              alignment: widget.style.collapseAlignment,
                              child: UnconstrainedBox(
                                clipBehavior: Clip.hardEdge,
                                alignment: Alignment.topCenter,
                                child: SizedBox(
                                  width: toRect.width,
                                  height: toRect.height,
                                  child: widget.toChild,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );

          return Positioned.fill(
            // Everything under here is a COPY, and the parts named in
            // `flownParts` are being drawn by this overlay instead —
            // so they hide themselves inside the children below.
            child: _HeroFlightScope(
              flownParts: parts.keys.toSet(),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  box,
                  // ON TOP of the box, each travelling and scaling its
                  // own way across it.
                  for (final part in parts.values)
                    _buildPart(part, t, crossfadeT),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// One part, mid-journey.
  ///
  /// It crossfades on the SAME curve as the children underneath, so a
  /// part whose two sides differ swaps at the moment the rest of the
  /// card does — and one whose sides match simply appears to travel.
  Widget _buildPart(_PartFlight part, double t, double crossfade) {
    // LIVE, for the same reason the box tracks its own target: the
    // endpoint this part is flying into is still moving.
    final toRect = part.liveToRect(
      InPageHeroController._overlayBox(widget.overlay),
    );
    final rect = Rect.lerp(part.fromRect, toRect, t)!;

    // SCALED to the box it is passing through rather than re-laid out:
    // a 40-point icon growing to 80 is exactly a scale, and re-laying
    // out mid-flight would reflow the thing being animated.
    Widget scaled(Widget child, Size natural) => FittedBox(
      fit: BoxFit.contain,
      child: SizedBox(
        width: natural.width,
        height: natural.height,
        child: child,
      ),
    );

    final morph = part.morph;
    return Positioned(
      left: rect.left,
      top: rect.top,
      width: rect.width,
      height: rect.height,
      child: Material(
        type: MaterialType.transparency,
        child: morph != null
            // Built at its TRUE size every frame — no scaling to soften
            // it and no second copy to read through.
            ? Center(
                child: morph(
                  context,
                  lerpDouble(part.fromT, part.toT, t)!,
                ),
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  if (crossfade < 1)
                    Opacity(
                      opacity: 1 - crossfade,
                      child: scaled(part.fromChild, part.fromRect.size),
                    ),
                  if (crossfade > 0)
                    Opacity(
                      opacity: crossfade,
                      child: scaled(part.toChild, toRect.size),
                    ),
                ],
              ),
      ),
    );
  }
}
