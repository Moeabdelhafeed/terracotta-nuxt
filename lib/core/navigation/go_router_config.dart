import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Banner;
import 'package:go_router/go_router.dart';

import '../../shared/module/system_pages/not_found_page.dart';
import '../error/ui_watchdog.dart';
import '../utils/loggers/logger.dart';
import 'app_routes.dart';
import 'deep_link_handler.dart';
import 'guards/auth_guard.dart';
import 'guards/staff_guard.dart';
import 'navigation_tracker.dart';
import 'route_guard.dart';

// ---------------------------------------------------------------------------
// Navigation Observer
// ---------------------------------------------------------------------------

class NavigationObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    final newPath = _getRoutePath(route);
    final prevPath = _getRoutePath(previousRoute);
    if (newPath != null) {
      NavigationTracker().onPush(newPath, prevPath);
      UiWatchdog.breadcrumb = newPath;
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    final poppedPath = _getRoutePath(route);
    final revealedPath = _getRoutePath(previousRoute);
    if (poppedPath != null) {
      NavigationTracker().onPop(poppedPath, revealedPath);
      if (revealedPath != null) UiWatchdog.breadcrumb = revealedPath;
    }
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    // Treat remove like pop
    final removedPath = _getRoutePath(route);
    final revealedPath = _getRoutePath(previousRoute);
    if (removedPath != null) {
      NavigationTracker().onPop(removedPath, revealedPath);
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    final newPath = _getRoutePath(newRoute);
    final oldPath = _getRoutePath(oldRoute);
    if (newPath != null) {
      NavigationTracker().onReplace(newPath, oldPath);
    }
  }

  String? _getRoutePath(Route<dynamic>? route) {
    if (route == null) return null;
    if (route.settings is GoRouterState) {
      return (route.settings as GoRouterState).matchedLocation;
    }
    return route.settings.name;
  }
}

// ---------------------------------------------------------------------------
// GoRouter Configuration
// ---------------------------------------------------------------------------

class GoRouterConfig {
  const GoRouterConfig._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'go_router.navigatorKey');

  static final RouteObserver<ModalRoute> routeObserver =
      RouteObserver<ModalRoute>();

  static final NavigationObserver navigationObserver = NavigationObserver();

  // ─── Guards (middleware) ────────────────────────────────────

  /// Register your guards here. They run in order on every navigation.
  /// First guard to return a redirect wins.
  ///
  /// Example:
  /// ```dart
  /// static final guardRunner = GuardRunner([
  ///   const MaintenanceGuard(),
  ///   const AuthGuard(),
  ///   const RoleGuard(AppRole.admin, ['/admin/*']),
  /// ]);
  /// ```
  static final guardRunner = GuardRunner([
    // Terracotta runs guest mode: browsing is public, identity actions
    // are gated. See `guards/auth_guard.dart` for why this is a
    // deny-list rather than an allow-list.
    const AuthGuard(),
    // AND STAFF BELONG ON THE DESK. Runs after the auth guard, which
    // has already established there is a session — this one only says
    // which app that session opens. See [StaffGuard].
    const StaffGuard(),
  ]);

  // ─── Router ────────────────────────────────────────────────

  /// Set to `true` the first time the router's `redirect` callback
  /// fires. Lets us force the splash route on cold start regardless
  /// of where state-restoration / deep-link arrival would otherwise
  /// land, while still letting subsequent in-session navigations
  /// (splash → onboarding → home) flow naturally.
  static bool _firstRedirectSeen = false;

  /// The LIVE routing table.
  ///
  /// Built through `GoRouter.routingConfig` rather than the plain
  /// `GoRouter(routes: …)` constructor so the route set can be swapped on
  /// the EXISTING router instance: go_router listens to this notifier and
  /// reparses the current stack in place. That is what makes a
  /// newly-added route work on hot reload (see [debugRefreshRoutes]) —
  /// and it keeps every captured `GoRouterConfig.router` reference
  /// (NavigationService, notifications, deep links) valid, which
  /// recreating the router would not.
  static final ValueNotifier<RoutingConfig> _routingConfig =
      ValueNotifier<RoutingConfig>(_buildRoutingConfig(AppRoutes.routes));

  static RoutingConfig _buildRoutingConfig(List<RouteBase> routes) =>
      RoutingConfig(routes: routes, redirect: _redirect);

  /// Re-run every guard against the stack that is already on screen.
  ///
  /// The guards only fire on NAVIGATION, so a session that ends while
  /// the customer is standing on a private page — the profile, the
  /// wallet — leaves them standing there reading someone's cached
  /// name. Swapping in an equal-but-new `RoutingConfig` makes GoRouter
  /// reparse the current stack in place, which is the same mechanism
  /// [debugRefreshRoutes] uses.
  static void refreshGuards() =>
      _routingConfig.value = _buildRoutingConfig(AppRoutes.routes);

  /// Structural signature of the route table currently registered on
  /// [router]. Compared on hot reload to detect added/removed/renamed
  /// routes without rebuilding anything when nothing changed.
  static String _liveRoutesSignature = _routesSignature(AppRoutes.routes);

  static final GoRouter router = GoRouter.routingConfig(
    routingConfig: _routingConfig,
    initialLocation: AppRoutes.splash.path,
    navigatorKey: navigatorKey,
    // Native GoRouter `going to /x` / `pushing /x` logs are redundant
    // with NavigationObserver → NavigationTracker. Keep off; flip to
    // `kDebugMode` only when debugging GoRouter internals.
    debugLogDiagnostics: false,
    // Enables Flutter's state-restoration pipeline for this navigator.
    // Individual scrollable widgets still need their own `restorationId`
    // to actually restore scroll position on their side.
    restorationScopeId: 'app_router',
    observers: [
      routeObserver,
      navigationObserver,
    ],
    errorBuilder: (context, state) => NotFoundPage(
      path: state.matchedLocation,
    ),
  );

  static String? _redirect(BuildContext context, GoRouterState state) {
    // Force splash on the very first redirect call each app session.
    // Without this, GoRouter's state restoration (or a deep-link
    // arrival on a route guarded by splash logic) can land the user
    // directly on /onboarding / /home before the splash gate fires.
    // Splash itself never lands on splash again so this won't loop.
    if (!_firstRedirectSeen) {
      _firstRedirectSeen = true;
      if (state.matchedLocation != AppRoutes.splash.path) {
        return AppRoutes.splash.path;
      }
    }
    // Deep-link rewrites first — legacy URLs / short links / scheme
    // normalization. If a rewrite fires we redirect to the new path
    // and let GoRouter re-enter `redirect` with the rewritten URL.
    final incoming = Uri.tryParse(state.uri.toString());
    if (incoming != null) {
      final rewritten = DeepLinkHandler.resolve(incoming);
      if (rewritten != state.uri.toString() &&
          rewritten != state.matchedLocation) {
        return rewritten;
      }
    }
    // Then run guards.
    return guardRunner.redirect(state);
  }

  // ─── Hot reload ────────────────────────────────────────────

  /// Re-registers the route table when it changed, WITHOUT a full
  /// restart. Call from a root widget's `reassemble` (MyApp does).
  ///
  /// Why this is needed: `router` is a `static final`, and Dart does not
  /// re-run static initializers on hot reload — so the route LIST it was
  /// built from stays frozen even though `AppRoutes.routes` is a getter
  /// whose body hot reload does update. Existing routes still pick up
  /// edits (hot reload swaps closure bodies in place); only adding,
  /// removing or renaming one needed the restart. Re-reading the getter
  /// here and pushing the result into [_routingConfig] closes that gap:
  /// go_router reparses the CURRENT stack, so the page you are on stays
  /// put.
  ///
  /// No-op in profile/release (`kDebugMode` is a compile-time const, so
  /// the body is tree-shaken away).
  static void debugRefreshRoutes() {
    if (!kDebugMode) return;
    final next = AppRoutes.routes;
    final signature = _routesSignature(next);
    if (signature == _liveRoutesSignature) return;
    _liveRoutesSignature = signature;
    _routingConfig.value = _buildRoutingConfig(next);
    Logger.m.i(
      '[Nav] route table changed on hot reload — '
      '${_countRoutes(next)} routes re-registered',
    );
  }

  /// Structure-only fingerprint: path + name of every route, depth-first.
  /// Deliberately ignores builders — their bodies are hot-swapped in
  /// place and must NOT force a re-register.
  static String _routesSignature(List<RouteBase> routes) {
    final buffer = StringBuffer();
    void walk(List<RouteBase> list) {
      for (final route in list) {
        if (route is GoRoute) {
          buffer.write('g:${route.path}#${route.name ?? ''};');
        } else {
          buffer.write('${route.runtimeType};');
        }
        walk(route.routes);
      }
    }

    walk(routes);
    return buffer.toString();
  }

  static int _countRoutes(List<RouteBase> routes) {
    var total = 0;
    void walk(List<RouteBase> list) {
      for (final route in list) {
        total++;
        walk(route.routes);
      }
    }

    walk(routes);
    return total;
  }
}
