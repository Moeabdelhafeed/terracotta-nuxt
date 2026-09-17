import 'package:flutter/material.dart';

import '../../core/extensions/theme_colors_extension.dart';
import '../../core/tokens/extensions.dart';
import '../../shared/module/shimmer/global_shimmer.dart';

/// One placeholder block, SHIMMERING.
///
/// ## The bug this exists to end
///
/// Every skeleton in `lib/features` built the same thing by hand:
///
/// ```dart
/// final box = DecoratedBox(decoration: BoxDecoration(...));
/// return GlobalSkeleton(loading: true, skeleton: box, child: box);
/// ```
///
/// [GlobalSkeleton] does not shimmer. It is an `AnimatedCrossFade`
/// between a skeleton the CALLER supplies and the real content — and
/// handed the same box twice with `loading` pinned to `true`, it
/// cross-faded a widget into itself and drew a static grey rectangle.
/// Its own factories (`.listTile`, `.card`) reach for [GlobalShimmer]
/// to build their placeholders; these eleven hand-rolled ones never
/// did, so **nothing in the app has ever shimmered** — on any screen,
/// at any speed. Every one of them carried the comment "one grey
/// block, shimmering".
///
/// ## Why it is a block and not a wrapper
///
/// [GlobalShimmer] in wrap mode paints its OWN surface behind whatever
/// it is given, so wrapping an already-coloured box stacks two. Here
/// the shimmer IS the block: it takes the colour and the corner and
/// sweeps them itself.
///
/// The sweep follows the reading direction and stops under
/// `disableAnimations`, where the block still draws — the shape of
/// what is coming is the part that carries meaning, and the motion is
/// the part that does not.
class SkeletonBlock extends StatelessWidget {
  const SkeletonBlock({this.height, this.radius, this.color, super.key});

  /// Null takes whatever the parent gives it — most callers put these
  /// inside a `SizedBox` of the real row's height.
  final double? height;

  /// Null takes the house `md`, the radius a card wears.
  final double? radius;

  /// Null takes the page's placeholder grey. Named only where a
  /// placeholder sits on a coloured panel — the workshop accordion's
  /// wash — and the house grey would read as a hole in it.
  final Color? color;

  @override
  Widget build(BuildContext context) => GlobalShimmer(
    height: height,
    // The page's own placeholder grey, not the shimmer module's
    // default surface — these sit ON a page, and a white block on a
    // white page is an empty screen with a sheen moving over it.
    containerColor: color ?? context.backgroundColors.container,
    borderRadius: BorderRadius.circular(radius ?? context.radii.md),
    // The block has no content. Its size is the parent's, or [height].
    child: const SizedBox(width: double.infinity),
  );
}
