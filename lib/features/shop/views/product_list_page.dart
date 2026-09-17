import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/animations/animation_presets.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/strings/auth_strings.dart';
import '../../../core/localization/strings/common_strings.dart';
import '../../../core/localization/strings/home_strings.dart';
import '../../../core/localization/strings/shop_strings.dart';
import '../../../core/tokens/extensions.dart';
import '../../../data/models/terracotta/shop/product.dart';
import '../../../data/models/terracotta/shop/shop_category.dart';
import '../../../shared/module/buttons/global_filled_button.dart';
import '../../../shared/module/empty_state/global_empty_state.dart';
import '../../../shared/module/list/global_list.dart';
import '../../../shared/module/scrollable/global_scrollable.dart';
import '../../_shared/category_chips.dart';
import '../../_shared/shared_hero.dart';
import '../../_shared/skeleton_block.dart';
import '../../_shared/terracotta_cta_style.dart';
import '../../_shared/terracotta_page_bar.dart';
import '../../_shared/terracotta_widgets.dart';
import '../cubits/product_browse_cubit.dart';
import '../cubits/product_browse_state.dart';
import '../cubits/shop_home_cubit.dart';
import '../cubits/shop_home_state.dart';
import '../data/product_source.dart';
import '../widgets/favorite_product_row.dart';
import '../widgets/product_filter_sheet.dart';
import '../widgets/shop_widgets.dart';
import 'product_detail_page.dart';

/// تصفح الفئات — browse one category.
///
/// Reached by tapping a category on the shop landing. The rails stay
/// put while the list below them reloads, which is why the state is one
/// object rather than a sealed loading/loaded family.
/// What the shop landing hands the browse screen when a category is
/// tapped.
///
/// The tree travels with the tap rather than being fetched again: the
/// landing already merged the artwork into it, and
/// `GET /api/shop/categories` does not carry an `image` at all.
@immutable
class ProductBrowseArgs {
  const ProductBrowseArgs({
    this.categoryId,
    this.categories = const [],
    this.featuredOnly = false,
    this.onSaleOnly = false,
    this.openKeyboard = false,
  });

  final int? categoryId;
  final List<ShopCategory> categories;

  /// Opened from a "see all" on a rail rather than from a category.
  ///
  /// The rail is «المنتجات المميزة» or «أحدث العروض» across the WHOLE
  /// shop, so the screen opens with that filter on and no category
  /// chosen — narrowing it to the first category would answer a
  /// question the reader did not ask.
  final bool featuredOnly;
  final bool onSaleOnly;

  /// Arrived by TAPPING SEARCH, so the keyboard comes with it.
  ///
  /// The shop tab's own field filters the payload it already has;
  /// searching the catalogue is this screen's job. Tapping the one on
  /// the shop bar therefore lands here — and it has to land ready to
  /// type, or the tap that meant "search" needs a second tap to do it.
  final bool openKeyboard;

  /// Whether this is a filter-led arrival, which is what decides
  /// against opening on a category.
  bool get isFilterLed => featuredOnly || onSaleOnly;
}

class ProductListPage extends StatefulWidget {
  const ProductListPage({
    this.subCategoryId,
    this.args,
    this.cubit,
    this.source = ProductSource.shop,
    super.key,
  });

  /// The sub-category the reader arrived on, if any.
  final int? subCategoryId;

  /// Which storefront this is — finished pieces, or raw materials and
  /// tools. See [ProductSource]: the two answer the identical wire off
  /// parallel endpoints, so this whole screen serves both.
  final ProductSource source;

  /// Everything the landing already knew. Null on a deep link, where
  /// the screen has to fetch the tree itself.
  final ProductBrowseArgs? args;

  /// A cubit to use instead of making one — the seam a widget test
  /// needs, since the page loads on mount. Null in the app.
  final ProductBrowseCubit? cubit;

  /// The cubit this page's inputs describe.
  ///
  /// Its own function because the mapping is where the screen broke:
  /// [args] carried the tapped category, the tree and now the filters,
  /// and the page was reading NONE of them — so every arrival refetched
  /// `/shop/categories`, lost the artwork it does not carry, and opened
  /// on the first category whatever had been tapped. Declared, passed,
  /// dropped is invisible in a page that still renders.
  ///
  /// [categories] and [products] are the fetch seams, so a test can
  /// assert on the configuration without a server.
  @visibleForTesting
  static ProductBrowseCubit cubitFor({
    int? subCategoryId,
    ProductBrowseArgs? args,
    List<ShopCategory> fallbackCategories = const [],
    String? locale,
    CategoriesFetch? categories,
    ProductsPageFetch? products,
    ProductSource source = ProductSource.shop,
  }) => ProductBrowseCubit(
    source: source,
    // Product titles are the SERVER's, so what this screen showed last
    // is only worth reopening with in the same language.
    locale: locale,
    // `0` is the route's SENTINEL for "no sub-category", not a
    // sub-category.
    //
    // The path is `/shop/categories/:subCategoryId` and it is not
    // optional, so every caller that opens the browse screen on a
    // CATEGORY — the home rails' "see all", the shop's category tiles,
    // a banner — pushes `'0'`. Passed through, the cubit filtered by
    // sub-category 0, the server matched nothing, and the screen opened
    // EMPTY on a category that has products. Choosing a category then
    // cleared the sub-category and they appeared, which is what made it
    // look like a loading bug rather than a filter one.
    initialSubCategoryId: subCategoryId == 0 ? null : subCategoryId,
    initialCategoryId: args?.categoryId,
    // The tree, from whoever already has it.
    //
    // The SHOP hands its own over with the tap. The HOME page cannot —
    // its category rows carry an image and no sub-categories — so it
    // used to arrive with nothing and the rail blanked while this
    // screen fetched, which is why a category flew in from the shop and
    // not from home.
    //
    // `ShopHomeCubit` is where the merged tree lives (image AND
    // sub-categories, from two endpoints neither of which is complete),
    // it is an app-wide singleton, and the home page warms it. So there
    // is a tree in memory either way — this reads it rather than asking
    // again.
    knownCategories: args?.categories.isNotEmpty ?? false
        ? args!.categories
        : fallbackCategories,
    initialFeatured: args?.featuredOnly ?? false,
    initialOnSale: args?.onSaleOnly ?? false,
    categories: categories,
    products: products,
  );

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  final _scroll = ScrollController();
  final _search = TextEditingController();

  /// Focused on arrival when the reader tapped SEARCH to get here —
  /// see [ProductBrowseArgs.openKeyboard].
  final _searchFocus = FocusNode();

  late final _browse =
      widget.cubit ??
      ProductListPage.cubitFor(
        subCategoryId: widget.subCategoryId,
        args: widget.args,
        // THE SHOP'S TREE ONLY. `ShopHomeCubit` holds finished pieces;
        // seeding the materials rail from it would put Cups above a
        // list of clay until the real tree landed.
        fallbackCategories: widget.source.isMaterials
            ? const []
            : _warmCategories(),
        locale: _openingLocale,
        source: widget.source,
      );

  /// The language this screen opens in, for the cache key.
  ///
  /// The APP's, not the device's — the reader chooses it in
  /// preferences, and a cache keyed to the phone's would hand back
  /// Arabic rows under an English UI.
  ///
  /// Safe here: `_browse` is `late final` and nothing touches it before
  /// `didChangeDependencies`, which is the first place `Localizations`
  /// is resolvable.
  String get _openingLocale => Localizations.localeOf(context).languageCode;

  /// The tree the SHOP tab already loaded, when this screen was opened
  /// from somewhere that could not hand one over.
  static List<ShopCategory> _warmCategories() {
    if (!getIt.isRegistered<ShopHomeCubit>()) return const [];
    final state = getIt<ShopHomeCubit>().state;
    return state is ShopHomeLoaded ? state.categories : const [];
  }

  /// How close to the bottom asks for the next page.
  static const _loadMoreAt = 400.0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    if (widget.args?.openKeyboard ?? false) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openKeyboard());
    }
  }

  /// Focus the field once the ROUTE has finished arriving.
  ///
  /// One post-frame callback is not enough, and the reason is the
  /// hero: the field is the far end of a flight from the shop tab's
  /// bar, so it is laid out but NOT PAINTED until the flight lands.
  /// Focusing a node whose widget is not on screen quietly does
  /// nothing, and the reader who tapped "search" got a search screen
  /// with no keyboard — needing a second tap to do what the first one
  /// meant.
  ///
  /// The route's own animation is the signal. It is already
  /// `completed` when the page is arrived at without a transition
  /// (a `go`, or reduced motion), so both paths end in the same call.
  void _openKeyboard() {
    if (!mounted) return;
    final route = ModalRoute.of(context);
    final animation = route?.animation;

    if (animation == null || animation.isCompleted) {
      _searchFocus.requestFocus();
      return;
    }

    void onStatus(AnimationStatus status) {
      if (status != AnimationStatus.completed) return;
      animation.removeStatusListener(onStatus);
      if (mounted) _searchFocus.requestFocus();
    }

    animation.addStatusListener(onStatus);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // A product's NAME is the server's, so it only re-says itself when
    // the server is asked again. `didChangeDependencies` fires on mount
    // AND when `Localizations` changes — which is what turns a language
    // switch into a reload instead of leaving Arabic names under an
    // English page.
    unawaited(
      _browse.ensureLoaded(Localizations.localeOf(context).languageCode),
    );
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final remaining = _scroll.position.maxScrollExtent - _scroll.offset;
    if (remaining < _loadMoreAt) unawaited(_browse.loadMore());
  }

  @override
  void dispose() {
    _scroll
      ..removeListener(_onScroll)
      ..dispose();
    _search.dispose();
    _searchFocus.dispose();
    if (widget.cubit == null) unawaited(_browse.close());
    super.dispose();
  }

  Future<void> _openFilters(ProductBrowseState state) async {
    final chosen = await showProductFilterSheet(
      context,
      initial: ProductFilters(
        featuredOnly: state.featuredOnly,
        onSaleOnly: state.onSaleOnly,
        sort: state.sort,
        minPrice: state.minPrice,
        maxPrice: state.maxPrice,
      ),
    );
    // Null means dismissed without choosing — the filters stay as they
    // were rather than being cleared by a swipe.
    if (chosen == null) return;
    _browse.applyFilters(
      featuredOnly: chosen.featuredOnly,
      onSaleOnly: chosen.onSaleOnly,
      sort: chosen.sort,
      minPrice: chosen.minPrice,
      maxPrice: chosen.maxPrice,
    );
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    // The rows on this page carry hero tags, and a search can put the
    // same product in more than one place — the scope hands each tag
    // out once.
    return HeroScope(
      child: Scaffold(
        backgroundColor: context.backgroundColors.scaffoldBackground,
        appBar: TerracottaPageBar(
          title: ShopStrings.title,
          // PINNED. The field below is this screen's main control, and a
          // bar that retreated would take it away exactly when the reader
          // has scrolled far enough to want it.
          pinned: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(_searchBarHeight),
            child: Padding(
              padding: EdgeInsetsDirectional.fromSTEB(
                spacing.md,
                0,
                spacing.md,
                spacing.sm,
              ),
              child: BlocBuilder<ProductBrowseCubit, ProductBrowseState>(
                bloc: _browse,
                buildWhen: (a, b) => a.activeFilters != b.activeFilters,
                // The OTHER END of the shop tab's own field — the same
                // control in the same place, flown rather than
                // replaced. See [HeroTag.searchField].
                builder: (context, state) => ShopSearchField(
                  heroTag: HeroTag.searchField,
                  controller: _search,
                  focusNode: _searchFocus,
                  onChanged: _browse.search,
                  filterCount: state.activeFilters,
                  onFilter: () => unawaited(_openFilters(state)),
                ),
              ),
            ),
          ),
        ),
        body: SafeArea(
          // NEITHER edge. The bar above supplies the top inset, and the
          // page ends in its own `xxl` gutter — a bottom inset on top of
          // that is a second empty band the reader scrolls into and finds
          // nothing in.
          top: false,
          bottom: false,
          child: BlocBuilder<ProductBrowseCubit, ProductBrowseState>(
            bloc: _browse,
            builder: (context, state) => GlobalScrollable(
              controller: _scroll,
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: spacing.md),
                  _CategoryRail(state: state, onTap: _browse.selectCategory),
                  SizedBox(height: spacing.md),
                  _SubCategoryRail(
                    state: state,
                    onTap: _browse.selectSubCategory,
                  ),
                  SizedBox(height: spacing.md),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: spacing.md),
                    child: _Results(
                      state: state,
                      source: widget.source,
                      onRetry: () => unawaited(_browse.refresh()),
                      onToggleFavorite: (id) =>
                          unawaited(_browse.toggleFavorite(id)),
                    ),
                  ),
                  SizedBox(height: spacing.xxl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Room for the field plus the gap under it.
const double _searchBarHeight = 64;

/// The top-level categories.
class _CategoryRail extends StatefulWidget {
  const _CategoryRail({required this.state, required this.onTap});

  final ProductBrowseState state;
  final ValueChanged<int> onTap;

  @override
  State<_CategoryRail> createState() => _CategoryRailState();
}

class _CategoryRailState extends State<_CategoryRail> {
  /// The chosen chip, so the rail can be scrolled to it.
  final _chosen = GlobalKey();

  @override
  void initState() {
    super.initState();
    _reveal();
  }

  @override
  void didUpdateWidget(_CategoryRail old) {
    super.didUpdateWidget(old);
    if (widget.state.selectedCategoryId != old.state.selectedCategoryId) {
      _reveal();
    }
  }

  /// SCROLL TO THE CHOSEN ONE.
  ///
  /// Tapping a category on the home or shop rails opens this screen
  /// with that category already selected — and the rail opened at its
  /// start, so a category far along it was chosen, filtered by, and
  /// nowhere on screen. The reader could see the products and not what
  /// they had picked.
  ///
  /// Centred rather than merely brought into view: the neighbours on
  /// both sides are the useful thing about a rail, and a chip flush
  /// against the trailing edge hides half of them.
  void _reveal() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final at = _chosen.currentContext;
      if (at == null || !mounted) return;
      unawaited(
        Scrollable.ensureVisible(
          at,
          alignment: 0.5,
          duration: AppDurations.normal,
          curve: Curves.easeOutCubic,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final state = widget.state;
    if (state.categoriesLoading) return const SizedBox(height: 96);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: spacing.md),
          child: SectionHeader(title: HomeStrings.browseCategories),
        ),
        SizedBox(height: spacing.sm),
        SizedBox(
          height: 104,
          child: GlobalList.static(
            items: state.categories,
            scrollDirection: Axis.horizontal,
            // EDGE TO EDGE, insetting its own contents — padded from
            // outside, the last tile is clipped with nowhere to scroll.
            style: ListStyle(
              padding: EdgeInsets.symmetric(horizontal: spacing.md),
            ),
            separatorBuilder: (_, _) => SizedBox(width: spacing.sm),
            itemBuilder: (context, category, index) {
              final chosen = category.id == state.selectedCategoryId;
              return CategoryChip(
                // Keyed only when chosen, so `_reveal` has exactly one
                // context to scroll to.
                key: chosen ? _chosen : null,
                label: category.title,
                image: category.image,
                // The tile the reader tapped on home or in the shop
                // flies into this chip — same artwork, same name, new
                // shape.
                heroId: category.id,
                selected: chosen,
                onTap: () => widget.onTap(category.id),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// The sub-categories of whichever category is chosen.
class _SubCategoryRail extends StatelessWidget {
  const _SubCategoryRail({required this.state, required this.onTap});

  final ProductBrowseState state;
  final ValueChanged<int?> onTap;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final subs = state.selectedCategory?.subCategories ?? const [];
    // Nothing at all rather than an empty strip: a category with one
    // sub-category is common, and a rail of one chip is noise.
    if (subs.length < 2) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: spacing.md),
          child: SectionHeader(
            title: ShopStrings.browseSubCategories(
              state.selectedCategory?.title ?? '',
            ),
          ),
        ),
        SizedBox(height: spacing.sm),
        SizedBox(
          // Two lines of label. The chip has no vertical padding of
          // its own any more — it fills this and centres the words in
          // it.
          height: 64,
          child: GlobalList.static(
            items: subs,
            scrollDirection: Axis.horizontal,
            style: ListStyle(
              padding: EdgeInsets.symmetric(horizontal: spacing.md),
            ),
            separatorBuilder: (_, _) => SizedBox(width: spacing.sm),
            itemBuilder: (context, sub, index) => SubCategoryChip(
              label: sub.title,
              selected: sub.id == state.selectedSubCategoryId,
              // Tapping the CURRENT one clears it — the only way back
              // to "everything in this category" once one is chosen.
              onTap: () =>
                  onTap(sub.id == state.selectedSubCategoryId ? null : sub.id),
            ),
          ),
        ),
      ],
    );
  }
}

/// The products, their placeholders, or the reason there are none.
class _Results extends StatelessWidget {
  const _Results({
    required this.state,
    required this.source,
    required this.onRetry,
    required this.onToggleFavorite,
  });

  final ProductBrowseState state;

  /// Which storefront's detail route a row opens. `/shop/products/16`
  /// and `/materials/products/16` are different products.
  final ProductSource source;

  final VoidCallback onRetry;
  final ValueChanged<int> onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    // Placeholders only when there is NOTHING to keep.
    //
    // Re-searching used to swap the list for a skeleton and back on
    // every filter change, so typing made the page flash. The rows
    // already on screen are the closest thing to the answer until the
    // new ones arrive, so they stay and dim.
    if (state.productsLoading && state.products.isEmpty) {
      return const _ResultsSkeleton();
    }

    if (state.products.isEmpty) {
      // A search that matched nothing is not a screen that broke.
      if (state.error != null) {
        return GlobalEmptyState(
          icon: Icons.wifi_off_rounded,
          title: AuthStrings.errorGeneric,
          subtitle: state.error is NetworkException
              ? null
              : state.error!.message,
          primaryAction: GlobalFilledButton(
            text: CommonStrings.retry,
            onPressed: onRetry,
            style: terracottaCtaStyle(showArrow: false),
          ),
        );
      }
      return GlobalEmptyState(
        icon: Icons.search_off_rounded,
        title: ShopStrings.noResults,
        variant: EmptyStateVariant.compact,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // HOW MANY, above the list.
        //
        // The server's `total` for the filters as they stand, which is
        // the whole answer rather than the ten rows paged in so far —
        // and it re-says itself as a search narrows, which is the
        // fastest way to see that a filter did anything.
        //
        // Quiet until a page has landed: a list seeded from
        // `ProductBrowseCache` has rows and no count, and a number
        // taken from `products.length` there would be the size of the
        // last visit's first page.
        if (state.hasTotal) ...[
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              ShopStrings.resultsCount(state.total),
              style: context.textTheme.bodySmall?.copyWith(
                color: context.textColors.secondary,
              ),
            ),
          ),
          SizedBox(height: spacing.sm),
        ],
        // DIMMED while the next answer is on its way, rather than
        // replaced: the reader keeps their place and sees that
        // something is happening.
        AnimatedOpacity(
          opacity: state.productsLoading ? 0.45 : 1,
          duration: AppDurations.fast,
          child: GlobalList<Product>.static(
            items: state.products,
            // The PAGE scrolls, not this: two scrollables would fight,
            // and the outer one is what drives paging.
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            // The results WAVE in — pieces rising one after another
            // as they cross into view.
            //
            // This is the list a search rewrites, and the motion is
            // what says the answer changed. `once` is on by default,
            // so scrolling back up does not replay it.
            style: const ListStyle(
              padding: EdgeInsets.zero,
              scrollIn: ScrollInStyle.wave,
            ),
            separatorBuilder: (_, _) => SizedBox(height: spacing.sm),
            itemBuilder: (context, product, index) => FavoriteProductRow(
              product: product,
              // Without this the row's heart is an `IconButton` with a
              // null `onPressed` — drawn, and dead to the touch.
              onUnfavorite: () => onToggleFavorite(product.id),
              onTap: () => context.pushNamed(
                source.detailRoute,
                pathParameters: {'productId': '${product.id}'},
                // What this row already knew, so the heroes have
                // somewhere to land while the detail page fetches —
                // without it the flight only worked on the way BACK.
                extra: ProductPreview(
                  id: product.id,
                  title: product.title,
                  price: product.price,
                  salePrice: product.salePrice,
                  image: product.image,
                  isFeatured: product.isFeatured,
                  isFavorited: product.isFavorited,
                ),
              ),
            ),
          ),
        ),
        if (state.loadingMore) ...[
          SizedBox(height: spacing.md),
          const Center(child: CircularProgressIndicator.adaptive()),
        ],
      ],
    );
  }
}

/// Placeholder rows in the shape the results will take.
class _ResultsSkeleton extends StatelessWidget {
  const _ResultsSkeleton();

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < 4; i++) ...[
          const SizedBox(
            height: 112,
            child: SkeletonBlock(),
          ),
          SizedBox(height: spacing.sm),
        ],
      ],
    );
  }
}
