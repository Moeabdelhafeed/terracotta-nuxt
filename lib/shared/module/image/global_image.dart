// Dart imports:
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:flutter_svg/svg.dart';

import '../../../core/constants/enums/media/image_format.dart';
import '../../../core/constants/enums/media/image_type.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/strings/common_strings.dart';
import '../../../core/painters/gradient_border_painter.dart';
import '../../../core/tokens/extensions.dart';
import '../../../core/utils/loggers/logger.dart';
import '../buttons/global_filled_button.dart';
import '../icon/global_icon.dart';
import '../progress/global_progress.dart';
import '../shimmer/global_shimmer.dart';
import 'image_models.dart';
import 'image_painters.dart';
import 'image_viewer.dart';
import 'masked_ripple.dart';
import 'theme/image_theme.dart';

export 'image_models.dart';
export 'image_painters.dart';
export 'image_viewer.dart';
export 'theme/image_theme.dart';

part 'image_state.dart';

// ---------------------------------------------------------------------------
// GlobalImage — multi-source image widget
// ---------------------------------------------------------------------------

/// A picture from any of four sources, in a themeable frame.
///
/// ```dart
/// GlobalImage.n('https://…/photo.jpg', width: 120, height: 80)
/// GlobalImage.a('assets/images/logo.png', style: ImageStyle(padding: …))
/// GlobalImage.auto(source)   // picks the source kind from the string
/// ```
///
/// The widget keeps SOURCES, LAYOUT and BEHAVIOUR; everything an app
/// would rebrand — the corner, the frame, the plate behind a picture
/// that failed to arrive — lives on [ImageStyle]. There were
/// twenty-seven flat visual parameters on the widget before, forwarded
/// by hand through five factories, which is most of why this file was
/// four hundred lines of parameter list.
class GlobalImage extends StatefulWidget {
  const GlobalImage({
    super.key,
    required this.type,
    this.url,
    this.assetPath,
    this.file,
    this.bytes,
    this.provider,
    this.style = const ImageStyle(),
    this.width,
    this.height,
    this.aspectRatio,
    this.placeholder,
    this.errorWidget,
    this.overlay,
    this.onTap,
    this.heroTag,
    this.semanticLabel,
    this.mirrorInRtl = false,
    this.transparencyAwareRipple = false,
    this.retryOnError = false,
    this.showProgress = false,
    this.cacheNetwork = true,
    this.errorBuilder,
    this.httpHeaders,
    this.cacheKey,
    this.blurHash,
    this.onLoaded,
    this.onError,
    this.lightbox = false,
  }) : assert(
         (type == ImageType.network && url != null) ||
             (type == ImageType.asset && assetPath != null) ||
             (type == ImageType.file && file != null) ||
             (type == ImageType.memory && bytes != null) ||
             (type == ImageType.provider && provider != null),
         'Corresponding data must be provided for the selected ImageType',
       );

  // ─── Sources ───────────────────────────────────────────────

  final ImageType type;

  /// An `ImageProvider` the caller already has.
  ///
  /// The escape hatch for the three widgets whose API takes one — a
  /// container's background, a sliver app bar's backdrop, an avatar's
  /// picture. Everything else names a url, an asset, a file or bytes
  /// and lets this module resolve it, because a provider skips the
  /// module's own caching decisions.
  final ImageProvider? provider;
  final String? url;
  final String? assetPath;
  final File? file;
  final Uint8List? bytes;

  // ─── Style + layout ────────────────────────────────────────

  /// Themeable paint bag. See [ImageStyle].
  final ImageStyle style;

  final double? width;
  final double? height;

  /// Forces a ratio (16 / 9, 1, 4 / 3) whatever the picture's own.
  final double? aspectRatio;

  // ─── Slots ─────────────────────────────────────────────────

  /// Shown while a network image loads. A shimmer of the image's own
  /// size otherwise.
  final Widget? placeholder;

  /// Shown when the source cannot be read. The module's own plate
  /// otherwise.
  ///
  /// Use [errorBuilder] instead when the message depends on WHY: a 404
  /// means the picture is gone, a timeout means try again, and a static
  /// widget cannot tell them apart.
  final Widget? errorWidget;

  /// Builds the failed state from the error itself. Wins over
  /// [errorWidget].
  final Widget Function(BuildContext context, Object? error)? errorBuilder;

  /// Painted over the picture, inside the frame — a play button, a
  /// caption scrim.
  final Widget? overlay;

  // ─── Behaviour ─────────────────────────────────────────────

  final VoidCallback? onTap;

  /// Wraps the frame in a `Hero` when set.
  final String? heroTag;

  /// What a screen reader calls this picture.
  ///
  /// Null makes it DECORATION and hides it from the semantics tree,
  /// which is right for a background or a texture and wrong for a photo
  /// carrying meaning. There was no way to say either before.
  final String? semanticLabel;

  /// Whether the picture mirrors horizontally in RTL.
  ///
  /// OFF, and this used to be ON for every image: an Arabic build
  /// mirrored photographs, logos and screenshots — text inside them
  /// included. A picture is not a directional glyph.
  final bool mirrorInRtl;

  /// Masks the ripple to the picture's own non-transparent pixels.
  final bool transparencyAwareRipple;

  /// Whether tapping the error plate reloads the source.
  final bool retryOnError;

  /// Whether a network download shows its progress.
  final bool showProgress;

  /// Sent with a network request — an `Authorization` header, a signed
  /// cookie, a referer a CDN insists on.
  ///
  /// Without this there was no way to show a private image at all,
  /// which rules out most real backends.
  final Map<String, String>? httpHeaders;

  /// What the disk cache keys on, when the URL itself is unstable.
  ///
  /// A signed URL carries an expiring token, so keying on it misses
  /// every single time and re-downloads the same bytes; key on the
  /// object's own id instead.
  final String? cacheKey;

  /// A BlurHash of the picture, shown while it loads.
  ///
  /// Twenty-odd characters that decode to a blurred version of the
  /// image itself, so a gallery fills with the right SHAPES immediately
  /// instead of grey rectangles. Wins over the shimmer placeholder.
  final String? blurHash;

  /// Fired once the picture is on screen, and when it fails — for
  /// telemetry, not for layout.
  final VoidCallback? onLoaded;
  final void Function(Object? error)? onError;

  /// Whether tapping opens the full-screen viewer.
  ///
  /// Ignored when [onTap] is set: the caller wants their own action.
  final bool lightbox;

  /// Whether a network picture is served from the disk cache.
  ///
  /// On by default. Off for a source whose bytes change behind a fixed
  /// URL, or a signed one that must not be kept — the markdown and HTML
  /// renderers expose exactly this as `cacheNetworkImages`, which is
  /// why the knob exists here rather than each of them keeping a raw
  /// `Image.network` to fall back to.
  final bool cacheNetwork;

  // ─── Factories ─────────────────────────────────────────────

  /// Picks the source kind from the string — a URL, an asset path or a
  /// file path.
  factory GlobalImage.auto(
    String source, {
    Key? key,
    ImageStyle style = const ImageStyle(),
    double? width,
    double? height,
    double? aspectRatio,
    Widget? errorWidget,
    Widget Function(BuildContext, Object?)? errorBuilder,
    Widget? overlay,
    VoidCallback? onTap,
    String? heroTag,
    String? semanticLabel,
    String? blurHash,
    VoidCallback? onLoaded,
    void Function(Object?)? onError,
    bool lightbox = false,
    bool mirrorInRtl = false,
    bool transparencyAwareRipple = false,
  }) {
    final detected = ImageType.detectFromPath(source) ?? ImageType.network;
    return GlobalImage(
      key: key,
      type: detected,
      url: detected == ImageType.network ? source : null,
      assetPath: detected == ImageType.asset ? source : null,
      file: detected == ImageType.file ? File(source) : null,
      style: style,
      width: width,
      height: height,
      aspectRatio: aspectRatio,
      errorWidget: errorWidget,
      overlay: overlay,
      onTap: onTap,
      heroTag: heroTag,
      semanticLabel: semanticLabel,
      mirrorInRtl: mirrorInRtl,
      transparencyAwareRipple: transparencyAwareRipple,
    );
  }

  /// Network.
  factory GlobalImage.n(
    String url, {
    Key? key,
    ImageStyle style = const ImageStyle(),
    double? width,
    double? height,
    double? aspectRatio,
    Widget? placeholder,
    Widget? errorWidget,
    Widget Function(BuildContext, Object?)? errorBuilder,
    Widget? overlay,
    VoidCallback? onTap,
    String? heroTag,
    String? semanticLabel,
    String? blurHash,
    VoidCallback? onLoaded,
    void Function(Object?)? onError,
    bool lightbox = false,
    bool mirrorInRtl = false,
    bool transparencyAwareRipple = false,
    bool retryOnError = false,
    bool showProgress = false,
    bool cacheNetwork = true,
    Map<String, String>? httpHeaders,
    String? cacheKey,
  }) => GlobalImage(
    key: key,
    type: ImageType.network,
    url: url,
    style: style,
    width: width,
    height: height,
    aspectRatio: aspectRatio,
    placeholder: placeholder,
    errorWidget: errorWidget,
    errorBuilder: errorBuilder,
    overlay: overlay,
    onTap: onTap,
    heroTag: heroTag,
    semanticLabel: semanticLabel,
    blurHash: blurHash,
    onLoaded: onLoaded,
    onError: onError,
    lightbox: lightbox,
    mirrorInRtl: mirrorInRtl,
    transparencyAwareRipple: transparencyAwareRipple,
    retryOnError: retryOnError,
    showProgress: showProgress,
    cacheNetwork: cacheNetwork,
    httpHeaders: httpHeaders,
    cacheKey: cacheKey,
  );

  /// Asset.
  ///
  /// [placeholder] is here for the same reason it is on [GlobalImage.n]:
  /// an asset that has not decoded yet still trips the shimmer, and
  /// there are places where a shimmer is the wrong answer — a splash
  /// screen, whose whole job is to BE the wait, cannot sensibly show a
  /// skeleton of its own logo. Pass `SizedBox.shrink()` for nothing at
  /// all; leave it null for the house shimmer.
  factory GlobalImage.a(
    String assetPath, {
    Key? key,
    ImageStyle style = const ImageStyle(),
    double? width,
    double? height,
    double? aspectRatio,
    Widget? placeholder,
    Widget? errorWidget,
    Widget Function(BuildContext, Object?)? errorBuilder,
    Widget? overlay,
    VoidCallback? onTap,
    String? heroTag,
    String? semanticLabel,
    String? blurHash,
    VoidCallback? onLoaded,
    void Function(Object?)? onError,
    bool lightbox = false,
    bool mirrorInRtl = false,
    bool transparencyAwareRipple = false,
  }) => GlobalImage(
    key: key,
    type: ImageType.asset,
    assetPath: assetPath,
    style: style,
    width: width,
    height: height,
    aspectRatio: aspectRatio,
    placeholder: placeholder,
    errorWidget: errorWidget,
    errorBuilder: errorBuilder,
    overlay: overlay,
    onTap: onTap,
    heroTag: heroTag,
    semanticLabel: semanticLabel,
    blurHash: blurHash,
    onLoaded: onLoaded,
    onError: onError,
    lightbox: lightbox,
    mirrorInRtl: mirrorInRtl,
    transparencyAwareRipple: transparencyAwareRipple,
  );

  /// File on disk.
  factory GlobalImage.f(
    File file, {
    Key? key,
    ImageStyle style = const ImageStyle(),
    double? width,
    double? height,
    double? aspectRatio,
    Widget? errorWidget,
    Widget Function(BuildContext, Object?)? errorBuilder,
    Widget? overlay,
    VoidCallback? onTap,
    String? heroTag,
    String? semanticLabel,
    String? blurHash,
    VoidCallback? onLoaded,
    void Function(Object?)? onError,
    bool lightbox = false,
    bool mirrorInRtl = false,
    bool transparencyAwareRipple = false,
  }) => GlobalImage(
    key: key,
    type: ImageType.file,
    file: file,
    style: style,
    width: width,
    height: height,
    aspectRatio: aspectRatio,
    errorWidget: errorWidget,
    errorBuilder: errorBuilder,
    overlay: overlay,
    onTap: onTap,
    heroTag: heroTag,
    semanticLabel: semanticLabel,
    blurHash: blurHash,
    onLoaded: onLoaded,
    onError: onError,
    lightbox: lightbox,
    mirrorInRtl: mirrorInRtl,
    transparencyAwareRipple: transparencyAwareRipple,
  );

  /// Bytes in memory.
  /// From an `ImageProvider` the caller already holds.
  ///
  /// Prefer `.n` / `.a` / `.f` / `.m`: they let the module pick the
  /// loader, the cache extent and the error plate. This is for an API
  /// that hands you a provider and nothing else.
  factory GlobalImage.p(
    ImageProvider provider, {
    Key? key,
    ImageStyle style = const ImageStyle(),
    double? width,
    double? height,
    double? aspectRatio,
    String? semanticLabel,
    VoidCallback? onTap,
    Widget? placeholder,
    Widget? errorWidget,
  }) => GlobalImage(
    key: key,
    type: ImageType.provider,
    provider: provider,
    style: style,
    width: width,
    height: height,
    aspectRatio: aspectRatio,
    semanticLabel: semanticLabel,
    onTap: onTap,
    placeholder: placeholder,
    errorWidget: errorWidget,
  );

  factory GlobalImage.m(
    Uint8List bytes, {
    Key? key,
    ImageStyle style = const ImageStyle(),
    double? width,
    double? height,
    double? aspectRatio,
    Widget? errorWidget,
    Widget Function(BuildContext, Object?)? errorBuilder,
    Widget? overlay,
    VoidCallback? onTap,
    String? heroTag,
    String? semanticLabel,
    String? blurHash,
    VoidCallback? onLoaded,
    void Function(Object?)? onError,
    bool lightbox = false,
    bool mirrorInRtl = false,
    bool transparencyAwareRipple = false,
  }) => GlobalImage(
    key: key,
    type: ImageType.memory,
    bytes: bytes,
    style: style,
    width: width,
    height: height,
    aspectRatio: aspectRatio,
    errorWidget: errorWidget,
    errorBuilder: errorBuilder,
    overlay: overlay,
    onTap: onTap,
    heroTag: heroTag,
    semanticLabel: semanticLabel,
    blurHash: blurHash,
    onLoaded: onLoaded,
    onError: onError,
    lightbox: lightbox,
    mirrorInRtl: mirrorInRtl,
    transparencyAwareRipple: transparencyAwareRipple,
  );

  @override
  State<GlobalImage> createState() => _GlobalImageState();
}
