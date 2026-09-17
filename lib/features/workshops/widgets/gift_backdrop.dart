import 'package:flutter/material.dart';

import '../../../shared/module/image/global_image.dart';

/// The drawn loop behind the gift glyph.
///
/// Its own widget because its GEOMETRY is the whole of it, and geometry
/// is the thing that went wrong twice: the art is a rounded-square loop
/// with a hollow middle, so scaling it up and centre-cropping showed
/// the hollow and the tile came out a flat coral. Separated out, it can
/// be rasterised on its own in a test — see `gift_backdrop_test` — with
/// no text in the frame and therefore no font to load.
class GiftBackdrop extends StatelessWidget {
  const GiftBackdrop({
    required this.tint,
    this.scale = 1.3,
    this.fit = BoxFit.contain,
    super.key,
  });

  /// The colour the line work is recoloured to. Its ALPHA carries the
  /// contrast: the strokes are hairline whatever the loop is scaled to,
  /// so at the 0.35 this started on they were invisible on a phone.
  final Color tint;

  /// How the loop meets its box.
  ///
  /// This and [scale] pull AGAINST each other, which is why both are
  /// exposed and why neither has an obviously right value. A bigger
  /// box crops harder, so on a 96 × 44 chip `cover` lays down 288 lit
  /// pixels at scale 1.0 and only 39 at 1.3 — worse than `contain`
  /// there, better here. Measured, not reasoned; `gift_backdrop_test`
  /// holds the comparison.
  final BoxFit fit;

  static const asset = 'assets/images/card-background-illustration.png';

  /// Larger than the tile, and the SAME on both axes.
  ///
  /// Stretching it tall did put strokes on the tile, but it distorted
  /// the drawing — the loop read as an oval. Scaled evenly it keeps its
  /// own shape and still bleeds past all four edges.
  ///
  /// Scaling UP is not the lever it looks like. On a short tile the
  /// visible window crops the loop's hollow middle, so more scale can
  /// mean less drawing: `contain` at 1.8 lays down 251 lit pixels and
  /// at 2.6 only 157.
  final double scale;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    // A texture, not a picture anyone is meant to look at or touch.
    child: FractionallySizedBox(
      widthFactor: scale,
      heightFactor: scale,
      child: GlobalImage.a(
        asset,
        placeholder: const SizedBox.shrink(),
        style: ImageStyle(
          fit: fit,
          borderRadius: BorderRadius.zero,
          // The art ships as BLACK line work, recoloured to the tint.
          // `srcIn` masks the colour by the drawing's own alpha, so
          // only the strokes take it and the transparent ground stays
          // transparent. (`srcATop`, the module's default, lands in the
          // same place for an OPAQUE tint — this is the exact one, not
          // the only one that works.)
          color: tint,
          overlayBlendMode: BlendMode.srcIn,
        ),
      ),
    ),
  );
}
