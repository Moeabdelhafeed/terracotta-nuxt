import 'package:flutter/material.dart';

import 'scanner_models.dart';

/// The viewfinder: a dim everywhere else, four brackets, and a line
/// that sweeps to say the camera is live.
///
/// It takes a RESOLVED bag. It used to answer the accent itself out of
/// the widget's `build`, so the box and the controls beside it could
/// disagree about what the brand colour was.
class ScannerViewfinder extends StatefulWidget {
  const ScannerViewfinder({
    required this.style,
    this.acceptedCount = 0,
    super.key,
  });

  final ResolvedScannerStyle style;

  /// How many codes have been accepted. A COUNTER rather than a flag:
  /// two reads in a row have to flash twice, and a bool that is
  /// already true says nothing the second time.
  final int acceptedCount;

  @override
  State<ScannerViewfinder> createState() => _ScannerViewfinderState();
}

class _ScannerViewfinderState extends State<ScannerViewfinder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: ScannerDefaults.scanLinePeriod,
  );

  /// The flash a read leaves. Separate controller, because it has to
  /// run WHILE the sweep does — one controller cannot hold two
  /// animations at different speeds.
  late final AnimationController _flash = AnimationController(
    vsync: this,
    duration: ScannerDefaults.successFlash,
  );

  @override
  void didUpdateWidget(covariant ScannerViewfinder old) {
    super.didUpdateWidget(old);
    if (widget.acceptedCount == old.acceptedCount) return;
    if (!widget.style.showSuccessFlash) return;
    // Reduced motion drops the flash with everything else. The haptic
    // and the caller's own answer to the read both still happen.
    if (MediaQuery.disableAnimationsOf(context)) return;
    _flash
      ..value = 1
      ..reverse();
  }

  @override
  void dispose() {
    _sweep.dispose();
    _flash.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Reduced motion STILLS the line rather than shortening it: it is
    // an affordance, not information, so removing it costs nothing.
    // The dim and the brackets stay — those ARE the information.
    final still =
        !widget.style.showScanLine || MediaQuery.disableAnimationsOf(context);
    if (still) {
      _sweep.stop();
    } else if (!_sweep.isAnimating) {
      _sweep.repeat(reverse: true);
    }

    return ExcludeSemantics(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: Listenable.merge([_sweep, _flash]),
          builder: (_, _) => CustomPaint(
            painter: ScannerViewfinderPainter(
              style: widget.style,
              sweep: still ? null : _sweep.value,
              flash: _flash.value,
            ),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }
}

/// Draws the dim, the brackets and the sweeping line.
///
/// The rect comes from `ResolvedScannerStyle.viewfinderRect` — the
/// same answer the scan window is built from, so what is drawn and
/// what is READ cannot drift apart.
class ScannerViewfinderPainter extends CustomPainter {
  const ScannerViewfinderPainter({
    required this.style,
    required this.sweep,
    this.flash = 0,
  });

  final ResolvedScannerStyle style;

  /// 0..1 down the window, or null when the line is not drawn.
  final double? sweep;

  /// 1 at the moment of a read, fading to 0.
  final double flash;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = style.viewfinderRect(size);
    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(style.cornerRadius),
    );

    // Dim everything outside the viewfinder.
    if (style.dimColor.a > 0) {
      final dim = Paint()..color = style.dimColor;
      final outer = Path()..addRect(Offset.zero & size);
      final inner = Path()..addRRect(rrect);
      canvas.drawPath(
        Path.combine(PathOperation.difference, outer, inner),
        dim,
      );
    }

    _paintSweep(canvas, rrect);
    _paintBrackets(canvas, rect);
  }

  /// Where the sweep line sits, for a window and a phase.
  ///
  /// Pure and named because it is the one number in this painter that
  /// can be wrong in a way nobody sees until a device is in hand — a
  /// line that starts or ends outside the box it belongs to.
  @visibleForTesting
  static double sweepLineY(Rect window, double t) =>
      window.top + window.height * t.clamp(0.0, 1.0);

  void _paintSweep(Canvas canvas, RRect rrect) {
    final t = sweep;
    if (t == null) return;
    final rect = rrect.outerRect;
    final y = sweepLineY(rect, t);
    canvas
      ..save()
      // Clipped to the window, so the glow does not bleed over the dim
      // and read as a second, softer box.
      ..clipRRect(rrect)
      ..drawRect(
        Rect.fromLTWH(
          rect.left,
          y - ScannerDefaults.scanLineHeight / 2,
          rect.width,
          ScannerDefaults.scanLineHeight,
        ),
        Paint()
          ..shader = LinearGradient(
            colors: [
              style.viewfinderColor.withValues(alpha: 0),
              style.viewfinderColor,
              style.viewfinderColor.withValues(alpha: 0),
            ],
          ).createShader(rect)
          ..maskFilter = const MaskFilter.blur(
            BlurStyle.normal,
            ScannerDefaults.scanLineGlow / 4,
          ),
      )
      ..restore();
  }

  /// The four corner brackets, as paths.
  ///
  /// Lifted out of `paint` so their geometry can be checked at all:
  /// there are no golden files here, and four hand-written path
  /// sequences with a mirrored arc apiece is exactly the kind of code
  /// that is wrong in one corner only.
  @visibleForTesting
  static List<Path> bracketPaths({
    required Rect rect,
    required double length,
    required double radius,
  }) {
    final l = length;
    final r = radius;
    return [
      Path()
        ..moveTo(rect.left, rect.top + l + r)
        ..lineTo(rect.left, rect.top + r)
        ..arcToPoint(
          Offset(rect.left + r, rect.top),
          radius: Radius.circular(r),
        )
        ..lineTo(rect.left + r + l, rect.top),
      Path()
        ..moveTo(rect.right - r - l, rect.top)
        ..lineTo(rect.right - r, rect.top)
        ..arcToPoint(
          Offset(rect.right, rect.top + r),
          radius: Radius.circular(r),
        )
        ..lineTo(rect.right, rect.top + r + l),
      Path()
        ..moveTo(rect.right, rect.bottom - r - l)
        ..lineTo(rect.right, rect.bottom - r)
        ..arcToPoint(
          Offset(rect.right - r, rect.bottom),
          radius: Radius.circular(r),
        )
        ..lineTo(rect.right - r - l, rect.bottom),
      Path()
        ..moveTo(rect.left + r + l, rect.bottom)
        ..lineTo(rect.left + r, rect.bottom)
        ..arcToPoint(
          Offset(rect.left, rect.bottom - r),
          radius: Radius.circular(r),
        )
        ..lineTo(rect.left, rect.bottom - r - l),
    ];
  }

  void _paintBrackets(Canvas canvas, Rect rect) {
    // The brackets themselves carry the success, rather than a plate
    // over the picture: they are already where the reader is looking,
    // and a plate would cover the code that was just read.
    final colour = flash <= 0
        ? style.viewfinderColor
        : Color.lerp(style.viewfinderColor, style.successColor, flash)!;
    final stroke = Paint()
      ..color = colour
      ..style = PaintingStyle.stroke
      ..strokeWidth = style.cornerWidth
      ..strokeCap = StrokeCap.round;

    for (final path in bracketPaths(
      rect: rect,
      length: style.cornerLength,
      radius: style.cornerRadius,
    )) {
      canvas.drawPath(path, stroke);
    }
  }

  @override
  bool shouldRepaint(ScannerViewfinderPainter old) =>
      old.style != style || old.sweep != sweep || old.flash != flash;
}
