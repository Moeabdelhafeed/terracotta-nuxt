import 'package:dio/dio.dart';

import '../../../core/constants/enums/api/request_type.dart';
import '../../../core/types/result.dart';
import '../../models/terracotta/account/auth_session.dart';
import '../../models/terracotta/account/device_list.dart';
import '../../models/terracotta/account/social_account_list.dart';
import '../../models/terracotta/account/wallet_statement.dart';
import '../api_service.dart';
import '../endpoints/terracotta_endpoints.dart';

/// Profile API calls — social sign-in and account linking, profile
/// edits, identifier (email / phone) changes, the wallet ledger and
/// the device list.
///
/// Every method returns an `AsyncResult<...>` — pattern-match at the
/// call site; nothing here throws.
///
/// Group-wide notes:
/// - **Money is a decimal STRING** (`"65.00"`), never a number. The
///   wallet ledger's balances and amounts are strings — parse them as
///   decimals, never round-trip through `double`.
/// - **VAT is INCLUSIVE** everywhere it appears: `vat_amount` is
///   already contained in `total_price`, never added to it.
/// - `firebase-login` is rate-limited with `login` / `register`
///   (5 per minute); `request-identifier-change` sits on the OTP
///   limiter (3 per 5 minutes). Both surface as a 429.
/// - Validation errors come back **keyed by the input name** —
///   `errors.token` for any social failure, `errors.otp` for a bad
///   code — so they can be shown under the field that caused them.
/// - PUT and DELETE below are written as PUT and DELETE. The
///   method-override interceptor rewrites them to POST at send time;
///   never hand-write the override.
class ProfileApis {
  ProfileApis._();

  // ─── Per-endpoint log flags ───────────────────────────────

  static ApiLogConfig logFirebaseLogin = kApiLogVerbose;
  static ApiLogConfig logGetSocialAccounts = kApiLogVerbose;
  static ApiLogConfig logLinkSocialAccount = kApiLogVerbose;
  static ApiLogConfig logUnlinkSocialAccount = kApiLogVerbose;
  static ApiLogConfig logUpdateProfile = kApiLogVerbose;
  static ApiLogConfig logRequestIdentifierChange = kApiLogVerbose;
  static ApiLogConfig logVerifyIdentifierChange = kApiLogVerbose;
  static ApiLogConfig logGetWalletTransactions = kApiLogVerbose;
  static ApiLogConfig logGetDevices = kApiLogVerbose;
  static ApiLogConfig logRevokeDevice = kApiLogVerbose;

  // ─── Mock setup ───────────────────────────────────────────

  /// Register mock responses for the GET endpoints in this class.
  /// Call once at app init when [ApiService.useMock] is true.
  static void installMocks() {
    ApiService.registerMock(
      endpoint: TerracottaEndpoints.socialAccounts,
      type: RequestType.get,
      data: {
        'social_accounts': [
          {
            'id': 1,
            'provider': 'google.com',
            'email': 'jane@example.com',
            'name': 'Jane Doe',
          },
        ],
        'allowed_providers': ['google.com', 'apple.com'],
        'max_accounts': 0,
        'can_link_more': true,
      },
    );
    ApiService.registerMock(
      endpoint: TerracottaEndpoints.walletTransactions,
      type: RequestType.get,
      data: {
        'current_page': 1,
        'per_page': 20,
        'total': 2,
        'data': [
          {
            'id': 9,
            'type': 'credit',
            'amount': '150.00',
            'balance_after': '150.00',
            'reason': 'gift_redeemed',
            'created_at': '2026-07-19T09:00:00.000000Z',
          },
          {
            'id': 8,
            'type': 'debit',
            'amount': '65.00',
            'balance_after': '85.00',
            'reason': 'booking_paid',
            'created_at': '2026-07-18T09:00:00.000000Z',
          },
        ],
      },
    );
    ApiService.registerMock(
      endpoint: TerracottaEndpoints.devices,
      type: RequestType.get,
      data: {
        'devices': [
          {
            'id': 3,
            'device_name': null,
            'platform': 'ios',
            'ip': '10.0.0.1',
            'user_agent': 'Terracotta/1.0',
            'last_seen_at': '2026-07-19T09:00:00.000000Z',
            'created_at': '2026-07-10T08:00:00.000000Z',
            'is_current': true,
          },
          {
            'id': 2,
            'device_name': null,
            'platform': 'android',
            'ip': '10.0.0.2',
            'user_agent': 'Terracotta/1.0',
            'last_seen_at': '2026-07-15T09:00:00.000000Z',
            'created_at': '2026-07-01T08:00:00.000000Z',
            'is_current': false,
          },
        ],
      },
    );
  }

  // ─── API methods ──────────────────────────────────────────

  /// Trades a Firebase ID token for a Terracotta bearer token —
  /// PUBLIC, this is what runs before a session exists.
  ///
  /// The returned `data` carries `token`, the `user`, `is_new_user`
  /// and `linked_providers`. Any social failure comes back 422 under
  /// `errors.token`, whatever actually went wrong upstream.
  static AsyncResult<AuthSession> firebaseLogin({
    required String token,
    CancelToken? cancelToken,
    Duration? timeout,
  }) => ApiService.call(
    () => ApiService().post<AuthSession>(
      TerracottaEndpoints.firebaseLogin,
      data: {'token': token},
      fromJson: AuthSession.fromJson,
      logRequest: logFirebaseLogin.request,
      logResponse: logFirebaseLogin.response,
      cancelToken: cancelToken,
      timeout: timeout,
    ),
  );

  /// Lists the social providers linked to this account, plus
  /// `allowed_providers` / `can_link_more` — read it before offering
  /// a "link another account" button.
  static AsyncResult<SocialAccountList> getSocialAccounts({
    CancelToken? cancelToken,
    Duration? timeout,
  }) => ApiService.call(
    () => ApiService().get<SocialAccountList>(
      TerracottaEndpoints.socialAccounts,
      fromJson: SocialAccountList.fromJson,
      logRequest: logGetSocialAccounts.request,
      logResponse: logGetSocialAccounts.response,
      cancelToken: cancelToken,
      timeout: timeout,
    ),
  );

  /// Attaches another social provider to the signed-in account, using
  /// a fresh Firebase ID token for that provider.
  ///
  /// Already-linked providers come back under `errors.token`; check
  /// `can_link_more` from [getSocialAccounts] first.
  static AsyncResult<Map<String, dynamic>> linkSocialAccount({
    required String token,
    CancelToken? cancelToken,
    Duration? timeout,
  }) => ApiService.call(
    () => ApiService().post<Map<String, dynamic>>(
      TerracottaEndpoints.linkSocialAccount,
      data: {'token': token},
      fromJson: (json) => json,
      logRequest: logLinkSocialAccount.request,
      logResponse: logLinkSocialAccount.response,
      cancelToken: cancelToken,
      timeout: timeout,
    ),
  );

  /// Detaches a social provider (`google.com`, `apple.com`, …) from
  /// the signed-in account.
  ///
  /// **`provider` travels as a query parameter, not a JSON body.**
  /// `ApiService.delete` carries no body (`RequestType.delete.hasBody`
  /// is false), and the override interceptor sends this as
  /// `POST …/unlink-social-account?provider=…&_method=DELETE`, which
  /// Laravel reads identically to a body field.
  static AsyncResult<Map<String, dynamic>> unlinkSocialAccount({
    required String provider,
    CancelToken? cancelToken,
    Duration? timeout,
  }) => ApiService.call(
    () => ApiService().delete<Map<String, dynamic>>(
      TerracottaEndpoints.unlinkSocialAccount,
      queryParameters: {'provider': provider},
      fromJson: (json) => json,
      logRequest: logUnlinkSocialAccount.request,
      logResponse: logUnlinkSocialAccount.response,
      cancelToken: cancelToken,
      timeout: timeout,
    ),
  );

  /// Edits the profile — every field optional, nulls are not sent.
  ///
  /// **The login identifier cannot be changed here.** With
  /// `AUTH_IDENTIFIERS=phone`, `phone` is the identifier and is
  /// rejected by this endpoint; moving it goes through
  /// [requestIdentifierChange] + [verifyIdentifierChange]. `username`
  /// and `email` only exist when their `HAS_*_FIELD` flag is on.
  static AsyncResult<Map<String, dynamic>> updateProfile({
    String? name,
    String? username,
    String? email,
    String? phone,
    CancelToken? cancelToken,
    Duration? timeout,
  }) => ApiService.call(
    () => ApiService().put<Map<String, dynamic>>(
      TerracottaEndpoints.updateProfile,
      data: {
        if (name != null) 'name': name,
        if (username != null) 'username': username,
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
      },
      fromJson: (json) => json,
      logRequest: logUpdateProfile.request,
      logResponse: logUpdateProfile.response,
      cancelToken: cancelToken,
      timeout: timeout,
    ),
  );

  /// Starts moving the account to a new email or phone — sends an OTP
  /// to the NEW identifier and changes nothing yet.
  ///
  /// [type] is `email` or `phone` and is **never inferred from the
  /// value** — send it explicitly. A phone must carry its country
  /// code, digits only, no `+` (`966500000000`), and
  /// `ALLOWED_PHONE_COUNTRIES` may reject anything outside Saudi.
  /// Rate-limited to 3 per 5 minutes; the response's
  /// `otp_expires_in_minutes` drives the resend countdown.
  static AsyncResult<Map<String, dynamic>> requestIdentifierChange({
    required String newIdentifier,
    required String type,
    CancelToken? cancelToken,
    Duration? timeout,
  }) => ApiService.call(
    () => ApiService().post<Map<String, dynamic>>(
      TerracottaEndpoints.requestIdentifierChange,
      data: {
        'new_identifier': newIdentifier,
        'type': type,
      },
      fromJson: (json) => json,
      logRequest: logRequestIdentifierChange.request,
      logResponse: logRequestIdentifierChange.response,
      cancelToken: cancelToken,
      timeout: timeout,
    ),
  );

  /// Confirms the new identifier with the OTP it received — this is
  /// the call that actually moves the login identifier.
  ///
  /// Send the same [newIdentifier] and [type] that
  /// [requestIdentifierChange] was given. A wrong code comes back 422
  /// under `errors.otp`; verification sits on the loose 60/min limiter
  /// so a mistyped code does not lock the customer out.
  static AsyncResult<Map<String, dynamic>> verifyIdentifierChange({
    required String newIdentifier,
    required String type,
    required String otp,
    CancelToken? cancelToken,
    Duration? timeout,
  }) => ApiService.call(
    () => ApiService().post<Map<String, dynamic>>(
      TerracottaEndpoints.verifyIdentifierChange,
      data: {
        'new_identifier': newIdentifier,
        'type': type,
        'otp': otp,
      },
      fromJson: (json) => json,
      logRequest: logVerifyIdentifierChange.request,
      logResponse: logVerifyIdentifierChange.response,
      cancelToken: cancelToken,
      timeout: timeout,
    ),
  );

  /// The wallet ledger, newest first — credits from gift redemptions
  /// and cancellations, debits from bookings and orders.
  ///
  /// Amounts and balances are **decimal strings** (`"65.00"`); parse
  /// them as decimals, never as `double`.
  ///
  /// [perPage] is always sent and defaults to 20: without it the
  /// backend returns the whole ledger as a bare JSON array, and this
  /// call's single-object handler only accepts the paginator object.
  /// When paginated, the rows sit at `data.data`.
  static AsyncResult<WalletStatement> getWalletTransactions({
    int perPage = 20,
    int? page,
    CancelToken? cancelToken,
    Duration? timeout,
  }) => ApiService.call(
    () => ApiService().get<WalletStatement>(
      TerracottaEndpoints.walletTransactions,
      queryParameters: {
        'per_page': perPage,
        if (page != null) 'page': page,
      },
      fromJson: WalletStatement.fromJson,
      logRequest: logGetWalletTransactions.request,
      logResponse: logGetWalletTransactions.response,
      cancelToken: cancelToken,
      timeout: timeout,
    ),
  );

  /// Every device holding a live token for this account. The entry
  /// with `is_current: true` is the one making the call — the UI must
  /// not offer to revoke it like the others.
  static AsyncResult<DeviceList> getDevices({
    CancelToken? cancelToken,
    Duration? timeout,
  }) => ApiService.call(
    () => ApiService().get<DeviceList>(
      TerracottaEndpoints.devices,
      fromJson: DeviceList.fromJson,
      logRequest: logGetDevices.request,
      logResponse: logGetDevices.response,
      cancelToken: cancelToken,
      timeout: timeout,
    ),
  );

  /// Signs one device out by revoking its token.
  ///
  /// Revoking the current device (`is_current: true` in [getDevices])
  /// kills the caller's own session — treat that as a logout locally.
  /// The success envelope carries `data: null`.
  static AsyncResult<Map<String, dynamic>> revokeDevice(
    String deviceId, {
    CancelToken? cancelToken,
    Duration? timeout,
  }) => ApiService.call(
    () => ApiService().delete<Map<String, dynamic>>(
      TerracottaEndpoints.device(deviceId),
      fromJson: (json) => json,
      logRequest: logRevokeDevice.request,
      logResponse: logRevokeDevice.response,
      cancelToken: cancelToken,
      timeout: timeout,
    ),
  );
}
