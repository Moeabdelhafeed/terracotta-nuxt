import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/color_name.dart';
import '../../../core/localization/number_formatter.dart';
import '../../../core/localization/strings/auth_strings.dart';
import '../../../core/localization/strings/common_strings.dart';
import '../../../core/localization/strings/home_strings.dart';
import '../../../core/localization/strings/shop_strings.dart';
import '../../../core/tokens/extensions.dart';
import '../../../data/models/terracotta/core/api_image.dart';
import '../../../data/models/terracotta/shop/product_detail.dart';
import '../../../shared/module/buttons/global_filled_button.dart';
import '../../../shared/module/divider/global_divider.dart';
import '../../../shared/module/empty_state/global_empty_state.dart';
import '../../../shared/module/image/global_image.dart';
import '../../../shared/module/media_picker/media_picker_models.dart';
import '../../../shared/module/media_picker/picker_lightbox.dart';
import '../../../shared/module/refreshable/global_refreshable.dart';
import '../../../shared/module/scrollable/global_scrollable.dart';
import '../../../shared/module/toast/global_toast.dart';
import '../../../shared/module/tooltip/global_tooltip.dart';
import '../../_shared/favorites_registry.dart';
import '../../_shared/screen_entrance.dart';
import '../../_shared/shared_hero.dart';
import '../../_shared/skeleton_block.dart';
import '../../_shared/terracotta_cta_style.dart';
import '../../_shared/terracotta_image.dart';
import '../../_shared/terracotta_page_bar.dart';
import '../../_shared/terracotta_widgets.dart';
import '../../auth/widgets/auth_failure.dart';
import '../../cart/cubits/cart_cubit.dart';
import '../../cart/cubits/cart_state.dart';
import '../../cart/data/guest_basket.dart';
import '../../cart/widgets/fly_to_cart.dart';
import '../../home/widgets/product_carousel.dart';
import '../cubits/product_detail_cubit.dart';
import '../cubits/product_detail_state.dart';
import '../data/product_source.dart';
import '../data/stock.dart';
import '../widgets/discount_badge.dart';
import '../widgets/stock_label.dart';

/// «كوب تيراكوتا» — one product.
///
/// ONE request feeds the whole page: `GET /api/shop/products/{id}`
/// answers the gallery, the description, the colourways, the three
/// measurements, the taxonomy labels and the related rail together.
///
/// Two things the wire does NOT support, and the page is honest about
/// both rather than drawing them as the design does:
///
///   * **Colours have no names.** `colors` is a flat list of bare hex
///     strings — `["#c96f4a", …]` — with no id and no label. The design
///     writes «احمر . ازرق»; there is nothing on the wire to write, so
///     the row draws SWATCHES.
///   * **The category is a NAME, not an id.** `category` /
///     `sub_category` arrive as display labels with nothing numeric
///     attached, so the row reads but does not navigate.
/// What the tapped CARD already knew.
///
/// The detail page fetches, and until it answers there is nothing on
/// screen for a hero to land on — so the flight worked on the way BACK
/// and not on the way in. This is the card's own picture, name and
/// price, handed over with the tap so the destination can paint them
/// immediately and the rest of the page fills in behind.
///
/// Null on a deep link, where there was no card.
@immutable
class ProductPreview {
  const ProductPreview({
    required this.id,
    required this.title,
    required this.price,
    this.salePrice,
    this.image,
    this.isFeatured = false,
    this.isFavorited = false,
  });

  final int id;
  final String title;

  /// Decimal STRINGS, shown exactly as the card showed them.
  final String price;
  final String? salePrice;

  final ApiImage? image;

  /// So «مميز» and the heart have somewhere to land too — without
  /// these the badge would be absent on arrival and only the picture,
  /// name and price would fly.
  final bool isFeatured;
  final bool isFavorited;

  String get effectivePrice => salePrice ?? price;
  bool get isOnSale => salePrice != null;
}

class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage({
    required this.productId,
    this.cubit,
    this.cart,
    this.preview,
    this.source = ProductSource.shop,
    super.key,
  });

  /// Which storefront this product belongs to. `/shop/products/16` and
  /// `/materials/products/16` are different products — see
  /// [ProductSource].
  final ProductSource source;

  /// What the card that was tapped already knew — see [ProductPreview].
  final ProductPreview? preview;

  final String productId;

  /// A cubit to use instead of making one — the seam a widget test
  /// needs, since the page loads on mount. Null in the app.
  final ProductDetailCubit? cubit;

  /// The cart to add to. Null in the app, which reaches for the
  /// singleton behind the badge.
  final CartCubit? cart;

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  late final _detail =
      widget.cubit ??
      ProductDetailCubit(
        productId: widget.productId,
        source: widget.source,
        // THE APP'S REGISTRY, not one of this page's own.
        //
        // Left out, the cubit built a `FavoritesRegistry()` of its
        // own — so the heart here recorded into an object nothing
        // else could see, and read back from one nothing else had
        // written to. A piece favourited on the shop rail opened with
        // an empty heart, and a heart filled here left the rail
        // behind it unchanged. Every other screen takes the
        // singleton; this one was the exception.
        registry: getIt<FavoritesRegistry>(),
      );

  int _qty = 1;

  /// A write is in flight. The button says so rather than letting a
  /// second tap add the same thing twice.
  bool _adding = false;

  /// The APP's cart — the badge on the bar above reads the same one.
  late final _cart = widget.cart ?? getIt<CartCubit>();

  /// Where the flight starts, and where it lands.
  final _galleryKey = GlobalKey();
  final _cartKey = GlobalKey();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // On mount AND when `Localizations` changes above us. The title,
    // the description and both taxonomy labels come from the server in
    // whichever language the request asked for, and switching language
    // rebuilds `MaterialApp` WITHOUT remounting this page — so a load
    // on mount alone left the copy in the language it first arrived in.
    unawaited(_detail.ensureLoaded(_locale));
  }

  String get _locale => Localizations.localeOf(context).languageCode;

  @override
  void dispose() {
    // Only what this page MADE. An injected one belongs to its test.
    if (widget.cubit == null) unawaited(_detail.close());
    super.dispose();
  }

  /// Put this piece in the cart, then fly it into the bar.
  ///
  /// The flight goes AFTER the server takes it, never before: an
  /// animation that lands in the cart is a promise, and one made for a
  /// request that then failed is a lie the customer only discovers at
  /// checkout.
  Future<void> _addToCart(ProductDetail product) async {
    setState(() => _adding = true);

    final color = product.colors.isEmpty ? null : product.colors.first;
    final added = await _cart.add(
      productId: product.id,
      // The hex string ITSELF is the variant id — there is nothing else
      // on the wire to send. Null when the product has no colourways.
      color: color,
      quantity: _qty,
      // WHAT A GUEST'S BASKET NEEDS TO DRAW THE ROW.
      //
      // Every cart route answers 401 without a session, so a guest's
      // basket lives on the device — and it has nothing to ask for the
      // picture, the title and the price with. `CartCubit.add` refuses
      // outright when this is missing, which is what a guest tapping
      // "add" actually got: no line, and a network error for a request
      // that was never sent.
      offline: BasketLine(
        productId: product.id,
        title: product.title,
        unitPrice: product.salePrice ?? product.price,
        wasPrice: product.salePrice == null ? null : product.price,
        quantity: _qty,
        color: color,
        image: product.images.isNotEmpty ? product.images.first : product.image,
      ),
      ceiling: Stock.ceiling(product.maxQuantity),
    );
    if (!mounted) return;
    setState(() => _adding = false);

    if (!added) {
      showAuthFailure(
        _cart.state.error ?? const NetworkException(message: 'cart'),
      );
      return;
    }
    unawaited(_flyToCart(product));
  }

  /// The piece, arcing up into the cart glyph.
  ///
  /// An overlay rather than a `Hero`: a Hero flies between ROUTES, and
  /// nothing is being pushed here — the page stays exactly where it is
  /// and only the picture travels.
  Future<void> _flyToCart(ProductDetail product) async {
    final image = product.images.isNotEmpty
        ? product.images.first
        : product.image;
    if (image == null || !mounted) return;

    final overlay = Overlay.maybeOf(context);
    final target = _cartKey.currentContext;
    final source = _galleryKey.currentContext;
    if (overlay == null || target == null || source == null) return;

    final from =
        (source.findRenderObject()! as RenderBox).localToGlobal(Offset.zero) &
        (source.findRenderObject()! as RenderBox).size;
    final to =
        (target.findRenderObject()! as RenderBox).localToGlobal(Offset.zero) &
        (target.findRenderObject()! as RenderBox).size;

    await showFlyToCart(overlay: overlay, image: image, from: from, to: to);
  }

  /// This page's product, for the tags it reserves below.
  int get _heroId => int.tryParse(widget.productId) ?? -1;

  @override
  Widget build(BuildContext context) => HeroScope(
    // The page RESERVES its own product's tags.
    //
    // The gallery, the title, the price, «مميز» and the heart already
    // wear them, and a related-products rail sits further down the same
    // page. If that rail held this product, its card would claim a tag
    // that is already on screen — two heroes, one tag, and Flutter
    // asserts. Reserving takes them out of circulation first.
    child: Builder(
      builder: (context) {
        for (final tag in [
          HeroTag.product(_heroId),
          HeroTag.productTitle(_heroId),
          HeroTag.productPrice(_heroId),
          HeroTag.productFeatured(_heroId),
          HeroTag.productFavourite(_heroId),
        ]) {
          HeroScope.reserve(context, tag);
        }
        return _scaffold(context);
      },
    ),
  );

  Widget _scaffold(BuildContext context) => Scaffold(
    backgroundColor: context.backgroundColors.scaffoldBackground,
    // The HOUSE bar. This page used to build `GlobalAppBar` itself,
    // purely so the cart action could carry the key a piece flies to —
    // and in doing so it took the module's default title instead of the
    // app's own start-aligned bold one.
    appBar: TerracottaPageBar(
      // The SCREEN's name, not the product's. The product's own name is
      // on the page, under its photographs, where the design puts it.
      title: ShopStrings.productDetails,
      cartKey: _cartKey,
      // PINNED. The bar carries the cart a piece flies INTO, and a
      // target that has retreated off screen is a flight to nowhere.
      pinned: true,
    ),
    body: GlobalRefreshable(
      onRefresh: () => _detail.refresh(_locale),
      child: BlocBuilder<ProductDetailCubit, ProductDetailState>(
        bloc: _detail,
        builder: (context, state) => switch (state) {
          // The PREVIEW, not a grey box, whenever the tap carried one.
          //
          // The heroes need somewhere to land the moment the page is
          // pushed; a skeleton has no gallery, which is why the flight
          // only ever worked on the way back.
          ProductDetailLoading() =>
            widget.preview == null
                ? const _DetailSkeleton()
                : _Preview(preview: widget.preview!),
          ProductDetailFailed(:final error) => GlobalEmptyState(
            icon: Icons.wifi_off_rounded,
            title: AuthStrings.errorGeneric,
            subtitle: error.message,
            primaryAction: GlobalFilledButton(
              text: CommonStrings.retry,
              onPressed: () => unawaited(_detail.refresh(_locale)),
              style: terracottaCtaStyle(showArrow: false),
            ),
          ),
          ProductDetailLoaded(:final product) => _Loaded(
            product: product,
            source: widget.source,
            galleryKey: _galleryKey,
            onToggleFavorite: (id) => unawaited(_detail.toggleFavorite(id)),
          ),
        },
      ),
    ),
    // PINNED. The design puts the stepper and the button on the screen
    // rather than at the foot of a page the reader has to reach — a
    // description and a rail of six can be a long way down.
    bottomNavigationBar: BlocBuilder<ProductDetailCubit, ProductDetailState>(
      bloc: _detail,
      builder: (context, state) => switch (state) {
        // IT ARRIVES, like the page it belongs to.
        //
        // Everything above it is staged, and this sat still while the
        // page assembled behind it — a control that was simply there
        // over a page that was still coming. `mount`, not `route`: it
        // is built when the product lands, which is long after the
        // route finished, so a route-gated entrance would stand down.
        ProductDetailLoaded(:final product) => ScreenEntrance(
          arrival: EntranceArrival.mount,
          // PINNED CHROME: it arrived on a clock of its own, so it
          // leaves on one too — down and out at the speed of the pop,
          // rather than sitting still on a page sliding away. See
          // [ScreenEntrance.exitsWithRoute].
          exitsWithRoute: true,
          // WATCHED, not read once. The count moves the moment the
          // add lands, and the bar has to move with it — the line
          // under the stepper and the state of the button are both
          // built from it.
          child: BlocBuilder<CartCubit, CartState>(
            bloc: _cart,
            buildWhen: (a, b) =>
                a.quantityOf(product.id) != b.quantityOf(product.id),
            builder: (context, cart) => _AddBar(
              qty: _qty,
              busy: _adding,
              inStock: product.inStock,
              ceiling: Stock.ceiling(product.maxQuantity),
              // HOW MANY ARE ALREADY IN THERE. The bar was counting
              // from zero every time the page opened, so a reader with
              // the cap already in their cart could go on pressing
              // «أضف» and go on being refused by the server, with
              // nothing on screen saying why.
              inCart: cart.quantityOf(product.id),
              onQty: (v) => setState(() => _qty = v),
              onAdd: () => unawaited(_addToCart(product)),
            ),
          ),
        ),
        // Nothing to add until there is something to add. A stepper over
        // a skeleton is a control for a product nobody has yet seen.
        _ => const SizedBox.shrink(),
      },
    ),
  );
}

/// The page once its one request has landed.
class _Loaded extends StatelessWidget {
  const _Loaded({
    required this.product,
    required this.source,
    required this.onToggleFavorite,
    this.galleryKey,
  });

  final ProductDetail product;

  /// Which storefront's route a related row opens.
  final ProductSource source;

  final ValueChanged<int> onToggleFavorite;

  /// Where a piece added from this page starts its flight.
  final GlobalKey? galleryKey;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    return GlobalScrollable(
      // The CALLER has to ask. Without it a page shorter than the
      // viewport drops the drag recogniser and the pull above it never
      // sees an overscroll — and the failed page, which is the one
      // most worth pulling, is the shortest of all.
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        // STAGGERED as the page settles.
        //
        // The pinned CTA at the foot is NOT in here: a hero
        // flies it between the steps of this flow, and an
        // entrance replaying on top of a landed flight is the
        // thing `ScreenEntrance` stands down for.
        children: ScreenEntrance.stage([
          // NOT STAGED: everything in these two FLEW here.
          //
          // The picture, the title, the price, the badge and the heart
          // all have counterparts on the card this page was opened
          // from, and a hero is an arrival — the element travels from
          // where it was to where it is. An entrance over the top of
          // that is a second arrival for the same thing, playing at the
          // same time and in a different direction.
          //
          // `stage` stands a top-level [SharedHero] down on its own,
          // but these are heroes NESTED inside a section, and it cannot
          // see through a widget to know that. So the section says so.
          EntranceSkip(
            child: _Gutter(
              child: _Gallery(
                key: galleryKey,
                images: product.images.isEmpty && product.image != null
                    // The gallery INCLUDES the cover as its first entry,
                    // so this is a fallback for a CMS row that has a cover
                    // and nothing else — not a hero above the pager.
                    ? [product.image!]
                    : product.images,
                featured: product.isFeatured,
                price: product.price,
                salePrice: product.salePrice,
                productId: product.id,
                // The card this page was opened from, if it was.
                heroTag: HeroTag.product(product.id),
              ),
            ),
          ),
          SizedBox(height: spacing.md),
          EntranceSkip(
            child: _Gutter(
              child: _TitleBlock(
                product: product,
                onToggleFavorite: () => onToggleFavorite(product.id),
              ),
            ),
          ),
          if (product.description case final description?
              when description.trim().isNotEmpty) ...[
            const _Rule(),
            _Gutter(child: _DescriptionCard(text: description)),
          ],
          const _Rule(),
          _Gutter(child: _Specs(product: product)),
          if (product.relatedProducts.isNotEmpty) ...[
            const _Rule(),
            _Gutter(child: SectionHeader(title: ShopStrings.youMayLike)),
            SizedBox(height: spacing.sm),
            // EDGE TO EDGE, so it is outside the gutter — a rail padded
            // from outside is clipped with nowhere to scroll into.
            ProductCarousel.shop(
              items: product.relatedProducts,
              onToggleFavorite: onToggleFavorite,
              // `pushNamed`, not `replace`: the reader came here from
              // somewhere and a rail is a detour, not a redirect.
              //
              // The callback hands back the TILE, not its id — named
              // `id` here, it stringified the object and the request
              // went to `/shop/products/Instance of 'ProductTile'`.
              // THE SAME STOREFRONT. `related_products` on a material
              // are materials, and sending them to the shop's route
              // would fetch whatever piece happened to share the id.
              onOpen: (tile) => context.pushNamed(
                source.detailRoute,
                pathParameters: {'productId': '${tile.id}'},
                // What the card already knew, so the heroes have
                // somewhere to land while the page fetches — every
                // other rail in the app passes this.
                extra: ProductPreview(
                  id: tile.id,
                  title: tile.title,
                  price: tile.price,
                  salePrice: tile.salePrice,
                  image: tile.image,
                  isFeatured: tile.isFeatured,
                  isFavorited: tile.isFavorited,
                ),
              ),
            ),
          ],
          SizedBox(height: spacing.lg),
        ]),
      ),
    );
  }
}

/// A hairline between the page's parts — after the price, after the
/// description, and before the related rail.
///
/// `primaryColors.border` rather than a literal: it IS black at 10% in
/// the light palette, and it is the one value that also has a dark
/// answer. A hardcoded `0x1A000000` would be invisible on the dark
/// ramp.
class _Rule extends StatelessWidget {
  const _Rule();

  @override
  Widget build(BuildContext context) => _Gutter(
    child: GlobalDivider(
      style: DividerStyle(
        color: context.primaryColors.border,
        thickness: 1,
        // The rule's own breathing room, so the sections do not each
        // have to remember to add a gap around it.
        spacing: context.spacing.md,
      ),
    ),
  );
}

/// The page's side gutter, applied per child — the rail runs to both
/// screen edges and pads its own contents instead.
class _Gutter extends StatelessWidget {
  const _Gutter({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(horizontal: context.spacing.md),
    child: child,
  );
}

/// The photographs, as the home banner's strip: one clip around the
/// whole pager, the «مميز» tag over it and the vessel dots at its foot.
///
/// It does NOT loop. The home banner does because a banner strip is
/// ambient and endless; a product has a known number of photographs and
/// running off the end of them is how the reader knows they have seen
/// them all.
class _Gallery extends StatefulWidget {
  const _Gallery({
    required this.images,
    required this.featured,
    this.price,
    this.salePrice,
    this.productId,
    this.heroTag,
    super.key,
  });

  final List<ApiImage> images;
  final bool featured;

  /// The two prices, as decimal STRINGS, so the corner can show what
  /// this piece saves. Null on a gallery with no price to hand — the
  /// badge simply does not draw. See [DiscountBadge].
  final String? price;
  final String? salePrice;

  /// Which product, so «مميز» can fly to the card's own badge.
  final int? productId;

  /// Where the card's picture flew from. Null when this page was not
  /// opened from one — a deep link, or a second copy of the card that
  /// did not get the tag.
  final String? heroTag;

  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  final _pages = PageController();
  int _index = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  /// The full-screen viewer the media picker already owns — swipeable,
  /// pinch-zoom, drag to dismiss. Opened ON the tapped photograph.
  void _open(int index) {
    final viewable = widget.images.where((i) => i.display.isNotEmpty).toList();
    if (viewable.isEmpty) return;

    unawaited(
      showPickerLightbox(
        context: context,
        items: [for (final i in viewable) PickerItem.url(i.display)],
        kinds: List.filled(viewable.length, AttachmentKind.image),
        initialIndex: index.clamp(0, viewable.length - 1),
        // NO NAME over the picture. `serving-plates-1-1-6.jpg` is the
        // CMS's upload slug — it says nothing to a customer and sits
        // on the photograph they opened it to look at. The counter
        // stays: which of two it is, is worth knowing.
        showTitle: false,
        // The tapped photograph FLIES up into the viewer rather than
        // being replaced by it. The same tag the card flew here with:
        // the two routes are a different pair, so there is no
        // duplicate — this route has one hero under that tag and the
        // lightbox has the other.
        heroTag: widget.heroTag,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    final gallery = AspectRatio(
      aspectRatio: 1.4,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(context.radii.md),
        child: Stack(
          children: [
            Positioned.fill(
              child: ColoredBox(color: context.backgroundColors.container),
            ),
            if (widget.images.isNotEmpty)
              // The hero wraps the PICTURES, not the whole gallery.
              //
              // Wrapped around the `Stack`, «مميز» and the page dots
              // became descendants of it — and a `Hero` inside another
              // `Hero` is an assertion, not a warning. The photograph
              // is the shared object anyway; the badge flies to the
              // card's own badge as its own sibling flight.
              Positioned.fill(child: _pager(context)),
            // THE SAVING, at the top of the reading START — the same
            // corner the cards put it in, so it flies rather than
            // appearing somewhere new.
            if (widget.price case final price?)
              PositionedDirectional(
                top: spacing.sm,
                start: spacing.sm,
                child: switch (widget.productId) {
                  final id? => DiscountBadge(
                    price: price,
                    salePrice: widget.salePrice,
                    productId: id,
                  ),
                  null => DiscountBadge(
                    price: price,
                    salePrice: widget.salePrice,
                  ),
                },
              ),
            if (widget.featured)
              PositionedDirectional(
                top: spacing.sm,
                end: spacing.sm,
                child: switch (widget.productId) {
                  final id? => SharedHero(
                    tag: HeroTag.productFeatured(id),
                    child: const _FeaturedTag(),
                  ),
                  null => const _FeaturedTag(),
                },
              ),
            if (widget.images.length > 1)
              Align(
                alignment: AlignmentDirectional.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.all(spacing.sm),
                  child: _Dots(count: widget.images.length, active: _index),
                ),
              ),
          ],
        ),
      ),
    );

    return gallery;
  }

  /// The pictures, flying as one.
  Widget _pager(BuildContext context) {
    final pager = PageView.builder(
      controller: _pages,
      itemCount: widget.images.length,
      onPageChanged: (i) => setState(() => _index = i),
      itemBuilder: (context, i) => GestureDetector(
        onTap: () => _open(i),
        child: TerracottaImage(image: widget.images[i]),
      ),
    );

    final tag = widget.heroTag;
    if (tag == null) return pager;

    return SharedHero(
      tag: tag,
      // A scrollable in flight is a scrollable being resized every
      // frame. The shuttle paints the FIRST picture instead — the one
      // the card showed, so the flight is of the same object either
      // way.
      flightShuttleBuilder: (_, _, _, _, _) =>
          TerracottaImage(image: widget.images.first),
      child: pager,
    );
  }
}

/// The tapped card's own picture, name and price, held until the
/// server answers.
///
/// It carries the SAME hero tags the loaded page does, so the flight
/// lands here and the real page swaps in underneath without anything
/// moving.
class _Preview extends StatelessWidget {
  const _Preview({required this.preview});

  final ProductPreview preview;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    return GlobalScrollable(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Gutter(
            child: _Gallery(
              images: preview.image == null ? const [] : [preview.image!],
              featured: preview.isFeatured,
              // The preview knows both prices, so the saving is drawn
              // while the page loads rather than appearing after it.
              price: preview.price,
              salePrice: preview.salePrice,
              productId: preview.id,
              heroTag: HeroTag.product(preview.id),
            ),
          ),
          SizedBox(height: spacing.md),
          _Gutter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: SharedHero(
                        tag: HeroTag.productTitle(preview.id),
                        child: Text(
                          preview.title,
                          style: context.textTheme.titleLarge?.copyWith(
                            color: context.textColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: spacing.xs),
                    SharedHero(
                      tag: HeroTag.productFavourite(preview.id),
                      child: _Heart(filled: preview.isFavorited),
                    ),
                  ],
                ),
                SizedBox(height: spacing.xs),
                SharedHero(
                  tag: HeroTag.productPrice(preview.id),
                  child: PriceText(
                    amount: preview.effectivePrice,
                    was: preview.isOnSale ? preview.price : null,
                    large: true,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: spacing.lg),
          // Everything the card did NOT know still has to arrive.
          const _DetailSkeleton(),
        ],
      ),
    );
  }
}

/// «مميز».
class _FeaturedTag extends StatelessWidget {
  const _FeaturedTag();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: context.primaryColors.primary,
      borderRadius: BorderRadius.circular(context.radii.xs),
    ),
    child: Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.spacing.xs,
        vertical: 2,
      ),
      child: Text(
        HomeStrings.badgeFeatured,
        style: context.textTheme.labelSmall?.copyWith(
          color: context.textColors.onPrimary,
        ),
      ),
    ),
  );
}

/// The vessel that marks the page you are on, as on the home banner.
class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.active});

  static const _asset = 'assets/images/vessel-dot.png';

  /// Taller than the home banner's 16. These sit over a product
  /// photograph that fills the frame, where the smaller mark was hard
  /// to pick out at all.
  static const _height = 22.0;

  /// Derived from the artwork's own 83 x 116 rather than guessed, so
  /// the vessel cannot end up subtly stretched.
  static const _width = _height * 83 / 116;

  final int count;
  final int active;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var i = 0; i < count; i++)
        Padding(
          padding: EdgeInsetsDirectional.only(start: i == 0 ? 0 : 6),
          // Sized from OUTSIDE. An explicit width and height on the
          // image become `cacheWidth` / `cacheHeight`, which force the
          // decode to exactly those pixels and squash anything that is
          // not square — and this vessel is 83 by 116.
          child: SizedBox(
            width: _width,
            height: _height,
            child: GlobalImage.a(
              _asset,
              placeholder: const SizedBox.shrink(),
              style: ImageStyle(
                fit: BoxFit.contain,
                borderRadius: BorderRadius.zero,
                color: context.textColors.onPrimary.withValues(
                  alpha: i == active ? 1 : 0.5,
                ),
                // srcIn: a solid silhouette on transparency. srcATop
                // would tint the transparent field with it too.
                overlayBlendMode: BlendMode.srcIn,
              ),
            ),
          ),
        ),
    ],
  );
}

/// The name, its heart, and the price under both.
class _TitleBlock extends StatelessWidget {
  const _TitleBlock({required this.product, required this.onToggleFavorite});

  final ProductDetail product;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: SharedHero(
              tag: HeroTag.productTitle(product.id),
              child: Text(
                product.title,
                style: context.textTheme.titleLarge?.copyWith(
                  color: context.textColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          SizedBox(width: context.spacing.xs),
          SharedHero(
            tag: HeroTag.productFavourite(product.id),
            child: _Heart(
              filled: product.isFavorited,
              onPressed: onToggleFavorite,
            ),
          ),
        ],
      ),
      SizedBox(height: context.spacing.xs),
      // Between the name and the price, which is where a customer
      // deciding whether to buy is already looking.
      if (Stock.level(inStock: product.inStock, stock: product.stock) !=
          StockLevel.fine) ...[
        StockLabel(
          inStock: product.inStock,
          stock: product.stock,
          productId: product.id,
        ),
        SizedBox(height: context.spacing.xs),
      ],
      // The SALE price leads when there is one, the original struck
      // through beside it. Both stay STRINGS — money is decimal on this
      // API and parsing it to a double rounds totals wrong.
      SharedHero(
        tag: HeroTag.productPrice(product.id),
        child: PriceText(
          amount: product.effectivePrice,
          was: product.isOnSale ? product.price : null,
          large: true,
        ),
      ),
    ],
  );
}

class _Heart extends StatelessWidget {
  const _Heart({required this.filled, this.onPressed});

  final bool filled;

  /// Null leaves it a read-only mark — which is what the loading
  /// preview shows, since there is nothing to toggle yet.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    onPressed: onPressed,
    icon: Icon(
      filled ? Icons.favorite_rounded : Icons.favorite_border_rounded,
      color: context.primaryColors.accent,
      size: context.iconSizes.md,
    ),
    tooltip: filled ? CommonStrings.remove : ShopStrings.myFavorites,
    visualDensity: VisualDensity.compact,
  );
}

/// The body copy, in the design's bordered well.
class _DescriptionCard extends StatelessWidget {
  const _DescriptionCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => TerracottaCard(
    child: Text(
      text,
      // Flush to the reading START. Body copy centred over several
      // lines gives both edges a ragged shape the eye has to re-find on
      // every line.
      textAlign: TextAlign.start,
      style: context.textTheme.bodySmall?.copyWith(
        color: context.textColors.primary,
        height: 1.8,
      ),
    ),
  );
}

/// «الفئة» / «اللون» / «المقاس».
///
/// Each row draws only when the wire sent something for it: a
/// half-filled CMS row renders, it does not print an empty well.
class _Specs extends StatelessWidget {
  const _Specs({required this.product});

  final ProductDetail product;

  /// «أكواب · أكواب عباسية» — the pair the taxonomy sends, or whichever
  /// half of it exists.
  static String? _taxonomy(ProductDetail p) {
    final parts = [
      if (p.category case final c? when c.isNotEmpty) c,
      if (p.subCategory case final s? when s.isNotEmpty) s,
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }

  /// «٨ سم ارتفاع · ٦ سم عرض · ٦ سم طول».
  ///
  /// The three measurements are INDEPENDENTLY nullable, so this is
  /// built from whichever arrived rather than from one sentence with
  /// three holes in it. [PriceText.format] does the digit work —
  /// `"8.00"` is a decimal STRING here too, and «٨٫٠٠ سم» is not what
  /// the design says.
  static String? _dimensions(ProductDetail p) {
    String? part(String? value, String label) =>
        value == null || value.trim().isEmpty
        ? null
        : '${PriceText.format(value)} ${ShopStrings.dimensionUnit} $label';

    final parts = [
      ?part(p.height, ShopStrings.dimensionHeight),
      ?part(p.width, ShopStrings.dimensionWidth),
      ?part(p.length, ShopStrings.dimensionLength),
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final taxonomy = _taxonomy(product);
    final dimensions = _dimensions(product);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (taxonomy != null)
          _SpecRow(
            label: ShopStrings.category,
            child: _SpecValue(text: taxonomy),
          ),
        if (product.colors.isNotEmpty)
          _SpecRow(
            label: ShopStrings.colour,
            // SWATCHES, not words. `colors` is a flat list of bare hex
            // strings with no name attached — the design writes «احمر»
            // and there is nothing on the wire to write.
            child: _Swatches(hexes: product.colors),
          ),
        if (dimensions != null)
          _SpecRow(
            label: ShopStrings.size,
            child: _SpecValue(text: dimensions),
          ),
      ],
    );
  }
}

/// One labelled well: the label pinned at the reading start, its value
/// at the far END of the row.
class _SpecRow extends StatelessWidget {
  const _SpecRow({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: context.spacing.sm),
    child: TerracottaCard(
      padding: EdgeInsets.symmetric(
        horizontal: context.spacing.md,
        vertical: context.spacing.sm,
      ),
      child: Row(
        children: [
          Text(
            label,
            style: context.textTheme.titleSmall?.copyWith(
              color: context.textColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          Expanded(
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: child,
            ),
          ),
        ],
      ),
    ),
  );
}

class _SpecValue extends StatelessWidget {
  const _SpecValue({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    textAlign: TextAlign.end,
    style: context.textTheme.bodySmall?.copyWith(
      color: context.primaryColors.primary,
    ),
  );
}

/// The colourways, as rounded rectangles — each one naming itself when
/// it is tapped.
///
/// The NAME is derived, not received: `colors` is a flat list of bare
/// hex strings with no label attached, so `ColorName` picks the nearest
/// of a small reference set. Without it a swatch is a coloured square
/// and nothing else, which is unreadable to anyone who cannot see it.
class _Swatches extends StatelessWidget {
  const _Swatches({required this.hexes});

  final List<String> hexes;

  static const _width = 26.0;
  static const _height = 18.0;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: context.spacing.xs,
    runSpacing: context.spacing.xs,
    alignment: WrapAlignment.end,
    children: [
      for (final hex in hexes)
        if (ColorName.parse(hex) case final color?)
          GlobalTooltip(
            message: ColorName.nameOf(color),
            // TAP, not the module's default. Hover does not exist on a
            // phone and a long press is a gesture nobody guesses — and
            // this label exists nowhere else on the screen.
            trigger: TooltipTrigger.tap,
            child: Container(
              width: _width,
              height: _height,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(context.radii.xs),
                border: Border.all(color: context.primaryColors.border),
              ),
            ),
          ),
    ],
  );
}

/// The stepper and «اضافة», pinned to the foot of the screen.
class _AddBar extends StatelessWidget {
  const _AddBar({
    required this.qty,
    required this.inCart,
    required this.onQty,
    required this.onAdd,
    required this.inStock,
    required this.ceiling,
    this.busy = false,
  });

  final int qty;

  /// How many of this piece the cart already holds. Counts toward
  /// [ceiling] — the server's cap is on the LINE, not on one tap.
  final int inCart;

  final bool busy;
  final ValueChanged<int> onQty;
  final VoidCallback onAdd;

  /// Whether there is anything to add at all.
  final bool inStock;

  /// The most the SERVER will take — `stock` when the piece is tracked,
  /// 100 when it is not. Going past it is a 422, so the stepper simply
  /// does not.
  final int ceiling;

  /// Whether the cart already holds everything this piece allows.
  bool get _full => inCart >= ceiling;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    // NOT `GlobalContainer.shell`: that is the page-shell wrapper and
    // it FILLS its slot, so a `bottomNavigationBar` built from one takes
    // the whole screen and packs the stepper and the button against the
    // top of it. A bar sizes itself to its contents.
    return Material(
      color: context.backgroundColors.scaffoldBackground,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(
            spacing.md,
            spacing.sm,
            spacing.md,
            0,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Sold out is not a disabled stepper next to a live
              // price — that reads as a bug. There is nothing to count,
              // so there is no counter.
              if (inStock) ...[
                _QtyStepper(
                  value: qty,
                  onChanged: onQty,
                  // WHAT IS LEFT, not the whole cap. The ceiling is on
                  // the line the server keeps, so two already in the
                  // cart is two off what this stepper may ask for.
                  ceiling: (ceiling - inCart).clamp(0, ceiling),
                ),
                SizedBox(height: spacing.sm),
              ],
              // WHAT THEY ALREADY HAVE. Quietly, under the stepper —
              // it is context for the decision, not a warning.
              if (inStock && inCart > 0 && !_full) ...[
                Text(
                  ShopStrings.inCartAlready(
                    AppNumbers.localizeDigits('$inCart'),
                  ),
                  textAlign: TextAlign.center,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.textColors.secondary,
                  ),
                ),
                SizedBox(height: spacing.sm),
              ],
              GlobalFilledButton(
                text: inStock ? ShopStrings.addToCart : ShopStrings.outOfStock,
                isLoading: busy,
                // OFF once the cart holds the cap.
                //
                // It used to stay live and go on firing, and the
                // server went on refusing — a button that does nothing
                // and explains nothing. Disabled it says the cart is
                // full of this piece; the line below says why.
                onPressed: inStock && !_full ? onAdd : null,
                style: terracottaCtaStyle(showArrow: false),
              ),
              if (inStock && _full) ...[
                SizedBox(height: spacing.sm),
                Text(
                  ShopStrings.cartFullForItem(
                    AppNumbers.localizeDigits('$inCart'),
                  ),
                  textAlign: TextAlign.center,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.statusColors.warning,
                  ),
                ),
              ],
              SizedBox(height: spacing.sm),
            ],
          ),
        ),
      ),
    );
  }
}

/// «− عدد ٢ +», the count centred between its two ends.
class _QtyStepper extends StatelessWidget {
  const _QtyStepper({
    required this.value,
    required this.onChanged,
    required this.ceiling,
  });

  final int value;
  final ValueChanged<int> onChanged;

  /// The most the server will accept for this piece.
  final int ceiling;

  @override
  Widget build(BuildContext context) => Row(
    // LOGICAL order, so the reading direction places them: in Arabic
    // the minus lands at the right and the plus at the left, which is
    // the design as drawn.
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      _Step(
        icon: Icons.remove_rounded,
        semanticLabel: CommonStrings.remove,
        onTap: value > 1 ? () => onChanged(value - 1) : null,
      ),
      Text(
        // «عدد ٢», not «عدد 2». Plain `ar` formats in WESTERN digits,
        // which is why this goes through the localizer rather than
        // straight into the placeholder.
        ShopStrings.quantity(AppNumbers.localizeDigits('$value')),
        style: context.textTheme.titleMedium?.copyWith(
          color: context.primaryColors.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
      _Step(
        icon: Icons.add_rounded,
        semanticLabel: ShopStrings.addToCart,
        // Disabled at the ceiling, and SAYING why. A plus that quietly
        // does nothing is the same to the thumb as a broken one — and
        // the two reasons differ: running out of a piece is about the
        // piece, the 100 cap is about the order.
        onTap: value < ceiling
            ? () => onChanged(value + 1)
            : () => GlobalToast.info(Stock.reachedMessage(ceiling)),
      ),
    ],
  );
}

class _Step extends StatelessWidget {
  const _Step({required this.icon, required this.semanticLabel, this.onTap});

  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onTap;

  /// From the design. Not a palette role: the page's own ground is the
  /// scaffold colour and these two squares sit a shade off it, which is
  /// the whole point of them.
  static const ground = Color(0xFFFAF7F6);

  /// A proper touch target. The old 6-point padding round an `sm` glyph
  /// came out under the 44 points a finger needs.
  static const _box = 44.0;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: onTap != null,
    label: semanticLabel,
    excludeSemantics: true,
    // `Material` + `InkWell`, not a bare `GestureDetector`: ink paints
    // on the nearest Material above it, and a `Container` painting its
    // own colour over one swallows the splash — the button worked and
    // looked dead.
    child: Material(
      color: ground,
      borderRadius: BorderRadius.circular(context.radii.sm),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: _box,
          height: _box,
          child: Icon(
            icon,
            size: context.iconSizes.md,
            color: onTap == null
                ? context.textColors.disabled
                : context.primaryColors.primary,
          ),
        ),
      ),
    ),
  );
}

/// The page's shape while the one request is out.
class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    Widget shimmer() => const SkeletonBlock();

    // SCROLLABLE, like the page it stands in for. A fixed column of
    // placeholders taller than the viewport overflows on a short window
    // — and landscape is where that lands.
    return GlobalScrollable(
      padding: EdgeInsets.symmetric(horizontal: spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(aspectRatio: 1, child: shimmer()),
          SizedBox(height: spacing.md),
          SizedBox(height: 22, width: 180, child: shimmer()),
          SizedBox(height: spacing.xs),
          SizedBox(height: 18, width: 90, child: shimmer()),
          SizedBox(height: spacing.md),
          SizedBox(height: 96, child: shimmer()),
          SizedBox(height: spacing.md),
          SizedBox(height: 44, child: shimmer()),
          SizedBox(height: spacing.sm),
          SizedBox(height: 44, child: shimmer()),
        ],
      ),
    );
  }
}
