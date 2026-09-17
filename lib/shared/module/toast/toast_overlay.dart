import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/animations/animation_presets.dart';
import 'toast_models.dart';

/// The overlay engine behind [GlobalToast] — insert, stack, animate,
/// auto-close, dismiss.
///
/// ## Why this is ours
///
/// It replaces a package that was only ever doing six things: put an
/// `OverlayEntry` on screen, place it by alignment, stack several,
/// animate them in and out, run an auto-close timer, and hand back a
/// handle. Everything visible — container, icon, gradients, border
/// trace, swipe shell — was already written here, so the dependency was
/// paying for scheduling, not for looks. Owning it also gets a
/// third-party enum out of `GlobalToast`'s public signature.
///
/// ## The parts that are easy to get wrong
///
/// - **The entry must outlive its own dismissal.** Removing it the
///   moment a toast is dismissed cuts the exit animation off mid-frame,
///   so removal waits for the controller to finish.
/// - **Stacking is per ALIGNMENT.** Two toasts pinned bottom stack
///   against each other; a toast pinned top is a separate pile. Each
///   entry rebuilds when its pile changes so the survivors slide into
///   the gap rather than jumping.
/// - **The ROOT overlay, not the nearest one.** A toast raised from
///   inside a dialog belongs above that dialog, and a nearest-overlay
///   entry would be buried by it — or die with the route.
class ToastOverlay {
  ToastOverlay._();

  static final List<_ToastEntry> _entries = <_ToastEntry>[];

  /// Live handles, newest last. Exposed for tests and debug tooling.
  static List<ToastHandle> get visible =>
      List.unmodifiable(_entries.map((e) => e.handle));

  /// Puts [builder]'s toast on screen and returns its handle.
  ///
  /// [builder] receives the handle so the toast can close itself, and an
  /// animation whose value runs 0 → 1 on entry and back on exit.
  static ToastHandle? show({
    required OverlayState overlay,
    required Widget Function(BuildContext, ToastHandle, Animation<double>)
    builder,
    required Alignment alignment,
    Duration duration = kToastAutoClose,
    Duration animationDuration = kToastAnimDuration,
    double stackSpacing = kToastStackSpacing,
    bool showProgress = false,
    VoidCallback? onDismissed,
  }) {
    final entry = _ToastEntry(
      alignment: alignment,
      stackSpacing: stackSpacing,
      showProgress: showProgress,
      duration: duration,
      animationDuration: animationDuration,
      onDismissed: onDismissed,
      builder: builder,
    );
    _entries.add(entry);
    entry.mount(overlay);
    _reflow(alignment);
    return entry.handle;
  }

  /// Removes [handle] with its exit animation, unless [animate] is off —
  /// a swipe has already moved the toast off screen, so animating it
  /// away again reads as a stutter.
  static void dismiss(ToastHandle? handle, {bool animate = true}) {
    final entry = _entries.where((e) => e.handle == handle).firstOrNull;
    entry?.dismiss(animate: animate);
  }

  /// Removes every toast at once.
  static void dismissAll({bool animate = true}) {
    for (final entry in List<_ToastEntry>.from(_entries)) {
      entry.dismiss(animate: animate);
    }
  }

  /// Removes the OLDEST toast — what makes room when [maxVisible] is
  /// reached.
  static void dismissOldest({bool animate = true}) {
    if (_entries.isEmpty) return;
    _entries.first.dismiss(animate: animate);
  }

  /// Removes only the most recent — the `hideCurrentSnackBar` shape.
  static void dismissCurrent({bool animate = true}) {
    if (_entries.isEmpty) return;
    _entries.last.dismiss(animate: animate);
  }

  static void _remove(_ToastEntry entry) {
    if (!_entries.remove(entry)) return;
    entry.unmount();
    _reflow(entry.alignment);
  }

  /// Drops an entry whose host is being disposed WITH the tree.
  ///
  /// Distinct from [_remove]: there is no overlay entry left to take
  /// down — the Overlay is going away itself — so touching it here
  /// would remove something mid-teardown.
  static void _forget(_ToastEntry entry) {
    if (!_entries.remove(entry)) return;
    _reflow(entry.alignment);
  }

  /// Tells everything in the same pile to rebuild, so survivors take up
  /// the space a departing toast leaves behind.
  static void _reflow(Alignment alignment) {
    for (final entry in _entries) {
      if (entry.alignment == alignment) entry.markNeedsBuild();
    }
  }

  /// Summed height of the toasts between [entry] and its edge.
  static double _offsetFor(_ToastEntry entry) {
    final pile = _entries.where((e) => e.alignment == entry.alignment).toList();
    final nearer = entry.alignment.y > 0
        ? pile.sublist(pile.indexOf(entry) + 1)
        : pile.sublist(0, pile.indexOf(entry));
    return nearer.fold<double>(0, (sum, e) => sum + (e.height ?? 0));
  }

  /// Index within its own pile, counted from the anchored edge.
  static int _indexOf(_ToastEntry entry) {
    final pile = _entries.where((e) => e.alignment == entry.alignment).toList();
    final index = pile.indexOf(entry);
    // Bottom-anchored piles grow upward, so the newest sits closest to
    // the edge; top-anchored ones grow downward.
    return entry.alignment.y > 0 ? pile.length - 1 - index : index;
  }

  @visibleForTesting
  static void debugReset() {
    for (final entry in List<_ToastEntry>.from(_entries)) {
      _entries.remove(entry);
      entry.unmount();
    }
  }
}

/// One live toast: its overlay entry, its animation and its timer.
class _ToastEntry {
  _ToastEntry({
    required this.alignment,
    required this.stackSpacing,
    required this.showProgress,
    required this.duration,
    required this.animationDuration,
    required this.builder,
    this.onDismissed,
  });

  final Alignment alignment;
  final double stackSpacing;

  /// Whether anything is watching the countdown.
  ///
  /// Decides HOW the toast expires, which is not a detail: a ticking
  /// AnimationController schedules a frame every vsync for the toast's
  /// whole life, and `pumpAndSettle` runs it to completion — so every
  /// widget test that settles would dismiss its own toast. A Timer
  /// schedules no frames at all. So the controller is created only when
  /// a progress bar actually needs to be drawn.
  final bool showProgress;
  final Duration duration;
  final Duration animationDuration;
  final VoidCallback? onDismissed;
  final Widget Function(BuildContext, ToastHandle, Animation<double>) builder;

  late final ToastHandle handle = ToastHandle(
    dismiss: () => ToastOverlay.dismiss(handle),
    pause: pause,
    resume: resume,
    hasTimer: () => _life != null || _timer != null || _remaining != null,
  );

  OverlayEntry? _overlayEntry;
  AnimationController? _controller;

  /// Runs 0 → 1 over the toast's lifetime and dismisses on completion.
  ///
  /// Replaces a Timer, which could only say "not yet" or "now". A
  /// controller also answers "how much is left", which is what the
  /// progress bar needs, and pausing is `stop()` rather than arithmetic
  /// on a remaining Duration.
  AnimationController? _life;
  Timer? _timer;
  Duration? _remaining;
  DateTime? _startedAt;

  /// Measured after layout. Toasts are not a fixed height — one with a
  /// description is taller than one without — so a constant stack
  /// spacing overlapped them.
  double? height;

  bool _leaving = false;

  void mount(OverlayState overlay) {
    _overlayEntry = OverlayEntry(
      builder: (context) => _ToastHost(
        entry: this,
        // Read at build time: the index changes as the pile changes.
        index: ToastOverlay._indexOf(this),
      ),
    );
    overlay.insert(_overlayEntry!);
  }

  /// Takes the toast off screen. Does NOT dispose the controllers: the
  /// host created them against its own vsync and disposes them in turn.
  void unmount() {
    _timer?.cancel();
    _timer = null;
    _life?.stop();
    _controller = null;
    _life = null;
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  /// The host is going down with the tree.
  ///
  /// Cancels the countdown and forgets the entry. Without this a toast
  /// still on screen when its route or the whole app is torn down
  /// leaves an armed Timer behind — harmless at runtime, but it fails
  /// every widget test that ends with a toast showing, which is most of
  /// them.
  void detach() {
    _timer?.cancel();
    _timer = null;
    _life?.stop();
    _controller = null;
    _life = null;
    _overlayEntry = null;
    ToastOverlay._forget(this);
  }

  void markNeedsBuild() => _overlayEntry?.markNeedsBuild();

  void attach(AnimationController enter, AnimationController? life) {
    _controller = enter;
    _life = life;
    enter.forward();
    if (life != null) {
      life.forward().whenComplete(() {
        if (life.isCompleted) dismiss();
      });
    } else {
      _startTimer(duration);
    }
  }

  void _startTimer(Duration remaining) {
    _timer?.cancel();
    // Zero means persistent: nothing to count down.
    if (remaining <= Duration.zero) return;
    _remaining = remaining;
    _startedAt = DateTime.now();
    _timer = Timer(remaining, dismiss);
  }

  void pause() {
    if (_life != null) {
      _life!.stop();
      return;
    }
    if (_timer == null || _startedAt == null) return;
    _timer!.cancel();
    _timer = null;
    _remaining = _remaining! - DateTime.now().difference(_startedAt!);
  }

  void resume() {
    if (_leaving) return;
    final life = _life;
    if (life != null) {
      if (life.isCompleted) return;
      life.forward().whenComplete(() {
        if (life.isCompleted) dismiss();
      });
      return;
    }
    if (_timer != null || _remaining == null) return;
    _startTimer(_remaining!);
  }

  /// Reports this toast's measured height so the pile can lay itself out
  /// against real sizes rather than a guessed constant.
  void reportHeight(double value) {
    if (height != null && (height! - value).abs() < 0.5) return;
    height = value;
    ToastOverlay._reflow(alignment);
  }

  void dismiss({bool animate = true}) {
    // Guarded: a swipe and an elapsed timer can both land on the same
    // toast, and removing the entry twice throws.
    if (_leaving) return;
    _leaving = true;
    _timer?.cancel();
    _timer = null;
    _life?.stop();
    onDismissed?.call();

    final controller = _controller;
    if (!animate || controller == null) {
      ToastOverlay._remove(this);
      return;
    }
    // The entry has to survive its own exit, or the animation is cut
    // off at the frame it started.
    controller.reverse().whenComplete(() => ToastOverlay._remove(this));
  }
}

/// Positions one toast in its pile and owns its enter/exit animation.
class _ToastHost extends StatefulWidget {
  const _ToastHost({required this.entry, required this.index});

  final _ToastEntry entry;
  final int index;

  @override
  State<_ToastHost> createState() => _ToastHostState();
}

class _ToastHostState extends State<_ToastHost> with TickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.entry.animationDuration,
  );

  /// Only when a progress bar needs it, and never for a persistent
  /// toast — see [_ToastEntry.showProgress].
  late final AnimationController? _life =
      !widget.entry.showProgress || widget.entry.duration <= Duration.zero
      ? null
      : AnimationController(vsync: this, duration: widget.entry.duration);

  final _measureKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    widget.entry.attach(_controller, _life);
    _measure();
  }

  /// Measured after every layout: text scale, a locale change or a
  /// description appearing all move it.
  void _measure() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final box = _measureKey.currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) return;
      widget.entry.reportHeight(box.size.height);
    });
  }

  @override
  void dispose() {
    // Ownership, stated once: the host CREATED these controllers against
    // its own vsync, so the host disposes them. The entry only borrows
    // references and drops them here.
    widget.entry.detach();
    _controller.dispose();
    _life?.dispose();
    super.dispose();
  }

  /// Distance from the anchored edge: the real heights of every toast
  /// nearer that edge, plus a gap each.
  ///
  /// A constant per index cannot work — a toast with a description is
  /// half again as tall as one without, so a fixed step either overlaps
  /// them or leaves holes.
  double get _offset =>
      ToastOverlay._offsetFor(widget.entry) +
      widget.index * widget.entry.stackSpacing;

  @override
  Widget build(BuildContext context) {
    _measure();
    final alignment = widget.entry.alignment;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    // Slide in from whichever edge the toast is anchored to; a centred
    // toast has no edge to come from, so it only fades.
    final from = alignment.y == 0 ? 0.0 : (alignment.y > 0 ? 1.0 : -1.0);

    return SafeArea(
      child: Align(
        alignment: alignment,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final t = reduceMotion
                ? (_controller.value > 0 ? 1.0 : 0.0)
                : Curves.easeOutCubic.transform(_controller.value);
            return Opacity(
              opacity: t.clamp(0.0, 1.0),
              child: Transform.translate(
                offset: Offset(0, (1 - t) * kToastEnterOffset * from),
                child: child,
              ),
            );
          },
          // Stack offset lives OUTSIDE the animation so a toast sliding
          // away does not drag the ones behind it.
          child: AnimatedPadding(
            duration: reduceMotion ? Duration.zero : AppDurations.quick,
            curve: Curves.easeOut,
            padding: EdgeInsets.only(
              top: alignment.y > 0 ? 0 : _offset,
              bottom: alignment.y > 0 ? _offset : 0,
            ),
            child: Material(
              key: _measureKey,
              color: Colors.transparent,
              // The LIFE animation drives the progress bar, not the
              // entry one: the bar means "time remaining", and the entry
              // animation is finished a moment after the toast appears.
              child: widget.entry.builder(
                context,
                widget.entry.handle,
                _life ?? kAlwaysDismissedAnimation,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
