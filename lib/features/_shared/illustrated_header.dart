import 'package:flutter/material.dart';

import '../../core/extensions/context_extensions.dart';
import '../../core/extensions/theme_colors_extension.dart';
import '../../core/tokens/extensions.dart';
import '../../shared/module/in_page_hero/global_in_page_hero.dart';
import '../shell/widgets/terracotta_app_bar.dart';
import 'dynamic_asset_image.dart';
import 'screen_entrance.dart';

/// One drawing in an [IllustratedHeader], and where it sits.
///
/// Coordinates are PHYSICAL and read as the ARABIC composition, because
/// the whole artwork layer is mirrored for English in one transform —
/// see [IllustratedHeader]. So `right` is the START edge and `left` is
/// the END edge, and the LTR build gets them the other way for free.
@immutable
class HeaderArt {
  const HeaderArt({
    required this.asset,
    required this.width,
    required this.height,
    this.top,
    this.bottom,
    this.left,
    this.right,
  });

  final String asset;
  final double width;
  final double height;
  final double? top;
  final double? bottom;
  final double? left;
  final double? right;

  /// Which corner it comes IN from, as a fraction of its own size.
  ///
  /// Read off the anchors, not typed per drawing: a camera pinned to
  /// the top END arrives from the top end, a pot pinned to the bottom
  /// START from the bottom start. That is the composition saying where
  /// each object belongs, and it is already written down — a second
  /// hand-kept list of directions would only be a way for the two to
  /// disagree.
  ///
  /// The coordinates are PHYSICAL-as-Arabic and the whole layer is
  /// mirrored for English, so this needs no side of its own: an offset
  /// toward `right` here travels toward the reading START in both
  /// builds.
  ///
  /// A piece anchored on neither axis has no corner to come from, and
  /// settles downward instead of jumping to a side it was not drawn
  /// at.
  Offset get driftFrom {
    final dx = right != null
        ? _drift
        : left != null
        ? -_drift
        : 0.0;
    final dy = top != null
        ? -_drift
        : bottom != null
        ? _drift
        : 0.0;
    if (dx == 0 && dy == 0) return const Offset(0, -_drift / 2);
    return Offset(dx, dy);
  }

  /// How far, as a fraction of the drawing's own size. Most of its own
  /// width: these bleed past the frame already, so a shorter travel
  /// reads as a twitch rather than as the object being placed.
  static const _drift = 0.8;
}

/// The drawn top of a browse tab: line art bleeding off both edges,
/// with the heading and its line centred over it.
///
/// The gallery and the workshops tab are the same picture with
/// different objects in it, so they are the same widget. The artwork is
/// POSITIONED rather than laid out in a row — the design has it running
/// past both edges and overlapping the words, which no flex arrangement
/// expresses.
class IllustratedHeader extends StatelessWidget {
  const IllustratedHeader({
    required this.title,
    required this.subtitle,
    required this.art,
    this.height = 300,
    this.topRoom = 0,
    this.wordsAt = Alignment.center,
    this.mirrorKey,
    this.entrance = false,
    this.titleMorph,
    super.key,
  });

  final String title;
  final String subtitle;
  final List<HeaderArt> art;

  /// Taller than the drawings need: the design gives the heading room
  /// to breathe between them rather than sitting tight against them.
  final double height;

  /// EMPTY SPACE ABOVE the composition, on top of [height].
  ///
  /// The browse tabs draw this behind a transparent, floating app bar —
  /// `extendBodyBehindAppBar`, so the header starts at the top edge of
  /// the SCREEN. That is what lets the line art run under the status
  /// bar, and it is also what put the topmost drawings underneath the
  /// bar's own buttons, where a camera read as a smudge behind the
  /// cart glyph.
  ///
  /// Pass the bar's height (`MediaQuery.paddingOf(context).top +
  /// kToolbarHeight`) to drop the whole composition clear of it. Zero
  /// keeps the original framing for a header with nothing up there to
  /// collide.
  final double topRoom;

  /// Where the heading sits in the box.
  ///
  /// Centred by default, which is right when there is a scene drawn
  /// around it. A header with only a star either side has nothing above
  /// the words to balance them against, and centring then reads as a
  /// gap the page did not ask for — those callers pass
  /// `Alignment.topCenter`.
  final Alignment wordsAt;

  /// Names the mirror layer so a test can ask whether it flipped.
  final Key? mirrorKey;

  /// Whether the drawings and the words ARRIVE rather than being there.
  ///
  /// The three tabs that wear this — the shop, the workshops and the
  /// gallery — each open on it, so it is the first thing anyone sees on
  /// the page. The artwork settles from slightly small
  /// ([EntranceMotion.art]: a rise measured as a fraction of a 200pt
  /// drawing's own height is a lurch), and the title and the line under
  /// it follow it up. Once per launch — see [TabEntrance].
  final bool entrance;

  /// Flies this heading INTO the app bar as the page collapses.
  ///
  /// Endpoint 0 is here, endpoint 1 is the bar's own title. Without it
  /// the two are unrelated events — the reader's heading scrolls away
  /// and a different one appears above it. See [TerracottaAppBar].
  final InPageHeroController? titleMorph;

  /// A drawing, sized from OUTSIDE so the decode keeps its own aspect —
  /// an explicit width AND height become `cacheWidth`/`cacheHeight`,
  /// which squash anything that is not square.
  static Widget _draw(HeaderArt a) => SizedBox(
    width: a.width,
    height: a.height,
    // THE STUDIO'S, when they have registered one — `forAsset` looks
    // the bundled path up in [dynamicAssetSlots] and falls straight
    // through to the plain asset when it is not the studio's to
    // change. See [DynamicAssetImage].
    child: DynamicAssetImage.forAsset(a.asset),
  );

  /// One element of the header's arrival, or the element untouched.
  Widget _entrance(int step, {required Widget child}) => entrance
      ? ScreenEntrance(
          step: step,
          arrival: EntranceArrival.mount,
          child: child,
        )
      : child;

  /// The heading as the SOURCE of a flight into the bar, when the page
  /// asked for one.
  ///
  /// `maintainSpace`, because this heading is centred in a band of
  /// artwork: letting its box collapse when it flies away would pull
  /// the line under it up through the drawings.
  Widget _morph(Widget heading) => titleMorph == null
      ? heading
      : InPageHero(
          tag: TerracottaAppBar.titleMorphTag,
          controller: titleMorph!,
          maintainSpace: true,
          child: heading,
        );

  /// One DRAWING, in from the corner it is anchored to.
  Widget _drift(int step, HeaderArt a, {required Widget child}) => entrance
      ? ScreenEntrance.drift(
          step: step,
          arrival: EntranceArrival.mount,
          from: a.driftFrom,
          child: child,
        )
      : child;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    // MIRRORED for English, as drawn for Arabic.
    //
    // The design is Arabic-first, so the composition as drawn belongs to
    // the RTL build and the LTR build gets its reflection — the opposite
    // of `GlobalImage.mirrorInRtl`, which is why that flag is no use
    // here. Same idiom as `AuthScaffold`'s arc.
    //
    // The flip wraps the artwork LAYER, not each drawing: flipping the
    // pieces without swapping their sides would leave a brush pointing
    // off the edge it used to point away from. One transform over the
    // whole Stack moves the positions and the pictures together, which
    // is what a mirror is.
    //
    // The words sit OUTSIDE it — text read backwards is not a mirror,
    // it is a bug.
    final flip = Directionality.of(context) == TextDirection.ltr;

    return Padding(
      padding: EdgeInsets.only(top: topRoom),
      child: SizedBox(
        height: height,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              // Keyed: something else in the tree flips on the same
              // axis, so a test looking for "a Transform with x-scale
              // −1" would find the wrong one and pass in the wrong
              // direction.
              child: Transform.flip(
                key: mirrorKey,
                flipX: flip,
                child: Stack(
                  // The drawings run past the frame on both sides, as
                  // drawn.
                  clipBehavior: Clip.none,
                  children: [
                    // INSIDE the mirror, one entrance each. Above it they
                    // were one block settling together, which is a header
                    // appearing rather than a picture being laid out —
                    // and an offset applied above the flip would travel
                    // the wrong way in English.
                    for (final (i, a) in art.indexed)
                      Positioned(
                        top: a.top,
                        bottom: a.bottom,
                        left: a.left,
                        right: a.right,
                        child: _drift(i, a, child: _draw(a)),
                      ),
                  ],
                ),
              ),
            ),

            // The words, over all of it.
            Align(
              alignment: wordsAt,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: spacing.xl).copyWith(
                  top: spacing.xxl,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _entrance(
                      art.length,
                      child: _morph(
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: context.textTheme.titleLarge?.copyWith(
                            color: context.textColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: spacing.sm),
                    _entrance(
                      art.length + 1,
                      child: Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: context.textColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
