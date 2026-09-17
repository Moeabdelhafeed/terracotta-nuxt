import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show Offset;

/// Where a circular track starts, and which way it runs.
///
/// Angles are in RADIANS and measured the way `Canvas.drawArc` measures
/// them: zero points RIGHT (three o'clock) and grows clockwise. Twelve
/// o'clock is therefore `-pi / 2`, which is what most callers actually
/// want and why [CircularSliderGeometry.top] exists.
@immutable
class CircularSliderGeometry {
  const CircularSliderGeometry({
    required this.startAngle,
    required this.sweepAngle,
  }) : assert(sweepAngle != 0, 'a track with no sweep has nowhere to drag');

  /// A full circle beginning at twelve o'clock — a clock face, a sleep
  /// schedule.
  static const CircularSliderGeometry top = CircularSliderGeometry(
    startAngle: -math.pi / 2,
    sweepAngle: math.pi * 2,
  );

  /// A full circle with a gap at the BOTTOM, so the two ends of the
  /// scale are visibly two ends rather than one seam nobody can find.
  /// The gap is where a "min" and "max" label go.
  static const CircularSliderGeometry gauge = CircularSliderGeometry(
    startAngle: math.pi * 0.75,
    sweepAngle: math.pi * 1.5,
  );

  /// The top half only.
  static const CircularSliderGeometry arc = CircularSliderGeometry(
    startAngle: math.pi,
    sweepAngle: math.pi,
  );

  /// Where the low end of the scale sits.
  final double startAngle;

  /// How far the scale runs. NEGATIVE sweeps anticlockwise, which is
  /// what a dial that counts down wants.
  final double sweepAngle;

  /// A full turn, give or take floating-point dust.
  ///
  /// It decides whether the two ends of the scale are the SAME POINT.
  /// On a closed dial a thumb dragged past the top wraps to the other
  /// end; on an open one it stops.
  bool get isClosed => (sweepAngle.abs() - math.pi * 2).abs() < 1e-6;

  CircularSliderGeometry copyWith({double? startAngle, double? sweepAngle}) =>
      CircularSliderGeometry(
        startAngle: startAngle ?? this.startAngle,
        sweepAngle: sweepAngle ?? this.sweepAngle,
      );

  @override
  bool operator ==(Object other) =>
      other is CircularSliderGeometry &&
      other.startAngle == startAngle &&
      other.sweepAngle == sweepAngle;

  @override
  int get hashCode => Object.hash(startAngle, sweepAngle);
}

/// The arithmetic a round track runs on.
///
/// Pure, and therefore testable — which the equivalent on a rectangular
/// slider was not until it was pulled out of six `paint` methods. None
/// of this can be checked by looking at a widget: a thumb one degree
/// off is invisible in a screenshot and obvious under a finger.
abstract final class CircularSliderMath {
  /// [value] as a fraction of the scale, 0 at [min] and 1 at [max].
  static double fraction(
    double value, {
    required double min,
    required double max,
  }) => max <= min ? 0 : ((value - min) / (max - min)).clamp(0.0, 1.0);

  /// The angle a value sits at.
  static double angleFor(
    double value, {
    required double min,
    required double max,
    required CircularSliderGeometry geometry,
  }) =>
      geometry.startAngle +
      geometry.sweepAngle * fraction(value, min: min, max: max);

  /// Where a value's thumb is drawn.
  static Offset offsetFor(
    double value, {
    required double min,
    required double max,
    required CircularSliderGeometry geometry,
    required Offset centre,
    required double radius,
  }) {
    final angle = angleFor(
      value,
      min: min,
      max: max,
      geometry: geometry,
    );
    return Offset(
      centre.dx + radius * math.cos(angle),
      centre.dy + radius * math.sin(angle),
    );
  }

  /// Reduces an angle to `[0, 2pi)`.
  static double normalize(double angle) {
    const turn = math.pi * 2;
    final wrapped = angle % turn;
    return wrapped < 0 ? wrapped + turn : wrapped;
  }

  /// How far along the sweep a point sits, as a fraction.
  ///
  /// Returns null when the point falls in an OPEN dial's gap and is
  /// nearer the gap's middle than either end — a finger there is not
  /// asking for anything, and snapping it to whichever end is closer
  /// would jump the value across the whole scale.
  static double? fractionForOffset(
    Offset point, {
    required Offset centre,
    required CircularSliderGeometry geometry,
  }) {
    final angle = math.atan2(point.dy - centre.dy, point.dx - centre.dx);
    // Distance travelled ALONG the sweep, so an anticlockwise dial
    // measures backwards without a second code path.
    final travelled = geometry.sweepAngle.isNegative
        ? normalize(geometry.startAngle - angle)
        : normalize(angle - geometry.startAngle);

    final span = geometry.sweepAngle.abs();
    if (travelled <= span) return travelled / span;
    if (geometry.isClosed) return 1;

    // Past the end, in the gap. Nearer which end?
    final gap = math.pi * 2 - span;
    return travelled - span > gap / 2 ? 0 : 1;
  }

  /// The value a point on the dial asks for, or null when the point is
  /// in the gap.
  static double? valueForOffset(
    Offset point, {
    required Offset centre,
    required CircularSliderGeometry geometry,
    required double min,
    required double max,
    int? divisions,
  }) {
    final t = fractionForOffset(point, centre: centre, geometry: geometry);
    if (t == null) return null;
    final raw = min + (max - min) * t;
    return snap(raw, min: min, max: max, divisions: divisions);
  }

  /// Snaps to the nearest division.
  static double snap(
    double value, {
    required double min,
    required double max,
    int? divisions,
  }) {
    if (divisions == null || divisions <= 0 || max <= min) return value;
    final step = (max - min) / divisions;
    return (min + ((value - min) / step).roundToDouble() * step).clamp(
      min,
      max,
    );
  }

  /// Which of two thumbs a point is asking for, by ANGLE rather than by
  /// straight-line distance.
  ///
  /// On a dial the two are not the same question: 23:30 and 00:30 are
  /// half an hour apart and, across the seam, almost a full circle
  /// apart in value. Picking by value would grab the wrong thumb every
  /// time a range straddles the top.
  static bool startThumbIsNearer(
    double t, {
    required double startFraction,
    required double endFraction,
    required bool closed,
  }) {
    double gapTo(double other) {
      final d = (t - other).abs();
      // On a closed dial the scale wraps, so the short way round may
      // be through the seam.
      return closed ? math.min(d, 1 - d) : d;
    }

    return gapTo(startFraction) <= gapTo(endFraction);
  }

  /// Whether a fraction lies inside the span from [start] to [end].
  ///
  /// On a CLOSED dial a span may wrap through the seam — a night that
  /// runs 22:00 to 06:00 is not "from 6 to 22 backwards", it is the
  /// eight hours the other way — so `start > end` is a legal span
  /// rather than an inverted one.
  static bool spanContains(
    double t, {
    required double start,
    required double end,
    required bool closed,
  }) {
    if (start <= end) return t >= start && t <= end;
    // Wrapped. Only a closed dial can express this; on an open one an
    // inverted pair is just inverted.
    return closed ? (t >= start || t <= end) : (t >= end && t <= start);
  }

  /// The LENGTH of a span, as a fraction of the scale, wrapping when
  /// the dial is closed.
  static double spanLength({
    required double start,
    required double end,
    required bool closed,
  }) {
    if (start <= end) return end - start;
    return closed ? 1 - start + end : start - end;
  }
}
