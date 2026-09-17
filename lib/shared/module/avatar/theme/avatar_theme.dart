import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../../../core/extensions/theme_colors_extension.dart';
import '../avatar_models.dart';

/// App-wide defaults for [GlobalAvatar].
///
/// The rebrand hook: set the avatar's shape, ring and initials treatment
/// once here and every face in the app follows.
@immutable
class GlobalAvatarTheme extends ThemeExtension<GlobalAvatarTheme> {
  const GlobalAvatarTheme({this.style});

  final AvatarStyle? style;

  static GlobalAvatarTheme? maybeOf(BuildContext context) =>
      Theme.of(context).extension<GlobalAvatarTheme>();

  @override
  GlobalAvatarTheme copyWith({AvatarStyle? style}) =>
      GlobalAvatarTheme(style: style ?? this.style);

  @override
  GlobalAvatarTheme lerp(ThemeExtension<GlobalAvatarTheme>? other, double t) {
    if (other is! GlobalAvatarTheme) return this;
    return GlobalAvatarTheme(style: _lerpStyle(style, other.style, t));
  }

  /// Continuous fields interpolate; discrete ones snap at the midpoint —
  /// half a shape would rebuild the clip mid-animation.
  static AvatarStyle? _lerpStyle(AvatarStyle? a, AvatarStyle? b, double t) {
    if (a == null && b == null) return null;
    final pick = t < 0.5 ? a : b;
    return AvatarStyle(
      backgroundColor: Color.lerp(a?.backgroundColor, b?.backgroundColor, t),
      foregroundColor: Color.lerp(a?.foregroundColor, b?.foregroundColor, t),
      backgroundGradient: Gradient.lerp(
        a?.backgroundGradient,
        b?.backgroundGradient,
        t,
      ),
      border: Border.lerp(a?.border, b?.border, t),
      borderGradient: Gradient.lerp(a?.borderGradient, b?.borderGradient, t),
      borderWidth: lerpDouble(a?.borderWidth, b?.borderWidth, t),
      shadow: BoxShadow.lerpList(a?.shadow, b?.shadow, t),
      borderRadius: BorderRadius.lerp(a?.borderRadius, b?.borderRadius, t),
      initialsStyle: TextStyle.lerp(a?.initialsStyle, b?.initialsStyle, t),
      initialsFontRatio: lerpDouble(
        a?.initialsFontRatio,
        b?.initialsFontRatio,
        t,
      ),
      shape: pick?.shape,
      // A DecorationImage cannot be interpolated — two images have no
      // midpoint — so it snaps like the other discrete fields.
      backgroundImage: pick?.backgroundImage,
      splashColor: Color.lerp(a?.splashColor, b?.splashColor, t),
      highlightColor: Color.lerp(a?.highlightColor, b?.highlightColor, t),
    );
  }
}

extension AvatarStyleResolve on AvatarStyle {
  /// Stacks `caller > theme > defaults`, then fills colours from
  /// `context.<group>Colors`.
  ///
  /// [ResolvedAvatarStyle.backgroundColor] deliberately stays nullable:
  /// a named avatar generates its colour FROM the name, and filling a
  /// themed default here would erase that — every face in a list would
  /// come out the same colour.
  ResolvedAvatarStyle resolve(BuildContext context) {
    final merged = AvatarStyle.defaults
        .mergedWith(GlobalAvatarTheme.maybeOf(context)?.style)
        .mergedWith(this);
    const floor = AvatarStyle.defaults;

    return ResolvedAvatarStyle(
      // Initials sit on a saturated generated colour, so they take the
      // on-primary foreground rather than a hard-coded white.
      foregroundColor: merged.foregroundColor ?? context.textColors.onPrimary,
      borderWidth: merged.borderWidth ?? floor.borderWidth!,
      shape: merged.shape ?? floor.shape!,
      initialsFontRatio: merged.initialsFontRatio ?? floor.initialsFontRatio!,
      placeholderBackground: context.backgroundColors.outline.withValues(
        alpha: kAvatarPlaceholderBgOpacity,
      ),
      placeholderForeground: context.backgroundColors.outline,
      // The ink lands on a saturated generated colour or on a photo, so
      // it takes the ON-content colour rather than the surface's — and
      // at a heavier opacity than Material's default, which is tuned
      // for a pale card.
      splashColor:
          merged.splashColor ??
          context.textColors.onPrimary.withValues(alpha: kAvatarSplashOpacity),
      highlightColor:
          merged.highlightColor ??
          context.textColors.onPrimary.withValues(
            alpha: kAvatarHighlightOpacity,
          ),
      backgroundColor: merged.backgroundColor,
      backgroundGradient: merged.backgroundGradient,
      backgroundImage: merged.backgroundImage,
      border: merged.border,
      borderGradient: merged.borderGradient,
      shadow: merged.shadow,
      borderRadius: merged.borderRadius,
      initialsStyle: merged.initialsStyle,
    );
  }
}
