import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/auth/account_scope.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/strings/auth_strings.dart';
import '../../../core/localization/strings/checkout_strings.dart';
import '../../../core/localization/strings/common_strings.dart';
import '../../../core/localization/strings/home_strings.dart';
import '../../../core/localization/strings/order_strings.dart';
import '../../../core/localization/strings/profile_strings.dart';
import '../../../core/tokens/extensions.dart';
import '../../../data/models/terracotta/commerce/order.dart';
import '../../../data/models/terracotta/commerce/order_item.dart';
import '../../../data/models/terracotta/commerce/order_status.dart';
import '../../../shared/module/buttons/global_filled_button.dart';
import '../../../shared/module/container/global_container.dart';
import '../../../shared/module/dialog/global_dialog.dart';
import '../../../shared/module/empty_state/global_empty_state.dart';
import '../../../shared/module/refreshable/global_refreshable.dart';
import '../../../shared/module/scrollable/global_scrollable.dart';
import '../../../shared/module/toast/global_toast.dart';
import '../../_shared/address_summary.dart';
import '../../_shared/screen_entrance.dart';
import '../../_shared/terracotta_cta_style.dart';
import '../../_shared/terracotta_image.dart';
import '../../_shared/terracotta_page_bar.dart';
import '../../_shared/terracotta_widgets.dart';
import '../cubits/order_detail_cubit.dart';

/// One shop order — what was bought, what it cost, and where it is
/// going.
///
/// `GET /api/shop/orders/{order}`, and the two things that can be done
/// to it: settle it while it is `awaiting_payment`, or cancel it while
/// the server says `can_cancel`. Cancel is written as DELETE and
/// rewritten to POST by the method-override interceptor, because
/// production blocks the verb.
///
/// **Every figure is the server's.** The breakdown is read off the
/// order — subtotal, discount, delivery, wallet, what is left — and
/// nothing on this page adds two money strings together. `vat_amount`
/// is the tax already INSIDE `total_price`; it is disclosed under the
/// total, never added to it.
///
/// **A cancel refunds to the WALLET, not the card**, which is what the
/// confirm copy says rather than promising a card refund the studio
/// does not make.
class OrderDetailPage extends StatefulWidget {
  const OrderDetailPage({this.orderId, this.cubit, super.key});

  /// The `:orderId` from the route. Null after a hot restart, where the
  /// page has nothing to ask for and says so.
  final String? orderId;

  /// A cubit to use instead of making one — the seam a widget test
  /// needs, since the page loads on mount. Null in the app.
  final OrderDetailCubit? cubit;

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  late final OrderDetailCubit? _order =
      widget.cubit ??
      (widget.orderId == null
          ? null
          : OrderDetailCubit(orderId: widget.orderId!));

  @override
  void initState() {
    super.initState();
    // A PUSH ABOUT THIS ORDER lands while it is on screen — see
    // [AccountScope.revision].
    AccountScope.revision.addListener(_onOwnedChanged);
    // Only when this page MADE one — a handed-in cubit is the test's,
    // and loading it twice would double every recorded call.
    if (widget.cubit == null) unawaited(_order?.load());
  }

  void _onOwnedChanged() {
    if (mounted) unawaited(_order?.load() ?? Future<void>.value());
  }

  @override
  void dispose() {
    AccountScope.revision.removeListener(_onOwnedChanged);
    if (widget.cubit == null) unawaited(_order?.close());
    super.dispose();
  }

  Future<void> _pay() async {
    final cubit = _order;
    if (cubit == null) return;

    final paid = await cubit.pay();
    if (!mounted) return;

    if (!paid) {
      // The hold may simply have run out, in which case the order is
      // gone and so is the wallet amount. Either way the words are the
      // server's.
      GlobalToast.error(
        cubit.state.error?.spokenMessage ?? AuthStrings.errorGeneric,
      );
      return;
    }
    GlobalToast.success(CommonStrings.success);
    // THE MONEY MOVED. Since 2026-09-13 a cancelled paid order credits
    // the WHOLE total — goods, delivery and VAT — to the wallet, not
    // just the slice that was paid from it. The balance shown
    // everywhere else comes from a `getIt` singleton that only re-asks
    // on a language change, and the live strip is still carrying this
    // order.
    AccountScope.ownedChanged();
  }

  Future<void> _cancel() async {
    final cubit = _order;
    if (cubit == null) return;

    final sure = await GlobalDialog.confirm(
      context: context,
      title: OrderStrings.cancelTitle,
      // WHERE the money goes, not HOW MUCH. Promising a card refund
      // here would be a promise the studio does not keep, and
      // promising an amount would be one the app cannot size — the
      // server's `refunded_amount` is the only honest number and it
      // does not exist until the cancel has run.
      message: OrderStrings.cancelBody,
      confirmText: OrderStrings.cancelYes,
      cancelText: OrderStrings.cancelNo,
      isDestructive: true,
    );
    if (!sure || !mounted) return;

    final done = await cubit.cancel();
    if (!mounted) return;

    if (!done) {
      GlobalToast.error(
        cubit.state.error?.spokenMessage ?? AuthStrings.errorGeneric,
      );
      return;
    }
    // WHAT ACTUALLY CAME BACK. `refunded_amount` is the auditable
    // record; `null` is not zero — it means nothing was ever paid, an
    // abandoned hold — so a null says nothing about money rather than
    // claiming a refund of nothing.
    final refunded = cubit.state.order?.refundedAmount;
    GlobalToast.success(
      refunded == null || refunded.isEmpty || refunded == '0.00'
          ? CommonStrings.success
          : OrderStrings.cancelRefunded(
              '${PriceText.format(refunded)} ${HomeStrings.currency}',
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final cubit = _order;

    // A hot restart takes the path parameter with it, and there is
    // nothing to ask the server for.
    if (cubit == null) {
      return Scaffold(
        backgroundColor: context.backgroundColors.scaffoldBackground,
        appBar: TerracottaPageBar(title: ProfileStrings.orderDetail),
        body: Center(
          child: GlobalEmptyState(
            icon: Icons.receipt_long_outlined,
            title: OrderStrings.notFound,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: context.backgroundColors.scaffoldBackground,
      // The app's own bar, like every other pushed page.
      appBar: TerracottaPageBar(title: ProfileStrings.orderDetail),
      body: BlocBuilder<OrderDetailCubit, OrderDetailState>(
        bloc: cubit,
        builder: (context, state) => GlobalRefreshable(
          onRefresh: cubit.refresh,
          child: GlobalScrollable(
            // The CALLER has to ask, or a page shorter than the
            // viewport drops the drag recogniser.
            physics: const AlwaysScrollableScrollPhysics(),
            child: GlobalContainer.shell(
              padding: EdgeInsetsDirectional.fromSTEB(
                spacing.md,
                spacing.md,
                spacing.md,
                spacing.xxl,
              ),
              child: _Body(state: state),
            ),
          ),
        ),
      ),
      bottomNavigationBar: BlocBuilder<OrderDetailCubit, OrderDetailState>(
        bloc: cubit,
        builder: (context, state) => _Actions(
          state: state,
          onPay: () => unawaited(_pay()),
          onCancel: () => unawaited(_cancel()),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.state});

  final OrderDetailState state;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final order = state.order;

    if (order == null) {
      if (state.loading) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 120),
          child: Center(child: CircularProgressIndicator.adaptive()),
        );
      }
      return ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 360),
        child: Center(
          child: GlobalEmptyState(
            icon: Icons.wifi_off_rounded,
            title: AuthStrings.errorGeneric,
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
        _Header(order: order),
        SizedBox(height: spacing.lg),
        SectionHeader(title: OrderStrings.itemsHeading),
        SizedBox(height: spacing.sm),
        for (final item in order.items) ...[
          _ItemRow(item: item),
          SizedBox(height: spacing.sm),
        ],
        SizedBox(height: spacing.sm),
        _Breakdown(order: order),
        // Only when there IS one. An order with no address line is a
        // payload that did not carry it, not an order going nowhere.
        if (order.deliveryAddress != null ||
            order.deliveryNotes != null ||
            order.deliveryShortAddress != null) ...[
          SizedBox(height: spacing.lg),
          SectionHeader(title: OrderStrings.deliveryHeading),
          SizedBox(height: spacing.sm),
          _Delivery(order: order),
        ],
      ]),
    );
  }
}

/// What the order IS: its number, where it got to, and when.
class _Header extends StatelessWidget {
  const _Header({required this.order});

  final Order order;

  /// Three answers, not seven — still owed, finished, or on its way.
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
    final date = DateFormat.yMMMd(locale);

    return TerracottaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  OrderStrings.number('${order.id}'),
                  style: context.textTheme.titleLarge?.copyWith(
                    color: context.textColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              StatusChip(
                // MAPPED. The wire sends `out_for_delivery`, and no
                // customer should ever read that.
                label: OrderStrings.status(order.status),
                color: _tint(context),
              ),
            ],
          ),
          SizedBox(height: spacing.xs),
          Text(
            OrderStrings.placedOn(date.format(order.createdAt)),
            style: context.textTheme.bodySmall?.copyWith(
              color: context.textColors.secondary,
            ),
          ),
          // The clock on an unpaid order. After it the server releases
          // the order and gives the wallet amount back.
          if (order.status.needsPayment &&
              !order.isAlreadySettled &&
              order.paymentExpiresAt != null) ...[
            SizedBox(height: spacing.xs),
            Text(
              OrderStrings.payBefore(
                DateFormat.yMMMd(
                  locale,
                ).add_jm().format(order.paymentExpiresAt!),
              ),
              style: context.textTheme.bodySmall?.copyWith(
                color: context.statusColors.warning,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (order.cancelledAt case final cancelled?) ...[
            SizedBox(height: spacing.xs),
            Text(
              OrderStrings.cancelledOn(date.format(cancelled)),
              style: context.textTheme.bodySmall?.copyWith(
                color: context.statusColors.error,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// One line of the order: the photograph, what it was, and what it
/// came to.
class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item});

  final OrderItem item;

  /// The row's height comes from the picture.
  static const _imageBox = 88.0;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    return TerracottaCard(
      padding: EdgeInsets.all(spacing.xs),
      child: Row(
        // START, never stretch: in a scrolling column stretch has no
        // height to stretch TO and the row resolves to infinity.
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(context.radii.sm),
            child: SizedBox(
              width: _imageBox,
              height: _imageBox,
              child: TerracottaImage(image: item.product.image),
            ),
          ),
          SizedBox(width: spacing.md),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: spacing.xs),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    // The server's own name for it, already localized.
                    item.product.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.titleSmall?.copyWith(
                      color: context.textColors.primary,
                    ),
                  ),
                  SizedBox(height: spacing.xs),
                  Text(
                    // The count and the UNIT price, so the total beside
                    // it is checkable rather than asserted.
                    OrderStrings.quantity(
                      item.quantity,
                      '${PriceText.format(item.unitPrice)} '
                      '${HomeStrings.currency}',
                    ),
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.textColors.secondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: spacing.sm),
          Padding(
            padding: EdgeInsets.symmetric(vertical: spacing.xs),
            // The SERVER's line total. Multiplying the unit price by
            // the count here would round differently from the receipt.
            child: PriceText(amount: item.lineTotal),
          ),
        ],
      ),
    );
  }
}

/// What it cost, in the order the server applied it.
class _Breakdown extends StatelessWidget {
  const _Breakdown({required this.order});

  final Order order;

  bool get _hasDiscount => order.discountAmount != '0.00';
  bool get _hasWallet => order.walletApplied != '0.00';
  bool get _hasVat => (order.vatAmount ?? '0.00') != '0.00';

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    return TerracottaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Line(label: CheckoutStrings.subtotal, amount: order.subtotal),
          if (_hasDiscount) ...[
            SizedBox(height: spacing.sm),
            _Line(
              label: CheckoutStrings.discount,
              amount: order.discountAmount,
              // The one line that comes OFF, so it is signed and tinted
              // rather than reading as another charge.
              negative: true,
            ),
          ],
          if (order.deliveryFee case final fee?) ...[
            SizedBox(height: spacing.sm),
            _Line(label: CheckoutStrings.deliveryFee, amount: fee),
          ],
          SizedBox(height: spacing.sm),
          Divider(color: context.primaryColors.border, height: 1),
          SizedBox(height: spacing.sm),
          _Line(
            label: CheckoutStrings.total,
            amount: order.totalPrice,
            strong: true,
          ),
          if (_hasVat) ...[
            SizedBox(height: spacing.xs),
            Text(
              // INSIDE the total, never added to it — and the rate is
              // read from the payload rather than hardcoded, because
              // the studio sets it.
              CheckoutStrings.vat(PriceText.format(order.vatRate ?? '0')),
              textAlign: TextAlign.end,
              style: context.textTheme.bodySmall?.copyWith(
                color: context.textColors.secondary,
              ),
            ),
          ],
          if (_hasWallet) ...[
            SizedBox(height: spacing.sm),
            _Line(
              label: CheckoutStrings.walletApplied,
              amount: order.walletApplied,
              negative: true,
            ),
            SizedBox(height: spacing.sm),
            _Line(
              label: CheckoutStrings.amountDue,
              amount: order.amountDue,
              strong: true,
            ),
          ],
        ],
      ),
    );
  }
}

/// Where it is going — the SAME shape «عناويني» draws a place in.
///
/// This was four stacked label-over-value rows, so one address read as
/// a form here and as a place there. It is the place version now; see
/// [AddressSummary].
///
/// **The line is the server's, whole.** `delivery_address` arrives
/// already composed — `"8228, Prince Turki Road, Unit 12, Al
/// Muhammadiyah, Riyadh, 12362, 2933"` — and the order carries no
/// structured fields behind it. Splitting that back into a building
/// number and a street would be guessing at a format the server is
/// free to change, so it is printed as one line and only the facts the
/// order really holds are drawn as chips.
class _Delivery extends StatelessWidget {
  const _Delivery({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) => TerracottaCard(
    child: AddressSummary(
      // The ZONE names the place, since an order has no label of its
      // own — «الرياض» over the line that spells it out. Without one
      // the line leads: the card is already under «التوصيل», and
      // repeating that heading inside it says nothing twice.
      title: order.deliveryZone,
      line: order.deliveryAddress ?? '',
      facts: [
        // The national short address, when the customer gave one — a
        // courier can enter it directly.
        if (order.deliveryShortAddress case final short?
            when short.trim().isNotEmpty)
          AddressFact(short, icon: Icons.pin_drop_rounded),
        if (order.deliveryZone case final zone?)
          AddressFact(zone, icon: Icons.local_shipping_rounded),
      ],
      // E.164, and shown as received — it is what the courier dials.
      phone: order.deliveryPhone,
      notes: order.deliveryNotes,
    ),
  );
}

/// One row of the breakdown.
class _Line extends StatelessWidget {
  const _Line({
    required this.label,
    required this.amount,
    this.strong = false,
    this.negative = false,
  });

  final String label;
  final String amount;
  final bool strong;
  final bool negative;

  @override
  Widget build(BuildContext context) {
    final style = strong
        ? context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)
        : context.textTheme.bodyMedium;

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: style?.copyWith(color: context.textColors.primary),
          ),
        ),
        Text(
          '${negative ? '−' : ''}${PriceText.format(amount)} '
          '${HomeStrings.currency}',
          style: style?.copyWith(
            color: negative
                ? context.statusColors.success
                : context.textColors.primary,
            fontWeight: strong ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// What can still be DONE to this order — and nothing when the answer
/// is nothing, rather than a disabled bar taking up the foot of the
/// screen.
class _Actions extends StatelessWidget {
  const _Actions({
    required this.state,
    required this.onPay,
    required this.onCancel,
  });

  final OrderDetailState state;
  final VoidCallback onPay;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    if (!state.canPay && !state.canCancel) return const SizedBox.shrink();

    return Material(
      color: context.backgroundColors.scaffoldBackground,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(
            spacing.md,
            spacing.sm,
            spacing.md,
            spacing.sm,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (state.canPay)
                GlobalFilledButton(
                  text: OrderStrings.payNow,
                  isLoading: state.working,
                  onPressed: onPay,
                  style: terracottaCtaStyle(showArrow: false),
                ),
              if (state.canPay && state.canCancel) SizedBox(height: spacing.sm),
              // The server's own verdict on whether the window is
              // still open — never derived from the status.
              if (state.canCancel)
                GlobalFilledButton(
                  text: OrderStrings.cancel,
                  isLoading: state.working && !state.canPay,
                  onPressed: onCancel,
                  // SOFT, not loud: cancelling is the destructive
                  // choice and must not be the brightest thing on the
                  // screen.
                  style: terracottaCtaStyle(showArrow: false).copyWith(
                    // The same soft-red pair the cancel-booking dialog
                    // wears, so the two destructive choices in the app
                    // read as one gesture.
                    backgroundColor: context.statusColors.error.withValues(
                      alpha: 0.16,
                    ),
                    textStyle: TextStyle(
                      fontSize: kTerracottaCtaLabelSize,
                      color: context.statusColors.error,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
