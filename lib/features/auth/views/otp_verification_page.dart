import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/localization/strings/auth_strings.dart';
import '../../../core/tokens/extensions.dart';
import '../../../core/types/result.dart';
import '../../../shared/common/text_form_fields/text_form_fields.dart';
import '../../../shared/module/buttons/global_filled_button.dart';
import '../../_shared/account_refresh.dart';
import '../../_shared/auth_drafts.dart';
import '../../_shared/server_error_locale.dart';
import '../../_shared/shared_hero.dart';
import '../../_shared/terracotta_cta_style.dart';
import '../data/auth_flow.dart';
import '../data/dev_otp.dart';
import '../data/guest_handover_flow.dart';
import '../data/otp_purpose.dart';
import '../widgets/auth_failure.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/otp_resend_button.dart';

/// auth 3 — «أدخل رمز التحقق» / "Enter the code".
///
/// **The code is SIX digits, whatever the design frame says.**
///
/// The frame writes it out — "رمز تحقق مكوّنًا من ٥ أرقام" — and this
/// followed it to five. The SERVER sends six: `POST /api/register`
/// under `REGISTER_REQUIRES_VERIFICATION` answered `"otp": "123456"`
/// on 2026-09-17, and `Validators.kOtpLength` has said six all along.
///
/// Five boxes against a six-digit code is the worse half of the same
/// mistake the doc here warned about: the last digit has nowhere to
/// go, `onCompleted` never fires, and the code the customer was sent
/// cannot be entered at all.
///
/// The SUBTITLE is built from this number, so the sentence follows the
/// boxes rather than contradicting them.
const kOtpLength = 6;

/// How long before the resend link comes back. The design draws the
/// countdown as `m:ss` ("١:٤٥"), so it is formatted, not a bare count.
const kOtpResendWindow = Duration(minutes: 1, seconds: 45);

class OtpVerificationPage extends StatefulWidget {
  const OtpVerificationPage({this.purpose, super.key});

  /// Why this screen is open — verifying a new account, or finishing
  /// an OTP-mode sign-in. See [OtpPurpose].
  final OtpPurpose? purpose;

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage>
    with ServerErrorsClearOnLocaleChange<OtpVerificationPage> {
  final _code = TextEditingController();
  bool _busy = false;

  /// Whether the code was short when the customer last submitted —
  /// NOT the message. A resolved string held in state freezes in the
  /// language it was raised in, and the form around it would turn
  /// Arabic while the error stayed English.
  bool _incomplete = false;

  /// What the SERVER said about the code.
  ///
  /// Unlike [_incomplete] this really is a stored string, because it is
  /// the server's sentence and there is no key to re-resolve. It is
  /// cleared on the next attempt, so the window where a language change
  /// could strand it in the previous one is a single failed try.
  String? _otpError;

  final _cancel = CancelToken();

  /// Why this screen is open — see [OtpPurpose]. A hot restart loses
  /// the `extra`, and registration is the flow it was built for.
  late final OtpPurpose _purpose =
      widget.purpose ?? const OtpPurpose.registration();

  @override
  void dispose() {
    _cancel.cancel();
    _code.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    // A short code used to return in SILENCE — the button appeared dead
    // and nothing on screen said why.
    if (_code.text.length < kOtpLength) {
      setState(() => _incomplete = true);
      return;
    }
    setState(() {
      _incomplete = false;
      _otpError = null;
      _busy = true;
    });

    // TWO JOBS, two endpoints — see [OtpPurpose].
    //
    // Registering already signed this customer in, so the session
    // token identifies the account and there is no identifier to send.
    // An OTP-mode SIGN-IN has no session yet: `login` sent the code
    // and minted nothing, and `verifyLogin` is what returns one.
    if (_purpose.identifier case final identifier?) {
      await _finishSignIn(identifier);
      return;
    }

    final result = await AuthFlow.verifyAccount(
      otp: _code.text,
      cancelToken: _cancel,
    );
    if (!mounted) return;
    setState(() => _busy = false);

    switch (result) {
      case Success():
        // THE CODE IS SPENT. Leaving the toast up would be a stale
        // number standing over a finished flow.
        DevOtp.clear();

        // AND THE STORED ACCOUNT IS NOW OUT OF DATE.
        //
        // `verify-otp` stamps `verified_at` on the SERVER; the copy in
        // `AuthBloc` — which is what `AuthGate.isVerified` reads, and
        // therefore what draws the card on home and profile — still
        // says null. Without this the reader verifies, comes back, and
        // is still being asked to verify.
        await AccountRefresh.user(context);
        if (!mounted) return;

        await context.pushNamed('register-success');
      case Failure(:final error):
        setState(() => _otpError = error.fieldError('otp'));
        showAuthFailure(error);
    }
  }

  /// The OTP-mode sign-in half: the code becomes the session.
  Future<void> _finishSignIn(String identifier) async {
    final result = await AuthFlow.verifySignIn(
      identifier: identifier,
      otp: _code.text,
      cancelToken: _cancel,
    );
    if (!mounted) return;
    setState(() => _busy = false);

    switch (result) {
      case Success(:final value):
        DevOtp.clear();
        // `land` waits until the token is READABLE — the next screen's
        // first request would otherwise go out unauthenticated. It is
        // also what refuses a staff login on the customer build.
        final refused = await AuthFlow.land(value);
        if (!mounted) return;
        if (refused != null) {
          showAuthFailure(refused);
          return;
        }
        AuthDrafts.clear();
        await GuestHandoverFlow.offer(context);
        if (!mounted) return;
        context.goNamed('home');
      case Failure(:final error):
        setState(() => _otpError = error.fieldError('otp'));
        showAuthFailure(error);
    }
  }

  Future<void> _resend() async {
    final result = await AuthFlow.resendAccountCode(cancelToken: _cancel);
    if (!mounted) return;
    switch (result) {
      case Success(:final value):
        // A RESEND IS A NEW CODE, and the toast has to follow it —
        // the one on screen is now wrong. See [DevOtp].
        DevOtp.showFrom(value);
      case Failure(:final error):
        showAuthFailure(error);
    }
  }

  @override
  void clearServerErrors() {
    _otpError = null;
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    return AuthScaffold(
      // This screen is reached from registering AND from resetting a
      // password; the bar is what tells the two apart.
      appBarTitle: AuthStrings.createAccount,
      illustration: AuthIllustration.otp,
      showMark: false,
      title: AuthStrings.otpTitle,
      subtitle: AuthStrings.otpSubtitle(kOtpLength),
      children: [
        OtpField(
          controller: _code,
          length: kOtpLength,
          errorText: _incomplete ? AuthStrings.otpIncomplete : _otpError,
          onChanged: (_) {
            if (_incomplete || _otpError != null) {
              setState(() {
                _incomplete = false;
                _otpError = null;
              });
            }
          },
          onCompleted: (_) => _verify(),
        ),
        SizedBox(height: spacing.xl),
        SharedHero(
          tag: AuthHeroTag.cta,
          // The bar is the same box on every screen; only the
          // label differs, so the two words cross-fade rather
          // than swapping the instant the flight starts.
          flightShuttleBuilder: crossFadeShuttle,
          child: GlobalFilledButton(
            text: AuthStrings.verify,
            isLoading: _busy,
            onPressed: _verify,
            style: terracottaCtaStyle(),
          ),
        ),
        SizedBox(height: spacing.md),
        // BELOW the primary action, as the design draws it — resending
        // is the fallback, not the next step.
        OtpResendButton(
          cooldown: kOtpResendWindow,
          onResend: _resend,
        ),
      ],
    );
  }
}
