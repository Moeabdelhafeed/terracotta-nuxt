import 'package:flutter/material.dart';

import '../../../core/constants/colors/workshop_family_colors.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/strings/booking_strings.dart';
import '../../../core/localization/strings/delivery_strings.dart';
import '../../../core/tokens/extensions.dart';
import '../../../data/models/terracotta/core/api_image.dart';
import '../../../shared/module/image/global_image.dart';
import '../../_shared/terracotta_cta_style.dart';
import '../../_shared/terracotta_image.dart';
import '../../_shared/terracotta_widgets.dart';

/// One of the customer's own bookings, in «ورشاتي».
///
/// The workshop card's twin: the same coloured band and illustration
/// well, with the session's own facts in place of the description and a
/// STATUS CHIP across the foot of the well.
///
/// The chip's colour is the only thing on the card that is not the
/// workshop's own — a cancelled booking has to read as cancelled
/// whatever family it belongs to.
class BookingCard extends StatelessWidget {
  const BookingCard({
    required this.title,
    required this.meta,
    required this.price,
    this.status,
    this.deliveryStatus,
    this.hasCelebration = false,
    this.family = WorkshopFamily.makeYourPiece,
    this.wireColor,
    this.image,
    this.onTap,
    super.key,
  });

  final String title;

  /// «٢ أشخاص · الثلاثاء ٤ يونيو · ٣ م الى ٤ م» — already composed, so
  /// the card does no date arithmetic. Times are Asia/Riyadh and are
  /// displayed as received.
  final String meta;

  /// A decimal STRING, printed by [PriceText]. Never parsed.
  final String price;

  /// The raw wire value (`confirmed`, `pending_payment`, …).
  ///
  /// NULL on the checkout, where the booking does not exist yet — the
  /// same card, with nothing to say about a lifecycle that has not
  /// started.
  final String? status;

  /// Where the piece is on its way to the customer, or null when the
  /// booking has no handover leg.
  ///
  /// Shown IN PLACE OF [status] when present. Packing, on the road and
  /// delivered are three different things and ONE `completed` booking —
  /// the booking status alone would label all three «مكتمل».
  final String? deliveryStatus;

  /// Whether a party is attached to this booking.
  ///
  /// Worth a mark on the CARD, not just inside: it is the difference
  /// between a workshop and someone's birthday, it is paid for, and a
  /// customer scanning «ورشاتي» for the one they booked the cake on
  /// should not have to open three to find it.
  final bool hasCelebration;

  final WorkshopFamily family;

  /// The admin-set colour for this workshop, when the row carried one.
  final String? wireColor;

  /// The workshop's OWN photograph — `workshop_image` on the booking
  /// row, which the server sends with every booking. Null falls back to
  /// the family's line drawing.
  final ApiImage? image;

  final VoidCallback? onTap;

  /// The design's height for a card whose words fit. Anything longer
  /// grows the row, and the well grows with it.
  static const _minRowHeight = 128.0;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final fam = WorkshopFamilyColors.resolve(
      family: family,
      isDark: context.isDarkMode,
      wireColor: wireColor,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(kTerracottaCtaRadius),
      // The card's colour has to BE the Material, or the ripple paints
      // underneath it and never shows.
      child: Material(
        color: fam.primary,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(spacing.xs),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: _minRowHeight),
              // The well matches the WORDS, however many lines they run
              // to — `IntrinsicHeight` is what gives `stretch` a height
              // to stretch to in an unbounded column.
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(
                          spacing.md,
                          spacing.md,
                          spacing.sm,
                          spacing.md,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: context.textTheme.titleLarge?.copyWith(
                                color: fam.onPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: spacing.sm),
                            Text(
                              meta,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: context.textTheme.labelSmall?.copyWith(
                                color: fam.onPrimary,
                                height: 1.5,
                              ),
                            ),
                            SizedBox(height: spacing.sm),
                            // On the card's OWN colour, so the price
                            // reads as part of the booking rather than
                            // borrowing the shop's brown.
                            PriceText(amount: price, color: fam.onPrimary),
                          ],
                        ),
                      ),
                    ),
                    _Well(
                      tint: fam.onPrimary,
                      family: family,
                      image: image,
                      status: status,
                      deliveryStatus: deliveryStatus,
                      hasCelebration: hasCelebration,
                    ),
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

/// The drawing, with the booking's status across its foot.
class _Well extends StatelessWidget {
  const _Well({
    required this.tint,
    required this.family,
    this.status,
    this.deliveryStatus,
    this.hasCelebration = false,
    this.image,
  });

  final Color tint;
  final WorkshopFamily family;

  /// The workshop's own photograph, when the row carried one.
  final ApiImage? image;

  final String? status;
  final String? deliveryStatus;
  final bool hasCelebration;

  /// The FALLBACK drawing, one per FAMILY rather than per workshop —
  /// two workshops can share a family. It was every row's well while
  /// `image` was null on all of them.
  static const _art = <WorkshopFamily, String>{
    WorkshopFamily.makeYourPiece:
        'assets/images/make-your-cup-workshop-illustration.png',
    WorkshopFamily.paintYourPiece:
        'assets/images/color-your-cup-workshop-illustration.png',
    WorkshopFamily.makeYourCandle:
        'assets/images/make-your-wax-workshop-illustration.png',
  };

  static const _width = 96.0;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(context.radii.xs),
    child: SizedBox(
      // WIDTH only. The height comes from the row — `stretch` hands
      // this a tight height, so a `height:` here would look like it did
      // something and do nothing.
      width: _width,
      child: ColoredBox(
        color: tint.withValues(alpha: 0.12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // A PHOTOGRAPH IS NOT LINE WORK — no `srcIn` over it, which
            // masks a colour by the image's own alpha and would paint
            // an opaque picture one flat colour.
            if (image case final photo?)
              TerracottaImage(image: photo, fit: BoxFit.cover)
            else
              GlobalImage.a(
                _art[family]!,
                placeholder: const SizedBox.shrink(),
                style: ImageStyle(
                  fit: BoxFit.contain,
                  // No radius on a line drawing — the house 8pt eats
                  // its own edges.
                  borderRadius: BorderRadius.zero,
                  color: tint,
                  // srcIn: a solid silhouette on transparency.
                  overlayBlendMode: BlendMode.srcIn,
                ),
              ),
            // The HANDOVER leg wins when there is one.
            if (deliveryStatus ?? status case final label?)
              Align(
                alignment: AlignmentDirectional.bottomCenter,
                child: _StatusChip(
                  status: label,
                  isDelivery: deliveryStatus != null,
                ),
              ),
            // The party mark, across the well's HEAD — the same band
            // the status wears at the foot, so the two read as a pair
            // of labels on one card rather than two inventions.
            if (hasCelebration)
              const Align(
                alignment: AlignmentDirectional.topCenter,
                child: _CelebrationRibbon(),
              ),
          ],
        ),
      ),
    ),
  );
}

/// «مؤكد» / «ملغاة» — the booking's lifecycle, as a word.
///
/// The wire sends MACHINE KEYS. An unmodelled one draws NOTHING rather
/// than printing `pending_payment` at a customer.
class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status, this.isDelivery = false});

  final String status;

  /// Whether [status] is a `delivery_status` rather than the booking's
  /// own — the two vocabularies overlap (`completed` is in both) and
  /// mean different things, so the label has to be looked up in the
  /// right one.
  final bool isDelivery;

  /// The colour a status reads in, whatever family it belongs to.
  static Color _colorFor(BuildContext context, String status) =>
      switch (status) {
        // The handover leg. `on_the_way` and `getting_ready` are
        // progress, not completion — the piece is not the customer's
        // until it is in their hands.
        'getting_ready' || 'on_the_way' => context.statusColors.info,
        'awaiting_pickup' => context.statusColors.warning,
        'confirmed' ||
        'attending' ||
        'completed' => context.statusColors.success,
        // NOT an error: the booking still stands and a late arrival can
        // still be scanned in. Only `sessions/finish` settles it.
        'absent' => context.statusColors.warning,
        // AMBER, not blue. The piece is in the kiln: nothing is
        // wrong and nothing is finished, and «قيد التحضير» in the
        // informational blue read as "done, here is a note" beside
        // «مكتمل» in green. Waiting is what warning colours are for.
        'preparing' => context.statusColors.warning,
        'cancelled' => context.statusColors.error,
        _ => context.statusColors.warning,
      };

  @override
  Widget build(BuildContext context) {
    final label = isDelivery
        ? DeliveryStrings.status(status)
        : BookingStrings.status(status);
    if (label == null) return const SizedBox.shrink();

    return DecoratedBox(
      decoration: BoxDecoration(color: _colorFor(context, status)),
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: context.spacing.xs),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: context.textTheme.labelMedium?.copyWith(
              color: context.textColors.onPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

/// «مع احتفال» — the band across the head of a booking with a party.
///
/// The STATUS CHIP's twin: same full-width band, same centred label,
/// same weight — at the opposite end of the well. Two labels on one
/// card should look like two labels, not like a chip and a sticker.
///
/// Coral, like every other celebration surface in the app. Never the
/// error ramp: same family of reds, opposite meaning.
class _CelebrationRibbon extends StatelessWidget {
  const _CelebrationRibbon();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(color: context.primaryColors.accent),
    child: SizedBox(
      width: double.infinity,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: context.spacing.xs),
        child: Text(
          BookingStrings.withCelebration,
          textAlign: TextAlign.center,
          style: context.textTheme.labelMedium?.copyWith(
            color: context.textColors.onPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ),
  );
}
