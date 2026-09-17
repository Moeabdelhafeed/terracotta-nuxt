import 'package:flutter/material.dart';

import 'tab_bar_models.dart';

/// Indicator decorations Material does not ship.
///
/// `UnderlineTabIndicator`, a `BoxDecoration` pill and a `BoxDecoration`
/// fill cover three of the six [TabIndicatorStyle] values. These two
/// paint the rest.

// ---------------------------------------------------------------------------
// Dot
// ---------------------------------------------------------------------------

/// A small dot centred below the tab, in place of an underline.
@immutable
class DotTabIndicator extends Decoration {
  const DotTabIndicator({
    required this.color,
    this.size = TabBarDefaults.dotIndicatorSize,
    this.margin = TabBarDefaults.dotIndicatorMargin,
  });

  final Color color;
  final double size;

  /// Gap between the dot's bottom edge and the tab's.
  final double margin;

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) => _DotPainter(this);

  @override
  bool operator ==(Object other) =>
      other is DotTabIndicator &&
      other.color == color &&
      other.size == size &&
      other.margin == margin;

  @override
  int get hashCode => Object.hash(color, size, margin);
}

class _DotPainter extends BoxPainter {
  _DotPainter(this.spec);
  final DotTabIndicator spec;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final size = configuration.size ?? Size.zero;
    canvas.drawCircle(
      Offset(
        offset.dx + size.width / 2,
        offset.dy + size.height - spec.size / 2 - spec.margin,
      ),
      spec.size / 2,
      Paint()..color = spec.color,
    );
  }
}

// ---------------------------------------------------------------------------
// Gradient underline
// ---------------------------------------------------------------------------

/// An underline stroked with a gradient.
///
/// `UnderlineTabIndicator` takes a `BorderSide`, which carries a single
/// colour — there is no way to hand it a shader, hence a painter.
@immutable
class GradientUnderlineTabIndicator extends Decoration {
  const GradientUnderlineTabIndicator({
    required this.gradient,
    required this.weight,
    required this.radius,
  });

  final Gradient gradient;
  final double weight;
  final double radius;

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) =>
      _GradientUnderlinePainter(this);

  @override
  bool operator ==(Object other) =>
      other is GradientUnderlineTabIndicator &&
      other.gradient == gradient &&
      other.weight == weight &&
      other.radius == radius;

  @override
  int get hashCode => Object.hash(gradient, weight, radius);
}

class _GradientUnderlinePainter extends BoxPainter {
  _GradientUnderlinePainter(this.spec);
  final GradientUnderlineTabIndicator spec;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final size = configuration.size ?? Size.zero;
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        offset.dx,
        offset.dy + size.height - spec.weight,
        size.width,
        spec.weight,
      ),
      Radius.circular(spec.radius),
    );
    canvas.drawRRect(
      rect,
      Paint()..shader = spec.gradient.createShader(rect.outerRect),
    );
  }
}
