import 'package:flutter/material.dart';

import '../../../shared/module/popup/popup.dart';
import '../../animations/animation_presets.dart';
import '../../constants/colors/background_colors.dart';
import '../../constants/colors/text_colors.dart';
import '../../tokens/app_tokens.dart';

/// Project-tuned defaults for the [GlobalPopup] module.
///
/// Builds a [GlobalPopupTheme] instance from the active palette + token
/// bucket so every popup in the app inherits the same surface fill,
/// elevation, radius, arrow geometry and motion timing. Per-call
/// [GlobalPopupOptions] overrides still win.
///
/// Wired in `theme.dart`'s `extensions:` list alongside `tokens` /
/// `palette`.
class MyGlobalPopupTheme {
  MyGlobalPopupTheme._();

  // Note: `bg` / `text` are already saturation-tuned upstream at
  // `AppPalette.build(saturation:)` (called from `AppTheme.getTheme`).
  // The popup theme inherits that tuning transitively — no explicit
  // `saturation` param needed here.
  static GlobalPopupTheme build({
    required BackgroundColors bg,
    required TextColors text,
    required AppTokens tokens,
  }) {
    final radius = BorderRadius.circular(tokens.radii.md);
    return GlobalPopupTheme(
      surface: GlobalPopupSurfaceStyle(
        color: bg.surface,
        elevation: tokens.elevation.medium,
        borderRadius: radius,
        borderColor: bg.outlineVariant,
        borderWidth: 0.5,
        // No padding — surfaces (menu, async panel, etc.) manage their
        // own inner padding. Callers wanting a padded panel set
        // `surfaceStyle.padding` per call. Putting padding here would
        // add an unwanted gutter inside every menu / list popup.
        clipBehavior: Clip.antiAlias,
        hoverColor: bg.container,
      ),
      // No default arrow — tooltip-style tails are opt-in per call site.
      // Motion.
      animation: GlobalPopupAnimation.reveal,
      animationDuration: AppDurations.quick,
      flipAnimationDuration: AppDurations.micro,
      animationCurve: Curves.easeOutCubic,
      // Geometry.
      gap: tokens.spacing.xs,
      screenPadding: tokens.spacing.sm,
      // Dynamic resize.
      animateContentSize: false,
      contentSizeAnimationDuration: AppDurations.quick,
      contentSizeAnimationCurve: Curves.easeOutCubic,
      dynamicResizeOnKeyboard: true,
      // Behavior.
      closeOnScroll: true,
      closeOnTapOutside: true,
      closeOnRouteChange: true,
      preserveStateOnFlip: true,
      respectReduceMotion: true,
      // Layout floors / ceilings.
      minHeight: 100,
      maxHeight: 360,
      preferAboveThreshold: 200,
      // Triggers.
      hoverCloseDelay: AppDurations.micro,
    );
  }
}
