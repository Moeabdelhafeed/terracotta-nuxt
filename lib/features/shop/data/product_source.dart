import '../../../core/localization/strings/shop_strings.dart';
import '../../../data/api/calls/material_apis.dart';
import '../../../data/api/calls/shop_apis.dart';
import '../cubits/product_browse_cubit.dart';
import '../cubits/product_detail_cubit.dart';

/// Which of the studio's two storefronts a browse screen is showing.
///
/// **Finished pieces and raw materials answer the identical wire** —
/// same category tree, same product row, same detail with its
/// `related_products` — off three parallel endpoints. So the shop's
/// list, detail, filter sheet and cards serve both, and this is the
/// one thing that differs between them: where the rows come from.
///
/// It is a path, not a flag on an extra. `/materials/products/16` and
/// `/shop/products/16` are different products, and a source carried in
/// a `GoRouter` extra is gone the moment somebody follows a link or
/// the app hot-restarts — which would fetch the wrong storefront and
/// show whatever happened to share the id.
///
/// ## The basket is SHARED
///
/// A material goes into `POST /api/shop/cart` like any other product,
/// and a basket holding a mug and a bag of clay checks out as one
/// order with one delivery fee. There is deliberately no materials
/// cart, checkout or order history — so nothing below touches those.
/// **MATERIALS IS WITHDRAWN.** Nothing constructs
/// [ProductSource.materials] any more: the two routes that did are
/// commented out in `app_routes.dart`, and the card that led to them
/// is commented out in `shop_home_page.dart`. This file is left whole
/// because it is what makes one list screen and one detail screen
/// serve two catalogues — deleting it would mean writing it again.
enum ProductSource {
  shop,
  materials;

  bool get isMaterials => this == ProductSource.materials;

  /// The category tree for this storefront.
  CategoriesFetch get categories =>
      isMaterials ? MaterialApis.getCategories : ShopApis.getCategories;

  /// One page of rows.
  ProductsPageFetch get products =>
      isMaterials ? MaterialApis.getProductsPage : ShopApis.getProductsPage;

  /// One product's detail.
  ProductDetailFetch get detail =>
      isMaterials ? MaterialApis.getProduct : ShopApis.getProduct;

  /// The route that opens one product of this storefront.
  String get detailRoute => isMaterials ? 'material-detail' : 'product-detail';

  /// What the screen is called at the top.
  String get title => isMaterials ? ShopStrings.materials : ShopStrings.title;

  /// The wire spelling, for a route that has to carry it in a path
  /// segment rather than in a type.
  String get wire => name;

  static ProductSource fromWire(String? wire) =>
      wire == ProductSource.materials.name
      ? ProductSource.materials
      : ProductSource.shop;
}
