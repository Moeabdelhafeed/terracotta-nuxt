import 'package:dio/dio.dart';

import '../../../core/constants/enums/api/request_type.dart';
import '../../../core/types/result.dart';
import '../../models/terracotta/commerce/cart.dart';
import '../../models/terracotta/commerce/cart_item.dart';
import '../../models/terracotta/commerce/order.dart';
import '../../models/terracotta/core/price_quote.dart';
import '../../models/terracotta/shop/product.dart';
import '../../models/terracotta/shop/product_detail.dart';
import '../../models/terracotta/shop/product_page.dart';
import '../../models/terracotta/shop/shop_category.dart';
import '../../models/terracotta/shop/shop_home.dart';
import '../api_service.dart';
import '../endpoints/terracotta_endpoints.dart';

/// Shop API calls — catalogue, favourites, cart, checkout and orders.
///
/// Browsing is PUBLIC ([getHome], [getCategories], [getProducts],
/// [getProduct]). Favourites, cart and orders belong to the caller and
/// need a session — a guest gets 401 there.
///
/// **Buying is three steps: quote → create → pay.**
/// [getCheckoutQuote] prices the cart and creates nothing.
/// [checkout] turns the cart into an UNPAID order and holds the
/// wallet amount and the discount-code use. [payOrder] settles it.
/// Read `amount_due` off the checkout response first: `"0.00"` means
/// wallet or a 100% discount already covered it and [payOrder] must
/// NOT be called.
///
/// **Money is a decimal STRING** (`"65.00"`) — parse as a decimal,
/// never round-trip through `double`. **VAT is INCLUSIVE**:
/// `vat_amount` is contained in `total_price`, never added to it.
///
/// PUT and DELETE are written as PUT and DELETE here; the method-
/// override interceptor rewrites them to POST at send time.
///
/// Every method returns an `AsyncResult<...>` — pattern-match at the
/// call site.
/// How `GET /api/shop/products` orders what it returns.
///
/// Omitting it keeps the studio's own catalogue order, which is a
/// deliberate arrangement and the right default. Both price orders
/// compare on what the customer PAYS — the sale price on a piece that
/// is on offer.
enum ProductSort {
  newest('newest'),
  priceAsc('price_asc'),
  priceDesc('price_desc');

  const ProductSort(this.wire);

  /// The exact string the server takes. An unknown one is a 422 keyed
  /// to `sort`, so this never sends a guess.
  final String wire;
}

class ShopApis {
  ShopApis._();

  // ─── Per-endpoint log flags ───────────────────────────────

  static ApiLogConfig logGetHome = kApiLogVerbose;
  static ApiLogConfig logGetCategories = kApiLogVerbose;
  static ApiLogConfig logGetProducts = kApiLogVerbose;
  static ApiLogConfig logGetProduct = kApiLogVerbose;
  static ApiLogConfig logGetFavorites = kApiLogVerbose;
  static ApiLogConfig logAddFavorite = kApiLogVerbose;
  static ApiLogConfig logRemoveFavorite = kApiLogVerbose;
  static ApiLogConfig logGetCart = kApiLogVerbose;
  static ApiLogConfig logAddToCart = kApiLogVerbose;
  static ApiLogConfig logUpdateCartItem = kApiLogVerbose;
  static ApiLogConfig logRemoveCartItem = kApiLogVerbose;
  static ApiLogConfig logGetCheckoutQuote = kApiLogVerbose;
  static ApiLogConfig logCheckout = kApiLogVerbose;
  static ApiLogConfig logPayOrder = kApiLogVerbose;
  static ApiLogConfig logGetOrders = kApiLogVerbose;
  static ApiLogConfig logGetOrder = kApiLogVerbose;
  static ApiLogConfig logCancelOrder = kApiLogVerbose;

  // ─── Mock setup ───────────────────────────────────────────

  /// Register mock responses for the read endpoints in this class.
  /// Call once at app init when [ApiService.useMock] is true.
  static void installMocks() {
    ApiService.registerMock(
      endpoint: TerracottaEndpoints.shopHome,
      type: RequestType.get,
      data: {
        'categories': [_mockCategory],
        'featured_products': [_mockProduct],
        'offers': [_mockProduct],
      },
    );
    ApiService.registerMock(
      endpoint: TerracottaEndpoints.shopCategories,
      type: RequestType.get,
      data: [
        {
          'id': 1,
          'title': 'Cups',
          'sub_categories': [
            {'id': 1, 'title': 'Abbasid Cups'},
          ],
        },
      ],
    );
    ApiService.registerMock(
      endpoint: TerracottaEndpoints.shopProducts,
      type: RequestType.get,
      data: [_mockProduct],
    );
    ApiService.registerMock(
      endpoint: TerracottaEndpoints.shopProduct('1'),
      type: RequestType.get,
      data: {
        ..._mockProduct,
        'description': 'A handmade terracotta cup.',
        'images': [_mockImage],
        'colors': ['#c0392b', '#2980b9'],
        'height': '8.00',
        'width': '3.00',
        'length': '4.00',
        'category': 'Cups',
        'sub_category': 'Abbasid Cups',
        'related_products': <Map<String, dynamic>>[],
      },
    );
    ApiService.registerMock(
      endpoint: TerracottaEndpoints.shopFavorites,
      type: RequestType.get,
      data: [
        {..._mockProduct, 'is_favorited': true},
      ],
    );
    ApiService.registerMock(
      endpoint: TerracottaEndpoints.shopCart,
      type: RequestType.get,
      data: {
        'items': [_mockCartItem],
        'total_price': '130.00',
      },
    );
    ApiService.registerMock(
      endpoint: TerracottaEndpoints.shopOrders,
      type: RequestType.get,
      data: [_mockOrder],
    );
    ApiService.registerMock(
      endpoint: TerracottaEndpoints.shopOrder('1'),
      type: RequestType.get,
      data: _mockOrder,
    );
  }

  static const Map<String, dynamic> _mockImage = {
    'id': 3,
    'url': 'shop/products/cup.webp',
    'type': 'webp',
    'blurhash': 'LKO2?U%2Tw=w]~RBVZRi};RPxuwH',
    'image_api': 'https://example.test/storage/shop/products/cup.webp',
  };

  static const Map<String, dynamic> _mockProduct = {
    'id': 1,
    'title': 'Terracotta Cup',
    'price': '65.00',
    'sale_price': null,
    'image': _mockImage,
    'is_featured': true,
    'is_favorited': false,
  };

  static const Map<String, dynamic> _mockCategory = {
    'id': 1,
    'title': 'Cups',
    'image': _mockImage,
  };

  static const Map<String, dynamic> _mockCartItem = {
    'id': 1,
    'product': _mockProduct,
    'color': '#c0392b',
    'quantity': 2,
    'unit_price': '65.00',
    'line_total': '130.00',
  };

  static const Map<String, dynamic> _mockOrder = {
    'id': 1,
    'status': 'pending',
    'total_price': '130.00',
    'wallet_applied': '0.00',
    'amount_due': '130.00',
    'delivery_lat': '24.7136000',
    'delivery_lng': '46.6753000',
    'delivery_phone': '+966500000000',
    'can_cancel': true,
    'created_at': '2026-07-04T12:00:00+00:00',
    'cancelled_at': null,
    'items': [
      {
        'id': 1,
        'product': _mockProduct,
        'quantity': 2,
        'unit_price': '65.00',
        'color': '#c0392b',
        'line_total': '130.00',
      },
    ],
  };

  // ─── API methods — catalogue (PUBLIC) ─────────────────────

  /// Shop landing payload — `categories`, `featured_products` and
  /// `offers` rails in one call. Public; no token needed.
  static AsyncResult<ShopHome> getHome({
    CancelToken? cancelToken,
    Duration? timeout,
  }) => ApiService.call(
    () => ApiService().get<ShopHome>(
      TerracottaEndpoints.shopHome,
      fromJson: ShopHome.fromJson,
      logRequest: logGetHome.request,
      logResponse: logGetHome.response,
      cancelToken: cancelToken,
      timeout: timeout,
    ),
  );

  /// The category tree — each row carries its `sub_categories`.
  /// Public; no token needed.
  static AsyncResult<List<ShopCategory>> getCategories({
    CancelToken? cancelToken,
    Duration? timeout,
  }) => ApiService.call(
    () => ApiService().getList<ShopCategory>(
      TerracottaEndpoints.shopCategories,
      fromJson: ShopCategory.fromJson,
      logRequest: logGetCategories.request,
      logResponse: logGetCategories.response,
      cancelToken: cancelToken,
      timeout: timeout,
    ),
  );

  /// Product listing, filterable by category, sub-category, featured,
  /// on-sale, PRICE and free-text search, and sortable. Public; no
  /// token needed.
  ///
  /// **[sort], [minPrice] and [maxPrice] landed on 2026-09-13.** The
  /// endpoint accepted all three before that and silently ignored
  /// them, answering the whole catalogue either way — which is why the
  /// filter sheet used to offer neither. Probed live on 2026-09-14:
  /// `sort=price_asc` and `price_desc` really order now, `min_price`
  /// really narrows, and an unknown [sort] is a 422 keyed to `sort`.
  ///
  /// Both compare on what the customer PAYS — the sale price when a
  /// piece is on offer, not the struck-through one. Omitting [sort]
  /// keeps the studio's own catalogue order.
  ///
  /// TRAP — leave [perPage] null. Unpaginated, `data` is a plain array
  /// and parses as this list. Pass a numeric `per_page` and the backend
  /// swaps `data` for a Laravel paginator whose rows move to
  /// `data.data`, which the shared list handler does not unwrap.
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
      TerracottaEndpoints.shopProducts,
      queryParameters: {
        if (categoryId != null) 'category_id': categoryId,
        if (subCategoryId != null) 'sub_category_id': subCategoryId,
        if (featured != null) 'featured': featured,
        if (onSale != null) 'on_sale': onSale,
        if (search != null) 'search': search,
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

  /// One PAGE of the product listing.
  ///
  /// Both `per_page` and `page` go out together, always: `page` on its
  /// own is ignored by the server and returns the whole catalogue.
  /// Sending `per_page` is also what turns `data` into a Laravel
  /// paginator — see [ProductPage], which is where that is unwrapped.
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
      TerracottaEndpoints.shopProducts,
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

  /// One product's detail — adds `description`, `images`, `colors`,
  /// dimensions and `related_products`. Public; no token needed.
  ///
  /// `price` / `sale_price` are decimal STRINGS; when `sale_price` is
  /// non-null it is what the customer pays.
  static AsyncResult<ProductDetail> getProduct(
    String productId, {
    CancelToken? cancelToken,
    Duration? timeout,
  }) => ApiService.call(
    () => ApiService().get<ProductDetail>(
      TerracottaEndpoints.shopProduct(productId),
      fromJson: ProductDetail.fromJson,
      logRequest: logGetProduct.request,
      logResponse: logGetProduct.response,
      cancelToken: cancelToken,
      timeout: timeout,
    ),
  );

  // ─── API methods — favourites ─────────────────────────────

  /// The caller's favourited products. Needs a session — a guest gets
  /// 401. A guest promoted to a real account on the same device keeps
  /// the favourites built while browsing.
  static AsyncResult<List<Product>> getFavorites({
    CancelToken? cancelToken,
    Duration? timeout,
  }) => ApiService.call(
    () => ApiService().getList<Product>(
      TerracottaEndpoints.shopFavorites,
      fromJson: Product.fromJson,
      logRequest: logGetFavorites.request,
      logResponse: logGetFavorites.response,
      cancelToken: cancelToken,
      timeout: timeout,
    ),
  );

  /// Favourite a product.
  ///
  /// Responds with `data: null` on success — around forty operations
  /// on this API do. That USED to surface as a `ValidationException`
  /// reading "Expected `data` on a successful response"; the shared
  /// handler now offers a null payload to the caller's own parser as
  /// `{}`, and the identity parser below accepts it. Verified live.
  static AsyncResult<Map<String, dynamic>> addFavorite(
    String productId, {
    CancelToken? cancelToken,
    Duration? timeout,
  }) => ApiService.call(
    () => ApiService().post<Map<String, dynamic>>(
      TerracottaEndpoints.shopFavorite(productId),
      fromJson: (json) => json,
      logRequest: logAddFavorite.request,
      logResponse: logAddFavorite.response,
      cancelToken: cancelToken,
      timeout: timeout,
    ),
  );

  /// Un-favourite a product. Sent as POST + `X-HTTP-Method-Override:
  /// DELETE` by the interceptor.
  ///
  /// TRAP — responds with `data: null`; see [addFavorite].
  /// Unfavourite a product.
  ///
  /// Goes out as a POST carrying `X-HTTP-Method-Override: DELETE` —
  /// `ApiService` rewrites every DELETE that way. Not only a production
  /// concern: the DEV server answers a plain DELETE here with a 500 and
  /// an empty body, and the same call with the override succeeds.
  static AsyncResult<Map<String, dynamic>> removeFavorite(
    String productId, {
    CancelToken? cancelToken,
    Duration? timeout,
  }) => ApiService.call(
    () => ApiService().delete<Map<String, dynamic>>(
      TerracottaEndpoints.shopFavorite(productId),
      fromJson: (json) => json,
      logRequest: logRemoveFavorite.request,
      logResponse: logRemoveFavorite.response,
      cancelToken: cancelToken,
      timeout: timeout,
    ),
  );

  // ─── API methods — cart ───────────────────────────────────

  /// The active cart — `items` plus a `total_price` decimal string.
  /// `total_price` here is goods only: no delivery, discount, wallet
  /// or VAT line. Call [getCheckoutQuote] for the real total.
  static AsyncResult<Cart> getCart({
    CancelToken? cancelToken,
    Duration? timeout,
  }) => ApiService.call(
    () => ApiService().get<Cart>(
      TerracottaEndpoints.shopCart,
      fromJson: Cart.fromJson,
      logRequest: logGetCart.request,
      logResponse: logGetCart.response,
      cancelToken: cancelToken,
      timeout: timeout,
    ),
  );

  /// Add a line to the cart; returns the created line. [color] must be
  /// one of the product's `colors` when it has any. [quantity]
  /// defaults to 1 server-side.
  static AsyncResult<CartItem> addToCart({
    required int shopProductId,
    String? color,
    int? quantity,
    CancelToken? cancelToken,
    Duration? timeout,
  }) => ApiService.call(
    () => ApiService().post<CartItem>(
      TerracottaEndpoints.shopCart,
      data: {
        'shop_product_id': shopProductId,
        if (color != null) 'color': color,
        if (quantity != null) 'quantity': quantity,
      },
      fromJson: CartItem.fromJson,
      logRequest: logAddToCart.request,
      logResponse: logAddToCart.response,
      cancelToken: cancelToken,
      timeout: timeout,
    ),
  );

  /// Set a cart line's quantity; returns the updated line. Sent as
  /// POST + `X-HTTP-Method-Override: PUT` by the interceptor.
  static AsyncResult<CartItem> updateCartItem(
    String itemId, {
    required int quantity,
    CancelToken? cancelToken,
    Duration? timeout,
  }) => ApiService.call(
    () => ApiService().put<CartItem>(
      TerracottaEndpoints.shopCartItem(itemId),
      data: {'quantity': quantity},
      fromJson: CartItem.fromJson,
      logRequest: logUpdateCartItem.request,
      logResponse: logUpdateCartItem.response,
      cancelToken: cancelToken,
      timeout: timeout,
    ),
  );

  /// Drop a line from the cart. Sent as POST + override.
  ///
  /// TRAP — responds with `data: null`; see [addFavorite]. Re-read
  /// [getCart] for the surviving lines.
  static AsyncResult<Map<String, dynamic>> removeCartItem(
    String itemId, {
    CancelToken? cancelToken,
    Duration? timeout,
  }) => ApiService.call(
    () => ApiService().delete<Map<String, dynamic>>(
      TerracottaEndpoints.shopCartItem(itemId),
      fromJson: (json) => json,
      logRequest: logRemoveCartItem.request,
      logResponse: logRemoveCartItem.response,
      cancelToken: cancelToken,
      timeout: timeout,
    ),
  );

  // ─── API methods — checkout (quote → create → pay) ────────

  /// QUOTE step — prices the cart with delivery, discount and wallet
  /// applied. **Creates no order and holds nothing**; the wallet
  /// amount and the code use are only consumed by [checkout].
  ///
  /// Arithmetic order is fixed: the discount hits goods only, delivery
  /// is added on top, then the wallet covers what is left — **a
  /// discount code never reduces `delivery_fee`.** `vat_amount` is
  /// already inside `total_price`; adding them overcharges. Every
  /// figure is a decimal string.
  ///
  /// [deliveryZoneId] prices a city the customer is still picking and
  /// overrides [addressId]; the map pin never affects the fee.
  static AsyncResult<PriceQuote> getCheckoutQuote({
    bool? useWallet,
    String? discountCode,
    int? addressId,
    int? deliveryZoneId,
    CancelToken? cancelToken,
    Duration? timeout,
  }) => ApiService.call(
    () => ApiService().post<PriceQuote>(
      TerracottaEndpoints.shopCartQuote,
      data: {
        if (useWallet != null) 'use_wallet': useWallet,
        if (discountCode != null) 'discount_code': discountCode,
        if (addressId != null) 'address_id': addressId,
        if (deliveryZoneId != null) 'delivery_zone_id': deliveryZoneId,
      },
      fromJson: PriceQuote.fromJson,
      logRequest: logGetCheckoutQuote.request,
      logResponse: logGetCheckoutQuote.response,
      cancelToken: cancelToken,
      timeout: timeout,
    ),
  );

  /// CREATE step — turns the cart into an UNPAID order and reserves
  /// the wallet amount and the discount-code use. The returned figures
  /// must match [getCheckoutQuote] field for field.
  ///
  /// **Check `amount_due` before paying**: `"0.00"` means wallet or a
  /// 100% discount already settled it and [payOrder] must be skipped.
  /// The cart is emptied when the order is PAID, not here — backing
  /// out of the payment screen must not lose it, and an abandoned hold
  /// expires and gives the wallet amount and code use back.
  ///
  /// Pass [addressId] for a saved address, or all of [lat], [lng] and
  /// [phone] instead — each is required only when [addressId] is
  /// absent. The city on the address carries the delivery fee; the
  /// map pin is for the driver only.
  static AsyncResult<Order> checkout({
    int? addressId,
    double? lat,
    double? lng,
    String? phone,
    bool? useWallet,
    String? discountCode,
    CancelToken? cancelToken,
    Duration? timeout,
  }) => ApiService.call(
    () => ApiService().post<Order>(
      TerracottaEndpoints.shopCartCheckout,
      data: {
        if (addressId != null) 'address_id': addressId,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
        if (phone != null) 'phone': phone,
        if (useWallet != null) 'use_wallet': useWallet,
        if (discountCode != null) 'discount_code': discountCode,
      },
      fromJson: Order.fromJson,
      logRequest: logCheckout.request,
      logResponse: logCheckout.response,
      cancelToken: cancelToken,
      timeout: timeout,
    ),
  );

  /// PAY step — settles an order held by [checkout] and empties the
  /// cart. Returns `payment_status` and `payment_expires_at`.
  ///
  /// **Idempotent** — a retry after a dropped response must not
  /// double-charge, so a resend is the correct recovery. Do not call
  /// this at all when [checkout] reported `amount_due` of `"0.00"`.
  static AsyncResult<Map<String, dynamic>> payOrder(
    String orderId, {
    CancelToken? cancelToken,
    Duration? timeout,
  }) => ApiService.call(
    () => ApiService().post<Map<String, dynamic>>(
      TerracottaEndpoints.shopOrderPay(orderId),
      fromJson: (json) => json,
      logRequest: logPayOrder.request,
      logResponse: logPayOrder.response,
      cancelToken: cancelToken,
      timeout: timeout,
    ),
  );

  // ─── API methods — orders ─────────────────────────────────

  /// The caller's orders, newest first. Statuses run
  /// `awaiting_payment → pending → preparing → out_for_delivery →
  /// completed`, plus `cancelled`.
  ///
  /// TRAP — leave [perPage] null; a numeric `per_page` swaps `data`
  /// for a Laravel paginator and moves the rows to `data.data`. See
  /// [getProducts].
  static AsyncResult<List<Order>> getOrders({
    int? perPage,
    int? page,
    CancelToken? cancelToken,
    Duration? timeout,
  }) => ApiService.call(
    () => ApiService().getList<Order>(
      TerracottaEndpoints.shopOrders,
      queryParameters: {
        if (perPage != null) 'per_page': perPage,
        if (page != null) 'page': page,
      },
      fromJson: Order.fromJson,
      logRequest: logGetOrders.request,
      logResponse: logGetOrders.response,
      cancelToken: cancelToken,
      timeout: timeout,
    ),
  );

  /// One of the caller's orders, with its `items`. Money on an order
  /// is a snapshot of what it was sold at — a later price, fee or VAT
  /// change must never alter it. Someone else's id must 404.
  static AsyncResult<Order> getOrder(
    String orderId, {
    CancelToken? cancelToken,
    Duration? timeout,
  }) => ApiService.call(
    () => ApiService().get<Order>(
      TerracottaEndpoints.shopOrder(orderId),
      fromJson: Order.fromJson,
      logRequest: logGetOrder.request,
      logResponse: logGetOrder.response,
      cancelToken: cancelToken,
      timeout: timeout,
    ),
  );

  /// Cancel an order and return it in `cancelled`. Sent as POST +
  /// `X-HTTP-Method-Override: DELETE` by the interceptor.
  ///
  /// Only allowed while `pending` or `preparing` — gate the button on
  /// the order's `can_cancel` rather than guessing from `status`.
  static AsyncResult<Order> cancelOrder(
    String orderId, {
    CancelToken? cancelToken,
    Duration? timeout,
  }) => ApiService.call(
    () => ApiService().delete<Order>(
      TerracottaEndpoints.shopOrder(orderId),
      fromJson: Order.fromJson,
      logRequest: logCancelOrder.request,
      logResponse: logCancelOrder.response,
      cancelToken: cancelToken,
      timeout: timeout,
    ),
  );
}
