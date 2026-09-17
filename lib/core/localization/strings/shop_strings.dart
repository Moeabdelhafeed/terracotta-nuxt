import '../../../generated/l10n.dart';
import '../number_formatter.dart';
import '../tr.dart';

/// Shop — landing, browse, product detail, cart and favourites.
class ShopStrings {
  /// «-٢٣٪» — how much a sale price takes off.
  ///
  /// A DISPLAY value, not money: it is a whole percent computed from
  /// the two prices beside it, and nothing is ever totalled from it.
  /// See `Discount.percentOff`.
  static String discountBadge(int percent) => Tr.t(
    'shop_discount_badge',
    S.current.shop_discount_badge(AppNumbers.localizeDigits('$percent')),
  );

  ShopStrings._();

  /// «١٥ نتيجة» — how many pieces the CURRENT filters match.
  ///
  /// The server's own `total`, not the length of what has been paged
  /// in: the list holds ten rows and the answer is fifteen, and a
  /// reader who is told «١٠» while scrolling to a eleventh has been
  /// lied to by their own screen.
  static String resultsCount(int count) => Tr.plural(
    'shop_results_count',
    count,
    S.current.shop_results_count(count),
  );

  static String get title => Tr.t('shop_title', S.current.shop_title);

  static String get subtitle => Tr.t('shop_subtitle', S.current.shop_subtitle);

  // ─── The second storefront ────────────────────────────────
  //
  // Clay, glazes and tools, off `/api/materials/*`. Browsed exactly
  // like the shop and sharing its BASKET — which is worth saying out
  // loud on the way in, because a second storefront usually means a
  // second cart and here it does not.

  static String get materials =>
      Tr.t('shop_materials', S.current.shop_materials);

  static String get materialsSubtitle => Tr.t(
    'shop_materials_subtitle',
    S.current.shop_materials_subtitle,
  );

  static String get materialsCta =>
      Tr.t('shop_materials_cta', S.current.shop_materials_cta);

  static String get materialsOneBasket => Tr.t(
    'shop_materials_one_basket',
    S.current.shop_materials_one_basket,
  );

  /// «تصفح فئات المباخر» — the sub-category rail's heading, named for
  /// whichever category is open.
  static String browseSubCategories(String category) => Tr.t(
    'shop_browse_sub_categories',
    S.current.shop_browse_sub_categories(category),
  );

  static String get filters => Tr.t('shop_filters', S.current.shop_filters);

  static String get filterFeatured =>
      Tr.t('shop_filter_featured', S.current.shop_filter_featured);

  static String get filterOnSale =>
      Tr.t('shop_filter_on_sale', S.current.shop_filter_on_sale);

  static String get filterApply =>
      Tr.t('shop_filter_apply', S.current.shop_filter_apply);

  static String get filterClear =>
      Tr.t('shop_filter_clear', S.current.shop_filter_clear);

  /// A search that matched nothing. NOT an error: the screen worked.
  static String get noResults =>
      Tr.t('shop_no_results', S.current.shop_no_results);

  static String get searchHint =>
      Tr.t('shop_search_hint', S.current.shop_search_hint);

  static String get myCart => Tr.t('shop_my_cart', S.current.shop_my_cart);

  static String get myFavorites =>
      Tr.t('shop_my_favorites', S.current.shop_my_favorites);

  static String get myOrders =>
      Tr.t('shop_my_orders', S.current.shop_my_orders);

  static String browseCategory(String category) =>
      Tr.t('shop_browse_category', S.current.shop_browse_category(category));

  static String get youMayLike =>
      Tr.t('shop_you_may_like', S.current.shop_you_may_like);

  /// The product detail screen's own app-bar title — the SCREEN, not
  /// the product. The product's name is on the page, under its
  /// photographs, where the design puts it.
  static String get productDetails =>
      Tr.t('shop_product_details', S.current.shop_product_details);

  static String get category => Tr.t('shop_category', S.current.shop_category);

  /// «ارتفاع» / «عرض» / «طول» and «سم».
  ///
  /// Three atoms rather than one sentence with three placeholders: the
  /// wire sends `height`, `width` and `length` INDEPENDENTLY nullable,
  /// and a CMS row with only a height has to read «٨ سم ارتفاع» rather
  /// than a sentence with two holes in it.
  static String get dimensionHeight =>
      Tr.t('shop_dimension_height', S.current.shop_dimension_height);

  static String get dimensionWidth =>
      Tr.t('shop_dimension_width', S.current.shop_dimension_width);

  static String get dimensionLength =>
      Tr.t('shop_dimension_length', S.current.shop_dimension_length);

  static String get dimensionUnit =>
      Tr.t('shop_dimension_unit', S.current.shop_dimension_unit);

  static String get colour => Tr.t('shop_colour', S.current.shop_colour);

  static String get size => Tr.t('shop_size', S.current.shop_size);

  static String get addToCart =>
      Tr.t('shop_add_to_cart', S.current.shop_add_to_cart);

  static String quantity(String count) =>
      Tr.t('shop_quantity', S.current.shop_quantity(count));

  static String get filter => Tr.t('shop_filter', S.current.shop_filter);

  static String get empty => Tr.t('shop_empty', S.current.shop_empty);

  static String get favoritesEmpty =>
      Tr.t('shop_favorites_empty', S.current.shop_favorites_empty);

  static String get ordersEmpty =>
      Tr.t('shop_orders_empty', S.current.shop_orders_empty);

  /// A title alone on a screen the customer opened to find something
  /// reads as a page that failed.
  static String get ordersEmptyBody =>
      Tr.t('shop_orders_empty_body', S.current.shop_orders_empty_body);

  static String get cartEmpty =>
      Tr.t('shop_cart_empty', S.current.shop_cart_empty);

  static String lineItem(String title, String count) =>
      Tr.t('shop_line_item', S.current.shop_line_item(title, count));

  /// Taking the last one of something out of the cart. Named for what
  /// it DOES rather than asking "are you sure": the minus at one is a
  /// removal, and a customer pressing it a third time deserves to know
  /// that before the row disappears.
  static String get removeLineTitle =>
      Tr.t('shop_remove_line_title', S.current.shop_remove_line_title);

  static String removeLineMessage(String title) => Tr.t(
    'shop_remove_line_message',
    S.current.shop_remove_line_message(title),
  );

  static String get checkout => Tr.t('shop_checkout', S.current.shop_checkout);

  /// Stock. See `Stock` for the rule these belong to — «نفدت الكمية»
  /// is the SOLD-OUT case only; an untracked piece says nothing.
  static String get outOfStock =>
      Tr.t('shop_out_of_stock', S.current.shop_out_of_stock);

  /// «بقي ٣ قطع», not «بقي 3 قطع».
  ///
  /// An ICU plural interpolates its count in ASCII even under `ar` —
  /// plain Arabic formats in western digits, and only the `ar_EG`
  /// variant does not. `localizeDigits` rewrites the digits and leaves
  /// the words alone, which is what the rest of the app does with a
  /// count inside a sentence.
  static String stockLeft(int count) => AppNumbers.localizeDigits(
    Tr.t('shop_stock_left', S.current.shop_stock_left(count)),
  );
  static String maxReached(int count) => AppNumbers.localizeDigits(
    Tr.t('shop_max_reached', S.current.shop_max_reached(count)),
  );
  static String get maxPerOrder => AppNumbers.localizeDigits(
    Tr.t('shop_max_per_order', S.current.shop_max_per_order),
  );

  /// «لديك ٢ من هذه القطعة في السلة» — what the reader already has,
  /// said on the product page so "add" is a decision and not a guess.
  static String inCartAlready(String count) =>
      Tr.t('shop_in_cart_already', S.current.shop_in_cart_already(count));

  /// The ceiling, reached — and WHY, which is the part that was
  /// missing: the button went on adding and the server went on
  /// refusing, with nothing on screen to say the cart was already
  /// full of this piece.
  static String cartFullForItem(String count) => Tr.t(
    'shop_cart_full_for_item',
    S.current.shop_cart_full_for_item(count),
  );

  /// «الترتيب» — how the list is ordered.
  ///
  /// `sort` landed on 2026-09-13. The endpoint accepted it before that
  /// and ignored it, which is why the sheet used to offer nothing.
  static String get sortLabel =>
      Tr.t('shop_sort_label', S.current.shop_sort_label);

  /// No `sort` at all — the studio's own arrangement, and the default.
  static String get sortDefault =>
      Tr.t('shop_sort_default', S.current.shop_sort_default);

  static String get sortNewest =>
      Tr.t('shop_sort_newest', S.current.shop_sort_newest);

  static String get sortPriceAsc =>
      Tr.t('shop_sort_price_asc', S.current.shop_sort_price_asc);

  static String get sortPriceDesc =>
      Tr.t('shop_sort_price_desc', S.current.shop_sort_price_desc);

  /// «السعر» — the price range in the filter sheet.
  ///
  /// `min_price` / `max_price` compare on what the customer PAYS: the
  /// sale price on a piece that is on offer, not the struck-through
  /// one.
  static String get priceRange =>
      Tr.t('shop_price_range', S.current.shop_price_range);

  static String get priceMin =>
      Tr.t('shop_price_min', S.current.shop_price_min);

  static String get priceMax =>
      Tr.t('shop_price_max', S.current.shop_price_max);

  /// The server answers 422 on a max below the min, so the sheet says
  /// it first.
  static String get priceRangeInvalid => Tr.t(
    'shop_price_range_invalid',
    S.current.shop_price_range_invalid,
  );
}
