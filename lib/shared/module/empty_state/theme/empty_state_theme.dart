import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/theme_colors_extension.dart';
import '../empty_state_models.dart';

/// App-wide defaults for `GlobalEmptyState`.
///
/// The rebrand hook: set the glyph treatment and the type of every
/// "nothing here yet" screen in the app once here.
@immutable
class GlobalEmptyStateTheme extends ThemeExtension<GlobalEmptyStateTheme> {
  const GlobalEmptyStateTheme({this.style});

  final EmptyStateStyle? style;

  static GlobalEmptyStateTheme? maybeOf(BuildContext context) =>
      Theme.of(context).extension<GlobalEmptyStateTheme>();

  @override
  GlobalEmptyStateTheme copyWith({EmptyStateStyle? style}) =>
      GlobalEmptyStateTheme(style: style ?? this.style);

  @override
  GlobalEmptyStateTheme lerp(
    ThemeExtension<GlobalEmptyStateTheme>? other,
    double t,
  ) {
    if (other is! GlobalEmptyStateTheme) return this;
    return GlobalEmptyStateTheme(style: _lerpStyle(style, other.style, t));
  }

  /// Continuous fields interpolate; discrete ones snap at the midpoint.
  static EmptyStateStyle? _lerpStyle(
    EmptyStateStyle? a,
    EmptyStateStyle? b,
    double t,
  ) {
    if (a == null && b == null) return null;
    final pick = t < 0.5 ? a : b;
    return EmptyStateStyle(
      iconSize: lerpDouble(a?.iconSize, b?.iconSize, t),
      iconColor: Color.lerp(a?.iconColor, b?.iconColor, t),
      titleStyle: TextStyle.lerp(a?.titleStyle, b?.titleStyle, t),
      subtitleStyle: TextStyle.lerp(a?.subtitleStyle, b?.subtitleStyle, t),
      spacing: lerpDouble(a?.spacing, b?.spacing, t),
      iconBackgroundColor: Color.lerp(
        a?.iconBackgroundColor,
        b?.iconBackgroundColor,
        t,
      ),
      iconBackgroundRadius: BorderRadius.lerp(
        a?.iconBackgroundRadius,
        b?.iconBackgroundRadius,
        t,
      ),
      padding: EdgeInsets.lerp(a?.padding, b?.padding, t),
      entranceOffset: lerpDouble(a?.entranceOffset, b?.entranceOffset, t),
      maxContentWidth: lerpDouble(a?.maxContentWidth, b?.maxContentWidth, t),
      announceOnAppear: pick?.announceOnAppear,
      animateEntrance: pick?.animateEntrance,
      animationDuration: pick?.animationDuration,
      animationCurve: pick?.animationCurve,
    );
  }
}

extension EmptyStateStyleResolve on EmptyStateStyle {
  /// Stacks `caller > theme > defaults`, then fills colours from
  /// `context.<group>Colors` and the sizes from the [variant].
  ///
  /// The variant is an argument because the bag cannot know it, and
  /// three of its fields — glyph size, spacing, padding — mean different
  /// numbers on a full page and inside a card.
  ///
  /// [disableAnimations] turns the entrance OFF rather than shortening
  /// it. A block that fades and rises is decoration; the content it is
  /// announcing is the point.
  ResolvedEmptyStateStyle resolve(
    BuildContext context, {
    required EmptyStateVariant variant,
    bool disableAnimations = false,
  }) {
    final merged = EmptyStateStyle.defaults
        .mergedWith(GlobalEmptyStateTheme.maybeOf(context)?.style)
        .mergedWith(this);
    const floor = EmptyStateStyle.defaults;

    final text = context.textColors;

    // The glyph is the quietest thing on the screen — it is a shrug, not
    // a warning — so it takes the OUTLINE colour faded, and its disc a
    // whisper of the same.
    final iconColor =
        merged.iconColor ??
        context.backgroundColors.outline.withValues(
          alpha: EmptyStateDefaults.iconOpacity,
        );

    return ResolvedEmptyStateStyle(
      iconSize:
          merged.iconSize ??
          (variant.isCompact
              ? EmptyStateDefaults.compactIconSize
              : EmptyStateDefaults.iconSize),
      iconColor: iconColor,
      iconBackgroundColor:
          merged.iconBackgroundColor ??
          iconColor.withValues(
            alpha: EmptyStateDefaults.iconBackgroundOpacity,
          ),
      iconBackgroundRadius: merged.iconBackgroundRadius,
      // `Theme.of(context).colorScheme.onSurface` before, for both — the
      // one place in this module that bypassed the palette entirely.
      titleStyle:
          merged.titleStyle ??
          (context.textTheme.titleMedium ?? const TextStyle()).copyWith(
            fontWeight: FontWeight.w700,
            color: text.primary,
          ),
      subtitleStyle:
          merged.subtitleStyle ??
          (context.textTheme.bodyMedium ?? const TextStyle()).copyWith(
            color: text.secondary,
            height: 1.5,
          ),
      spacing:
          merged.spacing ??
          (variant.isCompact
              ? EmptyStateDefaults.compactSpacing
              : EmptyStateDefaults.spacing),
      padding:
          merged.padding ??
          (variant.isCompact
              ? EmptyStateDefaults.compactPadding
              : EmptyStateDefaults.padding),
      animateEntrance:
          !disableAnimations &&
          (merged.animateEntrance ?? floor.animateEntrance!),
      animationDuration: merged.animationDuration ?? floor.animationDuration!,
      animationCurve: merged.animationCurve ?? floor.animationCurve!,
      entranceOffset: merged.entranceOffset ?? floor.entranceOffset!,
      maxContentWidth: merged.maxContentWidth ?? floor.maxContentWidth!,
      announceOnAppear: merged.announceOnAppear ?? floor.announceOnAppear!,
    );
  }
}
