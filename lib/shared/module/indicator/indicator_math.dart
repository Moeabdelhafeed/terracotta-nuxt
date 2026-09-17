/// The arithmetic behind the dot row, with no widgets in it.
///
/// Pulled out because none of it could be checked inside the widget:
/// the mirroring and the edge fades are decisions about geometry, and
/// every bug in them used to surface only on a device — one of them in
/// Arabic only, another only at the two ends of a long strip.
abstract final class IndicatorMath {
  /// Where a logical index SITS in the row.
  ///
  /// The pages a dot row names live in a scrollable, and scrollables
  /// reverse, so in Arabic dot one belongs on the right.
  static double physicalIndex(num index, int count, {required bool rtl}) =>
      (rtl ? (count - 1) - index : index).toDouble();

  /// How far the `scrollingDots` strip may travel before it runs out
  /// of dots at one end or the other.
  ///
  /// The strip centres the active dot until then, and stops.
  static ({double min, double max}) scrollClamp(int visible, int count) {
    final min = (visible - 1) / 2;
    final max = (count - 1) - min;
    // Fewer dots than the window: nothing scrolls at all.
    return max < min ? (min: min, max: min) : (min: min, max: max);
  }

  /// Which ENDS of the strip should fade.
  ///
  /// A fade says "there is more this way". At the first dot there is
  /// nothing before it and at the last nothing after, so fading those
  /// ends dimmed a dot the reader can see all of and promised a strip
  /// that is not there.
  static ({bool start, bool end}) edgeFades({
    required double clampedActive,
    required int visible,
    required int count,
  }) {
    final clamp = scrollClamp(visible, count);
    const epsilon = 0.001;
    // Nothing scrolls, so neither end has anything past it — whatever
    // the caller passes as the active position.
    if (clamp.max - clamp.min < epsilon) return (start: false, end: false);
    return (
      start: clampedActive > clamp.min + epsilon,
      end: clampedActive < clamp.max - epsilon,
    );
  }
}
