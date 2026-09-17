import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_gate.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/strings/auth_strings.dart';
import '../../../core/localization/strings/common_strings.dart';
import '../../../core/localization/strings/home_strings.dart';
import '../../../core/localization/strings/nav_strings.dart';
import '../../../core/notifications/notification_opt_in.dart';
import '../../../core/tokens/extensions.dart';
import '../../../data/models/terracotta/content/home_banner.dart';
import '../../../data/models/terracotta/content/home_payload.dart';
import '../../../data/services/media/dynamic_assets.dart';
import '../../../shared/module/buttons/global_filled_button.dart';
import '../../../shared/module/carousel/global_carousel.dart';
import '../../../shared/module/container/global_container.dart';
import '../../../shared/module/empty_state/global_empty_state.dart';
import '../../../shared/module/image/global_image.dart';
import '../../../shared/module/list/global_list.dart';
import '../../../shared/module/refreshable/global_refreshable.dart';
import '../../../shared/module/scrollable/global_scrollable.dart';
import '../../_shared/account_refresh.dart';
import '../../_shared/screen_entrance.dart';
import '../../_shared/shared_hero.dart';
import '../../_shared/skeleton_block.dart';
import '../../_shared/tab_entrance.dart';
import '../../_shared/terracotta_cta_style.dart';
import '../../_shared/terracotta_image.dart';
import '../../_shared/terracotta_widgets.dart';
import '../../auth/widgets/verify_account_card.dart';
import '../../shell/widgets/terracotta_app_bar.dart';
import '../../shell/widgets/terracotta_nav_bar.dart';
import '../../shop/cubits/product_counts_cubit.dart';
import '../../shop/cubits/shop_home_cubit.dart';
import '../../shop/views/product_detail_page.dart';
import '../../shop/views/product_list_page.dart';
import '../cubits/home_cubit.dart';
import '../cubits/home_state.dart';
import '../cubits/live_now_cubit.dart';
import '../data/banner_destination.dart';
import '../widgets/banner_frost.dart';
import '../widgets/category_strip.dart';
import '../widgets/home_greeting.dart';
import '../widgets/live_strip.dart';
import '../widgets/product_carousel.dart';

/// The home screen.
///
/// `GET /api/home` fills almost all of it in ONE call — banners,
/// categories, the active booking, featured pieces and offers. Do not
/// assemble this page out of the shop endpoints; that is more calls for
/// the same pixels and the two can disagree.
///
/// Two things are NOT in that call and need their own:
///   • the greeting name — `GET /api/user`
///   • the workshops row  — `GET /api/workshops`
class HomePage extends StatefulWidget {
  const HomePage({this.cubit, super.key});

  /// A cubit to use instead of making one.
  ///
  /// The seam a widget test needs: the page loads `GET /api/home` on
  /// mount, and a test has no network — without this every test of the
  /// laid-out page would be testing the skeleton. Null in the app,
  /// which is the only caller that should ever leave it null.
  final HomeCubit? cubit;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  /// Owned here because TWO things read it: the list scrolls it and the
  /// app bar watches it to know when the greeting should give way.
  final _scroll = ScrollController();

  /// The APP's cubit, not this page's — every tab is a top-level
  /// route, so `context.go` disposes this State and a page-owned cubit
  /// went with it, re-requesting everything on the way back.
  ///
  /// It is therefore NOT closed here: closing a singleton on the way
  /// out of one tab breaks it for every later visit.
  late final _home = widget.cubit ?? getIt<HomeCubit>();

  /// The app's, shared with the workshops and shop tabs.
  late final _live = getIt<LiveNowCubit>();

  /// How many pieces sit behind each «عرض الكل». Shared with the shop
  /// tab, which draws the same two sections.
  late final _counts = getIt<ProductCountsCubit>();

  /// The HEADINGS' one arrival, and which phase got it.
  ///
  /// Two slots for one latch. The skeleton and the loaded page draw
  /// the same section headings, so whichever is built first owns the
  /// arrival and the other is told, honestly, that it already
  /// happened. Memoised per phase because a rebuild inside a phase
  /// must not change its mind mid-animation — swapping the staged
  /// column for a bare one leaves the rows wherever the fade got to.
  bool? _skeletonHeadings;
  bool? _bodyHeadings;

  /// And the CONTENT's, which is a different moment: the server
  /// answering, not the page opening.
  bool? _bodyContent;

  bool get _skeletonEntrance =>
      _skeletonHeadings ??= TabEntrance.claim(TabEntranceKey.homeHeadings);

  bool get _bodyHeadingsEntrance =>
      _bodyHeadings ??= TabEntrance.claim(TabEntranceKey.homeHeadings);

  bool get _bodyContentEntrance =>
      _bodyContent ??= TabEntrance.claim(TabEntranceKey.homeContent);

  /// The SHOP's, warmed from here — see `didChangeDependencies`. Not
  /// closed: it is the app's, and the shop tab owns it.
  late final _shop = getIt<ShopHomeCubit>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Where the load is asked for, rather than in the field
    // initialiser. This runs on mount AND whenever `Localizations`
    // changes above us, which is exactly the two moments the data
    // could be stale: arriving with nothing, and arriving after the
    // reader switched language. `ensureLoaded` decides which.
    unawaited(_home.ensureLoaded(_locale));

    // WARM THE STUDIO'S ARTWORK. Every dynamic asset already shows
    // its bundled drawing while a remote file downloads, so nothing
    // waits on this — it only means the swap has usually happened
    // before the screen carrying it is reached. See [DynamicAssets].
    if (getIt.isRegistered<DynamicAssets>()) {
      unawaited(getIt<DynamicAssets>().precache(context));
    }

    // THE NOTIFICATION PERMISSION, asked here and nowhere else.
    //
    // Android 13+ shows nothing at all without `POST_NOTIFICATIONS`,
    // and nothing in this app had ever asked for it — pushes arrived
    // and were logged, and the device stayed silent whenever the app
    // was not in front. Home is the first screen after the splash and
    // every push this backend sends is about the reader's own booking
    // or order. See [NotificationOptIn].
    unawaited(NotificationOptIn.askOnce());

    // WARM THE SHOP, from the tab everyone lands on.
    //
    // Both tabs draw the same categories and the same products, and
    // those elements fly between them — but a hero needs BOTH ends, and
    // the shop tab shows a skeleton until its own payload lands. So the
    // first switch out of home flew nothing while the way back worked,
    // which is exactly the asymmetry it looked like.
    //
    // One request, for a public payload, on the screen the reader
    // starts on. It also makes the first tab switch instant instead of
    // a skeleton, which is worth it on its own.
    unawaited(_shop.ensureLoaded(_locale));
    // The numbers on the two «عرض الكل» buttons. Public, and the same
    // in both languages — so once per launch, not once per visit.
    unawaited(_counts.ensureLoaded());
    // The two "happening now" strips. Both routes behind them are the
    // CALLER's own and answer 401 to a guest, so they are asked for
    // only when there is an account.
    if (AuthGate.has(context)) {
      unawaited(_live.ensureLoaded(_locale));
    } else {
      _live.clear();
    }
  }

  /// The language the server should answer in. `Accept-Language` is
  /// resolved per request from `PreferencesCubit`, so a reload after a
  /// switch comes back translated with nothing else to do.
  String get _locale => Localizations.localeOf(context).languageCode;

  @override
  void dispose() {
    _scroll.dispose();
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
        currentIndex: 0,
        // The rail goes AROUND the scaffold: it has to sit in
        // front of the app bar and move it along, and nothing
        // inside the body can do either.
        child: Scaffold(
          backgroundColor: context.backgroundColors.scaffoldBackground,
          // Both bars RETREAT rather than shrink, so the body has to reach
          // under them. Without these the `Scaffold` keeps reserving the
          // height either bar reported and the retreat just exposes a white
          // band where the bar used to be — it leaves, and its hole stays.
          //
          // The page's own padding already clears the bars at rest.
          extendBodyBehindAppBar: true,
          extendBody: true,
          // The greeting used to be the first row of the page and scrolled
          // away with it, taking the bell along. Both belong to the SCREEN:
          // the bell is wanted wherever the reader has got to, and the
          // greeting simply stops being a greeting once the page has moved.
          appBar: TerracottaAppBar(
            controller: _scroll,
            collapsedTitle: HomeStrings.title,
            expanded: const HomeGreeting(key: ValueKey('greeting')),
          ),
          // Home is the first tab. The bar floats clear of the page and
          // retreats with it, so a long scroll is not spent looking at
          // chrome.
          // NOTHING HERE in a short window — the destinations are
          // on a rail over the body instead. The slot has no
          // height limit, so a rail put in it takes the screen.
          bottomNavigationBar: TerracottaNavBar.bottomSlot(
            context,
            currentIndex: 0,
            scrollController: _scroll,
          ),
          body: SafeArea(
            // NOT top or bottom. `extendBodyBehindAppBar` / `extendBody`
            // work by folding each bar's height into `MediaQuery.padding`,
            // and a `SafeArea` turns padding into a FIXED band outside the
            // scrollable — so the space the bar used to occupy stayed put
            // when the bar retreated, which is the white gap this fixes.
            //
            // The clearance belongs INSIDE the scroll instead, as the
            // content's own padding: it holds the first row clear of the
            // bar at rest, and scrolls away with everything else.
            top: false,
            bottom: false,
            // The insets the two bars used to be given by the `Scaffold`.
            // The bars float ON the page rather than sitting above and
            // below it, so the content starts below one and stops above the
            // other.
            // PULL TO REFRESH. The page is one request, so a pull re-runs
            // it — and a pull that fails leaves the page it already has
            // (see `HomeCubit.load`).
            child: GlobalRefreshable(
              onRefresh: () async {
                // The counts go with it: pulling the page down is the
                // reader asking for what is true NOW, and a stale «(٤)»
                // beside fresh pieces is the one thing this line of the
                // header can get wrong.
                // And WHO THEY ARE — the greeting is their name and
                // the strip is their booking, both of which the
                // studio can change without this app hearing about
                // it. See [AccountRefresh]; a no-op for a guest.
                await Future.wait([
                  _home.refresh(_locale),
                  _counts.refresh(),
                  AccountRefresh.user(context),
                ]);
              },
              // The spinner has to start BELOW the app bar.
              //
              // The body reaches behind the bar (`extendBodyBehindAppBar`),
              // so the scrollable's own top edge is the top of the screen —
              // and the indicator, which hangs off that edge, came down
              // behind the bar where nobody could see it. `edgeOffset`
              // moves the edge it hangs from.
              style: RefreshableStyle(
                edgeOffset: MediaQuery.paddingOf(context).top + kToolbarHeight,
              ),
              child: GlobalScrollable(
                controller: _scroll,
                // ALWAYS draggable, even when the content fits.
                //
                // Flutter drops the drag recogniser outright when
                // `minScrollExtent == maxScrollExtent`, so a short page
                // does not scroll AND never overscrolls — which is what a
                // `RefreshIndicator` listens for. Three albums fit on a
                // phone, and the page that most needs pulling to refresh
                // is the one with nothing on it.
                physics: const AlwaysScrollableScrollPhysics(),
                child: GlobalContainer.shell(
                  // VERTICAL only.
                  //
                  // The gutter used to live here, on the whole column, which
                  // meant the horizontally scrolling rails were boxed inside
                  // it: a category could never reach the screen edge, and the
                  // last one was clipped mid-tile with no room to scroll into.
                  // A rail has to run edge to edge and inset its own CONTENTS
                  // instead, so the first item lines up with the headings
                  // above it and the last one scrolls fully into view.
                  //
                  // So the gutter now belongs to each section that does not
                  // scroll sideways — `_Gutter` below — and to the rails' own
                  // list padding.
                  padding: EdgeInsetsDirectional.fromSTEB(
                    // THE RAIL'S SIDE in a short window, where the
                    // destinations stand down the leading edge instead
                    // of along the bottom. Zero in portrait.
                    TerracottaNavBar.reservedWidthIn(context),
                    // The bar occupies the STATUS BAR as well as the toolbar,
                    // and the `SafeArea` above deliberately no longer applies
                    // that inset — so `kToolbarHeight` alone left the first
                    // row tucked under the bar by the height of the status
                    // bar, which is 47 points on a notched phone and 0 in a
                    // test. Read it here, where it is still available.
                    MediaQuery.paddingOf(context).top +
                        kToolbarHeight +
                        spacing.md,
                    0,
                    TerracottaNavBar.reservedHeightIn(context) + spacing.md,
                  ),
                  child: BlocBuilder<HomeCubit, HomeState>(
                    bloc: _home,
                    builder: (context, state) => switch (state) {
                      HomeLoading() => _HomeSkeleton(
                        entrance: _skeletonEntrance,
                      ),
                      HomeFailed(:final error) => _HomeError(
                        error: error,
                        onRetry: () => unawaited(_home.refresh(_locale)),
                      ),
                      HomeLoaded(:final payload) => _HomeBody(
                        payload: payload,
                        counts: _counts,
                        // TWO answers, because there are two arrivals on
                        // this page and they do not happen at the same
                        // time. See [TabEntranceKey].
                        headings: _bodyHeadingsEntrance,
                        content: _bodyContentEntrance,
                        onToggleFavorite: (id) =>
                            unawaited(_home.toggleFavorite(id)),
                      ),
                    },
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

/// The page once its payload has arrived.
class _HomeBody extends StatelessWidget {
  const _HomeBody({
    required this.payload,
    required this.counts,
    required this.onToggleFavorite,
    this.headings = false,
    this.content = false,
  });

  final HomePayload payload;

  /// How many pieces each «عرض الكل» opens onto. Handed in rather than
  /// looked up, so nothing below here reaches for `getIt` in a build.
  final ProductCountsCubit counts;

  final ValueChanged<int> onToggleFavorite;

  /// Whether the section headings arrive HERE, rather than having
  /// arrived with the skeleton that drew them first. See
  /// [TabEntranceKey].
  final bool headings;

  /// Whether the rails and the cards arrive — the server answering,
  /// which is a different moment from the page opening.
  final bool content;

  /// A HEADING, a row of shortcuts: the page's own words, which the
  /// skeleton already drew in these same places.
  ///
  /// It keeps the RISE when it does arrive — nothing in it flies, so
  /// it is not under the rule the rails are.
  Widget _chrome(Widget section) =>
      headings ? ScreenEntrance(child: section) : EntranceSkip(child: section);

  /// Something the SERVER sent.
  Widget _content(Widget section) =>
      content ? section : EntranceSkip(child: section);

  List<Widget> _staged(List<Widget> sections) =>
      ScreenEntrance.stage(sections, heroSafe: true);

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      // FADE, not rise — `heroSafe`.
      //
      // Half the sections below hold heroes: the live strips fly
      // between the three tabs that draw them, and every product and
      // category on the rails flies into its own detail page. An
      // entrance sitting ABOVE a hero translates the render box
      // Flutter measures the shuttle against, mid-air. Opacity leaves
      // that box identical to the pixel, which is the whole reason
      // [EntranceMotion.fade] exists.
      children: _staged([
        // ABOVE THE HERO: the only two rows on this page that are
        // true right now — an order on its way, and a session the
        // customer is sitting in. Everything below them is browsing,
        // and browsing can wait behind a thing that is happening.
        //
        // BOUND, through `LiveNowCubit` — `GET /api/home` answers
        // neither, so the strips read the bookings and orders lists
        // themselves.
        _content(const _Gutter(child: _LiveNow())),

        // Everything that does NOT scroll sideways is guttered one by
        // one. The three rails are not, and inset their own contents
        // instead.
        // THE SERVER's, so it arrives with the content — the skeleton
        // drew a grey block here, not this.
        _content(_Gutter(child: _HeroBanner(banners: payload.banners))),
        SizedBox(height: spacing.sm),
        // No section title. The three cards name themselves, and a
        // heading over them repeated the first one's word.
        // THE APP's own three destinations, drawn identically by the
        // skeleton. Chrome — see `_chrome`.
        _chrome(const _Gutter(child: _WorkshopShortcuts())),
        SizedBox(height: spacing.md),
        _chrome(
          _Gutter(child: SectionHeader(title: HomeStrings.browseCategories)),
        ),
        SizedBox(height: spacing.sm),
        _content(
          CategoryStrip.home(
            categories: payload.categories,
            // The same tap the SHOP's own strip has. These were drawn
            // and dead — a rail of categories that does not open one
            // reads as a screen that has not finished loading.
            //
            // No `categories:` in the args: the home payload's category
            // rows are a different, thinner shape than the shop tree, so
            // the browse screen fetches the tree it needs rather than
            // being handed one that cannot answer for sub-categories.
            onTap: (id) => context.pushNamed(
              'product-list',
              pathParameters: {'subCategoryId': '0'},
              extra: ProductBrowseArgs(categoryId: id),
            ),
          ),
        ),

        // «استكمل ورشتك» USED TO BE HERE — a heading and a card of its
        // own shape, halfway down the page, under everything a
        // customer browses.
        //
        // It is a strip at the TOP now, beside «يحدث الآن», because
        // the two answer neighbouring questions: the session you are
        // in, and the one you are coming back for. See
        // [NextBookingSlot] — which reads the BOOKINGS list rather
        // than this payload's `current_booking`, so the workshops tab
        // can draw the same row and the two can fly between them.
        SizedBox(height: spacing.md),
        _chrome(
          _Gutter(
            child: CountedSectionHeader(
              counts: counts,
              pick: (c) => c.featured,
              title: HomeStrings.featured,
              // The browse screen with the featured filter already on —
              // "see all" means all of THESE, not the shop landing,
              // where the same rail is cut to the same handful.
              onAction: () => context.pushNamed(
                'product-list',
                pathParameters: {'subCategoryId': '0'},
                extra: const ProductBrowseArgs(featuredOnly: true),
              ),
            ),
          ),
        ),
        SizedBox(height: spacing.sm),
        _content(
          ProductCarousel.home(
            railKey: 'featured',
            cards: payload.featuredProducts,
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
                // WHAT THE CARD SHOWS, all of it. A flight needs the
                // same element at both ends, and the badge and the
                // heart are elements: left off, the detail page drew
                // neither while it loaded, so those two had one end
                // and simply appeared. The shop's own rails already
                // passed them; these did not.
                isFeatured: tile.isFeatured,
                isFavorited: tile.isFavorited,
              ),
            ),
          ),
        ),
        SizedBox(height: spacing.md),
        _chrome(
          _Gutter(
            child: CountedSectionHeader(
              counts: counts,
              pick: (c) => c.onSale,
              title: HomeStrings.offers,
              onAction: () => context.pushNamed(
                'product-list',
                pathParameters: {'subCategoryId': '0'},
                extra: const ProductBrowseArgs(onSaleOnly: true),
              ),
            ),
          ),
        ),
        SizedBox(height: spacing.sm),
        _content(
          ProductCarousel.home(
            railKey: 'offers',
            cards: payload.offers,
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
      ]),
    );
  }
}

/// What the page shows while the first request is in flight.
///
/// The SHAPE of the page rather than a spinner in the middle of it: the
/// bar, the rails and the headings all land in the same places they
/// will occupy, so nothing jumps when the payload arrives.
class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton({this.entrance = false});

  /// Whether the page's own words arrive as it opens.
  ///
  /// The SKELETON is where they arrive from, on a cold load: it draws
  /// the real shortcuts and the real headings — shimmering four words
  /// that are already here would pretend to wait for them — so this is
  /// the moment the reader watches the page assemble. The loaded page
  /// then swaps its content in underneath without moving them again.
  /// See [TabEntranceKey].
  final bool entrance;

  /// The page's own words. The placeholders stay still: a grey block
  /// that fades in and then shimmers is two waits, one after another.
  Widget _chrome(Widget section) =>
      entrance ? ScreenEntrance(child: section) : EntranceSkip(child: section);

  /// One grey block, shimmering.
  Widget _block(BuildContext context, {double? height, double? radius}) {
    return SkeletonBlock(height: height, radius: radius ?? context.radii.md);
  }

  /// A rail of placeholder cards, edge to edge like the real one.
  Widget _rail(
    BuildContext context, {
    required double height,
    required double width,
  }) {
    final spacing = context.spacing;
    // `GlobalList` here too, not a bare `ListView` — the adoption
    // sweeps hold every feature page to it, and a placeholder rail that
    // rolled its own would be the one scrollable in the app outside the
    // house list.
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

    // Only what the SERVER has to answer for shimmers.
    //
    // The shortcuts and the section headings are the app's own — they
    // are the same three destinations and the same four words whatever
    // `GET /api/home` says, so shimmering them pretends to be waiting
    // for something that is already here. The page then holds its real
    // shape while the content arrives into it, rather than dissolving
    // and reassembling.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: ScreenEntrance.stage([
        EntranceSkip(
          child: _Gutter(
            child: AspectRatio(
              aspectRatio: 350 / 184,
              child: _block(context, radius: 10),
            ),
          ),
        ),
        SizedBox(height: spacing.sm),
        // REAL, not a placeholder.
        _chrome(const _Gutter(child: _WorkshopShortcuts())),
        SizedBox(height: spacing.md),
        // Real heading, placeholder strip.
        _chrome(
          _Gutter(child: SectionHeader(title: HomeStrings.browseCategories)),
        ),
        SizedBox(height: spacing.sm),
        EntranceSkip(child: _rail(context, height: 94, width: 78)),
        SizedBox(height: spacing.md),
        _chrome(_Gutter(child: SectionHeader(title: HomeStrings.featured))),
        SizedBox(height: spacing.sm),
        EntranceSkip(child: _rail(context, height: 182, width: 133)),
        SizedBox(height: spacing.lg),
        _chrome(_Gutter(child: SectionHeader(title: HomeStrings.offers))),
        SizedBox(height: spacing.sm),
        EntranceSkip(child: _rail(context, height: 182, width: 133)),
      ]),
    );
  }
}

/// The first request failed and there is nothing to show.
class _HomeError extends StatelessWidget {
  const _HomeError({required this.error, required this.onRetry});

  final AppException error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => _Gutter(
    child: GlobalEmptyState(
      icon: Icons.wifi_off_rounded,
      title: AuthStrings.errorGeneric,
      // The server's own sentence when it sent one — a rate limit or a
      // maintenance window says something worth reading. Transport
      // failures carry Dio's wording, which names hosts and sockets and
      // means nothing to a customer.
      subtitle: error is NetworkException ? null : error.message,
      primaryAction: GlobalFilledButton(
        text: CommonStrings.retry,
        onPressed: onRetry,
        style: terracottaCtaStyle(showArrow: false),
      ),
    ),
  );
}

/// The page's side margin, applied per SECTION rather than to the whole
/// column.
///
/// One number in one place, so a section cannot drift out of line with
/// the headings above it — and so the rails can be left out of it
/// deliberately rather than by omission.
class _Gutter extends StatelessWidget {
  const _Gutter({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    // `spacing.md`, the same token the rails pass as their list
    // padding — symmetric, so there is no side to it and nothing for
    // the reading direction to mirror.
    padding: EdgeInsets.symmetric(horizontal: context.spacing.md),
    child: child,
  );
}

/// The two live strips at the top of the home page.
///
/// **Neither is a section with a heading.** A heading over one card
/// that is usually absent reads as a page with a hole in it — and the
/// cards name themselves, which is the same reason the workshop
/// shortcuts below carry no title either.
///
/// The WORKSHOP leads: someone standing in the studio needs the code
/// the desk scans before they need a parcel's whereabouts.
///
/// Each slot collapses on its own, so with neither live this whole
/// block is nothing and the page starts at the hero.
class _LiveNow extends StatelessWidget {
  const _LiveNow();

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    // IN ORDER OF URGENCY: the account that cannot buy yet, the
    // session happening now, the seat booked for later, the order on
    // its way. Each collapses to nothing when there is none, which is
    // most customers most of the time.
    //
    // VERIFICATION LEADS because it is the only one the reader has to
    // DO something about — the other three are news.
    children: [
      VerifyAccountCard(),
      LiveWorkshopSlot(),
      NextBookingSlot(),
      LiveOrderSlot(),
    ],
  );
}

/// The full-bleed banner under the greeting, with its page dots.
class _HeroBanner extends StatefulWidget {
  const _HeroBanner({required this.banners});

  final List<HomeBanner> banners;

  @override
  State<_HeroBanner> createState() => _HeroBannerState();
}

class _HeroBannerState extends State<_HeroBanner> {
  int _index = 0;

  /// Whether the strip's artwork has been warmed already.
  bool _warmed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _warm();
  }

  /// Pull EVERY banner's artwork into the image cache up front.
  ///
  /// A `PageView` builds a slide when it is about to be shown, so each
  /// photograph started downloading at the moment the reader swiped to
  /// it — the blurhash held the frame and then the picture appeared
  /// under them. Nine banners is a handful of images the studio chose
  /// for the top of the home screen; they can all be on the way while
  /// the reader is still looking at the first.
  ///
  /// Warms the SAME cache the strip reads from —
  /// `CachedNetworkImageProvider` keyed by url, which is what
  /// `GlobalImage.n` resolves — so a warmed slide paints from memory
  /// rather than fetching twice.
  ///
  /// Failures are swallowed on purpose: this is an optimisation, and a
  /// banner whose image 404s must still draw its blurhash and its
  /// words rather than take the home screen down.
  void _warm() {
    if (_warmed) return;
    _warmed = true;

    for (final banner in widget.banners) {
      final url = banner.image?.display ?? '';
      if (url.isEmpty) continue;
      unawaited(
        precacheImage(
          CachedNetworkImageProvider(url),
          context,
          onError: (_, _) {},
        ),
      );
    }
  }

  @override
  void didUpdateWidget(_HeroBanner old) {
    super.didUpdateWidget(old);
    // A refresh can bring a different set — the studio edits these.
    if (!identical(old.banners, widget.banners)) {
      _warmed = false;
      _warm();
    }
  }

  /// The strip's corner, from the design.
  static const _radius = 10.0;

  /// Long enough to read the headline and the line under it before the
  /// strip moves on.
  static const _dwell = Duration(seconds: 5);

  /// How long after a swipe the strip starts moving on its own again.
  ///
  /// Generous on purpose: the reader who just swiped is looking at the
  /// slide they chose, and taking it away two seconds later is the
  /// carousel arguing with them.
  static const _resume = Duration(seconds: 6);

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 350 / 184,
    // ONE clip, around the whole strip — not a radius per slide.
    //
    // The per-slide scheme was doing this the long way: square the
    // inner corners so only the outer ones show. Clipping the viewport
    // gets the same picture and cannot go wrong when a banner is added,
    // removed, or is the only one.
    child: ClipRRect(
      borderRadius: BorderRadius.circular(_radius),
      // WITH A SAVE LAYER. The slides contain a `BackdropFilter`, and
      // a plain antialiased clip does not contain one — the frost
      // painted straight over the rounded corners and squared them off.
      clipBehavior: Clip.antiAliasWithSaveLayer,
      child: Stack(
        children: [
          // The HOUSE carousel, which already owns the two hard parts:
          // wrapping at the ends, and knowing to stop advancing while
          // the reader is touching it — and to stop again when the
          // strip scrolls off screen, so a home page in the background
          // is not animating to nobody.
          //
          // This was a hand-rolled `PageView` over a thousand fake
          // cycles with no auto-advance at all.
          Positioned.fill(
            child: GlobalCarousel<HomeBanner>(
              items: widget.banners,
              // FULL WIDTH: the strip is one banner edge to edge, not
              // a peek carousel.
              viewportFraction: 1,
              padEnds: false,
              loop: true,
              autoAdvance: true,
              autoAdvanceInterval: _dwell,
              pauseOnInteraction: true,
              resumeDelay: _resume,
              // The dots below are this page's own — one small vessel
              // per banner, not the module's circles.
              showIndicator: false,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, banner, i, _) => _Slide(banner: banner),
            ),
          ),
          // Black from the foot of the slide, fading out before it
          // reaches the middle. Its only job is the indicators: a pale
          // vessel on a pale photograph disappears, and the artwork is
          // whatever the studio uploaded.
          //
          // Above the strip's own scrim so it darkens the words too
          // where they overlap — which is the readable direction.
          const Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Color(0x8C000000), Color(0x00000000)],
                    stops: [0, 0.45],
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: AlignmentDirectional.bottomCenter,
            child: Padding(
              padding: EdgeInsets.all(context.spacing.sm),
              child: _Dots(count: widget.banners.length, active: _index),
            ),
          ),
        ],
      ),
    ),
  );
}

/// One slide: the artwork, and the words the CMS sends with it.
///
/// **The whole slide is the tap target**, not the pill on it. The pill
/// is small by design — the design draws a compact one — and a small
/// button on a photograph is a hard thing to hit, so it is drawn as an
/// AFFORDANCE and the card behind it takes the press. One target, and
/// no nested gesture arena to lose.
class _Slide extends StatelessWidget {
  const _Slide({required this.banner});

  final HomeBanner banner;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    // The CMS names the destination in `link_type`; an unrecognised one
    // parses as `none` and goes quiet rather than offering a control
    // that does nothing.
    final tappable = bannerIsTappable(banner);

    final slide = Stack(
      fit: StackFit.expand,
      children: [
        // `imageApi` is the ABSOLUTE url; `url` is relative to the
        // storage host and renders as a broken image.
        // The strip's rounding is applied outside, per slide.
        TerracottaImage(image: banner.image),

        // The frost the words are read on — WIDER than they are, so
        // its inner edge can fade instead of ruling a line down the
        // middle of the photograph.
        const BannerFrost(),

        // The words take HALF the slide, at the reading END, and are
        // centred inside that half.
        //
        // Two rules doing different jobs. The HALF is about the
        // artwork: its subject lives on the other side and a title
        // running under it reads as a mistake, so the block is capped
        // rather than merely padded — capped, it cannot creep across
        // when the studio writes a long headline. The CENTRING is
        // about the block itself: a title, a line under it and a pill
        // are three things of three widths, and ragging them to one
        // edge left the pill floating.
        //
        // `AlignmentDirectional`, so the half follows the reading
        // direction rather than a side: END is the LEFT in Arabic and
        // the right in English. Unchanged from what shipped — only
        // the alignment INSIDE the half is new.
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: FractionallySizedBox(
            widthFactor: 0.5,
            heightFactor: 1,
            child: Padding(
              padding: EdgeInsetsDirectional.fromSTEB(
                spacing.sm,
                spacing.md,
                spacing.sm,
                // Clear of the indicators at the foot.
                spacing.xl,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    banner.label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    // A step down from the module's own size. The copy is
                    // the STUDIO's and can run long — «Every piece is
                    // thrown, glazed and fired in our studio.» — and at
                    // full size two lines of it crowded the headline.
                    style: _shrunk(context.textTheme.labelMedium)?.copyWith(
                      color: BannerFrost.mutedInk,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: spacing.xs),
                  Text(
                    banner.title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: _shrunk(context.textTheme.titleLarge)?.copyWith(
                      color: BannerFrost.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  // NOT every banner has one — the first on dev sends
                  // `cta_text: null` — and one that cannot be FOLLOWED is
                  // worse than none: the label is the studio's copy, but
                  // whether it leads anywhere is `link_type`'s answer.
                  if (tappable && (banner.ctaText ?? '').isNotEmpty) ...[
                    SizedBox(height: spacing.sm),
                    _CtaPill(label: banner.ctaText!),
                  ],
                ],
              ),
            ),
          ),
        ),

        // LAST, so the ripple lands over the artwork and the words.
        if (tappable) _ink(context),
      ],
    );

    return slide;
  }

  /// The press, and the ink it leaves.
  ///
  /// A LAYER, and the last one in the stack: `InkWell` splashes onto
  /// the `Material` beneath it, so wrapped around the slide the ripple
  /// would paint *behind* the photograph and never be seen. Transparent
  /// material on top gets the ink over the artwork, which is the only
  /// place it reads.
  ///
  /// A drag still wins — the page view's recogniser beats a tap in the
  /// arena — so swiping the strip does not open a banner.
  Widget _ink(BuildContext context) => Positioned.fill(
    child: Material(
      type: MaterialType.transparency,
      child: Semantics(
        button: true,
        label: banner.title,
        child: InkWell(
          onTap: () => unawaited(openBanner(context, banner)),
          child: const SizedBox.expand(),
        ),
      ),
    ),
  );

  /// A small step down, not a size class down.
  ///
  /// Multiplying keeps whatever the reader's own typography scale is
  /// doing — naming a smaller style outright would throw that away and
  /// shrink twice for anyone who had already turned text down.
  static TextStyle? _shrunk(TextStyle? style) {
    final size = style?.fontSize;
    if (style == null || size == null) return style;
    return style.copyWith(fontSize: size * 0.88);
  }
}

/// The call to action, drawn as a PILL.
///
/// Not a button: the whole slide takes the tap (see [_Slide]). This is
/// the affordance that says so — compact, fully rounded, and one line,
/// because `cta_text` is the studio's copy and nothing here can make it
/// shorter.
class _CtaPill extends StatelessWidget {
  const _CtaPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    return DecoratedBox(
      decoration: BoxDecoration(
        // The brand CORAL, which is where the accent went when the
        // frost took the subtitle: the pill's own fill is a background
        // this app controls, so `#290802` on `#FC8B8B` measures a flat
        // 8.15:1 whatever photograph is behind the slide. It also
        // separates from the dark frost, which the brand brown did
        // not.
        color: context.primaryColors.accent,
        // A PILL — `radii.full`, not the CTA's own soft corner.
        borderRadius: BorderRadius.circular(context.radii.full),
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(
          spacing.md,
          // Taller than the text needs. A pill that hugs its label
          // reads as a tag rather than as something to press.
          spacing.sm,
          spacing.md,
          spacing.sm,
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.textTheme.labelSmall?.copyWith(
            color: BannerFrost.tint,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// The slide indicator: one small vessel per banner, as the design
/// draws it — the same silhouette the onboarding uses, not a row of
/// circles.
class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.active});

  static const _asset = 'assets/images/vessel-dot.png';

  /// Taller than it was — the old 11 points vanished against a busy
  /// photograph.
  static const _height = 16.0;

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
          // image become `cacheWidth` and `cacheHeight`, which force the
          // decode to exactly those pixels and squash anything that is
          // not square — and this vessel is 8 by 11.
          child: SizedBox(
            width: _width,
            height: _height,
            child: GlobalImage.a(
              _asset,
              placeholder: const SizedBox.shrink(),
              style: ImageStyle(
                fit: BoxFit.contain,
                // The house 8pt radius is larger than the dot itself.
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

/// The three places the home screen sends people: the workshops, the
/// shop and the gallery.
///
/// Not the three workshop FAMILIES, which is what this used to draw —
/// the design's icons are a brush, a cart and a picture, one per
/// destination, and a row of three identical brushes was the giveaway.
class _WorkshopShortcuts extends StatelessWidget {
  const _WorkshopShortcuts();

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    // In LOGICAL order, so Arabic reads brush-cart-gallery from the
    // right and English the same from the left.
    final shortcuts = <({String label, String asset, String route})>[
      (
        label: NavStrings.workshops,
        asset: 'assets/icons/heroicons_paint_brush_16_solid.svg',
        route: 'workshops',
      ),
      (
        label: NavStrings.shop,
        asset: 'assets/icons/boxicons_cart_filled.svg',
        route: 'shop',
      ),
      (
        label: NavStrings.gallery,
        asset: 'assets/icons/streamline-plump_gallery_2_remix.svg',
        route: 'gallery',
      ),
    ];

    // A ROW, not a grid.
    //
    // `GlobalGrid` earns its keep on a COLLECTION — a variable number of
    // items, scrolling, an empty state, pagination. This is three fixed
    // shortcuts that never scroll and never change in number, so the
    // grid was carrying a controller and a viewport to do what three
    // `Expanded`s do on their own.
    return SizedBox(
      height: 94,
      child: Row(
        spacing: spacing.sm,
        children: [
          for (final shortcut in shortcuts)
            Expanded(
              child: TerracottaCard(
                onTap: () => context.pushNamed(shortcut.route),
                // TRANSPARENT, so the page shows through and the card
                // is only its hairline — `primaryColors.border`, which
                // is 0x1A000000, black at 10%. The shadow is gone at
                // the source: `TerracottaCard` now passes `shadow:
                // const []`, because a null shadow means "give me the
                // house one" rather than "give me none".
                color: Colors.transparent,
                padding: EdgeInsets.all(spacing.sm),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Sized from OUTSIDE — an explicit width and height
                    // on the image become cacheWidth/cacheHeight, which
                    // force the decode to those exact pixels and squash
                    // anything that is not square.
                    SizedBox.square(
                      dimension: context.iconSizes.lg,
                      child: GlobalImage.a(
                        shortcut.asset,
                        placeholder: const SizedBox.shrink(),
                        style: ImageStyle(
                          fit: BoxFit.contain,
                          borderRadius: BorderRadius.zero,
                          color: context.primaryColors.primary,
                          overlayBlendMode: BlendMode.srcIn,
                        ),
                      ),
                    ),
                    SizedBox(height: spacing.xs),
                    Text(
                      shortcut.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.primaryColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
