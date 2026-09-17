import 'dart:async';
import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

import '../../core/extensions/theme_colors_extension.dart';

/// Paper in the air on the four screens that celebrate something.
///
/// ## Why it is not the picture it replaced
///
/// It was a PNG of confetti lying still behind the words. Confetti at
/// rest is wallpaper: the moment being celebrated has already happened
/// by the time the page is looked at, and a photograph of it says so.
/// The paper has to be moving, once, as the page arrives.
///
/// ## Fireworks, not a single burst
///
/// One cone from the top is a machine. Real celebration confetti comes
/// from several places at slightly different moments, so this fires
/// three bursts from three corners of the frame, staggered — each with
/// its own controller because a `ConfettiController` drives one
/// emitter.
///
/// ## It stops
///
/// Every burst is a fixed [_burst] long and nothing restarts them.
/// Confetti that keeps coming turns a moment into a screen effect, and
/// the reader still has a button to press underneath it.
class CelebrationConfetti extends StatefulWidget {
  const CelebrationConfetti({this.child, super.key});

  /// The page. Drawn UNDER the paper, so nothing is obscured while it
  /// falls.
  final Widget? child;

  @override
  State<CelebrationConfetti> createState() => _CelebrationConfettiState();
}

class _CelebrationConfettiState extends State<CelebrationConfetti> {
  /// How long each emitter throws for. Long enough to read as a burst,
  /// short enough that the page is clear before anyone reaches for the
  /// button.
  static const _burst = Duration(milliseconds: 900);

  /// When each one goes off, after the page arrives.
  static const _delays = [
    Duration(milliseconds: 120),
    Duration(milliseconds: 340),
    Duration(milliseconds: 560),
  ];

  late final List<ConfettiController> _controllers = [
    for (var i = 0; i < _delays.length; i++)
      ConfettiController(duration: _burst),
  ];

  final _timers = <Timer>[];

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < _controllers.length; i++) {
      _timers.add(
        Timer(_delays[i], () {
          if (mounted) _controllers[i].play();
        }),
      );
    }
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // REDUCED MOTION takes the paper away entirely. A burst of moving
    // shapes is exactly what the setting is for, and the page reads
    // perfectly well without it.
    if (MediaQuery.disableAnimationsOf(context)) {
      return widget.child ?? const SizedBox.shrink();
    }

    // THE STUDIO'S OWN COLOURS, not a rainbow. The celebration belongs
    // to this app — its terracotta, the workshop greens and the warm
    // sand behind them.
    final colors = <Color>[
      context.primaryColors.primary,
      context.statusColors.success,
      context.statusColors.warning,
      context.backgroundColors.container,
      Colors.white,
    ];

    return Stack(
      children: [
        if (widget.child != null) widget.child!,
        // IGNORING POINTERS, all of it: the reader has a button under
        // this and paper must not intercept the tap.
        Positioned.fill(
          child: IgnorePointer(
            child: Stack(
              children: [
                // From the top corners, thrown INWARD and down —
                // the two arcs cross over the middle of the page,
                // which is where the words are.
                //
                // PHYSICAL corners, written as coordinates rather than
                // by the named corner constants, and that is not a
                // way around the logical-directions rule: these two are
                // a MIRRORED PAIR. Each one's launch angle is the
                // other's reflection, so the picture they make is
                // already identical in both reading directions and
                // there is nothing left for `AlignmentDirectional` to
                // flip. Swapping the corners without swapping the
                // angles would aim both arcs the same way and lose the
                // cross.
                _Emitter(
                  controller: _controllers[0],
                  alignment: const Alignment(-1, -1),
                  direction: math.pi / 3,
                  colors: colors,
                ),
                _Emitter(
                  controller: _controllers[1],
                  alignment: const Alignment(1, -1),
                  direction: 2 * math.pi / 3,
                  colors: colors,
                ),
                // And one straight down the middle, last, so the
                // three do not read as a pattern.
                _Emitter(
                  controller: _controllers[2],
                  alignment: Alignment.topCenter,
                  direction: math.pi / 2,
                  colors: colors,
                  spread: math.pi / 2,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// One burst.
class _Emitter extends StatelessWidget {
  const _Emitter({
    required this.controller,
    required this.alignment,
    required this.direction,
    required this.colors,
    this.spread = math.pi / 4,
  });

  final ConfettiController controller;
  final Alignment alignment;

  /// Radians, clockwise from the positive x axis — `pi / 2` is
  /// straight down.
  final double direction;

  final List<Color> colors;
  final double spread;

  @override
  Widget build(BuildContext context) => Align(
    alignment: alignment,
    child: ConfettiWidget(
      confettiController: controller,
      blastDirection: direction,
      blastDirectionality: BlastDirectionality.directional,
      emissionFrequency: 0.06,
      numberOfParticles: 14,
      // Enough to carry across the page, not so much that it leaves
      // the frame before it is seen.
      maxBlastForce: 26,
      minBlastForce: 12,
      gravity: 0.28,
      shouldLoop: false,
      colors: colors,
      // Small rectangles, like real paper — the default circles read
      // as bubbles.
      createParticlePath: _paper,
    ),
  );

  /// A scrap of paper: a rectangle half as wide as it is long.
  static Path _paper(Size size) {
    final w = size.width;
    return Path()..addRect(Rect.fromLTWH(0, 0, w * 0.6, w * 0.28));
  }
}
