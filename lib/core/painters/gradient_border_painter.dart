import 'package:flutter/material.dart';

/// Strokes a rounded rectangle with a gradient.
///
/// Ten modules carried a private copy of this — popup, buttons, toast,
/// chip, checkbox, switch, segmented control, toggle group, image and
/// banner — with the same twelve lines and small differences nobody
/// intended: some guarded an empty canvas and some did not, one called
/// the width `strokeWidth` and the rest `borderWidth`.
///
/// Flutter has no gradient `BoxBorder`, which is why everyone wrote it.
/// It lives in core because it is framework-shaped: no palette, no
/// tokens, no module of its own to belong to.
class GradientBorderPainter extends CustomPainter {
  const GradientBorderPainter({
    required this.gradient,
    required this.borderRadius,
    required this.borderWidth,
  });

  final Gradient gradient;
  final BorderRadius borderRadius;
  final double borderWidth;

  @override
  void paint(Canvas canvas, Size size) {
    // A shader on a zero-sized rect throws rather than drawing nothing.
    if (size.isEmpty || borderWidth <= 0) return;

    final rect = Offset.zero & size;
    // Deflated by half the stroke: a stroke straddles its path, so the
    // outer half would otherwise paint outside the box it belongs to.
    final rrect = borderRadius.toRRect(rect).deflate(borderWidth / 2);

    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = gradient.createShader(rect)
        ..strokeWidth = borderWidth
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(GradientBorderPainter old) =>
      gradient != old.gradient ||
      borderRadius != old.borderRadius ||
      borderWidth != old.borderWidth;
}
