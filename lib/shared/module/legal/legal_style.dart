import 'package:flutter/material.dart';

/// The floor for the about / legal pages.
abstract final class LegalDefaults {
  /// The app card at the top of About.
  static const headerPadding = EdgeInsets.all(20);
  static const headerRadius = 16.0;

  /// The app mark inside it.
  static const markSize = 64.0;
  static const markRadius = 16.0;
  static const markGlyphSize = 36.0;

  /// How far the mark's gradient fades toward its far corner.
  static const markFadeOpacity = 0.7;

  /// A row in the list below.
  static const tileRadius = 14.0;
  static const tileGap = 10.0;

  /// Between the header, the section label and the list.
  static const sectionGap = 24.0;
  static const labelGap = 12.0;

  /// How far the page holds its content off the screen edge.
  ///
  /// `GlobalContainer.shell` clamps the WIDTH — it does not add a
  /// margin — so without this every card ran corner to corner on a
  /// phone.
  static const pagePadding = 16.0;
}

/// How the about / legal pages LOOK.
///
/// Every field is nullable: unanswered means "ask the theme, then the
/// floor". No colours — they come from `context.<group>Colors` at
/// build time, so an About page tracks role, brightness and
/// saturation like the rest of the app.
@immutable
class LegalStyle {
  const LegalStyle({
    this.headerPadding,
    this.headerRadius,
    this.markSize,
    this.markRadius,
    this.markGlyphSize,
    this.markFadeOpacity,
    this.tileRadius,
    this.tileGap,
    this.sectionGap,
    this.labelGap,
    this.pagePadding,
    this.markBuilder,
  });

  /// The floor — the only place a compile-time constant lives.
  static const defaults = LegalStyle(
    headerPadding: LegalDefaults.headerPadding,
    headerRadius: LegalDefaults.headerRadius,
    markSize: LegalDefaults.markSize,
    markRadius: LegalDefaults.markRadius,
    markGlyphSize: LegalDefaults.markGlyphSize,
    markFadeOpacity: LegalDefaults.markFadeOpacity,
    tileRadius: LegalDefaults.tileRadius,
    tileGap: LegalDefaults.tileGap,
    sectionGap: LegalDefaults.sectionGap,
    labelGap: LegalDefaults.labelGap,
    pagePadding: LegalDefaults.pagePadding,
  );

  /// Tighter, for an About embedded in a settings flow rather than
  /// opened as its own destination.
  static const compact = LegalStyle(
    headerPadding: EdgeInsets.all(12),
    markSize: 44,
    markGlyphSize: 24,
    sectionGap: 16,
    labelGap: 8,
    pagePadding: 12,
    tileGap: 6,
  );

  final EdgeInsets? headerPadding;
  final double? headerRadius;
  final double? markSize;
  final double? markRadius;
  final double? markGlyphSize;
  final double? markFadeOpacity;
  final double? tileRadius;
  final double? tileGap;
  final double? sectionGap;
  final double? labelGap;
  final double? pagePadding;

  /// The app's own mark, in place of the generated one.
  ///
  /// The default is a gradient plate with a Flutter glyph on it —
  /// unmistakably a PLACEHOLDER, which is right for a template and
  /// wrong for a shipped app. This is the seam an adopter fills, and
  /// it is on the bag so a house fills it once.
  final WidgetBuilder? markBuilder;

  /// Field-by-field: whatever `other` answers wins, and what it leaves
  /// null keeps this bag's answer.
  LegalStyle mergedWith(LegalStyle? other) {
    if (other == null) return this;
    return LegalStyle(
      headerPadding: other.headerPadding ?? headerPadding,
      headerRadius: other.headerRadius ?? headerRadius,
      markSize: other.markSize ?? markSize,
      markRadius: other.markRadius ?? markRadius,
      markGlyphSize: other.markGlyphSize ?? markGlyphSize,
      markFadeOpacity: other.markFadeOpacity ?? markFadeOpacity,
      tileRadius: other.tileRadius ?? tileRadius,
      tileGap: other.tileGap ?? tileGap,
      sectionGap: other.sectionGap ?? sectionGap,
      labelGap: other.labelGap ?? labelGap,
      pagePadding: other.pagePadding ?? pagePadding,
      markBuilder: other.markBuilder ?? markBuilder,
    );
  }

  LegalStyle copyWith({
    EdgeInsets? headerPadding,
    double? headerRadius,
    double? markSize,
    double? markRadius,
    double? markGlyphSize,
    double? markFadeOpacity,
    double? tileRadius,
    double? tileGap,
    double? sectionGap,
    double? labelGap,
    double? pagePadding,
    WidgetBuilder? markBuilder,
  }) => LegalStyle(
    headerPadding: headerPadding ?? this.headerPadding,
    headerRadius: headerRadius ?? this.headerRadius,
    markSize: markSize ?? this.markSize,
    markRadius: markRadius ?? this.markRadius,
    markGlyphSize: markGlyphSize ?? this.markGlyphSize,
    markFadeOpacity: markFadeOpacity ?? this.markFadeOpacity,
    tileRadius: tileRadius ?? this.tileRadius,
    tileGap: tileGap ?? this.tileGap,
    sectionGap: sectionGap ?? this.sectionGap,
    labelGap: labelGap ?? this.labelGap,
    pagePadding: pagePadding ?? this.pagePadding,
    markBuilder: markBuilder ?? this.markBuilder,
  );

  @override
  bool operator ==(Object other) =>
      other is LegalStyle &&
      other.headerPadding == headerPadding &&
      other.headerRadius == headerRadius &&
      other.markSize == markSize &&
      other.markRadius == markRadius &&
      other.markGlyphSize == markGlyphSize &&
      other.markFadeOpacity == markFadeOpacity &&
      other.tileRadius == tileRadius &&
      other.tileGap == tileGap &&
      other.sectionGap == sectionGap &&
      other.labelGap == labelGap &&
      other.pagePadding == pagePadding &&
      other.markBuilder == markBuilder;

  @override
  int get hashCode => Object.hash(
    headerPadding,
    headerRadius,
    markSize,
    markRadius,
    markGlyphSize,
    markFadeOpacity,
    tileRadius,
    tileGap,
    sectionGap,
    labelGap,
    pagePadding,
    markBuilder,
  );
}

/// A [LegalStyle] with every question answered.
@immutable
class ResolvedLegalStyle {
  const ResolvedLegalStyle({
    required this.headerPadding,
    required this.headerRadius,
    required this.markSize,
    required this.markRadius,
    required this.markGlyphSize,
    required this.markFadeOpacity,
    required this.tileRadius,
    required this.tileGap,
    required this.sectionGap,
    required this.labelGap,
    required this.pagePadding,
    this.markBuilder,
  });

  final EdgeInsets headerPadding;
  final double headerRadius;
  final double markSize;
  final double markRadius;
  final double markGlyphSize;
  final double markFadeOpacity;
  final double tileRadius;
  final double tileGap;
  final double sectionGap;
  final double labelGap;
  final double pagePadding;
  final WidgetBuilder? markBuilder;
}
