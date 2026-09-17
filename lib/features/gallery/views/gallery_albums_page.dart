import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/strings/auth_strings.dart';
import '../../../core/localization/strings/common_strings.dart';
import '../../../core/localization/strings/gallery_strings.dart';
import '../../../core/tokens/extensions.dart';
import '../../../data/models/terracotta/gallery/gallery_album.dart';
import '../../../shared/module/buttons/global_filled_button.dart';
import '../../../shared/module/empty_state/global_empty_state.dart';
import '../../../shared/module/grid/global_grid.dart';
import '../../../shared/module/in_page_hero/global_in_page_hero.dart';
import '../../../shared/module/refreshable/global_refreshable.dart';
import '../../../shared/module/scrollable/global_scrollable.dart';
import '../../_shared/illustrated_header.dart';
import '../../_shared/localized_rebuild.dart';
import '../../_shared/screen_entrance.dart';
import '../../_shared/skeleton_block.dart';
import '../../_shared/tab_entrance.dart';
import '../../_shared/terracotta_cta_style.dart';
import '../../shell/widgets/terracotta_app_bar.dart';
import '../../shell/widgets/terracotta_nav_bar.dart';
import '../cubits/gallery_cubit.dart';
import '../cubits/gallery_state.dart';
import '../widgets/album_detail_sheet.dart';
import '../widgets/album_tile.dart';
import '../widgets/masonry_heights.dart';

/// «لحظات تيراكوتا» — the album list.
///
/// `GET /api/gallery`; each album carries `images_count` and
/// `videos_count`, so the counts need no second call.
class GalleryAlbumsPage extends StatefulWidget {
  const GalleryAlbumsPage({this.cubit, super.key});

  /// A cubit to use instead of making one — the seam a widget test
  /// needs, since the page loads on mount and a test has no network.
  /// Null in the app.
  final GalleryCubit? cubit;

  @override
  State<GalleryAlbumsPage> createState() => _GalleryAlbumsPageState();
}

class _GalleryAlbumsPageState extends State<GalleryAlbumsPage> {
  /// Shared by the page, the app bar and the nav bar — the bar swaps
  /// its title on it and the nav bar retreats with it.
  final _scroll = ScrollController();

  /// The heading FLYING into the bar as the page collapses — see
  /// [InPageHero]. Nothing is pushed when a page scrolls, so a route
  /// `Hero` has nothing to fire on.
  final _titleMorph = InPageHeroController();

  /// Whether this session's one gallery entrance is still going spare.
  /// Held so a rebuild cannot change its mind mid-animation.
  bool? _claim;

  bool get _entrance => _claim ??= TabEntrance.claim(TabEntranceKey.gallery);

  /// The header and the grid, staged on the FIRST sight of this tab in
  /// the session and left alone on every one after it.
  List<Widget> _staged(List<Widget> sections) =>
      _entrance ? ScreenEntrance.stage(sections, heroSafe: true) : sections;

  // `load` OUTSIDE the `??` — an injected cubit has to be loaded too,
  // and a fixture that overrides `load` to answer from a capture never
  // runs if the call hangs off the fallback.
  /// The APP's cubit, not this page's — every tab is a top-level
  /// route, so `context.go` disposes this State and a page-owned cubit
  /// went with it, re-requesting everything on the way back.
  ///
  /// It is therefore NOT closed here: closing a singleton on the way
  /// out of one tab breaks it for every later visit.
  late final _gallery = widget.cubit ?? getIt<GalleryCubit>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Where the load is asked for, rather than in the field
    // initialiser. This runs on mount AND whenever `Localizations`
    // changes above us, which is exactly the two moments the data
    // could be stale: arriving with nothing, and arriving after the
    // reader switched language. `ensureLoaded` decides which.
    unawaited(_gallery.ensureLoaded(_locale));
  }

  /// The language the server should answer in. `Accept-Language` is
  /// resolved per request from `PreferencesCubit`, so a reload after a
  /// switch comes back translated with nothing else to do.
  String get _locale => Localizations.localeOf(context).languageCode;

  /// The design's staggered rhythm, shared with the opened album so
  /// the sheet and the list read as one screen — see [MasonryHeights].
  double _heightFor(GalleryAlbum album) => MasonryHeights.forId(album.id);

  @override
  void dispose() {
    _scroll.dispose();
    _titleMorph.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    return TerracottaNavBar.wrapScaffold(
      context,
      currentIndex: 1,
      // The rail goes AROUND the scaffold: it has to sit in
      // front of the app bar and move it along, and nothing
      // inside the body can do either.
      child: Scaffold(
        backgroundColor: context.backgroundColors.scaffoldBackground,
        // The header's line art runs up behind the bar, so the bar has no
        // surface of its own and the body reaches under it.
        extendBodyBehindAppBar: true,
        appBar: TerracottaAppBar(
          controller: _scroll,
          collapsedTitle: GalleryStrings.title,
          titleMorph: _titleMorph,
          // STAYS. Only home and the account let their bar retreat —
          // see [TerracottaPageBar.pinned]. This page opens on drawn
          // artwork the bar floats over, and a bar that comes and goes
          // across it reads as the drawing flickering.
          hideOnScroll: false,
          // NOTHING at the top: the page draws its own heading right
          // below, and a second copy in the bar would be the same words
          // twice until the first scrolled away.
          transparent: true,
        ),
        // The bar floats over the page and retreats with it, so the body
        // reaches underneath — see `HomePage` for why reserving the space
        // instead leaves a white band when it goes.
        extendBody: true,
        // NOTHING HERE in a short window — the destinations are
        // on a rail over the body instead. The slot has no
        // height limit, so a rail put in it takes the screen.
        bottomNavigationBar: TerracottaNavBar.bottomSlot(
          context,
          currentIndex: 1,
          scrollController: _scroll,
        ),
        body: SafeArea(
          // TOP off, deliberately. `extendBodyBehindAppBar` makes the
          // Scaffold fold the whole rendered bar — status inset AND its
          // 56pt toolbar — into the body's own `padding.top`, so a
          // default `SafeArea` here does not clear the notch, it clears
          // the app bar: roughly 103pt of empty white above the drawing,
          // in a fixed band OUTSIDE the scrollable that never moves.
          //
          // The header is meant to run to the top edge of the screen and
          // under the status bar, which is why the bar names a dark
          // status-bar style.
          top: false,
          // The nav bar's clearance is the page's own padding, not a
          // `SafeArea` inset — an inset is a fixed band outside the
          // scroll and stays behind when the bar retreats.
          bottom: false,
          child: GlobalRefreshable(
            onRefresh: () => _gallery.refresh(_locale),
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
              child: BlocBuilder<GalleryCubit, GalleryState>(
                bloc: _gallery,
                builder: (context, state) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  // ONCE per launch, and a FADE: the albums grid flies
                  // its covers into the opened album, and an entrance
                  // above a hero moves the box its flight is measured
                  // against. See [TabEntrance] and [EntranceMotion.fade].
                  children: _staged([
                    // The header is the page's own and never waits on the
                    // server — drawing a placeholder over artwork that is
                    // already in the bundle would be pretending to load
                    // it.
                    // STAGES ITSELF — see [EntranceSkip]. The cameras,
                    // the heading and the line under it are three
                    // arrivals rather than a header that is simply there.
                    EntranceSkip(
                      child: _GalleryHeader(
                        entrance: _entrance,
                        titleMorph: _titleMorph,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsetsDirectional.fromSTEB(
                        // Plus the RAIL's side in a short window.
                        spacing.md,
                        0,
                        spacing.md,
                        TerracottaNavBar.reservedHeightIn(context) + spacing.md,
                      ),
                      child: switch (state) {
                        GalleryLoading() => const _AlbumsSkeleton(),
                        GalleryFailed(:final error) => _AlbumsError(
                          error: error,
                          onRetry: () => unawaited(_gallery.refresh(_locale)),
                        ),
                        GalleryLoaded(:final albums) => _AlbumsGrid(
                          albums: albums,
                          heightFor: _heightFor,
                        ),
                      },
                    ),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The masonry grid itself.
class _AlbumsGrid extends StatelessWidget {
  const _AlbumsGrid({required this.albums, required this.heightFor});

  final List<GalleryAlbum> albums;
  final double Function(GalleryAlbum) heightFor;

  @override
  Widget build(BuildContext context) => GlobalGrid<GalleryAlbum>.static(
    items: albums,
    compactColumns: 2,
    // MORE COLUMNS WHEN THERE IS WIDTH. A landscape phone is ~874dp
    // across, which reads as `expanded` — two columns there means two
    // very wide tiles and a screen that shows almost nothing. The
    // buckets are by WIDTH, so a tablet gets the same benefit.
    mediumColumns: 3,
    expandedColumns: 4,
    largeColumns: 5,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    style: GridStyle(
      spacing: context.spacing.sm,
      // The albums read as ONE block: only the four outside corners
      // of the grid are rounded, everything inside is square.
      // `AlbumTile` reads the scope this sets — see its `corners`.
      unifyTiles: true,
    ),
    // MASONRY. Each tile takes its own height and drops into the
    // shortest column, which is what makes the two columns fall out of
    // step. There is no enum for it — passing this callback IS the
    // switch.
    tileExtentExtractor: (album, tileWidth) => heightFor(album),
    itemBuilder: (context, album, index) => AlbumTile(
      cover: album.cover,
      title: album.title,
      photos: album.imagesCount,
      videos: album.videosCount,
      onTap: () => showAlbumDetailSheet(context, album),
    ),
  );
}

/// Placeholder tiles in the same staggered rhythm, so nothing moves
/// when the albums arrive.
class _AlbumsSkeleton extends StatelessWidget {
  const _AlbumsSkeleton();

  static const _heights = [173.0, 199.0, 225.0, 147.0];

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    return Row(
      spacing: spacing.sm,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var column = 0; column < 2; column++)
          Expanded(
            child: Column(
              spacing: spacing.sm,
              children: [
                for (var i = column; i < _heights.length; i += 2)
                  SizedBox(
                    height: _heights[i],
                    child: const SkeletonBlock(),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Nothing arrived and there is nothing to show.
class _AlbumsError extends StatelessWidget {
  const _AlbumsError({required this.error, required this.onRetry});

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

/// The drawn header — the same anatomy as the workshops tab, with
/// cameras in it instead of brushes.
class _GalleryHeader extends StatelessWidget {
  const _GalleryHeader({this.entrance = false, this.titleMorph});

  /// Passed straight through to [IllustratedHeader].
  final bool entrance;

  /// And so is this — the heading is endpoint 0 of the flight into the
  /// bar's own title.
  final InPageHeroController? titleMorph;

  /// The camera riding a long sweeping LINE. Sits at the START.
  static const _lineCamera = 'assets/images/gallery-illustration-1.png';

  /// The smaller camera with a heart above it. Sits at the END.
  static const _heartCamera = 'assets/images/gallery-illustration-2.png';

  static const _star = 'assets/images/star-illustration.png';

  @override
  Widget build(BuildContext context) {
    // The words below are read HERE, so this build has to run again
    // when the language changes — see `dependOnLanguage`.
    dependOnLanguage(context);

    return IllustratedHeader(
      entrance: entrance,
      titleMorph: titleMorph,
      mirrorKey: const ValueKey('gallery-header-mirror'),
      title: GalleryStrings.title,
      subtitle: GalleryStrings.subtitle,
      // PHYSICAL sides, read as the Arabic composition — `right` is the
      // START edge. See `IllustratedHeader`.
      art: const [
        // START: the line camera, its sweep running inward. It rides
        // HIGHER and LARGER than the other — the sweep is most of its
        // box, so it reads smaller than its numbers suggest.
        HeaderArt(
          asset: _lineCamera,
          width: 218,
          height: 184,
          top: -12,
          right: -8,
        ),
        // END: the heart camera, dropped clear of it.
        HeaderArt(
          asset: _heartCamera,
          width: 132,
          height: 132,
          top: 56,
          left: -24,
        ),
        // The stars follow their cameras.
        HeaderArt(asset: _star, width: 68, height: 68, bottom: 16, right: 24),
        HeaderArt(asset: _star, width: 56, height: 56, bottom: 32, left: 24),
      ],
    );
  }
}
