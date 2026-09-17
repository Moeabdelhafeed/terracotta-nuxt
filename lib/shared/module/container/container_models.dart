import 'package:flutter/material.dart';

import 'container_defaults.dart';

export 'container_decorations.dart';
export 'container_defaults.dart';

/// Themeable styling bag for [GlobalContainer] — EVERY field nullable.
///
/// Resolution order, materialized once per build by
/// `style.resolve(context)`:
/// `caller > GlobalContainerTheme.style > ContainerStyle.defaults > palette`.
///
/// The BOX stays here — `width`, `height`, the min/max pair, `padding`
/// and `margin` — where other modules push layout onto the widget. A
/// container IS its box: the whole point of the module is a styled
/// rectangle, and its size is the first thing a caller restyles.
///
/// Adding a themed field means touching five places: here, [mergedWith],
/// [copyWith], [ResolvedContainerStyle] and `GlobalContainerTheme.lerp`.
@immutable
class ContainerStyle {
  const ContainerStyle({
    this.backgroundColor,
    this.backgroundGradient,
    this.backgroundImage,
    this.backgroundImageFit,
    this.backgroundImageOpacity,
    this.imageScrimOpacity,
    this.borderRadius,
    this.border,
    this.borderGradient,
    this.borderWidth,
    this.borderLineStyle,
    this.borderColor,
    this.borderDashWidth,
    this.borderDashGap,
    this.borderWaveAmplitude,
    this.borderWaveFrequency,
    this.shadow,
    this.innerShadow,
    this.innerShadowGradient,
    this.blur,
    this.blurBackgroundOpacity,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.minHeight,
    this.maxHeight,
    this.minWidth,
    this.maxWidth,
    this.useDeviceRadius,
    this.clipBehavior,
    this.animationDuration,
    this.animationCurve,
    this.respectReducedMotion,
    this.dense,
    this.enableHaptic,
    this.pressScale,
    this.tileMinHeight,
    this.slotSize,
    this.focusColor,
    this.focusRingWidth,
  });

  /// Compile-time floor. Colours are deliberately absent: they resolve
  /// from the palette at build time, so a container tracks the app's
  /// role, brightness and saturation.
  ///
  /// The RADIUS is absent too — the app theme sizes it from the tokens
  /// (`MyGlobalContainerTheme.build`), and a value here would win over
  /// nothing but still hide the token.
  static const ContainerStyle defaults = ContainerStyle(
    backgroundImageFit: BoxFit.cover,
    backgroundImageOpacity: 1,
    imageScrimOpacity: ContainerDefaults.imageScrimOpacity,
    borderWidth: ContainerDefaults.borderWidth,
    borderDashWidth: ContainerDefaults.borderDashWidth,
    borderDashGap: ContainerDefaults.borderDashGap,
    borderWaveAmplitude: ContainerDefaults.borderWaveAmplitude,
    borderWaveFrequency: ContainerDefaults.borderWaveFrequency,
    blur: 0,
    blurBackgroundOpacity: ContainerDefaults.blurBackgroundOpacity,
    useDeviceRadius: false,
    clipBehavior: Clip.antiAlias,
    animationDuration: ContainerDefaults.expandDuration,
    animationCurve: Curves.easeInOut,
    respectReducedMotion: true,
    dense: false,
    enableHaptic: false,
    pressScale: 1,
    focusRingWidth: ContainerDefaults.focusRingWidth,
  );

  /// Surface fill. Null takes the palette's CONTAINER — a container sits
  /// above the page, so it is not the page's own surface.
  final Color? backgroundColor;

  final Gradient? backgroundGradient;
  final ImageProvider? backgroundImage;
  final BoxFit? backgroundImageFit;
  final double? backgroundImageOpacity;

  /// The scrim over a background image, so text on it stays readable.
  final double? imageScrimOpacity;

  final BorderRadius? borderRadius;
  final Border? border;
  final Gradient? borderGradient;
  final double? borderWidth;
  final ContainerBorderLineStyle? borderLineStyle;

  /// Null takes the palette's OUTLINE. It was `colorScheme.outline`,
  /// which is Material's scheme rather than the app's.
  final Color? borderColor;

  final double? borderDashWidth;
  final double? borderDashGap;
  final double? borderWaveAmplitude;
  final double? borderWaveFrequency;

  /// Null takes one soft shadow in the palette's SCRIM. Pass `const []`
  /// for a flat container — that is not the same as null.
  final List<BoxShadow>? shadow;

  /// Inner shadow (inset).
  final List<BoxShadow>? innerShadow;

  /// Gradient for inner shadow. When set, draws a gradient inner glow.
  final Gradient? innerShadowGradient;

  final double? blur;

  /// How much of the fill shows through when [blur] is on.
  final double? blurBackgroundOpacity;

  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double? width;
  final double? height;
  final double? minHeight;
  final double? maxHeight;
  final double? minWidth;
  final double? maxWidth;
  final bool? useDeviceRadius;
  final Clip? clipBehavior;

  final Duration? animationDuration;
  final Curve? animationCurve;

  /// Tighter padding and smaller slots, for a row in a long list.
  final bool? dense;

  /// Whether a tap buzzes. Off, like every other module's — a list of
  /// fifty rows that all buzz is not feedback.
  final bool? enableHaptic;

  /// How far the box sinks under a finger. `1` is no press feedback.
  final double? pressScale;

  /// The floor a TILE stands at. Null takes the tile default, and only
  /// applies when the container is built as one.
  final double? tileMinHeight;

  /// What a leading or trailing slot is boxed to.
  final double? slotSize;

  /// The ring a keyboard-focused container wears. Null takes the
  /// palette's primary.
  final Color? focusColor;

  /// Zero draws no ring, for a container whose focus is shown some
  /// other way.
  final double? focusRingWidth;

  /// Whether "reduce motion" quiets this container's own animations —
  /// the expand, the selection ease, the animated border.
  ///
  /// ON. A border that rotates forever is exactly what the setting is
  /// for. Turn it off only for a container whose motion IS the content.
  final bool? respectReducedMotion;

  /// Field-by-field override — anything set on [other] wins.
  ContainerStyle mergedWith(ContainerStyle? other) {
    if (other == null) return this;
    return ContainerStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      backgroundGradient: other.backgroundGradient ?? backgroundGradient,
      backgroundImage: other.backgroundImage ?? backgroundImage,
      backgroundImageFit: other.backgroundImageFit ?? backgroundImageFit,
      backgroundImageOpacity:
          other.backgroundImageOpacity ?? backgroundImageOpacity,
      imageScrimOpacity: other.imageScrimOpacity ?? imageScrimOpacity,
      borderRadius: other.borderRadius ?? borderRadius,
      border: other.border ?? border,
      borderGradient: other.borderGradient ?? borderGradient,
      borderWidth: other.borderWidth ?? borderWidth,
      borderLineStyle: other.borderLineStyle ?? borderLineStyle,
      borderColor: other.borderColor ?? borderColor,
      borderDashWidth: other.borderDashWidth ?? borderDashWidth,
      borderDashGap: other.borderDashGap ?? borderDashGap,
      borderWaveAmplitude: other.borderWaveAmplitude ?? borderWaveAmplitude,
      borderWaveFrequency: other.borderWaveFrequency ?? borderWaveFrequency,
      shadow: other.shadow ?? shadow,
      innerShadow: other.innerShadow ?? innerShadow,
      innerShadowGradient: other.innerShadowGradient ?? innerShadowGradient,
      blur: other.blur ?? blur,
      blurBackgroundOpacity:
          other.blurBackgroundOpacity ?? blurBackgroundOpacity,
      padding: other.padding ?? padding,
      margin: other.margin ?? margin,
      width: other.width ?? width,
      height: other.height ?? height,
      minHeight: other.minHeight ?? minHeight,
      maxHeight: other.maxHeight ?? maxHeight,
      minWidth: other.minWidth ?? minWidth,
      maxWidth: other.maxWidth ?? maxWidth,
      useDeviceRadius: other.useDeviceRadius ?? useDeviceRadius,
      clipBehavior: other.clipBehavior ?? clipBehavior,
      animationDuration: other.animationDuration ?? animationDuration,
      animationCurve: other.animationCurve ?? animationCurve,
      dense: other.dense ?? dense,
      enableHaptic: other.enableHaptic ?? enableHaptic,
      pressScale: other.pressScale ?? pressScale,
      tileMinHeight: other.tileMinHeight ?? tileMinHeight,
      slotSize: other.slotSize ?? slotSize,
      focusColor: other.focusColor ?? focusColor,
      focusRingWidth: other.focusRingWidth ?? focusRingWidth,
      respectReducedMotion: other.respectReducedMotion ?? respectReducedMotion,
    );
  }

  ContainerStyle copyWith({
    Color? backgroundColor,
    Gradient? backgroundGradient,
    ImageProvider? backgroundImage,
    BoxFit? backgroundImageFit,
    double? backgroundImageOpacity,
    double? imageScrimOpacity,
    BorderRadius? borderRadius,
    Border? border,
    Gradient? borderGradient,
    double? borderWidth,
    ContainerBorderLineStyle? borderLineStyle,
    Color? borderColor,
    double? borderDashWidth,
    double? borderDashGap,
    double? borderWaveAmplitude,
    double? borderWaveFrequency,
    List<BoxShadow>? shadow,
    List<BoxShadow>? innerShadow,
    Gradient? innerShadowGradient,
    double? blur,
    double? blurBackgroundOpacity,
    EdgeInsets? padding,
    EdgeInsets? margin,
    double? width,
    double? height,
    double? minHeight,
    double? maxHeight,
    double? minWidth,
    double? maxWidth,
    bool? useDeviceRadius,
    Clip? clipBehavior,
    Duration? animationDuration,
    Curve? animationCurve,
    bool? dense,
    bool? enableHaptic,
    double? pressScale,
    double? tileMinHeight,
    double? slotSize,
    Color? focusColor,
    double? focusRingWidth,
    bool? respectReducedMotion,
  }) => ContainerStyle(
    backgroundColor: backgroundColor ?? this.backgroundColor,
    backgroundGradient: backgroundGradient ?? this.backgroundGradient,
    backgroundImage: backgroundImage ?? this.backgroundImage,
    backgroundImageFit: backgroundImageFit ?? this.backgroundImageFit,
    backgroundImageOpacity:
        backgroundImageOpacity ?? this.backgroundImageOpacity,
    imageScrimOpacity: imageScrimOpacity ?? this.imageScrimOpacity,
    borderRadius: borderRadius ?? this.borderRadius,
    border: border ?? this.border,
    borderGradient: borderGradient ?? this.borderGradient,
    borderWidth: borderWidth ?? this.borderWidth,
    borderLineStyle: borderLineStyle ?? this.borderLineStyle,
    borderColor: borderColor ?? this.borderColor,
    borderDashWidth: borderDashWidth ?? this.borderDashWidth,
    borderDashGap: borderDashGap ?? this.borderDashGap,
    borderWaveAmplitude: borderWaveAmplitude ?? this.borderWaveAmplitude,
    borderWaveFrequency: borderWaveFrequency ?? this.borderWaveFrequency,
    shadow: shadow ?? this.shadow,
    innerShadow: innerShadow ?? this.innerShadow,
    innerShadowGradient: innerShadowGradient ?? this.innerShadowGradient,
    blur: blur ?? this.blur,
    blurBackgroundOpacity: blurBackgroundOpacity ?? this.blurBackgroundOpacity,
    padding: padding ?? this.padding,
    margin: margin ?? this.margin,
    width: width ?? this.width,
    height: height ?? this.height,
    minHeight: minHeight ?? this.minHeight,
    maxHeight: maxHeight ?? this.maxHeight,
    minWidth: minWidth ?? this.minWidth,
    maxWidth: maxWidth ?? this.maxWidth,
    useDeviceRadius: useDeviceRadius ?? this.useDeviceRadius,
    clipBehavior: clipBehavior ?? this.clipBehavior,
    animationDuration: animationDuration ?? this.animationDuration,
    animationCurve: animationCurve ?? this.animationCurve,
    dense: dense ?? this.dense,
    enableHaptic: enableHaptic ?? this.enableHaptic,
    pressScale: pressScale ?? this.pressScale,
    tileMinHeight: tileMinHeight ?? this.tileMinHeight,
    slotSize: slotSize ?? this.slotSize,
    focusColor: focusColor ?? this.focusColor,
    focusRingWidth: focusRingWidth ?? this.focusRingWidth,
    respectReducedMotion: respectReducedMotion ?? this.respectReducedMotion,
  );

  /// The same bag with nothing painted OUTSIDE the box.
  ///
  /// For a container nested in a wrapper that owns the outside — the
  /// selection frame, the dismiss background. `copyWith` cannot express
  /// it: passing null there means "keep what you had", and the whole
  /// point is to clear the margin and flatten the shadow.
  ContainerStyle withoutOuterDecoration() => copyWith(
    shadow: const [],
  )._clearMargin();

  ContainerStyle _clearMargin() => ContainerStyle(
    backgroundColor: backgroundColor,
    backgroundGradient: backgroundGradient,
    backgroundImage: backgroundImage,
    backgroundImageFit: backgroundImageFit,
    backgroundImageOpacity: backgroundImageOpacity,
    imageScrimOpacity: imageScrimOpacity,
    borderRadius: borderRadius,
    border: border,
    borderGradient: borderGradient,
    borderWidth: borderWidth,
    borderLineStyle: borderLineStyle,
    borderColor: borderColor,
    borderDashWidth: borderDashWidth,
    borderDashGap: borderDashGap,
    borderWaveAmplitude: borderWaveAmplitude,
    borderWaveFrequency: borderWaveFrequency,
    shadow: const [],
    innerShadow: innerShadow,
    innerShadowGradient: innerShadowGradient,
    blur: blur,
    blurBackgroundOpacity: blurBackgroundOpacity,
    padding: padding,
    width: width,
    height: height,
    minHeight: minHeight,
    maxHeight: maxHeight,
    minWidth: minWidth,
    maxWidth: maxWidth,
    useDeviceRadius: useDeviceRadius,
    clipBehavior: clipBehavior,
    animationDuration: animationDuration,
    animationCurve: animationCurve,
    respectReducedMotion: respectReducedMotion,
  );
}

// ---------------------------------------------------------------------------
// ResolvedContainerStyle
// ---------------------------------------------------------------------------

/// [ContainerStyle] after `caller > theme > defaults > palette`. Every
/// themed field is non-null, so build code reads `rs.backgroundColor`
/// with no `??` ladder behind it.
///
/// The genuinely optional ones stay nullable, because null MEANS
/// something there: no gradient, no image, no border, no fixed width.
@immutable
class ResolvedContainerStyle {
  const ResolvedContainerStyle({
    required this.backgroundColor,
    required this.backgroundGradient,
    required this.backgroundImage,
    required this.backgroundImageFit,
    required this.backgroundImageOpacity,
    required this.imageScrimOpacity,
    required this.borderRadius,
    required this.border,
    required this.borderGradient,
    required this.borderWidth,
    required this.borderLineStyle,
    required this.borderColor,
    required this.borderDashWidth,
    required this.borderDashGap,
    required this.borderWaveAmplitude,
    required this.borderWaveFrequency,
    required this.shadow,
    required this.innerShadow,
    required this.innerShadowGradient,
    required this.blur,
    required this.blurBackgroundOpacity,
    required this.padding,
    required this.margin,
    required this.width,
    required this.height,
    required this.minHeight,
    required this.maxHeight,
    required this.minWidth,
    required this.maxWidth,
    required this.useDeviceRadius,
    required this.clipBehavior,
    required this.animationDuration,
    required this.animationCurve,
    required this.respectReducedMotion,
    required this.dense,
    required this.enableHaptic,
    required this.pressScale,
    required this.tileMinHeight,
    required this.slotSize,
    required this.focusColor,
    required this.focusRingWidth,
    required this.scrimColor,
    required this.onSurfaceColor,
    required this.secondaryTextColor,
    required this.badgeColor,
    required this.onBadgeColor,
  });

  final Color backgroundColor;
  final Gradient? backgroundGradient;
  final ImageProvider? backgroundImage;
  final BoxFit backgroundImageFit;
  final double backgroundImageOpacity;
  final double imageScrimOpacity;

  /// Null means "take the device's own screen radius", which is only
  /// known asynchronously — the widget resolves it separately.
  final BorderRadius? borderRadius;

  final Border? border;
  final Gradient? borderGradient;
  final double borderWidth;
  final ContainerBorderLineStyle? borderLineStyle;
  final Color borderColor;
  final double borderDashWidth;
  final double borderDashGap;
  final double borderWaveAmplitude;
  final double borderWaveFrequency;
  final List<BoxShadow> shadow;
  final List<BoxShadow>? innerShadow;
  final Gradient? innerShadowGradient;
  final double blur;
  final double blurBackgroundOpacity;
  final EdgeInsets padding;
  final EdgeInsets? margin;
  final double? width;
  final double? height;
  final double? minHeight;
  final double? maxHeight;
  final double? minWidth;
  final double? maxWidth;
  final bool useDeviceRadius;
  final Clip clipBehavior;
  final Duration animationDuration;
  final Curve animationCurve;
  final bool respectReducedMotion;
  final bool dense;
  final bool enableHaptic;
  final double pressScale;
  final double tileMinHeight;
  final double slotSize;
  final Color focusColor;
  final double focusRingWidth;

  /// The palette's scrim — what a shadow and an image wash are made of.
  /// Both were `Colors.black`.
  final Color scrimColor;

  /// What reads ON [backgroundColor] — the chevron, the drag handle, a
  /// title. It was `colorScheme.onSurface`.
  final Color onSurfaceColor;

  /// The subtitle, and anything else deliberately quieter than the
  /// title. It was `onSurface` at sixty per cent, which is a different
  /// colour from the palette's own secondary text.
  final Color secondaryTextColor;

  /// A badge's and a ribbon's fill, when the caller named none. It was
  /// `colorScheme.error` — the right MEANING, from the wrong scheme.
  final Color badgeColor;

  /// What reads ON [badgeColor]. It was a hard-coded `Colors.white`,
  /// which disappears the moment the fill is a light colour.
  final Color onBadgeColor;
}

// ---------------------------------------------------------------------------
// Badge + ribbon
// ---------------------------------------------------------------------------
