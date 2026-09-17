import 'package:dio/dio.dart';

import '../../../core/types/result.dart';
import '../../models/terracotta/shop/product.dart';
import '../../models/terracotta/shop/product_detail.dart';
import '../../models/terracotta/shop/product_page.dart';
import '../../models/terracotta/shop/shop_category.dart';
import '../api_service.dart';
import '../endpoints/terracotta_endpoints.dart';
import 'shop_apis.dart';

/// Raw materials and tools — the studio's second storefront.
///
/// Clay, glazes, tools. Three public read endpoints and nothing else,
/// because **there is no materials cart, checkout or order history**:
/// a material goes into [ShopApis.addToCart] like any other product,
/// and a basket holding a mug and a bag of clay checks out as ONE
/// order with ONE delivery fee.
///
/// The wire is the shop's, byte for byte — verified live on
/// 2026-09-14, including the nested `image` object, `sub_categories`,
/// `max_quantity` and the `related_products` on a detail. That is why
/// [Product], [ProductDetail], [ShopCategory] and [ProductSort] are
/// reused rather than copied: a divergence here is a bug in one of the
/// two storefronts, not a second shape to model.
///
/// **Money is a decimal STRING** (`"90.00"`). Never parse it.
class MaterialApis {
  MaterialApis._();

  // ─── Per-endpoint log flags ───────────────────────────────

  static ApiLogConfig logGetCategories = kApiLogVerbose;
  static ApiLogConfig logGetProducts = kApiLogVerbose;
  static ApiLogConfig logGetProduct = kApiLogVerbose;

  // ─── API methods ──────────────────────────────────────────

  /// The material category tree. Public; no token needed.
  static AsyncResult<List<ShopCategory>> getCategories({
    CancelToken? cancelToken,
    Duration? timeout,
  }) => ApiService.call(
    () => ApiService().getList<ShopCategory>(
      TerracottaEndpoints.materialCategories,
      fromJson: ShopCategory.fromJson,
      logRequest: logGetCategories.request,
      logResponse: logGetCategories.response,
      cancelToken: cancelToken,
      timeout: timeout,
    ),
  );

  /// Material listing. Every filter the shop's listing takes.
  ///
  /// TRAP — leave [perPage] null. Unpaginated, `data` is a plain array
  /// and parses as this list. Pass a numeric `per_page` and the
  /// backend swaps `data` for a Laravel paginator whose rows move to
  /// `data.data`; [getProductsPage] is the one that unwraps it.
  static AsyncResult<List<Product>> getProducts({
    int? categoryId,
    int? subCategoryId,
    bool? featured,
    bool? onSale,
    String? search,
    ProductSort? sort,
    num? minPrice,
    num? maxPrice,
    int? perPage,
    int? page,
    CancelToken? cancelToken,
    Duration? timeout,
  }) => ApiService.call(
    () => ApiService().getList<Product>(
      TerracottaEndpoints.materialProducts,
      queryParameters: {
        if (categoryId != null) 'category_id': categoryId,
        if (subCategoryId != null) 'sub_category_id': subCategoryId,
        if (featured != null) 'featured': featured,
        if (onSale != null) 'on_sale': onSale,
        if (search != null && search.isNotEmpty) 'search': search,
        if (sort != null) 'sort': sort.wire,
        if (minPrice != null) 'min_price': minPrice,
        if (maxPrice != null) 'max_price': maxPrice,
        if (perPage != null) 'per_page': perPage,
        if (page != null) 'page': page,
      },
      fromJson: Product.fromJson,
      logRequest: logGetProducts.request,
      logResponse: logGetProducts.response,
      cancelToken: cancelToken,
      timeout: timeout,
    ),
  );

  /// One PAGE of the material listing.
  ///
  /// Both `per_page` and `page` go out together, always: `page` on its
  /// own is ignored by the server and returns the whole catalogue.
  static AsyncResult<ProductPage> getProductsPage({
    required int page,
    int perPage = 10,
    int? categoryId,
    int? subCategoryId,
    bool? featured,
    bool? onSale,
    String? search,
    ProductSort? sort,
    num? minPrice,
    num? maxPrice,
    CancelToken? cancelToken,
    Duration? timeout,
  }) => ApiService.call(
    () => ApiService().get<ProductPage>(
      TerracottaEndpoints.materialProducts,
      queryParameters: {
        if (categoryId != null) 'category_id': categoryId,
        if (subCategoryId != null) 'sub_category_id': subCategoryId,
        if (featured != null) 'featured': featured,
        if (onSale != null) 'on_sale': onSale,
        if (search != null && search.isNotEmpty) 'search': search,
        // Omitted entirely for the studio's own order — see
        // [ProductSort].
        if (sort != null) 'sort': sort.wire,
        if (minPrice != null) 'min_price': minPrice,
        if (maxPrice != null) 'max_price': maxPrice,
        'per_page': perPage,
        'page': page,
      },
      fromJson: ProductPage.fromJson,
      logRequest: logGetProducts.request,
      logResponse: logGetProducts.response,
      cancelToken: cancelToken,
      timeout: timeout,
    ),
  );

  /// One material's detail — `description`, `images`, dimensions and
  /// `related_products`, exactly as a shop product answers.
  static AsyncResult<ProductDetail> getProduct(
    String productId, {
    CancelToken? cancelToken,
    Duration? timeout,
  }) => ApiService.call(
    () => ApiService().get<ProductDetail>(
      TerracottaEndpoints.materialProduct(productId),
      fromJson: ProductDetail.fromJson,
      logRequest: logGetProduct.request,
      logResponse: logGetProduct.response,
      cancelToken: cancelToken,
      timeout: timeout,
    ),
  );
}
