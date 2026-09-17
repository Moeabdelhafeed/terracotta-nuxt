import 'package:flutter/foundation.dart';

/// WHY the OTP screen is open.
///
/// It has two jobs and they call different endpoints:
///
///   * [OtpPurpose.registration] — the account was just created and
///     the session already exists, so `POST /api/verify-account`
///     identifies it by the bearer token and there is no identifier to
///     send;
///   * [OtpPurpose.signIn] — the tenant runs `auth_mode: otp`, so
///     `POST /api/login` sent a code and minted NOTHING. The session
///     comes from `POST /api/verify-login`, which pairs the code with
///     the identifier it was sent to.
///
/// Passed as the route's `extra`. Absent — a hot restart, a deep link —
/// it falls back to [registration], which is the flow the screen was
/// built for and the only one reachable when the config says
/// `password`.
@immutable
class OtpPurpose {
  /// Verifying an account that is already signed in.
  const OtpPurpose.registration() : identifier = null;

  /// Finishing an OTP-mode sign-in for [identifier].
  const OtpPurpose.signIn(String this.identifier);

  /// The credential the code was sent to, or null when the bearer
  /// token identifies the account instead.
  final String? identifier;

  /// Whether this is the sign-in half.
  bool get isSignIn => identifier != null;
}
