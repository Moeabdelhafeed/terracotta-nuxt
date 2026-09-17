import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show Ticker, TickerCallback;
import 'package:flutter/services.dart';

import '../tooltip/global_tooltip.dart';
import 'controller/global_popup_controller.dart';
import 'surfaces/popup_surfaces.dart';

/// Declarative wrapper around [GlobalPopupController]. Handles
/// LayerLink / GlobalKey / TickerProvider boilerplate + trigger wiring +
/// auto-disposal. Use this for 90% of cases; reach for the controller
/// directly only when you need fine-grained imperative control.
///
/// ```dart
/// GlobalPopup(
///   trigger: GlobalPopupTrigger.tap,
///   overlay: (ctx, layout) => MyMenu(),
///   child: ElevatedButton(onPressed: () {}, child: const Text('Open')),
/// );
/// ```
class GlobalPopup extends StatefulWidget {
  const GlobalPopup({
    super.key,
    required this.child,
    required this.overlay,
    this.controller,
    this.trigger = GlobalPopupTrigger.tap,
    this.options = const GlobalPopupOptions(),
    this.enabled = true,
    this.anchorFocusNode,
  });

  /// The anchor widget. Tap / hover / focus / etc. fire the trigger.
  final Widget child;

  /// The node the ANCHOR focuses on, for a caller that wants to paint
  /// its own focus state.
  ///
  /// A `tap`-triggered anchor is a tab stop — the popup owns the key
  /// handling, so the trigger widget cannot see its own focus without
  /// this. The toggle group's collapsed "+N" needs it: with no tap
  /// handler of its own it has no `InkWell` focus to paint from.
  final FocusNode? anchorFocusNode;

  /// Builds the overlay surface. Receives the resolved [GlobalPopupLayout].
  final GlobalPopupBuilder overlay;

  /// Optional caller-supplied controller for imperative show/hide. If
  /// null, a private controller is created + disposed automatically.
  final GlobalPopupController? controller;

  final GlobalPopupTrigger trigger;
  final GlobalPopupOptions options;

  /// When `false`, no trigger fires + any existing overlay hides.
  final bool enabled;

  /// Convenience builder — wraps [trigger] anchor with a popup whose
  /// overlay is a [GlobalPopupMenu]. Use this for the common
  /// "trigger button + menu items" case instead of building the
  /// `overlay:` callback by hand.
  ///
  /// ```dart
  /// GlobalPopup.menu(
  ///   anchor: ElevatedButton(onPressed: () {}, child: Text('Open')),
  ///   items: [
  ///     GlobalPopupMenuItem(value: 'a', label: 'Apple'),
  ///     GlobalPopupMenuItem(value: 'b', label: 'Banana'),
  ///   ],
  ///   onSelected: (v) => print(v),
  /// );
  /// ```
  static Widget menu<T>({
    Key? key,
    required Widget anchor,
    required List<GlobalPopupMenuItem<T>> items,
    required ValueChanged<T> onSelected,
    GlobalPopupTrigger trigger = GlobalPopupTrigger.tap,
    GlobalPopupOptions options = const GlobalPopupOptions(),
    GlobalPopupSurfaceStyle? menuStyle,
    bool searchable = false,
    String? searchHint,
    String? emptyText,
    // A menu sizes to its CONTENT, not to its anchor.
    //
    // The popup default is `matchAnchor`, and a menu's commonest anchor
    // is an icon button — which gave a 32px-wide surface whose own item
    // rows overflowed it by twenty-odd pixels. The row already
    // `Expanded`s its label; the icon and its gap alone are wider than
    // the anchor. Matching a narrow anchor is never right for a menu.
    //
    // Pass `options: GlobalPopupOptions(width: …)` for the cases where
    // it is — a menu under a wide field that should line up with it.
    bool autoWidth = true,
    double? maxWidth,
    bool enabled = true,
    VoidCallback? onOpen,
    VoidCallback? onClose,
    String? tooltip,
    String? semanticLabel,
  }) {
    // When autoWidth is on, override the popup's width strategy so the
    // controller computes a content-based budget instead of matching
    // the (often narrower) anchor. Without this override, the surface
    // is capped at anchor width before IntrinsicWidth can grow.
    var effectiveOptions = autoWidth
        ? options.copyWith(width: GlobalPopupWidth.content(max: maxWidth))
        : options;
    if (onOpen != null || onClose != null) {
      // Compose lifecycle hooks if caller provided onOpen/onClose without
      // pre-baking a `GlobalPopupHooks` in `options`.
      final existing = effectiveOptions.hooks;
      effectiveOptions = effectiveOptions.copyWith(
        hooks: GlobalPopupHooks(
          onOpen: onOpen ?? existing?.onOpen,
          onClose: onClose ?? existing?.onClose,
          onWillClose: existing?.onWillClose,
        ),
      );
    }
    Widget popup = GlobalPopup(
      key: key,
      trigger: trigger,
      options: effectiveOptions,
      enabled: enabled,
      overlay: (ctx, layout) => GlobalPopupMenuView<T>(
        layout: layout,
        items: items,
        onSelected: onSelected,
        style: menuStyle ?? options.surfaceStyle,
        arrow: options.arrow,
        searchable: searchable,
        searchHint: searchHint,
        emptyText: emptyText,
        autoWidth: autoWidth,
        maxWidth: maxWidth,
      ),
      child: anchor,
    );
    if (tooltip != null) {
      popup = GlobalTooltip(message: tooltip, child: popup);
    }
    if (semanticLabel != null) {
      popup = Semantics(
        button: true,
        label: semanticLabel,
        enabled: enabled,
        child: popup,
      );
    }
    return popup;
  }

  /// Convenience builder wrapping a custom child in a styled panel.
  ///
  /// ```dart
  /// GlobalPopup.panel(
  ///   anchor: OutlinedButton(
  ///     onPressed: () {},
  ///     child: const Text('Filter'),
  ///   ),
  ///   options: const GlobalPopupOptions(
  ///     placement: GlobalPopupPlacement.bottomEnd,
  ///     width: GlobalPopupWidth.fixed(280),
  ///   ),
  ///   child: const FilterForm(),
  /// );
  /// ```
  static Widget panel({
    Key? key,
    required Widget anchor,
    required Widget child,
    GlobalPopupTrigger trigger = GlobalPopupTrigger.tap,
    GlobalPopupOptions options = const GlobalPopupOptions(),
    GlobalPopupSurfaceStyle? style,
    double? maxWidth,
    bool enabled = true,
    FocusNode? anchorFocusNode,
  }) {
    return GlobalPopup(
      key: key,
      trigger: trigger,
      options: options,
      enabled: enabled,
      anchorFocusNode: anchorFocusNode,
      overlay: (ctx, layout) => GlobalPopupPanel(
        layout: layout,
        style: style ?? options.surfaceStyle,
        maxWidth: maxWidth,
        arrow: options.arrow,
        child: child,
      ),
      child: anchor,
    );
  }

  @override
  State<GlobalPopup> createState() => _GlobalPopupState();

  /// Programmatic open at a global [anchor] position — no widget anchor
  /// needed. Use for right-click context menus, cursor-anchored
  /// popovers, or opening at the row of a list item.
  ///
  /// Inserts an `OverlayEntry` directly (no Navigator route) so the
  /// popup paints inside whatever `Overlay` ancestor is closest —
  /// honoring `GlobalPopupScope` for paint-hierarchy control. The
  /// returned `Future<R?>` resolves when caller invokes the
  /// `onSelected: (R) { ... }` callback inside the builder OR the
  /// barrier is tapped (resolves to `null`).
  ///
  /// Use the [GlobalPopupRouteHandle] passed into [builder] to close
  /// programmatically with a value.
  ///
  /// ```dart
  /// final picked = await GlobalPopup.showAt<String>(
  ///   context,
  ///   anchor: details.globalPosition,
  ///   builder: (ctx, route) => GlobalPopupMenuView<String>(
  ///     layout: …,
  ///     items: …,
  ///     onSelected: (v) => route.close(v),
  ///   ),
  /// );
  /// ```
  ///
  /// **Note** — anchor-less programmatic popups don't benefit from
  /// keyboard-aware flip / scrollable-clip dismissal (no RenderBox to
  /// track). Animation, theme cascade, tap-outside, and Escape work.
  static Future<R?> showAt<R>(
    BuildContext context, {
    required Offset anchor,
    required Widget Function(BuildContext, GlobalPopupRouteHandle<R>) builder,
    Size desiredSize = const Size(280, 360),
    Alignment anchorAlignment = Alignment.topLeft,
    bool barrierDismissible = true,
    Color? barrierColor,
    Duration transitionDuration = const Duration(milliseconds: 180),
  }) {
    final completer = Completer<R?>();
    final overlay = Overlay.of(context, rootOverlay: false);
    OverlayEntry? entry;
    late final AnimationController anim;
    // The anchor arrives in GLOBAL coordinates — that is the
    // documented contract — but the entry is inserted into the
    // NEAREST overlay, which in this app is the page's own and does
    // not start at the top-left of the screen. Placing a global point
    // in a local space opened the menu a long way from the finger.
    final overlayBox = overlay.context.findRenderObject();
    final localAnchor = overlayBox is RenderBox && overlayBox.attached
        ? overlayBox.globalToLocal(anchor)
        : anchor;

    final ticker = _ShowAtTickerProvider();
    anim = AnimationController(
      vsync: ticker,
      duration: transitionDuration,
    );

    void close([R? value]) {
      if (completer.isCompleted) return;
      anim.reverse().whenComplete(() {
        if (!completer.isCompleted) completer.complete(value);
        entry?.remove();
        entry = null;
        anim.dispose();
        ticker.dispose();
      });
    }

    final handle = GlobalPopupRouteHandle<R>._(close);
    final ambient = Theme.of(context);
    entry = OverlayEntry(
      builder: (ctx) {
        return Theme(
          data: ambient,
          child: AnimatedBuilder(
            animation: anim,
            builder: (_, _) {
              final t = Curves.easeOutCubic.transform(anim.value);
              return Stack(
                children: [
                  if (barrierDismissible)
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => close(),
                        child: ColoredBox(
                          color: (barrierColor ?? Colors.transparent)
                              .withValues(alpha: (barrierColor?.a ?? 0) * t),
                          child: const SizedBox.expand(),
                        ),
                      ),
                    ),
                  Shortcuts(
                    shortcuts: const <ShortcutActivator, Intent>{
                      SingleActivator(LogicalKeyboardKey.escape):
                          DismissIntent(),
                    },
                    child: Actions(
                      actions: <Type, Action<Intent>>{
                        DismissIntent: CallbackAction<DismissIntent>(
                          onInvoke: (_) {
                            close();
                            return null;
                          },
                        ),
                      },
                      child: Focus(
                        autofocus: true,
                        child: Opacity(
                          opacity: t,
                          child: Transform.scale(
                            scale: 0.96 + 0.04 * t,
                            alignment: anchorAlignment,
                            child: _PositionedPopup(
                              anchor: localAnchor,
                              desiredSize: desiredSize,
                              anchorAlignment: anchorAlignment,
                              child: Builder(
                                builder: (c) => builder(c, handle),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
    overlay.insert(entry!);
    anim.forward();
    return completer.future;
  }

  // Legacy showGeneralDialog path retained for reference — preserved
  // below as `showAtViaDialog` (deprecated). New code should prefer
  // [showAt] above which uses the controller-overlay path.
  static Future<R?> showAtViaDialog<R>(
    BuildContext context, {
    required Offset anchor,
    required WidgetBuilder builder,
    Size desiredSize = const Size(280, 360),
    Alignment anchorAlignment = Alignment.topLeft,
    bool barrierDismissible = true,
    bool useRootNavigator = true,
    Color? barrierColor,
    Duration transitionDuration = const Duration(milliseconds: 180),
  }) {
    return showGeneralDialog<R>(
      context: context,
      useRootNavigator: useRootNavigator,
      barrierDismissible: barrierDismissible,
      barrierLabel: 'popup',
      barrierColor: barrierColor ?? Colors.transparent,
      transitionDuration: transitionDuration,
      pageBuilder: (ctx, _, _) => _PositionedPopup(
        anchor: anchor,
        desiredSize: desiredSize,
        anchorAlignment: anchorAlignment,
        child: Builder(builder: builder),
      ),
      transitionBuilder: (ctx, anim, _, child) {
        return FadeTransition(
          opacity: anim,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1).animate(
              CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
            ),
            alignment: anchorAlignment,
            child: child,
          ),
        );
      },
    );
  }
}

/// Positions [child] near [anchor] with the panel's [anchorAlignment]
/// pinned at the anchor, clamped to an 8 px viewport margin.
class _PositionedPopup extends StatelessWidget {
  const _PositionedPopup({
    required this.anchor,
    required this.desiredSize,
    required this.anchorAlignment,
    required this.child,
  });

  final Offset anchor;
  final Size desiredSize;
  final Alignment anchorAlignment;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final maxW = constraints.maxWidth;
        final maxH = constraints.maxHeight;
        const margin = 8.0;

        final w = desiredSize.width.clamp(0.0, maxW - margin * 2);
        final h = desiredSize.height.clamp(0.0, maxH - margin * 2);

        final fx = (anchorAlignment.x + 1) / 2;
        final fy = (anchorAlignment.y + 1) / 2;

        var left = anchor.dx - w * fx;
        var top = anchor.dy - h * fy;
        left = left.clamp(margin, maxW - w - margin);
        top = top.clamp(margin, maxH - h - margin);

        return Stack(
          children: [
            Positioned(
              left: left,
              top: top,
              width: w,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: h),
                child: child,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GlobalPopupState extends State<GlobalPopup>
    with TickerProviderStateMixin {
  late GlobalPopupController _ctrl;
  bool _ownsController = false;
  final LayerLink _link = LayerLink();
  final GlobalKey _anchorKey = GlobalKey();
  final FocusNode _hoverFocusNode = FocusNode(canRequestFocus: false);
  Timer? _hoverCloseTimer;
  Timer? _hoverOpenTimer;
  Timer? _autoDismissTimer;
  Timer? _longPressTimer;
  Offset? _pointerDownPos;

  /// Last successful tap / long-press location, captured so the
  /// controller can position the overlay at the tap point when
  /// `placement: atTap`. Cleared on close.
  Offset? _lastTapPos;
  static const _tapSlop = 12.0;
  static const _longPressDelay = Duration(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    _attachController();
  }

  @override
  void didUpdateWidget(covariant GlobalPopup old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      _detachController();
      _attachController();
    }
    if (!widget.enabled && _ctrl.isOpen) _ctrl.hide();
    // Forward fresh builder + options into the open overlay so popup
    // contents track parent setState (e.g. stateful demos that grow a
    // list while the popup is shown).
    if (_ctrl.isOpen &&
        (old.overlay != widget.overlay || old.options != widget.options)) {
      _ctrl.refresh(builder: widget.overlay, options: widget.options);
    }
  }

  @override
  void dispose() {
    _hoverCloseTimer?.cancel();
    _hoverCloseTimer = null;
    _hoverOpenTimer?.cancel();
    _hoverOpenTimer = null;
    _autoDismissTimer?.cancel();
    _autoDismissTimer = null;
    _longPressTimer?.cancel();
    _longPressTimer = null;
    _detachController();
    _hoverFocusNode.dispose();
    super.dispose();
  }

  // Listener-based tap detection. Bypasses the gesture arena so it
  // doesn't compete with interactive descendants (ElevatedButton's
  // InkWell, etc.). Both our trigger AND the descendant's onPressed
  // fire — desired for showcase cases where the child looks like a
  // button but the trigger is the wrapper.
  void _onPointerDownTap(PointerDownEvent e) {
    _pointerDownPos = e.position;
  }

  void _onPointerUpTap(PointerUpEvent e) {
    final start = _pointerDownPos;
    _pointerDownPos = null;
    if (start == null) return;
    if ((e.position - start).distance > _tapSlop) return;
    _lastTapPos = e.position;
    _toggle();
  }

  void _onPointerCancelTap(PointerCancelEvent _) {
    _pointerDownPos = null;
  }

  void _onPointerDownLongPress(PointerDownEvent e) {
    _pointerDownPos = e.position;
    _longPressTimer?.cancel();
    _longPressTimer = Timer(_longPressDelay, () {
      if (_pointerDownPos != null) {
        _lastTapPos = _pointerDownPos;
        _open();
      }
    });
  }

  void _onPointerUpLongPress(PointerUpEvent _) {
    _longPressTimer?.cancel();
    _longPressTimer = null;
    _pointerDownPos = null;
  }

  void _onPointerCancelLongPress(PointerCancelEvent _) {
    _longPressTimer?.cancel();
    _longPressTimer = null;
    _pointerDownPos = null;
  }

  void _attachController() {
    _ctrl = widget.controller ?? GlobalPopupController();
    _ownsController = widget.controller == null;
  }

  void _detachController() {
    if (_ownsController) _ctrl.dispose();
  }

  // ─── Trigger handlers ────────────────────────────────────────

  Future<void> _open() async {
    if (!widget.enabled || _ctrl.isOpen) return;
    final anchorCtx = _anchorKey.currentContext;
    if (anchorCtx == null) return;

    // Controller handles theme merge + reduce-motion override internally
    // (`_materialize`) AND fires the `onOpen` / `onClose` hooks so every
    // open path — widget trigger, imperative `show()`, controller
    // reuse — runs lifecycle consistently.
    await _ctrl.show(
      context: context,
      anchorContext: anchorCtx,
      link: _link,
      vsync: this,
      options: widget.options,
      builder: widget.overlay,
      overlayTheme: Theme.of(anchorCtx),
      // Forward the captured pointer offset so the controller can
      // honor `placement: atTap`. Controller ignores this value for
      // any other placement.
      anchorPoint: _lastTapPos,
    );

    // Armed AFTER the open resolves, so the countdown measures how long
    // the surface was actually on screen rather than how long the open
    // took.
    final life = widget.options.autoDismissAfter;
    if (life != null && mounted && _ctrl.isOpen) {
      _autoDismissTimer?.cancel();
      _autoDismissTimer = Timer(life, _close);
    }
  }

  Future<void> _close() async {
    // Cancel any pending hover/long-press timers so they can't refire
    // after the popup has closed (the close itself is idempotent, but
    // the timers held a reference that prolonged GC).
    _hoverCloseTimer?.cancel();
    _hoverCloseTimer = null;
    _hoverOpenTimer?.cancel();
    _hoverOpenTimer = null;
    _autoDismissTimer?.cancel();
    _autoDismissTimer = null;
    _longPressTimer?.cancel();
    _longPressTimer = null;
    _lastTapPos = null;
    if (!_ctrl.isOpen) return;
    final hooks = widget.options.hooks;
    final canClose = await (hooks?.onWillClose?.call() ?? true);
    if (!canClose) return;
    // `onClose` is invoked by the controller's `hide()` post-teardown
    // so it fires consistently regardless of whether close was
    // triggered here, by tap-outside, by Escape, or by route change.
    await _ctrl.hide();
  }

  Future<void> _toggle() async {
    if (_ctrl.isOpen) {
      await _close();
    } else {
      await _open();
    }
  }

  void _onHoverEnter(PointerEnterEvent _) {
    _hoverCloseTimer?.cancel();
    // A REST, not a crossing. Without the delay a popup fires at every
    // pointer that passes over the anchor on its way somewhere else,
    // which is most of them on a toolbar.
    final delay = widget.options.hoverOpenDelay ?? Duration.zero;
    if (delay == Duration.zero) {
      _open();
      return;
    }
    _hoverOpenTimer?.cancel();
    _hoverOpenTimer = Timer(delay, _open);
  }

  void _onHoverExit(PointerExitEvent _) {
    // A pointer that left before the rest completed never wanted it.
    _hoverOpenTimer?.cancel();
    _hoverOpenTimer = null;
    _hoverCloseTimer?.cancel();
    _hoverCloseTimer = Timer(
      widget.options.hoverCloseDelay ??
          GlobalPopupOptions.defaults.hoverCloseDelay!,
      _close,
    );
  }

  void _onFocusChanged(bool hasFocus) {
    if (hasFocus) {
      _open();
    } else {
      _close();
    }
  }

  bool _onKeyEvent(FocusNode _, KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    if (event.logicalKey == LogicalKeyboardKey.escape && _ctrl.isOpen) {
      _close();
      return true;
    }
    // Enter and Space OPEN a tap-triggered popup.
    //
    // The tap trigger is raw pointer events, so a keyboard could reach
    // the anchor and then do nothing with it — the overflow button on
    // a collapsed toggle group was focusable and dead. Anything a
    // pointer can open, a keyboard opens the same way.
    //
    // Only for the TAP trigger: hover, long-press and secondary-tap
    // are pointer gestures with no keyboard equivalent, and `focus`
    // opens on focus already.
    if (widget.trigger == GlobalPopupTrigger.tap &&
        (event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.space)) {
      _toggle();
      return true;
    }
    return false;
  }

  // ─── Build ───────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    Widget anchor = KeyedSubtree(
      key: _anchorKey,
      child: CompositedTransformTarget(
        link: _link,
        child: widget.child,
      ),
    );

    // Escape to close — always wired so keyboard users can dismiss.
    //
    // A TAP-triggered anchor can also take focus, so Tab reaches it
    // and Enter opens it. The other triggers cannot: a hover popup
    // that stole a tab stop would be a traversal stop that does
    // nothing.
    anchor = Focus(
      focusNode: widget.anchorFocusNode,
      canRequestFocus:
          widget.enabled && widget.trigger == GlobalPopupTrigger.tap,
      onKeyEvent: (node, event) => _onKeyEvent(node, event)
          ? KeyEventResult.handled
          : KeyEventResult.ignored,
      child: anchor,
    );

    if (!widget.enabled) return anchor;

    switch (widget.trigger) {
      case GlobalPopupTrigger.manual:
        return anchor;
      case GlobalPopupTrigger.tap:
        // A KEYBOARD can open it too.
        //
        // The tap trigger was a bare `Listener` — pointer events and
        // nothing else. An anchor that is a button therefore had no
        // focus state and did nothing on Enter: the popup owned the
        // tap, and the keyboard could not reach the popup. Wrapping
        // the same `Listener` in a `FocusableActionDetector` makes
        // every tap-triggered popup in the app a real focus stop that
        // opens on Enter or Space.
        return FocusableActionDetector(
          actions: <Type, Action<Intent>>{
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (_) {
                _toggle();
                return null;
              },
            ),
          },
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: _onPointerDownTap,
            onPointerUp: _onPointerUpTap,
            onPointerCancel: _onPointerCancelTap,
            child: anchor,
          ),
        );
      case GlobalPopupTrigger.longPress:
        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: _onPointerDownLongPress,
          onPointerUp: _onPointerUpLongPress,
          onPointerCancel: _onPointerCancelLongPress,
          child: anchor,
        );
      case GlobalPopupTrigger.hover:
        return MouseRegion(
          onEnter: _onHoverEnter,
          onExit: _onHoverExit,
          child: anchor,
        );
      case GlobalPopupTrigger.hoverOrLongPress:
        // BOTH, wired at once: a touch screen never fires hover, and a
        // mouse user should not have to hold the button down. The two
        // never collide — a device that hovers does not long-press to
        // read a label.
        return MouseRegion(
          onEnter: _onHoverEnter,
          onExit: _onHoverExit,
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: _onPointerDownLongPress,
            onPointerUp: _onPointerUpLongPress,
            onPointerCancel: _onPointerCancelLongPress,
            child: anchor,
          ),
        );
      case GlobalPopupTrigger.focus:
        return Focus(
          onFocusChange: _onFocusChanged,
          child: anchor,
        );
      case GlobalPopupTrigger.secondaryTap:
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onSecondaryTap: _open,
          onLongPress: _open,
          child: anchor,
        );
    }
  }
}

/// Handle passed into [GlobalPopup.showAt]'s `builder`. Call
/// [close] (optionally with a value) to dismiss the popup. The
/// `Future<R?>` returned by `showAt` resolves to that value.
class GlobalPopupRouteHandle<R> {
  GlobalPopupRouteHandle._(this._closeFn);

  final void Function([R?]) _closeFn;

  /// Close the popup, resolving the future to [value] (or `null` if
  /// omitted). Idempotent.
  void close([R? value]) => _closeFn(value);
}

/// Private TickerProvider for [GlobalPopup.showAt]'s entrance
/// animation. Lives only for the lifetime of one popup.
class _ShowAtTickerProvider implements TickerProvider {
  final Set<Ticker> _tickers = {};

  @override
  Ticker createTicker(TickerCallback onTick) {
    final t = Ticker(onTick);
    _tickers.add(t);
    return t;
  }

  void dispose() {
    for (final t in _tickers) {
      t.dispose();
    }
    _tickers.clear();
  }
}
