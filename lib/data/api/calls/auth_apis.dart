import 'package:dio/dio.dart';

import '../../../core/constants/enums/api/request_type.dart';
import '../../../core/types/result.dart';
import '../../models/terracotta/account/app_config.dart';
import '../../models/terracotta/account/auth_session.dart';
import '../../models/terracotta/account/terracotta_user.dart';
import '../api_service.dart';
import '../endpoints/terracotta_endpoints.dart';

/// Authentication API calls — capability config, sign-in, registration,
/// OTP, password reset, session teardown, guest sessions.
///
/// Every method returns an `AsyncResult<...>` — pattern-match at the call
/// site; nothing here throws.
///
/// Cross-cutting notes that hold for this whole group:
/// - **Identifiers are never inferred.** Every call that carries an
///   `identifier` also carries a `type` (`email` / `phone` /
///   `username`), and a phone MUST include its country code
///   (`966500000000`).
/// - **Errors come back field-keyed** under the same name as the input:
///   a wrong password lands on `password`, an unknown account on
///   `identifier`, a bad code on `otp`, a wrong current password on
///   `old_password`.
/// - **The four required headers** (`X-API-TOKEN`, `X-Device-Id`,
///   `X-Platform`, plus `X-FCM-Token` on mobile) are added by
///   `ApiService`'s Terracotta headers interceptor — never pass them
///   here.
/// - **OTP-sending calls are rate limited** to 3 per 5 minutes
///   (`forgotPassword`, `sendOtp`); `login` / `register` sit on 5 per
///   minute. Verification is deliberately on the loose 60/min limit.
class AuthApis {
  AuthApis._();

  // ─── Per-endpoint log flags ───────────────────────────────

  static ApiLogConfig logGetAuthConfig = kApiLogVerbose;
  static ApiLogConfig logLogin = kApiLogVerbose;
  static ApiLogConfig logVerifyLogin = kApiLogVerbose;
  static ApiLogConfig logRegister = kApiLogVerbose;
  static ApiLogConfig logCheckIdentifier = kApiLogVerbose;
  static ApiLogConfig logForgotPassword = kApiLogVerbose;
  static ApiLogConfig logVerifyForgotPasswordOtp = kApiLogVerbose;
  static ApiLogConfig logChangeForgotPassword = kApiLogVerbose;
  static ApiLogConfig logSendOtp = kApiLogVerbose;
  static ApiLogConfig logVerifyOtp = kApiLogVerbose;
  static ApiLogConfig logChangePassword = kApiLogVerbose;
  static ApiLogConfig logLogout = kApiLogVerbose;
  static ApiLogConfig logDeleteAccount = kApiLogVerbose;
  static ApiLogConfig logGetCurrentUser = kApiLogVerbose;
  static ApiLogConfig logCreateGuest = kApiLogVerbose;

  // ─── Mock setup ───────────────────────────────────────────

  /// Register mock responses for all endpoints in this class.
  /// Call once at app init when [ApiService.useMock] is true.
  static void installMocks() {
    ApiService.registerMock(
      endpoint: TerracottaEndpoints.config,
      type: RequestType.get,
      data: {
        'identifiers': ['phone'],
        'has_username_field': false,
        'has_email_field': false,
        'has_phone_field': false,
        'social_providers': ['google.com', 'apple.com'],
        'max_social_accounts': 0,
        'social_auth_available': true,
        'is_otp_whatsapp': false,
        'multi_session': true,
        'app_users': true,
        'app_guests': true,
        'auth_mode': 'password',
        'allowed_email_domains': 'all',
        'allowed_phone_countries': 'SA',
      },
    );
    ApiService.registerMock(
      endpoint: TerracottaEndpoints.user,
      type: RequestType.get,
      data: {
        'id': 42,
        'name': 'Jane Doe',
        'email': 'jane@example.com',
        'is_guest': false,
      },
    );
  }

  // ─── API methods ──────────────────────────────────────────

  /// Auth capability flags — which identifiers are accepted, which
  /// social providers are on, whether `auth_mode` is `password` or
  /// `otp`. Read this BEFORE drawing any auth screen: under `otp` the
  /// register + password endpoints are not there at all.
  static AsyncResult<AppConfig> getAuthConfig({
    CancelToken? cancelToken,
    Duration? timeout,
  }) => ApiService.call(
    () => ApiService().get<AppConfig>(
      TerracottaEndpoints.config,
      fromJson: AppConfig.fromJson,
      logRequest: logGetAuthConfig.request,
      logResponse: logGetAuthConfig.response,
      cancelToken: cancelToken,
      timeout: timeout,
    ),
  );

  /// Password sign-in — also the scanner-staff login, which lands on the
  /// same endpoint with a `scanner` role.
  ///
  /// TRAP: under `auth_mode: otp` this returns NO token — it only sends
  /// the code, and [verifyLogin] is what mints the session. Always look
  /// for `data.token` before assuming you are signed in.
  ///
  /// A phone [identifier] MUST carry its country code
  /// (`966500000000`), and [type] names which kind it is — the server
  /// never infers it from the value. A wrong password errors under
  /// `password`, an unknown account under `identifier`.
  static AsyncResult<AuthSession> login({
    required String identifier,
    required String type,
    required String password,
    bool? rememberMe,
    CancelToken? cancelToken,
    Duration? timeout,
  }) => ApiService.call(
    () => ApiService().post<AuthSession>(
      TerracottaEndpoints.login,
      data: {
        'identifier': identifier,
        'type': type,
        'password': password,
        if (rememberMe != null) 'remember_me': rememberMe,
      },
      fromJson: AuthSession.fromJson,
      logRequest: logLogin.request,
      logResponse: logLogin.response,
      cancelToken: cancelToken,
      timeout: timeout,
    ),
  );

  /// Exchange a login OTP for a bearer token — the second half of
  /// OTP-mode sign-in.
  ///
  /// [identifier] and [type] must be exactly what was passed to
  /// [login]. A wrong code errors under `otp`. The response carries
  /// `data.token`, `data.is_verified` and `data.account_restored` (true
  /// when a soft-deleted account came back).
  static AsyncResult<AuthSession> verifyLogin({
    required String identifier,
    required String type,
    required String otp,
    CancelToken? cancelToken,
    Duration? timeout,
  }) => ApiService.call(
    () => ApiService().post<AuthSession>(
      TerracottaEndpoints.verifyLogin,
      data: {
        'identifier': identifier,
        'type': type,
        'otp': otp,
      },
      fromJson: AuthSession.fromJson,
      logRequest: logVerifyLogin.request,
      logResponse: logVerifyLogin.response,
      cancelToken: cancelToken,
      timeout: timeout,
    ),
  );

  /// Create an account.
  ///
  /// TRAP: this RETURNS A TOKEN and signs the user in already — do not
  /// call [login] afterwards, and do not send them to an OTP screen for
  /// it.
  ///
  /// Registering on a device that already has a guest session PROMOTES
  /// that guest in place (same user id), so a cart or favourites built
  /// as a guest survive. [policyAgreed] must be `true`, [password] is
  /// 8 characters minimum and [passwordConfirmation] must match it.
  ///
  /// [username], [email] and [phone] are only accepted when the
  /// matching `has_*_field` flag from [getAuthConfig] is on and the
  /// field is not itself the login identifier.
  static AsyncResult<AuthSession> register({
    required bool policyAgreed,
    required String name,
    required String identifier,
    required String type,
    required String password,
    required String passwordConfirmation,
    String? username,
    String? email,
    String? phone,
    CancelToken? cancelToken,
    Duration? timeout,
  }) => ApiService.call(
    () => ApiService().post<AuthSession>(
      TerracottaEndpoints.register,
      data: {
        'policy_agreed': policyAgreed,
        'name': name,
        'identifier': identifier,
        'type': type,
        'password': password,
        'password_confirmation': passwordConfirmation,
        if (username != null) 'username': username,
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
      },
      fromJson: AuthSession.fromJson,
      logRequest: logRegister.request,
      logResponse: logRegister.response,
      cancelToken: cancelToken,
      timeout: timeout,
    ),
  );

  /// Ask whether an email / phone / username already has an account and
  /// how it can sign in — used to branch the auth screen between
  /// sign-in and sign-up without burning a login attempt.
  static AsyncResult<Map<String, dynamic>> checkIdentifier({
    required String identifier,
    required String type,
    CancelToken? cancelToken,
    Duration? timeout,
  }) => ApiService.call(
    () => ApiService().post<Map<String, dynamic>>(
      TerracottaEndpoints.checkIdentifier,
      data: {
        'identifier': identifier,
        'type': type,
      },
      fromJson: (json) => json,
      logRequest: logCheckIdentifier.request,
      logResponse: logCheckIdentifier.response,
      cancelToken: cancelToken,
      timeout: timeout,
    ),
  );

  /// Start a password reset — sends an OTP and returns
  /// `otp_expires_in_minutes` to drive the resend countdown.
  ///
  /// [channel] (`email` or `phone`) picks where the code goes and must
  /// be one of the account's populated channels. Rate limited to 3 per
  /// 5 minutes; a 429 here is the limiter, not a broken endpoint.
  static AsyncResult<Map<String, dynamic>> forgotPassword({
    required String identifier,
    required String type,
    String? channel,
    CancelToken? cancelToken,
    Duration? timeout,
  }) => ApiService.call(
    () => ApiService().post<Map<String, dynamic>>(
      TerracottaEndpoints.forgotPassword,
      data: {
        'identifier': identifier,
        'type': type,
        if (channel != null) 'channel': channel,
      },
      fromJson: (json) => json,
      logRequest: logForgotPassword.request,
      logResponse: logForgotPassword.response,
      cancelToken: cancelToken,
      timeout: timeout,
    ),
  );

  /// Check a reset OTP WITHOUT consuming it — lets the code screen
  /// validate before showing the new-password fields.
  ///
  /// The same [otp] must be sent again to [changeForgotPassword]; this
  /// call does not reset anything on its own. A wrong code errors under
  /// `otp`.
  static AsyncResult<Map<String, dynamic>> verifyForgotPasswordOtp({
    required String identifier,
    required String type,
    required String otp,
    CancelToken? cancelToken,
    Duration? timeout,
  }) => ApiService.call(
    () => ApiService().post<Map<String, dynamic>>(
      TerracottaEndpoints.verifyForgotPasswordOtp,
      data: {
        'identifier': identifier,
        'type': type,
        'otp': otp,
      },
      fromJson: (json) => json,
      logRequest: logVerifyForgotPasswordOtp.request,
      logResponse: logVerifyForgotPasswordOtp.response,
      cancelToken: cancelToken,
      timeout: timeout,
    ),
  );

  /// Set a new password using a verified reset OTP — the step that
  /// actually consumes the code.
  ///
  /// [password] is 8 characters minimum and [passwordConfirmation] must
  /// match it. Returns `data: null` on success; it does NOT sign the
  /// user in, so follow with [login].
  static AsyncResult<Map<String, dynamic>> changeForgotPassword({
    required String identifier,
    required String type,
    required String otp,
    required String password,
    required String passwordConfirmation,
    CancelToken? cancelToken,
    Duration? timeout,
  }) => ApiService.call(
    () => ApiService().post<Map<String, dynamic>>(
      TerracottaEndpoints.changeForgotPassword,
      data: {
        'identifier': identifier,
        'type': type,
        'otp': otp,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
      fromJson: (json) => json,
      logRequest: logChangeForgotPassword.request,
      logResponse: logChangeForgotPassword.response,
      cancelToken: cancelToken,
      timeout: timeout,
    ),
  );

  /// Resend the account-verification OTP to the signed-in user — the
  /// destination comes from the session, so there is no body.
  ///
  /// Rate limited to 3 per 5 minutes. Returns the user plus
  /// `otp_expires_in_minutes` for the resend countdown.
  static AsyncResult<Map<String, dynamic>> sendOtp({
    CancelToken? cancelToken,
    Duration? timeout,
  }) => ApiService.call(
    () => ApiService().post<Map<String, dynamic>>(
      TerracottaEndpoints.sendOtp,
      fromJson: (json) => json,
      logRequest: logSendOtp.request,
      logResponse: logSendOtp.response,
      cancelToken: cancelToken,
      timeout: timeout,
    ),
  );

  /// Verify the signed-in user's account with the OTP from [sendOtp].
  ///
  /// Success stamps `data.user.verified_at`. A wrong code errors under
  /// `otp` — verification sits on the loose 60/min limit so a mistyped
  /// code can't lock the account out.
  static AsyncResult<Map<String, dynamic>> verifyOtp({
    required String otp,
    CancelToken? cancelToken,
    Duration? timeout,
  }) => ApiService.call(
    () => ApiService().post<Map<String, dynamic>>(
      TerracottaEndpoints.verifyOtp,
      data: {'otp': otp},
      fromJson: (json) => json,
      logRequest: logVerifyOtp.request,
      logResponse: logVerifyOtp.response,
      cancelToken: cancelToken,
      timeout: timeout,
    ),
  );

  /// Change the signed-in user's password.
  ///
  /// [oldPassword] is required EXCEPT on an account that has no
  /// password yet — a social-only account setting its first one — which
  /// is why it is optional here. A wrong current password errors under
  /// `old_password`, not `password`.
  static AsyncResult<Map<String, dynamic>> changePassword({
    required String password,
    required String passwordConfirmation,
    String? oldPassword,
    CancelToken? cancelToken,
    Duration? timeout,
  }) => ApiService.call(
    () => ApiService().post<Map<String, dynamic>>(
      TerracottaEndpoints.changePassword,
      data: {
        if (oldPassword != null) 'old_password': oldPassword,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
      fromJson: (json) => json,
      logRequest: logChangePassword.request,
      logResponse: logChangePassword.response,
      cancelToken: cancelToken,
      timeout: timeout,
    ),
  );

  /// Revoke the current session's token. Clear the locally stored token
  /// regardless of the outcome — a failed logout still leaves the app
  /// holding a token the user asked to be rid of.
  static AsyncResult<Map<String, dynamic>> logout({
    CancelToken? cancelToken,
    Duration? timeout,
  }) => ApiService.call(
    () => ApiService().post<Map<String, dynamic>>(
      TerracottaEndpoints.logout,
      fromJson: (json) => json,
      logRequest: logLogout.request,
      logResponse: logLogout.response,
      cancelToken: cancelToken,
      timeout: timeout,
    ),
  );

  /// Permanently delete the calling account — immediate, no undo, no
  /// retention window. Gate it behind an explicit confirmation.
  ///
  /// Written as a real DELETE: the method-override interceptor rewrites
  /// it to `POST` + `X-HTTP-Method-Override` at send time, because the
  /// production host drops the verb. Never hand-write the override.
  static AsyncResult<Map<String, dynamic>> deleteAccount({
    CancelToken? cancelToken,
    Duration? timeout,
  }) => ApiService.call(
    () => ApiService().delete<Map<String, dynamic>>(
      TerracottaEndpoints.deleteAccount,
      fromJson: (json) => json,
      logRequest: logDeleteAccount.request,
      logResponse: logDeleteAccount.response,
      cancelToken: cancelToken,
      timeout: timeout,
    ),
  );

  /// The caller's own user record.
  ///
  /// Resolves from EITHER the bearer token or the device headers, so it
  /// answers for a guest too — read `is_guest` rather than assuming a
  /// 200 means a registered account.
  static AsyncResult<TerracottaUser> getCurrentUser({
    CancelToken? cancelToken,
    Duration? timeout,
  }) => ApiService.call(
    () => ApiService().get<TerracottaUser>(
      TerracottaEndpoints.user,
      fromJson: TerracottaUser.fromJson,
      logRequest: logGetCurrentUser.request,
      logResponse: logGetCurrentUser.response,
      cancelToken: cancelToken,
      timeout: timeout,
    ),
  );

  /// Mint an anonymous guest, keyed to the `X-Device-Id` header the
  /// interceptor already sends — hence no body.
  ///
  /// **It returns NO TOKEN.** Probed live on dev, 2026-09-05: the
  /// answer is `{"data": {"user": {... "is_guest": true, "guest_id":
  /// "<the X-Device-Id you sent>"}}}` and nothing else. A guest is a
  /// DEVICE, not a session — which is why this returns the user and why
  /// nothing needs storing: the header that identifies them goes on
  /// every request already. Parsed as `AuthSession` it threw, because
  /// `token` is required there.
  ///
  /// **And a guest can browse, nothing more.** The docs say a guest can
  /// build a cart; the live server answers 401 `You need to sign in to
  /// do that.` on `/api/shop/cart`, `/api/shop/favorites` and
  /// `/api/wallet/*` for one. `GET /api/user` is the only auth-shaped
  /// route that resolves them. See `docs/api-contract.md` §17.
  ///
  /// Registering later on the SAME device promotes this guest in place,
  /// keeping the id and anything built under it.
  static AsyncResult<TerracottaUser> createGuest({
    CancelToken? cancelToken,
    Duration? timeout,
  }) => ApiService.call(
    () => ApiService().post<TerracottaUser>(
      TerracottaEndpoints.guest,
      fromJson: (json) => TerracottaUser.fromJson(
        // The user is nested one level down here and flat on
        // `GET /api/user`. One model, two envelopes.
        (json['user'] as Map<String, dynamic>?) ?? json,
      ),
      logRequest: logCreateGuest.request,
      logResponse: logCreateGuest.response,
      cancelToken: cancelToken,
      timeout: timeout,
    ),
  );
}
