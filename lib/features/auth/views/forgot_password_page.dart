import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/localization/strings/auth_strings.dart';
import '../../../core/localization/strings/field_strings.dart';
import '../../../core/tokens/extensions.dart';
import '../../../core/types/result.dart';
import '../../../shared/common/text_form_fields/text_form_fields.dart';
import '../../../shared/module/buttons/global_filled_button.dart';
import '../../_shared/auth_drafts.dart';
import '../../_shared/server_error_locale.dart';
import '../../_shared/shared_hero.dart';
import '../../_shared/terracotta_cta_style.dart';
import '../data/auth_flow.dart';
import '../widgets/auth_failure.dart';
import '../widgets/auth_scaffold.dart';

/// auth 5 — «أدخل رقم هاتفك» / "Enter your phone number".
///
/// Rate-limited to **3 per 5 minutes** server-side (the `otp` limiter),
/// so a customer who taps twice will be refused. Surface the 429
/// message rather than retrying.
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage>
    with ServerErrorsClearOnLocaleChange<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();
  bool _busy = false;

  /// The parsed number — the controller holds only national digits.
  PhoneNumber? _number;

  String? _identifierError;

  final _cancel = CancelToken();

  /// Detaches the draft bindings — a controller outlives its widget
  /// only if someone forgets to.
  VoidCallback? _unbindPhone;

  @override
  void initState() {
    super.initState();
    _unbindPhone = AuthDrafts.phone.bind(_phone);
  }

  @override
  void dispose() {
    _cancel.cancel();
    _unbindPhone?.call();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final number = _number;
    if (number == null) return;

    setState(() {
      _busy = true;
      _identifierError = null;
    });

    final identifier = AuthFlow.wireIdentifier(number);
    final result = await AuthFlow.requestReset(
      identifier: identifier,
      cancelToken: _cancel,
    );
    if (!mounted) return;
    setState(() => _busy = false);

    switch (result) {
      case Success():
        await context.pushNamed(
          'reset-otp',
          // The number the code went to travels with the reset: the
          // code screen has to send it back, and a customer with two
          // numbers needs to see which one was used.
          extra: ResetTicket(identifier: identifier, display: _phone.text),
        );
      case Failure(:final error):
        // An unknown account comes back under `identifier`. Sending
        // three a minute is the OTP limiter, and a 429 message is worth
        // reading, so the toast shows the server's own sentence.
        setState(() => _identifierError = error.fieldError('identifier'));
        showAuthFailure(error);
    }
  }

  @override
  void clearServerErrors() {
    _identifierError = null;
  }

  @override
  Widget build(BuildContext context) => Form(
    key: _formKey,
    child: AuthScaffold(
      // The BAR names the flow, the heading names the step.
      appBarTitle: AuthStrings.resetTitle,
      illustration: AuthIllustration.passwordRequest,
      // The handset is the drawing's subject; a vessel under it would
      // be a second one.
      showMark: false,
      title: AuthStrings.forgotTitle,
      subtitle: AuthStrings.forgotSubtitle,
      children: [
        SharedHero(
          tag: AuthHeroTag.phone,
          // A field in the air needs a Material the Overlay
          // does not have.
          flightShuttleBuilder: fieldShuttle,
          child: PhoneNumberField(
            controller: _phone,
            hint: AuthStrings.enterPhoneNumberHint,
            identifier: FieldStrings.phoneLabel,
            errorText: _identifierError,
            onNumberChanged: (n) {
              _number = n;
              clearOnEdit(_identifierError, () => _identifierError = null);
            },
            onSubmitted: (_) => _submit(),
          ),
        ),
        SizedBox(height: context.spacing.xl),
        SharedHero(
          tag: AuthHeroTag.cta,
          // The bar is the same box on every screen; only the
          // label differs, so the two words cross-fade rather
          // than swapping the instant the flight starts.
          flightShuttleBuilder: crossFadeShuttle,
          child: GlobalFilledButton(
            text: AuthStrings.sendCode,
            isLoading: _busy,
            onPressed: _submit,
            style: terracottaCtaStyle(),
          ),
        ),
      ],
    ),
  );
}
