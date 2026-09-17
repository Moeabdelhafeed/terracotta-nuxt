import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/strings/auth_strings.dart';
import '../../../core/localization/strings/home_strings.dart';
import '../../../core/localization/strings/profile_strings.dart';
import '../../../core/localization/strings/wallet_strings.dart';
import '../../../core/localization/strings/workshop_strings.dart';
import '../../../core/tokens/extensions.dart';
import '../../../data/models/terracotta/account/wallet_transaction.dart';
import '../../../shared/module/container/global_container.dart';
import '../../../shared/module/empty_state/global_empty_state.dart';
import '../../../shared/module/refreshable/global_refreshable.dart';
import '../../../shared/module/scrollable/global_scrollable.dart';
import '../../../shared/module/skeleton/global_skeleton.dart';
import '../../_shared/account_refresh.dart';
import '../../_shared/screen_entrance.dart';
import '../../_shared/terracotta_page_bar.dart';
import '../../_shared/terracotta_widgets.dart';
import '../cubits/wallet_ledger_cubit.dart';
import '../cubits/wallet_ledger_state.dart';

/// «محفظتي» — the balance and the ledger behind it.
///
/// `GET /api/wallet/transactions` answers BOTH in one request: the
/// balance the checkout screens spend, and every credit and debit that
/// made it.
///
/// **There is no way to put money in from here, and that is not an
/// omission.** The API has ninety-seven operations and exactly one
/// touches the wallet — this list. Credits arrive as refunds (a
/// cancelled booking, a no-show, seats a party did not fill), as a
/// redeemed gift, or as an admin top-up made in the CMS. A "top up"
/// button would have to call an endpoint that does not exist.
///
/// **`balance_after` is on every row**, so the ledger reconstructs
/// itself — the balance is never derived by summing what is on screen,
/// which would be wrong the moment the list is paginated. The spec says
/// so outright: "the ledger is always independently reconstructable —
/// it never needs to be summed by the client".
class WalletPage extends StatefulWidget {
  const WalletPage({this.cubit, super.key});

  /// A cubit to use instead of making one — the seam a widget test
  /// needs, since the page loads on mount. Null in the app.
  final WalletLedgerCubit? cubit;

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  late final _ledger = (widget.cubit ?? WalletLedgerCubit())..load();

  @override
  void dispose() {
    // Only what this page MADE. An injected one belongs to its test.
    if (widget.cubit == null) unawaited(_ledger.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    return Scaffold(
      backgroundColor: context.backgroundColors.scaffoldBackground,
      // The bar every SECONDARY page wears — the title against the
      // reading start, the cart, the bell and the language toggle. The
      // wallet is reached FROM a tab, so it is one of those pages.
      appBar: TerracottaPageBar(title: ProfileStrings.wallet),
      body: BlocBuilder<WalletLedgerCubit, WalletLedgerState>(
        bloc: _ledger,
        builder: (context, state) => GlobalRefreshable(
          onRefresh: () async {
            // AND WHO THEY ARE. The BALANCE lives on `GET /api/user`,
            // not on the ledger below — so a wallet credited by the
            // studio moved the statement and left the number above it
            // saying what it said at sign-in.
            await Future.wait([
              AccountRefresh.user(context),
              _ledger.refresh(),
            ]);
          },
          child: NotificationListener<ScrollNotification>(
            // Within a screen of the foot, ask for the next page. The
            // cubit refuses once the server has answered short, so this
            // cannot spend a request per scroll at the end of the list.
            onNotification: (n) {
              if (n.metrics.pixels >= n.metrics.maxScrollExtent - 400) {
                unawaited(_ledger.loadMore());
              }
              return false;
            },
            child: GlobalScrollable(
              // The CALLER has to ask, or a page shorter than the
              // viewport drops the drag recogniser — and the page that
              // most needs pulling is the empty or failed one.
              physics: const AlwaysScrollableScrollPhysics(),
              child: GlobalContainer.shell(
                padding: EdgeInsetsDirectional.fromSTEB(
                  spacing.md,
                  spacing.md,
                  spacing.md,
                  spacing.xxl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _BalanceHeader(
                      balance: state.balance,
                      loading: state.loading && !state.hasData,
                    ),
                    SizedBox(height: spacing.lg),
                    _Ledger(state: state),
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

/// «رصيد تيراكوتا» — what there is to spend, over the ledger that
/// explains it.
class _BalanceHeader extends StatelessWidget {
  const _BalanceHeader({required this.balance, required this.loading});

  final String? balance;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    return TerracottaCard(
      padding: EdgeInsets.all(spacing.lg),
      child: Column(
        children: [
          Text(
            WorkshopStrings.walletBalance,
            style: context.textTheme.bodyLarge?.copyWith(
              color: context.textColors.secondary,
            ),
          ),
          SizedBox(height: spacing.sm),
          if (loading)
            const SizedBox(
              height: 32,
              width: 120,
              child: GlobalSkeleton(
                loading: true,
                skeleton: _SkeletonBox(),
                child: _SkeletonBox(),
              ),
            )
          else
            // «٠ ريال» is the TRUE answer for a new customer, and an
            // empty space where a balance goes reads as a screen that
            // failed. Printed, not hidden.
            PriceText(amount: balance ?? '0.00', large: true),
        ],
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: context.backgroundColors.container,
      borderRadius: BorderRadius.circular(context.radii.sm),
    ),
  );
}

/// The rows, or the reason there are none.
class _Ledger extends StatelessWidget {
  const _Ledger({required this.state});

  final WalletLedgerState state;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    if (state.loading && state.rows.isEmpty) {
      return Column(
        children: [
          for (var i = 0; i < 4; i++) ...[
            const SizedBox(
              height: 72,
              child: GlobalSkeleton(
                loading: true,
                skeleton: _SkeletonBox(),
                child: _SkeletonBox(),
              ),
            ),
            SizedBox(height: spacing.sm),
          ],
        ],
      );
    }

    if (state.rows.isEmpty) {
      // A HEIGHT, and centred in it. Dropped straight into a column the
      // empty state collapsed against the card above it and read as a
      // page that had failed to draw.
      return ConstrainedBox(
        // A FLOOR, not a fixed height: the state has to be tall enough
        // to sit in the middle of the page rather than collapse against
        // the card above it, and still free to grow — pinned to 320 the
        // subtitle overflowed it by eighteen pixels.
        constraints: const BoxConstraints(minHeight: 320),
        child: Center(
          child: GlobalEmptyState(
            icon: state.error != null
                ? Icons.wifi_off_rounded
                : Icons.account_balance_wallet_outlined,
            title: state.error != null
                ? AuthStrings.errorGeneric
                : ProfileStrings.noTransactions,
            // The empty state had a title and NOTHING else, which on a
            // screen the customer opened to see their money reads as a
            // failure rather than an answer.
            subtitle: state.error != null ? null : WalletStrings.emptyBody,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      // STAGGERED. The rows arrive one after another as the screen
      // settles, rather than the whole block appearing at once.
      children: ScreenEntrance.stage([
        for (final row in state.rows) ...[
          _LedgerRow(row: row),
          SizedBox(height: spacing.sm),
        ],
        if (state.loadingMore) ...[
          SizedBox(height: spacing.sm),
          const Center(child: CircularProgressIndicator.adaptive()),
        ],
      ]),
    );
  }
}

/// One movement: what it was, when, how much, and what it left behind.
class _LedgerRow extends StatelessWidget {
  const _LedgerRow({required this.row});

  final WalletTransaction row;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final isCredit = row.kind == WalletTransactionKind.credit;
    final isDebit = row.kind == WalletTransactionKind.debit;

    // An UNKNOWN direction is drawn neutrally rather than guessed at:
    // a sign picked at random is worse than no sign.
    final tint = isCredit
        ? context.statusColors.success
        : isDebit
        ? context.statusColors.error
        : context.textColors.secondary;

    return TerracottaCard(
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Padding(
              padding: EdgeInsets.all(spacing.sm),
              child: Icon(
                isCredit
                    ? Icons.south_west_rounded
                    : isDebit
                    ? Icons.north_east_rounded
                    : Icons.swap_horiz_rounded,
                size: context.iconSizes.sm,
                color: tint,
              ),
            ),
          ),
          SizedBox(width: spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  // Never the raw key — see `WalletStrings.reason`.
                  WalletStrings.reason(row.reason, isCredit: isCredit),
                  style: context.textTheme.titleMedium?.copyWith(
                    color: context.textColors.primary,
                  ),
                ),
                if (row.createdAt != null) ...[
                  SizedBox(height: spacing.xs),
                  Text(
                    DateFormat.yMMMd(
                      Localizations.localeOf(context).toString(),
                    ).format(row.createdAt!),
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.textColors.secondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: spacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // The SIGN carries the direction, since `amount` is an
              // absolute value on the wire.
              Text(
                '${isCredit
                    ? '+'
                    : isDebit
                    ? '−'
                    : ''}'
                '${PriceText.format(row.amount ?? '0')} '
                '${HomeStrings.currency}',
                style: context.textTheme.titleMedium?.copyWith(
                  color: tint,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (row.balanceAfter != null) ...[
                SizedBox(height: spacing.xs),
                Text(
                  // The server sends the running balance, so it is
                  // shown rather than worked out.
                  WalletStrings.balanceAfter(
                    '${PriceText.format(row.balanceAfter!)} '
                    '${HomeStrings.currency}',
                  ),
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.textColors.secondary,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
