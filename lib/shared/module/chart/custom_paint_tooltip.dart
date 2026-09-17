import 'package:flutter/material.dart';
// ignore: unnecessary_import — RenderProxyBox isn't re-exported by material.
import 'package:flutter/rendering.dart';

import 'chart_tooltip_overlay.dart';

export 'chart_tooltip_overlay.dart' show TooltipEntry, ChartTooltipBuilder;

/// Resolve the tooltip rows under [localPos]. Return an empty list
/// when the pointer isn't over any data datum (clears the tooltip).
typedef CustomChartHitTester =
    List<TooltipEntry> Function(
      Offset localPos,
      Size size,
    );

/// Tooltip overlay for `CustomPaint`-based charts (bullet, histogram,
/// waterfall, stepped line, etc.). Wraps the chart in a hover-aware
/// region that calls [hitTest] with the local pointer position; when
/// hits return non-empty rows the tooltip widget renders at the
/// pointer with edge-aware flipping.
///
/// Mirrors `ChartTooltipOverlay` (used by graphic charts) so the
/// look + position behavior is identical.
class CustomPaintTooltipOverlay extends StatefulWidget {
  const CustomPaintTooltipOverlay({
    required this.child,
    required this.hitTest,
    this.builder = defaultTooltipBuilder,
    this.offset = const Offset(16, 16),
    super.key,
  });

  final Widget child;
  final CustomChartHitTester hitTest;
  final ChartTooltipBuilder builder;
  final Offset offset;

  @override
  State<CustomPaintTooltipOverlay> createState() =>
      _CustomPaintTooltipOverlayState();
}

class _CustomPaintTooltipOverlayState extends State<CustomPaintTooltipOverlay> {
  Offset? _pointer;
  List<TooltipEntry> _entries = const [];
  Size? _tooltipSize;

  static const _margin = EdgeInsets.all(6);
  static const _maxTooltipWidth = 280.0;
  static const _flipDuration = Duration(milliseconds: 160);
  static const _flipCurve = Curves.easeOutCubic;

  void _update(Offset? pos, Size chartSize) {
    if (pos == null) {
      if (_pointer != null) {
        setState(() {
          _pointer = null;
          _entries = const [];
        });
      }
      return;
    }
    final hits = widget.hitTest(pos, chartSize);
    if (hits.isEmpty) {
      if (_pointer != null) {
        setState(() {
          _pointer = null;
          _entries = const [];
        });
      }
      return;
    }
    setState(() {
      _pointer = pos;
      _entries = hits;
    });
  }

  Offset _resolvePosition(Offset pointer, Size tooltipSize, Size chartSize) {
    var dx = pointer.dx + widget.offset.dx;
    if (dx + tooltipSize.width + _margin.right > chartSize.width) {
      dx = pointer.dx - widget.offset.dx - tooltipSize.width;
    }
    var dy = pointer.dy + widget.offset.dy;
    if (dy + tooltipSize.height + _margin.bottom > chartSize.height) {
      dy = pointer.dy - widget.offset.dy - tooltipSize.height;
    }
    final maxDx = (chartSize.width - tooltipSize.width - _margin.right).clamp(
      _margin.left,
      double.infinity,
    );
    final maxDy = (chartSize.height - tooltipSize.height - _margin.bottom)
        .clamp(_margin.top, double.infinity);
    dx = dx.clamp(_margin.left, maxDx);
    dy = dy.clamp(_margin.top, maxDy);
    return Offset(dx, dy);
  }

  void _onTooltipSize(Size size) {
    if (_tooltipSize == size) return;
    _tooltipSize = size;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final chartSize = Size(constraints.maxWidth, constraints.maxHeight);
        final pointer = _pointer;
        final entries = _entries;

        Widget? tooltipPositioned;
        if (pointer != null && entries.isNotEmpty) {
          final tooltipChild = IgnorePointer(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _maxTooltipWidth),
              child: _MeasureSize(
                onChange: _onTooltipSize,
                child: widget.builder(context, entries),
              ),
            ),
          );
          if (_tooltipSize == null) {
            tooltipPositioned = Positioned(
              left: -9999,
              top: -9999,
              child: Opacity(opacity: 0, child: tooltipChild),
            );
          } else {
            final target = _resolvePosition(pointer, _tooltipSize!, chartSize);
            tooltipPositioned = AnimatedPositioned(
              left: target.dx,
              top: target.dy,
              duration: _flipDuration,
              curve: _flipCurve,
              child: tooltipChild,
            );
          }
        }

        return MouseRegion(
          onHover: (e) => _update(e.localPosition, chartSize),
          onExit: (_) => _update(null, chartSize),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (d) => _update(d.localPosition, chartSize),
            onTapUp: (_) => _update(null, chartSize),
            onTapCancel: () => _update(null, chartSize),
            onLongPressMoveUpdate: (d) => _update(d.localPosition, chartSize),
            onLongPressEnd: (_) => _update(null, chartSize),
            child: Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.none,
              children: [
                widget.child,
                if (tooltipPositioned != null) tooltipPositioned,
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MeasureSize extends SingleChildRenderObjectWidget {
  const _MeasureSize({required this.onChange, required Widget super.child});

  final ValueChanged<Size> onChange;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _MeasureSizeRenderBox()..onChange = onChange;

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _MeasureSizeRenderBox renderObject,
  ) {
    renderObject.onChange = onChange;
  }
}

class _MeasureSizeRenderBox extends RenderProxyBox {
  ValueChanged<Size>? onChange;
  Size? _last;

  @override
  void performLayout() {
    super.performLayout();
    final newSize = child?.size ?? Size.zero;
    if (newSize == _last) return;
    _last = newSize;
    final cb = onChange;
    if (cb == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => cb(newSize));
  }
}
