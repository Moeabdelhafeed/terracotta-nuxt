import 'package:flutter/material.dart';

import '../../../core/extensions/theme_colors_extension.dart';

/// The success disc with its halo — a solid check on a mint circle
/// inside a 17%-alpha ring, drawn on every success screen in the file
/// (account created, booking confirmed, gift purchased).
///
/// Not directional: a check mark reads the same in both locales, so
/// unlike the auth arc this is deliberately NOT flipped. Neither is the
/// gift box the purchase frame puts there instead.
///
/// **Contrast:** white on `#06CD90` is 2.07:1, which fails WCAG. It is
/// shipped as the design draws it — see `docs/contrast-report.md` — but
/// the glyph is a large graphic rather than text, which is the only
/// reason that is defensible here. Do not reuse this pairing for a
/// label.
class SuccessMark extends StatelessWidget {
  const SuccessMark({this.size = 104, this.art, super.key});

  final double size;

  /// What the disc carries INSTEAD of the check.
  ///
  /// Null on every frame but one: the app's celebrations all say
  /// "done", so a check is the right mark for them. The gift frame says
  /// WHAT was done, because the thing still left to do — send the link
  /// — only makes sense beside it, and it says so with the studio's own
  /// glyph rather than a Material lookalike.
  final Widget? art;

  @override
  Widget build(BuildContext context) {
    final success = context.statusColors.success;
    return SizedBox.square(
      dimension: size * 1.33,
      child: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: success.withValues(alpha: 0.17),
          ),
          child: Padding(
            padding: EdgeInsets.all(size * 0.16),
            child: DecoratedBox(
              decoration: BoxDecoration(shape: BoxShape.circle, color: success),
              child: SizedBox.square(
                dimension: size,
                child: Center(
                  child:
                      art ??
                      Icon(
                        Icons.check_rounded,
                        size: size * 0.55,
                        color: context.textColors.onPrimary,
                      ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
