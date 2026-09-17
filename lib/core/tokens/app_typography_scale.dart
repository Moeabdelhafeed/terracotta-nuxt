import 'package:flutter/foundation.dart';

import '../responsive/window_size_class.dart';

/// Typography multiplier per [WindowSizeClass]. Applied to the base
/// font sizes in [MyTextTheme.build] so text sizes increase smoothly
/// as the window grows — phone bodies stay 14, tablet bodies become
/// 15, desktop bodies 17, etc.
///
/// Kept gentle (≤ 1.20×) — large jumps make typography feel inflated
/// rather than scaled.
@immutable
class AppTypographyScale {
  const AppTypographyScale({required this.factor});

  /// Multiplier applied to every base font size.
  final double factor;

  static const compact = AppTypographyScale(factor: 1.00);
  static const medium = AppTypographyScale(factor: 1.05);
  static const expanded = AppTypographyScale(factor: 1.10);
  static const large = AppTypographyScale(factor: 1.15);
  static const extraLarge = AppTypographyScale(factor: 1.20);

  static AppTypographyScale forBucket(WindowSizeClass bucket) =>
      switch (bucket) {
        WindowSizeClass.compact => compact,
        WindowSizeClass.medium => medium,
        WindowSizeClass.expanded => expanded,
        WindowSizeClass.large => large,
        WindowSizeClass.extraLarge => extraLarge,
      };

  /// Apply [factor] to a base font size.
  double scale(double base) => base * factor;

  AppTypographyScale lerp(AppTypographyScale other, double t) {
    return AppTypographyScale(factor: factor + (other.factor - factor) * t);
  }
}
