/// Duration utility extensions.

extension DurationExtensions on Duration {
  // ─── Components ─────────────────────────────────────────────

  /// Total whole days.
  int get totalDays => inDays;

  /// Total whole hours.
  int get totalHours => inHours;

  /// Total whole minutes.
  int get totalMinutes => inMinutes;

  /// Total whole seconds.
  int get totalSeconds => inSeconds;

  // ─── Formatting ─────────────────────────────────────────────

  /// Human-readable compact format: "2h 30m", "45s", "3d 1h".
  /// Shows the two most significant units. Not localized — pairs
  /// with ARB strings at the call site if you need translation.
  String get formatted {
    if (inDays > 0) {
      final h = inHours.remainder(24);
      return h > 0 ? '${inDays}d ${h}h' : '${inDays}d';
    }
    if (inHours > 0) {
      final m = inMinutes.remainder(60);
      return m > 0 ? '${inHours}h ${m}m' : '${inHours}h';
    }
    if (inMinutes > 0) {
      final s = inSeconds.remainder(60);
      return s > 0 ? '${inMinutes}m ${s}s' : '${inMinutes}m';
    }
    return '${inSeconds}s';
  }

  /// Timer-style format: "03:45", "1:02:30".
  String get toTimerString {
    final h = inHours;
    final m = inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = inSeconds.remainder(60).toString().padLeft(2, '0');
    if (h > 0) return '$h:$m:$s';
    return '$m:$s';
  }

  /// MM:SS shorthand (caps at 59:59, rolls over for longer durations).
  String get toMinutesSeconds {
    final m = inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ─── Arithmetic ─────────────────────────────────────────────

  /// Multiply duration by a factor.
  Duration operator *(double factor) =>
      Duration(microseconds: (inMicroseconds * factor).round());

  /// Divide duration by a factor.
  Duration operator /(double factor) =>
      Duration(microseconds: (inMicroseconds / factor).round());
}
