import 'package:flutter/foundation.dart';

import '../../../core/error/app_exception.dart';
import '../../../data/models/terracotta/shop/product_detail.dart';

/// What the product detail screen knows.
///
/// A SEALED family here, unlike the browse screen: this page has
/// nothing to show until the one request lands — no rails that stay put
/// while something below them reloads — so "loading" and "loaded" are
/// genuinely different screens.
@immutable
sealed class ProductDetailState {
  const ProductDetailState();
}

class ProductDetailLoading extends ProductDetailState {
  const ProductDetailLoading();
}

class ProductDetailFailed extends ProductDetailState {
  const ProductDetailFailed(this.error);

  final AppException error;
}

class ProductDetailLoaded extends ProductDetailState {
  const ProductDetailLoaded(this.product);

  final ProductDetail product;
}
