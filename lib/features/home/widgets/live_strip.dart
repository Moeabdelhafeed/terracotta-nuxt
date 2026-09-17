import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/colors/workshop_family_colors.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/strings/home_strings.dart';
import '../../../core/localization/strings/order_strings.dart';
import '../../../core/tokens/extensions.dart';
import '../../../data/models/terracotta/commerce/order_status.dart';
import '../../_shared/shared_hero.dart';
import '../../_shared/terracotta_widgets.dart';
import '../../booking/widgets/clock_time.dart';
import '../../workshops/cubits/workshops_cubit.dart';
import '../../workshops/cubits/workshops_state.dart';
import '../cubits/live_now_cubit.dart';

/// The two strips at the very top of the home page — an order on its
/// way, and a workshop the customer is sitting in.
///
/// **They are not another rail.** Everything else on this page is
/// browsing: things to look at, categories to open, pieces to buy.
/// These two are the only rows that are true RIGHT NOW, which is why
/// they sit above the hero rather than under it, and why each is a
/// single card with one thing to do rather than a scroller.
///
/// ## Why this looks like everything else
///
/// The first cut drew them as tint-filled bands with an icon in a
/// coloured disc and the action spelled out as an inline link. It read
/// as a Material info banner dropped onto the page, because none of
/// those three things appear anywhere else in this app.
///
/// This is the house card instead: [TerracottaCard]'s white surface and
/// hairline, a [StatusChip] carrying the colour exactly as «طلباتي»,
/// «قطعي» and «تواصل معنا» do, [PriceText] for money, and the forward
/// arrow that says a row opens something — the same one [ProfileRow]
/// ends with. The colour is in the CHIP, not in the surface, which is
/// the rule the rest of the app already follows.
class LiveStrip extends StatelessWidget {
  const LiveStrip({
    required this.accent,
    required this.icon,
    required this.title,
    required this.statusLabel,
    required this.subtitle,
    this.trailingNote,
    this.onTap,
    super.key,
  });

  /// The status chip's fill, and the leading glyph's ink.
  ///
  /// Passed in rather than themed: an order takes a status colour and a
  /// workshop takes its family's hue, and those are not the same
  /// decision. It does NOT tint the card — the surface stays the
  /// house white.
  final Color accent;

  final IconData icon;
  final String title;

  /// The state, in the customer's words. Never a machine key.
  final String statusLabel;

  final String subtitle;

  /// A figure at the reading end — a price. Optional.
  final String? trailingNote;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    return TerracottaCard(
      onTap: onTap,
      child: Row(
        // START, never stretch: in a scrolling column stretch has no
        // height to stretch TO and the row resolves to infinity.
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // No disc behind it. A coloured glyph on the white card is
          // how the shortcuts below already do this.
          Icon(icon, size: context.iconSizes.md, color: accent),
          SizedBox(width: spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.titleSmall?.copyWith(
                          color: context.textColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    SizedBox(width: spacing.sm),
                    // The colour lives HERE, as it does on every other
                    // status the app draws.
                    StatusChip(label: statusLabel, color: accent),
                  ],
                ),
                SizedBox(height: spacing.xs),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.textColors.secondary,
                        ),
                      ),
                    ),
                    if (trailingNote case final note?) ...[
                      SizedBox(width: spacing.sm),
                      Text(
                        note,
                        style: context.textTheme.labelMedium?.copyWith(
                          color: context.textColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: spacing.sm),
          // The `_rounded` arrow, which Flutter mirrors — the same one
          // every openable row in the app ends with.
          Icon(
            Icons.arrow_forward_rounded,
            size: context.iconSizes.sm,
            color: context.textColors.secondary,
          ),
        ],
      ),
    );
  }
}

/// «طلبك» — the shop order in flight.
class LiveOrderStrip extends StatelessWidget {
  const LiveOrderStrip({
    required this.orderId,
    required this.status,
    required this.itemCount,
    required this.total,
    this.eta,
    this.onTap,
    super.key,
  });

  final int orderId;
  final OrderStatus status;
  final int itemCount;

  /// A decimal STRING, formatted here and never parsed.
  final String total;

  /// When it is expected. Null while the studio has not said.
  final String? eta;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return LiveStrip(
      // The SAME three answers «طلباتي» gives a status — still owed,
      // finished, or on its way — so one order does not wear two
      // different colours on two screens.
      accent: switch (status) {
        OrderStatus.cancelled => context.statusColors.error,
        OrderStatus.completed => context.statusColors.success,
        OrderStatus.awaitingPayment => context.statusColors.warning,
        _ => context.primaryColors.primary,
      },
      icon: switch (status) {
        OrderStatus.outForDelivery => Icons.local_shipping_rounded,
        OrderStatus.preparing => Icons.inventory_2_rounded,
        _ => Icons.receipt_long_rounded,
      },
      title: OrderStrings.number('$orderId'),
      // MAPPED, never the wire's `out_for_delivery`.
      statusLabel: OrderStrings.status(status),
      subtitle: eta == null
          ? HomeStrings.liveItems(itemCount)
          : '${HomeStrings.liveItems(itemCount)} · '
                '${HomeStrings.liveOrderEta(eta!)}',
      trailingNote: '${PriceText.format(total)} ${HomeStrings.currency}',
      onTap: onTap,
    );
  }
}

/// THE WORKSHOP'S OWN COLOUR, for a strip that only has a booking.
///
/// `GET /api/workshops/bookings` carries no `type` and no `color` —
/// only `workshop_title` and `workshop_image` — so the catalogue,
/// matched on `workshop_id`, is the only thing that can answer either.
///
/// ## Why this WATCHES the catalogue rather than reading it once
///
/// Read inline, the answer was whatever the catalogue happened to hold
/// at the moment the strip built — and on the home page that is
/// nothing at all, because the strip's own `LiveNowCubit` answers
/// first. The catalogue landing afterwards rebuilt nothing, so the
/// strip kept the fallback hue for the life of the screen.
///
/// It also ASKS for the catalogue, for the same reason: a page that
/// draws this strip and nothing else of the catalogue would otherwise
/// be waiting on a request nobody makes. `ensureLoaded` is a no-op
/// when it is already there in this language.
class _Skinned extends StatefulWidget {
  const _Skinned({required this.workshopId, required this.builder});

  final int workshopId;

  /// Handed the family and the CMS colour, in that order.
  final Widget Function(BuildContext, WorkshopFamily, String?) builder;

  @override
  State<_Skinned> createState() => _SkinnedState();
}

class _SkinnedState extends State<_Skinned> {
  /// NOT EVERY TREE HAS ONE. A widget test pumps these strips with a
  /// `LiveNowCubit` and nothing else, and reading the locator blind
  /// threw «Object/factory with type WorkshopsCubit is not registered»
  /// out of `build`. The colour is a refinement; the strip is not.
  WorkshopsCubit? get _catalogue =>
      getIt.isRegistered<WorkshopsCubit>() ? getIt<WorkshopsCubit>() : null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    unawaited(
      _catalogue?.ensureLoaded(Localizations.localeOf(context).languageCode),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = _catalogue;
    if (cubit == null) {
      return widget.builder(context, WorkshopFamily.makeYourPiece, null);
    }

    return BlocBuilder<WorkshopsCubit, WorkshopsState>(
      bloc: cubit,
      builder: (context, state) {
        final listed = state is WorkshopsLoaded
            ? state.workshops
                  .where((w) => w.id == widget.workshopId)
                  .firstOrNull
            : null;

        return widget.builder(
          context,
          listed == null
              ? WorkshopFamily.makeYourPiece
              : WorkshopFamily.fromWire(listed.type.wire),
          listed?.color,
        );
      },
    );
  }
}

/// «يحدث الآن» — the session the customer is sitting in.
///
/// Only for a booking the desk has actually SCANNED IN (`attending`).
/// A confirmed booking three days out is not happening now, and putting
/// it here would make this strip mean nothing.
class LiveWorkshopStrip extends StatelessWidget {
  const LiveWorkshopStrip({
    required this.title,
    required this.endsAt,
    this.family = WorkshopFamily.makeYourPiece,
    this.wireColor,
    this.onTap,
    super.key,
  });

  final String title;

  /// Asia/Riyadh, printed as received — the workshop happens at the
  /// studio, not wherever the customer is standing.
  final String endsAt;

  final WorkshopFamily family;

  /// The workshop's admin-set `color`, which wins over the family bag.
  final String? wireColor;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final fam = WorkshopFamilyColors.resolve(
      family: family,
      isDark: context.isDarkMode,
      wireColor: wireColor,
    );

    return LiveStrip(
      accent: fam.primary,
      icon: Icons.qr_code_2_rounded,
      title: title,
      // «يحدث الآن» — the state, in the same chip every other status
      // in the app wears.
      statusLabel: HomeStrings.liveWorkshop,
      // The one thing someone already AT the studio needs from this
      // app is the code the desk scans, and how long they have.
      subtitle:
          '${HomeStrings.liveShowCode} · '
          '${HomeStrings.liveWorkshopUntil(endsAt)}',
      onTap: onTap,
    );
  }
}

/// «يحدث الآن», wherever it belongs — the home page above the hero, and
/// the workshops page above the segmented control.
///
/// A SLOT rather than a card: it reads [LiveNowCubit], decides whether
/// there is anything to say, and collapses to nothing when there is
/// not — which is most customers, most of the time. Three call sites
/// sharing one answer is why this exists; three copies of the same
/// null check is how they drift.
///
/// The cubit is the APP's, not the page's: the same answer serves all
/// three, and none of them closes it.
class LiveWorkshopSlot extends StatelessWidget {
  const LiveWorkshopSlot({this.cubit, super.key});

  /// A cubit to read instead of the app's — the seam a widget test
  /// needs. Null everywhere else.
  final LiveNowCubit? cubit;

  @override
  Widget build(BuildContext context) => BlocBuilder<LiveNowCubit, LiveNowState>(
    bloc: cubit ?? getIt<LiveNowCubit>(),
    builder: (context, state) {
      final booking = state.booking;
      if (booking == null) return const SizedBox.shrink();

      return Padding(
        // The gap belongs to the STRIP, not to the page: a page
        // that spaces it itself has to know whether it drew.
        padding: EdgeInsetsDirectional.only(bottom: context.spacing.sm),
        child: SharedHero(
          // HOLDS STILL across the three tabs that draw it. The tag has
          // existed since these strips were written and nothing wore
          // it, so a thing that is true right now was being rebuilt on
          // every tab switch instead of staying put.
          tag: HeroTag.liveWorkshop,
          child: _Skinned(
            workshopId: booking.workshopId,
            builder: (context, family, wireColor) => LiveWorkshopStrip(
              // Already localized by the server — shown as-is.
              title: booking.workshopTitle,
              family: family,
              wireColor: wireColor,
              // Asia/Riyadh already; printed as received.
              endsAt: formatClock(
                booking.endTime,
                Localizations.localeOf(context).toString(),
              ),
              onTap: () => context.pushNamed(
                'booking-detail',
                pathParameters: {'bookingId': '${booking.id}'},
              ),
            ),
          ),
        ),
      );
    },
  );
}

/// «ورشتك القادمة» — the seat already booked, not yet sat in.
///
/// The SAME shape as [LiveWorkshopStrip], and deliberately so: the two
/// answer neighbouring questions — the session you are in, and the one
/// you are coming back for — and drawing them differently made the
/// second one look like a different kind of thing. It replaced a
/// «استكمل ورشتك» section halfway down the home page, under its own
/// heading, in a card shape nothing else on the page used.
class NextBookingStrip extends StatelessWidget {
  const NextBookingStrip({
    required this.title,
    required this.when,
    this.family = WorkshopFamily.makeYourPiece,
    this.wireColor,
    this.onTap,
    super.key,
  });

  final String title;

  /// «الخميس ٣ سبتمبر · ٧:٠٠ م» — already composed, already localized,
  /// and already Asia/Riyadh.
  final String when;

  final WorkshopFamily family;

  /// The workshop's admin-set `color`, which wins over the family bag.
  final String? wireColor;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final fam = WorkshopFamilyColors.resolve(
      family: family,
      isDark: context.isDarkMode,
      wireColor: wireColor,
    );

    return LiveStrip(
      accent: fam.primary,
      // A DATE, not a QR glyph: the code is for the desk on the day,
      // and this row is about a day that has not come.
      icon: Icons.event_available_rounded,
      title: title,
      statusLabel: HomeStrings.nextBooking,
      subtitle: when,
      onTap: onTap,
    );
  }
}

/// «ورشتك القادمة», wherever it belongs — above the home page and
/// above the workshops page.
///
/// See [LiveWorkshopSlot] for why this is a slot and why the cubit is
/// the app's. It reads the SAME bookings list: `GET /api/home` carries
/// a `current_booking`, and this does not read it — that key is
/// unmodelled and answers only one of the two pages that draw this.
class NextBookingSlot extends StatelessWidget {
  const NextBookingSlot({this.cubit, super.key});

  /// A cubit to read instead of the app's — the seam a widget test
  /// needs. Null everywhere else.
  final LiveNowCubit? cubit;

  @override
  Widget build(BuildContext context) => BlocBuilder<LiveNowCubit, LiveNowState>(
    bloc: cubit ?? getIt<LiveNowCubit>(),
    builder: (context, state) {
      final booking = state.next;
      if (booking == null) return const SizedBox.shrink();

      final locale = Localizations.localeOf(context).toString();

      return Padding(
        // The gap belongs to the STRIP, not to the page: a page that
        // spaces it itself has to know whether it drew.
        padding: EdgeInsetsDirectional.only(bottom: context.spacing.sm),
        child: SharedHero(
          // HOLDS STILL while the page changes under it. The home and
          // workshops tabs both draw this in the same place, so flying
          // it is what makes switching between them read as one page
          // moving rather than two pages swapping.
          tag: HeroTag.nextBooking,
          child: _Skinned(
            workshopId: booking.workshopId,
            builder: (context, family, wireColor) => NextBookingStrip(
              family: family,
              wireColor: wireColor,
              // Already localized by the server — shown as-is.
              title: booking.workshopTitle,
              when: HomeStrings.nextBookingWhen(
                formatBookingDate(booking.bookingDate, locale),
                formatClock(booking.startTime, locale),
              ),
              onTap: () => context.pushNamed(
                'booking-detail',
                pathParameters: {'bookingId': '${booking.id}'},
              ),
            ),
          ),
        ),
      );
    },
  );
}

/// «طلبك», wherever it belongs — the home page above the hero, and the
/// shop page under its heading.
///
/// See [LiveWorkshopSlot] for why this is a slot and why the cubit is
/// the app's.
class LiveOrderSlot extends StatelessWidget {
  const LiveOrderSlot({this.cubit, super.key});

  final LiveNowCubit? cubit;

  @override
  Widget build(BuildContext context) => BlocBuilder<LiveNowCubit, LiveNowState>(
    bloc: cubit ?? getIt<LiveNowCubit>(),
    builder: (context, state) {
      final order = state.order;
      if (order == null) return const SizedBox.shrink();

      return Padding(
        padding: EdgeInsetsDirectional.only(bottom: context.spacing.sm),
        child: SharedHero(
          tag: HeroTag.liveOrder,
          child: LiveOrderStrip(
            orderId: order.id,
            status: order.status,
            itemCount: order.items.length,
            total: order.totalPrice,
            onTap: () => context.pushNamed(
              'order-detail',
              pathParameters: {'orderId': '${order.id}'},
            ),
          ),
        ),
      );
    },
  );
}
