import 'dart:async';

import 'package:flutter/material.dart';

import '../go_router_config.dart';
import 'nav_animation_style.dart';
import 'theme/nav_animation_theme.dart';

export 'nav_animation_style.dart';
export 'theme/nav_animation_theme.dart';

// ---------------------------------------------------------------------------
// NavigationAwareAnimation
// ---------------------------------------------------------------------------

/// Wraps a widget and animates it differently based on navigation events.
///
/// Uses Flutter's [RouteAware] + [RouteObserver] for reliable detection —
/// works correctly with GoRouter's declarative routing.
///
/// **4 events:**
/// - [onPush] — this page was pushed (entering)
/// - [onPushOther] — another page was pushed on top (this page covered)
/// - [onPop] — this page is being popped (leaving)
/// - [onPopOther] — the page on top was popped (this page revealed)
///
/// ```dart
/// NavigationAwareAnimation(
///   onPush: WidgetAnimation.slideFromBottom,
///   onPushOther: WidgetAnimation.slideToLeft,
///   onPop: WidgetAnimation.slideToBottom,
///   onPopOther: WidgetAnimation.slideFromLeft,
///   child: MyButton(),
/// )
/// ```
class NavigationAwareAnimation extends StatefulWidget {
  const NavigationAwareAnimation({
    super.key,
    required this.child,
    this.onPush,
    this.onPushOther,
    this.onPop,
    this.onPopOther,
    this.autoPlay = true,
  });

  /// The widget to animate.
  final Widget child;

  /// Animation when this page is pushed (entering).
  final WidgetAnimation? onPush;

  /// Animation when another page is pushed on top of this one.
  final WidgetAnimation? onPushOther;

  /// Animation when this page is popped (leaving).
  final WidgetAnimation? onPop;

  /// Animation when the page on top is popped (this page revealed).
  final WidgetAnimation? onPopOther;

  /// If true, automatically plays [onPush] on first build.
  final bool autoPlay;

  @override
  State<NavigationAwareAnimation> createState() =>
      _NavigationAwareAnimationState();
}

class _NavigationAwareAnimationState extends State<NavigationAwareAnimation>
    with SingleTickerProviderStateMixin, RouteAware {
  /// Built in `initState`, NOT lazily.
  ///
  /// A `late final` here is created on first touch — and the first
  /// touch can be `dispose`, when nothing ever played (reduced motion
  /// returns before playing). Constructing a ticker while the element
  /// is unmounting looks up an ancestor that is already gone.
  late final AnimationController _controller;

  ModalRoute<dynamic>? _route;

  /// What is playing, already resolved.
  ResolvedWidgetAnimation? _current;

  Animation<Offset>? _slide;
  Animation<double>? _fade;
  Animation<double>? _scale;

  /// The entrance's own wait, held so it can be CANCELLED.
  ///
  /// A bare `Future.delayed` outlives the widget: the tree is torn down
  /// and the timer is still pending, which a test binding reports and a
  /// real app pays for.
  Timer? _pending;

  bool _initialBuild = true;

  /// An entrance is SCHEDULED but has not started yet.
  ///
  /// Separate from [_initialBuild] because the two want opposite
  /// lifetimes. `_initialBuild` has to be false by the time `didPush`
  /// runs — `RouteObserver.subscribe` calls it synchronously, and
  /// without the flag the entrance would be triggered twice. But `build`
  /// needs to know the entrance is still coming, and it runs AFTER
  /// `didChangeDependencies`, so reading `_initialBuild` there always
  /// found it already false: the child painted one frame at full
  /// strength and then snapped back to `fadeFrom` to start fading in.
  bool _entrancePending = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // RouteAware is how push / pop are detected — GoRouter's routing is
    // declarative, so there is no callback to hang this on.
    final route = ModalRoute.of(context);
    if (route != null && route != _route) {
      if (_route != null) GoRouterConfig.routeObserver.unsubscribe(this);
      _route = route;
      GoRouterConfig.routeObserver.subscribe(this, route);
    }

    if (_initialBuild && widget.autoPlay && widget.onPush != null) {
      _initialBuild = false;
      _entrancePending = true;
      // After the frame: resolving needs the palette and the media
      // query, and playing in `didChangeDependencies` would animate
      // before the first paint.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _trigger(widget.onPush);
      });
    }
  }

  @override
  void dispose() {
    _pending?.cancel();
    GoRouterConfig.routeObserver.unsubscribe(this);
    _controller.dispose();
    super.dispose();
  }

  // ─── RouteAware ───────────────────────────────────────────

  @override
  void didPush() {
    // `autoPlay` has already handled the first build.
    if (!_initialBuild || !widget.autoPlay) _trigger(widget.onPush);
  }

  @override
  void didPushNext() => _trigger(widget.onPushOther);

  @override
  void didPop() => _trigger(widget.onPop);

  @override
  void didPopNext() => _trigger(widget.onPopOther);

  // ─── Playing ──────────────────────────────────────────────

  void _trigger(WidgetAnimation? animation) {
    if (animation == null || !mounted) return;
    final resolved = animation.resolve(context);

    // Nothing to play — reduced motion resolves to exactly this, so it
    // costs a controller nothing rather than running a zero-length one.
    if (resolved.isNoop) {
      // Reduced motion lands here, and it is already safe: `resolve`
      // returns a bag with no fade at all under that setting, so
      // `restingOpacity` is 1 and `build` shows the child whatever this
      // flag says. Cleared anyway, because the flag means "an entrance
      // is still coming" and after this line none is.
      _entrancePending = false;
      if (_current != null) setState(() => _current = null);
      return;
    }

    _pending?.cancel();
    if (resolved.delay > Duration.zero) {
      _pending = Timer(resolved.delay, () {
        if (mounted) _play(resolved);
      });
      return;
    }
    _play(resolved);
  }

  void _play(ResolvedWidgetAnimation animation) {
    _entrancePending = false;
    final curved = CurvedAnimation(
      parent: _controller,
      curve: animation.curve,
    );

    setState(() {
      _current = animation;
      _slide = animation.hasSlide
          ? Tween<Offset>(
              begin: animation.slideFrom,
              end: animation.slideTo,
            ).animate(curved)
          : null;
      _fade = animation.hasFade
          ? Tween<double>(
              begin: animation.fadeFrom,
              end: animation.fadeTo,
            ).animate(curved)
          : null;
      _scale = animation.hasScale
          ? Tween<double>(
              begin: animation.scaleFrom,
              end: animation.scaleTo,
            ).animate(curved)
          : null;
    });

    _controller
      ..duration = animation.duration
      ..forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    if (_current == null) {
      // Waiting for an entrance: sit where it STARTS, or the widget
      // paints one frame at full strength and a column of them flashes.
      if (_entrancePending) {
        final resting = widget.onPush!.resolve(context).restingOpacity;
        if (resting < 1) {
          return Opacity(opacity: resting, child: widget.child);
        }
      }
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        var result = child!;
        if (_scale != null) {
          result = ScaleTransition(scale: _scale!, child: result);
        }
        if (_fade != null) {
          result = FadeTransition(opacity: _fade!, child: result);
        }
        if (_slide != null) {
          result = SlideTransition(position: _slide!, child: result);
        }
        return result;
      },
    );
  }
}
