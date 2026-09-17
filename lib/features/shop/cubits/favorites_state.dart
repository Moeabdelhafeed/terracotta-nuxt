import 'package:flutter/foundation.dart';

import '../../../core/error/app_exception.dart';
import '../../../data/models/terracotta/shop/product.dart';

/// What the favourites sheet knows.
@immutable
sealed class FavoritesState {
  const FavoritesState();
}

final class FavoritesLoading extends FavoritesState {
  const FavoritesLoading();
}

final class FavoritesLoaded extends FavoritesState {
  const FavoritesLoaded(this.products);

  final List<Product> products;
}

final class FavoritesFailed extends FavoritesState {
  const FavoritesFailed(this.error);

  final AppException error;
}
