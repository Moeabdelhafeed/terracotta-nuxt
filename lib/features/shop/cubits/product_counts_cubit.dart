import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/types/result.dart';
import '../../../data/api/calls/shop_apis.dart';
import '../../../data/models/terracotta/shop/product_page.dart';

typedef ProductCountFetch =
    AsyncResult<ProductPage> Function({
      required int page,
      int perPage,
      int? categoryId,
      int? subCategoryId,
      bool? featured,
      bool? onSale,
      String? search,
      CancelToken? cancelToken,
      Duration? timeout,
    });

/// How many pieces are behind «عرض الكل».
///
/// ## Why not count the rail
///
/// `GET /api/home` and `GET /api/shop/home` each carry a HANDFUL of
/// featured pieces and a handful of offers — the rail, not the answer.
/// Counting what arrived would print the length of the rail, and the
/// button promises the list it opens. That list is
/// `GET /api/shop/products?featured=1`, so the count comes from the
/// same query: `per_page=1` makes the server answer with a Laravel
/// paginator whose `total` is the whole set, and one product row is
/// the smallest page it will send.
///
/// Probed live on 2026-09-08: `featured=1` → `total: 4`,
/// `on_sale=1` → `total: 5`, against fifteen products in all.
///
/// ## Unknown is a NUMBER-LESS button, not a zero
///
/// Both counts start null and stay null if the request fails, and the
/// header falls back to «عرض الكل» with nothing after it. A «(٠)» on a
/// rail with four pieces on it would be worse than saying nothing, and
/// a failed count must never be able to take the home page with it.
///
/// **A `getIt` SINGLETON, and NOT locale-scoped.** Two pages ask for
/// it — the home tab and the shop tab — and `context.go` tears each
/// one's `State` down. A count reads the same in both languages, so a
/// language switch is not a reason to ask again.
@immutable
class ProductCounts {
  const ProductCounts({this.featured, this.onSale, this.loading = false});

  /// How many pieces the studio has marked «مميز». Null until the
  /// count has landed, and after one that failed.
  final int? featured;

  /// How many are on offer.
  final int? onSale;

  final bool loading;

  /// Whether either number is worth printing.
  bool get hasAny => featured != null || onSale != null;
}

class ProductCountsCubit extends Cubit<ProductCounts> {
  ProductCountsCubit({ProductCountFetch? fetch})
    : _fetch = fetch ?? ShopApis.getProductsPage,
      super(const ProductCounts());

  final ProductCountFetch _fetch;
  final _cancel = CancelToken();

  /// Whether the pair has been asked for at all. A FAILED answer counts
  /// as asked: the pages call this on every mount, and retrying two
  /// requests on every tab switch would spend the reader's connection
  /// on a parenthesis.
  bool _asked = false;

  /// Once per launch. [refresh] is what a pull-to-refresh runs.
  Future<void> ensureLoaded() async {
    if (_asked || state.loading) return;
    await refresh();
  }

  Future<void> refresh() async {
    _asked = true;
    emit(
      ProductCounts(
        featured: state.featured,
        onSale: state.onSale,
        loading: true,
      ),
    );

    // TOGETHER. They are two questions about the same shelf and the
    // header draws both at once — asked in turn, the second number
    // appears after the first and the row re-lays itself twice.
    final answers = await Future.wait([
      _count(featured: true),
      _count(onSale: true),
    ]);
    if (isClosed) return;

    emit(ProductCounts(featured: answers[0], onSale: answers[1]));
  }

  /// The `total` for one filter, or null when the request failed.
  Future<int?> _count({bool? featured, bool? onSale}) async {
    final result = await _fetch(
      page: 1,
      // The smallest page the endpoint will answer with. `per_page` is
      // also what turns `data` into the paginator that carries the
      // count at all — see [ProductPage].
      perPage: 1,
      featured: featured,
      onSale: onSale,
      cancelToken: _cancel,
    );
    return switch (result) {
      Success(:final value) => value.total,
      Failure() => null,
    };
  }

  @override
  Future<void> close() {
    _cancel.cancel('product counts closed');
    return super.close();
  }
}
