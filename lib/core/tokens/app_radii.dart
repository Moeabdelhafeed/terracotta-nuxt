import 'package:flutter/foundation.dart';

import '../responsive/window_size_class.dart';

/// Corner-radius scale per [WindowSizeClass]. Larger surfaces get softer
/// corners on bigger screens — small radii on phones look right next to
/// 56-dp app bars but feel sharp at desktop sizes.
@immutable
class AppRadii {
  const AppRadii({
    required this.xs,
    required this.sm,
    required this.md,
    required this.lg,
    required this.xl,
    required this.full,
  });

  final double xs;
  final double sm;
  final double md;
  final double lg;
  final double xl;

  /// `999` — pill / circle stand-in. Apply to small things to circle them
  /// (small enough that 999 caps to half-side). Larger surfaces should
  /// pick a concrete value.
  final double full;

  static const compact = AppRadii(
    xs: 4,
    sm: 8,
    md: 12,
    lg: 16,
    xl: 24,
    full: 999,
  );
  static const medium = AppRadii(
    xs: 4,
    sm: 8,
    md: 14,
    lg: 18,
    xl: 26,
    full: 999,
  );
  static const expanded = AppRadii(
    xs: 6,
    sm: 10,
    md: 16,
    lg: 22,
    xl: 32,
    full: 999,
  );
  static const large = AppRadii(
    xs: 6,
    sm: 12,
    md: 20,
    lg: 26,
    xl: 36,
    full: 999,
  );
  static const extraLarge = AppRadii(
    xs: 8,
    sm: 14,
    md: 22,
    lg: 28,
    xl: 40,
    full: 999,
  );

  static AppRadii forBucket(WindowSizeClass bucket) => switch (bucket) {
    WindowSizeClass.compact => compact,
    WindowSizeClass.medium => medium,
    WindowSizeClass.expanded => expanded,
    WindowSizeClass.large => large,
    WindowSizeClass.extraLarge => extraLarge,
  };

  AppRadii lerp(AppRadii other, double t) {
    double l(double a, double b) => a + (b - a) * t;
    return AppRadii(
      xs: l(xs, other.xs),
      sm: l(sm, other.sm),
      md: l(md, other.md),
      lg: l(lg, other.lg),
      xl: l(xl, other.xl),
      full: l(full, other.full),
    );
  }
}
