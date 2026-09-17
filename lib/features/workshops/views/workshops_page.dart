import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/animations/animation_presets.dart';
import '../../../core/auth/auth_gate.dart';
import '../../../core/constants/colors/workshop_family_colors.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/strings/auth_strings.dart';
import '../../../core/localization/strings/common_strings.dart';
import '../../../core/localization/strings/workshop_strings.dart';
import '../../../core/tokens/extensions.dart';
import '../../../data/models/terracotta/workshop/workshop.dart';
import '../../../shared/module/buttons/global_filled_button.dart';
import '../../../shared/module/container/global_container.dart';
import '../../../shared/module/empty_state/global_empty_state.dart';
import '../../../shared/module/in_page_hero/global_in_page_hero.dart';
import '../../../shared/module/refreshable/global_refreshable.dart';
import '../../../shared/module/scrollable/global_scrollable.dart';
import '../../_shared/illustrated_header.dart';
import '../../_shared/localized_rebuild.dart';
import '../../_shared/screen_entrance.dart';
import '../../_shared/skeleton_block.dart';
import '../../_shared/tab_entrance.dart';
import '../../_shared/terracotta_cta_style.dart';
import '../../booking/views/booking_schedule_page.dart';
import '../../gift/widgets/gift_credit_sheet.dart';
import '../../home/cubits/live_now_cubit.dart';
import '../../home/widgets/live_strip.dart';
import '../../profile/cubits/wallet_cubit.dart';
import '../../profile/cubits/wallet_state.dart';
import '../../shell/widgets/terracotta_app_bar.dart';
import '../../shell/widgets/terracotta_nav_bar.dart';
import '../cubits/my_bookings_cubit.dart';
import '../cubits/workshop_detail_cubit.dart';
import '../cubits/workshops_cubit.dart';
import '../cubits/workshops_state.dart';
import '../widgets/booking_status_filter.dart';
import '../widgets/my_workshops_list.dart';
import '../widgets/studio_location_sheet.dart';
import '../widgets/workshop_card.dart';
import '../widgets/workshop_detail_panel.dart';
import '../widgets/workshops_header.dart';
import '../workshops_tab.dart';

/// «ورشات تيراكوتا» — browse and book.
///
/// Built as an ACCORDION, per the fork intake: tapping a workshop card
/// expands its full detail in place — gallery, info chips, description,
/// location and the book CTA — rather than pushing a route. That is how
/// the design draws it (the frames are 1682–1877px tall and stack card
/// and detail in one scroll).
///
/// Known cost, recorded here so it is not rediscovered: there is no
/// `/workshops/:id`, so nothing can deep-link to a single workshop. The
/// escape hatch is a route that opens this page pre-expanded — additive,
/// not a rewrite.
class WorkshopsPage extends StatefulWidget {
  const WorkshopsPage({
    this.cubit,
    this.wallet,
    this.bookings,
    this.initialTab = WorkshopsTab.book,
    super.key,
  });

  /// Which side the page opens on. «احجز» unless something sent the
  /// customer to their own bookings — paying for one does.
  final WorkshopsTab initialTab;

  /// A cubit to use instead of the app's — the seam a widget test
  /// needs, since the page loads on mount. Null in the app.
  final WorkshopsCubit? cubit;

  /// The balance behind «رصيد تيراكوتا», shared with the profile tab.
  final WalletCubit? wallet;

  /// «ورشاتي» — the caller's own bookings. The app's, unless a test
  /// hands one over.
  final MyBookingsCubit? bookings;

  @override
  State<WorkshopsPage> createState() => _WorkshopsPageState();
}

class _WorkshopsPageState extends State<WorkshopsPage> {
  /// The APP's cubit — every tab is a top-level route, so `context.go`
  /// disposes this State and a page-owned cubit went with it. Not
  /// closed here for the same reason.
  late final _workshops = widget.cubit ?? getIt<WorkshopsCubit>();

  /// Shared with the profile tab, which shows the same balance.
  late final _wallet = widget.wallet ?? getIt<WalletCubit>();

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
  bool get _entrance => _claim ??= TabEntrance.claim(TabEntranceKey.workshops);

  /// The sections, staged on the FIRST sight of this tab in the
  /// session and left alone on every one after it.
  List<Widget> _staged(List<Widget> sections, {bool heroSafe = false}) =>
      _entrance ? ScreenEntrance.stage(sections, heroSafe: heroSafe) : sections;

  /// «ورشاتي». The APP's cubit for the same reason the catalogue is —
  /// this tab is a top-level route and `context.go` disposes its
  /// `State`. Not closed here.
  late final _bookings = widget.bookings ?? getIt<MyBookingsCubit>();

  /// The strip above the segmented control. The app's, shared with the
  /// home and shop tabs.
  late final _live = getIt<LiveNowCubit>();

  @override
  void initState() {
    super.initState();
    // A tab asked for from elsewhere — «تتبع الحجز» on the
    // confirmation, which POPS back to this live `State` rather than
    // building a new one. Also taken once now, in case the request
    // was made while this page was already mounted.
    WorkshopsTab.requested.addListener(_onTabRequested);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onTabRequested());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // BACK FROM A BOOKING'S OWN PAGE, where it may have been cancelled
    // or rescheduled. `AccountScope.ownedChanged()` clears the
    // "already loaded" mark; this is what makes the list act on it —
    // otherwise «ورشاتي» went on showing a cancelled booking as
    // confirmed until the language changed.
    unawaited(_bookings.ensureLoaded(_locale));
    // Runs on mount AND when `Localizations` changes above us — the
    // catalogue's titles and descriptions come from the server, in the
    // language the request asked for.
    unawaited(_workshops.ensureLoaded(_locale));
    // THE WALLET IS THE CALLER'S OWN, and `GET /api/wallet` answers 401
    // without a session — which `SessionExpiry` reads as the session
    // ending, so it cleared the token, re-ran the guards and asked the
    // reader to sign in. That is how tapping «ورشاتنا» as a guest
    // landed on the login screen: the catalogue is public, the balance
    // beside it is not, and nobody asked the balance whether it should
    // be fetched. The profile tab already gated its own copy.
    if (AuthGate.has(context)) {
      unawaited(_wallet.ensureLoaded());
    }
    // The bookings are the CALLER's own and need a session; asking for
    // them as a guest is a 401 that says nothing. Locale-scoped like
    // the catalogue, because `workshop_title` is the server's.
    if (AuthGate.has(context)) {
      unawaited(_bookings.ensureLoaded(_locale));
    } else {
      _bookings.clear();
    }
    // The two "happening now" strips. Both routes behind them are the
    // CALLER's own and answer 401 to a guest, so they are asked for
    // only when there is an account.
    if (AuthGate.has(context)) {
      unawaited(_live.ensureLoaded(_locale));
    } else {
      _live.clear();
    }

    // NOTHING TO DROP ON A LANGUAGE SWITCH any more. The description
    // is the catalogue row's, so it re-arrives translated with the
    // catalogue itself — see [_detailFor].
  }

  String get _locale => Localizations.localeOf(context).languageCode;

  /// Into the booking flow for this workshop.
  ///
  /// The FAMILY travels with the tap: every screen from here to the
  /// confirmation is tinted by it, and deriving it again from the id
  /// would mean re-fetching the catalogue this page already has.
  /// «ورشاتي» is the reader's own; «حجز ورشة» is the catalogue.
  ///
  /// Switching to the first without an account would show an empty
  /// list that is empty for the wrong reason — there is nothing to
  /// fetch it with. Ask for the account instead, and stay where we are
  /// if they decline.
  void _selectTab(WorkshopsTab tab) {
    if (tab != WorkshopsTab.mine || AuthGate.has(context)) {
      setState(() => _tab = tab);
      return;
    }
    unawaited(
      AuthGate.demand(context, action: () => setState(() => _tab = tab)),
    );
  }

  /// NOT GATED any more.
  ///
  /// It was, because `AuthGuard` would have bounced a guest off the
  /// schedule screen anyway — but that asked for an account before the
  /// reader knew what the workshop would cost. The availability and the
  /// price are both public (probed live), so the flow now runs to the
  /// seat and asks there. See `AuthGate.demandToFinish`.
  void _book(BuildContext context, Workshop workshop) => context.pushNamed(
    'booking-schedule',
    pathParameters: {'workshopId': '${workshop.id}'},
    extra: BookingScheduleArgs(
      workshopId: workshop.id,
      title: workshop.title,
      // The workshop's own ceiling. The calendar's
      // `max_available_seats` can be lower, and the strip runs to
      // whichever is smaller — a workshop that seats eight with three
      // left offers three.
      maxPeople: workshop.maxPeoplePerBooking,
      family: WorkshopFamily.fromWire(workshop.type.wire),
      // SEEDS THE WHOLE FLOW. Every screen from here to the
      // confirmation already carries `wireColor` through its args and
      // resolves its own tint from it — the schedule, the pieces, the
      // checkout, the sheets on each. Nothing ever put a value IN, so
      // all of them fell back to the family's hue.
      wireColor: workshop.color,
    ),
  );

  /// ALWAYS NULL — the catalogue row is the whole answer.
  ///
  /// `GET /api/workshops` sends `long_description` as a real key on
  /// every row, so a null there is the studio saying there is no long
  /// description. This asked `GET /api/workshops/{id}` on exactly that
  /// null and got the same null back: one request per card opened, for
  /// a fact the page already had.
  ///
  /// **What that gives up is the GALLERY**, which lives only on the
  /// detail endpoint. Every live workshop returns `gallery: []` today,
  /// so nothing is lost yet — and the day the studio uploads
  /// photographs, the way back is a signal on the LIST row saying a
  /// workshop has some. Fetching on the chance of one is what this
  /// method was doing, and it cost a request on every open to find out
  /// there was nothing.
  ///
  /// The panel still takes a cubit, so a test can hand it one.
  WorkshopDetailCubit? _detailFor(Workshop workshop) => null;

  /// Shared by the page, the app bar and the nav bar — the bar swaps
  /// its title on it and the nav bar retreats with it.
  final _scroll = ScrollController();

  /// The heading FLYING into the bar as the page collapses — see
  /// [InPageHero]. Nothing is pushed when a page scrolls, so a route
  /// `Hero` has nothing to fire on.
  final _titleMorph = InPageHeroController();

  /// Which card is open. Null means all collapsed, which is how the
  /// screen arrives — the design draws the catalogue as a closed list,
  /// and opening one on mount also fired its detail request before the
  /// reader had asked for anything.
  int? _open;

  /// One key per card, so an opening card can be scrolled to.
  ///
  /// Keyed on the workshop's own ID rather than the row index: the
  /// catalogue is re-read on a language change and on pull-to-refresh,
  /// and an index would follow whatever happens to be in that slot
  /// afterwards.
  final _cardKeys = <int, GlobalKey>{};

  GlobalKey _cardKey(int workshopId) =>
      _cardKeys.putIfAbsent(workshopId, GlobalKey.new);

  /// Opens a card, or closes the one that is open.
  ///
  /// AND SCROLLS IT UP. The panel unfolds BELOW the card, so opening
  /// the third of four pushed everything worth reading off the bottom
  /// of the screen — the price, the description, «احجز» — and left the
  /// reader to find them. The card goes to the top of the viewport
  /// instead and its panel fills the space under it.
  ///
  /// Only on OPEN: scrolling on a close moves the page out from under
  /// somebody who just asked to see less.
  void _toggle(int index, int workshopId) {
    final opening = _open != index;
    setState(() => _open = opening ? index : null);
    if (!opening) return;

    // AFTER THE FRAME THAT BUILT IT. The panel does not exist until
    // this rebuild lands, and `ensureVisible` measures what is on
    // screen — called inline it would scroll to the card's collapsed
    // height and stop short.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _cardKeys[workshopId]?.currentContext;
      if (target == null || !mounted) return;
      unawaited(
        Scrollable.ensureVisible(
          target,
          // The card's own TOP against the viewport's, so the panel
          // that just opened has the whole screen under it.
          alignment: 0,
          duration: AppDurations.normal,
          curve: Curves.easeOutCubic,
        ),
      );
    });
  }

  /// Which side of the segmented control is selected.
  ///
  /// The control is real now — it was two boxes and a hardcoded bool —
  /// but the CONTENT under it does not switch yet: «ورشاتي» is the
  /// customer's own bookings, and binding that list is its own pass.
  late WorkshopsTab _tab = widget.initialTab;

  /// Answers a tab REQUESTED from elsewhere — see
  /// [WorkshopsTab.requested]. A route parameter cannot do this,
  /// because arriving here from the booking flow pops back to a
  /// `State` that is already alive and never rebuilds.
  void _onTabRequested() {
    final tab = WorkshopsTab.takeRequest();
    if (tab == null || !mounted || tab == _tab) return;
    setState(() => _tab = tab);
  }

  @override
  void dispose() {
    WorkshopsTab.requested.removeListener(_onTabRequested);
    _scroll.dispose();
    _titleMorph.dispose();
    super.dispose();
  }

  /// A pull is an ask for everything on the page.
  Future<void> _refresh() async {
    await _workshops.refresh(_locale);
    // Both halves of the segmented control, whichever one is showing:
    // a pull is an ask for everything on the page.
    if (mounted && AuthGate.has(context)) {
      await _bookings.refresh(_locale);
    }
  }

  /// The workshop this booking is for, out of the catalogue the page
  /// already has.
  ///
  /// The booking payload carries no `type`, and the card's whole
  /// treatment is the family's — so it is matched on `workshop_id`
  /// rather than re-fetched.
  Workshop? _workshopFor(int id) {
    final state = _workshops.state;
    if (state is! WorkshopsLoaded) return null;
    for (final workshop in state.workshops) {
      if (workshop.id == id) return workshop;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    return TerracottaNavBar.wrapScaffold(
      context,
      currentIndex: 2,
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
          // STAYS. This page opens on drawn artwork the bar floats
          // over, and a bar that retreats and returns across it reads
          // as the drawing flickering rather than as chrome getting
          // out of the way.
          hideOnScroll: false,
          collapsedTitle: WorkshopStrings.title,
          titleMorph: _titleMorph,
          // NOTHING at the top: the page draws its own heading right
          // below, and a second copy in the bar would be the same words
          // twice.
          transparent: true,
        ),
        // The bar floats over the page and retreats with it, so the body
        // reaches underneath — reserving the space instead leaves a white
        // band where the bar used to be.
        extendBody: true,
        // NOTHING HERE in a short window — the destinations are
        // on a rail over the body instead. The slot has no
        // height limit, so a rail put in it takes the screen.
        bottomNavigationBar: TerracottaNavBar.bottomSlot(
          context,
          currentIndex: 2,
          scrollController: _scroll,
        ),
        body: SafeArea(
          // TOP off: `extendBodyBehindAppBar` folds the whole rendered
          // bar — status inset AND its 56pt toolbar — into the body's own
          // `padding.top`, so a default `SafeArea` here does not clear the
          // notch, it clears the app bar, leaving a fixed band of white
          // above the drawing. Same as the gallery.
          top: false,
          bottom: false,
          child: GlobalRefreshable(
            onRefresh: _refresh,
            style: RefreshableStyle(
              // Below the floating app bar, which the body reaches under.
              edgeOffset: MediaQuery.paddingOf(context).top + kToolbarHeight,
            ),
            child: GlobalScrollable(
              controller: _scroll,
              // ALWAYS draggable, even when the content fits: Flutter drops
              // the drag recogniser when there is nothing to scroll.
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // OUTSIDE the shell padding: the drawings bleed past both
                  // edges of the screen, which a padded box would clip.
                  _WorkshopsIntro(entrance: _entrance, titleMorph: _titleMorph),
                  GlobalContainer.shell(
                    padding: EdgeInsetsDirectional.fromSTEB(
                      // Plus the RAIL's side in a short window — see
                      // [TerracottaNavBar.reservedWidthIn].
                      spacing.md,
                      0,
                      spacing.md,
                      TerracottaNavBar.reservedHeightIn(context) + spacing.md,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      // ONCE per launch, and a FADE rather than a rise:
                      // the live workshop strip flies between the three
                      // tabs that draw it, and an entrance above a hero
                      // moves the box its flight is measured against.
                      // See [TabEntrance] and [EntranceMotion.fade].
                      children: _staged([
                        // ABOVE the segmented control, which is the
                        // first thing in the header below. A session the
                        // customer is sitting in outranks the choice of
                        // which list to look at.
                        const LiveWorkshopSlot(),
                        // And the seat already booked, in the same place
                        // and the same shape it takes on the home tab —
                        // flown, so switching between the two reads as
                        // one page moving rather than two swapping.
                        const NextBookingSlot(),

                        // The balance is the app's, not this page's: the
                        // profile tab shows the same number and neither
                        // should ask twice. It was hardcoded '0' here.
                        // STAGES ITSELF — the control, the balance and
                        // the gift tile are three things arriving, not
                        // one block. See [EntranceSkip].
                        EntranceSkip(
                          child: BlocBuilder<WalletCubit, WalletState>(
                            bloc: _wallet,
                            builder: (context, wallet) => WorkshopsHeader(
                              entrance: _entrance,
                              tab: _tab,
                              onTabChanged: _selectTab,
                              // The SHEET first: the amount is admin-set,
                              // but who it is for and what it says are the
                              // purchaser's, and the checkout has no way to
                              // ask.
                              onGiftTap: () => unawaited(
                                showGiftCreditSheet(context),
                              ),
                              // The ledger behind the number beside it.
                              // GATED. The ledger is the reader's own and
                              // `GET /api/wallet/transactions` answers 401
                              // without a session — and a 401 anywhere is
                              // read as the session ending, which would
                              // evict a guest rather than just failing.
                              onOpenWallet: () => unawaited(
                                AuthGate.demand(
                                  context,
                                  action: () => context.pushNamed('wallet'),
                                ),
                              ),
                              walletBalance: wallet.balance ?? '0',
                              // The badge on «ورشاتي». It was hardcoded 0.
                              bookingCount: _bookings.state.bookings.length,
                            ),
                          ),
                        ),
                        SizedBox(height: spacing.md),
                        // «ورشاتي» — the customer's own bookings, which
                        // are a different list from the catalogue and
                        // share only the card's shape.
                        if (_tab == WorkshopsTab.mine)
                          BlocBuilder<MyBookingsCubit, MyBookingsState>(
                            bloc: _bookings,
                            builder: (context, mine) => _MyBookings(
                              state: mine,
                              // The card's colour is the workshop's, and
                              // the booking payload does not carry it.
                              workshopFor: _workshopFor,
                              onRetry: () =>
                                  unawaited(_bookings.refresh(_locale)),
                              onOpen: (entry) => context.pushNamed(
                                'booking-detail',
                                pathParameters: {'bookingId': '${entry.id}'},
                              ),
                            ),
                          )
                        else
                          BlocBuilder<WorkshopsCubit, WorkshopsState>(
                            bloc: _workshops,
                            builder: (context, state) => switch (state) {
                              WorkshopsLoading() => const _CatalogueSkeleton(),
                              WorkshopsFailed(:final error) => _CatalogueError(
                                error: error,
                                onRetry: () =>
                                    unawaited(_workshops.refresh(_locale)),
                              ),
                              WorkshopsLoaded(:final workshops)
                                  when workshops.isEmpty =>
                                GlobalEmptyState(
                                  icon: Icons.brush_outlined,
                                  title: WorkshopStrings.empty,
                                ),
                              WorkshopsLoaded(:final workshops) => Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  for (
                                    var i = 0;
                                    i < workshops.length;
                                    i++
                                  ) ...[
                                    WorkshopCard(
                                      key: _cardKey(workshops[i].id),
                                      // Every word from the SERVER. The
                                      // design's copy and the catalogue's do
                                      // not match, and the catalogue is what
                                      // the studio edits.
                                      title: workshops[i].title,
                                      description:
                                          workshops[i].shortDescription,
                                      // WHO IT IS FOR, on the closed
                                      // card — the list is where the
                                      // choice is made.
                                      audience: workshops[i].audience,
                                      family: WorkshopFamily.fromWire(
                                        workshops[i].type.wire,
                                      ),
                                      // THE CMS COLOUR WINS.
                                      //
                                      // It was held back while the live
                                      // values were stock Tailwind hues
                                      // that read as somebody else's
                                      // palette beside the studio's
                                      // terracotta. That is the studio's
                                      // call to make, not this app's —
                                      // and the ink on top is chosen by
                                      // MEASURED contrast, so even a flat
                                      // #ff0000 keeps a legible label.
                                      // Null or unparseable falls back to
                                      // the family's own, which is still
                                      // what `type` decides.
                                      wireColor: workshops[i].color,
                                      // ITS OWN PHOTOGRAPH, when the CMS
                                      // has one. Null keeps the family
                                      // line drawing — which is every row
                                      // that has not been given a picture
                                      // yet.
                                      image: workshops[i].image,
                                      expanded: _open == i,
                                      onTap: () => _toggle(i, workshops[i].id),
                                    ),
                                    // The detail is part of the same
                                    // scroll, which is what makes this an
                                    // accordion rather than a route.
                                    //
                                    // Built ONLY when open. `AnimatedCrossFade`
                                    // mounts BOTH of its children whatever
                                    // it is showing, so handing it the panel
                                    // unconditionally put one under every
                                    // card and fired four detail requests
                                    // the moment the catalogue arrived.
                                    AnimatedCrossFade(
                                      duration: const Duration(
                                        milliseconds: 220,
                                      ),
                                      firstChild: const SizedBox(
                                        width: double.infinity,
                                      ),
                                      secondChild: _open == i
                                          ? Padding(
                                              padding: EdgeInsets.only(
                                                top: spacing.md,
                                              ),
                                              child: WorkshopDetailPanel(
                                                workshop: workshops[i],
                                                family: WorkshopFamily.fromWire(
                                                  workshops[i].type.wire,
                                                ),
                                                // The panel already
                                                // tints everything in
                                                // it — the fact chips,
                                                // the note, «الموقع»
                                                // and «احجز» — from
                                                // `fam`. It was just
                                                // never handed the
                                                // studio's colour, so
                                                // a red card opened on
                                                // a green panel.
                                                wireColor: workshops[i].color,
                                                cubit: _detailFor(workshops[i]),
                                                // The CTA had no handler
                                                // at all — a button that
                                                // looked like the way in
                                                // and was not.
                                                onBook: () => _book(
                                                  context,
                                                  workshops[i],
                                                ),
                                                // It fell back to
                                                // `() {}` — a button
                                                // that looked live and
                                                // was not.
                                                onLocation: () => unawaited(
                                                  showStudioLocationSheet(
                                                    context,
                                                    locationUrl: workshops[i]
                                                        .locationUrl,
                                                  ),
                                                ),
                                              ),
                                            )
                                          : const SizedBox(
                                              width: double.infinity,
                                            ),
                                      crossFadeState: _open == i
                                          ? CrossFadeState.showSecond
                                          : CrossFadeState.showFirst,
                                    ),
                                    SizedBox(height: spacing.md),
                                  ],
                                ],
                              ),
                            },
                          ),
                      ], heroSafe: true),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The drawn top of the workshops tab — the same anatomy as the
/// gallery's, with brushes and a glaze pot in it instead of cameras.
class _WorkshopsIntro extends StatelessWidget {
  const _WorkshopsIntro({this.entrance = false, this.titleMorph});

  /// Passed straight through to [IllustratedHeader].
  final bool entrance;

  /// And so is this — the heading is endpoint 0 of the flight into the
  /// bar's own title.
  final InPageHeroController? titleMorph;

  /// The lidded glaze pot. Sits at the START.
  static const _pot = 'assets/images/workshop-illustration-1.png';

  /// The brush and its paint jars. Sits at the END.
  static const _brushes = 'assets/images/workshop-illustration-2.png';

  static const _star = 'assets/images/star-illustration.png';

  @override
  Widget build(BuildContext context) {
    // The words below are read HERE, so this build has to run again
    // when the language changes — see `dependOnLanguage`.
    dependOnLanguage(context);

    return IllustratedHeader(
      entrance: entrance,
      titleMorph: titleMorph,
      mirrorKey: const ValueKey('workshops-header-mirror'),
      title: WorkshopStrings.title,
      subtitle: WorkshopStrings.subtitle,
      // PHYSICAL sides, read as the Arabic composition — `right` is the
      // START edge. See `IllustratedHeader`.
      art: const [
        HeaderArt(asset: _pot, width: 132, height: 132, top: 24, right: -10),
        HeaderArt(asset: _brushes, width: 124, height: 152, top: 40, left: -6),
        HeaderArt(asset: _star, width: 68, height: 68, bottom: 24, left: 28),
        HeaderArt(asset: _star, width: 56, height: 56, bottom: 40, right: 26),
      ],
    );
  }
}

/// Three placeholder bands in the catalogue's own rhythm, so nothing
/// jumps when the workshops arrive.
class _CatalogueSkeleton extends StatelessWidget {
  const _CatalogueSkeleton();

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < 3; i++) ...[
          SizedBox(
            height: 124,
            child: SkeletonBlock(radius: context.radii.sm),
          ),
          SizedBox(height: spacing.md),
        ],
      ],
    );
  }
}

/// The catalogue did not arrive.
class _CatalogueError extends StatelessWidget {
  const _CatalogueError({required this.error, required this.onRetry});

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

/// «ورشاتي» — the caller's own bookings, in whatever state asking for
/// them left the page.
///
/// FOUR answers, not one list: no account, still asking, it did not
/// arrive, and the bookings themselves. Collapsing the first three into
/// an empty list would tell a guest they have never booked anything,
/// which is not what the server said.
class _MyBookings extends StatefulWidget {
  const _MyBookings({
    required this.state,
    required this.workshopFor,
    required this.onRetry,
    required this.onOpen,
  });

  final MyBookingsState state;

  /// The catalogue row behind a booking, for the family that colours
  /// its card. Null when the catalogue has not arrived or no longer
  /// lists that workshop.
  final Workshop? Function(int workshopId) workshopFor;

  final VoidCallback onRetry;
  final ValueChanged<MyWorkshopEntry> onOpen;

  @override
  State<_MyBookings> createState() => _MyBookingsState();
}

class _MyBookingsState extends State<_MyBookings> {
  /// The status being filtered to, or null for all of them.
  ///
  /// Held by the LIST rather than the page: it is a way of reading
  /// this list, and it should not survive switching to the catalogue
  /// and back.
  String? _status;

  MyBookingsState get state => widget.state;
  Workshop? Function(int) get workshopFor => widget.workshopFor;
  VoidCallback get onRetry => widget.onRetry;
  ValueChanged<MyWorkshopEntry> get onOpen => widget.onOpen;

  @override
  Widget build(BuildContext context) {
    // Nothing to ask for, and a way forward that is not "try again".
    if (state.signedOut) {
      return GlobalEmptyState(
        icon: Icons.lock_outline_rounded,
        title: AuthStrings.signInRequiredTitle,
        subtitle: AuthStrings.signInRequiredMessage,
        primaryAction: GlobalFilledButton(
          text: AuthStrings.signIn,
          onPressed: () => unawaited(AuthGate.demand(context)),
          style: terracottaCtaStyle(showArrow: false),
        ),
      );
    }

    if (state.loading && !state.hasData) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 80),
        child: Center(child: CircularProgressIndicator.adaptive()),
      );
    }

    // A failed load with nothing behind it. A failed REFRESH keeps the
    // list that is already on screen and says nothing.
    if (state.error != null && !state.hasData) {
      return _CatalogueError(error: state.error!, onRetry: onRetry);
    }

    final entries = [
      for (final booking in state.bookings)
        if (workshopFor(booking.workshopId) case final workshop?)
          myWorkshopEntry(
            context,
            booking,
            family: WorkshopFamily.fromWire(workshop.type.wire),
            // THE STUDIO'S COLOUR FOR THIS WORKSHOP. The booking row
            // carries no `color` and no `type`, so the catalogue —
            // matched on `workshop_id` — is the only thing that can
            // answer it. A booking whose workshop the catalogue no
            // longer lists keeps the family's own hue.
            wireColor: workshop.color,
          )
        else
          // The catalogue does not list it — a workshop the studio
          // retired, or a catalogue that has not landed yet. The
          // booking is still the customer's and still shows.
          myWorkshopEntry(context, booking),
    ];

    // The chips are built from the WHOLE list, not the filtered one —
    // otherwise choosing «ملغاة» would leave a strip with only
    // «ملغاة» on it and no way back.
    // THE SERVER'S TALLY, which is the customer's whole history — so
    // «ملغاة ٣» stays 3 once «ملغاة» is chosen. See
    // [BookingStatusFilter.countsFor].
    final counts = BookingStatusFilter.countsFor(
      entries,
      serverCounts: state.statusCounts,
    );
    final total = BookingStatusFilter.totalFor(
      counts,
      serverCounts: state.statusCounts,
    );
    final shown = _status == null
        ? entries
        : [
            for (final entry in entries)
              if (entry.status == _status) entry,
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // EDGE TO EDGE — the strip escapes the shell's gutter itself
        // and sets its own inset. See [BookingStatusFilter].
        BookingStatusFilter(
          counts: counts,
          total: total,
          selected: _status,
          onChanged: (status) => setState(() => _status = status),
        ),
        if (counts.length > 1) SizedBox(height: context.spacing.md),
        MyWorkshopsList(entries: shown, onOpen: onOpen),
      ],
    );
  }
}
