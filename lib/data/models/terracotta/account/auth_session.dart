import 'package:freezed_annotation/freezed_annotation.dart';

import 'terracotta_user.dart';

part 'auth_session.freezed.dart';
part 'auth_session.g.dart';

/// What the server hands back when a session begins.
///
/// Returned by `POST /api/login`, `POST /api/register`,
/// `POST /api/verify-login`, `POST /api/firebase-login` and
/// `POST /api/guest` — all five answer with the same envelope, which is
/// why one model serves them.
///
/// **THE TOKEN IS OPTIONAL, and that is not a nicety.** `register`
/// answers in one of two shapes and the tenant chooses which:
///
///   * **logged in** (the default) — a bearer token, `is_verified:
///     true`, and nothing left to do;
///   * **OTP sent** (`REGISTER_REQUIRES_VERIFICATION=true`) — a user
///     with `verified_at: null`, an `otp_expires_in_minutes`, and **no
///     token at all**.
///
/// Declared `required String token` this threw inside `fromJson` on
/// the second shape — so a registration the server had ACCEPTED came
/// back to the customer as an error, and trying again answered «قيمة
/// حقل الهاتف مُستخدمة من قبل» because the account was already there.
/// Seen live 2026-09-17, when the tenant turned verification on.
///
/// The spec's own instruction is to "check `data.is_verified` / the
/// presence of `token` rather than assuming either shape" — which is
/// what [needsVerification] does.
///
/// [isScanner] separates front-desk staff from customers. The scanner
/// endpoints (`/api/scan/*`) are not part of this app, so a true here
/// means someone signed in with staff credentials on the customer
/// build — worth refusing rather than silently allowing.
@freezed
abstract class AuthSession with _$AuthSession {
  const factory AuthSession({
    /// The bearer token. Send as `Authorization: Bearer <token>`.
    ///
    /// NULL on a registration that owes an OTP — see the class doc.
    String? token,

    /// The signed-in principal.
    TerracottaUser? user,

    /// Server-side id of this token, so a session can be revoked by id
    /// through `DELETE /api/devices/{deviceId}`.
    int? tokenId,

    /// Whether the identifier has completed OTP verification.
    ///
    /// ABSENT on the OTP-sent shape, where the absence of [token] is
    /// what says so.
    bool? isVerified,

    /// How long the code just sent is good for. Present on both the
    /// unverified `login` and the OTP-sent `register`; null when
    /// nothing was sent.
    int? otpExpiresInMinutes,

    /// THE CODE ITSELF, when the server is feeling generous.
    ///
    /// Dev and staging hand it straight back rather than only sending
    /// it — `"otp": "123456"` on a live registration, 2026-09-17 — so
    /// a tester on a number that receives nothing can still get in.
    /// Production does not, and nothing may depend on it: read it
    /// through `DevOtp.show`, which simply says nothing when it is
    /// absent.
    String? otp,

    /// True for front-desk staff, not customers.
    bool? isScanner,
  }) = _AuthSession;

  const AuthSession._();

  factory AuthSession.fromJson(Map<String, dynamic> json) =>
      _$AuthSessionFromJson(json);

  /// A staff login on the customer app — refuse it.
  bool get isStaffLogin => isScanner ?? false;

  /// The account still owes an OTP before it is fully usable.
  ///
  /// Either half is enough: no token means the OTP-sent shape, and an
  /// explicit `is_verified: false` is the unverified `login`. An
  /// absent flag WITH a token is the default shape, which is done.
  bool get needsVerification => token == null || isVerified == false;

  /// Whether this session can actually authenticate a request.
  bool get hasToken => (token ?? '').isNotEmpty;
}
