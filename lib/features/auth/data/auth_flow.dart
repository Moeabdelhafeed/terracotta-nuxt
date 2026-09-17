import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/types/result.dart';
import '../../../data/api/calls/auth_apis.dart';
import '../../../data/blocs/auth/auth_bloc.dart';
import '../../../data/blocs/auth/auth_event.dart';
import '../../../data/blocs/auth/auth_state.dart';
import '../../../data/models/auth/user/user.dart';
import '../../../data/models/terracotta/account/app_config.dart';
import '../../../data/models/terracotta/account/auth_session.dart';
import '../../../data/models/terracotta/account/terracotta_user.dart';
import '../../../data/services/app_config_service.dart';
import '../../../shared/common/text_form_fields/domain/phone_number_field.dart';

/// What the auth screens call, and what happens to a session the server
/// hands back.
///
/// The screens own their forms; this owns the parts that are easy to get
/// subtly wrong and that more than one of them needs — the wire shape of
/// an identifier, the fact that `register` has already signed the
/// customer in, and making the new token readable before the next
/// request goes out.
abstract final class AuthFlow {
  /// The identifier KIND, which the server never infers from the value.
  ///
  /// Omitting it is a 422 under `type` on every attempt, and it is in
  /// neither supplied document.
  ///
  /// **Read from `GET /api/config` now**, with `phone` as the fallback
  /// for a config that has not arrived — which is what this was
  /// hardcoded to, and what the live server reports.
  ///
  /// The app can only RENDER a phone number: the design draws one
  /// field and it is a country-code picker beside a numeric keyboard.
  /// So `phone` is preferred whenever the server offers it, and
  /// [supportsIdentifier] is what says whether signing in is possible
  /// at all — a tenant that turned phone off and email on would be
  /// asking for a screen this build does not have.
  static String get identifierType {
    final kinds = _config?.identifierKinds ?? const <AuthIdentifier>[];
    if (kinds.isEmpty || kinds.contains(AuthIdentifier.phone)) {
      return AuthIdentifier.phone.wire;
    }
    // Not renderable, but honest: the server is told which kind this
    // value claims to be, and refuses it for the right reason.
    return kinds.first.wire;
  }

  /// Whether this build can draw a field for what the server accepts.
  ///
  /// False only when the tenant has turned phone off. The auth screens
  /// say so rather than offering a form whose every submission is a
  /// 422 under `type`.
  static bool get supportsIdentifier {
    final kinds = _config?.identifierKinds ?? const <AuthIdentifier>[];
    return kinds.isEmpty || kinds.contains(AuthIdentifier.phone);
  }

  /// How this tenant authenticates — `password` or `otp`.
  ///
  /// Under `otp` there is no password anywhere: `POST /api/login`
  /// takes the identifier alone, answers with NO token, and sends a
  /// code that [verifySignIn] exchanges for the session. The sign-in
  /// screen hides its password box on that mode rather than asking for
  /// something the server will not read.
  ///
  /// Falls back to [AuthMode.password] when the config has not
  /// arrived, which is the form that always works.
  static AuthMode get mode => _config?.mode ?? AuthMode.password;

  /// Whether the code is delivered by WhatsApp rather than SMS — for
  /// the sentence on the OTP screen, which should name the app the
  /// customer is about to go and look in.
  static bool get otpOverWhatsApp => _config?.isOtpWhatsapp ?? false;

  static AppConfig? get _config => getIt.isRegistered<AppConfigService>()
      ? getIt<AppConfigService>().config
      : null;

  /// A phone number as the API wants it: country code and national
  /// digits, NO leading `+` (`962791234567`).
  static String wireIdentifier(PhoneNumber number) =>
      number.e164.replaceFirst('+', '');

  // ─── Sign in ──────────────────────────────────────────────

  static AsyncResult<AuthSession> signIn({
    required String identifier,
    required String password,
    CancelToken? cancelToken,
  }) => AuthApis.login(
    identifier: identifier,
    type: identifierType,
    password: password,
    cancelToken: cancelToken,
  );

  /// Create an account.
  ///
  /// This RETURNS A TOKEN and signs the customer in already — the
  /// supplied screen mapping says to call `login` afterwards, which
  /// would spend one of the five-per-minute auth attempts for nothing.
  /// Hand the session straight to [land].
  static AsyncResult<AuthSession> createAccount({
    required String name,
    required String identifier,
    required String password,
    required String passwordConfirmation,
    CancelToken? cancelToken,
  }) => AuthApis.register(
    policyAgreed: true,
    name: name,
    identifier: identifier,
    type: identifierType,
    password: password,
    passwordConfirmation: passwordConfirmation,
    cancelToken: cancelToken,
  );

  /// Exchange a sign-in code for the session — the second half of
  /// OTP-mode sign-in.
  ///
  /// [identifier] must be exactly what [signIn] was given, because the
  /// server pairs the code with it.
  static AsyncResult<AuthSession> verifySignIn({
    required String identifier,
    required String otp,
    CancelToken? cancelToken,
  }) => AuthApis.verifyLogin(
    identifier: identifier,
    type: identifierType,
    otp: otp,
    cancelToken: cancelToken,
  );

  // ─── Verifying the account you just made ──────────────────

  /// Send the account-verification code again.
  ///
  /// Named `resend` on the server too, because registering already
  /// sends one — which is why the code screen does not fire this on
  /// arrival. It sits on the 3-per-5-minutes OTP limiter, so an
  /// automatic send on every visit would spend the customer's own
  /// retries before they had typed anything.
  static AsyncResult<Map<String, dynamic>> resendAccountCode({
    CancelToken? cancelToken,
  }) => AuthApis.sendOtp(cancelToken: cancelToken);

  /// Verify the signed-in account. Needs the session token, so it must
  /// follow a [land].
  static AsyncResult<Map<String, dynamic>> verifyAccount({
    required String otp,
    CancelToken? cancelToken,
  }) => AuthApis.verifyOtp(otp: otp, cancelToken: cancelToken);

  // ─── Resetting a forgotten password ───────────────────────

  static AsyncResult<Map<String, dynamic>> requestReset({
    required String identifier,
    CancelToken? cancelToken,
  }) => AuthApis.forgotPassword(
    identifier: identifier,
    type: identifierType,
    channel: identifierType,
    cancelToken: cancelToken,
  );

  /// Check the code WITHOUT consuming it, so the code screen can refuse
  /// a wrong one before showing the new-password fields. The same code
  /// must be sent again to [setNewPassword].
  static AsyncResult<Map<String, dynamic>> checkResetCode({
    required String identifier,
    required String otp,
    CancelToken? cancelToken,
  }) => AuthApis.verifyForgotPasswordOtp(
    identifier: identifier,
    type: identifierType,
    otp: otp,
    cancelToken: cancelToken,
  );

  /// Consume the code and set the password. Does NOT sign the customer
  /// in — follow it with [signIn] using the password they just chose.
  static AsyncResult<Map<String, dynamic>> setNewPassword({
    required String identifier,
    required String otp,
    required String password,
    required String passwordConfirmation,
    CancelToken? cancelToken,
  }) => AuthApis.changeForgotPassword(
    identifier: identifier,
    type: identifierType,
    otp: otp,
    password: password,
    passwordConfirmation: passwordConfirmation,
    cancelToken: cancelToken,
  );

  // ─── Landing a session ────────────────────────────────────

  /// Persist a freshly minted session and wait until the token can
  /// actually be read.
  ///
  /// The waiting is the point. `ApiService` resolves its bearer token
  /// from `AuthBloc` on every request, and a bloc event is processed
  /// asynchronously — so a screen that dispatched and immediately
  /// called a protected endpoint would send it unauthenticated and get
  /// a 401. The code screen after registration does exactly that.
  ///
  /// Returns null on success, or the reason it refused.
  static Future<AppException?> land(
    AuthSession session, {
    bool remember = true,
  }) async {
    // FRONT-DESK STAFF are welcome now — they land somewhere else.
    //
    // This used to refuse them outright, because the scanner
    // endpoints were not part of this app. They are: `is_scanner` on
    // the sign-in is what tells the two apart, and the caller reads
    // it to choose the destination. The session itself is identical
    // — one token, and the server's role decides which half of the
    // API answers.

    final user = session.user;
    if (user == null) {
      return const ServerException(
        message: 'The session arrived without an account.',
        code: 'no-user',
      );
    }

    // NOTHING TO LAND. The OTP-sent shapes carry an account and no
    // token — `register` under `REGISTER_REQUIRES_VERIFICATION`, and
    // `login` in OTP mode. Storing a signed-in state with an empty
    // bearer would put the app past the guard with nothing to
    // authenticate its next request.
    final token = session.token;
    if (token == null || token.isEmpty) {
      return const ServerException(
        message: 'The session arrived without a token.',
        code: 'no-token',
      );
    }

    final bloc = getIt<AuthBloc>();
    bloc.add(
      AuthEvent.signedIn(
        user: user.toAppUser(),
        token: token,
        // WHICH APP this token opens. Persisted with it, because
        // `is_scanner` is on the sign-in response and nowhere else —
        // `GET /api/user` does not carry it, so a cold start has no
        // second chance to ask.
        isScanner: session.isStaffLogin,
        // Whether the session survives the app being killed — see
        // [AuthEvent.signedIn]. Only the sign-in screen ever sends
        // false; registering and resetting a password both mean to
        // stay.
        remember: remember,
      ),
    );

    try {
      await bloc.stream
          .firstWhere((state) => state is AuthAuthenticated)
          .timeout(const Duration(seconds: 5));
    } on Object {
      // The bloc did not get there. Better to say so than to send the
      // customer onward to a screen whose first request will 401.
      return const CacheException(
        message: 'The session could not be stored.',
        code: 'session-not-stored',
      );
    }
    return null;
  }
}

/// Bridges the server's account to the one the app persists.
///
/// Two models because [TerracottaUser] is the wire shape — guest flags,
/// wallet balance, language — while [User] is what `AuthBloc` stores and
/// every other screen reads. The extra fields are dropped here, not
/// lost: re-read them from `GET /api/profile` where they are needed.
///
/// This tenant's account has no email at all — `phone` is the only
/// identifier — so [User.email] stays null rather than being invented.
extension TerracottaUserMapping on TerracottaUser {
  User toAppUser() {
    // The server keeps ONE name field. Split on the first space so a
    // greeting can say "Ahmed" rather than the whole string, and accept
    // that a two-part family name lands in `lastName` whole.
    final parts = (name ?? '').trim().split(RegExp(r'\s+'));
    final first = parts.isEmpty || parts.first.isEmpty ? null : parts.first;
    final rest = parts.length > 1 ? parts.sublist(1).join(' ') : null;

    return User(
      id: id,
      firstName: first,
      lastName: rest,
      phoneNumber: phone,
      phoneVerifiedAt: verifiedAt,
    );
  }
}

/// What a password reset carries from one screen to the next.
///
/// Three screens share one reset: the number is typed on the first, the
/// code on the second, and the new password on the third — and the LAST
/// call needs all three at once, because `change-forgot-password` takes
/// the identifier and the code again alongside the password. So it
/// travels as one object rather than as a widening list of arguments.
///
/// [identifier] is the wire form (`962791234567`), [display] is what the
/// customer typed and what the code screen shows back to them, so a
/// person with two numbers can see which one the code went to.
///
/// Route extras are in-memory only: a hot restart re-creates the route
/// from the URL and hands the page a null ticket. That is why every
/// field is required here and the NULL case is handled by the screens,
/// which send the customer back to the start of the reset rather than
/// showing a form whose submit could never work.
@immutable
class ResetTicket {
  const ResetTicket({
    required this.identifier,
    required this.display,
    this.otp,
  });

  final String identifier;
  final String display;

  /// The code, once a screen has checked it. `verify-forgot-password-otp`
  /// deliberately does NOT consume the code, so the same one is sent
  /// again to finish the reset.
  final String? otp;

  ResetTicket withOtp(String otp) =>
      ResetTicket(identifier: identifier, display: display, otp: otp);
}
