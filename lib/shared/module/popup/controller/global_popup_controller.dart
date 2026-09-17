import 'dart:async';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show SemanticsService, Assertiveness;

import '../../../../core/keyboard/keyboard_observer.dart';
import '../../../../core/keyboard/keyboard_scope.dart';
import '../models/popup_models.dart';
import '../theme/popup_theme.dart';
import 'flip_animator.dart';
import 'overlay_builder.dart';
import 'placement_engine.dart';
import 'resolved_options.dart';

export '../models/popup_models.dart';

/// Builder signature for [GlobalPopupController.show].
typedef GlobalPopupBuilder =
    Widget Function(
      BuildContext context,
      GlobalPopupLayout layout,
    );

/// Anchor-bound overlay with built-in keyboard-aware repositioning,
/// configurable close-on-scroll, and smooth side flipping.
///
/// Reusable across `GlobalTextFormField` suggestions, `GlobalDropdown`,
/// `GlobalPopupMenu`, etc.
///
/// **Internal architecture** (single file by design — see CLAUDE.md):
///
/// - **Placement engine** — `_recomputeLayout` picks side + maxHeight
///   based on space above/below and keyboard inset.
/// - **Flip animator** — `_animateFlip` runs reverse → side-swap →
///   forward when the chosen side changes. Anti-flicker invariants
///   live here (`_flipInProgress` guard, post-frame paint wait).
/// - **Keyboard observer** — subscribes to a [KeyboardObserver]
///   when [GlobalKeyboardScope] is mounted. Falls back to
///   `MediaQuery.viewInsets.bottom` polling otherwise.
/// - **Listeners** — scroll position, WidgetsBinding metrics, ModalRoute
///   change. All detach on `hide`.
///
/// ```dart
/// final ctrl = GlobalPopupController();
/// ctrl.show(
///   context: context,
///   anchorContext: _fieldContext,
///   link: _link,
///   builder: (ctx, layout) => MySurface(maxHeight: layout.maxHeight),
///   options: const GlobalPopupOptions(closeOnScroll: false),
/// );
/// ```
class GlobalPopupController extends ChangeNotifier {
  GlobalPopupController();

  /// Global LIFO of currently-open controllers. Used by tap-outside
  /// + Escape-key handlers to only dismiss the TOP popup so a tap
  /// inside an inner popup doesn't also dismiss the outer one that
  /// spawned it.
  static final List<GlobalPopupController> _openStack = [];

  bool get _isTopMost =>
      _openStack.isNotEmpty && identical(_openStack.last, this);

  OverlayEntry? _entry;
  AnimationController? _animController;
  GlobalPopupBuilder? _builder;
  GlobalPopupOptions _options = const GlobalPopupOptions();

  /// Type-safe snapshot of [_options] after `_materialize`. Internal
  /// reads can use `_resolved.foo` (non-null, compiler-checked)
  /// instead of `_options.foo!` (nullable, asserted at debug-time).
  ResolvedPopupOptions? _resolved;
  BuildContext? _anchorContext;
  LayerLink? _link;

  /// Captured tap position when [GlobalPopupOptions.placement] is
  /// `atTap`. When non-null, the overlay positions absolutely at this
  /// global offset instead of following the anchor's `LayerLink`.
  Offset? _anchorPoint;
  GlobalPopupLayout? _layout;
  ScrollPosition? _scrollPosition;
  _MetricsListener? _metricsListener;
  ModalRoute<dynamic>? _route;
  AnimationStatusListener? _routeStatusListener;
  bool _disposed = false;
  double _lastObservedKeyboard = 0;
  bool _recomputeScheduled = false;
  late final PopupOverlayBuilder _overlayBuilder = PopupOverlayBuilder(
    options: () => _options,
    layoutGetter: () => _layout,
    linkGetter: () => _link,
    animControllerGetter: () => _animController,
    builderGetter: () => _builder,
    anchorPointGetter: () => _anchorPoint,
    overlayThemeGetter: () => _overlayTheme,
    overlayDirectionGetter: () => _overlayDirection,
    contentSizeKey: _contentSizeKey,
    measuredContentHeightGetter: () => _measuredContentHeight,
    measuredContentHeightSetter: (h) => _measuredContentHeight = h,
    liveClampShift: _liveClampShift,
    clampShiftReporter: (dx) {
      // Reported as a TOTAL — the drift already applied plus whatever
      // the clamp added on top — so once it is folded into the layout
      // the next report equals the stored value and this settles
      // instead of ping-ponging.
      if (_clampShiftX != null && (_clampShiftX! - dx).abs() < 0.5) return;
      _clampShiftX = dx;
      if (!_recomputeScheduled) _scheduleRecompute();
    },
    lastObservedKeyboardGetter: () => _lastObservedKeyboard,
    lastObservedKeyboardSetter: (v) => _lastObservedKeyboard = v,
    recomputeScheduledGetter: () => _recomputeScheduled,
    scheduleRecompute: _scheduleRecompute,
    scheduleLayoutAfterFrame: _scheduleLayoutAfterFrame,
    hide: hide,
    isTopMost: () => _isTopMost,
  );
  late final FlipAnimator _flip = FlipAnimator(
    options: () => _options,
    controller: () => _animController,
    anchorContext: () => _anchorContext,
    isEntryAttached: () => _entry != null,
    markNeedsBuild: () => _entry?.markNeedsBuild(),
    getLayout: () => _layout,
    setLayout: (l) => _layout = l,
    recomputeLayout: ({bool isFlipping = false}) =>
        _recomputeLayout(isFlipping: isFlipping),
  );
  bool get _flipInProgress => _flip.inProgress;

  // ─── Native keyboard observer integration ────────────────────
  // Reads `PlatformDispatcher.views.first.viewInsets.bottom` directly so
  // it works regardless of the host Scaffold's `resizeToAvoidBottomInset`
  // setting (Scaffold mutates MediaQuery, never the underlying view).
  KeyboardObserver? _kbObserver;
  VoidCallback? _kbListener;

  /// Latest measured intrinsic height of the popup body, reported by a
  /// `SizeChangedLayoutNotifier` wrapping the builder output. Only
  /// populated when `animateContentSize` is enabled — used by
  /// `_recomputeLayout` to flip sides when growing content outruns the
  /// current side's budget.
  double? _measuredContentHeight;

  /// Sideways correction reported by `_ScreenClampX` once an
  /// intrinsic-width surface has measured itself. Held here so the next
  /// placement can fold it into `followerOffset`, which is what the
  /// arrow reads.
  double? _clampShiftX;

  /// Same correction as [_clampShiftX], published during the layout
  /// pass that measures it rather than the frame after — the arrow
  /// reads this so it never slides into place after the fact.
  final ValueNotifier<double> _liveClampShift = ValueNotifier(0);

  /// Stable key on the inner `SizeChangedLayoutNotifier` so the
  /// `NotificationListener.onNotification` callback can resolve the
  /// notifier's RenderBox + read its current size without rebuilding
  /// the key each frame.
  final GlobalKey _contentSizeKey = GlobalKey();

  /// Optional Theme snapshot from the anchor's context. The overlay
  /// inserts into the nearest `Overlay` ancestor which may live outside
  /// any local `Theme(data: ...)` wrapper around the anchor — without
  /// this snapshot, surfaces reading theme via `Theme.of` or
  /// `GlobalPopupTheme.maybeOf` would see the wrong ambient theme.
  ThemeData? _overlayTheme;

  /// Ambient text direction at the anchor, captured at `show()`.
  /// The overlay paints in the host `Overlay` (typically the root
  /// Navigator) where the ambient Directionality is LTR. A demo
  /// wrapping ITS subtree in `Directionality(textDirection: rtl)`
  /// doesn't reach the overlay otherwise — so we re-apply it on the
  /// overlay subtree from this captured value.
  TextDirection? _overlayDirection;

  /// Caller-managed state preserved across side flips when
  /// [GlobalPopupOptions.preserveStateOnFlip] is `true`. Builders can
  /// read/write this to restore scroll position, selection, etc.
  Object? preservedState;

  bool get isOpen => _entry != null;

  GlobalPopupLayout? get layout => _layout;

  /// Open the overlay anchored to [anchorContext] / [link].
  ///
  /// Pass [overlayTheme] (typically `Theme.of(anchorContext)`) when the
  /// anchor lives under a local `Theme` override — the controller wraps
  /// the overlay subtree with it so surfaces resolve the right theme +
  /// extensions even when the Overlay ancestor is outside the wrap.
  Future<void> show({
    required BuildContext context,
    required BuildContext anchorContext,
    required LayerLink link,
    required GlobalPopupBuilder builder,
    required TickerProvider vsync,
    GlobalPopupOptions options = const GlobalPopupOptions(),
    ThemeData? overlayTheme,

    /// Captured pointer-down global Offset. When non-null AND
    /// `options.placement == atTap`, the controller positions the
    /// overlay absolutely at this coordinate instead of via the
    /// anchor's [LayerLink]. Caller (typically `GlobalPopup` widget)
    /// captures this in its Listener's `onPointerDown`.
    Offset? anchorPoint,
  }) async {
    assert(!_disposed, 'GlobalPopupController used after dispose');
    if (_disposed) return;
    // Materialize options against the active `GlobalPopupTheme` so
    // every nullable field is resolved to a concrete value before
    // anything else touches it. Internal code can then read
    // `_options.foo!` safely.
    final resolved = _materialize(options, anchorContext);
    // When `closeOthersOnOpen` is on (default), force-close any other
    // popups currently in the stack so only this one stays open.
    if (resolved.closeOthersOnOpen! && _openStack.isNotEmpty) {
      // Snapshot the list — `.remove(this)` happens during each hide.
      final toClose = _openStack
          .where((c) => !identical(c, this))
          .toList(growable: false);
      for (final other in toClose) {
        unawaited(other.hide(immediate: true));
      }
    }
    if (_entry != null) {
      // Already open → refresh layout instead of double-inserting.
      _builder = builder;
      _options = resolved;
      _resolved = ResolvedPopupOptions(resolved);
      _recomputeLayout();
      _entry?.markNeedsBuild();
      return;
    }

    _builder = builder;
    _options = resolved;
    _resolved = ResolvedPopupOptions(resolved);
    _anchorContext = anchorContext;
    _link = link;
    _anchorPoint = resolved.placement == GlobalPopupPlacement.atTap
        ? anchorPoint
        : null;
    _overlayTheme = overlayTheme;
    _overlayDirection = Directionality.maybeOf(anchorContext);

    _animController = AnimationController(
      vsync: vsync,
      duration: resolved.animationDuration!,
    );

    _recomputeLayout();
    _attachScrollListener();
    _attachMetricsListener();
    _attachRouteListener(context);
    _attachKeyboardListener(anchorContext);

    // Always use the NEAREST Overlay (rootOverlay: false). When the
    // anchor lives inside an `GlobalPopupScope`, the overlay paints
    // inside it — so Scaffold's FAB, app bar, shaders, etc. that wrap
    // the scope can paint over the overlay. With no scope present this
    // resolves to the Navigator's root Overlay (existing behavior).
    final overlay = Overlay.of(anchorContext, rootOverlay: false);
    _entry = OverlayEntry(builder: _build);
    overlay.insert(_entry!);
    _openStack.add(this);
    // Live-region announce so screen-readers report the popup opening.
    _announce(_resolved!.openSemanticLabel, anchorContext);
    // Fire the lifecycle open hook here (post-insert) so listeners
    // see a consistent post-open state. Caller routes that bypass
    // `GlobalPopup._open` (direct imperative `show()`) would otherwise
    // skip the hook entirely.
    resolved.hooks?.onOpen?.call();
    notifyListeners();
    await _animController!.forward();
  }

  /// Close the overlay.
  Future<void> hide({bool immediate = false}) async {
    if (_entry == null) return;
    _announce(_resolved!.closeSemanticLabel, _anchorContext);
    _detachScrollListener();
    _detachMetricsListener();
    _detachRouteListener();
    _detachKeyboardListener();

    if (!immediate && _animController != null) {
      try {
        await _animController!.reverse();
      } catch (e, st) {
        // Widget unmounted mid-animation — non-fatal. Log in debug
        // so unexpected throws surface in DevTools.
        if (kDebugMode) {
          debugPrint('[GlobalPopup] hide() reverse swallowed: $e\n$st');
        }
      }
    }

    // Guard against double-remove (e.g. anchor unmount races with an
    // in-flight close). `OverlayEntry.remove` throws if called twice
    // and there is no public `isInserted` check.
    final entry = _entry;
    _entry = null;
    _openStack.remove(this);
    if (entry != null) {
      try {
        entry.remove();
      } catch (_) {
        // Already removed by the framework — safe to ignore.
      }
    }
    _animController?.dispose();
    _animController = null;
    _layout = null;
    _measuredContentHeight = null;
    _clampShiftX = null;
    _liveClampShift.value = 0;
    _anchorPoint = null;
    if (!_resolved!.preserveStateOnFlip) preservedState = null;
    final hooks = _resolved!.hooks;
    _resolved = null;
    // Fire the lifecycle close hook here (post-teardown) so listeners
    // see a consistent post-close state. Caller routes that bypass
    // the widget's `_close` (controller tap-outside, Escape, route
    // change, anchor unmount) would otherwise skip the hook entirely.
    hooks?.onClose?.call();
    notifyListeners();
  }

  /// Recompute layout — call after content size changes (e.g. async results
  /// arrived). Most callers don't need this; layout auto-recomputes on
  /// scroll + metrics.
  void markNeedsLayout() {
    assert(!_disposed, 'GlobalPopupController used after dispose');
    _recomputeLayout();
    _entry?.markNeedsBuild();
  }

  /// Resolve the caller-supplied options against the active
  /// [GlobalPopupTheme] (read from [anchorContext]) and apply the
  /// reduce-motion override when [GlobalPopupOptions.respectReduceMotion]
  /// is on and the platform reports reduced motion. The returned
  /// instance has every themeable field populated.
  /// Fire a live-region announcement for screen readers. Uses the
  /// platform's polite assertiveness so the message queues behind any
  /// currently-speaking content.
  void _announce(String message, BuildContext? ctx) {
    if (ctx == null) return;
    final dir = Directionality.maybeOf(ctx) ?? TextDirection.ltr;
    // ignore: deprecated_member_use
    unawaited(
      SemanticsService.announce(
        message,
        dir,
        assertiveness: Assertiveness.polite,
      ),
    );
  }

  GlobalPopupOptions _materialize(
    GlobalPopupOptions options,
    BuildContext anchorContext,
  ) {
    final theme = GlobalPopupTheme.maybeOf(anchorContext);
    var merged = options.merged(theme);
    final mq = MediaQuery.maybeOf(anchorContext);
    final reduceMotion = mq?.disableAnimations ?? false;
    if (merged.respectReduceMotion! && reduceMotion) {
      merged = merged.copyWith(animation: GlobalPopupAnimation.none);
    }
    // Sanity: `maxHeight` must be >= `minHeight` post-merge. Easy to
    // botch via theme that lowers maxHeight below the project default
    // minHeight without re-tuning both.
    assert(
      merged.maxHeight! >= merged.minHeight!,
      'GlobalPopupOptions.maxHeight (${merged.maxHeight}) is less than '
      'minHeight (${merged.minHeight}). Theme + per-call values need to '
      'be re-tuned together.',
    );
    // Defensive belt: every themeable field must be populated after
    // merge so internal code can safely read `_options.foo!`. If any
    // is still null, [GlobalPopupOptions.defaults] is missing a value
    // — fix the defaults const rather than papering over it here.
    assert(
      merged.animation != null &&
          merged.animationDuration != null &&
          merged.flipAnimationDuration != null &&
          merged.animationCurve != null &&
          merged.closeOnScroll != null &&
          merged.closeOnTapOutside != null &&
          merged.closeOnRouteChange != null &&
          merged.minHeight != null &&
          merged.maxHeight != null &&
          merged.preferAboveThreshold != null &&
          merged.dynamicResizeOnKeyboard != null &&
          merged.preserveStateOnFlip != null &&
          merged.gap != null &&
          merged.screenPadding != null &&
          merged.placement != null &&
          merged.width != null &&
          merged.hoverCloseDelay != null &&
          merged.respectReduceMotion != null &&
          merged.animateContentSize != null &&
          merged.contentSizeAnimationDuration != null &&
          merged.contentSizeAnimationCurve != null &&
          merged.closeOthersOnOpen != null,
      'GlobalPopupOptions.merged left a themeable field null — '
      'GlobalPopupOptions.defaults likely missing that field.',
    );
    return merged;
  }

  /// Push a fresh builder closure / options into the open overlay.
  ///
  /// The controller stores the builder closure passed to [show]. When the
  /// anchor's `State` rebuilds with new data (e.g. parent `setState` adds
  /// list items, toggles a section), the new closure that would capture
  /// the new state never reaches the overlay unless the host calls this.
  ///
  /// `GlobalPopup` wires this from `didUpdateWidget` automatically — only
  /// call manually when driving the controller imperatively.
  ///
  /// Stores the new closure synchronously but defers the overlay rebuild
  /// to the next post-frame callback. `didUpdateWidget` (the typical
  /// caller) runs inside the build phase — calling `markNeedsBuild` on
  /// the overlay there triggers Flutter's "called during build" assert.
  void refresh({
    GlobalPopupBuilder? builder,
    GlobalPopupOptions? options,
  }) {
    if (_entry == null) return;
    if (builder != null) _builder = builder;
    // Re-snapshot the ambient direction + theme from the anchor — both
    // were captured at show() and go stale when the locale (LTR↔RTL)
    // or theme flips while the overlay is open; the entry rebuild
    // below would otherwise re-apply the old values to the subtree.
    final anchor = _anchorContext;
    if (anchor != null && anchor.mounted) {
      _overlayDirection = Directionality.maybeOf(anchor);
      _overlayTheme = Theme.of(anchor);
    }
    if (options != null) {
      // Caller hands us raw widget options — re-run the same
      // theme-merge + reduce-motion materialization that `show()` does
      // so internal `_options.foo!` accesses stay safe.
      final ctx = _anchorContext;
      _options = ctx != null
          ? _materialize(options, ctx)
          : options.merged(null);
      _resolved = ResolvedPopupOptions(_options);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_entry == null) return;
      _recomputeLayout();
      _entry?.markNeedsBuild();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _liveClampShift.dispose();
    _detachScrollListener();
    _detachMetricsListener();
    _detachRouteListener();
    _detachKeyboardListener();
    _entry?.remove();
    _entry = null;
    _animController?.dispose();
    _animController = null;
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════
  // PLACEMENT ENGINE
  // ═══════════════════════════════════════════════════════════════

  void _recomputeLayout({bool isFlipping = false}) {
    // While a flip is in progress, only the internal call from
    // _animateFlip (which passes isFlipping: true) is allowed to
    // mutate _layout. External calls — scroll, metrics, MediaQuery
    // rebuilds — would otherwise swap _layout.isAbove mid-reverse and
    // teleport the overlay to the new side before the reverse animation
    // has played out.
    if (_flipInProgress && !isFlipping) return;

    final ctx = _anchorContext;
    if (ctx == null) return;
    final renderBox = ctx.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.attached) {
      _scheduleAutoCloseIfHidden();
      return;
    }

    final mediaQuery = MediaQuery.maybeOf(ctx);
    if (mediaQuery == null) return;

    final textDir = Directionality.maybeOf(ctx) ?? TextDirection.ltr;
    final anchorTopLeft = renderBox.localToGlobal(Offset.zero);
    final anchorSize = renderBox.size;
    final screenSize = mediaQuery.size;
    final keyboardHeight = _currentKeyboardHeight(mediaQuery);
    final safeBottom = mediaQuery.padding.bottom;
    final safeTop = mediaQuery.padding.top;
    final availableBottom = screenSize.height - keyboardHeight - safeBottom;
    final anchorRect = anchorTopLeft & anchorSize;
    final anchorVisible =
        !(anchorRect.bottom <= safeTop ||
            anchorRect.top >= availableBottom ||
            anchorRect.right <= 0 ||
            anchorRect.left >= screenSize.width);

    var clippedByScrollable = false;
    final scrollable = Scrollable.maybeOf(ctx);
    if (scrollable != null) {
      final vpBox = scrollable.context.findRenderObject() as RenderBox?;
      if (vpBox != null && vpBox.attached) {
        final vpRect = vpBox.localToGlobal(Offset.zero) & vpBox.size;
        clippedByScrollable = !anchorRect.overlaps(vpRect);
      }
    }

    // Pure placement engine — returns one of `PlacementOk` /
    // `PlacementRequestFlip` / `PlacementAutoClose` / `PlacementHardClose`.
    // Controller's role is purely orchestration of side-effects.
    final outcome = computePopupPlacement(
      PlacementInputs(
        anchorTopLeft: anchorTopLeft,
        anchorSize: anchorSize,
        screenSize: screenSize,
        safeTop: safeTop,
        safeBottom: safeBottom,
        keyboardHeight: keyboardHeight,
        textDirection: textDir,
        options: _options,
        currentLayout: _layout,
        measuredContentHeight: _measuredContentHeight,
        measuredClampShiftX: _clampShiftX,
        liveClampShift: _liveClampShift,
        isFlipRecompute: isFlipping,
        flipInProgress: _flipInProgress,
        anchorVisible: anchorVisible,
        clippedByScrollable: clippedByScrollable,
      ),
    );

    switch (outcome) {
      case PlacementOk(:final layout):
        _layout = layout;
      case PlacementRequestFlip(:final toAbove):
        _animateFlip(toAbove: toAbove);
      case PlacementAutoClose():
        _scheduleAutoCloseIfHidden();
      case PlacementHardClose():
        hide();
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // FLIP ANIMATOR — delegated to FlipAnimator (see flip_animator.dart)
  // ═══════════════════════════════════════════════════════════════

  Future<void> _animateFlip({required bool toAbove}) =>
      _flip.run(toAbove: toAbove);

  // ═══════════════════════════════════════════════════════════════
  // KEYBOARD OBSERVER (core/keyboard + MediaQuery fallback)
  // ═══════════════════════════════════════════════════════════════

  /// When a [GlobalKeyboardScope] ancestor is present, subscribe to
  /// its observer for raw view-inset transitions. Otherwise fall back to
  /// MediaQuery polling inside `_buildInner` (works but rebuild-bound).
  void _attachKeyboardListener(BuildContext context) {
    final observer = GlobalKeyboardScope.maybeOf(context);
    if (observer == null) return;
    _kbObserver = observer;
    _kbListener = () {
      if (!isOpen) return;
      _scheduleRecompute();
    };
    _kbObserver!.addListener(_kbListener!);
  }

  void _detachKeyboardListener() {
    if (_kbObserver != null && _kbListener != null) {
      _kbObserver!.removeListener(_kbListener!);
    }
    _kbListener = null;
    _kbObserver = null;
  }

  /// Resolve the effective keyboard height. Prefer the scoped observer
  /// (raw view inset) over MediaQuery (which a parent Scaffold may have
  /// consumed via `resizeToAvoidBottomInset`).
  ///
  /// During the `rising` phase, the observer's `bottomInset` reflects
  /// each intermediate value as the keyboard animates in — for early
  /// flip detection we want to PREDICT the final height. Use
  /// `lastKnownSize` when it's larger than the current reading.
  double _currentKeyboardHeight(MediaQueryData mq) {
    final obs = _kbObserver;
    if (obs != null) {
      if (obs.phase == KeyboardPhase.rising &&
          obs.lastKnownSize > obs.bottomInset) {
        // Predictively use the last final keyboard size so the popup
        // shrinks / flips at the moment the keyboard starts rising,
        // not after it finishes its animation.
        return obs.lastKnownSize;
      }
      if (obs.bottomInset > 0) return obs.bottomInset;
    }
    return mq.viewInsets.bottom;
  }

  // ═══════════════════════════════════════════════════════════════
  // LISTENERS (scroll / metrics / route)
  // ═══════════════════════════════════════════════════════════════

  void _attachScrollListener() {
    final ctx = _anchorContext;
    if (ctx == null) return;
    final scrollable = Scrollable.maybeOf(ctx);
    if (scrollable == null) return;
    _scrollPosition = scrollable.position;
    _scrollPosition?.addListener(_onScroll);
  }

  void _detachScrollListener() {
    _scrollPosition?.removeListener(_onScroll);
    _scrollPosition = null;
  }

  void _onScroll() {
    // Suppress close-on-scroll while the keyboard is animating or up.
    // Two cases:
    //   1. Keyboard is rising → Scaffold's `resizeToAvoidBottomInset`
    //      scrolls its body so the focused field stays visible. That
    //      scroll fires here even though the user did not actually
    //      scroll — popup must not dismiss.
    //   2. Keyboard already up → user lightly nudges scroll while
    //      typing; keyboard-aware popups should track the anchor, not
    //      dismiss.
    // Read the keyboard signal from BOTH sources because Scaffold may
    // have consumed MediaQuery's `viewInsets.bottom` before we see it.
    final ctx = _anchorContext;
    final mq = ctx != null ? MediaQuery.maybeOf(ctx) : null;
    final mqInset = mq?.viewInsets.bottom ?? 0;
    final obsInset = _kbObserver?.bottomInset ?? 0;
    final rawInset = obsInset > mqInset ? obsInset : mqInset;
    final kbActive = rawInset > 0;
    final kbTransition = _kbObserver?.isTransitioning ?? false;
    final suppress =
        _resolved!.dynamicResizeOnKeyboard && (kbActive || kbTransition);

    if (_resolved!.closeOnScroll && !suppress) {
      hide();
      return;
    }
    _scheduleRecompute();
  }

  void _attachMetricsListener() {
    _metricsListener = _MetricsListener(() {
      if (!isOpen) return;
      _scheduleRecompute();
    });
    WidgetsBinding.instance.addObserver(_metricsListener!);
  }

  /// Close the overlay when the anchor has become non-visible. Defer
  /// via post-frame because `_recomputeLayout` may be called from build
  /// — calling `hide()` directly there would mutate state mid-build.
  void _scheduleAutoCloseIfHidden() {
    if (!isOpen || _flipInProgress) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!isOpen) return;
      hide();
    });
  }

  /// Defer layout recompute to the next frame so anchor render box and
  /// MediaQuery have settled (matters most when keyboard rises — both
  /// the anchor position and viewInsets change in the same frame).
  void _scheduleRecompute() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!isOpen) return;
      _recomputeLayout();
      _entry?.markNeedsBuild();
    });
  }

  /// Schedule exactly one post-frame layout pass. Used by the reactive
  /// MediaQuery path so the anchor's *new* position (after Scaffold
  /// re-laid itself for the keyboard) is read AFTER this frame's layout
  /// has settled.
  void _scheduleLayoutAfterFrame() {
    if (_recomputeScheduled) return;
    _recomputeScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _recomputeScheduled = false;
      if (!isOpen) return;
      final before = _layout;
      _recomputeLayout();
      if (_layout != null &&
          before != null &&
          (before.isAbove != _layout!.isAbove ||
              before.maxHeight != _layout!.maxHeight ||
              before.width != _layout!.width)) {
        _entry?.markNeedsBuild();
      } else if (before == null && _layout != null) {
        _entry?.markNeedsBuild();
      }
    });
  }

  void _detachMetricsListener() {
    if (_metricsListener != null) {
      WidgetsBinding.instance.removeObserver(_metricsListener!);
      _metricsListener = null;
    }
  }

  void _attachRouteListener(BuildContext context) {
    if (!_resolved!.closeOnRouteChange) return;
    _route = ModalRoute.of(context);
    if (_route == null) return;
    // Hold the AnimationStatusListener instance so `_detachRouteListener`
    // can remove it. Anonymous closures couldn't be removed → the
    // listener stayed bound to the route's animation after the popup
    // closed, holding the controller (and its `hide` closure) alive.
    _routeStatusListener = (_) {
      if (!(_route?.isCurrent ?? true)) hide();
    };
    _route!.animation?.addStatusListener(_routeStatusListener!);
  }

  void _detachRouteListener() {
    if (_route != null && _routeStatusListener != null) {
      _route!.animation?.removeStatusListener(_routeStatusListener!);
    }
    _route = null;
    _routeStatusListener = null;
  }

  // ═══════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════

  /// Builds the overlay subtree via [PopupOverlayBuilder]. The
  /// extracted builder owns backdrop / tap-outside catcher /
  /// anchored content / escape trap so the controller stays
  /// focused on lifecycle + listeners.
  Widget _build(BuildContext context) => _overlayBuilder.build(context);
}

/// Internal: forwards `didChangeMetrics` to a callback.
class _MetricsListener with WidgetsBindingObserver {
  _MetricsListener(this.onChange);
  final VoidCallback onChange;
  @override
  void didChangeMetrics() => onChange();
}

// ─────────────────────────────────────────────────────────────────────
// GlobalPopupScope — local Overlay wrapper
// ─────────────────────────────────────────────────────────────────────

/// Defines a local `Overlay` scope. Drop anywhere in your widget tree
/// to control where overlays opened with the popup controller paint.
///
/// Use it to make the overlay participate in ancestor paint effects
/// (ShaderMask edge-fades, ClipRect, RepaintBoundary, …) instead of
/// floating over the root Navigator overlay.
/// Stateful on purpose: `Overlay` reads `initialEntries` ONCE (its own
/// State keeps the list), so a scope that builds a fresh `OverlayEntry`
/// per rebuild would leave the LIVE entry holding a closure over the
/// first-ever `child` — ancestor rebuilds (new props, locale-driven
/// reconfiguration) would silently never reach the subtree. One cached
/// entry whose builder reads `widget.child`, nudged with
/// `markNeedsBuild` on updates, keeps the child element (and its state)
/// continuous.
class GlobalPopupScope extends StatefulWidget {
  const GlobalPopupScope({super.key, required this.child});

  final Widget child;

  @override
  State<GlobalPopupScope> createState() => _GlobalPopupScopeState();
}

class _GlobalPopupScopeState extends State<GlobalPopupScope> {
  late final OverlayEntry _entry = OverlayEntry(builder: (_) => widget.child);

  @override
  void didUpdateWidget(covariant GlobalPopupScope old) {
    super.didUpdateWidget(old);
    if (old.child != widget.child) _entry.markNeedsBuild();
  }

  // NOTE: the entry is deliberately NOT disposed. `OverlayState` never
  // detaches its entries on unmount (`_overlay` stays set), so
  // `OverlayEntry.dispose` can't legally run for an entry hosted by our
  // own child Overlay — and `remove()` would hit the already-disposed
  // OverlayState. The entry simply dies with the subtree.

  @override
  Widget build(BuildContext context) => Overlay(initialEntries: [_entry]);
}
