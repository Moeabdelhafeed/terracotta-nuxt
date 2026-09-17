import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

/// Direction modifier for [RevealStrategy]s. Different strategies accept
/// different subsets — see [RevealStrategy.supportedDirections].
enum RevealDirection {
  /// Radial: shape grows outward from origin.
  expand,

  /// Radial: shape shrinks inward to origin.
  collapse,

  /// Linear: edge travels left → right.
  leftToRight,

  /// Linear: edge travels right → left.
  rightToLeft,

  /// Linear: edge travels top → bottom.
  topToBottom,

  /// Linear: edge travels bottom → top.
  bottomToTop,

  /// Linear: edge angled, top-left → bottom-right.
  diagonalDown,

  /// Linear: edge angled, bottom-left → top-right.
  diagonalUp;

  String get label => switch (this) {
    expand => 'Expand',
    collapse => 'Collapse',
    leftToRight => 'Left → Right',
    rightToLeft => 'Right → Left',
    topToBottom => 'Top → Bottom',
    bottomToTop => 'Bottom → Top',
    diagonalDown => 'Diagonal ↘',
    diagonalUp => 'Diagonal ↗',
  };

  static RevealDirection fromName(
    String name, {
    RevealDirection fallback = RevealDirection.expand,
  }) {
    for (final d in values) {
      if (d.name == name) return d;
    }
    return fallback;
  }
}

/// Renders the OLD-frame snapshot transition that uncovers the live
/// (already-mutated) tree underneath. Each concrete strategy chooses
/// its own technique — clip-path for shape-based reveals, opacity +
/// scale + blur for the morph cross-fade.
@immutable
abstract class RevealStrategy {
  const RevealStrategy();

  /// Stable id — used for prefs persistence + lookup.
  String get key;

  /// Human label for pickers.
  String get label;

  /// Directions this strategy understands. UI uses this to show only
  /// valid options. Falls back to [defaultDirection] when an unsupported
  /// value is passed.
  List<RevealDirection> get supportedDirections;

  /// Direction used when none is provided / when the requested one is
  /// unsupported.
  RevealDirection get defaultDirection;

  /// Build the animated overlay that paints the [snapshot] transitioning
  /// out. Driven by [progress] (already curve-applied, `0 → 1`).
  Widget buildOverlay({
    required ui.Image snapshot,
    required Animation<double> progress,
    required Offset origin,
    required Size size,
    required RevealDirection direction,
  });

  /// Resolve a direction the strategy supports — returns [direction] if
  /// listed in [supportedDirections], else [defaultDirection].
  RevealDirection resolveDirection(RevealDirection direction) {
    return supportedDirections.contains(direction)
        ? direction
        : defaultDirection;
  }

  // ─── Built-in strategies ─────────────────────────────────────
  static const RevealStrategy circle = _CircleStrategy();
  static const RevealStrategy oval = _OvalStrategy();
  static const RevealStrategy horizontalSweep = _HorizontalSweepStrategy();
  static const RevealStrategy verticalSweep = _VerticalSweepStrategy();
  static const RevealStrategy diagonalSweep = _DiagonalSweepStrategy();
  static const RevealStrategy diamond = _DiamondStrategy();
  static const RevealStrategy morph = _MorphStrategy();

  /// All built-in strategies, in display order.
  static const List<RevealStrategy> values = [
    circle,
    oval,
    horizontalSweep,
    verticalSweep,
    diagonalSweep,
    diamond,
    morph,
  ];

  /// Look up a built-in strategy by [key]. Returns [circle] when unknown.
  static RevealStrategy fromKey(String key) {
    for (final s in values) {
      if (s.key == key) return s;
    }
    return circle;
  }

  // ─── Helpers ─────────────────────────────────────────────────

  static double maxDistanceToCorner(Offset origin, Size size) {
    final corners = <Offset>[
      Offset.zero,
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height),
    ];
    return corners
        .map((c) => (c - origin).distance)
        .reduce((a, b) => a > b ? a : b);
  }
}

/// Backwards-compatible alias — old call-sites still reference
/// `RevealShape`. The picker name in the UI also reads more
/// naturally as "shape".
typedef RevealShape = RevealStrategy;

// ─── Clip-based strategies ─────────────────────────────────────

/// Base for strategies that uncover the live tree by clipping the
/// snapshot to a shrinking visible region.
abstract class _ClipStrategy extends RevealStrategy {
  const _ClipStrategy();

  /// Path describing where the [snapshot] should remain visible.
  /// As [progress] goes `0 → 1` this region must shrink to nothing —
  /// what's underneath (the live tree) becomes visible everywhere else.
  Path buildVisiblePath({
    required Offset origin,
    required Size size,
    required double progress,
    required RevealDirection direction,
  });

  @override
  Widget buildOverlay({
    required ui.Image snapshot,
    required Animation<double> progress,
    required Offset origin,
    required Size size,
    required RevealDirection direction,
  }) {
    final resolved = resolveDirection(direction);
    return AnimatedBuilder(
      animation: progress,
      builder: (context, _) {
        return ClipPath(
          clipper: _StrategyClipper(
            strategy: this,
            origin: origin,
            size: size,
            progress: progress.value,
            direction: resolved,
          ),
          child: IgnorePointer(
            child: RawImage(
              image: snapshot,
              fit: BoxFit.cover,
              width: size.width,
              height: size.height,
            ),
          ),
        );
      },
    );
  }
}

class _StrategyClipper extends CustomClipper<Path> {
  _StrategyClipper({
    required this.strategy,
    required this.origin,
    required this.size,
    required this.progress,
    required this.direction,
  });

  final _ClipStrategy strategy;
  final Offset origin;
  final Size size;
  final double progress;
  final RevealDirection direction;

  @override
  Path getClip(Size _) => strategy.buildVisiblePath(
    origin: origin,
    size: size,
    progress: progress,
    direction: direction,
  );

  @override
  bool shouldReclip(_StrategyClipper old) =>
      old.progress != progress ||
      old.origin != origin ||
      old.size != size ||
      old.direction != direction ||
      old.strategy != strategy;
}

/// Build "everywhere except [hole]" clip path (snapshot painted around
/// the hole). Used by radial strategies in [RevealDirection.expand].
Path _outsideHole(Size size, Path hole) {
  return Path()
    ..fillType = PathFillType.evenOdd
    ..addRect(Offset.zero & size)
    ..addPath(hole, Offset.zero);
}

// ─── Circle ────────────────────────────────────────────────────

class _CircleStrategy extends _ClipStrategy {
  const _CircleStrategy();

  @override
  String get key => 'circle';

  @override
  String get label => 'Circle';

  @override
  List<RevealDirection> get supportedDirections => const [
    RevealDirection.expand,
    RevealDirection.collapse,
  ];

  @override
  RevealDirection get defaultDirection => RevealDirection.expand;

  @override
  Path buildVisiblePath({
    required Offset origin,
    required Size size,
    required double progress,
    required RevealDirection direction,
  }) {
    final maxR = RevealStrategy.maxDistanceToCorner(origin, size);
    if (direction == RevealDirection.collapse) {
      // Snapshot visible inside SHRINKING circle.
      final r = math.max((1 - progress) * maxR, 0.0001);
      return Path()..addOval(Rect.fromCircle(center: origin, radius: r));
    }
    // expand: snapshot visible everywhere except GROWING circle.
    final r = math.max(progress * maxR, 0.0001);
    final hole = Path()..addOval(Rect.fromCircle(center: origin, radius: r));
    return _outsideHole(size, hole);
  }
}

// ─── Oval (1.6:1, wider than tall) ─────────────────────────────

class _OvalStrategy extends _ClipStrategy {
  const _OvalStrategy();

  @override
  String get key => 'oval';

  @override
  String get label => 'Oval';

  @override
  List<RevealDirection> get supportedDirections => const [
    RevealDirection.expand,
    RevealDirection.collapse,
  ];

  @override
  RevealDirection get defaultDirection => RevealDirection.expand;

  Rect _ovalRect(Offset origin, Size size, double progress) {
    final maxR = RevealStrategy.maxDistanceToCorner(origin, size);
    final rx = progress * maxR * 1.4;
    final ry = progress * maxR * 0.85;
    return Rect.fromCenter(
      center: origin,
      width: math.max(rx * 2, 0.0001),
      height: math.max(ry * 2, 0.0001),
    );
  }

  @override
  Path buildVisiblePath({
    required Offset origin,
    required Size size,
    required double progress,
    required RevealDirection direction,
  }) {
    if (direction == RevealDirection.collapse) {
      final rect = _ovalRect(origin, size, 1 - progress);
      return Path()..addOval(rect);
    }
    final rect = _ovalRect(origin, size, progress);
    final hole = Path()..addOval(rect);
    return _outsideHole(size, hole);
  }
}

// ─── Diamond (rotated square) ──────────────────────────────────

class _DiamondStrategy extends _ClipStrategy {
  const _DiamondStrategy();

  @override
  String get key => 'diamond';

  @override
  String get label => 'Diamond';

  @override
  List<RevealDirection> get supportedDirections => const [
    RevealDirection.expand,
    RevealDirection.collapse,
  ];

  @override
  RevealDirection get defaultDirection => RevealDirection.expand;

  Path _diamond(Offset origin, double radius) {
    final r = math.max(radius, 0.0001);
    return Path()
      ..moveTo(origin.dx, origin.dy - r)
      ..lineTo(origin.dx + r, origin.dy)
      ..lineTo(origin.dx, origin.dy + r)
      ..lineTo(origin.dx - r, origin.dy)
      ..close();
  }

  @override
  Path buildVisiblePath({
    required Offset origin,
    required Size size,
    required double progress,
    required RevealDirection direction,
  }) {
    final maxR = RevealStrategy.maxDistanceToCorner(origin, size);
    if (direction == RevealDirection.collapse) {
      return _diamond(origin, (1 - progress) * maxR);
    }
    final hole = _diamond(origin, progress * maxR);
    return _outsideHole(size, hole);
  }
}

// ─── Horizontal sweep (single edge traverses screen) ───────────

class _HorizontalSweepStrategy extends _ClipStrategy {
  const _HorizontalSweepStrategy();

  @override
  String get key => 'horizontalSweep';

  @override
  String get label => 'Horizontal';

  @override
  List<RevealDirection> get supportedDirections => const [
    RevealDirection.leftToRight,
    RevealDirection.rightToLeft,
  ];

  @override
  RevealDirection get defaultDirection => RevealDirection.leftToRight;

  @override
  Path buildVisiblePath({
    required Offset origin,
    required Size size,
    required double progress,
    required RevealDirection direction,
  }) {
    final w = size.width;
    final h = size.height;
    // leftToRight: edge travels rightward → snapshot visible right portion.
    // rightToLeft: edge travels leftward → snapshot visible left portion.
    final visibleWidth = math.max(w * (1 - progress), 0.0001);
    final left = direction == RevealDirection.leftToRight
        ? w - visibleWidth
        : 0.0;
    return Path()..addRect(Rect.fromLTWH(left, 0, visibleWidth, h));
  }
}

// ─── Vertical sweep (single edge traverses screen) ─────────────

class _VerticalSweepStrategy extends _ClipStrategy {
  const _VerticalSweepStrategy();

  @override
  String get key => 'verticalSweep';

  @override
  String get label => 'Vertical';

  @override
  List<RevealDirection> get supportedDirections => const [
    RevealDirection.topToBottom,
    RevealDirection.bottomToTop,
  ];

  @override
  RevealDirection get defaultDirection => RevealDirection.topToBottom;

  @override
  Path buildVisiblePath({
    required Offset origin,
    required Size size,
    required double progress,
    required RevealDirection direction,
  }) {
    final w = size.width;
    final h = size.height;
    final visibleHeight = math.max(h * (1 - progress), 0.0001);
    final top = direction == RevealDirection.topToBottom
        ? h - visibleHeight
        : 0.0;
    return Path()..addRect(Rect.fromLTWH(0, top, w, visibleHeight));
  }
}

// ─── Diagonal sweep (single angled edge) ───────────────────────

class _DiagonalSweepStrategy extends _ClipStrategy {
  const _DiagonalSweepStrategy();

  @override
  String get key => 'diagonalSweep';

  @override
  String get label => 'Diagonal';

  @override
  List<RevealDirection> get supportedDirections => const [
    RevealDirection.diagonalDown,
    RevealDirection.diagonalUp,
  ];

  @override
  RevealDirection get defaultDirection => RevealDirection.diagonalDown;

  @override
  Path buildVisiblePath({
    required Offset origin,
    required Size size,
    required double progress,
    required RevealDirection direction,
  }) {
    // Line normal — direction the edge moves. diagonalDown: bottom-right.
    // diagonalUp: top-right.
    const k = 0.7071067811865476; // √2 / 2
    final normal = direction == RevealDirection.diagonalUp
        ? const Offset(k, -k)
        : const Offset(k, k);
    final corners = <Offset>[
      Offset.zero,
      Offset(size.width, 0),
      Offset(size.width, size.height),
      Offset(0, size.height),
    ];
    double s(Offset p) => p.dx * normal.dx + p.dy * normal.dy;
    final sValues = corners.map(s).toList(growable: false);
    final sMin = sValues.reduce(math.min);
    final sMax = sValues.reduce(math.max);
    // Edge sweeps from "behind everything" → "past everything".
    // Snapshot is visible AHEAD of the edge (s(p) > sLine).
    final sLine = sMin + (sMax - sMin) * progress;
    return _clipRectByHalfPlane(corners: corners, normal: normal, sLine: sLine);
  }
}

/// Sutherland-Hodgman clip of a convex polygon (the screen rect) by the
/// half-plane `p · normal > sLine`.
Path _clipRectByHalfPlane({
  required List<Offset> corners,
  required Offset normal,
  required double sLine,
}) {
  double s(Offset p) => p.dx * normal.dx + p.dy * normal.dy;
  final out = <Offset>[];
  for (var i = 0; i < corners.length; i++) {
    final cur = corners[i];
    final next = corners[(i + 1) % corners.length];
    final sCur = s(cur);
    final sNext = s(next);
    final inCur = sCur > sLine;
    final inNext = sNext > sLine;
    if (inCur) out.add(cur);
    if (inCur != inNext) {
      final t = (sLine - sCur) / (sNext - sCur);
      out.add(
        Offset(
          cur.dx + (next.dx - cur.dx) * t,
          cur.dy + (next.dy - cur.dy) * t,
        ),
      );
    }
  }
  if (out.isEmpty) {
    return Path()..addRect(Rect.zero);
  }
  final path = Path()..moveTo(out.first.dx, out.first.dy);
  for (var i = 1; i < out.length; i++) {
    path.lineTo(out[i].dx, out[i].dy);
  }
  path.close();
  return path;
}

// ─── Morph (PowerPoint-style cross-fade + scale + blur) ────────

class _MorphStrategy extends RevealStrategy {
  const _MorphStrategy();

  @override
  String get key => 'morph';

  @override
  String get label => 'Morph';

  @override
  List<RevealDirection> get supportedDirections => const [
    RevealDirection.expand,
  ];

  @override
  RevealDirection get defaultDirection => RevealDirection.expand;

  @override
  Widget buildOverlay({
    required ui.Image snapshot,
    required Animation<double> progress,
    required Offset origin,
    required Size size,
    required RevealDirection direction,
  }) {
    return AnimatedBuilder(
      animation: progress,
      builder: (context, _) {
        final t = progress.value.clamp(0.0, 1.0);
        final opacity = 1.0 - t;
        final scale = 1.0 + t * 0.06;
        final blur = t * 6.0;
        Widget image = RawImage(
          image: snapshot,
          fit: BoxFit.cover,
          width: size.width,
          height: size.height,
        );
        if (blur > 0.001) {
          image = ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
            child: image,
          );
        }
        return IgnorePointer(
          child: Opacity(
            opacity: opacity,
            child: Transform.scale(scale: scale, child: image),
          ),
        );
      },
    );
  }
}
