import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/localization/strings/auth_strings.dart';
import '../../../core/tokens/extensions.dart';
import '../../../core/types/result.dart';
import '../../../shared/common/text_form_fields/text_form_fields.dart';
import '../../../shared/module/buttons/global_filled_button.dart';
import '../../_shared/auth_drafts.dart';
import '../../_shared/server_error_locale.dart';
import '../../_shared/shared_hero.dart';
import '../../_shared/terracotta_cta_style.dart';
import '../data/auth_flow.dart';
import '../data/guest_handover_flow.dart';
import '../widgets/auth_failure.dart';
import '../widgets/auth_scaffold.dart';

/// auth 7 — «تغيير كلمة السر» / "Change your password", the new one.
///
/// `POST /api/change-forgot-password`. A failure comes back keyed to
/// the field it belongs to, so a weak password lands under `password`
/// and a stale code under `otp` — render each under its own input
/// rather than in one alert.
class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({this.ticket, super.key});

  /// The reset in progress, carrying the identifier AND the code the
  /// previous screen checked — `change-forgot-password` needs both
  /// again alongside the new password.
  ///
  /// Null after a hot restart, because route extras live in memory
  /// only. The screen sends the customer back to the start rather than
  /// showing a form it could not submit.
  final ResetTicket? ticket;

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage>
    with ServerErrorsClearOnLocaleChange<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;

  String? _passwordError;

  /// A code that expired between the screen before this one and the
  /// submit here comes back under `otp` — which is on the PREVIOUS
  /// screen, so it is shown as a toast and the customer is sent back
  /// for a fresh one.
  final _cancel = CancelToken();

  @override
  void initState() {
    super.initState();
    if (widget.ticket?.otp == null) {
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
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final ticket = widget.ticket;
    final otp = ticket?.otp;
    if (ticket == null || otp == null) return;

    setState(() {
      _busy = true;
      _passwordError = null;
    });

    final changed = await AuthFlow.setNewPassword(
      identifier: ticket.identifier,
      otp: otp,
      password: _password.text,
      passwordConfirmation: _confirm.text,
      cancelToken: _cancel,
    );
    if (!mounted) return;

    if (changed case Failure(:final error)) {
      setState(() {
        _busy = false;
        _passwordError = error.fieldError('password');
      });
      showAuthFailure(error);
      // A stale or already-spent code is answered under `otp`, which
      // belongs to the screen before this one. Send them back for a
      // fresh one rather than leaving them on a form that cannot pass.
      if (error.fieldError('otp') != null) context.goNamed('forgot-password');
      return;
    }

    // Changing the password does NOT sign the customer in, so this
    // signs them in with the password they just chose — sparing them
    // typing it again into the screen they came from.
    final signedIn = await AuthFlow.signIn(
      identifier: ticket.identifier,
      password: _password.text,
      cancelToken: _cancel,
    );
    if (!mounted) return;
    setState(() => _busy = false);

    switch (signedIn) {
      case Success(:final value):
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
        // The password DID change; only the convenience sign-in
        // failed. Sending them to sign in by hand is honest — telling
        // them the reset failed would not be.
        showAuthFailure(error);
        AuthDrafts.clear();
        context.goNamed('login');
    }
  }

  @override
  void clearServerErrors() {
    _passwordError = null;
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    return Form(
      key: _formKey,
      child: AuthScaffold(
        appBarTitle: AuthStrings.resetTitle,
        illustration: AuthIllustration.passwordChange,
        showMark: false,
        title: AuthStrings.resetTitle,
        subtitle: AuthStrings.resetSubtitle,
        children: [
          PasswordField(
            controller: _password,
            mode: PasswordFieldMode.create,
            // THE CONFIRM BOX TOO — see `RegisterPage`.
            confirmController: _confirm,
            hint: AuthStrings.enterPasswordHint,
            identifier: AuthStrings.newPassword,
            errorText: _passwordError,
            onChanged: (_) =>
                clearOnEdit(_passwordError, () => _passwordError = null),
            textInputAction: TextInputAction.next,
          ),
          SizedBox(height: spacing.md),
          PasswordField(
            controller: _confirm,
            mode: PasswordFieldMode.confirm,
            matchController: _password,
            hint: AuthStrings.enterConfirmPasswordHint,
            identifier: AuthStrings.confirmPassword,
            onSubmitted: (_) => _submit(),
          ),
          SizedBox(height: spacing.xl),
          SharedHero(
            tag: AuthHeroTag.cta,
            // The bar is the same box on every screen; only the
            // label differs, so the two words cross-fade rather
            // than swapping the instant the flight starts.
            flightShuttleBuilder: crossFadeShuttle,
            child: GlobalFilledButton(
              text: AuthStrings.change,
              isLoading: _busy,
              onPressed: _submit,
              // The last step of the flow — nothing follows it to
              // point at.
              style: terracottaCtaStyle(showArrow: false),
            ),
          ),
        ],
      ),
    );
  }
}
