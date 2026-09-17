import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/strings/auth_strings.dart';
import '../../../core/types/result.dart';
import '../../../data/api/calls/auth_apis.dart';
import '../../../shared/module/toast/global_toast.dart';
import '../widgets/auth_failure.dart';
import 'dev_otp.dart';

/// Getting a SIGNED-IN account verified.
///
/// Registration under `REGISTER_REQUIRES_VERIFICATION` leaves the
/// customer inside the app with an account the server will not let
/// book or buy — so this is not a door to be stood in front of. They
/// browse; the two revenue actions ask; and this is what the asking
/// leads to.
///
/// `POST /api/send-otp` takes no body: the destination comes off the
/// session. So the only thing this needs is to be signed in, which is
/// exactly the state it exists for.
abstract final class VerificationFlow {
  /// Sends a fresh code and opens the code screen.
  ///
  /// The code is sent FIRST and the screen opened only if it went: an
  /// OTP page reached with nothing on its way is six empty boxes and a
  /// countdown to a resend of something that was never sent.
  ///
  /// Answers whether the screen opened.
  static Future<bool> start(BuildContext context) async {
    final sent = await AuthApis.sendOtp();
    if (!context.mounted) return false;

    switch (sent) {
      case Success(:final value):
        // The server hands the code back on dev and staging — see
        // [DevOtp]. Silent in production, which sends it and does not
        // repeat it.
        if (!DevOtp.showFrom(value)) {
          GlobalToast.success(AuthStrings.verifySent);
        }
        // NO `OtpPurpose`: this account is already signed in, so the
        // code screen verifies the SESSION rather than exchanging an
        // identifier for one.
        await context.pushNamed('otp-verification');
        return true;
      case Failure(:final error):
        // Rate limited at 3 per 5 minutes, which is the common failure
        // here and worth showing as the server words it.
        showAuthFailure(error);
        return false;
    }
  }
}
