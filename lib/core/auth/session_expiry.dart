import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:go_router/go_router.dart';

import '../../data/blocs/auth/auth_bloc.dart';
import '../../data/blocs/auth/auth_event.dart';
import '../../shared/module/dialog/global_dialog.dart';
import '../di/service_locator.dart';
import '../localization/strings/auth_strings.dart';
import '../localization/strings/common_strings.dart';
import '../navigation/go_router_config.dart';
import '../utils/loggers/logger.dart';

/// What a 401 means on this API, and what to do about it.
///
/// The Terracotta API has NO refresh token. A 401 is not a transient
/// failure to paper over — it is the server saying the caller is not
/// signed in, in one of exactly two situations:
///
/// - **The token is dead.** The customer signed in once, the session
///   has since been revoked or expired, and the app has been sending a
///   token the server no longer knows. Nothing on screen says so,
///   because the profile renders the AppUser cached in local storage
///   and never asks. So the session has to be ended HERE, or every
///   auth-only screen fails one at a time forever.
/// - **They never signed in.** Browsing is public; the cart, bookings,
///   favourites, notifications and the wallet are not. A visitor
///   reaching one of those gets a 401 by design.
///
/// Both end at the same prompt, with different words: one says they
/// were signed out, the other that this needs an account.
class SessionExpiry {
  const SessionExpiry._();

  /// Paths whose 401 is the ANSWER, not a session problem.
  ///
  /// Signing in with the wrong password is a 422 on this server today,
  /// but an auth endpoint saying "not authenticated" is never news
  /// worth a dialog — and a sign-in prompt raised ON the sign-in page
  /// would be a loop.
  static const _authPaths = <String>[
    '/api/login',
    '/api/register',
    '/api/config',
    '/api/forgot-password',
    '/api/verify-forgot-password-otp',
    '/api/change-forgot-password',
    '/api/check-identifier',
    '/api/verify-login',
    '/api/guest',
    '/api/logout',
  ];

  /// One prompt at a time. The profile page alone fires the wallet and
  /// the cart within 300ms of each other, and three stacked dialogs
  /// saying the same thing is worse than the failure they describe.
  static bool _prompting = false;

  /// Test seam. The guard is a static, and a test that leaves the
  /// dialog standing would silence every test after it.
  @visibleForTesting
  static void debugReset() => _prompting = false;

  /// Wired to `ApiService.onTokenExpired` in bootstrap.
  ///
  /// **It does not ask anything.** A 401 is overwhelmingly a page
  /// LOADING something the reader never asked for — home alone fires
  /// the cart, the wallet and the inbox on arrival — and a dialog for
  /// each of those is a dialog nobody opened, on every screen, forever.
  /// The 401 is a fact about the SESSION; what the screen does about it
  /// is the screen's business, and screens render a guest state.
  ///
  /// What this does own is the one thing no screen can: a token the
  /// server has stopped accepting has to be dropped, or the app keeps
  /// showing a cached profile for a session that no longer exists.
  ///
  /// Always answers null: there is no token to replay with, so the
  /// original failure goes on to the caller.
  static Future<String?> onUnauthorized(RequestOptions request) async {
    final path = Uri.parse(request.path).path;
    if (_authPaths.any((p) => path.endsWith(p) || path == p)) return null;

    final auth = getIt.isRegistered<AuthBloc>() ? getIt<AuthBloc>() : null;
    if (auth?.isAuthenticated ?? false) {
      Logger.m.w('[Auth] 401 on $path — the stored token is dead, signing out');
      auth!.add(const AuthEvent.signedOut());
      // The guards only fire on navigation, and the customer is
      // standing on a private page RIGHT NOW — that is where the 401
      // came from. Without this they keep reading a cached profile
      // belonging to a session that no longer exists.
      GoRouterConfig.refreshGuards();
      // And THIS one is worth saying: they were signed in a moment ago
      // and are not any more, which is a fact about their account
      // rather than about the button they pressed.
      unawaited(prompt(expired: true));
    }
    return null;
  }

  /// The prompt itself.
  ///
  /// Raised at the GATE — the button that needs an account: adding to
  /// the cart, favouriting a piece, booking a workshop, opening the
  /// wallet. Never on a background load; see [onUnauthorized].
  static Future<void> prompt({required bool expired}) async {
    if (_prompting) return;
    _prompting = true;
    try {
      final signIn = await GlobalDialog.confirm(
        title: expired
            ? AuthStrings.sessionExpiredTitle
            : AuthStrings.signInRequiredTitle,
        message: expired
            ? AuthStrings.sessionExpiredMessage
            : AuthStrings.signInRequiredMessage,
        confirmText: AuthStrings.signIn,
        cancelText: CommonStrings.cancel,
      );
      if (!signIn) return;

      final context = GoRouterConfig.navigatorKey.currentContext;
      if (context == null || !context.mounted) return;
      // PUSH, not go: the page they were on is still the page they
      // wanted, and signing in lands them home on its own.
      context.pushNamed('login');
    } finally {
      _prompting = false;
    }
  }
}
