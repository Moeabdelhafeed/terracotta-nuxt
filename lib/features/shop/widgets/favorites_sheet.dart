import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/localization/strings/auth_strings.dart';
import '../../../core/localization/strings/common_strings.dart';
import '../../../core/localization/strings/shop_strings.dart';
import '../../../core/tokens/extensions.dart';
import '../../../core/types/result.dart';
import '../../../data/blocs/auth/auth_bloc.dart';
import '../../../data/models/terracotta/shop/product.dart';
import '../../../shared/module/buttons/global_filled_button.dart';
import '../../../shared/module/empty_state/global_empty_state.dart';
import '../../../shared/module/list/global_list.dart';
import '../../../shared/module/scrollable/scroll_in_style.dart';
import '../../../shared/module/sheet/global_sheet.dart';
import '../../_shared/favorite_writer.dart';
import '../../_shared/favorites_registry.dart';
import '../../_shared/terracotta_cta_style.dart';
import '../cubits/favorites_cubit.dart';
import '../cubits/favorites_state.dart';
import '../data/guest_wishlist.dart';
import 'favorite_product_row.dart';

/// «منتجاتي المفضلة» — the saved list behind the heart.
///
/// `GET /api/shop/favorites`, which needs a SESSION: a guest gets 401,
/// and that surfaces here as the error state rather than an empty one —
/// "you have saved nothing" and "we could not ask" are different
/// sentences.
class FavoritesSheet extends StatefulWidget {
  const FavoritesSheet({this.cubit, this.registry, super.key});

  /// The app's record of what is favourited, so removing a row here
  /// reaches the rails behind the sheet.
  final FavoritesRegistry? registry;

  /// A cubit to use instead of making one — the seam a widget test
  /// needs, since the sheet loads on mount. Null in the app.
  final FavoritesCubit? cubit;

  @override
  State<FavoritesSheet> createState() => _FavoritesSheetState();
}

class _FavoritesSheetState extends State<FavoritesSheet> {
  /// `load` outside the `??`: an injected cubit has to be loaded too,
  /// or a fixture is never asked and the sheet measures placeholders.
  late final _favorites =
      (widget.cubit ?? FavoritesCubit(registry: widget.registry))..load();

  @override
  void dispose() {
    // Only what this sheet MADE.
    if (widget.cubit == null) unawaited(_favorites.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    return BlocBuilder<FavoritesCubit, FavoritesState>(
      bloc: _favorites,
      builder: (context, state) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          switch (state) {
            FavoritesLoading() => const _Busy(),
            FavoritesFailed(:final error) => GlobalEmptyState(
              icon: Icons.wifi_off_rounded,
              title: AuthStrings.errorGeneric,
              // Transport failures carry Dio's wording, which names
              // hosts and sockets and means nothing to a customer.
              subtitle: error is NetworkException ? null : error.message,
              variant: EmptyStateVariant.compact,
            ),
            FavoritesLoaded(:final products) when products.isEmpty =>
              GlobalEmptyState(
                title: ShopStrings.favoritesEmpty,
                icon: Icons.favorite_border_rounded,
                variant: EmptyStateVariant.compact,
              ),
            FavoritesLoaded(:final products) => _FavoritesList(
              products: products,
              onForget: (id) => unawaited(_favorites.unfavorite(id)),
            ),
          },
          SizedBox(height: spacing.md),
          // The design closes this sheet with a full-width bar of its
          // own, on top of the module's own close button — the list can
          // be long, and a control at the top is a scroll away by the
          // time the reader is done with it.
          GlobalFilledButton(
            text: CommonStrings.close,
            onPressed: () => Navigator.of(context).maybePop(),
            style: terracottaCtaStyle(showArrow: false),
          ),
        ],
      ),
    );
  }
}

/// The saved rows.
class _FavoritesList extends StatelessWidget {
  const _FavoritesList({required this.products, required this.onForget});

  final List<Product> products;
  final ValueChanged<int> onForget;

  @override
  Widget build(BuildContext context) => GlobalList<Product>.static(
    items: products,
    // The SHEET scrolls, not the list inside it — two scrollables here
    // would fight over the drag that dismisses the sheet.
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    // A quiet fade as the rows land. This is a SHEET — it is already
    // arriving — so a second, louder motion inside it competes with
    // its own.
    style: const ListStyle(
      padding: EdgeInsets.zero,
      scrollIn: ScrollInStyle.subtle,
    ),
    separatorBuilder: (_, _) => SizedBox(height: context.spacing.sm),
    itemBuilder: (context, product, index) => FavoriteProductRow(
      product: product,
      onUnfavorite: () => onForget(product.id),
      // The sheet CLOSES first: it is a modal over the page the reader
      // came from, and leaving it open behind a pushed screen means
      // coming back to a sheet they had finished with.
      onTap: () {
        Navigator.of(context).pop();
        context.pushNamed(
          'product-detail',
          pathParameters: {'productId': '${product.id}'},
        );
      },
    ),
  );
}

/// Placeholders in the shape the rows will take.
class _Busy extends StatelessWidget {
  const _Busy();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 48),
    child: Center(child: CircularProgressIndicator.adaptive()),
  );
}

/// Opens [FavoritesSheet] over the shop.
///
/// Through `GlobalBottomSheet`, which draws the grab handle, the title
/// row and the close button itself — the body must not draw any of
/// them, or there are two of each.
Future<void> showFavoritesSheet(
  BuildContext context, {
  FavoritesCubit? cubit,
  FavoritesRegistry? registry,
}) => GlobalBottomSheet.show<void>(
  context: context,
  title: ShopStrings.myFavorites,
  content: FavoritesSheet(
    cubit: cubit ?? _forReader(registry),
    registry: registry,
  ),
);

/// The list this reader actually has.
///
/// `GET /api/shop/favorites` answers 401 for a guest, so theirs is the
/// one on the device. Built HERE rather than inside `FavoritesCubit`,
/// which deliberately keeps `getIt` out of its own defaults so a test
/// need not stand the container up.
FavoritesCubit? _forReader(FavoritesRegistry? registry) {
  if (!getIt.isRegistered<AuthBloc>() ||
      !getIt.isRegistered<GuestWishlist>() ||
      getIt<AuthBloc>().isAuthenticated) {
    return null;
  }
  final wishlist = getIt<GuestWishlist>()..load();
  return FavoritesCubit(
    fetch: ({cancelToken}) async => Success(wishlist.items),
    favorites: FavoriteWriter(
      registry: registry ?? FavoritesRegistry(),
      wishlist: wishlist,
    ),
    registry: registry,
  );
}
