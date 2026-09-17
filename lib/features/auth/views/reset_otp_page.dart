import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/localization/strings/auth_strings.dart';
import '../../../core/tokens/extensions.dart';
import '../../../core/types/result.dart';
import '../../../shared/common/text_form_fields/text_form_fields.dart';
import '../../../shared/module/buttons/global_filled_button.dart';
import '../../_shared/server_error_locale.dart';
import '../../_shared/shared_hero.dart';
import '../../_shared/terracotta_cta_style.dart';
import '../data/auth_flow.dart';
import '../widgets/auth_failure.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/otp_resend_button.dart';
import 'otp_verification_page.dart' show kOtpLength, kOtpResendWindow;

/// auth 6 — «تغيير كلمة السر» / "Change your password", the OTP step.
///
/// Same five-digit code as registration, a different endpoint:
/// `POST /api/verify-forgot-password-otp`. Verification sits on the
/// LOOSE rate limit (60/min) on purpose, so mistyping does not lock the
/// customer out — only requesting a new code is throttled.
class ResetOtpPage extends StatefulWidget {
  const ResetOtpPage({this.ticket, super.key});

  /// The reset in progress — the number the code went to, in both the
  /// wire form this screen has to send back and the form the customer
  /// typed.
  ///
  /// Null after a hot restart or on a deep link straight into this
  /// route: extras live in memory only. There is nothing to verify
  /// against in that case, so the screen sends them back to the start
  /// rather than showing a form whose submit could not work.
  final ResetTicket? ticket;

  @override
  State<ResetOtpPage> createState() => _ResetOtpPageState();
}

class _ResetOtpPageState extends State<ResetOtpPage>
    with ServerErrorsClearOnLocaleChange<ResetOtpPage> {
  final _code = TextEditingController();
  bool _busy = false;

  /// Whether the code was short when the customer last submitted —
  /// NOT the message. A resolved string held in state freezes in the
  /// language it was raised in, and the form around it would turn
  /// Arabic while the error stayed English.
  bool _incomplete = false;

  /// What the SERVER said about the code — its own sentence, with no
  /// key to re-resolve, cleared on the next attempt.
  String? _otpError;

  final _cancel = CancelToken();

  @override
  void initState() {
    super.initState();
    if (widget.ticket == null) {
      // Nothing to verify against. Back to where the number is asked
      // for, which is the only place that can start a reset.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        // `maybeOf`, because a screen hosted outside a router has
        // nowhere to send anyone — a widget test pumping it on its own,
        // or a preview. Throwing there would be worse than doing
        // nothing, and the submit is already guarded.
        if (GoRouter.maybeOf(context) != null) {
          context.goNamed('forgot-password');
        }
      });
    }
  }

  @override
  void dispose() {
    _cancel.cancel();
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final ticket = widget.ticket;
    if (ticket == null) return;
    if (_code.text.length < kOtpLength) {
      setState(() => _incomplete = true);
      return;
    }
    setState(() {
      _incomplete = false;
      _otpError = null;
      _busy = true;
    });

    // Checks the code WITHOUT consuming it, so a wrong one is refused
    // here rather than on the password screen. The same code is sent
    // again to finish the reset.
    final result = await AuthFlow.checkResetCode(
      identifier: ticket.identifier,
      otp: _code.text,
      cancelToken: _cancel,
    );
    if (!mounted) return;
    setState(() => _busy = false);

    switch (result) {
      case Success():
        await context.pushNamed(
          'reset-password',
          extra: ticket.withOtp(_code.text),
        );
      case Failure(:final error):
        setState(() => _otpError = error.fieldError('otp'));
        showAuthFailure(error);
    }
  }

  Future<void> _resend() async {
    final ticket = widget.ticket;
    if (ticket == null) return;
    final result = await AuthFlow.requestReset(
      identifier: ticket.identifier,
      cancelToken: _cancel,
    );
    if (!mounted) return;
    if (result case Failure(:final error)) showAuthFailure(error);
  }

  @override
  void clearServerErrors() {
    _otpError = null;
  }

  @override
  Widget build(BuildContext context) => AuthScaffold(
    appBarTitle: AuthStrings.resetTitle,
    illustration: AuthIllustration.otp,
    showMark: false,
    title: AuthStrings.otpTitle,
    subtitle: (widget.ticket?.display ?? '').isEmpty
        ? AuthStrings.otpSubtitle(kOtpLength)
        : AuthStrings.otpSubtitleFor(kOtpLength, widget.ticket!.display),
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
        onCompleted: (_) => _submit(),
      ),
      SizedBox(height: context.spacing.xl),
      SharedHero(
        tag: AuthHeroTag.cta,
        // The bar is the same box on every screen; only the
        // label differs, so the two words cross-fade rather
        // than swapping the instant the flight starts.
        flightShuttleBuilder: crossFadeShuttle,
        child: GlobalFilledButton(
          text: AuthStrings.verify,
          isLoading: _busy,
          onPressed: _submit,
          style: terracottaCtaStyle(),
        ),
      ),
      SizedBox(height: context.spacing.md),
      // `auth 6` draws it at y615, under the verify button — the reset
      // flow gets the same resend as registration.
      OtpResendButton(
        cooldown: kOtpResendWindow,
        onResend: _resend,
      ),
    ],
  );
}
