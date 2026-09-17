import 'package:flutter/material.dart';

import 'popup_enums.dart';

/// Sealed width strategy for the overlay surface.
sealed class GlobalPopupWidth {
  const GlobalPopupWidth();

  /// Overlay matches anchor's measured width.
  const factory GlobalPopupWidth.matchAnchor() = WidthMatchAnchor;

  /// Overlay at least as wide as the anchor; may grow with content.
  const factory GlobalPopupWidth.minAnchor({double? max}) = WidthMinAnchor;

  /// Exact width in pixels.
  const factory GlobalPopupWidth.fixed(double width) = WidthFixed;

  /// Fraction of screen width (0..1).
  const factory GlobalPopupWidth.fraction(double fraction) = WidthFraction;

  /// Let the content size itself. Surface wraps content tight.
  const factory GlobalPopupWidth.content({double? min, double? max}) =
      WidthContent;

  /// Span the screen minus [inset] on BOTH edges, aligned to the screen
  /// (not the anchor) — a narrow trigger can open a screen-wide overlay
  /// (e.g. a country picker). Vertical placements only; symmetric, so
  /// RTL-agnostic.
  const factory GlobalPopupWidth.screenInset({double inset}) = WidthScreenInset;
}

class WidthMatchAnchor extends GlobalPopupWidth {
  const WidthMatchAnchor();
}

class WidthMinAnchor extends GlobalPopupWidth {
  const WidthMinAnchor({this.max});
  final double? max;
}

class WidthFixed extends GlobalPopupWidth {
  const WidthFixed(this.width);
  final double width;
}

class WidthFraction extends GlobalPopupWidth {
  const WidthFraction(this.fraction);
  final double fraction;
}

class WidthContent extends GlobalPopupWidth {
  const WidthContent({this.min, this.max});
  final double? min;
  final double? max;
}

class WidthScreenInset extends GlobalPopupWidth {
  const WidthScreenInset({this.inset = 16});
  final double inset;
}

/// Internal helper: anchor/follower Alignments + axis hint for a given
/// [GlobalPopupPlacement]. Consumed by the controller (positioning) and
/// surface arrow renderer.
@immutable
class PlacementGeometry {
  const PlacementGeometry({
    required this.target,
    required this.follower,
    required this.axis,
    required this.isVertical,
    required this.isAbove,
    required this.isLeading,
  });

  final Alignment target;
  final Alignment follower;
  final Axis axis;

  /// `true` = placement is top/bottom (vertical axis), else start/end.
  final bool isVertical;

  /// For vertical placements: above the anchor.
  /// For horizontal: ignored (use [isLeading] for start/end).
  final bool isAbove;

  /// For horizontal placements: on the start (left in LTR) side.
  final bool isLeading;
}

/// Maps a semantic [GlobalPopupPlacement] (`start` / `end` are
/// reading-direction aware) to the PHYSICAL placement actually used
/// for layout under the given [direction].
///
/// In LTR the input is returned unchanged. In RTL `start` and `end`
/// swap so all downstream code (placement geometry, width budget,
/// arrow side selection) can keep working in physical left/right
/// terms.
GlobalPopupPlacement physicalPlacement(
  GlobalPopupPlacement p,
  TextDirection direction,
) {
  if (direction == TextDirection.ltr) return p;
  switch (p) {
    case GlobalPopupPlacement.bottomStart:
      return GlobalPopupPlacement.bottomEnd;
    case GlobalPopupPlacement.bottomEnd:
      return GlobalPopupPlacement.bottomStart;
    case GlobalPopupPlacement.topStart:
      return GlobalPopupPlacement.topEnd;
    case GlobalPopupPlacement.topEnd:
      return GlobalPopupPlacement.topStart;
    case GlobalPopupPlacement.startTop:
      return GlobalPopupPlacement.endTop;
    case GlobalPopupPlacement.start:
      return GlobalPopupPlacement.end;
    case GlobalPopupPlacement.startBottom:
      return GlobalPopupPlacement.endBottom;
    case GlobalPopupPlacement.endTop:
      return GlobalPopupPlacement.startTop;
    case GlobalPopupPlacement.end:
      return GlobalPopupPlacement.start;
    case GlobalPopupPlacement.endBottom:
      return GlobalPopupPlacement.startBottom;
    case GlobalPopupPlacement.auto:
    case GlobalPopupPlacement.atTap:
    case GlobalPopupPlacement.top:
    case GlobalPopupPlacement.bottom:
      return p;
  }
}

/// Resolve a [GlobalPopupPlacement] to its [PlacementGeometry].
PlacementGeometry resolvePlacement(GlobalPopupPlacement p) {
  switch (p) {
    case GlobalPopupPlacement.auto:
    case GlobalPopupPlacement.atTap:
    case GlobalPopupPlacement.bottomStart:
      return const PlacementGeometry(
        target: Alignment.bottomLeft,
        follower: Alignment.topLeft,
        axis: Axis.vertical,
        isVertical: true,
        isAbove: false,
        isLeading: true,
      );
    case GlobalPopupPlacement.bottom:
      return const PlacementGeometry(
        target: Alignment.bottomCenter,
        follower: Alignment.topCenter,
        axis: Axis.vertical,
        isVertical: true,
        isAbove: false,
        isLeading: true,
      );
    case GlobalPopupPlacement.bottomEnd:
      return const PlacementGeometry(
        target: Alignment.bottomRight,
        follower: Alignment.topRight,
        axis: Axis.vertical,
        isVertical: true,
        isAbove: false,
        isLeading: false,
      );
    case GlobalPopupPlacement.topStart:
      return const PlacementGeometry(
        target: Alignment.topLeft,
        follower: Alignment.bottomLeft,
        axis: Axis.vertical,
        isVertical: true,
        isAbove: true,
        isLeading: true,
      );
    case GlobalPopupPlacement.top:
      return const PlacementGeometry(
        target: Alignment.topCenter,
        follower: Alignment.bottomCenter,
        axis: Axis.vertical,
        isVertical: true,
        isAbove: true,
        isLeading: true,
      );
    case GlobalPopupPlacement.topEnd:
      return const PlacementGeometry(
        target: Alignment.topRight,
        follower: Alignment.bottomRight,
        axis: Axis.vertical,
        isVertical: true,
        isAbove: true,
        isLeading: false,
      );
    case GlobalPopupPlacement.startTop:
      return const PlacementGeometry(
        target: Alignment.topLeft,
        follower: Alignment.topRight,
        axis: Axis.horizontal,
        isVertical: false,
        isAbove: false,
        isLeading: true,
      );
    case GlobalPopupPlacement.start:
      return const PlacementGeometry(
        target: Alignment.centerLeft,
        follower: Alignment.centerRight,
        axis: Axis.horizontal,
        isVertical: false,
        isAbove: false,
        isLeading: true,
      );
    case GlobalPopupPlacement.startBottom:
      return const PlacementGeometry(
        target: Alignment.bottomLeft,
        follower: Alignment.bottomRight,
        axis: Axis.horizontal,
        isVertical: false,
        isAbove: false,
        isLeading: true,
      );
    case GlobalPopupPlacement.endTop:
      return const PlacementGeometry(
        target: Alignment.topRight,
        follower: Alignment.topLeft,
        axis: Axis.horizontal,
        isVertical: false,
        isAbove: false,
        isLeading: false,
      );
    case GlobalPopupPlacement.end:
      return const PlacementGeometry(
        target: Alignment.centerRight,
        follower: Alignment.centerLeft,
        axis: Axis.horizontal,
        isVertical: false,
        isAbove: false,
        isLeading: false,
      );
    case GlobalPopupPlacement.endBottom:
      return const PlacementGeometry(
        target: Alignment.bottomRight,
        follower: Alignment.bottomLeft,
        axis: Axis.horizontal,
        isVertical: false,
        isAbove: false,
        isLeading: false,
      );
  }
}
