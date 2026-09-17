import 'package:flutter/material.dart';

import '../../../core/constants/colors/workshop_family_colors.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/localization/strings/workshop_strings.dart';
import '../../../core/tokens/extensions.dart';
import '../../../data/models/terracotta/core/api_image.dart';
import '../../../data/models/terracotta/workshop/workshop_audience.dart';
import '../../../shared/module/image/global_image.dart';
import '../../_shared/terracotta_cta_style.dart';
import '../../_shared/terracotta_image.dart';

/// A workshop-type card — the coloured band with its illustration well.
///
/// The card is painted in the WORKSHOP's own colour. On the live server
/// that is an admin-set `color` per workshop (two `make_your_piece`
/// workshops came back different), so it is resolved through
/// [WorkshopFamilyColors.resolve] rather than keyed on `type`.
///
/// The illustration well sits at the END, with the text running from
/// the reading start — the whole row is logical, so it mirrors as a
/// unit.
class WorkshopCard extends StatelessWidget {
  const WorkshopCard({
    required this.title,
    required this.description,
    this.audience = WorkshopAudience.mixed,
    this.family = WorkshopFamily.makeYourPiece,
    this.wireColor,
    this.image,
    this.expanded = false,
    this.onTap,
    super.key,
  });

  final String title;
  final String description;

  /// WHO THE SESSION IS FOR. `mixed` — the default, and most of them —
  /// draws nothing: «للجميع» on every card in the list is noise, and
  /// the badge is only worth its space when it excludes somebody.
  final WorkshopAudience audience;
  final WorkshopFamily family;
  final String? wireColor;

  /// The workshop's OWN photograph, when the CMS has one.
  ///
  /// Null falls back to the family's line drawing — which is what
  /// every row used to get, because `image` was null on all of them.
  /// It is not any more (workshop 4 carries one, verified live
  /// 2026-09-15), and a photograph of the actual session says more
  /// than a shared illustration three workshops have in common.
  final ApiImage? image;

  /// Whether this card is the one currently open in the accordion.
  final bool expanded;

  final VoidCallback? onTap;

  /// The design's height for a card whose words fit one line each.
  /// Anything longer grows the row, and the well grows with it.
  static const _minRowHeight = 110.0;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final fam = WorkshopFamilyColors.resolve(
      family: family,
      isDark: context.isDarkMode,
      wireColor: wireColor,
    );

    return ClipRRect(
      // The design's own corner, shared with the panel's inner cards
      // and the CTA below them.
      borderRadius: BorderRadius.circular(kTerracottaCtaRadius),
      // The card's colour has to BE the Material, or the ripple paints
      // underneath it and never shows.
      child: Material(
        color: fam.primary,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(spacing.xs),
            // The well matches the WORDS, however many lines they run
            // to.
            //
            // It used to be a fixed 110 tall beside a column that grows
            // — a two-line title with a two-line description left a
            // band of card colour under the drawing. `IntrinsicHeight`
            // measures the row so `stretch` has a height to stretch
            // TO; in an unbounded column there is otherwise nothing for
            // it to fill.
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: _minRowHeight),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Padding(
                        // Generous on the reading side: the words used to
                        // start hard against the card's edge.
                        padding: EdgeInsetsDirectional.fromSTEB(
                          spacing.md,
                          spacing.md,
                          spacing.sm,
                          spacing.md,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // The chevron rides WITH the title rather than
                            // in a column of its own — given its own it
                            // took a full gutter out of the card's width
                            // and pushed the words into a narrow strip.
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    title,
                                    style: context.textTheme.titleLarge
                                        ?.copyWith(
                                          color: fam.onPrimary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ),
                                AnimatedRotation(
                                  turns: expanded ? 0.5 : 0,
                                  duration: const Duration(milliseconds: 200),
                                  child: Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: fam.onPrimary,
                                  ),
                                ),
                              ],
                            ),
                            if (audience.isRestricted) ...[
                              SizedBox(height: spacing.xs),
                              // ON THE CARD as well as inside, because
                              // the list is where a customer decides
                              // which workshop to open — and nothing
                              // on the server stops them booking one
                              // that is not for them.
                              _AudiencePill(
                                audience: audience,
                                ink: fam.onPrimary,
                              ),
                            ],
                            SizedBox(height: spacing.xs),
                            Text(
                              description,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: context.textTheme.labelSmall?.copyWith(
                                color: fam.onPrimary,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    _Well(tint: fam.onPrimary, family: family, image: image),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The workshop's PHOTOGRAPH, or — when the CMS has none — the
/// translucent panel its family's drawing sits in.
///
/// The illustration is per FAMILY, not per workshop: two workshops can
/// share one — «اصنع كوبك الخاص» and «اصنع وعاءك الخاص» are both
/// `make_your_piece` and got the same vessel. That was every row once,
/// because `image` was null on all of them; it is the FALLBACK now.
class _Well extends StatelessWidget {
  const _Well({required this.tint, required this.family, this.image});

  final Color tint;
  final WorkshopFamily family;
  final ApiImage? image;

  /// The line drawing each family is illustrated with.
  static const _art = <WorkshopFamily, String>{
    WorkshopFamily.makeYourPiece:
        'assets/images/make-your-cup-workshop-illustration.png',
    WorkshopFamily.paintYourPiece:
        'assets/images/color-your-cup-workshop-illustration.png',
    WorkshopFamily.makeYourCandle:
        'assets/images/make-your-wax-workshop-illustration.png',
  };

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(context.radii.xs),
    child: SizedBox(
      // WIDTH only. The height comes from the row: `stretch` hands
      // this a TIGHT height, which would override a `height:` here
      // anyway — so setting one would look like it did something and
      // do nothing.
      width: 101,
      // A PHOTOGRAPH IS NOT LINE WORK. No wash behind it and no
      // recolouring over it — `srcIn` masks a colour by the drawing's
      // own alpha, which on an opaque photograph paints the whole
      // rectangle one flat colour.
      child: image != null
          ? TerracottaImage(image: image, fit: BoxFit.cover)
          : ColoredBox(
              color: tint.withValues(alpha: 0.46),
              child: GlobalImage.a(
                _art[family]!,
                placeholder: const SizedBox.shrink(),
                style: ImageStyle(
                  fit: BoxFit.contain,
                  borderRadius: BorderRadius.zero,
                  // The art ships as BLACK line work, recoloured to the
                  // tint. `srcIn` masks the colour by the drawing's own
                  // alpha, so only the strokes take it. (`srcATop`, the
                  // module's default, lands in the same place for an OPAQUE
                  // tint — this is the exact one, not the only one that
                  // works.)
                  color: tint.withValues(alpha: 0.9),
                  overlayBlendMode: BlendMode.srcIn,
                ),
              ),
            ),
    ),
  );
}

/// «للنساء فقط» on the closed card — in the workshop's own ink, on a
/// wash of it, so it reads as part of the panel rather than a sticker.
class _AudiencePill extends StatelessWidget {
  const _AudiencePill({required this.audience, required this.ink});

  final WorkshopAudience audience;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: ink.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(context.radii.full),
        ),
        child: Padding(
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: spacing.sm,
            vertical: 2,
          ),
          child: Text(
            WorkshopStrings.audience(audience),
            style: context.textTheme.labelSmall?.copyWith(
              color: ink,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
