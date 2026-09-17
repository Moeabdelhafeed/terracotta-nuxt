import 'package:flutter/material.dart';

import '../../../../core/extensions/theme_colors_extension.dart';
import '../scanner_models.dart';

/// App-wide defaults for [GlobalScanner].
///
/// The rebrand hook: set the viewfinder's shape, which controls every
/// scanner offers, and whether the box is honoured, once, here.
@immutable
class GlobalScannerTheme extends ThemeExtension<GlobalScannerTheme> {
  const GlobalScannerTheme({this.style});

  final ScannerStyle? style;

  static GlobalScannerTheme? maybeOf(BuildContext context) =>
      Theme.of(context).extension<GlobalScannerTheme>();

  @override
  GlobalScannerTheme copyWith({ScannerStyle? style}) =>
      GlobalScannerTheme(style: style ?? this.style);

  @override
  GlobalScannerTheme lerp(ThemeExtension<GlobalScannerTheme>? other, double t) {
    if (other is! GlobalScannerTheme) return this;
    // A style is a bag of independent decisions, not a value with a
    // midpoint — half a `showTorch` means nothing. It SNAPS at the
    // halfway mark, which is what every other bag in this app does.
    return t < 0.5 ? this : other;
  }
}

/// Turns a caller's bag into one with every question answered.
extension ScannerStyleResolve on ScannerStyle {
  /// `caller > GlobalScannerTheme.style > ScannerStyle.defaults`, then
  /// the accent from the palette.
  ///
  /// Only the ACCENT comes from the palette. The controls sit on
  /// camera pixels and stay white-on-scrim — see the module's
  /// CLAUDE.md, and the video module for the same argument.
  ResolvedScannerStyle resolve(BuildContext context) {
    final merged = ScannerStyle.defaults
        .mergedWith(GlobalScannerTheme.maybeOf(context)?.style)
        .mergedWith(this);

    return ResolvedScannerStyle(
      viewfinderColor: merged.viewfinderColor ?? context.primaryColors.primary,
      // The one other palette colour here, and for the same reason:
      // an accepted code is a SUCCESS, and every other success in the
      // app is this green.
      successColor: merged.successColor ?? context.statusColors.success,
      viewfinderSize: merged.viewfinderSize,
      viewfinderFraction:
          merged.viewfinderFraction ?? ScannerDefaults.viewfinderFraction,
      viewfinderAspect:
          merged.viewfinderAspect ?? ScannerDefaults.viewfinderAspect,
      cornerLength: merged.cornerLength ?? ScannerDefaults.cornerLength,
      cornerWidth: merged.cornerWidth ?? ScannerDefaults.cornerWidth,
      cornerRadius: merged.cornerRadius ?? ScannerDefaults.cornerRadius,
      dimColor: merged.dimColor ?? ScannerDefaults.dimColor,
      controlsColor: merged.controlsColor ?? Colors.white,
      controlScrim: merged.controlScrim ?? ScannerDefaults.controlScrim,
      controlSize: merged.controlSize ?? ScannerDefaults.controlSize,
      showTorch: merged.showTorch ?? true,
      showFlip: merged.showFlip ?? true,
      showZoom: merged.showZoom ?? true,
      showScanLine: merged.showScanLine ?? true,
      showSuccessFlash: merged.showSuccessFlash ?? true,
      restrictToViewfinder: merged.restrictToViewfinder ?? true,
      enableHaptic: merged.enableHaptic ?? true,
      enablePinchZoom: merged.enablePinchZoom ?? true,
      tapToFocus: merged.tapToFocus ?? true,
      autoZoom: merged.autoZoom ?? false,
      invertImage: merged.invertImage ?? false,
      detectionSpeed:
          merged.detectionSpeed ?? ScannerDetectionSpeed.noDuplicates,
      detectionTimeout:
          merged.detectionTimeout ?? ScannerDefaults.detectionTimeout,
      cameraResolution: merged.cameraResolution,
    );
  }
}
