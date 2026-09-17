import 'package:flutter/material.dart';

import '../../core/extensions/theme_colors_extension.dart';
import '../../data/models/terracotta/core/api_image.dart';
import '../../shared/module/image/global_image.dart';

/// Any picture the API sent, drawn the one way.
///
/// Two things every call site was getting wrong on its own, which is
/// why they are here instead:
///
///   * **The BLURHASH.** Every image on this wire carries one —
///     `"LER.x;%L_N%M%Mj[M|ay%Mj[IUay"`, twenty-odd characters that
///     decode to a blurred version of the picture itself. Handed to
///     `GlobalImage` it fills the frame with the right SHAPES and
///     colours while the real thing downloads, instead of a grey
///     rectangle. Not one of the eleven places that drew an `ApiImage`
///     was passing it.
///   * **WHICH url.** `url` is relative to the storage host and 404s;
///     `image_api` is the absolute one. [ApiImage.display] is the
///     model's own rule for picking between them, and half the call
///     sites were reaching past it for `imageApi ?? ''` — which paints
///     nothing at all on a row the CMS has not finished processing.
///
/// A null [image] draws the page's own container colour rather than an
/// empty frame: an image is missing on plenty of live rows, and that is
/// a normal state, not a failure — unless a [placeholder] was given, in
/// which case that is what a missing picture looks like too.
class TerracottaImage extends StatelessWidget {
  const TerracottaImage({
    required this.image,
    this.fit = BoxFit.cover,
    this.backgroundColor,
    this.placeholder,
    super.key,
  });

  final ApiImage? image;

  final BoxFit fit;

  /// Behind a transparent cut-out. Null takes `GlobalImage`'s own.
  final Color? backgroundColor;

  /// Drawn while the picture downloads AND when there is no picture.
  ///
  /// `DynamicAssetImage` passes the BUNDLED drawing here, so a studio
  /// image that has not arrived yet is covered by the app's own copy of
  /// the same illustration rather than by a shimmer. Null keeps
  /// `GlobalImage`'s default, which is the blurhash.
  final Widget? placeholder;

  @override
  Widget build(BuildContext context) {
    final picture = image;
    if (picture == null || picture.display.isEmpty) {
      return placeholder ??
          ColoredBox(color: context.backgroundColors.container);
    }

    return GlobalImage.n(
      picture.display,
      blurHash: picture.blurhash,
      placeholder: placeholder,
      style: ImageStyle(
        fit: fit,
        backgroundColor: backgroundColor,
        // NO radius of its own. Every caller clips from outside, and a
        // second radius inside theirs shows as a double edge.
        borderRadius: BorderRadius.zero,
      ),
    );
  }
}
