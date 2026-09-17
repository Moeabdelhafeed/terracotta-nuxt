import 'package:flutter/foundation.dart';

import '../responsive/window_size_class.dart';

/// Icon-size scale per [WindowSizeClass]. Pulls from
/// `context.iconSizes.<step>` so icons stay legible without ScreenUtil
/// scaling.
@immutable
class AppIconSizes {
  const AppIconSizes({
    required this.xs,
    required this.sm,
    required this.md,
    required this.lg,
    required this.xl,
    required this.xxl,
  });

  final double xs;
  final double sm;
  final double md;
  final double lg;
  final double xl;
  final double xxl;

  static const compact = AppIconSizes(
    xs: 12,
    sm: 16,
    md: 20,
    lg: 24,
    xl: 32,
    xxl: 48,
  );
  static const medium = AppIconSizes(
    xs: 14,
    sm: 18,
    md: 22,
    lg: 26,
    xl: 36,
    xxl: 56,
  );
  static const expanded = AppIconSizes(
    xs: 16,
    sm: 20,
    md: 24,
    lg: 28,
    xl: 40,
    xxl: 64,
  );
  static const large = AppIconSizes(
    xs: 16,
    sm: 22,
    md: 26,
    lg: 32,
    xl: 44,
    xxl: 72,
  );
  static const extraLarge = AppIconSizes(
    xs: 18,
    sm: 24,
    md: 28,
    lg: 36,
    xl: 48,
    xxl: 80,
  );

  static AppIconSizes forBucket(WindowSizeClass bucket) => switch (bucket) {
    WindowSizeClass.compact => compact,
    WindowSizeClass.medium => medium,
    WindowSizeClass.expanded => expanded,
    WindowSizeClass.large => large,
    WindowSizeClass.extraLarge => extraLarge,
  };

  AppIconSizes lerp(AppIconSizes other, double t) {
    double l(double a, double b) => a + (b - a) * t;
    return AppIconSizes(
      xs: l(xs, other.xs),
      sm: l(sm, other.sm),
      md: l(md, other.md),
      lg: l(lg, other.lg),
      xl: l(xl, other.xl),
      xxl: l(xxl, other.xxl),
    );
  }
}
