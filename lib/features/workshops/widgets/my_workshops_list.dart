import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/colors/workshop_family_colors.dart';
import '../../../core/localization/strings/booking_strings.dart';
import '../../../core/tokens/extensions.dart';
import '../../../data/models/terracotta/booking/booking.dart';
import '../../../data/models/terracotta/core/api_image.dart';
import '../../../shared/module/empty_state/global_empty_state.dart';
import '../../_shared/screen_entrance.dart';
import '../../booking/widgets/clock_time.dart';
import 'booking_card.dart';

/// One of the customer's bookings, as this screen needs it.
///
/// A VIEW MODEL, not the wire shape. `Booking` carries thirty-odd
/// fields — VAT, wallet, discount, delivery — and this card needs five
/// of them; binding the page later is a change of SOURCE, not a rewrite
/// of the card.
@immutable
class MyWorkshopEntry {
  const MyWorkshopEntry({
    required this.id,
    required this.title,
    required this.meta,
    required this.price,
    required this.status,
    this.deliveryStatus,
    this.hasCelebration = false,
    this.family = WorkshopFamily.makeYourPiece,
    this.wireColor,
    this.image,
  });

  final int id;
  final String title;

  /// Already composed — «٢ أشخاص · الثلاثاء ٤ يونيو · ٣ م الى ٤ م».
  final String meta;

  /// A decimal STRING. Money is decimal on this API.
  final String price;

  /// The raw wire value (`confirmed`, `attending`, `absent`, …).
  final String status;

  /// Where the piece is on its way to the customer, or null when the
  /// booking has no handover leg.
  ///
  /// Shown IN PLACE OF [status] when present: packing, on the road and
  /// delivered are three different things and one `completed` booking,
  /// so the booking status alone would label all three the same.
  final String? deliveryStatus;

  /// Whether a party is attached — worth a mark on the card.
  final bool hasCelebration;

  final WorkshopFamily family;
  final String? wireColor;

  /// The workshop's own photograph — `workshop_image`, which every
  /// booking row carries. Unlike [wireColor] this needs no catalogue
  /// lookup: it is on the booking itself.
  final ApiImage? image;
}

/// One row of `GET /api/workshops/bookings`, as this card needs it.
///
/// Composed at PAINT time, from [context]'s language: the meta line
/// used to travel already built, so a booking listed in Arabic kept its
/// Arabic under an English UI. The date and the clock are Asia/Riyadh
/// strings and are shown as received — a workshop happens at the
/// studio, not wherever the customer is standing.
///
/// [family] and [wireColor] are NOT on the booking payload — it carries
/// no `type` — so the CATALOGUE is what answers them, matched on
/// `workshop_id`. Unmatched falls back to the studio's own hue rather
/// than drawing nothing.
MyWorkshopEntry myWorkshopEntry(
  BuildContext context,
  Booking booking, {
  WorkshopFamily family = WorkshopFamily.makeYourPiece,
  String? wireColor,
}) {
  final locale = Localizations.localeOf(context).toString();

  return MyWorkshopEntry(
    id: booking.id,
    // Already localized by the server — display as-is.
    title: booking.workshopTitle,
    meta: BookingStrings.meta(
      BookingStrings.party(booking.peopleCount),
      DateFormat.MMMMEEEEd(locale).format(DateTime.parse(booking.bookingDate)),
      BookingStrings.slotLabel(
        formatClock(booking.startTime, locale),
        formatClock(booking.endTime, locale),
      ),
    ),
    price: booking.totalPrice,
    status: booking.status,
    // The REAL delivery leg, null until the customer asks for one —
    // gate on this, never on the workshop's `has_delivery`.
    deliveryStatus: booking.deliveryStatus,
    hasCelebration: booking.hasCelebration,
    family: family,
    wireColor: wireColor,
    // OFF THE BOOKING ITSELF. `workshop_image` travels with every row,
    // so a booking of a retired workshop — one the catalogue can no
    // longer colour — still shows the right picture.
    image: booking.workshopImage,
  );
}

/// «ورشاتي» — the bookings the customer already has.
///
/// Renders whatever it is handed; [myWorkshopEntry] is what turns a
/// row of `GET /api/workshops/bookings` into one of these.
class MyWorkshopsList extends StatelessWidget {
  const MyWorkshopsList({required this.entries, this.onOpen, super.key});

  final List<MyWorkshopEntry> entries;
  final ValueChanged<MyWorkshopEntry>? onOpen;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return GlobalEmptyState(
        icon: Icons.event_busy_rounded,
        title: BookingStrings.mineEmpty,
        variant: EmptyStateVariant.compact,
      );
    }

    final spacing = context.spacing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      // STAGGERED. The rows arrive one after another as the screen
      // settles, rather than the whole block appearing at once.
      children: ScreenEntrance.stage([
        for (final entry in entries) ...[
          BookingCard(
            title: entry.title,
            meta: entry.meta,
            price: entry.price,
            status: entry.status,
            deliveryStatus: entry.deliveryStatus,
            hasCelebration: entry.hasCelebration,
            family: entry.family,
            wireColor: entry.wireColor,
            image: entry.image,
            onTap: onOpen == null ? null : () => onOpen!(entry),
          ),
          SizedBox(height: spacing.md),
        ],
      ]),
    );
  }
}
