import 'package:flutter/material.dart';

import '../../../core/animations/animation_presets.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

/// Geometry and tolerances that only change when this module changes.
/// Anything an app would rebrand lives on [EmptyStateStyle] instead.
abstract final class EmptyStateDefaults {
  /// Glyph size, per variant. A full-page empty state is the only thing
  /// on screen and can afford the room; a compact one sits inside a card
  /// that already has content around it.
  static const iconSize = 64.0;
  static const compactIconSize = 40.0;

  static const spacing = 16.0;
  static const compactSpacing = 10.0;

  static const padding = EdgeInsets.symmetric(horizontal: 32, vertical: 48);
  static const compactPadding = EdgeInsets.all(16);

  /// Share of the glyph's size the soft disc adds around it.
  static const iconPaddingFraction = 0.35;

  /// How far the glyph and its disc sit from the outline colour.
  static const iconOpacity = 0.4;
  static const iconBackgroundOpacity = 0.08;

  /// Gap between the title and the subtitle, and before the actions, as
  /// multiples of the spacing step.
  static const subtitleGapFraction = 0.5;
  static const actionGapFraction = 1.5;

  static const animDuration = AppDurations.slow;

  /// How far the whole block travels on entrance.
  static const entranceOffset = 20.0;

  /// Reading width for the title and subtitle. Past this a sentence
  /// stops scanning as one line and starts scanning as a paragraph —
  /// the same reason `GlobalContainer.prose` exists.
  static const maxContentWidth = 420.0;
}

// ---------------------------------------------------------------------------
// EmptyStateVariant
// ---------------------------------------------------------------------------

/// Layout variant of the empty state.
enum EmptyStateVariant {
  /// Full-page centred layout. Takes all the height it is given.
  fullPage,

  /// Compact inline layout, for inside a card or a section.
  compact;

  bool get isCompact => this == EmptyStateVariant.compact;
}

// ---------------------------------------------------------------------------
// EmptyStateStyle
// ---------------------------------------------------------------------------

/// Themeable styling bag for `GlobalEmptyState` — EVERY field nullable.
///
/// Resolution order, materialized once per build by `resolve`:
/// `caller > GlobalEmptyStateTheme.style > EmptyStateStyle.defaults >
/// palette`.
///
/// Adding a themed field means touching five places: here, [mergedWith],
/// [copyWith], [ResolvedEmptyStateStyle] and
/// `GlobalEmptyStateTheme.lerp`.
@immutable
class EmptyStateStyle {
  const EmptyStateStyle({
    this.iconSize,
    this.iconColor,
    this.titleStyle,
    this.subtitleStyle,
    this.spacing,
    this.iconBackgroundColor,
    this.iconBackgroundRadius,
    this.padding,
    this.animateEntrance,
    this.animationDuration,
    this.animationCurve,
    this.entranceOffset,
    this.maxContentWidth,
    this.announceOnAppear,
  });

  /// Compile-time floor. Colours are deliberately absent: they resolve
  /// from `context.<group>Colors` at build time so an empty state tracks
  /// role, brightness and saturation.
  ///
  /// The SIZES are absent too — they depend on the variant, which the
  /// bag does not know. `resolve` takes it.
  static const EmptyStateStyle defaults = EmptyStateStyle(
    animateEntrance: true,
    animationDuration: EmptyStateDefaults.animDuration,
    animationCurve: Curves.easeOutCubic,
    entranceOffset: EmptyStateDefaults.entranceOffset,
    maxContentWidth: EmptyStateDefaults.maxContentWidth,
    announceOnAppear: true,
  );

  /// Size of the glyph. Null takes the variant's own.
  final double? iconSize;
  final Color? iconColor;

  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;

  /// Step between the elements. Null takes the variant's own.
  final double? spacing;

  /// The soft disc behind the glyph.
  final Color? iconBackgroundColor;

  /// Its corner radius. Null is a circle.
  final BorderRadius? iconBackgroundRadius;

  /// Inset around the whole block. Null takes the variant's own.
  final EdgeInsets? padding;

  /// Whether the block fades and rises on first build.
  final bool? animateEntrance;
  final Duration? animationDuration;
  final Curve? animationCurve;

  /// How far it rises.
  final double? entranceOffset;

  /// Cap on the text block's width. The glyph and the actions keep
  /// their own size; it is the SENTENCES that need a reading measure.
  final double? maxContentWidth;

  /// Whether the empty state announces itself when it appears.
  final bool? announceOnAppear;

  /// Field-by-field override — anything set on [other] wins.
  EmptyStateStyle mergedWith(EmptyStateStyle? other) {
    if (other == null) return this;
    return EmptyStateStyle(
      iconSize: other.iconSize ?? iconSize,
      iconColor: other.iconColor ?? iconColor,
      titleStyle: other.titleStyle ?? titleStyle,
      subtitleStyle: other.subtitleStyle ?? subtitleStyle,
      spacing: other.spacing ?? spacing,
      iconBackgroundColor: other.iconBackgroundColor ?? iconBackgroundColor,
      iconBackgroundRadius: other.iconBackgroundRadius ?? iconBackgroundRadius,
      padding: other.padding ?? padding,
      animateEntrance: other.animateEntrance ?? animateEntrance,
      animationDuration: other.animationDuration ?? animationDuration,
      animationCurve: other.animationCurve ?? animationCurve,
      entranceOffset: other.entranceOffset ?? entranceOffset,
      maxContentWidth: other.maxContentWidth ?? maxContentWidth,
      announceOnAppear: other.announceOnAppear ?? announceOnAppear,
    );
  }

  EmptyStateStyle copyWith({
    double? iconSize,
    Color? iconColor,
    TextStyle? titleStyle,
    TextStyle? subtitleStyle,
    double? spacing,
    Color? iconBackgroundColor,
    BorderRadius? iconBackgroundRadius,
    EdgeInsets? padding,
    bool? animateEntrance,
    Duration? animationDuration,
    Curve? animationCurve,
    double? entranceOffset,
    double? maxContentWidth,
    bool? announceOnAppear,
  }) => EmptyStateStyle(
    iconSize: iconSize ?? this.iconSize,
    iconColor: iconColor ?? this.iconColor,
    titleStyle: titleStyle ?? this.titleStyle,
    subtitleStyle: subtitleStyle ?? this.subtitleStyle,
    spacing: spacing ?? this.spacing,
    iconBackgroundColor: iconBackgroundColor ?? this.iconBackgroundColor,
    iconBackgroundRadius: iconBackgroundRadius ?? this.iconBackgroundRadius,
    padding: padding ?? this.padding,
    animateEntrance: animateEntrance ?? this.animateEntrance,
    animationDuration: animationDuration ?? this.animationDuration,
    animationCurve: animationCurve ?? this.animationCurve,
    entranceOffset: entranceOffset ?? this.entranceOffset,
    maxContentWidth: maxContentWidth ?? this.maxContentWidth,
    announceOnAppear: announceOnAppear ?? this.announceOnAppear,
  );
}

// ---------------------------------------------------------------------------
// ResolvedEmptyStateStyle
// ---------------------------------------------------------------------------

/// [EmptyStateStyle] after `caller > theme > defaults > palette`, for
/// ONE variant. Every themed field is non-null, so build code reads
/// `rs.iconColor` with no `??` ladder behind it.
@immutable
class ResolvedEmptyStateStyle {
  const ResolvedEmptyStateStyle({
    required this.iconSize,
    required this.iconColor,
    required this.iconBackgroundColor,
    required this.titleStyle,
    required this.subtitleStyle,
    required this.spacing,
    required this.padding,
    required this.animateEntrance,
    required this.animationDuration,
    required this.animationCurve,
    required this.entranceOffset,
    required this.maxContentWidth,
    required this.announceOnAppear,
    this.iconBackgroundRadius,
  });

  final double iconSize;
  final Color iconColor;
  final Color iconBackgroundColor;
  final TextStyle titleStyle;
  final TextStyle subtitleStyle;
  final double spacing;
  final EdgeInsets padding;
  final bool animateEntrance;
  final Duration animationDuration;
  final Curve animationCurve;
  final double entranceOffset;
  final double maxContentWidth;
  final bool announceOnAppear;

  /// Null is a circle, which is what a disc behind a glyph wants.
  final BorderRadius? iconBackgroundRadius;

  /// Inset the disc adds around the glyph.
  EdgeInsets get iconPadding =>
      EdgeInsets.all(iconSize * EmptyStateDefaults.iconPaddingFraction);

  /// A radius the size of the glyph is round enough to BE a circle at
  /// any size the disc can take.
  BorderRadius get discRadius =>
      iconBackgroundRadius ?? BorderRadius.circular(iconSize);

  double get subtitleGap => spacing * EmptyStateDefaults.subtitleGapFraction;
  double get actionGap => spacing * EmptyStateDefaults.actionGapFraction;
}
