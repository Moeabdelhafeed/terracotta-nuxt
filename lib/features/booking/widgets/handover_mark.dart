import 'package:flutter/material.dart';

import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/tokens/extensions.dart';
import '../../../shared/module/image/global_image.dart';

/// The head of «مسلمة» — a tick, not a drawing.
///
/// Every other frame draws the thing that is happening: a kiln, a van,
/// a calendar. The end of the story is not a thing, it is a FACT, and
/// the design draws it as one — a filled tick on a soft halo, with the
/// studio's tools scattered either side of it.
///
/// It also has to serve BOTH legs. A customer who drove to the studio
/// and one who waited at home end in the same place, and a picture of
/// a van would be wrong for half of them.
class HandoverMark extends StatelessWidget {
  const HandoverMark({
    required this.startArt,
    required this.endArt,
    this.size = 240,
    super.key,
  });

  /// The flourish either side of the mark — the brush and tube on one
  /// side, the glaze jar on the other. TWO drawings, not one mirrored:
  /// the studio ships both, and a mirrored copy read as the same
  /// picture twice.
  final String startArt;
  final String endArt;

  /// The band the whole thing sits in.
  final double size;

  /// The tick's own disc, and the halo behind it.
  static const _disc = 116.0;
  static const _halo = 176.0;

  @override
  Widget build(BuildContext context) {
    final green = context.statusColors.success;

    return SizedBox(
      height: size,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // The tools, scattered at the top corners as drawn.
          PositionedDirectional(
            top: 0,
            start: context.spacing.sm,
            child: _Art(art: startArt, size: size * 0.46),
          ),
          PositionedDirectional(
            top: 0,
            end: context.spacing.sm,
            child: _Art(art: endArt, size: size * 0.46),
          ),
          // A soft disc under the mark, so it reads as lit rather than
          // stamped on.
          Container(
            width: _halo,
            height: _halo,
            decoration: BoxDecoration(
              color: green.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
          ),
          Container(
            width: _disc,
            height: _disc,
            decoration: BoxDecoration(color: green, shape: BoxShape.circle),
            child: Icon(
              // NOT mirrored in RTL. A tick means the same thing in
              // every language, and flipping it makes it a mark nobody
              // recognises.
              Icons.check_rounded,
              // Bigger than the icon ramp goes — this is the whole
              // point of the frame, not a glyph in a row.
              size: _disc * 0.56,
              color: context.textColors.onPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Art extends StatelessWidget {
  const _Art({required this.art, required this.size});

  final String art;
  final double size;

  @override
  Widget build(BuildContext context) {
    final image = SizedBox(
      height: size,
      child: GlobalImage.a(
        art,
        placeholder: const SizedBox.shrink(),
        style: const ImageStyle(
          fit: BoxFit.contain,
          borderRadius: BorderRadius.zero,
        ),
      ),
    );

    return IgnorePointer(child: image);
  }
}
