import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../data/blocs/auth/auth_bloc.dart';
import '../../data/blocs/auth/auth_state.dart';
import '../../features/auth/data/verification_flow.dart';
import '../../shared/module/dialog/global_dialog.dart';
import '../localization/strings/auth_strings.dart';
import 'session_expiry.dart';

/// Whether there is an account behind this tap, and what to do if not.
///
/// **Browsing is the default and blocking is the exception.** A visitor
/// reads the shop, the gallery, the workshops and their own profile
/// page without an account; what they cannot do is the handful of
/// things that belong to a person — a cart the server keeps, a
/// favourite, a booking, a balance.
///
/// So the gate is at the BUTTON, not at the door. Bouncing someone off
/// a whole page teaches them the app is closed; refusing one row tells
/// them exactly which thing needs an account, with the rest of the page
/// still under their thumb.
///
/// Nothing here fires on a background load — see
/// [SessionExpiry.onUnauthorized] for why a 401 while a page is fetching
/// is a state and not an event.
class AuthGate {
  const AuthGate._();

  /// Whether the reader has a real account. A guest is NOT one: the
  /// server keys them to `X-Device-Id` and refuses the cart, favourites
  /// and the wallet all the same.
  static bool has(BuildContext context) =>
      context.read<AuthBloc>().state is AuthAuthenticated;

  /// Same, but rebuilds the caller when it changes.
  static bool watch(BuildContext context) =>
      context.watch<AuthBloc>().state is AuthAuthenticated;

  /// Whether the account's number has been confirmed by code.
  ///
  /// **An account is not a verified account.** Under
  /// `REGISTER_REQUIRES_VERIFICATION` the server hands out a session
  /// before the code is entered, so a customer can be signed in,
  /// browsing, with an account the server will refuse to let book or
  /// buy. Signed out reads as false: there is nothing verified about
  /// nobody.
  static bool isVerified(BuildContext context) =>
      _verified(context.read<AuthBloc>().state);

  /// Same, but rebuilds the caller when it changes — which is what the
  /// card on home and profile hangs off.
  static bool watchVerified(BuildContext context) =>
      _verified(context.watch<AuthBloc>().state);

  static bool _verified(AuthState state) => switch (state) {
    AuthAuthenticated(:final user) => user.phoneVerifiedAt != null,
    _ => false,
  };

  /// Whether there is a SIGNED-IN account still owing a code.
  ///
  /// The card's whole condition: a visitor has nothing to verify and a
  /// finished account has nothing to do.
  static bool watchNeedsVerification(BuildContext context) {
    final state = context.watch<AuthBloc>().state;
    return state is AuthAuthenticated && !_verified(state);
  }

  /// Run [action] if there is an account; otherwise ask for one.
  ///
  /// Returns whether it ran, so a caller with its own follow-up can
  /// stop rather than pretend the tap worked.
  static Future<bool> demand(
    BuildContext context, {
    VoidCallback? action,
  }) async {
    if (has(context)) {
      action?.call();
      return true;
    }
    await SessionExpiry.prompt(expired: false);
    return false;
  }

  /// Ask for an account at the END of something the reader has already
  /// filled in — and say that none of it is lost.
  ///
  /// [demand] is for a tap that has nowhere to go without a session: a
  /// bell, an order history, a wallet. This is for the other case, and
  /// it is a different conversation. A visitor who has picked a date,
  /// chosen their seats and reached the pay button is not asking to see
  /// a private screen — they are trying to buy something, and the only
  /// question they have at that moment is whether signing in throws
  /// away the ten minutes they just spent.
  ///
  /// So the copy answers that question first and asks second. Returns
  /// whether they signed in — a caller must not proceed on false.
  static Future<bool> demandToFinish(
    BuildContext context, {
    required String because,
  }) async {
    if (has(context)) return true;

    final go = await GlobalDialog.confirm(
      context: context,
      title: AuthStrings.needAccountTitle,
      message: because,
      confirmText: AuthStrings.needAccountConfirm,
      cancelText: AuthStrings.needAccountLater,
      icon: Icons.lock_open_rounded,
    );
    if (!go || !context.mounted) return false;

    // The sign-in screen, and back here afterwards — `from` is what
    // `AuthGuard` uses for the same trip, so a customer who signs in
    // lands where they were rather than on home.
    context.pushNamed('login');
    return false;
  }

  /// An account AND a confirmed number, or the way to get one.
  ///
  /// The second gate, and it is deliberately the same shape as the
  /// first: a dialog at the button that names what is missing, with
  /// the rest of the page still under the reader's thumb. Bouncing an
  /// unverified customer off the shop would teach them the app is
  /// closed; refusing the pay button tells them exactly which thing
  /// needs the code.
  ///
  /// [because] says what they were trying to do — see
  /// `AuthStrings.verifyNeededBook` and its neighbour.
  ///
  /// Returns whether the caller may proceed. It answers false on the
  /// way to the code screen as well as on a refusal: the action is not
  /// resumed afterwards, because by then the reader is three screens
  /// away and would not expect it to be.
  static Future<bool> demandVerified(
    BuildContext context, {
    required String because,
  }) async {
    // NO ACCOUNT AT ALL is the other conversation, and it comes first.
    if (!has(context)) {
      return demandToFinish(context, because: because);
    }
    if (isVerified(context)) return true;

    final go = await GlobalDialog.confirm(
      context: context,
      title: AuthStrings.verifyNeededTitle,
      message: because,
      confirmText: AuthStrings.verifyNeededConfirm,
      cancelText: AuthStrings.needAccountLater,
      icon: Icons.verified_outlined,
    );
    if (!go || !context.mounted) return false;

    await VerificationFlow.start(context);
    return false;
  }
}
