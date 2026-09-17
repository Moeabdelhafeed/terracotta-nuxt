import 'package:flutter/material.dart';

import '../responsive/window_size_class.dart';
import 'app_elevation.dart';
import 'app_icon_sizes.dart';
import 'app_radii.dart';
import 'app_spacing.dart';
import 'app_typography_scale.dart';

/// `ThemeExtension` bundle of every bucket-aware design token. Built
/// once per theme + window-size combination and registered into
/// `ThemeData.extensions`. Lerps automatically when the theme animates
/// between light/dark or between buckets.
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    required this.windowSize,
    required this.spacing,
    required this.radii,
    required this.iconSizes,
    required this.elevation,
    required this.typography,
  });

  /// Source bucket — useful for diagnostics + breakpoint badges.
  final WindowSizeClass windowSize;

  final AppSpacing spacing;
  final AppRadii radii;
  final AppIconSizes iconSizes;
  final AppElevation elevation;
  final AppTypographyScale typography;

  /// Build a token bundle for [windowSize].
  factory AppTokens.forBucket(WindowSizeClass windowSize) {
    return AppTokens(
      windowSize: windowSize,
      spacing: AppSpacing.forBucket(windowSize),
      radii: AppRadii.forBucket(windowSize),
      iconSizes: AppIconSizes.forBucket(windowSize),
      elevation: AppElevation.forBucket(windowSize),
      typography: AppTypographyScale.forBucket(windowSize),
    );
  }

  @override
  AppTokens copyWith({
    WindowSizeClass? windowSize,
    AppSpacing? spacing,
    AppRadii? radii,
    AppIconSizes? iconSizes,
    AppElevation? elevation,
    AppTypographyScale? typography,
  }) {
    return AppTokens(
      windowSize: windowSize ?? this.windowSize,
      spacing: spacing ?? this.spacing,
      radii: radii ?? this.radii,
      iconSizes: iconSizes ?? this.iconSizes,
      elevation: elevation ?? this.elevation,
      typography: typography ?? this.typography,
    );
  }

  @override
  AppTokens lerp(ThemeExtension<AppTokens>? other, double t) {
    if (other is! AppTokens) return this;
    return AppTokens(
      // windowSize is discrete — pick destination once we cross 0.5.
      windowSize: t < 0.5 ? windowSize : other.windowSize,
      spacing: spacing.lerp(other.spacing, t),
      radii: radii.lerp(other.radii, t),
      iconSizes: iconSizes.lerp(other.iconSizes, t),
      elevation: elevation.lerp(other.elevation, t),
      typography: typography.lerp(other.typography, t),
    );
  }
}
