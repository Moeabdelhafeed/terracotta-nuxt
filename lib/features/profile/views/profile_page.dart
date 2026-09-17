import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_gate.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/strings/common_strings.dart';
import '../../../core/localization/strings/complaint_strings.dart';
import '../../../core/localization/strings/piece_strings.dart';
import '../../../core/localization/strings/profile_strings.dart';
import '../../../core/localization/strings/shop_strings.dart';
import '../../../core/localization/strings/workshop_strings.dart';
import '../../../core/tokens/extensions.dart';
import '../../../data/blocs/auth/auth_bloc.dart';
import '../../../data/models/auth/user/user.dart';
import '../../../shared/common/text_form_fields/text_form_fields.dart';
import '../../../shared/module/container/global_container.dart';
import '../../../shared/module/dialog/global_dialog.dart';
import '../../../shared/module/refreshable/global_refreshable.dart';
import '../../../shared/module/scrollable/global_scrollable.dart';
import '../../../shared/module/toast/global_toast.dart';
import '../../_shared/account_refresh.dart';
import '../../_shared/favorites_registry.dart';
import '../../_shared/screen_entrance.dart';
import '../../_shared/tab_entrance.dart';
import '../../auth/widgets/auth_failure.dart';
import '../../auth/widgets/verify_account_card.dart';
import '../../gift/data/gift_availability.dart';
import '../../gift/widgets/gift_credit_sheet.dart';
import '../../shell/widgets/terracotta_app_bar.dart';
import '../../shell/widgets/terracotta_nav_bar.dart';
import '../../shop/widgets/favorites_sheet.dart';
import '../cubits/notifications_cubit.dart';
import '../cubits/notifications_state.dart';
import '../cubits/pages_cubit.dart';
import '../cubits/profile_counts_cubit.dart';
import '../cubits/wallet_cubit.dart';
import '../cubits/wallet_state.dart';
import '../data/account_actions.dart';
import '../widgets/account_header.dart';
import '../widgets/contact_studio_sheet.dart';
import '../widgets/profile_widgets.dart';

/// «حسابي» — the account home.
///
/// **Nothing in the design.** The bottom nav has carried a person icon
/// with nothing behind it; this is built from the existing component
/// vocabulary per the intake decision.
///
/// The load-bearing item is DELETE ACCOUNT: both app stores require it
/// to be reachable in-app, and `DELETE /api/delete-account` is
/// immediate and permanent with no retention — so it gets a
/// confirmation rather than a single tap.
class ProfilePage extends StatefulWidget {
  const ProfilePage({this.wallet, super.key});

  /// A cubit to use instead of the app's — the seam a widget test
  /// needs, since the page loads on mount. Null in the app.
  final WalletCubit? wallet;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  /// Shared with the app bar and the nav bar, which both retreat as the
  /// page scrolls.
  final _scroll = ScrollController();
  final _cancel = CancelToken();

  /// The rename dialog's field. Lives as long as the PAGE — see
  /// `_editName`.
  final _name = TextEditingController();

  /// The studio's own pages, shared with the register screen's terms
  /// link. Not closed here: it is the app's, not this page's.
  ///
  /// NULLABLE on purpose. A container without one is a test that does
  /// not care about this section, and the section simply does not
  /// draw — the same rule `FavoriteWriter` follows for the device
  /// wishlist. The alternative is every widget test in the app having
  /// to know about a list of policy pages.
  late final PagesCubit? _pages = getIt.isRegistered<PagesCubit>()
      ? getIt<PagesCubit>()
      : null;

  /// Whether this build gets the arrival, held so a rebuild cannot
  /// change its mind halfway through one — swapping the staged column
  /// for a bare one mid-animation would leave the rows wherever the
  /// fade had got to.
  bool? _claim;

  /// The rows, staged on the FIRST sight of this tab in the session and
  /// left alone on every one after it. See [TabEntrance].
  List<Widget> _staged(List<Widget> rows) =>
      (_claim ??= TabEntrance.claim(TabEntranceKey.profile))
      ? ScreenEntrance.stage(rows)
      : rows;

  /// The one `name` field the wire keeps, put back together from the
  /// two halves `toAppUser` split it into.
  static String _fullName(User user) => [
    ?user.firstName,
    ?user.lastName,
  ].where((part) => part.trim().isNotEmpty).join(' ');

  /// The APP's cubit — the profile tab is a top-level route, so
  /// `context.go` disposes this State and a page-owned cubit went with
  /// it. Not closed here for the same reason.
  late final _wallet = widget.wallet ?? getIt<WalletCubit>();

  /// The numbers beside the rows. The app's own, for the same reason
  /// the wallet above it is.
  ///
  /// NULLABLE, like [_pages]: a widget test pumps this page without
  /// the service locator, and a row that cannot say how many is a row
  /// without a number, not a screen that fails to build.
  /// The inbox, for the unread number on its row — the app's own, the
  /// same one the bell in every bar reads. Null when the locator has
  /// none, for the same reason [_counts] is.
  late final NotificationsCubit? _inbox =
      getIt.isRegistered<NotificationsCubit>()
      ? getIt<NotificationsCubit>()
      : null;

  late final ProfileCountsCubit? _counts =
      getIt.isRegistered<ProfileCountsCubit>()
      ? getIt<ProfileCountsCubit>()
      : null;

  /// `GET /api/user`, on EVERY arrival and on every pull.
  ///
  /// See [AccountRefresh] — this page is the reason it exists, and
  /// the wallet, orders, pieces and inbox screens share it.
  Future<void> _refreshUser() => AccountRefresh.user(context);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // WHO THEY ARE, re-read every time. See [_refreshUser].
    unawaited(_refreshUser());
    // Not for a guest: `/api/wallet/*` answers 401 for them, and asking
    // anyway is a request whose only outcome is a line in the log.
    if (AuthGate.has(context)) {
      unawaited(_wallet.ensureLoaded());
      // The four counts, in one batch — see [ProfileCountsCubit].
      // Every one of them is the caller's own and answers 401 without
      // a session, which the app reads as the session ending.
      unawaited(_counts?.ensureLoaded() ?? Future.value());
    } else {
      // A guest has none of these things, and whatever is in there
      // belongs to whoever was signed in before.
      _counts?.clear();
    }
    // PUBLIC, so it is asked for whoever is reading. Locale-scoped:
    // the names and the words are the server's.
    if (_pages case final pages?) {
      unawaited(
        pages.ensureLoaded(Localizations.localeOf(context).languageCode),
      );
    }
  }

  @override
  void dispose() {
    _cancel.cancel('profile closed');
    _name.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// A row that needs an account: go there, or ask for one.
  ///
  /// The page itself is NOT gated. Bouncing a visitor off the whole
  /// screen the moment they tap the account tab teaches them the app is
  /// closed; refusing the one row tells them which thing needs signing
  /// in, with everything else still under their thumb.
  Future<void> _gated(BuildContext context, String route) =>
      AuthGate.demand(context, action: () => context.pushNamed(route));

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    // Built once so its height can be RESERVED below. The bar is
    // transparent and fades in as the page moves, which needs the body
    // behind it — and `extendBodyBehindAppBar` then starts that body at
    // the top of the SCREEN, so nothing reserves the toolbar and the
    // first card sat 40dp under it. The other tabs hide this by filling
    // the bar's `expanded` slot; this page has none.
    final bar = TerracottaAppBar(
      controller: _scroll,
      collapsedTitle: ProfileStrings.title,
      transparent: true,
      // This page puts nothing in the bar's `expanded` slot, so without
      // this it showed an empty bar until the reader scrolled — the
      // account tab with no name on it.
      alwaysShowTitle: true,
    );

    // Rebuilds the page when the session ends under it — a 401 mid-read
    // clears the token, and this list must not keep offering «تسجيل
    // الخروج» to someone already out.
    final signedIn = AuthGate.watch(context);

    return TerracottaNavBar.wrapScaffold(
      context,
      currentIndex: 4,
      // The rail goes AROUND the scaffold: it has to sit in
      // front of the app bar and move it along, and nothing
      // inside the body can do either.
      child: Scaffold(
        backgroundColor: context.backgroundColors.scaffoldBackground,
        appBar: bar,
        extendBodyBehindAppBar: true,
        extendBody: true,
        // NOTHING HERE in a short window — the destinations are
        // on a rail over the body instead. The slot has no
        // height limit, so a rail put in it takes the screen.
        bottomNavigationBar: TerracottaNavBar.bottomSlot(
          context,
          currentIndex: 4,
          scrollController: _scroll,
        ),
        body: SafeArea(
          // NEITHER edge. `extendBodyBehindAppBar` folds the bar's whole
          // height into the body's own inset, so taking the top again
          // would push the page down by a second toolbar — and taking the
          // BOTTOM stopped the body above the home indicator, which left
          // a strip of bare scaffold showing every time the nav bar
          // retreated. Both insets are paid for in the padding below.
          top: false,
          bottom: false,
          child: GlobalRefreshable(
            onRefresh: () async {
              if (AuthGate.has(context)) {
                await Future.wait([
                  // THE ACCOUNT RECORD TOO. A pull on this page is a
                  // customer asking "is this still right about me" —
                  // and the name, the verified number and the wallet
                  // balance all live on `GET /api/user`, which the
                  // wallet and the counts below do not carry. In the
                  // same batch, so the spinner covers all three rather
                  // than ending while one is still in flight.
                  _refreshUser(),
                  _wallet.refresh(),
                  if (_counts case final counts?) counts.load(),
                ]);
              }
            },
            // The spinner drops from the TOP OF THE BODY, and this body
            // starts behind the status bar — so it appeared under the
            // notch. Pushed down past the bar it lives under.
            style: RefreshableStyle(
              edgeOffset:
                  MediaQuery.paddingOf(context).top + bar.preferredSize.height,
            ),
            child: GlobalScrollable(
              controller: _scroll,
              // The CALLER has to ask. Without it a page shorter than the
              // viewport drops the drag recogniser and the pull never
              // happens — and this page is short.
              physics: const AlwaysScrollableScrollPhysics(),
              child: GlobalContainer.shell(
                padding: EdgeInsetsDirectional.fromSTEB(
                  // Plus the RAIL's side in a short window.
                  spacing.md,
                  // The bar's own height plus the status inset the
                  // `SafeArea(top: false)` above deliberately did not
                  // take — asked of the bar rather than typed, so a
                  // change to its height cannot leave this behind.
                  MediaQuery.paddingOf(context).top +
                      bar.preferredSize.height +
                      spacing.md,
                  spacing.md,
                  TerracottaNavBar.reservedHeightIn(context) + spacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  // ONCE, on the first sight of this tab in the session.
                  //
                  // Every row here exists the moment the page is built,
                  // so there is no waiting to cover — the stagger is the
                  // page introducing itself, and a page that introduces
                  // itself on the fortieth visit is a page that is slow.
                  // See [TabEntrance].
                  //
                  // Nothing in this column flies, so it gets the rise.
                  children: _staged([
                    BlocBuilder<WalletCubit, WalletState>(
                      bloc: _wallet,
                      builder: (context, state) => AccountHeader(
                        wallet: state,
                        onEditName: (user) =>
                            unawaited(_editName(context, user)),
                        onOpenWallet: () =>
                            unawaited(_gated(context, 'wallet')),
                        onSignIn: () => context.pushNamed('login'),
                      ),
                    ),
                    SizedBox(height: spacing.lg),
                    // AN ACCOUNT THAT CANNOT BUY YET.
                    //
                    // Directly under the header, because this page is
                    // where somebody comes to look at their own
                    // account and this is a fact about it. Collapses
                    // to nothing for a visitor and for a finished
                    // account — see [VerifyAccountCard].
                    const VerifyAccountCard(),
                    // No «تعديل الملف» row: the only editable field is the
                    // name, and it is a pencil in the header above.
                    // No «محفظتي» row either — the balance strip up there
                    // is the way in, and two doors to one screen is one
                    // too many.
                    // THE NUMBERS BESIDE THE ROWS. One builder over the
                    // whole run of them, rather than one per row: they
                    // all land together, from one cubit, in one batch.
                    if (_counts case final counts?)
                      BlocBuilder<ProfileCountsCubit, ProfileCountsState>(
                        bloc: counts,
                        builder: _accountRows,
                      )
                    else
                      _accountRows(context, const ProfileCountsState()),
                    // THE STUDIO'S OWN WRITING — terms, privacy, returns,
                    // shipping, about.
                    //
                    // Listed from what the server publishes rather than
                    // from a hardcoded five: the CMS can add a sixth
                    // tomorrow, and a row per slug typed in here would be
                    // a section that quietly went out of date. Public,
                    // like the pages themselves.
                    if (_pages case final cubit?)
                      BlocBuilder<PagesCubit, PagesState>(
                        bloc: cubit,
                        builder: (context, pages) => pages.pages.isEmpty
                            // Nothing yet, or nothing at all. Either way an
                            // empty section header over no rows is worse
                            // than no section.
                            ? const SizedBox.shrink()
                            : ProfileSection(
                                children: [
                                  for (final page in pages.pages)
                                    ProfileRow(
                                      // The CMS's own name for it.
                                      label: page.name,
                                      icon: Icons.article_rounded,
                                      onTap: () => context.pushNamed(
                                        'page',
                                        pathParameters: {'slug': page.slug},
                                      ),
                                    ),
                                ],
                              ),
                      ),
                    // Only for someone who HAS an account. A guest has no
                    // password to change, no session to end and nothing to
                    // delete — rows offering all three would be three
                    // separate lies rather than a gate.
                    // الإعدادات — language, text size, notifications.
                    //
                    // PUBLIC: a visitor changes the language too, and
                    // it is the one screen they are most likely to
                    // need before anything else. The route existed and
                    // nothing linked to it.
                    ProfileSection(
                      children: [
                        ProfileRow(
                          label: CommonStrings.settings,
                          icon: Icons.settings_rounded,
                          onTap: () => context.pushNamed('settings'),
                        ),
                      ],
                    ),
                    if (signedIn) ...[
                      ProfileSection(
                        children: [
                          ProfileRow(
                            label: ProfileStrings.changePassword,
                            icon: Icons.lock_rounded,
                            onTap: () => context.pushNamed('change-password'),
                          ),
                        ],
                      ),
                      ProfileSection(
                        children: [
                          ProfileRow(
                            label: ProfileStrings.logout,
                            icon: Icons.logout_rounded,
                            onTap: () => unawaited(_signOut(context)),
                          ),
                          // Permanent and immediate — see the class doc.
                          ProfileRow(
                            label: ProfileStrings.deleteAccount,
                            icon: Icons.delete_forever_rounded,
                            tint: context.statusColors.error,
                            onTap: () => unawaited(_deleteAccount(context)),
                          ),
                        ],
                      ),
                    ],
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Rename the account.
  ///
  /// A dialog with one input rather than a page: the name is the only
  /// field this tenant lets anyone change — `phone` is the login
  /// identifier and the endpoint refuses it, and `username` / `email`
  /// sit behind flags that are off.
  /// The account rows and their tallies.
  ///
  /// A method rather than an inline block so the page can build it
  /// with or without a [ProfileCountsCubit] behind it — see [_counts].
  Widget _accountRows(BuildContext context, ProfileCountsState counts) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProfileSection(
            children: [
              ProfileRow(
                label: ProfileStrings.addresses,
                icon: Icons.location_on_rounded,
                count: counts.addresses,
                // NOT gated. A guest's address book lives on
                // the device — see `GuestAddresses` — for the
                // same reason their basket and wishlist do.
                onTap: () => context.pushNamed('address-book'),
              ),
              // «أهدِ رصيداً» — the same sheet the wallet tile on the
              // shop and workshops pages opens, reachable from the one
              // screen a customer goes to when they are looking for
              // their OWN things rather than browsing.
              //
              // GATED ON THE STUDIO, not on the reader: `allow_gift`
              // off takes the whole surface away, here and on both
              // tiles, rather than leaving a row that opens a sheet
              // saying no. See `AppConfigService.allowsGift`.
              if (giftsAllowed())
                ProfileRow(
                  label: WorkshopStrings.gift,
                  icon: Icons.card_giftcard_rounded,
                  onTap: () => unawaited(showGiftCreditSheet(context)),
                ),
              ProfileRow(
                label: ShopStrings.myFavorites,
                icon: Icons.favorite_rounded,
                count: counts.favorites,
                // The shop's own sheet, and the app's registry
                // with it — a heart taken off here empties the
                // same heart on the rails behind it.
                // NOT gated. A guest has a wishlist of their
                // own on the device, and the sheet opens on
                // whichever list this reader actually has.
                onTap: () => unawaited(
                  showFavoritesSheet(
                    context,
                    registry: getIt<FavoritesRegistry>(),
                  ),
                ),
              ),
            ],
          ),
          ProfileSection(
            children: [
              ProfileRow(
                label: ProfileStrings.orders,
                icon: Icons.receipt_long_rounded,
                count: counts.orders,
                onTap: () => unawaited(_gated(context, 'my-orders')),
              ),
              // «قطعي» — what the customer has MADE, as
              // opposed to what they have bought. Gated: the
              // pieces are the caller's own.
              ProfileRow(
                label: PieceStrings.title,
                icon: Icons.coffee_rounded,
                onTap: () => unawaited(_gated(context, 'my-pieces')),
              ),
              // UNREAD, not the inbox's size: what a
              // number on this row answers is "is there
              // anything waiting", and «الاشعارات ٤٢» for
              // forty-two read ones answers a question
              // nobody asked. Read from the same singleton
              // the bell in every bar reads, so the two can
              // never disagree.
              // NOT `bloc: _inbox` with a null: `BlocBuilder`
              // handed no bloc falls back to `context.read`,
              // and this page has no provider for one — which
              // is a `ProviderNotFoundException` rather than
              // the row simply going without its number. See
              // [_counts] for why either can be absent.
              if (_inbox case final inbox?)
                BlocBuilder<NotificationsCubit, NotificationsState>(
                  bloc: inbox,
                  buildWhen: (a, b) => a.unread != b.unread,
                  builder: (context, state) => _notificationsRow(
                    context,
                    state.unread,
                  ),
                )
              else
                _notificationsRow(context, 0),
              // «تواصل معنا» — the studio's own channels.
              //
              // These two rows had ONE entry between them and it
              // pointed at the complaints screen, so a customer who
              // wanted to message the studio had to file a formal
              // complaint against an order to do it. Public, like the
              // sheet it opens.
              ProfileRow(
                label: ProfileStrings.contactUs,
                icon: Icons.chat_bubble_outline_rounded,
                onTap: () => unawaited(showContactStudioSheet(context)),
              ),
              ProfileRow(
                // «إرسال شكوى», not «تواصل معنا» — see
                // [ComplaintStrings.sendTitle]. This screen files a
                // complaint against an ORDER; it had been wearing the
                // words a customer looks for when they only want to
                // say hello.
                label: ComplaintStrings.sendTitle,
                icon: Icons.support_agent_rounded,
                count: counts.complaints,
                // NOT gated. Filing a complaint is public —
                // someone with no account is exactly the person
                // who may need to.
                onTap: () => context.pushNamed('complaints'),
              ),
            ],
          ),
        ],
      );

  /// The notifications row, with its UNREAD count.
  ///
  /// Unread rather than the inbox's size: what a number on this row
  /// answers is "is there anything waiting", and «الاشعارات ٤٢» for
  /// forty-two read ones answers a question nobody asked. Zero draws
  /// NOTHING here, unlike the rows above it — «٠» beside a bell reads
  /// as a badge that failed to clear.
  Widget _notificationsRow(BuildContext context, int unread) => ProfileRow(
    label: ProfileStrings.notifications,
    icon: Icons.notifications_rounded,
    count: unread > 0 ? unread : null,
    countTint: context.statusColors.error,
    // NOT GATED. The inbox needs a session and says so itself — see
    // `NotificationsInboxPage`. Stopping a guest at the row told them
    // less than the screen does.
    onTap: () => context.pushNamed('notifications'),
  );

  Future<void> _editName(BuildContext context, User user) async {
    final auth = context.read<AuthBloc>();
    // OWNED BY THE STATE, not by this call.
    //
    // Disposing it the moment the dialog's future returns kills it
    // while the exit transition is still running — the field is on
    // screen for another frame, rebuilds, and asserts "used after being
    // disposed", which then takes the overlay's own teardown down with
    // it (`_dependents.isEmpty`, duplicate `GlobalKey`s). The State
    // outlives every dialog it opens, so it is the right owner.
    final controller = _name..text = _fullName(user);

    // `show` rather than `confirm`: only `show` takes a `content`, and
    // a rename dialog with no field in it is just a question.
    var saved = false;
    await GlobalDialog.show<void>(
      context: context,
      title: ProfileStrings.editName,
      confirmText: CommonStrings.save,
      cancelText: CommonStrings.cancel,
      icon: Icons.edit_rounded,
      content: Padding(
        padding: EdgeInsets.only(top: context.spacing.sm),
        child: SimpleTextField(
          controller: controller,
          label: ProfileStrings.nameLabel,
          hint: ProfileStrings.nameHint,
          textInputAction: TextInputAction.done,
        ),
      ),
      onConfirm: () => saved = true,
    );

    final name = controller.text.trim();
    if (!saved || !context.mounted) return;
    // Nothing to send, and an empty name would leave the account with
    // none — the field is the whole form, so this is its validation.
    if (name.isEmpty) return;

    final failure = await AccountActions.rename(
      auth,
      user,
      name: name,
      cancelToken: _cancel,
    );
    if (!context.mounted) return;

    if (failure != null) {
      showAuthFailure(failure);
      return;
    }
    GlobalToast.success(ProfileStrings.nameUpdated);
  }

  /// Sign out, once the customer has said so.
  ///
  /// The dialog is friendly rather than a warning: signing out is
  /// reversible and costs them nothing, and dressing it as a danger
  /// makes the DESTRUCTIVE one below indistinguishable from it.
  Future<void> _signOut(BuildContext context) async {
    final auth = context.read<AuthBloc>();
    final confirmed = await GlobalDialog.confirm(
      context: context,
      title: ProfileStrings.signOutTitle,
      message: ProfileStrings.signOutMessage,
      confirmText: ProfileStrings.logout,
      icon: Icons.logout_rounded,
    );
    if (!confirmed || !context.mounted) return;

    // The local session is cleared WHATEVER the server says — see
    // `AccountActions`.
    await AccountActions.signOut(auth, cancelToken: _cancel);
    if (!context.mounted) return;
    context.goNamed('home');
  }

  /// End the account. Permanent, immediate, no retention window.
  Future<void> _deleteAccount(BuildContext context) async {
    final auth = context.read<AuthBloc>();
    final confirmed = await GlobalDialog.confirm(
      context: context,
      title: ProfileStrings.deleteAccount,
      // What GOES, not "are you sure" — the customer cannot weigh a
      // question that does not say what it costs.
      message:
          '${ProfileStrings.deleteWarning}\n\n'
          '${ProfileStrings.deleteMessage}',
      confirmText: ProfileStrings.deleteConfirm,
      isDestructive: true,
      icon: Icons.delete_forever_rounded,
    );
    if (!confirmed || !context.mounted) return;

    final failure = await AccountActions.deleteAccount(
      auth,
      cancelToken: _cancel,
    );
    if (!context.mounted) return;

    // Still signed in, and the account is still there.
    if (failure != null) {
      showAuthFailure(failure);
      return;
    }
    context.goNamed('home');
  }
}
