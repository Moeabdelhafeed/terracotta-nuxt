import 'package:flutter/material.dart';

import '../../../core/animations/animation_presets.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

const kAvatarDefaultSize = 40.0;
const kAvatarDefaultBorderWidth = 2.0;

/// Ink opacities for a tappable avatar. Louder than Material's defaults
/// because the ripple lands on a saturated generated colour or a photo,
/// not on a pale surface.
const kAvatarSplashOpacity = 0.28;
const kAvatarHighlightOpacity = 0.14;
const kAvatarAnimDuration = AppDurations.quick;
const kAvatarStatusBorderWidth = 2.0;
const kAvatarGroupOverlap = 0.3;
const kAvatarGroupMaxVisible = 5;

/// Share of the chip's box the "+N" glyph fills. Smaller than the
/// initials ratio on purpose — "+12" is three characters where initials
/// are at most two.
const kAvatarGroupOverflowFontRatio = 0.3;

/// Opacity of the overflow chip's fill against the page outline.
const kAvatarGroupOverflowOpacity = 0.15;
const kAvatarInitialsFontRatio = 0.38;
const kAvatarDisabledOpacity = 0.5;

/// Tint behind the "no image, no name" fallback glyph.
const kAvatarPlaceholderBgOpacity = 0.2;

/// Presence dot: size as a share of the avatar, how far it tucks in, and
/// the pulse it runs when `AvatarStatus.pulsate` is on.
const kAvatarStatusSizeRatio = 0.3;
const kAvatarStatusInsetRatio = 0.1;
const kAvatarPulseDuration = Duration(milliseconds: 1500);
const kAvatarPulseScale = 1.3;
const kAvatarPulseMinOpacity = 0.6;

/// Marks the presence dot's pulse wrapper, mounted only when
/// `AvatarStatus.pulsate` is on AND motion is allowed.
///
/// `FadeTransition` alone is not a usable finder — the avatar's image
/// fade mounts one too.
const kAvatarPulseKey = Key('avatar-status-pulse');

// ---------------------------------------------------------------------------
// AvatarShape
// ---------------------------------------------------------------------------

/// Shape of the avatar container.
enum AvatarShape {
  /// Perfect circle.
  circle,

  /// Rounded square.
  roundedSquare,

  /// iOS-style squircle (superellipse).
  squircle,
}

// ---------------------------------------------------------------------------
// AvatarSize
// ---------------------------------------------------------------------------

/// Predefined size presets.
enum AvatarSize {
  xs(24),
  sm(32),
  md(40),
  lg(56),
  xl(72);

  const AvatarSize(this.value);
  final double value;
}

// ---------------------------------------------------------------------------
// AvatarStatusType
// ---------------------------------------------------------------------------

/// Predefined status indicator types.
enum AvatarStatusType {
  online,
  offline,
  busy,
  away,
}

// ---------------------------------------------------------------------------
// AvatarStatusPosition
// ---------------------------------------------------------------------------

/// Position of the status indicator dot.
enum AvatarStatusPosition {
  topRight,
  topLeft,
  bottomRight,
  bottomLeft,
}

// ---------------------------------------------------------------------------
// AvatarStatus
// ---------------------------------------------------------------------------

/// Configuration for the status indicator dot.
@immutable
class AvatarStatus {
  const AvatarStatus({
    this.type,
    this.color,
    this.position = AvatarStatusPosition.bottomRight,
    this.size,
    this.borderColor,
    this.borderWidth = kAvatarStatusBorderWidth,
    this.pulsate = false,
    this.customWidget,
  });

  /// Predefined status type. Determines color when [color] is null.
  final AvatarStatusType? type;

  /// Custom status color. Overrides [type]-based color.
  final Color? color;

  /// Position of the status dot.
  final AvatarStatusPosition position;

  /// Size of the status dot. Defaults based on avatar size.
  final double? size;

  /// Border color around the dot (creates visual separation from avatar).
  /// Defaults to scaffold background color.
  final Color? borderColor;

  /// Border width around the dot.
  final double borderWidth;

  /// When true, the dot pulses for attention.
  final bool pulsate;

  /// Custom widget instead of a dot (e.g. icon, emoji).
  final Widget? customWidget;

  /// Resolves the effective color from [type] when [color] is null.
  Color resolveColor() {
    if (color != null) return color!;
    return switch (type) {
      AvatarStatusType.online => const Color(0xFF4CAF50),
      AvatarStatusType.offline => const Color(0xFF9E9E9E),
      AvatarStatusType.busy => const Color(0xFFF44336),
      AvatarStatusType.away => const Color(0xFFFF9800),
      null => const Color(0xFF4CAF50),
    };
  }

  /// Creates a copy with the given fields replaced.
  AvatarStatus copyWith({
    AvatarStatusType? type,
    Color? color,
    AvatarStatusPosition? position,
    double? size,
    Color? borderColor,
    double? borderWidth,
    bool? pulsate,
    Widget? customWidget,
  }) {
    return AvatarStatus(
      type: type ?? this.type,
      color: color ?? this.color,
      position: position ?? this.position,
      size: size ?? this.size,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      pulsate: pulsate ?? this.pulsate,
      customWidget: customWidget ?? this.customWidget,
    );
  }
}

// ---------------------------------------------------------------------------
// AvatarStyle
// ---------------------------------------------------------------------------

/// Styling configuration for [GlobalAvatar].
@immutable
class AvatarStyle {
  const AvatarStyle({
    this.backgroundColor,
    this.foregroundColor,
    this.backgroundGradient,
    this.backgroundImage,
    this.splashColor,
    this.highlightColor,
    this.border,
    this.borderGradient,
    this.borderWidth,
    this.shadow,
    this.shape,
    this.borderRadius,
    this.initialsStyle,
    this.initialsFontRatio,
  });

  /// Compile-time floor. Colours are deliberately absent: they come from
  /// `context.<group>Colors` at resolve time — or, for a named avatar,
  /// from the name itself — so an avatar tracks role and brightness.
  static const AvatarStyle defaults = AvatarStyle(
    borderWidth: kAvatarDefaultBorderWidth,
    shape: AvatarShape.circle,
    initialsFontRatio: kAvatarInitialsFontRatio,
  );

  /// Background color (for initials fallback). Auto-generated from name if null.
  final Color? backgroundColor;

  /// Foreground (text/icon) color. Defaults to white.
  final Color? foregroundColor;

  /// Gradient background. Overrides [backgroundColor].
  final Gradient? backgroundGradient;

  /// Ripple colour for a tappable avatar.
  final Color? splashColor;

  /// Colour held under a finger while it rests on a tappable avatar.
  final Color? highlightColor;

  /// Image painted BEHIND the avatar's content.
  ///
  /// Not the same thing as `imageUrl` / `imageProvider`, which are the
  /// content itself and fill the whole face. This one sits under
  /// initials, a placeholder icon or a custom child — a textured or
  /// branded backdrop rather than a photo of a person. It also shows
  /// through when a photo fails to load and the initials take over.
  final DecorationImage? backgroundImage;

  /// Solid border around the avatar.
  final Border? border;

  /// Gradient border. Overrides [border].
  final Gradient? borderGradient;

  /// Border width for [borderGradient].
  final double? borderWidth;

  /// Shadow behind the avatar.
  final List<BoxShadow>? shadow;

  /// Shape of the container.
  final AvatarShape? shape;

  /// Custom border radius. Overrides [shape] when set.
  final BorderRadius? borderRadius;

  /// Text style for initials. Overrides default.
  final TextStyle? initialsStyle;

  /// Font size as a ratio of avatar size. Defaults to 0.38.
  final double? initialsFontRatio;

  /// Field-by-field override — [other]'s non-null fields win.
  AvatarStyle mergedWith(AvatarStyle? other) {
    if (other == null) return this;
    return AvatarStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      foregroundColor: other.foregroundColor ?? foregroundColor,
      backgroundGradient: other.backgroundGradient ?? backgroundGradient,
      backgroundImage: other.backgroundImage ?? backgroundImage,
      splashColor: other.splashColor ?? splashColor,
      highlightColor: other.highlightColor ?? highlightColor,
      border: other.border ?? border,
      borderGradient: other.borderGradient ?? borderGradient,
      borderWidth: other.borderWidth ?? borderWidth,
      shadow: other.shadow ?? shadow,
      shape: other.shape ?? shape,
      borderRadius: other.borderRadius ?? borderRadius,
      initialsStyle: other.initialsStyle ?? initialsStyle,
      initialsFontRatio: other.initialsFontRatio ?? initialsFontRatio,
    );
  }

  /// Creates a copy with the given fields replaced.
  AvatarStyle copyWith({
    Color? backgroundColor,
    Color? foregroundColor,
    Gradient? backgroundGradient,
    DecorationImage? backgroundImage,
    Color? splashColor,
    Color? highlightColor,
    Border? border,
    Gradient? borderGradient,
    double? borderWidth,
    List<BoxShadow>? shadow,
    AvatarShape? shape,
    BorderRadius? borderRadius,
    TextStyle? initialsStyle,
    double? initialsFontRatio,
  }) {
    return AvatarStyle(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      foregroundColor: foregroundColor ?? this.foregroundColor,
      backgroundGradient: backgroundGradient ?? this.backgroundGradient,
      backgroundImage: backgroundImage ?? this.backgroundImage,
      splashColor: splashColor ?? this.splashColor,
      highlightColor: highlightColor ?? this.highlightColor,
      border: border ?? this.border,
      borderGradient: borderGradient ?? this.borderGradient,
      borderWidth: borderWidth ?? this.borderWidth,
      shadow: shadow ?? this.shadow,
      shape: shape ?? this.shape,
      borderRadius: borderRadius ?? this.borderRadius,
      initialsStyle: initialsStyle ?? this.initialsStyle,
      initialsFontRatio: initialsFontRatio ?? this.initialsFontRatio,
    );
  }
}

// ---------------------------------------------------------------------------
// ResolvedAvatarStyle
// ---------------------------------------------------------------------------

/// Materialized [AvatarStyle] — every themed field non-null.
@immutable
class ResolvedAvatarStyle {
  const ResolvedAvatarStyle({
    required this.foregroundColor,
    required this.borderWidth,
    required this.shape,
    required this.initialsFontRatio,
    required this.placeholderBackground,
    required this.placeholderForeground,
    required this.splashColor,
    required this.highlightColor,
    this.backgroundColor,
    this.backgroundGradient,
    this.backgroundImage,
    this.border,
    this.borderGradient,
    this.shadow,
    this.borderRadius,
    this.initialsStyle,
  });

  final Color foregroundColor;
  final double borderWidth;
  final AvatarShape shape;
  final double initialsFontRatio;

  /// Surface and glyph for the "no image, no name" fallback.
  final Color placeholderBackground;
  final Color placeholderForeground;

  /// Ink for a tappable avatar.
  final Color splashColor;
  final Color highlightColor;

  /// Null means "derive it" — from the name for a named avatar, or the
  /// brand colour otherwise. It is NOT a themed default, because a
  /// generated colour is the whole point of a named avatar.
  final Color? backgroundColor;

  final Gradient? backgroundGradient;

  /// Painted BEHIND the content — see [AvatarStyle.backgroundImage].
  final DecorationImage? backgroundImage;

  final Border? border;
  final Gradient? borderGradient;
  final List<BoxShadow>? shadow;
  final BorderRadius? borderRadius;
  final TextStyle? initialsStyle;
}
