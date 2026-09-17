import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/strings/auth_strings.dart';
import '../../../core/localization/strings/order_strings.dart';
import '../../../core/localization/strings/profile_strings.dart';
import '../../../core/localization/strings/shop_strings.dart';
import '../../../core/navigation/transitions/navigation_aware_animation.dart';
import '../../../core/tokens/extensions.dart';
import '../../../data/models/terracotta/commerce/order.dart';
import '../../../data/models/terracotta/commerce/order_status.dart';
import '../../../shared/module/container/global_container.dart';
import '../../../shared/module/empty_state/global_empty_state.dart';
import '../../../shared/module/refreshable/global_refreshable.dart';
import '../../../shared/module/scrollable/global_scrollable.dart';
import '../../_shared/account_refresh.dart';
import '../../_shared/screen_entrance.dart';
import '../../_shared/terracotta_page_bar.dart';
import '../../_shared/terracotta_widgets.dart';
import '../cubits/orders_cubit.dart';

/// «طلباتي» — shop order history.
///
/// `GET /api/shop/orders` through [OrdersCubit], unpaginated: a numeric
/// `per_page` swaps `data` for a Laravel paginator and moves the rows
/// to `data.data`, which the list handler behind it does not read.
///
/// Status runs `awaiting_payment → pending → preparing →
/// out_for_delivery → completed`, plus `cancelled` — and is MAPPED, not
/// printed. The customer may only cancel while it is `pending` or
/// `preparing`, and `order.canCancel` is the authority on that, not the
/// status.
///
/// Every money field is a decimal STRING and is shown as it arrives.
class MyOrdersPage extends StatefulWidget {
  const MyOrdersPage({this.cubit, super.key});

  /// A cubit to use instead of making one — the seam a widget test
  /// needs, since the page loads on mount. Null in the app.
  final OrdersCubit? cubit;

  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage> {
  late final _orders = (widget.cubit ?? OrdersCubit())..load();

  @override
  void dispose() {
    // Only what this page MADE.
    if (widget.cubit == null) unawaited(_orders.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    return Scaffold(
      backgroundColor: context.backgroundColors.scaffoldBackground,
      // The app's own bar, like every other pushed page — this was the
      // bare module bar, which carries neither the language toggle nor
      // the cart the rest of the app has.
      appBar: TerracottaPageBar(title: ProfileStrings.orders),
      body: BlocBuilder<OrdersCubit, OrdersState>(
        bloc: _orders,
        builder: (context, state) => GlobalRefreshable(
          onRefresh: () async {
            // AND WHO THEY ARE. A pull on a page about the customer
            // is a person asking whether the app is still right about
            // them — see [AccountRefresh].
            await Future.wait([
              AccountRefresh.user(context),
              _orders.refresh(),
            ]);
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
              // COVERED and REVEALED.
              //
              // The route transition moves the incoming page; this is
              // what the page being LEFT BEHIND does, which until now
              // was nothing — a detail slid over a list that sat
              // perfectly still, so the push had no depth to it.
              //
              // Deliberately small. It plays UNDER an arriving page and
              // alongside its own back-swipe, and anything louder here
              // is a third thing moving in the same frame.
              child: NavigationAwareAnimation(
                onPushOther: _settleBack,
                onPopOther: _comeForward,
                child: _Body(state: state),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Sinking a little as something opens over it.
const _settleBack = WidgetAnimation(
  scaleFrom: 1,
  scaleTo: 0.96,
  fadeFrom: 1,
  fadeTo: 0.55,
);

/// And coming back when that thing closes.
const _comeForward = WidgetAnimation(
  scaleFrom: 0.96,
  scaleTo: 1,
  fadeFrom: 0.55,
  fadeTo: 1,
);

class _Body extends StatelessWidget {
  const _Body({required this.state});

  final OrdersState state;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    if (state.loading && !state.hasData) {
      return const _Waiting();
    }

    if (!state.hasData) {
      // A HEIGHT, and centred in it. Dropped straight into a stretched
      // column the empty state sat at the very top of the page and read
      // as a screen that had failed to draw.
      return ConstrainedBox(
        // A FLOOR, not a fixed height: tall enough to sit in the middle
        // of the page, still free to grow with the subtitle.
        constraints: const BoxConstraints(minHeight: 360),
        child: Center(
          child: GlobalEmptyState(
            icon: state.error != null
                ? Icons.wifi_off_rounded
                : Icons.receipt_long_outlined,
            title: state.error != null
                ? AuthStrings.errorGeneric
                : ShopStrings.ordersEmpty,
            // A title alone on a screen the customer opened to find
            // something reads as a failure rather than an answer.
            subtitle: state.error != null ? null : ShopStrings.ordersEmptyBody,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      // STAGGERED. The page slides in as one; its cards arrive one
      // after another behind it — the same treatment the auth flow
      // carries, and it skips any element that FLEW here rather than
      // replaying an arrival that already happened.
      children: ScreenEntrance.stage([
        for (final order in state.orders) ...[
          _OrderCard(order: order),
          SizedBox(height: spacing.sm),
        ],
      ]),
    );
  }
}

/// The first load, which has nothing to show yet.
class _Waiting extends StatelessWidget {
  const _Waiting();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 120),
    child: Center(child: CircularProgressIndicator.adaptive()),
  );
}

/// One order: what it is, where it got to, and what it cost.
class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final Order order;

  /// The chip's ink.
  ///
  /// Three answers, not seven: still owed, finished, or on its way.
  /// A cancelled order is the one that has to read differently from a
  /// delivered one, and a colour per status would say nothing the words
  /// beside it do not.
  Color _tint(BuildContext context) => switch (order.status) {
    OrderStatus.cancelled => context.statusColors.error,
    OrderStatus.completed => context.statusColors.success,
    OrderStatus.awaitingPayment => context.statusColors.warning,
    _ => context.primaryColors.primary,
  };

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final locale = Localizations.localeOf(context).toString();

    return TerracottaCard(
      // Into the order itself — its lines, its address, and whatever
      // can still be done to it.
      onTap: () => context.pushNamed(
        'order-detail',
        pathParameters: {'orderId': '${order.id}'},
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  OrderStrings.number('${order.id}'),
                  style: context.textTheme.titleMedium?.copyWith(
                    color: context.textColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              StatusChip(
                label: OrderStrings.status(order.status),
                color: _tint(context),
              ),
            ],
          ),
          SizedBox(height: spacing.xs),
          Text(
            OrderStrings.placedOn(
              DateFormat.yMMMd(locale).format(order.createdAt),
            ),
            style: context.textTheme.bodySmall?.copyWith(
              color: context.textColors.secondary,
            ),
          ),
          SizedBox(height: spacing.sm),
          Row(
            children: [
              Expanded(
                child: Text(
                  // The count and the unit pluralise together.
                  OrderStrings.items(order.items.length),
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.textColors.secondary,
                  ),
                ),
              ),
              // What was CHARGED, whole, as the server sent it — never
              // a sum of the lines, which would leave out the delivery
              // and disagree with the receipt.
              PriceText(amount: order.totalPrice),
            ],
          ),
        ],
      ),
    );
  }
}
