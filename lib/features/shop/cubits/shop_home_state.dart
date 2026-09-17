import 'package:flutter/foundation.dart';

import '../../../core/error/app_exception.dart';
import '../../../data/models/terracotta/shop/shop_category.dart';
import '../../../data/models/terracotta/shop/shop_home.dart';

/// What the shop landing knows. Same three states as the other tabs.
@immutable
sealed class ShopHomeState {
  const ShopHomeState();
}

final class ShopHomeLoading extends ShopHomeState {
  const ShopHomeLoading();
}

final class ShopHomeLoaded extends ShopHomeState {
  const ShopHomeLoaded(
    this.payload, {
    this.categories = const [],
    this.query = '',
  });

  final ShopHome payload;

  /// The category TREE, merged.
  ///
  /// Two endpoints answer about categories and neither is complete:
  /// `GET /api/shop/home` carries an `image` per category but no
  /// sub-categories, and `GET /api/shop/categories` carries
  /// `sub_categories` and omits `image` entirely — not null, absent
  /// from the row. Verified live on all four.
  ///
  /// So the tree is assembled once, here, and every screen that shows
  /// a category reads it: the landing's rail, and the browse screen's,
  /// which used to fetch its own and lose the artwork doing it.
  final List<ShopCategory> categories;

  /// What the reader has typed into the bar.
  ///
  /// Filtering happens HERE rather than in another request: everything
  /// this screen shows is already in the payload, and going back to the
  /// server for a subset of what is on the device would put a spinner
  /// on every keystroke. The browse screen searches the SERVER,
  /// because there the catalogue is bigger than the page.
  final String query;

  /// The payload with everything that does not match [query] removed.
  ShopHome get filtered {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return payload;
    bool matches(String title) => title.toLowerCase().contains(needle);
    return payload.copyWith(
      categories: [
        for (final c in payload.categories)
          if (matches(c.title)) c,
      ],
      featuredProducts: [
        for (final p in payload.featuredProducts)
          if (matches(p.title)) p,
      ],
      offers: [
        for (final p in payload.offers)
          if (matches(p.title)) p,
      ],
    );
  }

  /// Whether a search is on and matched nothing at all.
  bool get isEmptySearch =>
      query.trim().isNotEmpty &&
      filtered.categories.isEmpty &&
      filtered.featuredProducts.isEmpty &&
      filtered.offers.isEmpty;
}

final class ShopHomeFailed extends ShopHomeState {
  const ShopHomeFailed(this.error);

  final AppException error;
}
