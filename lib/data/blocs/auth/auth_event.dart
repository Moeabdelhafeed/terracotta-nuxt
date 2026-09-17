import 'package:freezed_annotation/freezed_annotation.dart';

import '../../models/auth/user/user.dart';

part 'auth_event.freezed.dart';

/// Events driving [AuthBloc] transitions.
@freezed
sealed class AuthEvent with _$AuthEvent {
  /// Load persisted credentials from [SecureCredentialStore]. Fired once on
  /// app boot; transitions from `unknown` → `authenticated` (if token
  /// + user present) or → `unauthenticated`.
  const factory AuthEvent.bootstrapped() = AuthBootstrapped;

  /// Successful login / register — persist credentials + transition
  /// to `authenticated`.
  const factory AuthEvent.signedIn({
    required User user,
    required String token,

    /// Whether this is a FRONT-DESK account — `is_scanner` on the
    /// sign-in response. Persisted with the token; see
    /// [AuthAuthenticated.isScanner].
    @Default(false) bool isScanner,

    /// Whether the session should survive the app being killed.
    ///
    /// True is the ordinary case and what every caller but the
    /// sign-in screen sends. FALSE means the reader unticked «أبقني
    /// مسجّل الدخول», and the token is then held in MEMORY only —
    /// `AuthBloc` does not write it to secure storage at all, rather
    /// than writing it and deleting it on the next launch. Somebody
    /// who asked the app not to keep their session should not have it
    /// written to disk even briefly.
    @Default(true) bool remember,
  }) = AuthSignedIn;

  /// Clear credentials → `unauthenticated`.
  const factory AuthEvent.signedOut() = AuthSignedOut;

  /// Mid-flow credential (OTP / password reset).
  const factory AuthEvent.pendingTokenSet(String token) = AuthPendingTokenSet;

  /// Drop pending credential.
  const factory AuthEvent.pendingTokenCleared() = AuthPendingTokenCleared;

  /// FCM registration-token refresh.
  const factory AuthEvent.fcmTokenChanged(String token) = AuthFcmTokenChanged;

  /// User profile updated without full re-auth (profile edit, avatar
  /// change, etc.).
  const factory AuthEvent.userUpdated(User user) = AuthUserUpdated;
}
