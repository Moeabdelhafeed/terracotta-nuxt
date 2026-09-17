import 'package:go_router/go_router.dart';

import '../../../data/blocs/auth/auth_bloc.dart';
import '../../../data/blocs/auth/auth_state.dart';
import '../../di/service_locator.dart';
import '../app_routes.dart';
import '../route_guard.dart';

/// Terracotta runs GUEST MODE.
///
/// A visitor browses the shop, the gallery and the workshops with no
/// account at all — `POST /api/guest` issues a device-scoped identity
/// so they can even build a cart — and is asked to sign in only at the
/// first action that needs a person behind it: booking, buying,
/// favouriting, or anything under the profile.
///
/// That is why this guard is written as a DENY-LIST of private routes
/// rather than an allow-list of public ones. A new browsing screen is
/// public by default, which is the safer failure: adding a screen and
/// forgetting to list it leaves it readable, not broken. A new screen
/// that touches the customer's own data has to be added to
/// [AppRoutes.terracottaPrivateRoutes], and the test in
/// `test/navigation/auth_guard_test.dart` fails if a route carrying an
/// obviously-personal path segment is missing from it.
class AuthGuard extends RouteGuard {
  const AuthGuard();

  @override
  List<String>? get appliesTo => _privatePaths;

  /// A PUBLIC route is never blocked, whatever a private child's glob
  /// happens to cover.
  ///
  /// The globs below are derived from parameterised paths, and
  /// `/workshops/:workshopId/schedule` becomes `/workshops/*` — which
  /// `RouteGuard._matchesPattern` matches against the bare prefix as
  /// well as its descendants. So the booking flow's private steps
  /// silently made the WORKSHOPS TAB private: a guest tapping it was
  /// redirected to sign-in by a guard that was only ever meant to
  /// cover what is underneath it.
  ///
  /// Listing the public routes here is the fix that cannot rot: a
  /// screen that is public says so in one place, and no glob written
  /// later can take it away.
  @override
  List<String> get excludeFrom => _publicPaths;

  static List<String> get _publicPaths => AppRoutes.terracottaPublicRoutes
      .whereType<GoRoute>()
      .map((r) => r.path)
      .toList(growable: false);

  static List<String> get _privatePaths => AppRoutes.terracottaPrivateRoutes
      .whereType<GoRoute>()
      .map((r) => r.path)
      // A parameterised path (`/bookings/:bookingId`) has to match every
      // concrete id, so guard the whole subtree.
      .map((p) => p.contains('/:') ? '${p.split('/:').first}/*' : p)
      .toList(growable: false);

  @override
  String? canActivate(GoRouterState state) {
    final auth = getIt<AuthBloc>().state;
    if (auth is AuthAuthenticated) return null;

    // Not signed in. Send them to sign-in and remember where they were
    // headed, so the flow can resume instead of dumping them on home.
    final from = Uri.encodeComponent(state.uri.toString());
    return '${AppRoutes.login.path}?from=$from';
  }
}
