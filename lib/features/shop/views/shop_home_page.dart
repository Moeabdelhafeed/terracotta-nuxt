import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_gate.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/strings/auth_strings.dart';
import '../../../core/localization/strings/common_strings.dart';
import '../../../core/localization/strings/home_strings.dart';
import '../../../core/localization/strings/shop_strings.dart';
import '../../../core/tokens/extensions.dart';
import '../../../data/models/terracotta/shop/shop_category.dart';
import '../../../data/models/terracotta/shop/shop_home.dart';
import '../../../shared/module/buttons/global_filled_button.dart';
import '../../../shared/module/buttons/global_icon_button.dart';
import '../../../shared/module/container/global_container.dart';
import '../../../shared/module/empty_state/global_empty_state.dart';
import '../../../shared/module/in_page_hero/global_in_page_hero.dart';
import '../../../shared/module/list/global_list.dart';
import '../../../shared/module/refreshable/global_refreshable.dart';
import '../../../shared/module/scrollable/global_scrollable.dart';
import '../../_shared/favorites_registry.dart';
import '../../_shared/illustrated_header.dart';
import '../../_shared/localized_rebuild.dart';
import '../../_shared/screen_entrance.dart';
import '../../_shared/shared_hero.dart';
import '../../_shared/skeleton_block.dart';
import '../../_shared/tab_entrance.dart';
import '../../_shared/terracotta_cta_style.dart';
import '../../_shared/terracotta_widgets.dart';
import '../../cart/cubits/cart_cubit.dart';
import '../../cart/cubits/cart_state.dart';
import '../../cart/widgets/cart_sheet.dart';
import '../../gift/widgets/gift_credit_sheet.dart';
import '../../gift/widgets/wallet_gift_row.dart';
import '../../home/cubits/live_now_cubit.dart';
import '../../home/widgets/category_strip.dart';
import '../../home/widgets/live_strip.dart';
import '../../home/widgets/product_carousel.dart';
import '../../profile/cubits/wallet_cubit.dart';
import '../../profile/cubits/wallet_state.dart';
import '../../shell/widgets/terracotta_app_bar.dart';
import '../../shell/widgets/terracotta_nav_bar.dart';
import '../cubits/product_counts_cubit.dart';
import '../cubits/shop_home_cubit.dart';
import '../cubits/shop_home_state.dart';
import '../widgets/favorites_sheet.dart';
import '../widgets/shop_widgets.dart';
import 'product_detail_page.dart';
import 'product_list_page.dart';

/// «متجر تيراكوتا» — the shop landing.
///
/// This is the FOURTH bottom-nav destination. The design draws a cart
/// glyph on that tab, but the destination behind it is the shop; the
/// cart itself is a sheet opened from here.
///
/// `GET /api/shop/home` fills the whole screen.
class ShopHomePage extends StatefulWidget {
  const ShopHomePage({this.cubit, super.key});

  /// A cubit to use instead of the app's — the seam a widget test
  /// needs, since the page loads on mount. Null in the app.
  final ShopHomeCubit? cubit;

  @override
  State<ShopHomePage> createState() => _ShopHomePageState();
}

class _ShopHomePageState extends State<ShopHomePage> {
  /// The order strip under the heading. The app's, shared with the
  /// home and workshops tabs.
  late final _live = getIt<LiveNowCubit>();

  /// Shared with the app bar and the nav bar, which both retreat as the
  /// page scrolls.
  final _scroll = ScrollController();

  /// The heading FLYING into the bar as the page collapses — see
  /// [InPageHero]. Nothing is pushed when a page scrolls, so a route
  /// `Hero` has nothing to fire on.
  ///
  /// The search field does NOT have one. See `_openSearch`.
  final _titleMorph = InPageHeroController();

  /// The APP's cubit — every tab is a top-level route, so `context.go`
  /// disposes this State and a page-owned cubit went with it. Not
  /// closed here for the same reason.
  late final _shop = widget.cubit ?? getIt<ShopHomeCubit>();

  /// The wallet behind the balance card. NULLABLE, like every other
  /// locator lookup on a page: a widget test pumps this screen without
  /// the service locator, and a row that cannot say the balance is a
  /// row that does not draw — not a screen that fails to build.
  late final WalletCubit? _wallet = getIt.isRegistered<WalletCubit>()
      ? getIt<WalletCubit>()
      : null;

  /// How many pieces sit behind each «عرض الكل». Shared with the home
  /// tab, which draws the same two sections.
  late final _counts = getIt<ProductCountsCubit>();

  /// Whether this session's one entrance is still going spare.
  ///
  /// Read through [_entrance], never as `_claim ?? false`. A child
  /// list is BUILT before the call that stages it, so a section
  /// reading the raw field got `null` on the first build — no
  /// entrance — and `true` on the second, once staging had claimed it.
  /// The section then animated a beat after everything else, having
  /// already been on screen: the reported "it shows twice".
  bool? _claim;

  /// Claimed on the first READ, whichever part of the page asks first.
  /// Held so a rebuild cannot change its mind mid-animation.
  ///
  /// This one is the page's own header and quick actions, which sit
  /// OUTSIDE the loading switch and are therefore drawn by the same
  /// element in every phase — they cannot arrive twice.
  bool get _entrance => _claim ??= TabEntrance.claim(TabEntranceKey.shop);

  /// The section HEADINGS, which are drawn twice: once by the skeleton
  /// holding the page's shape, once by the real rails. Two slots for
  /// one latch, so whichever phase draws them first owns the arrival
  /// and the other is told it already happened. See [TabEntranceKey].
  bool? _skeletonHeadings;
  bool? _railHeadings;

  /// And the rails themselves, which arrive when the server answers.
  bool? _contentClaim;

  bool get _skeletonEntrance =>
      _skeletonHeadings ??= TabEntrance.claim(TabEntranceKey.shopHeadings);

  bool get _railHeadingsEntrance =>
      _railHeadings ??= TabEntrance.claim(TabEntranceKey.shopHeadings);

  bool get _contentEntrance =>
      _contentClaim ??= TabEntrance.claim(TabEntranceKey.shopContent);

  /// The sections, staged on the FIRST sight of this tab in the
  /// session and left alone on every one after it.
  List<Widget> _staged(List<Widget> sections, {bool heroSafe = false}) =>
      _entrance ? ScreenEntrance.stage(sections, heroSafe: heroSafe) : sections;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // THE BALANCE, for the pair under the quick actions. Not for a
    // guest: `/api/wallet/*` answers 401 for them, and a 401 anywhere
    // is read as the session ending.
    if (_wallet case final wallet? when AuthGate.has(context)) {
      unawaited(wallet.ensureLoaded());
    }
    // The two "happening now" strips. Both routes behind them are the
    // CALLER's own and answer 401 to a guest, so they are asked for
    // only when there is an account.
    if (AuthGate.has(context)) {
      unawaited(_live.ensureLoaded(_locale));
    } else {
      _live.clear();
    }
    // On mount AND when `Localizations` changes above us: category
    // titles and product names come from the server in the language
    // the request asked for.
    unawaited(_shop.ensureLoaded(_locale));
    // The numbers on the two «عرض الكل» buttons. Public, and the same
    // in both languages — so once per launch, not once per visit.
    unawaited(_counts.ensureLoaded());
  }

  String get _locale => Localizations.localeOf(context).languageCode;

  /// The search field's focus, which is what drives the bar.
  ///
  /// Scrolled down, the field is replaced by a glyph; tapping the glyph
  /// reopens it and puts the caret in it, and letting it go collapses
  /// it back. So "is the field open" is really "does the field have
  /// focus", and this is where that is watched.
  final _searchFocus = FocusNode();

  /// Open across a scroll that would otherwise swap the bar back to its
  /// title under the reader's thumb.
  bool _searchOpen = false;

  @override
  void initState() {
    super.initState();
    _searchFocus.addListener(_onSearchFocus);
  }

  void _onSearchFocus() {
    if (!_searchFocus.hasFocus && _searchOpen) {
      setState(() => _searchOpen = false);
    }
  }

  /// Opens the field the glyph stands in for.
  ///
  /// ▸ NOT AN IN-PAGE FLIGHT ◂ — attempted twice, reverted twice, and
  /// the notes are here so a third attempt starts further along.
  ///
  /// Making the field and the glyph two ends of one `InPageHero` does
  /// work for the SCROLL: give `TerracottaAppBar` an `actionMorph`,
  /// SEARCHING IS THE BROWSE SCREEN'S JOB.
  ///
  /// The field on this bar filters the payload the page already has —
  /// the shop landing is one request and nothing below the fold is a
  /// second one. Searching the CATALOGUE means asking the server, and
  /// that screen already exists: it pages, it filters, and it carries
  /// the same field with the same hero tag, so the control flies
  /// across rather than being replaced.
  ///
  /// It opens with the keyboard up. A tap that means "search" must not
  /// need a second tap to type — which is what the previous in-page
  /// expansion could not deliver: the field was laid out but not
  /// PAINTED until the flight landed, so the focus had nothing to
  /// attach to, and waiting for the landing did not take it either.
  void _openSearch() {
    final state = _shop.state;
    context.pushNamed(
      'product-list',
      pathParameters: {'subCategoryId': '0'},
      extra: ProductBrowseArgs(
        // The MERGED tree travels, so the browse screen does not fetch
        // its own and lose the artwork this payload carries.
        categories: state is ShopHomeLoaded ? state.categories : const [],
        openKeyboard: true,
      ),
    );
  }

  @override
  void dispose() {
    _searchFocus
      ..removeListener(_onSearchFocus)
      ..dispose();
    _scroll.dispose();
    _titleMorph.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    // ONE scope per screen. The rails on this page can hold the SAME
    // product twice — the live home payload puts products 1 and 13 in
    // both the featured and the offers rail — and two heroes sharing a
    // tag throws. The scope hands each tag out once.
    return HeroScope(
      child: TerracottaNavBar.wrapScaffold(
        context,
        currentIndex: 3,
        // The rail goes AROUND the scaffold: it has to sit in
        // front of the app bar and move it along, and nothing
        // inside the body can do either.
        child: Scaffold(
          backgroundColor: context.backgroundColors.scaffoldBackground,
          // The bar floats over the page and retreats with it, so the body
          // reaches underneath — reserving the space leaves a white band
          // where the bar used to be.
          // The header's stars run up behind the bar, so the bar has no
          // surface of its own and the body reaches under it.
          extendBodyBehindAppBar: true,
          appBar: TerracottaAppBar(
            controller: _scroll,
            // STAYS. This page opens on drawn artwork the bar floats
            // over, and a bar that retreats and returns across it reads
            // as the drawing flickering rather than as chrome getting
            // out of the way.
            hideOnScroll: false,
            collapsedTitle: ShopStrings.title,
            titleMorph: _titleMorph,
            // The SEARCH rides in the bar rather than in the page: it is
            // the first thing this screen is for, and the bell and the
            // language toggle sit beside it.
            // The ROUTE flight to the browse screen's own field — the
            // same control in the same place, flown rather than replaced.
            //
            // NOT an in-page morph into the glyph beside it. That fight
            // is `forceExpanded`'s: tapping the glyph reopens the field
            // while the scroll offset still says collapsed, so the bar
            // and the flight disagree about which end is showing, and
            // the module ignores a request made mid-air rather than
            // queueing it. The fold is the bar's own and it works; a
            // second mechanism over the top of it did not.
            expanded: ShopSearchField(
              // The FIELD flies, not the row — see
              // [ShopSearchField.heroTag]. This bar has no filter button
              // beside it; the browse screen does, and carrying one out
              // of here would land it as though it had come from
              // somewhere.
              heroTag: HeroTag.searchField,
              // A WAY THROUGH, not an input. See `_openSearch`: the
              // catalogue is searched on the browse screen, which asks
              // the server and pages the answer. Typing here filtered
              // only the handful of rows this payload happens to carry.
              onTap: _openSearch,
            ),
            // The glyph that stands in for the field once it has scrolled
            // away — same pill as the bell and the language toggle.
            collapsedAction: _SearchGlyph(onPressed: _openSearch),
            forceExpanded: _searchOpen,
            transparent: true,
          ),
          extendBody: true,
          // NOTHING HERE in a short window — the destinations are
          // on a rail over the body instead. The slot has no
          // height limit, so a rail put in it takes the screen.
          bottomNavigationBar: TerracottaNavBar.bottomSlot(
            context,
            currentIndex: 3,
            scrollController: _scroll,
          ),
          body: SafeArea(
            // TOP off: `extendBodyBehindAppBar` folds the whole rendered
            // bar — status inset AND its 56pt toolbar — into the body's own
            // `padding.top`, so a default `SafeArea` here does not clear the
            // notch, it clears the app bar. That band is OUTSIDE the
            // scrollable, so it stayed behind when the bar retreated and
            // left a strip of empty page where the bar had been.
            top: false,
            bottom: false,
            child: GlobalRefreshable(
              onRefresh: () async {
                // The counts come down with the page: a stale «(٤)»
                // beside freshly loaded pieces is what this line of the
                // header can most easily get wrong.
                await Future.wait([_shop.refresh(_locale), _counts.refresh()]);
              },
              style: RefreshableStyle(
                edgeOffset: MediaQuery.paddingOf(context).top + kToolbarHeight,
              ),
              child: GlobalScrollable(
                controller: _scroll,
                // ALWAYS draggable, even when the content fits: Flutter
                // drops the drag recogniser when there is nothing to
                // scroll.
                physics: const AlwaysScrollableScrollPhysics(),
                child: GlobalContainer.shell(
                  // NO side gutter on the page: the rails run edge to edge
                  // and inset their own contents, so each non-rail child is
                  // guttered instead — the same arrangement `HomePage` uses.
                  padding: EdgeInsetsDirectional.only(
                    // The RAIL's side in a short window, the BAR's height
                    // otherwise — one of the two is always zero.
                    start: TerracottaNavBar.reservedWidthIn(context),
                    bottom:
                        TerracottaNavBar.reservedHeightIn(context) + spacing.md,
                  ),
                  child: BlocBuilder<ShopHomeCubit, ShopHomeState>(
                    bloc: _shop,
                    builder: (context, state) => Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      // ONCE per launch, and a FADE rather than a rise:
                      // the live strip flies between the three tabs that
                      // draw it, and every card on the rails flies into
                      // its detail page. An entrance above a hero moves
                      // the box its flight is measured against. See
                      // [TabEntrance] and [EntranceMotion.fade].
                      children: _staged([
                        // CLEAR OF THE BAR, then a breath.
                        //
                        // The body reaches under the app bar — that is what
                        // stops a band of empty page being left behind when
                        // the bar retreats — so the first thing in it
                        // starts at the top of the SCREEN, beneath the
                        // status inset and the toolbar both. The heading is
                        // top-aligned in its box, so without this it starts
                        // underneath them.
                        //
                        // Same sum the refresh indicator uses for its own
                        // edge offset, which is the other thing on this page
                        // that has to sit below the bar.
                        SizedBox(
                          height: kToolbarHeight + spacing.lg,
                        ),
                        // The heading and the shortcuts are the page's own
                        // and never wait on the server.
                        // STAGES ITSELF: the drawings, the title and the
                        // line under it are three arrivals, not one
                        // block. See [EntranceSkip].
                        EntranceSkip(
                          child: _ShopIntro(
                            entrance: _entrance,
                            titleMorph: _titleMorph,
                          ),
                        ),
                        // Under the heading: an order already placed is
                        // news, and the tiles below it are navigation.
                        const _Gutter(child: LiveOrderSlot()),
                        ScreenEntrance(
                          child: _Gutter(
                            child: BlocBuilder<CartCubit, CartState>(
                              bloc: getIt<CartCubit>(),
                              buildWhen: (a, b) => a.pieceCount != b.pieceCount,
                              builder: (context, cart) => ShopQuickActions(
                                // The tile already had a badge slot; it was
                                // being handed nothing. Same count as the bar
                                // above it, from the same cart.
                                cartCount: cart.pieceCount,
                                onCart: () => unawaited(showCartSheet(context)),
                                onFavorites: () => showFavoritesSheet(
                                  context,
                                  // The app's registry, so a row removed in
                                  // the sheet empties the heart on the rail
                                  // behind it.
                                  registry: getIt<FavoritesRegistry>(),
                                ),
                                // GATED. `GET /api/shop/orders` is the
                                // reader's own and answers 401 without a
                                // session, so a guest tapping this
                                // arrived at a screen that could only
                                // fail. Ask for the account instead.
                                onOrders: () => unawaited(
                                  AuthGate.demand(
                                    context,
                                    action: () =>
                                        context.pushNamed('my-orders'),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: spacing.md),
                        // THE BALANCE AND THE GIFT, the same pair the
                        // workshops tab carries — one widget, so the
                        // two tabs cannot drift. The shop is where the
                        // balance is spent, which makes it at least as
                        // good a place to see it.
                        if (_wallet case final wallet?)
                          ScreenEntrance(
                            child: _Gutter(
                              child: BlocBuilder<WalletCubit, WalletState>(
                                bloc: wallet,
                                builder: (context, wallet) => WalletGiftRow(
                                  balance: wallet.balance ?? '0.00',
                                  onGiftTap: () =>
                                      unawaited(showGiftCreditSheet(context)),
                                  // GATED. `GET /api/wallet/transactions`
                                  // is the reader's own and answers 401
                                  // without a session — and a 401 is read
                                  // as the session ending, which would
                                  // evict a guest rather than just fail.
                                  onOpenWallet: () => unawaited(
                                    AuthGate.demand(
                                      context,
                                      action: () => context.pushNamed('wallet'),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        SizedBox(height: spacing.lg),
                        // STAGES ITSELF — see [EntranceSkip]. Its own
                        // headings and rails are what the reader watches
                        // arrive; fading the block as a unit on top of
                        // that is two clocks over the same pixels.
                        EntranceSkip(
                          child: switch (state) {
                            // NOT guttered: it carries its own, because its
                            // rails run edge to edge exactly like the real
                            // ones.
                            ShopHomeLoading() => _ShopSkeleton(
                              entrance: _skeletonEntrance,
                            ),
                            ShopHomeFailed(:final error) => _Gutter(
                              child: _ShopError(
                                error: error,
                                onRetry: () =>
                                    unawaited(_shop.refresh(_locale)),
                              ),
                            ),
                            ShopHomeLoaded(:final isEmptySearch)
                                when isEmptySearch =>
                              _Gutter(
                                child: GlobalEmptyState(
                                  icon: Icons.search_off_rounded,
                                  title: ShopStrings.noResults,
                                  variant: EmptyStateVariant.compact,
                                ),
                              ),
                            // FILTERED, not the raw payload.
                            ShopHomeLoaded(
                              :final filtered,
                              :final categories,
                            ) =>
                              _ShopRails(
                                payload: filtered,
                                categories: categories,
                                counts: _counts,
                                headings: _railHeadingsEntrance,
                                content: _contentEntrance,
                                onToggleFavorite: (id) =>
                                    unawaited(_shop.toggleFavorite(id)),
                              ),
                          },
                        ),
                      ], heroSafe: true),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The three rails the shop landing is made of.
///
/// Each is a HORIZONTAL list, the same shape the home screen uses — a
/// grid here made the page a wall of tiles and buried the offers below
/// the fold.
class _ShopRails extends StatelessWidget {
  const _ShopRails({
    required this.payload,
    required this.categories,
    required this.counts,
    required this.onToggleFavorite,
    this.headings = false,
    this.content = false,
  });

  /// Whether the section HEADINGS arrive here, rather than having
  /// arrived with the skeleton that drew them first.
  final bool headings;

  /// Whether the rails do — the server answering, which is a different
  /// moment from the page opening.
  final bool content;

  /// A heading: the page's own words, which the skeleton already drew
  /// in this same place. It keeps the RISE, since nothing in it flies.
  Widget _chrome(Widget section) =>
      headings ? ScreenEntrance(child: section) : EntranceSkip(child: section);

  /// A rail, which is the server's.
  Widget _content(Widget section) =>
      content ? section : EntranceSkip(child: section);

  List<Widget> _staged(List<Widget> sections) =>
      ScreenEntrance.stage(sections, from: 3, heroSafe: true);

  final ShopHome payload;

  /// The MERGED tree — artwork from the landing payload,
  /// sub-categories from the category endpoint. Handed to the browse
  /// screen so it does not fetch its own and lose the pictures.
  final List<ShopCategory> categories;

  /// How many pieces each «عرض الكل» opens onto. Handed in rather than
  /// looked up, so nothing here reaches for `getIt` in a build.
  final ProductCountsCubit counts;

  final ValueChanged<int> onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      // Continuing the page's own count rather than starting again:
      // the heading and the quick actions above have already used the
      // first slots, and restarting here would put the first rail's
      // arrival back on top of theirs.
      children: _staged([
        if (categories.isNotEmpty) ...[
          _chrome(
            _Gutter(child: SectionHeader(title: HomeStrings.browseCategories)),
          ),
          SizedBox(height: spacing.sm),
          // EDGE TO EDGE: the strip insets its own contents, so it is
          // NOT guttered — padded from outside, its last tile is
          // clipped with nowhere to scroll into.
          _content(
            CategoryStrip.shop(
              categories: categories,
              // Tapping a category opens the browse screen on it.
              // The tree travels WITH the tap: the browse screen used to
              // re-fetch it, which cost a request and lost the artwork,
              // because `/shop/categories` carries no `image`.
              onTap: (id) => context.pushNamed(
                'product-list',
                pathParameters: {'subCategoryId': '0'},
                extra: ProductBrowseArgs(
                  categoryId: id,
                  categories: categories,
                ),
              ),
            ),
          ),
          SizedBox(height: spacing.lg),
        ],
        // WITHDRAWN: the second storefront's way in. See the block in
        // `app_routes.dart` — this card is the ONLY thing in the app
        // that points at `/materials`, so commenting it out is what
        // makes the section unreachable rather than merely unlinked.
        //
        // _chrome(_Gutter(child: const _MaterialsCard())),
        // SizedBox(height: spacing.lg),
        if (payload.featuredProducts.isNotEmpty) ...[
          _chrome(
            _Gutter(
              child: CountedSectionHeader(
                counts: counts,
                pick: (c) => c.featured,
                title: HomeStrings.featured,
                // With the filter on and NO category chosen — the rail is
                // the whole shop's featured pieces, so narrowing it to
                // the first category would answer a different question.
                // The tree still travels, so the screen does not refetch.
                onAction: () => context.pushNamed(
                  'product-list',
                  pathParameters: {'subCategoryId': '0'},
                  extra: ProductBrowseArgs(
                    categories: categories,
                    featuredOnly: true,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: spacing.sm),
          _content(
            ProductCarousel.shop(
              items: payload.featuredProducts,
              onToggleFavorite: onToggleFavorite,
              onOpen: (tile) => context.pushNamed(
                'product-detail',
                pathParameters: {'productId': '${tile.id}'},
                // What the card already knew, so the flight has somewhere
                // to land while the page fetches.
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
          ),
          SizedBox(height: spacing.lg),
        ],
        if (payload.offers.isNotEmpty) ...[
          _chrome(
            _Gutter(
              child: CountedSectionHeader(
                counts: counts,
                pick: (c) => c.onSale,
                title: HomeStrings.offers,
                onAction: () => context.pushNamed(
                  'product-list',
                  pathParameters: {'subCategoryId': '0'},
                  extra: ProductBrowseArgs(
                    categories: categories,
                    onSaleOnly: true,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: spacing.sm),
          _content(
            ProductCarousel.shop(
              items: payload.offers,
              onToggleFavorite: onToggleFavorite,
              onOpen: (tile) => context.pushNamed(
                'product-detail',
                pathParameters: {'productId': '${tile.id}'},
                // What the card already knew, so the flight has somewhere
                // to land while the page fetches.
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
          ),
        ],
      ]),
    );
  }
}

/// The page's side gutter, applied per child.
///
/// The page itself has none: a horizontal rail runs to both screen
/// edges and pads its own contents, and guttered from outside its last
/// card is clipped with nowhere to scroll into.
class _Gutter extends StatelessWidget {
  const _Gutter({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    // The same token the rails pass as their list padding — symmetric,
    // so there is no side to it and nothing to mirror.
    padding: EdgeInsets.symmetric(horizontal: context.spacing.md),
    child: child,
  );
}

/// Placeholders in the shape the rails will take.
///
/// Only what the SERVER has to answer for shimmers. The section
/// headings are the app's own — the same three words whatever
/// `GET /api/shop/home` says — so shimmering them pretends to wait for
/// something already here, and the page dissolves and reassembles
/// instead of holding its shape while the content arrives into it.
/// Same arrangement as `HomePage`.
class _ShopSkeleton extends StatelessWidget {
  const _ShopSkeleton({this.entrance = false});

  /// Whether the page's own headings arrive as it opens.
  ///
  /// The skeleton is where they arrive from on a cold load: it draws
  /// the REAL headings — shimmering four words that are already here
  /// would pretend to wait for them — so this is the moment the reader
  /// watches the page assemble. See [TabEntranceKey].
  final bool entrance;

  /// A heading. The placeholder rails stay still: a grey block that
  /// fades in and then shimmers is two waits, one after another.
  Widget _chrome(Widget section) =>
      entrance ? ScreenEntrance(child: section) : EntranceSkip(child: section);

  /// One grey block, shimmering — and it really does now. See
  /// [SkeletonBlock].
  Widget _block(BuildContext context) => const SkeletonBlock();

  /// A rail of placeholder cards, edge to edge like the real one.
  Widget _rail(
    BuildContext context, {
    required double height,
    required double width,
  }) {
    final spacing = context.spacing;
    // `GlobalList`, not a bare `ListView` — the adoption sweeps hold
    // every feature page to it.
    return SizedBox(
      height: height,
      child: GlobalList<int>.static(
        items: const [0, 1, 2, 3],
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        style: ListStyle(
          padding: EdgeInsets.symmetric(horizontal: spacing.md),
        ),
        separatorBuilder: (_, _) => SizedBox(width: spacing.sm),
        itemBuilder: (context, _, _) =>
            SizedBox(width: width, child: _block(context)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: ScreenEntrance.stage([
        // REAL headings, placeholder rails.
        _chrome(
          _Gutter(child: SectionHeader(title: HomeStrings.browseCategories)),
        ),
        SizedBox(height: spacing.sm),
        EntranceSkip(child: _rail(context, height: 94, width: 78)),
        SizedBox(height: spacing.lg),
        _chrome(_Gutter(child: SectionHeader(title: HomeStrings.featured))),
        SizedBox(height: spacing.sm),
        EntranceSkip(child: _rail(context, height: 182, width: 133)),
        SizedBox(height: spacing.lg),
        _chrome(_Gutter(child: SectionHeader(title: HomeStrings.offers))),
        SizedBox(height: spacing.sm),
        EntranceSkip(child: _rail(context, height: 182, width: 133)),
      ], from: 3),
    );
  }
}

/// Nothing arrived.
class _ShopError extends StatelessWidget {
  const _ShopError({required this.error, required this.onRetry});

  final AppException error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => GlobalEmptyState(
    icon: Icons.wifi_off_rounded,
    title: AuthStrings.errorGeneric,
    // Transport failures carry Dio's wording, which names hosts and
    // sockets and means nothing to a customer.
    subtitle: error is NetworkException ? null : error.message,
    primaryAction: GlobalFilledButton(
      text: CommonStrings.retry,
      onPressed: onRetry,
      style: terracottaCtaStyle(showArrow: false),
    ),
  );
}

/// «متجر تيراكوتا» and its line, with a star either side.
///
/// The same anatomy as the gallery's and the workshops' headers, with
/// only the two stars — the shop's own drawings are the shortcut tiles
/// below it.
class _ShopIntro extends StatelessWidget {
  const _ShopIntro({this.entrance = false, this.titleMorph});

  /// Passed straight through to [IllustratedHeader] — the drawings and
  /// the two lines of words arrive one after another, once per launch.
  final bool entrance;

  /// And so is this — the heading is endpoint 0 of the flight into the
  /// bar's own title.
  final InPageHeroController? titleMorph;

  static const _star = 'assets/images/star-illustration.png';

  @override
  Widget build(BuildContext context) {
    // The words below are read HERE, so this build has to run again
    // when the language changes — see `dependOnLanguage`.
    dependOnLanguage(context);

    return IllustratedHeader(
      entrance: entrance,
      titleMorph: titleMorph,
      mirrorKey: const ValueKey('shop-header-mirror'),
      title: ShopStrings.title,
      subtitle: ShopStrings.subtitle,
      // Shorter than the other two, and shorter again after a look at
      // it on screen: there is no scene here, only the heading and the
      // pair of stars under it, so the box was mostly air above the
      // words. The other tabs keep their 300 — this is the one page
      // that needed less.
      height: 168,
      // TOP, not centred: with no scene above the heading there is
      // nothing for centring to balance it against, and it read as a
      // band of empty page under the search field.
      wordsAt: Alignment.topCenter,
      // PHYSICAL sides, read as the Arabic composition — `right` is the
      // START edge. See `IllustratedHeader`.
      art: const [
        HeaderArt(asset: _star, width: 68, height: 68, bottom: 8, right: 16),
        HeaderArt(asset: _star, width: 60, height: 60, bottom: 16, left: 20),
      ],
    );
  }
}

/// The search glyph the bar wears once the field has scrolled away.
///
/// Same pill as the bell and the language toggle, because it does the
/// same kind of job: it is the field, folded up.
class _SearchGlyph extends StatelessWidget {
  const _SearchGlyph({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => GlobalIconButton(
    iconData: Icons.search_rounded,
    onPressed: onPressed,
    semanticLabel: ShopStrings.searchHint,
    // SMALL. The default box is sized for a labelled button; on a bare
    // glyph it reads as a slab.
    size: ButtonSize.small,
    style: ButtonStateStyle(
      backgroundColor: TerracottaAppBar.plate(context),
      foregroundColor: TerracottaAppBar.glyph(context),
    ),
  );
}

// /// «الخامات والأدوات» — the way into the studio's second storefront.
// ///
// /// Says the thing a reader would otherwise have to discover: this goes
// /// in the SAME basket. A second shop normally means a second cart, and
// /// here a mug and a bag of clay check out as one order with one
// /// delivery fee.
// class _MaterialsCard extends StatelessWidget {
//   const _MaterialsCard();
//
//   @override
//   Widget build(BuildContext context) {
//     final spacing = context.spacing;
//     final radius = BorderRadius.circular(context.radii.lg);
//     final accent = context.primaryColors.accent;
//
//     return Material(
//       color: accent.withValues(alpha: 0.08),
//       borderRadius: radius,
//       child: InkWell(
//         onTap: () => context.pushNamed('materials'),
//         borderRadius: radius,
//         child: Padding(
//           padding: EdgeInsets.all(spacing.md),
//           child: Row(
//             children: [
//               Icon(
//                 Icons.handyman_outlined,
//                 size: context.iconSizes.lg,
//                 color: accent,
//               ),
//               SizedBox(width: spacing.md),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Text(
//                       ShopStrings.materials,
//                       style: context.textTheme.titleSmall?.copyWith(
//                         color: context.textColors.primary,
//                       ),
//                     ),
//                     SizedBox(height: spacing.xs),
//                     Text(
//                       ShopStrings.materialsSubtitle,
//                       style: context.textTheme.labelMedium?.copyWith(
//                         color: context.textColors.secondary,
//                       ),
//                     ),
//                     SizedBox(height: spacing.xs),
//                     Text(
//                       ShopStrings.materialsOneBasket,
//                       style: context.textTheme.labelSmall?.copyWith(
//                         color: accent,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               Icon(
//                 Icons.arrow_forward_rounded,
//                 size: context.iconSizes.sm,
//                 color: accent,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
