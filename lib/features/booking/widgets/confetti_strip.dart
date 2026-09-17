import 'package:flutter/material.dart';

import '../../../shared/module/image/global_image.dart';

/// The party pattern, down one edge.
///
/// SCALED to the strip, not tiled. Tiling keeps the artwork at its own
/// 149 × 149 and never resamples it, which is sharper — and it reads as
/// wallpaper: the same handful of shapes over and over down the edge.
/// One scaled copy is softer and looks like scattered confetti, which
/// is what it is meant to be.
///
/// Pushed OUTWARDS past its own edge: centred in its strip the pattern
/// crowds whatever it frames, and half of it hanging off the side reads
/// as the surface being cut out of a wider sheet of confetti, which is
/// what the design draws.
class ConfettiStrip extends StatelessWidget {
  const ConfettiStrip({
    required this.edge,
    this.widthFactor = 0.34,
    this.overhang = 0.45,
    super.key,
  });

  /// Which side it runs down. Directional, so the pair mirrors together
  /// with the reading direction.
  final AlignmentDirectional edge;

  /// How much of the parent's width the strip covers.
  final double widthFactor;

  /// How far past its own edge it is pushed, as a fraction of the
  /// strip's width.
  final double overhang;

  static const asset = 'assets/images/party-pattern.png';

  @override
  Widget build(BuildContext context) {
    final away = edge == AlignmentDirectional.centerStart
        ? -overhang
        : overhang;

    return Positioned.fill(
      child: IgnorePointer(
        child: Align(
          alignment: edge,
          child: FractionallySizedBox(
            widthFactor: widthFactor,
            heightFactor: 1,
            alignment: edge,
            child: FractionalTranslation(
              translation: Directionality.of(context) == TextDirection.rtl
                  ? Offset(-away, 0)
                  : Offset(away, 0),
              child: GlobalImage.a(
                asset,
                placeholder: const SizedBox.shrink(),
                style: const ImageStyle(
                  fit: BoxFit.cover,
                  // The surface does its own clipping; a second radius
                  // inside it shows as a double edge.
                  borderRadius: BorderRadius.zero,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
