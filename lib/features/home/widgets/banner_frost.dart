import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

/// The blurred panel the hero banner's words sit on.
///
/// **Frost, not a wash.** What this replaced was a gradient of the
/// app's own `scaffoldBackground` — which in the light theme is PURE
/// WHITE — laid over warm terracotta photography. It read as fog: it
/// bleached the picture, its edge was visible, and it disagreed with
/// the black gradient at the foot that the indicators need. This blurs
/// the artwork instead of hiding it, so the photograph is still doing
/// its job behind the copy.
///
/// **The tint is FIXED in both themes**, like that foot gradient. A
/// frosted panel over a photograph is not a themed surface: what sits
/// behind it is whatever the studio uploaded, so ink chosen to suit the
/// app's own background would be unreadable half the time.
///
/// **The alpha is measured, not chosen.** Against a blown-out WHITE
/// photograph — the worst case, since anything darker only helps — the
/// panel resolves to about `rgb(116, 94, 91)`, which carries [ink] at
/// 5.99:1 and [mutedInk] at about 5.5:1. Both clear WCAG AA for body
/// text. `banner_frost_test.dart` holds those numbers to it.
class BannerFrost extends StatelessWidget {
  const BannerFrost({super.key});

  /// Warm near-black rather than plain black: the studio's own darkest
  /// brown, so the panel belongs to the brand rather than reading as a
  /// grey card dropped on the photograph.
  static const tint = Color(0xFF290802);

  /// The floor that keeps the copy legible over the brightest artwork
  /// the CMS might serve. Below ~0.6 the headline stops clearing AA on
  /// a bright photograph.
  static const alpha = 0.65;

  /// The headline.
  static const ink = Color(0xFFFFFFFF);

  /// The line under it — the palette's paper, so it sits BACK from the
  /// headline without dropping to a grey that stops clearing AA.
  ///
  /// This is where the brand coral used to be, and it could not stay:
  /// `#FC8B8B` is a mid-tone, and over a bright photograph it measures
  /// **3.15:1 even at a 0.70 tint**. Clearing AA would have needed
  /// ~0.90 — a flat dark panel with a rumour of blur behind it. The
  /// coral moved to the CTA pill instead, where the background is ours
  /// and its contrast does not depend on what was uploaded.
  static const mutedInk = Color(0xFFF2E9E4);

  /// Enough to lose the detail behind the words without smearing the
  /// picture into one colour — at which point the frost may as well
  /// have been the flat panel it replaced.
  static const blur = 18.0;

  /// How much of the slide the panel covers.
  ///
  /// WIDER than the words' half, because the panel has to have room to
  /// fade out. Drawn at exactly the width of the text it read as a
  /// rectangle pasted over the photograph — a razor edge straight down
  /// the middle, which is what a scrim must never look like.
  static const widthFactor = 0.62;

  /// Where the fade begins, as a fraction of the panel's own width
  /// measured from the reading end.
  ///
  /// Everything outside this is at full [alpha] — and the words live
  /// there, which is what keeps the measured contrast honest. The rest
  /// ramps to nothing.
  static const solidUntil = 0.72;

  /// What the panel actually resolves to over [behind].
  ///
  /// The test seam: contrast is a property of the COMPOSITE, not of
  /// [tint], and the composite is what a reader sees.
  static Color resolvedOver(Color behind) =>
      Color.alphaBlend(tint.withValues(alpha: alpha), behind);

  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.centerEnd,
    child: FractionallySizedBox(
      widthFactor: widthFactor,
      // FULL height: a column of frost, not a card floating in the
      // middle of the artwork.
      heightFactor: 1,
      // FEATHERED, and the mask takes the BLUR with it — fading only
      // the tint would have left the blur's own edge as a visible seam
      // down the picture, which is the same fault in a quieter form.
      child: ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (rect) => const LinearGradient(
          begin: AlignmentDirectional.centerEnd,
          end: AlignmentDirectional.centerStart,
          // Opaque, opaque, gone. The first two stops are the panel
          // the words sit on; the ramp between the second and the
          // third is the only part that is not at full strength.
          colors: [
            Color(0xFFFFFFFF),
            Color(0xFFFFFFFF),
            Color(0x00FFFFFF),
          ],
          stops: [0, solidUntil, 1],
        ).createShader(rect, textDirection: Directionality.of(context)),
        child: ClipRect(
          // REQUIRED. `BackdropFilter` samples everything painted
          // beneath it in the layer, and without a clip it blurs the
          // whole slide rather than the part it covers.
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
            child: ColoredBox(color: tint.withValues(alpha: alpha)),
          ),
        ),
      ),
    ),
  );
}
