import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:graphic/graphic.dart' as g;

import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/tokens/extensions.dart';
import '../image/global_image.dart';

/// One row in a custom chart tooltip — a label, value, color swatch,
/// and optional icon. Charts produce these from the currently
/// selected data points and pass them to [ChartTooltipBuilder].
@immutable
class TooltipEntry {
  const TooltipEntry({
    required this.label,
    required this.value,
    required this.color,
    this.icon,
    this.iconAsset,
    this.iconWidget,
  });

  /// Series / category name.
  final String label;

  /// Pre-formatted value (typically `AppNumbers.compact`).
  final String value;

  /// Series color — used for the swatch and icon tint.
  final Color color;

  final IconData? icon;
  final String? iconAsset;
  final Widget? iconWidget;
}

/// Build a custom tooltip widget from selected entries. Receives the
/// chart `BuildContext` so token access works (`context.spacing`,
/// `context.primaryColors`, etc.).
typedef ChartTooltipBuilder =
    Widget Function(
      BuildContext context,
      List<TooltipEntry> entries,
    );

/// Default token-themed tooltip — pill-style card with optional icons
/// per row. Fall-through when [ChartStyle.tooltipBuilder] is null
/// AND `style.useCustomTooltip == true`.
Widget defaultTooltipBuilder(BuildContext context, List<TooltipEntry> entries) {
  if (entries.isEmpty) return const SizedBox.shrink();

  final spacing = context.spacing;
  final radii = context.radii;
  final iconSizes = context.iconSizes;
  final bg = context.backgroundColors;
  final text = context.textColors;
  final theme = Theme.of(context);

  final labelStyle = theme.textTheme.labelMedium?.copyWith(
    color: text.secondary,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
  );
  final valueStyle = theme.textTheme.titleSmall?.copyWith(
    color: text.primary,
    fontWeight: FontWeight.w700,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  return Container(
    padding: EdgeInsets.symmetric(
      horizontal: spacing.md,
      vertical: spacing.sm,
    ),
    decoration: BoxDecoration(
      color: bg.cardBackground,
      borderRadius: BorderRadius.circular(radii.md),
      border: Border.all(color: bg.outlineVariant, width: 0.5),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.10),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < entries.length; i++) ...[
          if (i > 0) SizedBox(height: spacing.xs),
          _TooltipRow(
            entry: entries[i],
            labelStyle: labelStyle,
            valueStyle: valueStyle,
            iconSize: iconSizes.sm,
          ),
        ],
      ],
    ),
  );
}

class _TooltipRow extends StatelessWidget {
  const _TooltipRow({
    required this.entry,
    required this.labelStyle,
    required this.valueStyle,
    required this.iconSize,
  });

  final TooltipEntry entry;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final mark =
        entry.iconWidget ??
        (entry.iconAsset != null
            ? GlobalImage.a(entry.iconAsset!, width: iconSize, height: iconSize)
            : entry.icon != null
            ? Icon(entry.icon, size: iconSize, color: entry.color)
            : Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: entry.color,
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ));

    // `Flexible` on the Column so its Text children can wrap to
    // multiple lines instead of overflowing horizontally — long
    // tooltip values (e.g. box-plot quartile summary) need this.
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: iconSize,
          height: iconSize,
          child: Center(child: mark),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(entry.label, style: labelStyle, softWrap: true),
              Text(entry.value, style: valueStyle, softWrap: true),
            ],
          ),
        ),
      ],
    );
  }
}

/// Wraps a `graphic.Chart` in a `Stack` and overlays a Flutter widget
/// tooltip (instead of graphic's built-in canvas tooltip). The
/// overlay listens to the chart's [gestureStream] for the pointer
/// position and to a shared mark [selectionStream] for which datum
/// indexes are selected.
///
/// Pass [resolveEntries] — given a list of selected indexes, return
/// the `TooltipEntry` rows to render. Charts that flatten their data
/// across series should map indexes back to series before producing
/// entries.
class ChartTooltipOverlay extends StatefulWidget {
  const ChartTooltipOverlay({
    required this.child,
    required this.gestureStream,
    required this.selectionStream,
    required this.resolveEntries,
    this.builder = defaultTooltipBuilder,
    this.offset = const Offset(16, 16),
    super.key,
  });

  final Widget child;
  final StreamController<g.GestureEvent> gestureStream;
  final StreamController<g.Selected?> selectionStream;
  final List<TooltipEntry> Function(Set<int> selectedIndexes) resolveEntries;
  final ChartTooltipBuilder builder;

  /// Offset from the pointer to the tooltip's top-left corner.
  final Offset offset;

  @override
  State<ChartTooltipOverlay> createState() => _ChartTooltipOverlayState();
}

class _ChartTooltipOverlayState extends State<ChartTooltipOverlay> {
  StreamSubscription<g.GestureEvent>? _gestureSub;
  StreamSubscription<g.Selected?>? _selectionSub;

  Offset? _pointer;
  Set<int> _selected = const {};
  Size? _tooltipSize;

  static const _margin = EdgeInsets.all(6);
  static const _maxTooltipWidth = 280.0;
  static const _flipDuration = Duration(milliseconds: 160);
  static const _flipCurve = Curves.easeOutCubic;

  @override
  void initState() {
    super.initState();
    _gestureSub = widget.gestureStream.stream.listen(_onGesture);
    _selectionSub = widget.selectionStream.stream.listen(_onSelection);
  }

  @override
  void dispose() {
    _gestureSub?.cancel();
    _selectionSub?.cancel();
    super.dispose();
  }

  void _onGesture(g.GestureEvent event) {
    final type = event.gesture.type;
    if (type == g.GestureType.mouseExit ||
        type == g.GestureType.tapUp ||
        type == g.GestureType.longPressEnd) {
      if (mounted) setState(() => _pointer = null);
      return;
    }
    if (type == g.GestureType.hover ||
        type == g.GestureType.tapDown ||
        type == g.GestureType.longPressMoveUpdate ||
        type == g.GestureType.longPressStart) {
      if (mounted) setState(() => _pointer = event.gesture.localPosition);
    }
  }

  void _onSelection(g.Selected? selected) {
    var next = const <int>{};
    if (selected != null) {
      for (final indexes in selected.values) {
        next = {...next, ...indexes};
      }
    }
    if (mounted) setState(() => _selected = next);
  }

  /// Resolve tooltip top-left position given pointer + tooltip size +
  /// chart bounds. Flips around the pointer when tooltip would clip
  /// the right/bottom edge, then clamps to keep [_margin] from the
  /// chart edges.
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
    final pointer = _pointer;
    final selected = _selected;
    final entries = selected.isEmpty
        ? <TooltipEntry>[]
        : widget.resolveEntries(selected);

    return LayoutBuilder(
      builder: (context, constraints) {
        final tooltipSize = _tooltipSize;
        final chartSize = Size(constraints.maxWidth, constraints.maxHeight);

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

          if (tooltipSize == null) {
            // First frame — render off-screen at zero opacity so the
            // RenderBox lays out and reports its real size, then we
            // animate in on the next frame.
            tooltipPositioned = Positioned(
              left: -9999,
              top: -9999,
              child: Opacity(opacity: 0, child: tooltipChild),
            );
          } else {
            final target = _resolvePosition(pointer, tooltipSize, chartSize);
            tooltipPositioned = AnimatedPositioned(
              left: target.dx,
              top: target.dy,
              duration: _flipDuration,
              curve: _flipCurve,
              child: tooltipChild,
            );
          }
        }

        return Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: [
            widget.child,
            if (tooltipPositioned != null) tooltipPositioned,
          ],
        );
      },
    );
  }
}

/// Reports the laid-out size of [child] via [onChange] whenever it
/// changes. Used by the tooltip overlay to know the real tooltip
/// bounds so position math (flip + clamp) operates on actual size.
class _MeasureSize extends SingleChildRenderObjectWidget {
  const _MeasureSize({required this.onChange, required Widget super.child});

  final ValueChanged<Size> onChange;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _MeasureSizeRenderBox()..onChange = onChange;
  }

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
