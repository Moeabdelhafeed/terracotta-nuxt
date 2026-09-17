import 'dart:io';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

import '../../../core/animations/animation_presets.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/strings/common_strings.dart';
import '../../../core/tokens/extensions.dart';
import '../icon/global_icon.dart';
import '../progress/global_progress.dart';
import 'image_models.dart';

// ---------------------------------------------------------------------------
// GlobalImageSource
// ---------------------------------------------------------------------------

/// One picture, in the form the viewer needs it: an `ImageProvider`.
///
/// `GlobalImage` takes four separate source parameters because it is a
/// widget with an assert; a viewer takes a LIST, and a list of "one of
/// four nullable fields" is unusable. This is the same four as a sealed
/// value.
@immutable
sealed class GlobalImageSource {
  const GlobalImageSource({this.semanticLabel, this.heroTag});

  const factory GlobalImageSource.network(
    String url, {
    String? semanticLabel,
    String? heroTag,
    Map<String, String>? headers,
  }) = NetworkImageSource;

  const factory GlobalImageSource.asset(
    String path, {
    String? semanticLabel,
    String? heroTag,
  }) = AssetImageSource;

  /// A provider the caller already has. Every other case exists to
  /// BUILD one; this one is handed the answer.
  const factory GlobalImageSource.provider(
    ImageProvider provider, {
    String? semanticLabel,
    String? heroTag,
  }) = ProviderImageSource;

  const factory GlobalImageSource.file(
    File file, {
    String? semanticLabel,
    String? heroTag,
  }) = FileImageSource;

  const factory GlobalImageSource.memory(
    Uint8List bytes, {
    String? semanticLabel,
    String? heroTag,
  }) = MemoryImageSource;

  /// What a screen reader calls this picture.
  final String? semanticLabel;

  /// Shared with the thumbnail that opened the viewer, so the picture
  /// flies rather than cuts.
  final String? heroTag;

  ImageProvider get provider;
}

class NetworkImageSource extends GlobalImageSource {
  const NetworkImageSource(
    this.url, {
    super.semanticLabel,
    super.heroTag,
    this.headers,
  });

  final String url;
  final Map<String, String>? headers;

  @override
  ImageProvider get provider =>
      CachedNetworkImageProvider(url, headers: headers);
}

class AssetImageSource extends GlobalImageSource {
  const AssetImageSource(this.path, {super.semanticLabel, super.heroTag});

  final String path;

  @override
  ImageProvider get provider => AssetImage(path);
}

class FileImageSource extends GlobalImageSource {
  const FileImageSource(this.file, {super.semanticLabel, super.heroTag});

  final File file;

  @override
  ImageProvider get provider => FileImage(file);
}

class ProviderImageSource extends GlobalImageSource {
  const ProviderImageSource(
    this.provider, {
    super.semanticLabel,
    super.heroTag,
  });

  @override
  final ImageProvider provider;
}

class MemoryImageSource extends GlobalImageSource {
  const MemoryImageSource(this.bytes, {super.semanticLabel, super.heroTag});

  final Uint8List bytes;

  @override
  ImageProvider get provider => MemoryImage(bytes);
}

// ---------------------------------------------------------------------------
// GlobalZoomableImage
// ---------------------------------------------------------------------------

/// One zoomable page: pinch, two-finger rotate, double-tap.
///
/// Extracted so the picker's own lightbox — which also shows videos and
/// files, and so cannot simply BE this viewer — still shares the way an
/// image behaves inside it. Two implementations of pinch-to-zoom drifted
/// apart on loading and error states before.
class GlobalZoomableImage extends StatelessWidget {
  const GlobalZoomableImage({
    required this.source,
    super.key,
    this.controller,
    this.scaleStateController,
    this.onTap,
    this.maxScale = ImageDefaults.viewerMaxScale,
  });

  final GlobalImageSource source;

  /// Supply one to drive the view from outside — the picker's rotate
  /// button nudges it.
  final PhotoViewController? controller;

  /// Whether the picture is ZOOMED, for a caller that needs to know.
  ///
  /// A drag-to-dismiss host needs exactly this: at rest the drag is
  /// the host's, and zoomed in it belongs to the picture.
  final PhotoViewScaleStateController? scaleStateController;

  final VoidCallback? onTap;
  final double maxScale;

  @override
  Widget build(BuildContext context) {
    return PhotoView(
      imageProvider: source.provider,
      controller: controller,
      scaleStateController: scaleStateController,
      enableRotation: true,
      minScale: PhotoViewComputedScale.contained,
      maxScale: PhotoViewComputedScale.covered * maxScale,
      backgroundDecoration: const BoxDecoration(color: Colors.transparent),
      heroAttributes: source.heroTag == null
          ? null
          : PhotoViewHeroAttributes(tag: source.heroTag!),
      onTapUp: onTap == null ? null : (_, _, _) => onTap!(),
      loadingBuilder: (_, _) =>
          Center(child: GlobalProgress.loading(type: ProgressType.circular)),
      errorBuilder: (context, error, _) => Center(
        child: GlobalIcon(
          icon: Icons.broken_image_outlined,
          style: IconStyle(
            size: context.iconSizes.xxl,
            color: context.textColors.onPrimary,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// GlobalImageViewer
// ---------------------------------------------------------------------------

/// Full-screen picture viewer: pinch-zoom, swipe between pictures,
/// drag down to dismiss.
///
/// ```dart
/// GlobalImageViewer.open(
///   context,
///   sources: [GlobalImageSource.network(url, semanticLabel: alt)],
/// );
/// ```
///
/// Or, from a thumbnail, `GlobalImage.n(url, lightbox: true)`.
class GlobalImageViewer extends StatefulWidget {
  const GlobalImageViewer({
    required this.sources,
    super.key,
    this.initialIndex = 0,
  });

  final List<GlobalImageSource> sources;
  final int initialIndex;

  /// Pushes the viewer over the current route.
  static Future<void> open(
    BuildContext context, {
    required List<GlobalImageSource> sources,
    int initialIndex = 0,
  }) {
    if (sources.isEmpty) return Future<void>.value();
    return Navigator.of(context, rootNavigator: true).push<void>(
      PageRouteBuilder<void>(
        // Transparent, so the picture the viewer opened FROM is still
        // on screen underneath and a hero has somewhere to fly.
        opaque: false,
        barrierColor: Colors.transparent,
        fullscreenDialog: true,
        transitionDuration: AppDurations.quick,
        pageBuilder: (_, _, _) =>
            GlobalImageViewer(sources: sources, initialIndex: initialIndex),
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  State<GlobalImageViewer> createState() => _GlobalImageViewerState();
}

class _GlobalImageViewerState extends State<GlobalImageViewer> {
  late final PageController _pages = PageController(
    initialPage: widget.initialIndex,
  );

  /// One per page, so the viewer can ask whether THIS picture is
  /// zoomed before it treats a drag as a dismissal.
  late final List<PhotoViewScaleStateController> _scaleStates = List.generate(
    widget.sources.length,
    (_) => PhotoViewScaleStateController(),
  );

  late int _current = widget.initialIndex;

  /// How far the picture has been dragged, and therefore how much
  /// backdrop is left.
  double _drag = 0;
  Offset? _pointerStart;
  bool _dragging = false;

  @override
  void dispose() {
    for (final c in _scaleStates) {
      c.dispose();
    }
    _pages.dispose();
    super.dispose();
  }

  double get _dismissProgress =>
      (_drag.abs() / ImageDefaults.viewerDismissDistance).clamp(0.0, 1.0);

  /// A zoomed picture owns single-finger drags — that is how you move
  /// around inside it — so dismissal only engages at rest.
  bool get _canDismiss =>
      _scaleStates[_current].scaleState == PhotoViewScaleState.initial;

  // Raw pointers, not a `GestureDetector`. PhotoView claims pan in the
  // gesture arena and wins it, being deeper in the tree, so a drag
  // handler wrapped around the gallery never fired at all — the viewer
  // simply could not be dragged away. A `Listener` sees the pointer
  // before the arena does.
  void _onPointerDown(PointerDownEvent e) {
    _pointerStart = e.position;
    _dragging = false;
  }

  void _onPointerMove(PointerMoveEvent e) {
    final start = _pointerStart;
    if (start == null || !_canDismiss) return;
    final delta = e.position - start;

    if (!_dragging) {
      // Only take over once the gesture is clearly VERTICAL, or a swipe
      // between pictures would be stolen on its first pixel.
      if (delta.dy.abs() < ImageDefaults.viewerDragSlop ||
          delta.dy.abs() < delta.dx.abs() * 1.5) {
        return;
      }
      _dragging = true;
    }
    setState(() => _drag = delta.dy);
  }

  void _onPointerUp(PointerUpEvent e) {
    _pointerStart = null;
    if (!_dragging) return;
    _dragging = false;
    if (_dismissProgress >= 1) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _drag = 0);
  }

  @override
  Widget build(BuildContext context) {
    final multi = widget.sources.length > 1;
    final label = widget.sources[_current].semanticLabel;

    return Scaffold(
      backgroundColor: context.overlayColors.scrim.withValues(
        alpha: (1 - _dismissProgress) * ImageDefaults.viewerScrimOpacity,
      ),
      body: Listener(
        onPointerDown: _onPointerDown,
        onPointerMove: _onPointerMove,
        onPointerUp: _onPointerUp,
        child: Stack(
          children: [
            Transform.translate(
              offset: Offset(0, _drag),
              child: PhotoViewGallery.builder(
                pageController: _pages,
                itemCount: widget.sources.length,
                onPageChanged: (i) => setState(() => _current = i),
                backgroundDecoration: const BoxDecoration(
                  color: Colors.transparent,
                ),
                builder: (context, index) {
                  final source = widget.sources[index];
                  return PhotoViewGalleryPageOptions(
                    imageProvider: source.provider,
                    scaleStateController: _scaleStates[index],
                    minScale: PhotoViewComputedScale.contained,
                    maxScale:
                        PhotoViewComputedScale.covered *
                        ImageDefaults.viewerMaxScale,
                    heroAttributes: source.heroTag == null
                        ? null
                        : PhotoViewHeroAttributes(tag: source.heroTag!),
                    onTapUp: (_, _, _) => Navigator.of(context).pop(),
                  );
                },
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.all(context.spacing.sm),
                  child: Row(
                    children: [
                      GlobalIcon(
                        icon: Icons.close_rounded,
                        semanticLabel: CommonStrings.close,
                        onTap: () => Navigator.of(context).pop(),
                        style: IconStyle(
                          color: context.textColors.onPrimary,
                          backgroundColor: context.overlayColors.scrim,
                          backgroundOpacity:
                              ImageDefaults.viewerBarScrimOpacity,
                          containerShape: IconContainerShape.circle,
                          padding: EdgeInsets.all(context.spacing.xs),
                        ),
                      ),
                      const Spacer(),
                      if (multi)
                        Text(
                          '${_current + 1} / ${widget.sources.length}',
                          style: context.textTheme.labelLarge?.copyWith(
                            color: context.textColors.onPrimary,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            if (label != null)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.all(context.spacing.md),
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: context.textColors.onPrimary,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
