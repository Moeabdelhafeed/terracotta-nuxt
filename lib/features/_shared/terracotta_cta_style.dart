import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/extensions/theme_colors_extension.dart';
import '../../shared/module/buttons/button_state_style.dart';

/// The design's primary call to action, as a style for
/// `GlobalFilledButton` — the intro pages and every `auth` frame draw
/// the same brown bar, so it is defined once here rather than per
/// screen.
///
/// Design: 52 tall, corner radius 11, label 20.14 on the brand, with a
/// thin arrow on the END side.
///
/// ## The label's colour is NOT set here
///
/// It used to be `Colors.white`, which is what the design draws — on a
/// `#81341A` bar, where white measures 8.9:1. In DARK the bar is the
/// lifted brand `#E0703F`, a light ground, and white on it is 3.2:1.
/// The app's primary call to action was the least legible thing on a
/// dark screen.
///
/// Leaving `textStyle.color` null lets `GlobalFilledButton` fall
/// through to `context.textColors.onPrimary`, which is white in light
/// and the near-black ink in dark — the one value that already knows
/// which way round the brand is. The same rule is why
/// [TerracottaCtaArrow] resolves its own colour rather than taking a
/// constant.
ButtonStateStyle terracottaCtaStyle({bool showArrow = true}) =>
    ButtonStateStyle(
      height: kTerracottaCtaHeight,
      borderRadius: BorderRadius.circular(kTerracottaCtaRadius),
      // No side padding of its own. The module's default is a 16pt
      // horizontal inset, which the pinned arrow was then measured from
      // — so the 12 below was really 28 off the bar's edge. The bar is
      // full-width and its content is positioned, not packed, so it has
      // nothing to gain from an inner gutter.
      padding: EdgeInsets.zero,
      // NO COLOUR — see the note above. The module resolves it from
      // the theme's `onPrimary`, which flips with the brand.
      textStyle: const TextStyle(fontSize: kTerracottaCtaLabelSize),
      // TRAILING, not leading: the design puts the arrow on the far side
      // from where reading starts — the left in Arabic, because left is
      // forward there. The trailing slot is the logical end, so it lands
      // on the correct side in both locales without a branch.
      trailing: showArrow ? const TerracottaCtaArrow() : null,
      // Pinned to the edge with the label centred in the whole bar, as
      // the design draws it. In the module's default centred row the
      // label sits off-centre by half the arrow, and moves again between
      // "Next" and "Let's start".
      slotsAtEdges: true,
      slotEdgeInset: kTerracottaCtaArrowInset,
    );

const double kTerracottaCtaHeight = 52;
const double kTerracottaCtaRadius = 11;
const double kTerracottaCtaLabelSize = 20.14;

/// Inset from the bar's own edge to the arrow's BOX.
///
/// Measured from the EDGE, now that the bar carries no inner padding.
/// The design puts 20 to the box, but the glyph fills about two thirds
/// of its 24pt square, so 20 renders as more clearance than the drawing
/// shows — this sits against what the eye reads as the arrow.
const double kTerracottaCtaArrowInset = 12;

/// The forward arrow that rides in the CTA's trailing slot.
///
/// The asset is an arrow pointing UP; a quarter turn aims it at the end
/// edge — clockwise for English, anticlockwise for Arabic. Rotating it
/// per direction rather than relying on automatic mirroring is what
/// keeps it pointing FORWARD in both, since a quarter turn is not a
/// mirror.
class TerracottaCtaArrow extends StatelessWidget {
  const TerracottaCtaArrow({this.color, super.key});

  /// Null takes the theme's `onPrimary` — white on the light theme's
  /// brown bar, the near-black ink on dark's lifted one. It was a
  /// `Colors.white` default, which pointed a white arrow at a light
  /// orange ground.
  final Color? color;

  static const double _box = 24;
  static const String _asset = 'assets/icons/solar_arrow_up_linear.svg';

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final ink = color ?? context.textColors.onPrimary;
    return Transform.rotate(
      angle: isRtl ? -math.pi / 2 : math.pi / 2,
      child: SvgPicture.asset(
        _asset,
        width: _box,
        height: _box,
        colorFilter: ColorFilter.mode(ink, BlendMode.srcIn),
      ),
    );
  }
}
