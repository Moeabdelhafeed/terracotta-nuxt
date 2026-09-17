import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/assets/assets.dart';
import '../../core/di/service_locator.dart';
import '../../core/localization/strings/shop_strings.dart';
import '../../shared/module/buttons/global_icon_button.dart';
import '../cart/cubits/cart_cubit.dart';
import '../cart/cubits/cart_state.dart';
import '../cart/widgets/cart_sheet.dart';
import '../shell/widgets/terracotta_app_bar.dart';
import 'terracotta_count_badge.dart';

/// The cart, as one widget, so every bar that carries it carries the
/// SAME one.
///
/// It sits beside the language toggle and the bell on every screen that
/// has them: it is the one control a customer looks for from anywhere
/// in a shop, and having it on the product screen alone meant leaving
/// the page you were buying from to find what you had already picked
/// up.
class TerracottaCartAction extends StatefulWidget {
  const TerracottaCartAction({this.cubit, super.key});

  /// A cart to read instead of the app's — the seam a widget test
  /// needs. Null in the app.
  final CartCubit? cubit;

  /// The hero tag the cart wears, so a piece flying into it has
  /// somewhere to land. One per app, because only one bar is ever on
  /// screen.
  static const heroTag = 'terracotta-cart-action';

  @override
  State<TerracottaCartAction> createState() => _TerracottaCartActionState();
}

class _TerracottaCartActionState extends State<TerracottaCartAction> {
  late final _cart = widget.cubit ?? getIt<CartCubit>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Once per LANGUAGE. The badge is on every bar in the app, so this
    // would otherwise re-ask on every screen the reader walks through —
    // but a cart line carries the product's server-written name, and
    // nothing else would re-ask it after a switch.
    unawaited(
      _cart.ensureLoaded(Localizations.localeOf(context).languageCode),
    );
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<CartCubit, CartState>(
    bloc: _cart,
    // Only the COUNT matters here — a line going busy elsewhere in
    // the sheet must not repaint the bar.
    buildWhen: (a, b) => a.pieceCount != b.pieceCount,
    builder: (context, state) => Stack(
      clipBehavior: Clip.none,
      children: [
        GlobalIconButton(
          iconPath: Assets.icons.cart.defaultPath,
          onPressed: () => unawaited(showCartSheet(context)),
          semanticLabel: ShopStrings.myCart,
          // SMALL. The default box is sized for a labelled button;
          // on a bare glyph it reads as a slab.
          size: ButtonSize.small,
          style: ButtonStateStyle(
            backgroundColor: TerracottaAppBar.plate(context),
            foregroundColor: TerracottaAppBar.glyph(context),
          ),
        ),
        // How many PIECES are in the cart — two of one cup is two.
        if (state.pieceCount > 0)
          PositionedDirectional(
            top: TerracottaCountBadge.top,
            end: TerracottaCountBadge.end,
            child: IgnorePointer(
              child: TerracottaCountBadge(count: state.pieceCount),
            ),
          ),
      ],
    ),
  );
}
