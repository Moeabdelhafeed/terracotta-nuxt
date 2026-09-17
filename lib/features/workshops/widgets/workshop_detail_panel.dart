import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_html/flutter_html.dart';

import '../../../core/constants/colors/workshop_family_colors.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/number_formatter.dart';
import '../../../core/localization/strings/booking_strings.dart';
import '../../../core/localization/strings/home_strings.dart';
import '../../../core/localization/strings/workshop_strings.dart';
import '../../../core/tokens/extensions.dart';
import '../../../data/models/terracotta/core/api_image.dart';
import '../../../data/models/terracotta/workshop/workshop.dart';
import '../../../data/models/terracotta/workshop/workshop_audience.dart';
import '../../../shared/module/buttons/global_filled_button.dart';
import '../../../shared/module/buttons/global_outlined_button.dart';
import '../../_shared/skeleton_block.dart';
import '../../_shared/terracotta_cta_style.dart';
import '../../_shared/terracotta_widgets.dart';
import '../cubits/workshop_detail_cubit.dart';
import '../cubits/workshop_detail_state.dart';
import 'workshop_gallery_strip.dart';

/// The detail that unfolds under an expanded workshop card.
///
/// Photographs, the three fact chips, the description, the location
/// button and the book CTA — all tinted with the workshop's OWN hue,
/// which is admin-set per workshop and not a property of its family.
///
/// `GET /api/workshops/{workshop}` fills it, and that is a second
/// request: the catalogue row carries no gallery, no long description
/// and no categories. Note the endpoint returns `has_delivery` as a
/// BOOLEAN and no delivery fee — the price depends on the customer's
/// city, so it cannot be quoted here.
class WorkshopDetailPanel extends StatefulWidget {
  const WorkshopDetailPanel({
    required this.workshop,
    required this.family,
    this.wireColor,
    this.cubit,
    this.onBook,
    this.onLocation,
    super.key,
  });

  /// The catalogue row. It already carries the price, the seats and the
  /// duration, so those are drawn from it immediately — no waiting, no
  /// placeholders for facts the app already has.
  final Workshop workshop;

  final WorkshopFamily family;

  /// The `color` field straight off the workshop payload.
  final String? wireColor;

  /// The detail request, when one is needed at all.
  ///
  /// Owned by the PAGE so it survives the card being collapsed and
  /// opened again — a cubit made here died with the panel and asked the
  /// server the same question every time. Null when the row already has
  /// everything, and in tests that supply their own.
  final WorkshopDetailCubit? cubit;

  final VoidCallback? onBook;
  final VoidCallback? onLocation;

  @override
  State<WorkshopDetailPanel> createState() => _WorkshopDetailPanelState();
}

class _WorkshopDetailPanelState extends State<WorkshopDetailPanel> {
  /// Matches the accordion's own cross-fade, so the open and the
  /// settle read as one gesture.
  static const _settleDuration = Duration(milliseconds: 220);

  /// The description is the ONE thing the catalogue row may not carry.
  /// When it does, this panel needs no request at all.
  String get _ownDescription => widget.workshop.longDescription?.trim() ?? '';

  @override
  void initState() {
    super.initState();
    // Only when the row cannot answer. Asking anyway would have made
    // the row's own description free of charge in appearance only.
    //
    // Idempotent, so it does not matter that the page also made this
    // cubit — and it means a cubit handed in by a test is asked, which
    // is the thing that silently stopped when the creation moved out
    // of here.
    if (_ownDescription.isEmpty) unawaited(widget.cubit?.load());
  }

  @override
  Widget build(BuildContext context) {
    final fam = WorkshopFamilyColors.resolve(
      family: widget.family,
      isDark: context.isDarkMode,
      // The CMS colour wins, and `resolve` derives the 9% container
      // wash and a label colour from its LUMINANCE — so a pale hue
      // gets dark ink rather than white on white.
      wireColor: widget.wireColor,
    );

    final ownDescription = _ownDescription;
    final cubit = widget.cubit;

    // NO CUBIT, nothing to ask with — the fallback, and the only
    // branch that can still show an empty gallery.
    if (cubit == null) {
      return _body(context, fam: fam, html: ownDescription, gallery: const []);
    }

    // THE GALLERY LIVES ONLY ON THE DETAIL ENDPOINT.
    //
    // This used to skip the fetch entirely when the list row already
    // carried a description — and skipped the photographs with it. The
    // comment said no workshop had any, which was true when it was
    // written; the studio has since uploaded them, and probing
    // workshop 4 on 2026-09-10 returned three. A row's own description
    // is still used while the request is in flight, so nothing waits
    // on it.
    return BlocBuilder<WorkshopDetailCubit, WorkshopDetailState>(
      bloc: cubit,
      builder: (context, state) => switch (state) {
        WorkshopDetailLoaded(:final workshop) => _body(
          context,
          fam: fam,
          // The detail's own words, or the row's when it has none —
          // which is what stops a null `long_description` fetching
          // the same null again.
          html: workshop.longDescription?.trim().isNotEmpty ?? false
              ? workshop.longDescription!.trim()
              : ownDescription,
          gallery: workshop.gallery,
        ),
        // Waiting: show what the ROW already knows rather than a
        // blank panel.
        _ => _body(
          context,
          fam: fam,
          html: ownDescription,
          gallery: const [],
          busy: ownDescription.isEmpty,
        ),
      },
    );
  }

  Widget _body(
    BuildContext context, {
    required WorkshopFamilyColors fam,
    required String html,
    required List<ApiImage> gallery,
    bool busy = false,
  }) {
    final spacing = context.spacing;

    // The panel GROWS into its content rather than snapping to it.
    //
    // Opening a card can show placeholders and then the real detail,
    // and the two are never the same height — the description is
    // however long the studio wrote it. Swapped outright, the card
    // jumped and took everything below it along. `AnimatedSize` turns
    // that into the same easing the accordion opened with.
    return AnimatedSize(
      duration: _settleDuration,
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (gallery.isNotEmpty) ...[
            WorkshopGalleryStrip(images: gallery),
            SizedBox(height: spacing.md),
          ],
          // The facts come from the CATALOGUE ROW, which already has
          // them — so they are on screen the instant the card opens,
          // whether or not anything is being fetched.
          _Facts(workshop: widget.workshop, tint: fam.primary),
          // WHO THE SESSION IS FOR, when it is not everybody.
          //
          // Nothing on the server checks a booking against `audience`
          // — the app never asks anybody's gender — so being able to
          // READ it before booking is the whole of what keeps someone
          // out of a room they are not meant to be in. «للجميع» is the
          // default and says nothing, so it draws nothing.
          if (widget.workshop.audience.isRestricted) ...[
            SizedBox(height: spacing.sm),
            _AudienceBadge(
              audience: widget.workshop.audience,
              tint: fam.primary,
            ),
          ],
          SizedBox(height: spacing.md),
          if (busy)
            _DescriptionSkeleton(wash: fam.container)
          else
            _Description(
              html: html,
              fallback: widget.workshop.shortDescription,
              wash: fam.container,
            ),
          // HOW LONG THE STUDIO WILL HOLD IT, promised before booking
          // rather than discovered afterwards. `piece_warning_days` is
          // per workshop and is what the booking's own
          // `pickup_deadline` is computed from.
          SizedBox(height: spacing.md),
          _HoldNote(days: widget.workshop.pieceWarningDays, tint: fam.primary),
          SizedBox(height: spacing.md),
          // ONLY WHEN THERE IS A MAP LINK. `location_url` is null on a
          // workshop the CMS has not given one, and a button whose
          // only outcome is an apology is not a button.
          if (widget.workshop.locationUrl != null) ...[
            GlobalOutlinedButton(
              text: WorkshopStrings.location,
              icon: Icons.location_on_rounded,
              onPressed: widget.onLocation ?? () {},
              style: ButtonStateStyle(
                // The workshop's own hue, outlined — the CTA below is the
                // filled twin of it.
                foregroundColor: fam.primary,
                border: BorderSide(color: fam.primary),
                borderRadius: BorderRadius.circular(kTerracottaCtaRadius),
                height: kTerracottaCtaHeight,
              ),
            ),
            SizedBox(height: spacing.sm),
          ],
          GlobalFilledButton(
            text: WorkshopStrings.book,
            onPressed: widget.onBook ?? () {},
            // The auth CTA's shape — arrow pinned to the END, no inner
            // gutter, label centred in the whole bar — in the
            // workshop's colour rather than the app's brown.
            style: terracottaCtaStyle().copyWith(
              backgroundColor: fam.primary,
              foregroundColor: fam.onPrimary,
              textStyle: TextStyle(
                fontSize: kTerracottaCtaLabelSize,
                color: fam.onPrimary,
              ),
              trailing: TerracottaCtaArrow(color: fam.onPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

/// Price, seats and duration — each printed, or said to be missing.
class _Facts extends StatelessWidget {
  const _Facts({required this.workshop, required this.tint});

  final Workshop workshop;
  final Color tint;

  /// «٢٠٠ ريال للشخص», or «غير محدد».
  ///
  /// A fact the CMS has not filled in is SAID to be missing rather than
  /// left blank: an empty chip reads as a screen that failed to load.
  /// Money is never parsed to a number on the way past — it is a
  /// decimal string on this API.
  String get _price {
    // PRICED PER PIECE. `paint_your_piece` and `make_your_candle` carry
    // a seat price of `"0.00"` because the money is in the products the
    // customer picks — so the chip said «٠ ريال للشخص», which reads as
    // free and is the opposite of what it costs.
    if (workshop.type.hasProductCatalog) {
      return WorkshopStrings.pricePerPiece;
    }

    final raw = workshop.price.trim();
    if (raw.isEmpty) return WorkshopStrings.notSpecified;
    // Amount then currency — «٢٠٠ ريال» — and the whole phrase around
    // it from the ARB.
    return WorkshopStrings.pricePerPerson(
      '${PriceText.format(raw)} ${HomeStrings.currency}',
    );
  }

  String _seats() {
    final seats = workshop.capacityPerSession;
    if (seats <= 0) return WorkshopStrings.notSpecified;
    return WorkshopStrings.seatsPerSession(
      AppNumbers.localizeDigits('$seats'),
    );
  }

  String _duration() {
    final minutes = workshop.durationMinutes;
    if (minutes <= 0) return WorkshopStrings.notSpecified;
    // The ARB interpolates the number itself, and plain `ar` renders it
    // in WESTERN digits — so the whole phrase goes through
    // `localizeDigits`, not the number before it.
    if (minutes == 60) return WorkshopStrings.durationHour;
    return AppNumbers.localizeDigits(
      WorkshopStrings.durationMinutes(minutes),
    );
  }

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: InfoChip(
            label: _price,
            icon: Icons.sell_rounded,
            color: tint,
          ),
        ),
        SizedBox(width: context.spacing.sm),
        Expanded(
          child: InfoChip(
            label: _seats(),
            icon: Icons.people_rounded,
            color: tint,
          ),
        ),
        SizedBox(width: context.spacing.sm),
        Expanded(
          child: InfoChip(
            label: _duration(),
            icon: Icons.schedule_rounded,
            color: tint,
          ),
        ),
      ],
    ),
  );
}

/// The long description, which arrives as HTML.
class _Description extends StatelessWidget {
  const _Description({
    required this.html,
    required this.fallback,
    required this.wash,
  });

  /// `long_description` — `<p>…</p>` on the live server, and empty when
  /// the CMS has not written one.
  final String html;

  /// The catalogue row's short description. Still true, and worth
  /// saying before falling all the way back to "not specified".
  final String fallback;

  final Color wash;

  @override
  Widget build(BuildContext context) {
    final body = context.textTheme.bodySmall?.copyWith(
      color: context.textColors.primary,
      height: 1.7,
    );
    final short = fallback.trim();

    return DecoratedBox(
      decoration: BoxDecoration(
        // The workshop's own hue at 9%, and the design's 11pt corner.
        color: wash,
        borderRadius: BorderRadius.circular(kTerracottaCtaRadius),
      ),
      child: Padding(
        padding: EdgeInsets.all(context.spacing.md),
        child: html.isNotEmpty
            ? Html(
                data: html,
                style: {
                  // The default margins put a blank line above the
                  // first paragraph and below the last, inside a box
                  // that already has its own padding.
                  //
                  // And the FONT: `flutter_html` renders in its own
                  // default rather than inheriting the surrounding text
                  // style, so a paragraph of the description came out
                  // in a different face from every other word on the
                  // screen. Kufam has to be named.
                  'body': Style(
                    margin: Margins.zero,
                    padding: HtmlPaddings.zero,
                    color: body?.color,
                    fontFamily: body?.fontFamily,
                    fontSize: FontSize(body?.fontSize ?? 12),
                    lineHeight: const LineHeight(1.7),
                  ),
                  'p': Style(margin: Margins.zero),
                },
              )
            : Text(
                short.isNotEmpty ? short : WorkshopStrings.notSpecified,
                style: body,
              ),
      ),
    );
  }
}

/// A placeholder where the description will land.
///
/// Only the description: the facts above it come from the catalogue row
/// and are already on screen, so shimmering them would be pretending to
/// wait for something the app has.
class _DescriptionSkeleton extends StatelessWidget {
  const _DescriptionSkeleton({required this.wash});

  final Color wash;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: SkeletonBlock(radius: kTerracottaCtaRadius, color: wash),
    );
  }
}

/// «للنساء فقط» — who the session is for, when it is not everybody.
class _AudienceBadge extends StatelessWidget {
  const _AudienceBadge({required this.audience, required this.tint});

  final WorkshopAudience audience;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tint.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(context.radii.full),
        ),
        child: Padding(
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: spacing.md,
            vertical: spacing.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.groups_rounded,
                size: context.iconSizes.sm,
                color: tint,
              ),
              SizedBox(width: spacing.xs),
              Text(
                WorkshopStrings.audience(audience),
                style: context.textTheme.labelLarge?.copyWith(
                  color: tint,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// «أمامك ٧ أيام لاستلام قطعتك» — the collection window, said before
/// the customer books rather than after the piece is fired.
///
/// Information, not a warning: nothing is cancelled or refunded when
/// the date passes. So it reads in the secondary ink with a small
/// glyph, not in the error ramp — the ERROR ramp belongs to the
/// booking's own countdown, where a piece really can be lost.
class _HoldNote extends StatelessWidget {
  const _HoldNote({required this.days, required this.tint});

  final int days;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.info_outline_rounded,
          size: context.iconSizes.sm,
          color: tint,
        ),
        SizedBox(width: spacing.xs),
        Expanded(
          child: Text(
            // A SPAN, not a bare number — «يوم واحد» against «٧ أيام».
            WorkshopStrings.pieceHold(BookingStrings.dayCount(days)),
            style: context.textTheme.bodySmall?.copyWith(
              color: context.textColors.secondary,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
