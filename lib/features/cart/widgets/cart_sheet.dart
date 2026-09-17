import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/animations/animation_presets.dart';
import '../../../core/auth/auth_gate.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/number_formatter.dart';
import '../../../core/localization/strings/auth_strings.dart';
import '../../../core/localization/strings/cart_strings.dart';
import '../../../core/localization/strings/common_strings.dart';
import '../../../core/localization/strings/home_strings.dart';
import '../../../core/localization/strings/shop_strings.dart';
import '../../../core/tokens/extensions.dart';
import '../../../data/models/terracotta/commerce/cart_item.dart';
import '../../../shared/module/buttons/global_filled_button.dart';
import '../../../shared/module/dialog/global_dialog.dart';
import '../../../shared/module/empty_state/global_empty_state.dart';
import '../../../shared/module/sheet/global_sheet.dart';
import '../../../shared/module/toast/global_toast.dart';
import '../../_shared/skeleton_block.dart';
import '../../_shared/terracotta_cta_style.dart';
import '../../_shared/terracotta_image.dart';
import '../../_shared/terracotta_widgets.dart';
import '../../shop/data/stock.dart';
import '../cubits/cart_cubit.dart';
import '../cubits/cart_state.dart';
import '../data/cart_stock_check.dart';
import 'stock_conflict_sheet.dart';

/// «عربيتي» — the cart, as a sheet over whatever you were looking at.
///
/// The cart is emptied when the order is PAID, not at checkout, so
/// backing out of payment must not lose it.
///
/// `GET /api/shop/cart`; quantity and removal are PUT and DELETE on
/// `/api/shop/cart/{item}`, written as those verbs and rewritten to
/// POST by the method-override interceptor.
class CartSheet extends StatefulWidget {
  const CartSheet({this.cubit, super.key});

  /// A cubit to use instead of the app's — the seam a widget test
  /// needs. Null in the app.
  final CartCubit? cubit;

  @override
  State<CartSheet> createState() => _CartSheetState();
}

class _CartSheetState extends State<CartSheet> {
  /// The APP's cart. Not closed here — the badge on every app bar reads
  /// the same one, and this sheet is the shortest-lived thing that
  /// touches it.
  late final _cart = widget.cubit ?? getIt<CartCubit>();

  @override
  void initState() {
    super.initState();
    // Opening the sheet is the moment to be SURE: the badge may have
    // been drawn from a load that happened before the last add.
    unawaited(_openingCheck());
  }

  /// Re-read, then look at what came back.
  ///
  /// The stock check costs NOTHING extra — the server sends `in_stock`
  /// and `available_stock` on every cart line, so the load already
  /// carries the answer. See `docs/api-contract.md` §18.
  Future<void> _openingCheck() async {
    await _cart.load();
    if (!mounted) return;
    await checkCartStock(context, _cart);
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<CartCubit, CartState>(
    bloc: _cart,
    builder: (context, state) => _Body(state: state, cart: _cart),
  );
}

/// Ask about a basket the studio can no longer fill, and act on the
/// answer.
///
/// Runs on OPENING the sheet and again on the pay button, which is the
/// last moment it still matters — stock moves while a basket sits
/// there, and the alternative is a 422 at checkout.
///
/// Returns whether the basket is now safe to check out with.
Future<bool> checkCartStock(BuildContext context, CartCubit cart) async {
  final problems = cart.stockProblems;
  if (problems.isEmpty) return true;

  final decision = await showStockConflictSheet(context, problems: problems);
  if (decision != StockDecision.fix) return false;

  await cart.applyStockFixes();
  if (!context.mounted) return false;
  GlobalToast.success(CartStrings.stockFixed);
  return cart.stockProblems.isEmpty;
}

class _Body extends StatelessWidget {
  const _Body({required this.state, required this.cart});

  final CartState state;
  final CartCubit cart;

  /// The stepper moved. Going BELOW one is a removal, and it asks
  /// first.
  ///
  /// Pressing minus a third time on a line of one is how a customer
  /// loses something without meaning to — the button they have been
  /// pressing to make a number smaller suddenly takes the row away.
  Future<void> _changeQuantity(
    BuildContext context,
    CartItem item,
    int quantity,
  ) async {
    if (quantity >= 1) return cart.setQuantity(item, quantity);

    final confirmed = await GlobalDialog.confirm(
      context: context,
      title: ShopStrings.removeLineTitle,
      // Named, so it is obvious WHICH row is going.
      message: ShopStrings.removeLineMessage(item.product.title),
      confirmText: CommonStrings.remove,
      isDestructive: true,
      icon: Icons.remove_shopping_cart_rounded,
    );
    if (!confirmed) return;
    await cart.removeLine(item);
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    if (state.loading && state.cart == null) return const _CartSkeleton();

    if (state.isEmpty) {
      // A guest gets 401 on this endpoint, which is not a broken screen
      // — it is an empty cart until they sign in. Only a REAL failure
      // with nothing to show gets the error state.
      return state.error != null && state.cart == null
          ? GlobalEmptyState(
              icon: Icons.wifi_off_rounded,
              title: AuthStrings.errorGeneric,
              primaryAction: GlobalFilledButton(
                text: CommonStrings.retry,
                onPressed: () => unawaited(cart.load()),
                style: terracottaCtaStyle(showArrow: false),
              ),
            )
          : GlobalEmptyState(
              title: ShopStrings.cartEmpty,
              icon: Icons.shopping_cart_outlined,
              variant: EmptyStateVariant.compact,
            );
    }

    final items = state.cart!.items;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final item in items) ...[
          CartLineRow(
            item: item,
            busy: state.busyLines.contains(item.id),
            onQuantity: (q) => unawaited(_changeQuantity(context, item, q)),
            onOpen: () {
              Navigator.of(context).pop();
              context.pushNamed(
                'product-detail',
                pathParameters: {'productId': '${item.product.id}'},
              );
            },
          ),
          SizedBox(height: spacing.sm),
        ],
        SizedBox(height: spacing.sm),
        // The label CROSS-FADES when the total moves. A number that
        // changes between two frames is a number nobody sees change —
        // and the total is the whole point of pressing a stepper.
        AnimatedSwitcher(
          duration: AppDurations.quick,
          child: GlobalFilledButton(
            key: ValueKey(state.cart!.totalPrice),
            // The TOTAL is on the button, as the design draws it — «الدفع
            // ١٩٠». It is the cart's own `total_price`, never a sum of
            // the lines computed here: money is decimal on this API.
            // «تاكيد الدفع ١٩٠ ريال» — the amount AND what it is in.
            // A bare number on a pay button is the one place a customer
            // should not have to assume the currency.
            text:
                '${ShopStrings.checkout} '
                '${PriceText.format(state.cart!.totalPrice)} '
                '${HomeStrings.currency}',
            onPressed: () => unawaited(_payPressed(context)),
            style: terracottaCtaStyle(),
          ),
        ),
      ],
    );
  }
}

/// The last check before the money. A basket can sit open while the
/// studio sells the last of something, so the answer at OPENING time is
/// not the answer now — and a 422 at checkout is a worse place to find
/// out.
Future<void> _payPressed(BuildContext context) async {
  // AN ACCOUNT FIRST — and this is the one flow where that cannot wait
  // for the pay button.
  //
  // The booking flow lets a visitor all the way to the seat because
  // `GET /workshops/{id}/availability` and `/price` both answer a
  // guest: they see real numbers before they are asked for anything.
  // The shop has no equivalent. `POST /shop/cart/quote` answers «يجب
  // تسجيل الدخول للقيام بذلك» — probed live on 2026-09-08 — and the
  // delivery fee, the VAT, the discount and the wallet are all computed
  // there. Opening the checkout screen for a guest would mean either
  // totalling a basket in the app, which this codebase does not do with
  // money, or showing a page of blanks and asking them to pay it.
  //
  // So the ask happens here, where the basket is on screen and the copy
  // can say that none of it is lost.
  if (!await AuthGate.demandToFinish(
    context,
    because: AuthStrings.needAccountCart,
  )) {
    return;
  }
  if (!context.mounted) return;

  // AND A CONFIRMED NUMBER — see `AuthGate.demandVerified`. An account
  // the server has not verified cannot place an order, and finding
  // that out at the payment step is worse than being told here.
  if (!await AuthGate.demandVerified(
    context,
    because: AuthStrings.verifyNeededBuy,
  )) {
    return;
  }
  if (!context.mounted) return;

  final cart = getIt<CartCubit>();
  await cart.load();
  if (!context.mounted) return;
  if (!await checkCartStock(context, cart)) return;
  if (!context.mounted) return;

  Navigator.of(context).pop();
  context.pushNamed('shop-checkout');
}

/// One cart line — the product row with a stepper on it.
///
/// The shop's secondary card with quantity added, rather than a third
/// product layout: a customer should recognise the thing they put in
/// the cart from the list they picked it out of.
class CartLineRow extends StatelessWidget {
  const CartLineRow({
    required this.item,
    this.busy = false,
    this.onQuantity,
    this.onOpen,
    super.key,
  });

  final CartItem item;

  /// A write is in flight for THIS line. The stepper goes quiet; the
  /// rest of the sheet stays live.
  final bool busy;

  final ValueChanged<int>? onQuantity;
  final VoidCallback? onOpen;

  /// The picture's WIDTH. Its height comes from the row.
  static const _imageBox = 96.0;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final product = item.product;

    // What the studio can still fill of this line. Null means nothing
    // limits it — 13 of the 15 live products track no stock at all, and
    // reading that as zero would condemn almost every basket.
    final available = item.inStock == false ? 0 : item.availableStock;
    final over = available != null && available < item.quantity;

    return TerracottaCard(
      onTap: onOpen,
      bordered: true,
      // The line the customer has to look at wears the mark. A sheet
      // that says "some pieces ran out" without pointing at them sends
      // them hunting through six rows.
      borderColor: over ? context.statusColors.error : null,
      padding: EdgeInsets.all(spacing.xs),
      // `IntrinsicHeight` + `stretch`: the picture takes the height the
      // WORDS beside it end up needing, instead of a square that leaves
      // a strip of card blank under it whenever a title runs to two
      // lines or a line is on offer.
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: _imageBox,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(context.radii.sm),
                child: TerracottaImage(image: product.image),
              ),
            ),
            SizedBox(width: spacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.titleSmall?.copyWith(
                      color: context.textColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: spacing.xs),
                  // The line's OWN `unit_price`, which is what the server
                  // is charging for it — not the product's list price,
                  // which may have moved since it went in.
                  PriceText(
                    amount: item.unitPrice,
                    was: product.salePrice == null ? null : product.price,
                  ),
                  SizedBox(height: spacing.sm),
                  // The bottom of the card: the tag beside the picture,
                  // the count and its two buttons at the far end — the
                  // design's own arrangement.
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // The tag gives way to the WARNING: a line that
                      // cannot be bought has nothing to gain from being
                      // called featured.
                      if (over)
                        Flexible(child: _OverStock(left: available))
                      else if (product.isFeatured)
                        const _FeaturedTag(),
                      const Spacer(),
                      _Stepper(
                        // DISABLED while this line's write is out, so a
                        // second press cannot race the first.
                        value: item.quantity,
                        enabled: !busy && onQuantity != null,
                        // Capped at what is really left, so the customer
                        // cannot walk further into a refusal.
                        ceiling: available,
                        onChanged: onQuantity ?? (_) {},
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// «عدد ٢» between a minus and a plus.
class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.ceiling,
  });

  /// The most this line may reach — `available_stock`, or null when
  /// nothing limits it.
  final int? ceiling;

  final int value;
  final bool enabled;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    // The count sits ABOVE its two buttons, as the design draws it,
    // and the whole cluster is pinned to the reading END.
    crossAxisAlignment: CrossAxisAlignment.end,
    mainAxisSize: MainAxisSize.min,
    children: [
      AnimatedSwitcher(
        duration: AppDurations.quick,
        child: Text(
          // «عدد ٢» — plain `ar` formats in WESTERN digits, which is
          // why this goes through the localizer.
          ShopStrings.quantity(AppNumbers.localizeDigits('$value')),
          // KEYED on the value, or the switcher has nothing to tell
          // apart and the number changes with no motion at all.
          key: ValueKey(value),
          style: context.textTheme.bodySmall?.copyWith(
            color: context.textColors.secondary,
          ),
        ),
      ),
      SizedBox(height: context.spacing.xs),
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Step(
            icon: Icons.add_rounded,
            semanticLabel: ShopStrings.addToCart,
            // Stops at what the studio has left, and SAYS why. A plus
            // that quietly does nothing feels the same to the thumb as
            // a broken one.
            onTap: !enabled
                ? null
                : (ceiling == null || value < ceiling!)
                ? () => onChanged(value + 1)
                : () => GlobalToast.info(Stock.reachedMessage(ceiling!)),
          ),
          SizedBox(width: context.spacing.xs),
          _Step(
            icon: Icons.remove_rounded,
            semanticLabel: CommonStrings.remove,
            // At ONE the minus REMOVES the line. The endpoint takes a
            // count, and a cart line of nothing is not a thing this API
            // has.
            onTap: enabled ? () => onChanged(value - 1) : null,
          ),
        ],
      ),
    ],
  );
}

class _Step extends StatelessWidget {
  const _Step({required this.icon, required this.semanticLabel, this.onTap});

  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onTap;

  /// From the design — a shade off the card it sits on.
  static const ground = Color(0xFFFAF7F6);
  static const _box = 32.0;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: onTap != null,
    label: semanticLabel,
    excludeSemantics: true,
    // `Material` + `InkWell`, not a bare `GestureDetector`: ink paints
    // on the nearest Material above it, and a `Container` painting its
    // own colour over one swallows the splash — the button worked and
    // looked dead.
    child: Material(
      color: ground,
      borderRadius: BorderRadius.circular(context.radii.sm),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: _box,
          height: _box,
          child: Icon(
            icon,
            size: context.iconSizes.sm,
            // DISABLED while its line's write is out, and nothing more.
            // A spinner in a 32-point square is more motion than the
            // wait deserves.
            color: onTap == null
                ? context.textColors.disabled
                : context.primaryColors.primary,
          ),
        ),
      ),
    ),
  );
}

/// «مميز».
/// «المتبقي ٣ فقط» — the mark on a line the studio can no longer fill.
class _OverStock extends StatelessWidget {
  const _OverStock({required this.left});

  final int left;

  @override
  Widget build(BuildContext context) {
    final ink = context.statusColors.error;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ink.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(context.radii.xs),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Text(
          left <= 0 ? ShopStrings.outOfStock : overLabel(left),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.textTheme.labelSmall?.copyWith(
            color: ink,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _FeaturedTag extends StatelessWidget {
  const _FeaturedTag();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: context.primaryColors.primary,
      borderRadius: BorderRadius.circular(context.radii.xs),
    ),
    child: Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.spacing.xs,
        vertical: 2,
      ),
      child: Text(
        HomeStrings.badgeFeatured,
        style: context.textTheme.labelSmall?.copyWith(
          color: context.textColors.onPrimary,
        ),
      ),
    ),
  );
}

class _CartSkeleton extends StatelessWidget {
  const _CartSkeleton();

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < 3; i++) ...[
          const SizedBox(
            height: 112,
            child: SkeletonBlock(),
          ),
          SizedBox(height: spacing.sm),
        ],
      ],
    );
  }
}

/// Opens [CartSheet] over whatever is on screen.
Future<void> showCartSheet(BuildContext context, {CartCubit? cubit}) =>
    GlobalBottomSheet.show<void>(
      context: context,
      title: ShopStrings.myCart,
      content: CartSheet(cubit: cubit),
    );
