import 'package:freezed_annotation/freezed_annotation.dart';

import '../../models/auth/user/user.dart';

part 'auth_state.freezed.dart';

/// Authentication state — four lifecycle stages:
///
/// - [AuthState.unknown] — bootstrap; we haven't checked storage yet.
/// - [AuthState.unauthenticated] — no credentials. Baseline for logged-out.
/// - [AuthState.authenticated] — active session with token + user.
/// - [AuthState.pending] — mid-flow credential (OTP / password reset
///   confirmation). Carries a short-lived token that is **not**
///   persisted; dropped on app restart.
@freezed
sealed class AuthState with _$AuthState {
  const factory AuthState.unknown() = AuthUnknown;

  const factory AuthState.unauthenticated() = AuthUnauthenticated;

  const factory AuthState.authenticated({
    required User user,
    required String token,
    @Default('') String fcmToken,

    /// Whether this session belongs to FRONT-DESK STAFF.
    ///
    /// From `is_scanner` on the sign-in, and persisted with the token
    /// — it is not on `GET /api/user`, so a cold start has nowhere
    /// else to read it. Without it the app could not tell staff from a
    /// customer on reopening, and sent a scanner into the shop with a
    /// session that answers 403 to everything there.
    @Default(false) bool isScanner,
  }) = AuthAuthenticated;

  const factory AuthState.pending({required String temporaryToken}) =
      AuthPending;
}
