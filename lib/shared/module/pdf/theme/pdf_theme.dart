import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../../../core/extensions/theme_colors_extension.dart';
import '../pdf_models.dart';

/// App-wide defaults for `GlobalPdfViewer`.
///
/// The rebrand hook: set the surface, the corner and which controls a
/// document viewer offers, once, for every PDF in the app.
@immutable
class GlobalPdfTheme extends ThemeExtension<GlobalPdfTheme> {
  const GlobalPdfTheme({this.style});

  final PdfStyle? style;

  static GlobalPdfTheme? maybeOf(BuildContext context) =>
      Theme.of(context).extension<GlobalPdfTheme>();

  @override
  GlobalPdfTheme copyWith({PdfStyle? style}) =>
      GlobalPdfTheme(style: style ?? this.style);

  @override
  GlobalPdfTheme lerp(ThemeExtension<GlobalPdfTheme>? other, double t) {
    if (other is! GlobalPdfTheme) return this;
    return GlobalPdfTheme(style: _lerpStyle(style, other.style, t));
  }

  /// Continuous fields interpolate; discrete ones snap at the midpoint.
  static PdfStyle? _lerpStyle(PdfStyle? a, PdfStyle? b, double t) {
    if (a == null && b == null) return null;
    final pick = t < 0.5 ? a : b;
    return PdfStyle(
      accent: Color.lerp(a?.accent, b?.accent, t),
      background: Color.lerp(a?.background, b?.background, t),
      controlsColor: Color.lerp(a?.controlsColor, b?.controlsColor, t),
      matchColor: Color.lerp(a?.matchColor, b?.matchColor, t),
      activeMatchColor: Color.lerp(
        a?.activeMatchColor,
        b?.activeMatchColor,
        t,
      ),
      padding: EdgeInsets.lerp(a?.padding, b?.padding, t),
      borderRadius: BorderRadius.lerp(a?.borderRadius, b?.borderRadius, t),
      compactHeight: lerpDouble(a?.compactHeight, b?.compactHeight, t),
      thumbnailStripHeight: lerpDouble(
        a?.thumbnailStripHeight,
        b?.thumbnailStripHeight,
        t,
      ),
      pageGap: lerpDouble(a?.pageGap, b?.pageGap, t),
      initialZoom: lerpDouble(a?.initialZoom, b?.initialZoom, t),
      minZoom: lerpDouble(a?.minZoom, b?.minZoom, t),
      maxZoom: lerpDouble(a?.maxZoom, b?.maxZoom, t),
      zoomStep: lerpDouble(a?.zoomStep, b?.zoomStep, t),
      // Which controls EXIST is not a thing to interpolate — a button
      // half-present is a button that is there or is not.
      showPageIndicator: pick?.showPageIndicator,
      showZoomControls: pick?.showZoomControls,
      showSearchButton: pick?.showSearchButton,
      showOutlineButton: pick?.showOutlineButton,
      showThumbnailStrip: pick?.showThumbnailStrip,
      showShareButton: pick?.showShareButton,
      showRotateButton: pick?.showRotateButton,
      showActionsMenu: pick?.showActionsMenu,
      enableTextSelection: pick?.enableTextSelection,
      openExternalLinks: pick?.openExternalLinks,
      invertColorsInDark: pick?.invertColorsInDark,
      panEnabled: pick?.panEnabled,
      annotationMode: pick?.annotationMode,
    );
  }
}

extension PdfStyleResolve on PdfStyle {
  /// Stacks `caller > theme > defaults`, then fills colours from the
  /// palette.
  ///
  /// The viewer read `Theme.of(context).colorScheme` in seven places —
  /// Material's scheme rather than the app's, so a rebranded palette
  /// left every PDF surface, control and highlight behind.
  ResolvedPdfStyle resolve(BuildContext context) {
    final merged = PdfStyle.defaults
        .mergedWith(GlobalPdfTheme.maybeOf(context)?.style)
        .mergedWith(this);
    const floor = PdfStyle.defaults;

    final bg = context.backgroundColors;
    final accent = merged.accent ?? context.primaryColors.primary;

    return ResolvedPdfStyle(
      accent: accent,
      background: merged.background ?? bg.surface,
      controlsColor: merged.controlsColor ?? context.textColors.primary,
      padding: merged.padding ?? EdgeInsets.zero,
      borderRadius:
          merged.borderRadius ?? BorderRadius.circular(PdfDefaults.radius),
      compactHeight: merged.compactHeight ?? floor.compactHeight!,
      showPageIndicator: merged.showPageIndicator ?? floor.showPageIndicator!,
      showZoomControls: merged.showZoomControls ?? floor.showZoomControls!,
      showSearchButton: merged.showSearchButton ?? floor.showSearchButton!,
      showOutlineButton: merged.showOutlineButton ?? floor.showOutlineButton!,
      showThumbnailStrip:
          merged.showThumbnailStrip ?? floor.showThumbnailStrip!,
      showShareButton: merged.showShareButton ?? floor.showShareButton!,
      showRotateButton: merged.showRotateButton ?? floor.showRotateButton!,
      showActionsMenu: merged.showActionsMenu ?? floor.showActionsMenu!,
      enableTextSelection:
          merged.enableTextSelection ?? floor.enableTextSelection!,
      openExternalLinks: merged.openExternalLinks ?? floor.openExternalLinks!,
      invertColorsInDark:
          merged.invertColorsInDark ?? floor.invertColorsInDark!,
      thumbnailStripHeight:
          merged.thumbnailStripHeight ?? floor.thumbnailStripHeight!,
      pageGap: merged.pageGap ?? floor.pageGap!,
      initialZoom: merged.initialZoom ?? floor.initialZoom!,
      minZoom: merged.minZoom ?? floor.minZoom!,
      maxZoom: merged.maxZoom ?? floor.maxZoom!,
      zoomStep: merged.zoomStep ?? floor.zoomStep!,
      // A hit is the accent WASHED and the focused one is it at full
      // strength, so the match you are on reads as the one you are on.
      matchColor:
          merged.matchColor ??
          accent.withValues(alpha: PdfDefaults.matchOpacity),
      activeMatchColor: merged.activeMatchColor ?? accent,
      panEnabled: merged.panEnabled ?? floor.panEnabled!,
      annotationMode: merged.annotationMode ?? floor.annotationMode!,
    );
  }
}
