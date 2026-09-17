import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Inner Shadow Painter
// ---------------------------------------------------------------------------

class ImageInnerShadowPainter extends CustomPainter {
  ImageInnerShadowPainter({required this.shadow, required this.borderRadius});

  final BoxShadow shadow;
  final BorderRadius borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = borderRadius.toRRect(rect);

    canvas.save();
    canvas.clipRRect(rrect);

    final paint = Paint()
      ..color = shadow.color
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, shadow.blurRadius);

    final outer = rect.inflate(shadow.blurRadius * 2 + shadow.spreadRadius);
    final inner = rrect.shift(shadow.offset).deflate(shadow.spreadRadius);

    final path = Path()
      ..addRect(outer)
      ..addRRect(inner)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(ImageInnerShadowPainter oldDelegate) =>
      shadow != oldDelegate.shadow || borderRadius != oldDelegate.borderRadius;
}

// ---------------------------------------------------------------------------
// Gradient Border Painter
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Loading sheen
// ---------------------------------------------------------------------------

/// A band of light that sweeps across a still-loading picture.
///
/// NOT `GlobalShimmer`: that paints an opaque plate and recolours its
/// child through a shader, which is right for a skeleton block and
/// wrong here — it would cover the BlurHash whose whole point is to
/// show the picture's own shapes. This sits ON TOP and only adds light.
///
/// A blur alone is ambiguous: it reads as a photograph that has arrived
/// and is out of focus. The sweep is what says one is still coming.
class ImageLoadingSheen extends StatefulWidget {
  const ImageLoadingSheen({
    required this.child,
    required this.color,
    required this.period,
    required this.bandFraction,
    super.key,
  });

  final Widget child;

  /// Already at the opacity it should paint — the sweep's centre.
  final Color color;

  final Duration period;

  /// Band width as a share of the box.
  final double bandFraction;

  @override
  State<ImageLoadingSheen> createState() => _ImageLoadingSheenState();
}

class _ImageLoadingSheenState extends State<ImageLoadingSheen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.period,
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.passthrough,
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => CustomPaint(
                painter: _SheenPainter(
                  progress: _controller.value,
                  color: widget.color,
                  bandFraction: widget.bandFraction,
                  textDirection: Directionality.of(context),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SheenPainter extends CustomPainter {
  _SheenPainter({
    required this.progress,
    required this.color,
    required this.bandFraction,
    required this.textDirection,
  });

  final double progress;
  final Color color;
  final double bandFraction;
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final band = bandFraction.clamp(0.05, 1.0);
    // Travels a full band's width past each edge, so the sweep enters
    // and leaves rather than appearing mid-box.
    final span = 1 + band * 2;
    final start = (progress * span) - band;
    final rtl = textDirection == TextDirection.rtl;

    final gradient = LinearGradient(
      begin: rtl ? Alignment.centerRight : Alignment.centerLeft,
      end: rtl ? Alignment.centerLeft : Alignment.centerRight,
      colors: [color.withValues(alpha: 0), color, color.withValues(alpha: 0)],
      stops: [
        (start - band / 2).clamp(0.0, 1.0),
        start.clamp(0.0, 1.0),
        (start + band / 2).clamp(0.0, 1.0),
      ],
    );

    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));
  }

  @override
  bool shouldRepaint(covariant _SheenPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.bandFraction != bandFraction ||
      old.textDirection != textDirection;
}
