import 'package:flutter/material.dart';

import '../../../core/tokens/extensions.dart';
import '../../../shared/module/image/global_image.dart';

/// The two sparkles that sit either side of a booking's heading.
///
/// One HIGH on one side and one LOW on the other, never level: two
/// stars at the same height read as a border, and the design's are
/// scattered. [leadHigh] swaps which side is which, so consecutive
/// frames of the same booking do not look like the same page.
class StageStars extends StatelessWidget {
  const StageStars({required this.leadHigh, required this.child, super.key});

  /// True puts the starting side's star at the top.
  final bool leadHigh;

  /// The heading block they frame.
  final Widget child;

  static const asset = 'assets/images/star-illustration.png';
  static const _size = 22.0;

  /// How far in from the page's edge each star sits. Small: they belong
  /// to the margin, not to the text.
  static const _inset = 4.0;

  @override
  Widget build(BuildContext context) {
    final drop = context.spacing.lg;

    return Stack(
      alignment: Alignment.center,
      children: [
        // The words decide the height; the stars hang off them.
        Padding(
          padding: EdgeInsets.symmetric(horizontal: _size + context.spacing.md),
          child: child,
        ),
        PositionedDirectional(
          start: _inset,
          top: leadHigh ? 0 : null,
          bottom: leadHigh ? null : 0,
          child: const _Star(),
        ),
        PositionedDirectional(
          end: _inset,
          top: leadHigh ? null : 0,
          bottom: leadHigh ? 0 : null,
          // Nudged so the pair never lands level even when the block is
          // only one line tall.
          child: Padding(
            padding: EdgeInsets.only(top: leadHigh ? 0 : drop / 3),
            child: const _Star(),
          ),
        ),
      ],
    );
  }
}

class _Star extends StatelessWidget {
  const _Star();

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: SizedBox(
      width: StageStars._size,
      height: StageStars._size,
      child: GlobalImage.a(
        StageStars.asset,
        placeholder: const SizedBox.shrink(),
        style: const ImageStyle(
          fit: BoxFit.contain,
          borderRadius: BorderRadius.zero,
        ),
      ),
    ),
  );
}
