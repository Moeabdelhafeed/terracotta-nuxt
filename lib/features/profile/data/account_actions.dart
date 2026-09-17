import 'package:dio/dio.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/types/result.dart';
import '../../../data/api/calls/auth_apis.dart';
import '../../../data/api/calls/profile_apis.dart';
import '../../../data/blocs/auth/auth_bloc.dart';
import '../../../data/blocs/auth/auth_event.dart';
import '../../../data/blocs/auth/auth_state.dart';
import '../../../data/models/auth/user/user.dart';
import '../../cart/cubits/cart_cubit.dart';

/// A call that needs nothing but the session behind it.
typedef AccountCall =
    AsyncResult<Map<String, dynamic>> Function({
      CancelToken? cancelToken,
      Duration? timeout,
    });

/// Leaving the account — signing out of it, or ending it.
///
/// The parts that are easy to get wrong, in one place, the way
/// `AuthFlow` holds the ones for getting in:
///
///   * **Signing out clears the local token WHATEVER the server says.**
///     `POST /api/logout` revokes it server-side (verified live: the
///     token 401s straight after), but a customer on a dead connection
///     who taps sign out must not be left holding a session. The
///     request is best-effort; the local clear is not.
///   * **`AuthEvent.signedOut` is what actually clears it.** `AuthBloc`
///     wipes the token and the user from secure storage on that event —
///     calling the API without it logs the customer out of the server
///     and leaves the app signed in.
///   * **Deleting is the opposite way round.** It is permanent and has
///     no retention window, so the local session is cleared only once
///     the server has confirmed. Clearing first on a request that then
///     failed would sign someone out of an account that still exists.
class AccountActions {
  AccountActions._();

  /// The two calls, injectable so a test can answer without a server.
  /// `delete` is never exercised against the live API by anything but
  /// the app — it is permanent.
  static AccountCall logout = AuthApis.logout;
  static AccountCall delete = AuthApis.deleteAccount;

  /// `POST /api/update-profile` with a method override — the endpoint
  /// is a PUT and production drops the verb.
  static AsyncResult<Map<String, dynamic>> Function({
    String? name,
    CancelToken? cancelToken,
  })
  updateName = ({name, cancelToken}) =>
      ProfileApis.updateProfile(name: name, cancelToken: cancelToken);

  /// Sign out. Always succeeds locally.
  static Future<void> signOut(AuthBloc auth, {CancelToken? cancelToken}) async {
    // NOT FOR STAFF. `POST /api/logout` sits behind `role:user`, so a
    // front-desk token answers 403 every time — a guaranteed failed
    // request, logged as a rejection, on the way out of the app.
    //
    // The scanner group has no logout of its own (check-in, sessions,
    // start, finish and nothing else), so a staff token stays valid
    // server-side until it expires. Clearing it locally is the whole
    // of what this app can do, and it is what `signOut` does anyway —
    // the call below was always best-effort.
    final state = auth.state;
    final staff = state is AuthAuthenticated && state.isScanner;
    if (!staff) {
      // Best-effort, and its result is deliberately not read: see above.
      await logout(cancelToken: cancelToken);
    }
    auth.add(const AuthEvent.signedOut());

    // AND DROP WHAT WAS THEIRS.
    //
    // The cart is a `getIt` singleton that outlives every page, and it
    // only reloads when the LANGUAGE changes — so the badge in the bar
    // kept counting the last customer's basket until something opened
    // the sheet and forced a fetch. A count that is only right once you
    // tap it is worse than no count.
    if (getIt.isRegistered<CartCubit>()) getIt<CartCubit>().signedOut();
  }

  /// Rename the account.
  ///
  /// The NAME is the only profile field this tenant lets anyone edit —
  /// `phone` is the login identifier and this endpoint rejects it, and
  /// `username` / `email` exist only behind flags that are off. That is
  /// why there is no edit-profile PAGE: one field does not need one.
  ///
  /// The server echoes the whole updated user back under `data.user`,
  /// but `AuthBloc` holds the app's own `User` — so the name is written
  /// back into THAT rather than re-parsing a wire model the session
  /// does not store.
  static Future<AppException?> rename(
    AuthBloc auth,
    User current, {
    required String name,
    CancelToken? cancelToken,
  }) async {
    final result = await updateName(name: name, cancelToken: cancelToken);
    if (result case Failure(:final error)) return error;

    // ONE name field on the wire, split on the first space the same way
    // `toAppUser` does it — so a greeting still says the first word.
    final parts = name.trim().split(RegExp(r'\s+'));
    auth.add(
      AuthEvent.userUpdated(
        current.copyWith(
          firstName: parts.isEmpty || parts.first.isEmpty ? null : parts.first,
          lastName: parts.length > 1 ? parts.sublist(1).join(' ') : null,
        ),
      ),
    );
    return null;
  }

  /// End the account for good.
  ///
  /// Returns the failure when the server refused, so the caller can say
  /// what went wrong — the account is still there and the customer is
  /// still signed into it.
  static Future<AppException?> deleteAccount(
    AuthBloc auth, {
    CancelToken? cancelToken,
  }) async {
    final result = await delete(cancelToken: cancelToken);
    if (result case Failure(:final error)) return error;

    auth.add(const AuthEvent.signedOut());
    return null;
  }
}
