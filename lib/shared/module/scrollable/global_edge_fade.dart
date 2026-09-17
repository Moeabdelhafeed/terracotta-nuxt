import 'dart:async';

import 'package:flutter/material.dart';

import 'scrollable_models.dart';
import 'scrollable_style.dart';
import 'theme/scrollable_theme.dart';

/// The edge effect at the start / end of any scrollable.
///
/// Wraps a scrollable child and listens to its [ScrollController] so
/// the bands know whether there is more content that way.
///
/// Three modes, in [EdgeFadeMode]: `scrim`, `shader`, `innerShadow`.
///
/// There was a fourth — a tapered `BackdropFilter` band. It never
/// looked right: composing enough layers to ramp smoothly meant
/// blurring each one by more than its own height, and `TileMode.clamp`
/// then repeats the edge pixel instead of mixing content, so the band
/// read as a stack of horizontal bars. Capping the sigma to fix the
/// streaks left a blur too weak to see. It cost sixteen saveLayers and
/// sixteen backdrop reads for that.
///
/// **Start and end are the SCROLL's, not the screen's.** A horizontal
/// scrollable in Arabic starts at the right edge — `pixels == 0` is
/// the right-hand side — and the bands used to be pinned to left and
/// right whatever the direction, so the "there is more" band sat on
/// the side there was nothing more on.
class GlobalEdgeFade extends StatefulWidget {
  const GlobalEdgeFade({
    super.key,
    required this.child,
    required this.controller,
    this.style,
    this.axis = Axis.vertical,
  });

  final Widget child;
  final ScrollController controller;

  /// Merged over `GlobalScrollableTheme` and then the floor.
  final EdgeFadeStyle? style;

  final Axis axis;

  @override
  State<GlobalEdgeFade> createState() => _GlobalEdgeFadeState();
}

class _GlobalEdgeFadeState extends State<GlobalEdgeFade> {
  bool _atStart = true;
  bool _atEnd = true;

  /// Keeps the shader mounted for one duration after its last band
  /// turns off, so the band has frames to fade OUT in.
  ///
  /// Without it the optimisation below and the animation fight: the
  /// widget unmounts the instant both bands go false, and a band that
  /// is mid-fade vanishes instead of finishing. See [_ShaderFade].
  bool _lingering = false;
  Timer? _linger;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onScroll());
  }

  @override
  void didUpdateWidget(GlobalEdgeFade old) {
    super.didUpdateWidget(old);
    if (widget.controller != old.controller) {
      old.controller.removeListener(_onScroll);
      widget.controller.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    _linger?.cancel();
    widget.controller.removeListener(_onScroll);
    super.dispose();
  }

  /// Marks that there IS a band on screen, and schedules the moment
  /// it would have finished fading out.
  void _armLinger(Duration duration) {
    if (duration == Duration.zero) return;
    _lingering = true;
    _linger?.cancel();
    _linger = Timer(duration, () {
      if (mounted) setState(() => _lingering = false);
    });
  }

  void _onScroll() {
    if (!mounted || !widget.controller.hasClients) return;
    final pos = widget.controller.position;
    // `extentBefore` / `extentAfter` read min / maxScrollExtent, which
    // throw a null-check until the viewport has applied its
    // dimensions — a frame callback can fire before that, e.g. while
    // content is resizing.
    if (!pos.hasContentDimensions) return;
    final atStart = pos.extentBefore <= 0.5;
    final atEnd = pos.extentAfter <= 0.5;
    if (atStart != _atStart || atEnd != _atEnd) {
      setState(() {
        _atStart = atStart;
        _atEnd = atEnd;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.style.resolve(context);
    if (style.isOff) return widget.child;

    final showStart = style.start && (!style.smart || !_atStart);
    final showEnd = style.end && (!style.smart || !_atEnd);

    // Which SIDE the scroll's start lands on. Vertical always runs
    // top-to-bottom; horizontal follows the reading direction, which
    // is what a `Scrollable` itself does with its axis direction.
    final flip =
        widget.axis == Axis.horizontal &&
        Directionality.of(context) == TextDirection.rtl;
    final leading = flip ? showEnd : showStart;
    final trailing = flip ? showStart : showEnd;

    // NOTHING to draw — get out of the way entirely.
    //
    // A `ShaderMask` is a saveLayer the size of the whole viewport on
    // EVERY paint. It used to be built with both bands hidden too,
    // painting an all-white gradient that changes not one pixel:
    // content that fits its viewport, or a `smart` fade resting at the
    // only end there is, paid for it every frame. `ShowcasePage` puts a
    // shader fade on every page in the app, so this was the
    // most-paid-for nothing in the codebase.
    //
    // ONLY the shader mode, deliberately. The other three animate their
    // bands out over `style.duration`, and a widget that unmounts the
    // moment its band turns off has no frames left to do that in — the
    // band would vanish instead of fading. They cost a Stack and two
    // zero-opacity boxes at rest, which is not a saveLayer: `Opacity`
    // at zero skips painting its child outright, and `_BlurFade`
    // already builds no `BackdropFilter` at all while its controllers
    // sit at zero.
    if (style.mode == EdgeFadeMode.shader && !leading && !trailing) {
      if (!_lingering) return widget.child;
    } else if (style.mode == EdgeFadeMode.shader) {
      _armLinger(style.duration);
    }

    return switch (style.mode) {
      EdgeFadeMode.none => widget.child,
      EdgeFadeMode.shader => _ShaderFade(
        axis: widget.axis,
        size: style.size,
        duration: style.duration,
        showLeading: leading,
        showTrailing: trailing,
        child: widget.child,
      ),
      EdgeFadeMode.scrim || EdgeFadeMode.innerShadow => _OverlayFade(
        axis: widget.axis,
        size: style.size,
        color: style.color,
        duration: style.duration,
        showLeading: leading,
        showTrailing: trailing,
        child: widget.child,
      ),
    };
  }
}

/// `leading` / `trailing` are geometric — the top / left edge and the
/// bottom / right edge of the box. The caller has already mapped the
/// scroll's start and end onto them.
class _ShaderFade extends StatelessWidget {
  const _ShaderFade({
    required this.child,
    required this.axis,
    required this.size,
    required this.duration,
    required this.showLeading,
    required this.showTrailing,
  });
  final Widget child;
  final Axis axis;
  final double size;

  /// How long a band takes to arrive or leave. Zero under reduced
  /// motion — the resolver has already made that decision.
  final Duration duration;

  final bool showLeading;
  final bool showTrailing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, c) {
        final extent = axis == Axis.horizontal ? c.maxWidth : c.maxHeight;
        if (extent <= 0 || !extent.isFinite) return child;
        final fade = (size / extent).clamp(0.0, 0.4);

        // RAMPED, not switched. The band used to appear the instant
        // the first pixel scrolled and vanish the instant it came
        // back — a hard edge blinking on and off at the exact moment
        // the reader's eye is on the content moving past it. It is
        // saying "there is more this way", and that becomes true
        // gradually.
        //
        // Two independent ramps, because the ends are independent: a
        // short list reaching its end softens one while the other is
        // already up.
        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: showLeading ? 1 : 0),
          duration: duration,
          curve: Curves.easeOut,
          builder: (context, lead, _) => TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: showTrailing ? 1 : 0),
            duration: duration,
            curve: Curves.easeOut,
            builder: (context, trail, _) => ShaderMask(
              shaderCallback: (rect) => LinearGradient(
                begin: axis == Axis.horizontal
                    ? Alignment.centerLeft
                    : Alignment.topCenter,
                end: axis == Axis.horizontal
                    ? Alignment.centerRight
                    : Alignment.bottomCenter,
                colors: [
                  // `dstIn`: white KEEPS the pixel, transparent drops
                  // it, so the ramp is the alpha of the end stop.
                  Colors.white.withValues(alpha: 1 - lead),
                  Colors.white,
                  Colors.white,
                  Colors.white.withValues(alpha: 1 - trail),
                ],
                stops: [0, fade, 1 - fade, 1],
              ).createShader(rect),
              blendMode: BlendMode.dstIn,
              child: child,
            ),
          ),
        );
      },
    );
  }
}

class _OverlayFade extends StatelessWidget {
  const _OverlayFade({
    required this.child,
    required this.axis,
    required this.size,
    required this.color,
    required this.duration,
    required this.showLeading,
    required this.showTrailing,
  });
  final Widget child;
  final Axis axis;
  final double size;
  final Color color;
  final Duration duration;
  final bool showLeading;
  final bool showTrailing;

  @override
  Widget build(BuildContext context) {
    final h = axis == Axis.horizontal;
    // The child is the Stack's NON-positioned base so the Stack sizes
    // to it — with `Positioned.fill` the Stack expanded to the
    // incoming max constraints, blowing a shrink-wrapped list (the
    // dropdown overlay) up to its height cap.
    return Stack(
      children: [
        child,
        Positioned(
          top: 0,
          left: 0,
          right: h ? null : 0,
          bottom: h ? 0 : null,
          width: h ? size : null,
          height: h ? null : size,
          child: _edge(atLeading: true, show: showLeading),
        ),
        Positioned(
          top: h ? 0 : null,
          left: h ? null : 0,
          right: 0,
          bottom: 0,
          width: h ? size : null,
          height: h ? null : size,
          child: _edge(atLeading: false, show: showTrailing),
        ),
      ],
    );
  }

  Widget _edge({required bool atLeading, required bool show}) {
    final h = axis == Axis.horizontal;
    final transparent = color.withValues(alpha: 0);
    return IgnorePointer(
      child: AnimatedOpacity(
        duration: duration,
        opacity: show ? 1 : 0,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: h
                  ? (atLeading ? Alignment.centerLeft : Alignment.centerRight)
                  : (atLeading ? Alignment.topCenter : Alignment.bottomCenter),
              end: h
                  ? (atLeading ? Alignment.centerRight : Alignment.centerLeft)
                  : (atLeading ? Alignment.bottomCenter : Alignment.topCenter),
              colors: [color, transparent],
            ),
          ),
        ),
      ),
    );
  }
}
