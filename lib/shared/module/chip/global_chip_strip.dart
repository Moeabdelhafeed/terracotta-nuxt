import 'package:flutter/material.dart';

import '../../../core/tokens/extensions.dart';

/// A horizontally scrolling row of chips that keeps their shadows and
/// still stays inside its box.
///
/// An elevated chip paints its shadow OUTSIDE its own box and takes
/// exactly as much room as a flat one, so any ancestor that clips eats
/// it — a scroll view shears the selected chip's shadow off flat along
/// the bottom edge. The answer used to be `clipBehavior: Clip.none`,
/// and that traded one bug for a worse one: with clipping off entirely,
/// the chips PAST the viewport paint too, so a strip inside a card ran
/// out over the page and off the screen.
///
/// This clips on ONE axis. The rect is the strip's own width and a few
/// points of slack above and below, so the shadow has somewhere to land
/// and the scrolled-away chips do not.
class GlobalChipStrip extends StatelessWidget {
  const GlobalChipStrip({
    super.key,
    required this.children,
    this.spacing,
    this.shadowRoom = 6,
    this.padding,
    this.controller,
  });

  final List<Widget> children;

  /// Gap between chips. Defaults to `context.spacing.sm`.
  final double? spacing;

  /// How far above and below the strip a shadow may reach.
  final double shadowRoom;

  final EdgeInsetsGeometry? padding;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    final gap = spacing ?? context.spacing.sm;

    return ClipRect(
      clipper: _VerticalSlackClipper(shadowRoom),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        // The scroll view itself must NOT clip — that is what sheared
        // the shadow. The `ClipRect` outside does the bounding, on one
        // axis only.
        clipBehavior: Clip.none,
        controller: controller,
        padding: padding,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) SizedBox(width: gap),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}

/// Clips to the box's width, and lets [slack] points through above and
/// below it.
class _VerticalSlackClipper extends CustomClipper<Rect> {
  const _VerticalSlackClipper(this.slack);

  final double slack;

  @override
  Rect getClip(Size size) =>
      Rect.fromLTRB(0, -slack, size.width, size.height + slack);

  @override
  bool shouldReclip(_VerticalSlackClipper old) => old.slack != slack;
}
