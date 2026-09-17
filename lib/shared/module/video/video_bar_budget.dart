import 'package:flutter/foundation.dart';

/// How much room each part of the control row actually has.
///
/// This arithmetic has been wrong three times, each time by a few
/// pixels, each time found on a device rather than here — so it is a
/// value now instead of four expressions inlined in a build method.
/// The sums are trivial; what is not trivial is remembering which cost
/// comes out of which side, and that is exactly what kept going wrong.
///
/// The three mistakes, because each is easy to make again:
///
/// 1. The transport's trailing GAP was never subtracted. `controlGap`
///    is zero by design, so the fit's unit carries no spacing and that
///    single gap is the only separator in the row.
/// 2. The clock was measured in a different font from the one it is
///    drawn in — tabular figures are wider than proportional ones.
///    (That one lives at the call site; this only takes the number.)
/// 3. The pinned control was taken out BEFORE halving, which spread
///    its cost across both sides when it is drawn entirely on one.
@immutable
class VideoBarBudget {
  const VideoBarBudget._({
    required this.single,
    required this.side,
    required this.left,
    required this.right,
  });

  /// For a row with one cluster at its end.
  factory VideoBarBudget.singleCluster({
    required double barWidth,
    required double transportWidth,
    required double pinnedWidth,
    required double clockWidth,
  }) {
    final free = barWidth - transportWidth - pinnedWidth - clockWidth;
    return VideoBarBudget._(single: free, side: 0, left: 0, right: 0);
  }

  /// For a row with the transport in the middle and a cluster either
  /// side of it.
  ///
  /// Each side is an `Expanded`, so the flex divides what is left after
  /// the TRANSPORT and nothing else — [side] is that half. Everything
  /// drawn inside a half comes out of that half alone: the clock and
  /// its gap on the left, the pinned control on the right.
  factory VideoBarBudget.splitCluster({
    required double barWidth,
    required double transportWidth,
    required double pinnedWidth,
    required double clockWidth,
    required double clockGap,
  }) {
    final side = (barWidth - transportWidth) / 2;
    return VideoBarBudget._(
      single: 0,
      side: side,
      left: side - clockWidth - (clockWidth > 0 ? clockGap : 0),
      right: side - pinnedWidth,
    );
  }

  /// Room for the one cluster, when there is only one.
  final double single;

  /// What each `Expanded` half is given.
  final double side;

  /// Room for the controls on each side of a centred transport.
  final double left;
  final double right;
}
