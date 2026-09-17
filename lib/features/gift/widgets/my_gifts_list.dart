import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/strings/gift_strings.dart';
import '../../../core/tokens/extensions.dart';
import '../../../data/models/terracotta/commerce/gift.dart';
import '../../../data/models/terracotta/commerce/gift_history.dart';
import '../../../shared/module/buttons/global_text_button.dart';
import '../../../shared/module/chip/global_chip.dart';
import '../../../shared/module/empty_state/global_empty_state.dart';
import '../../../shared/module/list/global_list.dart';
import '../../../shared/module/shimmer/global_shimmer.dart';
import '../../../shared/module/toast/global_toast.dart';
import '../../_shared/terracotta_widgets.dart';
import '../../booking/widgets/clock_time.dart';
import '../cubits/my_gifts_cubit.dart';

/// «هداياي» — both sides of the reader's gifting, inside the sheet.
///
/// ## Two kinds of row, told apart by `direction`
///
/// A **sent** row is the buyer's own receipt: who it was for, how
/// much, when — and, above all, **whether it has been claimed**,
/// because that is the only thing they can still act on. An unclaimed
/// one carries the way to send the link again.
///
/// A **received** row is narrower, because the server sends it
/// narrower: what landed in the wallet, who it came from, the note.
/// There is no `share_url` and no `total_price` on it — those are the
/// BUYER's, and `GiftHistoryEntry` is sealed so the compiler is what
/// stops this screen asking for them.
///
/// ## The counts ARE the filter
///
/// `totals` covers the whole history whatever is being shown, so a
/// chip can carry its count and be the way to narrow to that side at
/// the same time — true before it is pressed, and still true after.
class MyGiftsList extends StatefulWidget {
  const MyGiftsList({required this.cubit, super.key});

  final MyGiftsCubit cubit;

  @override
  State<MyGiftsList> createState() => _MyGiftsListState();
}

class _MyGiftsListState extends State<MyGiftsList> {
  /// Which side is showing. Null is both.
  ///
  /// FILTERED HERE, not re-fetched. The endpoint takes a `direction`,
  /// but the app already holds the whole list — asking again to hide
  /// half of what is on screen is a request and a spinner for a thing
  /// the reader can watch happen.
  GiftDirection? _only;

  @override
  Widget build(BuildContext context) => BlocBuilder<MyGiftsCubit, MyGiftsState>(
    bloc: widget.cubit,
    builder: (context, state) {
      if (state.loading && state.gifts.isEmpty) return const _Skeleton();

      if (state.gifts.isEmpty) {
        return GlobalEmptyState(
          icon: Icons.card_giftcard_rounded,
          title: GiftStrings.empty,
          subtitle: state.error?.message,
          variant: EmptyStateVariant.compact,
        );
      }

      final spacing = context.spacing;
      final totals = state.totals;
      final shown = [
        for (final entry in state.gifts)
          if (_only == null || entry.direction == _only) entry,
      ];

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // THE COUNTS ARE THE FILTER.
          //
          // They were a sentence — «أرسلت ٢ · استلمت ١» — which is the
          // same two numbers doing nothing. The server's `totals` do
          // not narrow with the list, so a chip can carry its count
          // AND be the way to see only that side: the label is true
          // before it is pressed and stays true after.
          Wrap(
            spacing: spacing.xs,
            runSpacing: spacing.xs,
            children: [
              GlobalChip(
                label: GiftStrings.filterAll,
                count: totals.sentCount + totals.receivedCount,
                selected: _only == null,
                onSelected: (_) => setState(() => _only = null),
              ),
              GlobalChip(
                label: GiftStrings.filterSent,
                count: totals.sentCount,
                selected: _only == GiftDirection.sent,
                onSelected: (_) => setState(() => _only = GiftDirection.sent),
              ),
              GlobalChip(
                label: GiftStrings.filterReceived,
                count: totals.receivedCount,
                selected: _only == GiftDirection.received,
                onSelected: (_) =>
                    setState(() => _only = GiftDirection.received),
              ),
            ],
          ),
          SizedBox(height: spacing.md),
          if (shown.isEmpty)
            // SAID ABOUT THE FILTER. «ليس لديك هدايا» under a chip the
            // reader just pressed is about the wrong thing — they have
            // gifts, just none on this side.
            GlobalEmptyState(
              icon: Icons.card_giftcard_rounded,
              title: _only == GiftDirection.received
                  ? GiftStrings.noneReceived
                  : GiftStrings.noneSent,
              variant: EmptyStateVariant.compact,
            )
          else
            GlobalList<GiftHistoryEntry>.static(
              items: shown,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              separatorBuilder: (_, _) => SizedBox(height: spacing.sm),
              itemBuilder: (context, entry, _) => switch (entry) {
                SentGift(:final gift) => _SentRow(gift: gift),
                ReceivedGift() => _ReceivedRow(gift: entry),
              },
            ),
        ],
      );
    },
  );
}

class _SentRow extends StatelessWidget {
  const _SentRow({required this.gift});

  final Gift gift;

  /// WHAT THE BUYER CAN STILL DO ABOUT IT.
  ///
  /// Three states, and they are not the same question: unpaid means
  /// the gift exists and its link does nothing; unclaimed means the
  /// link works and nobody has opened it; claimed means it is spent.
  (String, Color) _state(BuildContext context) {
    if (gift.isRedeemed) {
      return (GiftStrings.stateClaimed, context.statusColors.success);
    }
    // THE HOLD LAPSED. `status: cancelled` — the buyer never paid, the
    // link is dead and the gift cannot be revived.
    if (gift.isDead) {
      return (GiftStrings.stateCancelled, context.textColors.disabled);
    }
    if (!gift.isAlreadySettled) {
      return (GiftStrings.stateUnpaid, context.statusColors.warning);
    }
    return (GiftStrings.stateUnclaimed, context.textColors.secondary);
  }

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: gift.shareUrl));
    if (!context.mounted) return;
    GlobalToast.success(GiftStrings.linkCopied);
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final locale = Localizations.localeOf(context).toString();
    final (label, tint) = _state(context);

    return TerracottaCard(
      padding: EdgeInsets.all(spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              // WHICH WAY IT WENT, on both kinds of row. The received
              // one had an arrow and this did not, so a list of both
              // read as one shape with a stray glyph on some of them.
              Icon(
                Icons.north_east_rounded,
                size: context.iconSizes.sm,
                color: context.primaryColors.accent,
              ),
              SizedBox(width: spacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      GiftStrings.forName(gift.recipientName),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: context.textColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: spacing.xs),
                    Text(
                      // Asia/Riyadh as the server wrote it.
                      formatBookingDate(
                        gift.createdAt.toIso8601String(),
                        locale,
                      ),
                      style: context.textTheme.labelSmall?.copyWith(
                        color: context.textColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
              // A decimal STRING, printed. Money is never parsed.
              PriceText(amount: gift.amount),
            ],
          ),
          SizedBox(height: spacing.sm),
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: context.textTheme.labelMedium?.copyWith(color: tint),
                ),
              ),
              // ONLY WHERE IT IS ANY USE. A claimed gift's link opens a
              // page saying it is spent, and an unpaid one's opens
              // nothing at all — offering either is offering a dead
              // link with the studio's name on it.
              if (gift.isShareable && gift.isAlreadySettled)
                GlobalTextButton(
                  text: GiftStrings.copyLink,
                  shrinkWidth: true,
                  style: ButtonStateStyle(
                    foregroundColor: context.primaryColors.accent,
                  ),
                  onPressed: () => unawaited(_copy(context)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A gift the reader CLAIMED.
///
/// Nothing to act on and nothing to share — the money is already in
/// the wallet, moved by its own `gift_redeemed` transaction. This is
/// the story, not a second ledger.
class _ReceivedRow extends StatelessWidget {
  const _ReceivedRow({required this.gift});

  final ReceivedGift gift;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final locale = Localizations.localeOf(context).toString();
    final from = (gift.from ?? '').trim();

    return TerracottaCard(
      padding: EdgeInsets.all(spacing.md),
      child: Row(
        children: [
          Icon(
            Icons.south_west_rounded,
            size: context.iconSizes.sm,
            color: context.statusColors.success,
          ),
          SizedBox(width: spacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  // `from` is NULLABLE in the spec, and a row that
                  // reads «من » is worse than one that does not name
                  // anybody.
                  from.isEmpty
                      ? GiftStrings.fromSomeone
                      : GiftStrings.fromName(from),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.textColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: spacing.xs),
                Text(
                  formatBookingDate(
                    (gift.redeemedAt ?? gift.createdAt).toIso8601String(),
                    locale,
                  ),
                  style: context.textTheme.labelSmall?.copyWith(
                    color: context.textColors.secondary,
                  ),
                ),
              ],
            ),
          ),
          PriceText(amount: gift.amount),
        ],
      ),
    );
  }
}

/// Three rows of nothing, at the shape the real ones take.
class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < 3; i++) ...[
          if (i > 0) SizedBox(height: spacing.sm),
          GlobalShimmer(
            child: SizedBox(
              height: 96,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: context.shimmerColors.baseColor,
                  borderRadius: BorderRadius.circular(context.radii.md),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
