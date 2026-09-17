import 'package:flutter/foundation.dart';

import '../responsive/window_size_class.dart';

/// 6-step spacing scale, hand-tuned per [WindowSizeClass]. Replaces
/// `.w` / `.h` arithmetic — pull from `context.spacing.<step>` instead
/// of multiplying a magic number by a screen ratio.
@immutable
class AppSpacing {
  const AppSpacing({
    required this.xs,
    required this.sm,
    required this.md,
    required this.lg,
    required this.xl,
    required this.xxl,
  });

  /// `4 dp` on phones — separator gap, dense list rows.
  final double xs;

  /// `8 dp` on phones — chip padding, icon-to-label.
  final double sm;

  /// `16 dp` on phones — default page padding, card inset.
  final double md;

  /// `24 dp` on phones — section gap, dialog inset.
  final double lg;

  /// `32 dp` on phones — group separator, hero margin.
  final double xl;

  /// `48 dp` on phones — full-bleed feature gap, empty-state breathe.
  final double xxl;

  static const compact = AppSpacing(
    xs: 4,
    sm: 8,
    md: 16,
    lg: 24,
    xl: 32,
    xxl: 48,
  );
  static const medium = AppSpacing(
    xs: 6,
    sm: 10,
    md: 18,
    lg: 28,
    xl: 40,
    xxl: 56,
  );
  static const expanded = AppSpacing(
    xs: 8,
    sm: 12,
    md: 20,
    lg: 32,
    xl: 48,
    xxl: 72,
  );
  static const large = AppSpacing(
    xs: 8,
    sm: 14,
    md: 24,
    lg: 36,
    xl: 56,
    xxl: 84,
  );
  static const extraLarge = AppSpacing(
    xs: 10,
    sm: 16,
    md: 28,
    lg: 40,
    xl: 64,
    xxl: 96,
  );

  static AppSpacing forBucket(WindowSizeClass bucket) => switch (bucket) {
    WindowSizeClass.compact => compact,
    WindowSizeClass.medium => medium,
    WindowSizeClass.expanded => expanded,
    WindowSizeClass.large => large,
    WindowSizeClass.extraLarge => extraLarge,
  };

  AppSpacing lerp(AppSpacing other, double t) {
    double l(double a, double b) => a + (b - a) * t;
    return AppSpacing(
      xs: l(xs, other.xs),
      sm: l(sm, other.sm),
      md: l(md, other.md),
      lg: l(lg, other.lg),
      xl: l(xl, other.xl),
      xxl: l(xxl, other.xxl),
    );
  }
}
