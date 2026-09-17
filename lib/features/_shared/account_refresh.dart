import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/auth/auth_gate.dart';
import '../../core/types/result.dart';
import '../../data/api/calls/auth_apis.dart';
import '../../data/blocs/auth/auth_bloc.dart';
import '../../data/blocs/auth/auth_event.dart';
import '../auth/data/auth_flow.dart';

/// Re-read WHO THE READER IS, from any screen that is about them.
///
/// ## What it is for
///
/// The account record on screen otherwise comes from whatever was
/// stored at sign-in, and is only rewritten when this app itself
/// changes it. So a name edited on the web, a phone number verified at
/// the front desk, or a wallet credited by the studio never appeared
/// until the next sign-in — on a screen the customer had opened
/// specifically to check it.
///
/// `GET /api/user` is one small record and it carries all three.
///
/// ## Where it belongs
///
/// On the screens that are about the CUSTOMER — their profile, wallet,
/// orders, pieces, bookings, inbox — and on the pull-to-refresh of
/// each, because a pull on one of those is a person asking whether the
/// app is still right about them.
///
/// **Not on the browsing screens.** The shop, the gallery and the
/// workshops catalogue answer the same to everybody; asking who is
/// reading in order to draw a price list is a request for nothing.
///
/// ## How it fails
///
/// Silently, and on purpose. Nothing on any of those pages depends on
/// it: the stored record is what draws until a fresher one arrives, so
/// a failure leaves the screen exactly as it was rather than putting
/// an error over content that is probably still correct.
abstract final class AccountRefresh {
  const AccountRefresh._();

  /// Ask, and store the answer.
  ///
  /// A no-op without a session: `GET /api/user` resolves from the
  /// device headers too, so it ANSWERS for a guest — but a guest has
  /// no stored record to update, and a 401 anywhere in this app is
  /// read as the session ending.
  static Future<void> user(BuildContext context) async {
    if (!AuthGate.has(context)) return;

    final result = await AuthApis.getCurrentUser();
    if (!context.mounted) return;

    switch (result) {
      case Success(:final value):
        if (value.isGuest) return;
        context.read<AuthBloc>().add(
          AuthEvent.userUpdated(value.toAppUser()),
        );
      case Failure():
        break;
    }
  }
}
