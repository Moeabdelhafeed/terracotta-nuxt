import 'package:flutter/material.dart';

import '../../image/global_image.dart';

/// A picture in a document that opens full-screen on tap. Used when
/// [MarkdownOptions.imageLightbox] is true.
///
/// It used to carry its own lightbox — a route, a scrim, an `AppBar` and
/// an `InteractiveViewer`, most of this file — standing beside the
/// picker's much larger one. Both go through the image module's viewer
/// now. What is left is the one thing markdown actually knows: that the
/// alt text names the picture.
class MarkdownLightboxImage extends StatelessWidget {
  const MarkdownLightboxImage({
    required this.uri,
    this.alt,
    this.cache = true,
    super.key,
  });

  final Uri uri;
  final String? alt;
  final bool cache;

  @override
  Widget build(BuildContext context) => GlobalImage.n(
    uri.toString(),
    style: const ImageStyle(fit: BoxFit.contain),
    semanticLabel: alt,
    cacheNetwork: cache,
    lightbox: true,
  );
}
