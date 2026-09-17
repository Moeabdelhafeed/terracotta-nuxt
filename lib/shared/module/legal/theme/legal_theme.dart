import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../legal_style.dart';

/// App-wide defaults for the about / legal pages.
@immutable
class GlobalLegalTheme extends ThemeExtension<GlobalLegalTheme> {
  const GlobalLegalTheme({this.style});

  final LegalStyle? style;

  static GlobalLegalTheme? maybeOf(BuildContext context) =>
      Theme.of(context).extension<GlobalLegalTheme>();

  @override
  GlobalLegalTheme copyWith({LegalStyle? style}) =>
      GlobalLegalTheme(style: style ?? this.style);

  @override
  GlobalLegalTheme lerp(ThemeExtension<GlobalLegalTheme>? other, double t) {
    if (other is! GlobalLegalTheme) return this;
    return GlobalLegalTheme(style: _lerpStyle(style, other.style, t));
  }

  /// Measurements interpolate; the MARK snaps — half of one logo and
  /// half of another is neither.
  static LegalStyle? _lerpStyle(LegalStyle? a, LegalStyle? b, double t) {
    if (a == null && b == null) return null;
    final pick = t < 0.5 ? a : b;
    return LegalStyle(
      headerPadding: EdgeInsets.lerp(a?.headerPadding, b?.headerPadding, t),
      headerRadius: lerpDouble(a?.headerRadius, b?.headerRadius, t),
      markSize: lerpDouble(a?.markSize, b?.markSize, t),
      markRadius: lerpDouble(a?.markRadius, b?.markRadius, t),
      markGlyphSize: lerpDouble(a?.markGlyphSize, b?.markGlyphSize, t),
      markFadeOpacity: lerpDouble(a?.markFadeOpacity, b?.markFadeOpacity, t),
      tileRadius: lerpDouble(a?.tileRadius, b?.tileRadius, t),
      tileGap: lerpDouble(a?.tileGap, b?.tileGap, t),
      sectionGap: lerpDouble(a?.sectionGap, b?.sectionGap, t),
      labelGap: lerpDouble(a?.labelGap, b?.labelGap, t),
      pagePadding: lerpDouble(a?.pagePadding, b?.pagePadding, t),
      markBuilder: pick?.markBuilder,
    );
  }
}

extension LegalStyleResolve on LegalStyle {
  /// Stacks `caller > GlobalLegalTheme.style > LegalStyle.defaults`.
  ResolvedLegalStyle resolve(BuildContext context) {
    final merged = LegalStyle.defaults
        .mergedWith(GlobalLegalTheme.maybeOf(context)?.style)
        .mergedWith(this);
    const floor = LegalStyle.defaults;

    return ResolvedLegalStyle(
      headerPadding: merged.headerPadding ?? floor.headerPadding!,
      headerRadius: merged.headerRadius ?? floor.headerRadius!,
      markSize: merged.markSize ?? floor.markSize!,
      markRadius: merged.markRadius ?? floor.markRadius!,
      markGlyphSize: merged.markGlyphSize ?? floor.markGlyphSize!,
      markFadeOpacity: merged.markFadeOpacity ?? floor.markFadeOpacity!,
      tileRadius: merged.tileRadius ?? floor.tileRadius!,
      tileGap: merged.tileGap ?? floor.tileGap!,
      sectionGap: merged.sectionGap ?? floor.sectionGap!,
      labelGap: merged.labelGap ?? floor.labelGap!,
      pagePadding: merged.pagePadding ?? floor.pagePadding!,
      markBuilder: merged.markBuilder,
    );
  }
}
