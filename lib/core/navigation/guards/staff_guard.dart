import 'package:go_router/go_router.dart';

import '../../../data/blocs/auth/auth_bloc.dart';
import '../../../data/blocs/auth/auth_state.dart';
import '../../di/service_locator.dart';
import '../app_routes.dart';
import '../route_guard.dart';

/// Front-desk staff belong on the desk, and nowhere else.
///
/// ## Why a guard and not just the right landing screen
///
/// The splash sends a staff session to `/desk`, which fixes the common
/// path. It does not fix a deep link, a notification tap, a restored
/// route from a killed app, or `context.go` anywhere in the customer
/// tree — and a scanner account has no business in any of it. Its
/// routes are mutually exclusive with the customer's on the server:
/// every shop, cart, booking and wallet call answers **403** for a
/// scanner token.
///
/// So without this, staff reopening the app could walk the whole
/// customer app, watching every screen fail one request at a time.
///
/// ## It sends them to the desk, not to sign-in
///
/// They ARE signed in. The session is valid; it simply opens a
/// different app. Bouncing them to login would ask them to prove
/// something they have already proved.
class StaffGuard extends RouteGuard {
  const StaffGuard();

  /// Everything a customer can reach. The desk itself is the one place
  /// staff are allowed, so it is excluded rather than listed.
  @override
  List<String>? get appliesTo => null;

  @override
  List<String> get excludeFrom => [
    AppRoutes.scannerDesk.path,
    // The way OUT has to stay reachable, or signing out would bounce
    // back to the desk before it could clear the session.
    AppRoutes.login.path,
    AppRoutes.splash.path,
  ];

  @override
  String? canActivate(GoRouterState state) {
    if (!getIt.isRegistered<AuthBloc>()) return null;
    // Only a STAFF session is redirected. A customer, a guest and a
    // signed-out reader all carry on as they were — this guard knows
    // one thing and says nothing about the rest.
    if (getIt<AuthBloc>().state case AuthAuthenticated(isScanner: true)) {
      return AppRoutes.scannerDesk.path;
    }
    return null;
  }
}
