import 'package:flutter/foundation.dart';

import '../responsive/window_size_class.dart';

/// Elevation scale per [WindowSizeClass]. Larger windows can carry more
/// pronounced shadows without overwhelming small UI; phones stay shallow
/// to match Material 3 mobile defaults.
@immutable
class AppElevation {
  const AppElevation({
    required this.flat,
    required this.low,
    required this.medium,
    required this.high,
    required this.max,
  });

  /// `0` — surface-level (no shadow). Cards on background, list rows.
  final double flat;

  /// `1–2 dp` — raised surface, default card.
  final double low;

  /// `4–6 dp` — app bar scrolled, dropdown.
  final double medium;

  /// `8–12 dp` — sheet, dialog backdrop.
  final double high;

  /// `16–24 dp` — full-screen overlay anchor.
  final double max;

  static const compact = AppElevation(
    flat: 0,
    low: 1,
    medium: 4,
    high: 8,
    max: 16,
  );
  static const medium_ = AppElevation(
    flat: 0,
    low: 2,
    medium: 4,
    high: 8,
    max: 16,
  );
  static const expanded = AppElevation(
    flat: 0,
    low: 2,
    medium: 6,
    high: 12,
    max: 24,
  );
  static const large = AppElevation(
    flat: 0,
    low: 3,
    medium: 8,
    high: 16,
    max: 32,
  );
  static const extraLarge = AppElevation(
    flat: 0,
    low: 4,
    medium: 10,
    high: 20,
    max: 40,
  );

  static AppElevation forBucket(WindowSizeClass bucket) => switch (bucket) {
    WindowSizeClass.compact => compact,
    WindowSizeClass.medium => medium_,
    WindowSizeClass.expanded => expanded,
    WindowSizeClass.large => large,
    WindowSizeClass.extraLarge => extraLarge,
  };

  AppElevation lerp(AppElevation other, double t) {
    double l(double a, double b) => a + (b - a) * t;
    return AppElevation(
      flat: l(flat, other.flat),
      low: l(low, other.low),
      medium: l(medium, other.medium),
      high: l(high, other.high),
      max: l(max, other.max),
    );
  }
}
