import 'package:flutter/material.dart';

import '../../../core/animations/animation_presets.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

/// Geometry that only changes when this module changes. Anything an app
/// would rebrand lives on [ImageStyle] instead.
abstract final class ImageDefaults {
  static const borderRadius = 8.0;
  static const opacity = 1.0;
  static const fit = BoxFit.cover;
  static const overlayBlendMode = BlendMode.srcATop;
  static const gradientBorderWidth = 2.0;

  /// Glyph the error state draws when the caller supplied no widget.
  static const errorIconSize = 32.0;

  /// How much of the surface colour the error plate keeps. It stands in
  /// for a picture, so it reads as a gap, not as a warning.
  static const errorPlateOpacity = 0.35;

  /// Width the shimmer placeholder falls back to when the image has no
  /// width of its own — a placeholder with no bounds is invisible.
  static const placeholderWidth = 56.0;

  static const progressThickness = 2.5;

  static const alignment = Alignment.center;

  /// How long one pass of the loading sheen takes, and how wide the
  /// band is as a share of the box.
  /// How long a load may take before a placeholder appears at all, and
  /// how long one stays once it has.
  ///
  /// The same pair `LoadingOptions` uses app-wide (200 / 400), and for
  /// the same reason: a placeholder that appears and vanishes inside a
  /// few frames reads as a GLITCH, not as progress. Below the delay the
  /// picture simply arrives; past it, the placeholder is held long
  /// enough to have been meant.
  static const placeholderDelay = Duration(milliseconds: 200);
  static const placeholderMinDuration = Duration(milliseconds: 400);

  static const sheenPeriod = Duration(milliseconds: 1400);
  static const sheenBandFraction = 0.35;

  /// How much of the highlight colour the sheen carries at its centre.
  /// A blurred picture underneath is the INFORMATION; the sweep only
  /// has to say "still working".
  static const sheenOpacity = 0.35;

  // ─── Full-screen viewer ──────────────────────────────────────

  /// How far past "fits the screen" a picture may be pinched.
  static const viewerMaxScale = 4.0;

  /// Drag needed to dismiss.
  static const viewerDismissDistance = 160.0;

  /// How far a pointer travels before the viewer decides a gesture is a
  /// dismissal rather than a swipe between pictures.
  static const viewerDragSlop = 12.0;

  /// The backdrop, and the discs the viewer's own buttons sit on —
  /// both over arbitrary imagery, so both are scrim rather than a role
  /// colour.
  static const viewerScrimOpacity = 0.92;
  static const viewerBarScrimOpacity = 0.45;
  static const repeat = ImageRepeat.noRepeat;

  /// Downscaled photographs alias without it — a 4000px source drawn at
  /// 100px picks single pixels rather than averaging them.
  static const filterQuality = FilterQuality.medium;

  /// How long a picture takes to arrive once decoded. Only a picture
  /// that was NOT ready synchronously fades; one already in the cache
  /// appears at once, or a scrolling list flickers.
  static const fadeDuration = AppDurations.fast;

  /// The retry pill's scrim, over arbitrary imagery.
  static const retryScrimOpacity = 0.55;

  /// Memory-cache resolution as a multiple of the laid-out size. Two is
  /// a 3x screen rounded down: decoding at 3x costs 2.25x the bytes of
  /// 2x for detail no phone shows on a thumbnail.
  static const cacheSizeFactor = 2;
}

// ---------------------------------------------------------------------------
// ImageStyle
// ---------------------------------------------------------------------------

/// Themeable styling bag for `GlobalImage` — EVERY field nullable.
///
/// Resolution order, materialized once per build by `resolve`:
/// `caller > GlobalImageTheme.style > ImageStyle.defaults > palette`.
///
/// The widget keeps SOURCES (url / asset / file / bytes), LAYOUT (width,
/// height, aspect ratio) and BEHAVIOUR (tap, retry, hero, overlay). What
/// lives here is what an app would rebrand once: the corner, the frame,
/// the plate behind a picture that failed to arrive.
///
/// Adding a themed field means touching five places: here, [mergedWith],
/// [copyWith], [ResolvedImageStyle] and `GlobalImageTheme.lerp`.
@immutable
class ImageStyle {
  const ImageStyle({
    this.fit,
    this.padding,
    this.borderRadius,
    this.border,
    this.borderColor,
    this.borderWidth,
    this.gradientBorder,
    this.gradientBorderWidth,
    this.backgroundColor,
    this.color,
    this.overlayBlendMode,
    this.gradient,
    this.boxShadow,
    this.innerShadow,
    this.opacity,
    this.grayscale,
    this.errorIconColor,
    this.errorPlateColor,
    this.errorIconSize,
    this.progressColor,
    this.filterQuality,
    this.fadeDuration,
    this.alignment,
    this.repeat,
    this.blurHashSheen,
    this.placeholderDelay,
    this.placeholderMinDuration,
  }) : assert(
         opacity == null || (opacity >= 0 && opacity <= 1),
         'Opacity must be between 0 and 1',
       );

  /// Compile-time floor. Colours are deliberately absent: they resolve
  /// from `context.<group>Colors` at build time, so a frame tracks role,
  /// brightness and saturation.
  static const ImageStyle defaults = ImageStyle(
    fit: ImageDefaults.fit,
    borderRadius: BorderRadius.all(
      Radius.circular(ImageDefaults.borderRadius),
    ),
    gradientBorderWidth: ImageDefaults.gradientBorderWidth,
    overlayBlendMode: ImageDefaults.overlayBlendMode,
    opacity: ImageDefaults.opacity,
    grayscale: false,
    errorIconSize: ImageDefaults.errorIconSize,
    filterQuality: ImageDefaults.filterQuality,
    fadeDuration: ImageDefaults.fadeDuration,
    alignment: ImageDefaults.alignment,
    repeat: ImageDefaults.repeat,
    blurHashSheen: true,
    placeholderDelay: ImageDefaults.placeholderDelay,
    placeholderMinDuration: ImageDefaults.placeholderMinDuration,
  );

  /// How the picture fills its box.
  final BoxFit? fit;

  /// Inset between the frame and the picture.
  final EdgeInsets? padding;

  /// The frame's corner. Directional radii are resolved against the
  /// ambient direction, not against LTR.
  final BorderRadiusGeometry? borderRadius;

  /// A whole border. Composed from [borderColor] / [borderWidth] when
  /// you do not hand one over.
  final BoxBorder? border;
  final Color? borderColor;
  final double? borderWidth;

  /// Gradient frame, which wins over [border].
  final Gradient? gradientBorder;
  final double? gradientBorderWidth;

  /// What shows through where the picture does not cover.
  final Color? backgroundColor;

  /// Tint over the picture, through [overlayBlendMode].
  final Color? color;
  final BlendMode? overlayBlendMode;

  /// Gradient over the picture, through the same blend.
  final Gradient? gradient;

  final List<BoxShadow>? boxShadow;

  /// Shadow drawn INSIDE the frame — a vignette, not a drop shadow.
  final BoxShadow? innerShadow;

  final double? opacity;
  final bool? grayscale;

  /// The failed-to-load plate.
  final Color? errorIconColor;
  final Color? errorPlateColor;
  final double? errorIconSize;

  /// The download indicator, when `showProgress` is on.
  final Color? progressColor;

  /// Sampling used when the picture is drawn at a size other than its
  /// own — which, for a photograph in a tile, is always.
  final FilterQuality? filterQuality;

  /// Fade applied to a picture that had to be decoded. `Duration.zero`
  /// turns it off.
  final Duration? fadeDuration;

  /// Which part survives the crop. `BoxFit.cover` on a portrait keeps
  /// the middle by default, which is where faces are NOT — a gallery of
  /// people wants `Alignment.topCenter`.
  final AlignmentGeometry? alignment;

  /// Tiling, for a pattern or a texture.
  final ImageRepeat? repeat;

  /// Whether a light sweeps across the BlurHash while the picture
  /// loads.
  ///
  /// A blur alone is ambiguous — it looks like a picture that HAS
  /// arrived and is simply out of focus. The sweep is what says the
  /// real one is still coming.
  final bool? blurHashSheen;

  /// How long a load may run before a placeholder appears. `Duration
  /// .zero` shows one immediately.
  final Duration? placeholderDelay;

  /// How long it stays once it has appeared.
  final Duration? placeholderMinDuration;

  /// Field-by-field override — anything set on [other] wins.
  ImageStyle mergedWith(ImageStyle? other) {
    if (other == null) return this;
    return ImageStyle(
      fit: other.fit ?? fit,
      padding: other.padding ?? padding,
      borderRadius: other.borderRadius ?? borderRadius,
      border: other.border ?? border,
      borderColor: other.borderColor ?? borderColor,
      borderWidth: other.borderWidth ?? borderWidth,
      gradientBorder: other.gradientBorder ?? gradientBorder,
      gradientBorderWidth: other.gradientBorderWidth ?? gradientBorderWidth,
      backgroundColor: other.backgroundColor ?? backgroundColor,
      color: other.color ?? color,
      overlayBlendMode: other.overlayBlendMode ?? overlayBlendMode,
      gradient: other.gradient ?? gradient,
      boxShadow: other.boxShadow ?? boxShadow,
      innerShadow: other.innerShadow ?? innerShadow,
      opacity: other.opacity ?? opacity,
      grayscale: other.grayscale ?? grayscale,
      errorIconColor: other.errorIconColor ?? errorIconColor,
      errorPlateColor: other.errorPlateColor ?? errorPlateColor,
      errorIconSize: other.errorIconSize ?? errorIconSize,
      progressColor: other.progressColor ?? progressColor,
      filterQuality: other.filterQuality ?? filterQuality,
      fadeDuration: other.fadeDuration ?? fadeDuration,
      alignment: other.alignment ?? alignment,
      repeat: other.repeat ?? repeat,
      blurHashSheen: other.blurHashSheen ?? blurHashSheen,
      placeholderDelay: other.placeholderDelay ?? placeholderDelay,
      placeholderMinDuration:
          other.placeholderMinDuration ?? placeholderMinDuration,
    );
  }

  ImageStyle copyWith({
    BoxFit? fit,
    EdgeInsets? padding,
    BorderRadiusGeometry? borderRadius,
    BoxBorder? border,
    Color? borderColor,
    double? borderWidth,
    Gradient? gradientBorder,
    double? gradientBorderWidth,
    Color? backgroundColor,
    Color? color,
    BlendMode? overlayBlendMode,
    Gradient? gradient,
    List<BoxShadow>? boxShadow,
    BoxShadow? innerShadow,
    double? opacity,
    bool? grayscale,
    Color? errorIconColor,
    Color? errorPlateColor,
    double? errorIconSize,
    Color? progressColor,
    FilterQuality? filterQuality,
    Duration? fadeDuration,
    AlignmentGeometry? alignment,
    ImageRepeat? repeat,
    bool? blurHashSheen,
    Duration? placeholderDelay,
    Duration? placeholderMinDuration,
  }) => ImageStyle(
    fit: fit ?? this.fit,
    padding: padding ?? this.padding,
    borderRadius: borderRadius ?? this.borderRadius,
    border: border ?? this.border,
    borderColor: borderColor ?? this.borderColor,
    borderWidth: borderWidth ?? this.borderWidth,
    gradientBorder: gradientBorder ?? this.gradientBorder,
    gradientBorderWidth: gradientBorderWidth ?? this.gradientBorderWidth,
    backgroundColor: backgroundColor ?? this.backgroundColor,
    color: color ?? this.color,
    overlayBlendMode: overlayBlendMode ?? this.overlayBlendMode,
    gradient: gradient ?? this.gradient,
    boxShadow: boxShadow ?? this.boxShadow,
    innerShadow: innerShadow ?? this.innerShadow,
    opacity: opacity ?? this.opacity,
    grayscale: grayscale ?? this.grayscale,
    errorIconColor: errorIconColor ?? this.errorIconColor,
    errorPlateColor: errorPlateColor ?? this.errorPlateColor,
    errorIconSize: errorIconSize ?? this.errorIconSize,
    progressColor: progressColor ?? this.progressColor,
    filterQuality: filterQuality ?? this.filterQuality,
    fadeDuration: fadeDuration ?? this.fadeDuration,
    alignment: alignment ?? this.alignment,
    repeat: repeat ?? this.repeat,
    blurHashSheen: blurHashSheen ?? this.blurHashSheen,
    placeholderDelay: placeholderDelay ?? this.placeholderDelay,
    placeholderMinDuration:
        placeholderMinDuration ?? this.placeholderMinDuration,
  );
}

// ---------------------------------------------------------------------------
// ResolvedImageStyle
// ---------------------------------------------------------------------------

/// [ImageStyle] after `caller > theme > defaults > palette`, resolved
/// against a DIRECTION — a directional corner radius means different
/// corners in Arabic, and the frame, its clip and its inner shadow all
/// have to agree on which.
@immutable
class ResolvedImageStyle {
  const ResolvedImageStyle({
    required this.fit,
    required this.borderRadius,
    required this.gradientBorderWidth,
    required this.overlayBlendMode,
    required this.opacity,
    required this.grayscale,
    required this.errorIconColor,
    required this.errorPlateColor,
    required this.errorIconSize,
    required this.progressColor,
    required this.filterQuality,
    required this.fadeDuration,
    required this.alignment,
    required this.repeat,
    required this.blurHashSheen,
    required this.placeholderDelay,
    required this.placeholderMinDuration,
    required this.retryScrimColor,
    required this.retryLabelColor,
    this.padding,
    this.border,
    this.gradientBorder,
    this.backgroundColor,
    this.color,
    this.gradient,
    this.boxShadow,
    this.innerShadow,
  });

  final BoxFit fit;

  /// Already resolved against the ambient direction.
  final BorderRadius borderRadius;

  final double gradientBorderWidth;
  final BlendMode overlayBlendMode;
  final double opacity;
  final bool grayscale;

  final Color errorIconColor;
  final Color errorPlateColor;
  final double errorIconSize;
  final Color progressColor;
  final FilterQuality filterQuality;
  final Duration fadeDuration;
  final AlignmentGeometry alignment;
  final ImageRepeat repeat;
  final bool blurHashSheen;
  final Duration placeholderDelay;
  final Duration placeholderMinDuration;

  /// The retry pill sits on a scrim over arbitrary imagery, so its two
  /// colours are fixed against each other rather than against the page.
  final Color retryScrimColor;
  final Color retryLabelColor;

  final EdgeInsets? padding;
  final BoxBorder? border;
  final Gradient? gradientBorder;
  final Color? backgroundColor;
  final Color? color;
  final Gradient? gradient;
  final List<BoxShadow>? boxShadow;
  final BoxShadow? innerShadow;

  /// How wide the frame's own line is, whichever kind it is.
  double get frameWidth {
    if (gradientBorder != null) return gradientBorderWidth;
    final b = border;
    return b is Border ? b.top.width : 0.0;
  }

  /// The radius to clip CONTENT with: the frame's own radius minus the
  /// line it draws, or the picture bleeds over its own border.
  BorderRadius get clipRadius =>
      borderRadius - BorderRadius.all(Radius.circular(frameWidth));

  /// Pixels to decode for a box [logical] wide, or null to decode at
  /// the source's own size.
  ///
  /// Applied to EVERY source, not only the network one: a 4000px asset
  /// in a 100px tile costs its full bitmap just as a downloaded photo
  /// does, and asset lists are where that adds up fastest.
  int? cacheExtent(double? logical) => logical != null && logical.isFinite
      ? (logical * ImageDefaults.cacheSizeFactor).toInt()
      : null;

  /// A ripple takes the frame's radius only when nothing insets it —
  /// with padding the ink sits in a smaller box and a rounded splash
  /// would float away from its corners.
  BorderRadius inkRadius(EdgeInsets? pad) =>
      pad == null || pad == EdgeInsets.zero ? borderRadius : BorderRadius.zero;
}

/// What a network image URL has to be.
///
/// Pure, and public, because the rule it replaces was a REGEX demanding
/// a file extension — and the widget it lived in cannot be built with a
/// network in a test, so nothing checked it.
abstract final class ImageUrls {
  /// Whether this is worth handing to the network stack at all.
  ///
  /// http(s) with a host, and nothing more. An EXTENSION is not what
  /// makes a URL an image — the response's content type is, and most
  /// real ones carry no extension: `picsum.photos/id/237/400/400`, an
  /// S3 presigned link, a Cloudinary transform, a Gravatar hash. Every
  /// one of those failed `Validators.isValidImageUrl` and drew an
  /// error plate for a picture that loads perfectly.
  ///
  /// A URL that is not a picture still ends at the error plate; it
  /// gets there by FAILING TO LOAD rather than by failing a regex.
  static bool looksFetchable(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    if (!uri.isScheme('http') && !uri.isScheme('https')) return false;
    return uri.host.isNotEmpty;
  }
}
