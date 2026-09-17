import 'package:flutter/widgets.dart';

import '../../data/blocs/auth/auth_bloc.dart';
import '../../data/blocs/auth/auth_state.dart';
import '../../features/gift/data/pending_gift.dart';
import '../di/service_locator.dart';
import '../navigation/app_routes.dart';
import '../onboarding/onboarding_redirect.dart';
import 'splash_models.dart';

/// Where the splash hands off: onboarding gate → auth check → home,
/// falling back to sign-in.
///
/// This has to agree with where onboarding's own CTA sends a customer
/// (see `AppRoutes.onboarding`). If it did not, finishing the intro
/// would land on sign-in while the NEXT cold start took the same
/// customer somewhere else entirely.
Future<SplashDestination> defaultSplashNext(BuildContext context) async {
  // A GIFT LINK LAUNCHED THE APP.
  //
  // It is parked rather than routed because the router bounces the
  // first navigation of every session to this splash on purpose — so
  // the link had to survive the bounce, and this is the other side of
  // it. It wins over onboarding and over the sign-in gate alike: the
  // recipient tapped a specific thing, and the gift screen is public
  // (`GET /api/gifts/{token}` needs no account) so it can be shown to
  // anybody. Signing in is asked for at the Claim button, by which
  // point they can see what they are signing in FOR.
  //
  // Peeked, not taken — the screen it opens is what consumes it.
  if (PendingGift.token case final token?) {
    return SplashDestination(
      location: '/gift/$token',
      mode: SplashPushMode.go,
    );
  }

  if (OnboardingRedirect.shouldShow()) {
    return SplashDestination(
      location: AppRoutes.onboarding.path,
    );
  }
  if (getIt.isRegistered<AuthBloc>() && getIt<AuthBloc>().isAuthenticated) {
    // FRONT-DESK STAFF GO TO THE DESK, not the shop.
    //
    // A scanner account and a customer account are mutually exclusive
    // on the server: every customer route answers 403 for one, and
    // every desk route answers 403 for the other. Sending staff to
    // `/home` on a cold start therefore did not just look wrong — it
    // put them in an app where nothing they touched could work, and
    // gave them the run of screens their session has no business in.
    //
    // The flag is persisted with the token. `is_scanner` arrives only
    // on the sign-in response, so there is nothing to ask here.
    if (getIt<AuthBloc>().state case AuthAuthenticated(isScanner: true)) {
      return SplashDestination(
        location: AppRoutes.scannerDesk.path,
        mode: SplashPushMode.go,
      );
    }
    return SplashDestination(
      location: AppRoutes.home.path,
    );
  }
  return SplashDestination(
    location: AppRoutes.login.path,
  );
}
