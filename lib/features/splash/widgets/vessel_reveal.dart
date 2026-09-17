import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';

/// Which half of the launch this is playing.
///
/// The animation is split because the two halves need different things
/// BEHIND them. See [VesselReveal].
enum VesselRevealMode {
  /// Ground, outline, fill. Ends with the mark standing on the ground
  /// and holds there. Played by the splash ROUTE, which has nothing
  /// underneath it worth showing.
  draw,

  /// The mark becomes a hole, the hole opens, the ground fades. Played
  /// as an OVERLAY above the app, so the hole is genuinely transparent
  /// and what shows through it is the real screen.
  open,
}

/// The launch animation: the vessel draws itself on the terracotta
/// ground, fills, then becomes a HOLE in that ground and opens outward
/// until the app is revealed through it.
///
/// ## One shape, three roles
///
/// Nothing here is swapped for anything else. The same outline is
/// stroked, then filled, then subtracted from the ground — and the
/// third role is what makes the reveal: `Path.combine` with
/// [PathOperation.difference] takes the vessel out of a full-screen
/// rectangle, so the app behind is seen THROUGH the mark rather than
/// beside it.
///
/// The web splash reaches the same effect with an SVG mask — a white
/// rectangle showing, a black vessel hiding — because SVG has no path
/// subtraction. Flutter does, so the mask, its oversized canvas and the
/// crossfade between two copies of the shape all collapse into one
/// painted path.
///
/// ## The beats, and their timings
///
/// Taken from the web component so the two channels open the same way:
///
/// | | starts | for |
/// |---|---|---|
/// | the outline draws | 0.00s | 1.20s |
/// | the fill arrives | 1.00s | 0.50s |
/// | it becomes the hole | 1.60s | 0.25s |
/// | the hole opens | 1.80s | 1.60s |
/// | the last of the ground fades | 2.95s | 0.45s |
///
/// [total] is the one knob: every beat is a fraction of it, so halving
/// it halves the whole thing in proportion.
///
/// ## Why it is in two halves
///
/// The web's splash is an overlay on a page that is ALREADY drawn, so
/// its hole reveals the site by simply being transparent. A Flutter
/// splash is a route, and the destination does not exist yet — a hole
/// cut in it reveals the route below, which is nothing.
///
/// So the draw happens on the splash route, and the OPENING happens on
/// an overlay above the app, after the destination has been navigated
/// to and painted. Both halves draw the same picture at the moment
/// they hand over — same ground, same mark, same place — so the swap
/// cannot be seen. See `VesselRevealGate`.
///
/// ## What it does NOT do
///
/// Decide when to leave. [onDone] fires when the animation ends, and
/// the splash's own gate — bootstrap readiness, `minDuration`,
/// `maxDuration` — decides the rest. Under reduced motion it reports
/// done on the first frame and paints the still mark, because a sweep
/// that opens the whole screen is exactly the motion that setting
/// turns off.
class VesselReveal extends StatefulWidget {
  const VesselReveal({
    required this.onDone,
    this.mode = VesselRevealMode.draw,
    this.ground = const Color(0xFF81341A),
    this.ink = const Color(0xFFFFFFFF),
    this.total,
    this.markHeight = 148,
    super.key,
  });

  /// Which half to play — see [VesselRevealMode].
  final VesselRevealMode mode;

  /// Fired once, when the reveal has finished — or immediately, when
  /// motion is switched off.
  final VoidCallback onDone;

  /// The ground the mark is drawn on, and the colour that opens away.
  /// Must match the native launch colour, or the handoff blinks.
  final Color ground;

  /// The stroke and the fill.
  final Color ink;

  /// Null takes the half's own length — [drawTotal] or [openTotal].
  final Duration? total;

  /// 1.20s of outline, and the fill landing at 1.50s.
  static const Duration drawTotal = Duration(milliseconds: 1500);

  /// 0.25s to become a hole, 1.60s to open, and the ground gone by
  /// 1.90s.
  static const Duration openTotal = Duration(milliseconds: 1900);

  /// How tall the vessel stands before it opens.
  final double markHeight;

  /// The mark, as the design's own 14 × 20 drawing.
  ///
  /// Kept as the raw `d` rather than as an asset: this is geometry the
  /// animation measures and subtracts, not a picture it shows, and
  /// `flutter_svg` hands back a widget rather than a [Path].
  static const String pathData =
      'M6.99933 19.6717C9.03374 19.6717 11.7259 18.8502 12.8363 15.5283C12.9068 '
      '15.3166 12.7005 15.1182 12.4914 15.1941C12.0907 15.3392 11.5115 15.487 '
      '10.9536 15.4045C10.71 15.3685 10.6448 15.0463 10.8538 14.9159C10.8977 '
      '14.8879 10.9297 14.8679 10.9443 14.8599C11.4356 14.583 11.9043 14.2635 '
      '12.3317 13.8947C13.4141 12.9613 14.2516 11.6179 13.9307 10.1414C13.715 '
      '9.15215 13.1838 8.23747 12.4422 7.55046C11.9416 7.0858 11.3091 6.80087 '
      '10.7766 6.37482C10.244 5.94877 9.77534 5.44949 9.44515 4.85568C8.55975 '
      '3.2673 9.11362 1.7122 10.1774 0.382118C10.2999 0.227674 10.1894 0 '
      '9.99103 0H7.00067H4.0103C3.81325 0 3.70142 0.227674 3.82391 '
      '0.382118C4.28591 0.959953 4.82913 1.7335 4.97292 2.46578C5.14068 3.32322 '
      '4.92765 4.23124 4.48429 4.97417C4.14478 5.54402 3.67878 6.02732 3.15554 '
      '6.43207C2.64028 6.8315 2.03848 7.10577 1.55784 7.55179C0.816238 8.2388 '
      '0.285004 9.15482 0.0693145 10.1427C-0.251557 11.6193 0.585901 12.9627 '
      '1.66834 13.896C2.09573 14.2648 2.56439 14.5843 3.05568 14.8613C3.06899 '
      '14.8693 3.10228 14.8892 3.14622 14.9172C3.35525 15.0477 3.29001 15.3699 '
      '3.04636 15.4058C2.48983 15.4884 1.90933 15.3406 1.50858 15.1955C1.29821 '
      '15.1196 1.09184 15.3179 1.16373 15.5296C2.27414 18.8515 4.96626 19.673 '
      '7.00067 19.673L6.99933 19.6717Z';

  /// The drawing's own box, which the placement scales from.
  static const Size artboard = Size(14, 20);

  @override
  State<VesselReveal> createState() => _VesselRevealState();
}

class _VesselRevealState extends State<VesselReveal> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.total ?? (widget.mode == VesselRevealMode.draw ? VesselReveal.drawTotal : VesselReveal.openTotal),
  );

  bool get _drawing => widget.mode == VesselRevealMode.draw;

  /// Parsed ONCE. `parseSvgPathData` walks the whole string, and this
  /// paints every frame.
  late final Path _mark = parseSvgPathData(VesselReveal.pathData);

  bool _reported = false;
  bool _started = false;

  // Fractions of the half's own length, from the table in the class
  // doc. Held as fractions rather than milliseconds so each half
  // scales with one number.

  // DRAW, over 1.50s.
  static const _drawFrom = 0.0, _drawTo = 1.20 / 1.5;
  static const _fillFrom = 1.00 / 1.5, _fillTo = 1.0;

  // OPEN, over 1.90s.
  static const _holeFrom = 0.0, _holeTo = 0.25 / 1.9;
  static const _openFrom = 0.20 / 1.9, _openTo = 1.80 / 1.9;
  static const _fadeFrom = 1.45 / 1.9, _fadeTo = 1.0;

  @override
  void initState() {
    super.initState();
    _c.addStatusListener((status) {
      if (status == AnimationStatus.completed) _report();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // A sweep that opens the whole screen is precisely the motion
    // `disableAnimations` exists to stop. The mark still stands on the
    // ground; it simply does not perform.
    if (MediaQuery.disableAnimationsOf(context)) {
      _report();
      return;
    }
    if (!_started) {
      _started = true;
      _c.forward();
    }
  }

  /// Once, and never during a build — the splash navigates on this.
  void _report() {
    if (_reported) return;
    _reported = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.onDone());
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  double _phase(double from, double to) => ((_c.value - from) / (to - from)).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);

    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        // Still: the finished mark on the ground for the draw half,
        // and an opening that is simply over for the other — a sweep
        // across the whole screen is what this setting turns off, but
        // the app still has to be reachable.
        final draw = still || !_drawing ? 1.0 : Curves.easeInOut.transform(_phase(_drawFrom, _drawTo));
        final fill = still || !_drawing ? 1.0 : Curves.easeOut.transform(_phase(_fillFrom, _fillTo));

        if (_drawing) {
          return _paint(draw: draw, fill: fill, hole: 0, open: 0, gone: 0);
        }

        final hole = still ? 1.0 : _phase(_holeFrom, _holeTo);
        // `easeInOut` over a long beat, as the web has it: area grows
        // with the SQUARE of the scale, so a sharper ease snaps.
        final open = still ? 1.0 : Curves.easeInOut.transform(_phase(_openFrom, _openTo));
        final gone = still ? 1.0 : _phase(_fadeFrom, _fadeTo);

        return _paint(
          draw: draw,
          fill: fill,
          hole: hole,
          open: open,
          gone: gone,
        );
      },
    );
  }

  Widget _paint({
    required double draw,
    required double fill,
    required double hole,
    required double open,
    required double gone,
  }) => Opacity(
    opacity: 1 - gone,
    child: CustomPaint(
      size: Size.infinite,
      painter: _VesselPainter(
        mark: _mark,
        ground: widget.ground,
        ink: widget.ink,
        markHeight: widget.markHeight,
        draw: draw,
        fill: fill,
        hole: hole,
        open: open,
      ),
    ),
  );
}

/// Everything the reveal paints, in one pass.
class _VesselPainter extends CustomPainter {
  const _VesselPainter({
    required this.mark,
    required this.ground,
    required this.ink,
    required this.markHeight,
    required this.draw,
    required this.fill,
    required this.hole,
    required this.open,
  });

  final Path mark;
  final Color ground;
  final Color ink;
  final double markHeight;

  /// How much of the outline has been drawn, 0 → 1.
  final double draw;

  /// How present the fill is, 0 → 1.
  final double fill;

  /// How far the shape has become a hole rather than a drawing.
  final double hole;

  /// How far that hole has opened, 0 → 1.
  final double open;

  @override
  void paint(Canvas canvas, Size size) {
    // The mark, centred and scaled to [markHeight] — the drawing's own
    // 14 × 20 box is far too small to place in screen coordinates.
    //
    // Centred on the PATH's own bounds rather than on the artboard:
    // the outline overshoots its viewBox slightly (14.5 wide against a
    // declared 14, since a stroke's curve may pass outside the box it
    // was drawn in), and centring on the declared size puts it a
    // quarter-unit off — visible once scaled ten times up.
    final raw = mark.getBounds();
    final scale = markHeight / raw.height;
    final placed = mark.transform(
      (Matrix4.identity()
            ..translate(
              (size.width - raw.width * scale) / 2 - raw.left * scale,
              (size.height - markHeight) / 2 - raw.top * scale,
            )
            ..scale(scale))
          .storage,
    );

    final screen = Path()..addRect(Offset.zero & size);

    // ── The ground, with the hole taken out of it ──────────────
    //
    // `difference` is the whole trick: the vessel is subtracted from a
    // rectangle covering the screen, so what shows through the gap is
    // whatever is painted beneath this widget — the app itself.
    if (hole <= 0) {
      canvas.drawPath(screen, Paint()..color = ground);
    } else {
      final centre = placed.getBounds().center;
      // Scaled about the vessel's OWN centre, so the opening reads as
      // the mark growing rather than as a shape sliding off.
      final grown = placed.transform(
        (Matrix4.identity()
              ..translate(centre.dx, centre.dy)
              ..scale(1 + (_coverScale(size, placed) - 1) * open)
              ..translate(-centre.dx, -centre.dy))
            .storage,
      );
      canvas.drawPath(
        Path.combine(PathOperation.difference, screen, grown),
        Paint()..color = ground,
      );
    }

    // ── The drawing itself, until it hands over ────────────────
    //
    // Faded out as the hole fades in — the web crossfades two copies
    // for the same reason: cutting from a filled mark to a window in
    // one frame reads as a jump.
    final showing = 1 - hole;
    if (showing <= 0) return;

    if (fill > 0) {
      canvas.drawPath(
        placed,
        Paint()..color = ink.withValues(alpha: fill * showing),
      );
    }

    if (draw > 0) {
      canvas.drawPath(
        draw >= 1 ? placed : _partial(placed, draw),
        Paint()
          ..style = PaintingStyle.stroke
          // Proportional to the mark, so it reads the same at any size
          // — the web's 1.5 in a 106-wide space.
          ..strokeWidth = markHeight * 0.012
          ..strokeCap = StrokeCap.round
          ..color = ink.withValues(alpha: showing),
      );
    }
  }

  /// The first [t] of the outline, BY LENGTH.
  ///
  /// `PathMetrics` is the analogue of the web's `DrawSVGPlugin`: the
  /// outline is measured and a prefix of it extracted, so it appears
  /// drawn by a pen rather than faded in. Every subpath advances
  /// together, or a shape made of several strokes would draw them one
  /// after another.
  static Path _partial(Path path, double t) {
    final out = Path();
    for (final metric in path.computeMetrics()) {
      out.addPath(metric.extractPath(0, metric.length * t), Offset.zero);
    }
    return out;
  }

  /// How far the hole must grow to swallow the screen.
  ///
  /// Measured rather than guessed at: the web hard-codes 34, which is
  /// a number for one viewport. The vessel's shortest half-axis has to
  /// reach the furthest corner — with a margin, because the shape is
  /// not a circle and its narrow waist arrives there last.
  static double _coverScale(Size size, Path placed) {
    final bounds = placed.getBounds();
    final c = bounds.center;
    final dx = math.max(c.dx, size.width - c.dx);
    final dy = math.max(c.dy, size.height - c.dy);
    final furthest = math.sqrt(dx * dx + dy * dy);
    final half = math.min(bounds.width, bounds.height) / 2;
    // 2.6, not 1: the vessel is not a circle. Its belly reaches the
    // corners long before its NECK does, and the neck is what has to
    // clear them for the ground to be gone. The web's hard-coded 34 is
    // the same ratio for its own geometry — a vessel 106 wide opening
    // to 3.6 viewport widths.
    return half <= 0 ? 1 : (furthest / half) * 2.6;
  }

  @override
  bool shouldRepaint(_VesselPainter old) => old.draw != draw || old.fill != fill || old.hole != hole || old.open != open || old.ground != ground || old.ink != ink || old.markHeight != markHeight;
}
