// Flutter imports:
import 'package:flutter/material.dart';
// Package imports:
import 'package:go_router/go_router.dart';

import '../../core/legal/legal_page.dart';
import '../../core/navigation/route_extras.dart';
import '../../core/navigation/transitions/route_transition.dart';
import '../../core/system_pages/error_payload.dart';
import '../../data/models/terracotta/account/address.dart';
import '../../data/services/remote_config_service.dart';
import '../../features/auth/data/otp_purpose.dart';
import '../../features/auth/views/forgot_password_page.dart';
import '../../features/auth/views/login_page.dart';
import '../../features/auth/views/otp_verification_page.dart';
import '../../features/auth/views/register_page.dart';
import '../../features/auth/views/register_success_page.dart';
import '../../features/auth/views/reset_otp_page.dart';
import '../../features/auth/views/reset_password_page.dart';
import '../../features/booking/views/booking_confirmed_page.dart';
import '../../features/booking/views/booking_detail_page.dart';
import '../../features/booking/views/booking_schedule_page.dart';
import '../../features/booking/views/piece_selection_page.dart';
import '../../features/checkout/views/booking_checkout_page.dart';
import '../../features/checkout/views/delivery_checkout_page.dart';
import '../../features/checkout/views/gift_checkout_page.dart';
import '../../features/checkout/views/order_confirmed_page.dart';
import '../../features/checkout/views/shop_checkout_page.dart';
import '../../features/gallery/views/gallery_albums_page.dart';
import '../../features/gift/data/gift_draft.dart';
import '../../features/gift/views/gift_claim_page.dart';
import '../../features/gift/views/gift_purchased_page.dart';
import '../../features/home/views/home_page.dart';
import '../../features/onboarding/data/terracotta_onboarding_pages.dart';
import '../../features/onboarding/views/onboarding_page.dart';
import '../../features/profile/views/address_book_page.dart';
import '../../features/profile/views/change_password_page.dart';
import '../../features/profile/views/complaints_page.dart';
import '../../features/profile/views/my_orders_page.dart';
import '../../features/profile/views/my_pieces_page.dart';
import '../../features/profile/views/notifications_inbox_page.dart';
import '../../features/profile/views/order_detail_page.dart';
import '../../features/profile/views/profile_page.dart';
import '../../features/profile/views/push_diagnostics_page.dart';
import '../../features/profile/views/settings_page.dart';
import '../../features/profile/views/static_page_view.dart';
import '../../features/profile/views/wallet_page.dart';
import '../../features/scanner/views/scanner_desk_page.dart';
import '../../features/shell/widgets/terracotta_nav_bar.dart';
import '../../features/shop/views/product_detail_page.dart';
import '../../features/shop/views/product_list_page.dart';
import '../../features/shop/views/shop_home_page.dart';
import '../../features/splash/views/splash_page.dart';
import '../../features/workshops/views/workshops_page.dart';
import '../../features/workshops/workshops_tab.dart';
import '../../shared/module/feedback/feedback_screen.dart';
import '../../shared/module/legal/legal_index_page.dart';
import '../../shared/module/legal/legal_screen.dart';
import '../../shared/module/system_pages/coming_soon_page.dart';
import '../../shared/module/system_pages/error_page.dart';
import '../../shared/module/system_pages/not_found_page.dart';

class AppRoutes {
  const AppRoutes._();

  /// The default page builder — one place, so routes stay a list of
  /// destinations rather than a list of animations.
  ///
  /// ONE way to say it: a route hands over a `TransitionStyle`. A
  /// `type:` shorthand beside it would be a second spelling of a
  /// one-field bag, which is the duplication the transition rewrite
  /// removed in the first place — `TransitionStyle(type: x)` is the
  /// same length.
  ///
  /// What the route does not answer falls through to
  /// `GlobalTransitionTheme`, and a caller can still override per push
  /// with a `TransitionOverride` in the extras.
  static Page<void> _page(
    BuildContext context,
    GoRouterState state,
    Widget child, {
    TransitionStyle style = const TransitionStyle(type: TransitionType.none),
  }) {
    return RouteTransition.buildPage<void>(
      context: context,
      state: state,
      child: child,
      // SWITCHING TABS IS NOT A JOURNEY.
      //
      // The five tabs are siblings, and `context.go` replaces the
      // stack — so the tab being left played its own transition in
      // reverse on the way out while the next one faded in. Two
      // animations for a move the reader thinks of as instant, and
      // the outgoing one is the half that reads as wrong: nothing
      // "left", the reader just looked somewhere else.
      //
      // Only tab-TO-tab is collapsed. Arriving at a tab from a detail
      // page still animates, because that IS a journey back.
      style:
          TerracottaNavBar.isTabPath(state.uri.path) &&
              TerracottaNavBar.leftATab
          ? const TransitionStyle(type: TransitionType.none)
          : style,
    );
  }

  // ==================== Routes ====================

  static final GoRoute splash = GoRoute(
    name: 'splash',
    path: '/',
    pageBuilder: (context, state) => _page(
      context,
      state,
      const SplashPage(),
      style: const TransitionStyle(type: TransitionType.fade),
    ),
  );

  static final GoRoute onboarding = GoRoute(
    name: 'onboarding',
    path: '/onboarding',
    pageBuilder: (context, state) => _page(
      context,
      state,
      OnboardingFlowPage(
        // A BUILDER, not a built list: the copy is localized, and a
        // list made once keeps whatever language it was made in.
        pagesBuilder: terracottaOnboardingPages,
        onFinish: (ctx) => ctx.go(splash.path),
      ),
      style: const TransitionStyle(type: TransitionType.fade),
    ),
  );

  static final GoRoute feedback = GoRoute(
    name: 'feedback',
    path: '/feedback',
    pageBuilder: (context, state) => _page(
      context,
      state,
      const FeedbackScreen(),
      style: const TransitionStyle(type: TransitionType.slideFromEnd),
    ),
  );

  static final GoRoute comingSoon = GoRoute(
    name: 'coming-soon',
    path: '/coming-soon',
    pageBuilder: (context, state) => _page(
      context,
      state,
      ComingSoonPage(
        feature: state.uri.queryParameters['feature'],
        eta: state.uri.queryParameters['eta'],
        // `?notify=false` drops the waiting-list capture entirely.
        showNotifyForm: state.uri.queryParameters['notify'] != 'false',
      ),
      style: const TransitionStyle(type: TransitionType.fade),
    ),
  );
  static final GoRoute notFound = GoRoute(
    name: 'not-found',
    path: '/not-found',
    pageBuilder: (context, state) => _page(
      context,
      state,
      NotFoundPage(path: state.uri.queryParameters['path']),
      style: const TransitionStyle(type: TransitionType.fade),
    ),
  );
  static final GoRoute error = GoRoute(
    name: 'error',
    path: '/error',
    pageBuilder: (context, state) {
      final payload = state.extra is ErrorPayload
          ? state.extra as ErrorPayload?
          : null;
      return _page(
        context,
        state,
        ErrorPage(
          payload: payload,
          // Resolved here, not inside the module: shared/module/ widgets
          // take dependencies as params rather than reaching for services.
          supportEmail: RemoteConfigService.feedbackSupportEmail,
        ),
        style: const TransitionStyle(type: TransitionType.fade),
      );
    },
  );

  // ─── About / Legal ──────────────────────────────────────────
  // `/about` is the index hub. `/legal/<slug>` resolves the slug to
  // a [LegalPage] and renders [LegalScreen]; an unknown / disabled
  // slug falls through to the not-found page so deep links can't
  // surface a removed page.
  static final GoRoute about = GoRoute(
    name: 'about',
    path: '/about',
    pageBuilder: (context, state) => _page(
      context,
      state,
      const LegalIndexPage(),
      style: const TransitionStyle(type: TransitionType.slideFromEnd),
    ),
  );

  static final GoRoute legal = GoRoute(
    name: 'legal',
    path: '/legal/:slug',
    pageBuilder: (context, state) {
      final page = LegalPage.fromSlug(state.pathParameters['slug']);
      if (page == null) {
        return _page(
          context,
          state,
          Container(),
          style: const TransitionStyle(type: TransitionType.slideFromEnd),
        );
      }
      return _page(context, state, LegalScreen(page: page));
    },
  );

  /// EVERY transition, over one route.
  ///
  /// Seventeen near-identical `GoRoute`s used to sit here, two of them
  /// duplicates (`/transitions/rt-fade` was `/transitions/fade`). The
  /// type is a path parameter, so a new `TransitionType` needs no route
  /// at all — and the showcase builds its list from the enum, which
  /// means the page cannot fall behind the code.

  // ==================== Route Examples (Reference) ====================
  //
  // ─── 1. Simple page (no params) ──────────────────────────────
  //
  // static final GoRoute profile = GoRoute(
  //   name: 'profile',
  //   path: '/profile',
  //   pageBuilder: (context, state) => _page(context, state, const ProfilePage()),
  // );
  // // Navigate: context.push('/profile');
  //
  // ─── 2. Path parameters ──────────────────────────────────────
  //
  // static final GoRoute orderDetails = GoRoute(
  //   name: 'order-details',
  //   path: '/orders/:orderId',
  //   pageBuilder: (context, state) {
  //     final orderId = state.param('orderId'); // from route_extras.dart
  //     return _page(context, state, OrderDetailsPage(orderId: orderId ?? ''));
  //   },
  // );
  // // Navigate: context.push('/orders/123');
  //
  // ─── 3. Query parameters ─────────────────────────────────────
  //
  // static final GoRoute search = GoRoute(
  //   name: 'search',
  //   path: '/search',
  //   pageBuilder: (context, state) {
  //     final query = state.query('q');       // from route_extras.dart
  //     final page = state.queryInt('page');
  //     return _page(context, state, SearchPage(query: query, page: page ?? 1));
  //   },
  // );
  // // Navigate: context.push('/search?q=flutter&page=2');
  //
  // ─── 4. Extra data (hot-restart safe) ────────────────────────
  //
  // static final GoRoute deals = GoRoute(
  //   name: 'deals',
  //   path: '/deals/:dealId',  // Always include an ID in the path!
  //   pageBuilder: (context, state) {
  //     final dealId = state.param('dealId') ?? '';
  //     // Extra is optional enhancement — page must work without it
  //     final order = state.extraOrParse<Order>(Order.fromJson);
  //     return _page(context, state, DealsPage(dealId: dealId, order: order));
  //   },
  // );
  // // Navigate: context.push('/deals/456', extra: order);
  // // Hot restart: page gets dealId from URL, fetches order from API
  //
  // ─── 5. Nested routes ────────────────────────────────────────
  //
  // static final GoRoute settings = GoRoute(
  //   name: 'settings',
  //   path: '/settings',
  //   pageBuilder: (context, state) => _page(context, state, const SettingsPage()),
  //   routes: [
  //     GoRoute(
  //       name: 'settings-notifications',
  //       path: 'notifications',  // becomes /settings/notifications
  //       pageBuilder: (context, state) => _page(context, state, const NotificationsSettingsPage()),
  //     ),
  //     GoRoute(
  //       name: 'settings-privacy',
  //       path: 'privacy',  // becomes /settings/privacy
  //       pageBuilder: (context, state) => _page(context, state, const PrivacySettingsPage()),
  //     ),
  //   ],
  // );
  //
  // ─── 6. Shell route (shared layout) ──────────────────────────
  //
  // Use `StatefulShellRoute.indexedStack` for tab-style shells where
  // each branch must preserve its own navigation stack and scroll
  // position when the user switches tabs. Plain `ShellRoute` shares
  // a single Navigator across siblings and is the wrong fit when
  // sibling state should survive switching.
  //
  // static final StatefulShellRoute dashboardShell = StatefulShellRoute.indexedStack(
  //   builder: (context, state, navigationShell) {
  //     return DashboardLayout(navigationShell: navigationShell);
  //   },
  //   branches: [
  //     // Each branch has its own Navigator — sibling state is
  //     // preserved across switches without manual KeepAlive wiring.
  //     StatefulShellBranch(routes: [
  //       GoRoute(path: '/dashboard/home', builder: (_, __) => const DashboardHomePage()),
  //     ]),
  //     StatefulShellBranch(routes: [
  //       GoRoute(path: '/dashboard/analytics', builder: (_, __) => const AnalyticsPage()),
  //     ]),
  //     StatefulShellBranch(routes: [
  //       GoRoute(path: '/dashboard/users', builder: (_, __) => const UsersPage()),
  //     ]),
  //   ],
  // );
  //
  // // Switch tab from inside a branch:
  // // navigationShell.goBranch(1, initialLocation: true);
  //
  // ==================== End Examples ====================

  /// الإعدادات — language, text size and whether notifications are on.
  ///
  /// TERRACOTTA'S, not the template's. The template ships a settings
  /// page carrying an app-role switch, a saturation ramp and two
  /// reveal-animation pickers — controls for the people building the
  /// template, and nothing in this app ever linked to it. See
  /// `features/profile/views/settings_page.dart`.
  static final GoRoute settings = GoRoute(
    name: 'settings',
    path: '/settings',
    pageBuilder: (context, state) => _page(
      context,
      state,
      const SettingsPage(),
      style: const TransitionStyle(type: TransitionType.slideFromEnd),
    ),
  );

  /// Whether push actually works on this device — see
  /// [PushDiagnosticsPage].
  ///
  /// A route rather than a debug-overlay tool because the question it
  /// answers is asked on a TESTER's phone, running a release build
  /// where every `Logger.m` line is compiled out. Reached from
  /// Settings, and only on the non-production flavors.
  static final GoRoute pushDiagnostics = GoRoute(
    name: 'push-diagnostics',
    path: '/settings/push',
    pageBuilder: (context, state) => _page(
      context,
      state,
      const PushDiagnosticsPage(),
      style: const TransitionStyle(type: TransitionType.slideFromEnd),
    ),
  );

  // ══════════════ Terracotta ══════════════
  //
  // 32 destinations from the Pencil design. The bottom sheets and
  // dialogs are deliberately NOT here — they open over the page
  // behind them and must not replace it.

  /// اهلا بعودتك — Sign in with a phone number and password.
  static final GoRoute login = GoRoute(
    name: 'login',
    path: '/login',
    pageBuilder: (context, state) => _page(
      context,
      state,
      const LoginPage(),
      // A change of MODE — there is nothing behind it to slide away.
      style: const TransitionStyle(type: TransitionType.fade),
    ),
  );

  /// اهلا بك بتيراكوتا — Create an account.
  static final GoRoute register = GoRoute(
    name: 'register',
    path: '/register',
    pageBuilder: (context, state) => _page(
      context,
      state,
      const RegisterPage(),
      // A step forward WITHIN a flow. Directional, so one declaration
      // enters from the right in English and the left in Arabic.
      style: const TransitionStyle(type: TransitionType.slideFromEnd),
    ),
  );

  /// أدخل رمز التحقق — Five-box OTP after registering, with resend.
  static final GoRoute otpVerification = GoRoute(
    name: 'otp-verification',
    path: '/otp',
    pageBuilder: (context, state) => _page(
      context,
      state,
      OtpVerificationPage(
        // WHY it is open — verifying a new account, or finishing an
        // OTP-mode sign-in. See [OtpPurpose].
        purpose: state.extraAs<OtpPurpose>(),
      ),
      // A step forward WITHIN a flow. Directional, so one declaration
      // enters from the right in English and the left in Arabic.
      style: const TransitionStyle(type: TransitionType.slideFromEnd),
    ),
  );

  /// تم انشاء الحساب بنجاح — Confirmation after the OTP clears.
  static final GoRoute registerSuccess = GoRoute(
    name: 'register-success',
    path: '/register-success',
    pageBuilder: (context, state) => _page(
      context,
      state,
      const RegisterSuccessPage(),
      // Nothing behind it — going back would register again.
      style: const TransitionStyle(type: TransitionType.fade),
    ),
  );

  /// أدخل رقم هاتفك — Start a password reset by phone number.
  static final GoRoute forgotPassword = GoRoute(
    name: 'forgot-password',
    path: '/forgot-password',
    pageBuilder: (context, state) => _page(
      context,
      state,
      const ForgotPasswordPage(),
      // A step forward WITHIN a flow. Directional, so one declaration
      // enters from the right in English and the left in Arabic.
      style: const TransitionStyle(type: TransitionType.slideFromEnd),
    ),
  );

  /// تغيير كلمة السر — OTP for the password reset.
  static final GoRoute resetOtp = GoRoute(
    name: 'reset-otp',
    path: '/reset-otp',
    pageBuilder: (context, state) => _page(
      context,
      state,
      const ResetOtpPage(),
      // A step forward WITHIN a flow. Directional, so one declaration
      // enters from the right in English and the left in Arabic.
      style: const TransitionStyle(type: TransitionType.slideFromEnd),
    ),
  );

  /// تغيير كلمة السر — Set the new password.
  static final GoRoute resetPassword = GoRoute(
    name: 'reset-password',
    path: '/reset-password',
    pageBuilder: (context, state) => _page(
      context,
      state,
      const ResetPasswordPage(),
      // A step forward WITHIN a flow. Directional, so one declaration
      // enters from the right in English and the left in Arabic.
      style: const TransitionStyle(type: TransitionType.slideFromEnd),
    ),
  );

  /// الرئيسية — Greeting, the active booking card, featured pieces, offers, categories and the workshops row.
  static final GoRoute home = GoRoute(
    name: 'home',
    path: '/home',
    pageBuilder: (context, state) => _page(
      context,
      state,
      const HomePage(),
      // A TAB. `context.go` REPLACES the stack, so there is no depth
      // to slide through — and a direction would be whichever the
      // declaration happened to name, whatever tab you came from.
      style: const TransitionStyle(type: TransitionType.fade),
    ),
  );

  /// لحظات تيراكوتا — Album list with photo and video counts.
  static final GoRoute gallery = GoRoute(
    name: 'gallery',
    path: '/gallery',
    pageBuilder: (context, state) => _page(
      context,
      state,
      const GalleryAlbumsPage(),
      style: const TransitionStyle(type: TransitionType.fade),
    ),
  );

  /// ورشات تيراكوتا — The three workshop types, each card expanding in place to its full detail — gallery, info chips, description, location and the book CTA.
  static final GoRoute workshops = GoRoute(
    name: 'workshops',
    path: '/workshops',
    pageBuilder: (context, state) => _page(
      context,
      state,
      // `?tab=mine` is how the booking-confirmed screen opens
      // «ورشاتي» — it was sent and never read, so «تتبع الحجز» landed
      // on the catalogue with the booking it had just made on the
      // other side of the control. A query parameter rather than an
      // extra, because an extra does not survive a restart.
      WorkshopsPage(
        initialTab: WorkshopsTab.fromWire(state.uri.queryParameters['tab']),
      ),
      style: const TransitionStyle(type: TransitionType.fade),
    ),
  );

  /// الاستقبال — The front desk: today's sessions, and the camera.
  ///
  /// A route rather than a tab: staff and customers are mutually
  /// exclusive on the server, so this is where a scanner sign-in
  /// lands and the tab shell is not part of their app at all.
  static final GoRoute scannerDesk = GoRoute(
    name: 'scanner-desk',
    path: '/desk',
    pageBuilder: (context, state) => _page(
      context,
      state,
      const ScannerDeskPage(),
      // A DESTINATION, not a step: staff land here from sign-in and it
      // is the whole app for that account. Nothing slid it into place.
      style: const TransitionStyle(type: TransitionType.fade),
    ),
  );

  /// اختر موعد — Party size, then date, then slot.
  static final GoRoute bookingSchedule = GoRoute(
    name: 'booking-schedule',
    path: '/workshops/:workshopId/schedule',
    pageBuilder: (context, state) => _page(
      context,
      state,
      // What the workshops page already knew — the family tints every
      // screen from here to the confirmation, and re-deriving it from
      // the id would refetch a catalogue that is already in hand.
      BookingSchedulePage(args: state.extraAs<BookingScheduleArgs>()),
      style: const TransitionStyle(type: TransitionType.slideFromEnd),
    ),
  );

  /// اختيار القطع — Catalogue step — only for paint_your_piece and make_your_candle.
  static final GoRoute pieceSelection = GoRoute(
    name: 'piece-selection',
    path: '/workshops/:workshopId/pieces',
    pageBuilder: (context, state) => _page(
      context,
      state,
      PieceSelectionPage(args: state.extraAs<BookingCheckoutArgs>()),
      style: const TransitionStyle(type: TransitionType.slideFromEnd),
    ),
  );

  /// تم تاكيد حجز الورشة ! — Success screen.
  static final GoRoute bookingConfirmed = GoRoute(
    name: 'booking-confirmed',
    path: '/bookings/confirmed',
    pageBuilder: (context, state) => _page(
      context,
      state,
      // The created booking's `editable_until`, so the page states the
      // real deadline rather than a constant. Null when the booking
      // was made inside the window and has no cancellation right.
      BookingConfirmedPage(
        bookingId: state.extraMap<int>('bookingId'),
        editableUntil: state.extraMap<DateTime>('editableUntil'),
      ),
      // Nothing behind it to slide away — going back would book again.
      style: const TransitionStyle(type: TransitionType.fade),
    ),
  );

  /// الحجز مؤكد — The booking card, days-until countdown, location, scan code, reschedule and cancel.
  static final GoRoute bookingDetail = GoRoute(
    name: 'booking-detail',
    path: '/bookings/:bookingId',
    pageBuilder: (context, state) => _page(
      context,
      state,
      BookingDetailPage(
        bookingId: int.tryParse(state.pathParameters['bookingId'] ?? ''),
      ),
      style: const TransitionStyle(type: TransitionType.slideFromEnd),
    ),
  );

  /// متجر تيراكوتا — Featured pieces, latest offers, the category strip and the quick-action tiles.
  static final GoRoute shop = GoRoute(
    name: 'shop',
    path: '/shop',
    pageBuilder: (context, state) => _page(
      context,
      state,
      const ShopHomePage(),
      style: const TransitionStyle(type: TransitionType.fade),
    ),
  );

  /// تصفح الفئات — Browse a category or sub-category.
  static final GoRoute productList = GoRoute(
    name: 'product-list',
    path: '/shop/categories/:subCategoryId',
    pageBuilder: (context, state) => _page(
      context,
      state,
      ProductListPage(
        subCategoryId: int.tryParse(
          state.pathParameters['subCategoryId'] ?? '',
        ),
        // The tree the landing already merged the artwork into —
        // `GET /api/shop/categories` does not carry an `image` at all.
        args: state.extraAs<ProductBrowseArgs>(),
      ),
      style: const TransitionStyle(type: TransitionType.slideFromEnd),
    ),
  );

  /// كوب تيراكوتا — Title, price, colour swatches, size, the favourite heart and add-to-cart.
  static final GoRoute productDetail = GoRoute(
    name: 'product-detail',
    path: '/shop/products/:productId',
    pageBuilder: (context, state) => _page(
      context,
      state,
      ProductDetailPage(
        productId: state.pathParameters['productId'] ?? '',
        // What the tapped card already knew. Null on a deep link,
        // where the page has to fetch before it can show anything.
        preview: state.extraAs<ProductPreview>(),
      ),
      style: const TransitionStyle(type: TransitionType.slideFromEnd),
    ),
  );

  // ══════════════ WITHDRAWN: الخامات والأدوات ══════════════
  //
  // The studio's SECOND storefront — clay, glazes and tools, off
  // `/api/materials/*`. Built, tested and then held back: the two
  // routes below are commented out so nothing can reach it, rather
  // than deleted, because the work is finished and the wire is live.
  //
  // What is still in the tree and costs nothing while it sits there:
  // `MaterialApis`, the three `TerracottaEndpoints.material*` paths,
  // and `ProductSource`, which is what let one list and one detail
  // screen serve both storefronts.
  //
  // TO BRING IT BACK: uncomment these two, add them to
  // `terracottaPublicRoutes` below, and uncomment `_MaterialsCard` in
  // `shop_home_page.dart` — the card is the only way in, so a route
  // without it is a section nobody can find.
  //
  // /// الخامات والأدوات — the studio's SECOND storefront: clay, glazes
  // /// and tools.
  // ///
  // /// The shop's own browse screen, pointed at `/api/materials/*` — the
  // /// two answer the identical wire, so there is one list, one detail,
  // /// one filter sheet and one card between them. See [ProductSource].
  // ///
  // /// **It shares the shop's basket**, so there is no materials cart,
  // /// checkout or order history to route to. These two are the whole
  // /// surface.
  // ///
  // /// The storefront is in the PATH rather than in an extra: a source
  // /// carried in a `GoRouter` extra is gone the moment somebody follows
  // /// a link or the app hot-restarts, and `/shop/products/16` and
  // /// `/materials/products/16` are different products.
  // static final GoRoute materials = GoRoute(
  //   name: 'materials',
  //   path: '/materials',
  //   pageBuilder: (context, state) => _page(
  //     context,
  //     state,
  //     const ProductListPage(source: ProductSource.materials),
  //     style: const TransitionStyle(type: TransitionType.slideFromEnd),
  //   ),
  // );
  //
  // /// One material — same detail screen, same shape, parallel path.
  // static final GoRoute materialDetail = GoRoute(
  //   name: 'material-detail',
  //   path: '/materials/products/:productId',
  //   pageBuilder: (context, state) => _page(
  //     context,
  //     state,
  //     ProductDetailPage(
  //       productId: state.pathParameters['productId'] ?? '',
  //       source: ProductSource.materials,
  //       // What the tapped card already knew. Null on a deep link,
  //       // where the page has to fetch before it can show anything.
  //       preview: state.extraAs<ProductPreview>(),
  //     ),
  //     style: const TransitionStyle(type: TransitionType.slideFromEnd),
  //   ),
  // );

  /// الدفع — Booking summary, celebration toggle, wallet balance, discount code and confirm.
  static final GoRoute bookingCheckout = GoRoute(
    name: 'booking-checkout',
    path: '/checkout/booking',
    pageBuilder: (context, state) => _page(
      context,
      state,
      // Everything the schedule (and the catalogue step after it)
      // collected, so this screen asks for none of it again.
      BookingCheckoutPage(args: state.extraAs<BookingCheckoutArgs>()),
      style: const TransitionStyle(type: TransitionType.slideFromEnd),
    ),
  );

  /// الدفع — Cart summary, wallet, delivery address and place order.
  static final GoRoute shopCheckout = GoRoute(
    name: 'shop-checkout',
    path: '/checkout/shop',
    pageBuilder: (context, state) => _page(
      context,
      state,
      const ShopCheckoutPage(),
      style: const TransitionStyle(type: TransitionType.slideFromEnd),
    ),
  );

  /// الدفع — The delivery fee, charged only when delivery is chosen.
  static final GoRoute deliveryCheckout = GoRoute(
    name: 'delivery-checkout',
    path: '/checkout/delivery/:bookingId',
    pageBuilder: (context, state) => _page(
      context,
      state,
      DeliveryCheckoutPage(
        // The booking whose piece is being delivered — the quote and
        // the choose call are both scoped to it.
        bookingId: state.pathParameters['bookingId'],
        address: state.extraAs<Address>(),
      ),
      style: const TransitionStyle(type: TransitionType.slideFromEnd),
    ),
  );

  /// الدفع — Pay for a gift.
  static final GoRoute giftCheckout = GoRoute(
    name: 'gift-checkout',
    path: '/checkout/gift',
    pageBuilder: (context, state) => _page(
      context,
      state,
      // What the sheet collected. Null after a hot restart, where a
      // route extra does not survive.
      GiftCheckoutPage(draft: state.extraAs<GiftDraft>()),
      style: const TransitionStyle(type: TransitionType.slideFromEnd),
    ),
  );

  /// تم شراء الهدية! — Success, with the share link.
  static final GoRoute giftPurchased = GoRoute(
    name: 'gift-purchased',
    path: '/gifts/purchased',
    pageBuilder: (context, state) => _page(
      context,
      state,
      const GiftPurchasedPage(),
      // Nothing behind it to slide away — going back would buy again.
      style: const TransitionStyle(type: TransitionType.fade),
    ),
  );

  /// هدية لك — What a `terracotta://gift/{token}` link opens.
  ///
  /// PUBLIC, and it has to be: `GET /api/gifts/{token}` takes no
  /// session (verified live — an unknown token is a 404, not a 401),
  /// because whoever opens a share link usually has no account at all.
  /// The account is asked for at the Claim button, by which point they
  /// can see what they are signing in for.
  ///
  /// A FADE. Most arrivals here are the app launching from a tap on a
  /// link, with nothing behind it to slide away.
  static final GoRoute giftClaim = GoRoute(
    name: 'gift-claim',
    path: '/gift/:token',
    pageBuilder: (context, state) => _page(
      context,
      state,
      GiftClaimPage(token: state.pathParameters['token'] ?? ''),
      style: const TransitionStyle(type: TransitionType.fade),
    ),
  );

  /// حسابي — Account home.
  static final GoRoute profile = GoRoute(
    name: 'profile',
    path: '/profile',
    pageBuilder: (context, state) => _page(
      context,
      state,
      const ProfilePage(),
      style: const TransitionStyle(type: TransitionType.fade),
    ),
  );

  /// تغيير كلمة السر — Change the password from inside the account.
  static final GoRoute changePassword = GoRoute(
    name: 'change-password',
    path: '/profile/password',
    pageBuilder: (context, state) => _page(
      context,
      state,
      const ChangePasswordPage(),
      style: const TransitionStyle(type: TransitionType.slideFromEnd),
    ),
  );

  /// عناويني — Add, edit, delete and set a default.
  static final GoRoute addressBook = GoRoute(
    name: 'address-book',
    path: '/profile/addresses',
    pageBuilder: (context, state) => _page(
      context,
      state,
      const AddressBookPage(),
      style: const TransitionStyle(type: TransitionType.slideFromEnd),
    ),
  );

  /// محفظتي — Where the balance came from and what it was spent on.
  static final GoRoute wallet = GoRoute(
    name: 'wallet',
    path: '/profile/wallet',
    pageBuilder: (context, state) => _page(
      context,
      state,
      const WalletPage(),
      style: const TransitionStyle(type: TransitionType.slideFromEnd),
    ),
  );

  /// الاشعارات — Every push also writes an inbox row.
  static final GoRoute notifications = GoRoute(
    name: 'notifications',
    path: '/notifications',
    pageBuilder: (context, state) => _page(
      context,
      state,
      const NotificationsInboxPage(),
      style: const TransitionStyle(type: TransitionType.slideFromEnd),
    ),
  );

  /// طلباتي — Shop order history.
  static final GoRoute myOrders = GoRoute(
    name: 'my-orders',
    path: '/orders',
    pageBuilder: (context, state) => _page(
      context,
      state,
      const MyOrdersPage(),
      style: const TransitionStyle(type: TransitionType.slideFromEnd),
    ),
  );

  /// تم تأكيد طلبك ! — Success screen, between paying and the order.
  ///
  /// DECLARED BEFORE [orderDetail], and on a two-segment path.
  /// `/orders/:orderId` would happily match `/orders/confirmed` and
  /// try to load an order called "confirmed"; the id here is a segment
  /// of its own, which also means the screen survives a hot restart
  /// with the order it is about.
  static final GoRoute orderConfirmed = GoRoute(
    name: 'order-confirmed',
    path: '/orders/confirmed/:orderId',
    pageBuilder: (context, state) => _page(
      context,
      state,
      OrderConfirmedPage(orderId: state.pathParameters['orderId']),
      // Nothing behind it to slide away — going back would pay again.
      style: const TransitionStyle(type: TransitionType.fade),
    ),
  );

  /// تفاصيل الطلب — Line items, delivery address and status.
  static final GoRoute orderDetail = GoRoute(
    name: 'order-detail',
    path: '/orders/:orderId',
    pageBuilder: (context, state) => _page(
      context,
      state,
      // The path parameter is what the page ASKS for. It used to be
      // dropped, so the screen could not have loaded an order even
      // once it had something to draw.
      OrderDetailPage(orderId: state.pathParameters['orderId']),
      style: const TransitionStyle(type: TransitionType.slideFromEnd),
    ),
  );

  /// تواصل معنا — File a complaint, and everything already filed.
  ///
  /// NOT private. Filing is public — `POST /api/complaints` takes one
  /// from a signed-out visitor, who then has to say who they are —
  /// while `GET /api/complaints` is the caller's own list and the page
  /// simply does not draw that half without a session.
  static final GoRoute complaints = GoRoute(
    name: 'complaints',
    path: '/complaints',
    pageBuilder: (context, state) => _page(
      context,
      state,
      const ComplaintsPage(),
      style: const TransitionStyle(type: TransitionType.slideFromEnd),
    ),
  );

  /// The studio's own writing — terms, privacy, returns, shipping,
  /// about.
  ///
  /// PUBLIC, and addressed by SLUG. A visitor deciding whether to buy
  /// is exactly who reads the returns policy, and the endpoint behind
  /// it takes no session — `GET /api/pages` is one of the few that
  /// answers a guest.
  static final GoRoute staticPage = GoRoute(
    name: 'page',
    path: '/pages/:slug',
    pageBuilder: (context, state) => _page(
      context,
      state,
      StaticPageView(slug: state.pathParameters['slug'] ?? ''),
      style: const TransitionStyle(type: TransitionType.slideFromEnd),
    ),
  );

  /// قطعي — Everything the customer has made at the studio.
  ///
  /// PRIVATE: the pieces are the caller's own, and the workshop detail
  /// they are read from returns an empty list to anyone signed out.
  static final GoRoute myPieces = GoRoute(
    name: 'my-pieces',
    path: '/pieces',
    pageBuilder: (context, state) => _page(
      context,
      state,
      const MyPiecesPage(),
      style: const TransitionStyle(type: TransitionType.slideFromEnd),
    ),
  );

  static List<RouteBase> get systemRoutes => [
    settings,
    pushDiagnostics,
    notFound,
    comingSoon,
    error,
    about,
    legal,
    feedback,
  ];

  // ─── Terracotta ────────────────────────────────────────────

  /// Browsing is PUBLIC. A guest reads the shop, the gallery and the
  /// workshops without an account — `POST /api/guest` issues a
  /// device identity so they can even build a cart — and is asked to
  /// sign in only at the first action that needs one.
  static List<RouteBase> get terracottaPublicRoutes => [
    login,
    register,
    otpVerification,
    registerSuccess,
    forgotPassword,
    resetOtp,
    resetPassword,
    home,
    gallery,
    workshops,
    shop,
    productList,
    productDetail,
    // materials,        ← withdrawn, see the block above
    // materialDetail,
    // PUBLIC on purpose. The account tab is one of five in the nav bar,
    // and bouncing a visitor to the sign-in screen for tapping it reads
    // as the app being closed. The page opens with a guest header and
    // gates the rows that need a person — see `AuthGate`.
    profile,
    // Filing a complaint needs no account either — `POST /api/complaints`
    // takes one from a signed-out visitor. Only the HISTORY half of that
    // page needs a session, and it simply does not draw without one.
    complaints,
    // The studio's own writing. `GET /api/pages` takes no session, and
    // a visitor deciding whether to buy is exactly who reads the
    // returns policy.
    staticPage,
    // A GIFT SOMEBODY WAS SENT. The preview is public by design —
    // possession of the token is what grants access, and the
    // recipient is a stranger to this app until they claim it.
    giftClaim,
    // THE INBOX, and it is public on purpose.
    //
    // `GET /api/notifications` answers 401 for a guest — verified
    // live, and a registered guest gets the same — but the PAGE knows
    // that: it does not ask without a session, and draws a "sign in to
    // see your notifications" state instead. Listed as private, the
    // guard bounced a visitor to the sign-in SCREEN before that page
    // ever drew, so the bell and the account row both looked like
    // they went to the wrong place.
    notifications,
    // THE BOOKING FLOW UP TO THE SEAT.
    //
    // Probed live on 2026-09-08: `GET /workshops/{id}/availability` and
    // `GET /workshops/{id}/price` both answer a guest. Only the CREATE
    // step — `POST /workshops/{id}/bookings`, which reserves the seat —
    // needs an account.
    //
    // So a visitor picks their date, their seats and their pieces with
    // real prices from the server, and is asked to sign in at the one
    // moment it is actually required. Bouncing them at the first screen
    // asked for an account before they knew what it would cost.
    //
    // The two screens AFTER the seat stay private: «تم الحجز» and a
    // booking's own detail are records of something that belongs to
    // someone.
    bookingSchedule,
    pieceSelection,
    bookingCheckout,
    // «عناويني» is PUBLIC because a guest's book lives on the device.
    //
    // Every address route answers 401 without a session, and someone
    // filling in a delivery address is about to buy something — the
    // worst possible moment to send them to a sign-in screen and make
    // them type it all again afterwards. `GuestAddresses` holds it
    // until there is an account to put it in.
    addressBook,
  ];

  /// Everything tied to a person. A signed-out visitor hitting one of
  /// these is bounced to `login`.
  static List<RouteBase> get terracottaPrivateRoutes => [
    // The desk is staff-only and every one of its calls needs a
    // session — a guest reaching it would 401 on the first request,
    // which the app reads as the session ending.
    scannerDesk,
    bookingConfirmed,
    orderConfirmed,
    bookingDetail,
    shopCheckout,
    deliveryCheckout,
    giftCheckout,
    giftPurchased,
    changePassword,
    wallet,
    myOrders,
    orderDetail,
    myPieces,
  ];

  static List<RouteBase> get onboardingRoutes => [onboarding];
  static List<RouteBase> get routes => [
    splash,
    ...systemRoutes,
    ...onboardingRoutes,
    ...terracottaPublicRoutes,
    ...terracottaPrivateRoutes,
  ];

  static List<RouteBase> get publicRoutes => [
    splash,
    ...systemRoutes,
    ...onboardingRoutes,
    ...terracottaPublicRoutes,
  ];

  static List<RouteBase> get privateRoutes =>
      routes.where((route) => !publicRoutes.contains(route)).toList();
}
