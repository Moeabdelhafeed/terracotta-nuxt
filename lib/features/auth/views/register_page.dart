import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/localization/strings/auth_strings.dart';
import '../../../core/localization/strings/field_strings.dart';
import '../../../core/localization/strings/page_strings.dart';
import '../../../core/tokens/extensions.dart';
import '../../../core/types/result.dart';
import '../../../data/models/terracotta/account/auth_session.dart';
import '../../../shared/common/selection_fields/selection_fields.dart';
import '../../../shared/common/text_form_fields/text_form_fields.dart';
import '../../../shared/module/buttons/global_filled_button.dart';
import '../../_shared/auth_drafts.dart';
import '../../_shared/server_error_locale.dart';
import '../../_shared/shared_hero.dart';
import '../../_shared/terracotta_cta_style.dart';
import '../data/auth_flow.dart';
import '../data/dev_otp.dart';
import '../data/guest_handover_flow.dart';
import '../widgets/auth_failure.dart';
import '../widgets/auth_footer_prompt.dart';
import '../widgets/auth_scaffold.dart';

/// auth 2 — «اهلا بك بتيراكوتا» / "Welcome to Terracotta".
///
/// **`register` already returns a token.** The screen-to-API mapping
/// says to follow it with `login`; that is wrong, and would spend one
/// of the five-per-minute auth attempts for nothing. `AuthApis.register`
/// answers with an `AuthSession`.
///
/// **Two fields here are not in the design.** `POST /api/register`
/// requires `name` and `policy_agreed`, and the Pencil frame draws
/// neither — it shows only phone, password and confirm. They are added
/// because the call fails without them, and flagged in
/// `docs/api-contract.md` so the design can catch up.
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with ServerErrorsClearOnLocaleChange<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _agreed = false;
  bool _busy = false;

  /// The parsed number — the controller holds only the national digits.
  PhoneNumber? _number;

  String? _nameError;
  String? _identifierError;
  String? _passwordError;

  final _cancel = CancelToken();

  /// Detaches the draft bindings — a controller outlives its widget
  /// only if someone forgets to.
  VoidCallback? _unbindPhone;
  VoidCallback? _unbindPassword;

  @override
  void initState() {
    super.initState();
    _unbindPhone = AuthDrafts.phone.bind(_phone);
    _unbindPassword = AuthDrafts.password.bind(_password);
  }

  @override
  void dispose() {
    _cancel.cancel();
    _unbindPhone?.call();
    _unbindPassword?.call();
    _name.dispose();
    _phone.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_agreed) return;
    final number = _number;
    if (number == null) return;

    setState(() {
      _busy = true;
      _nameError = null;
      _identifierError = null;
      _passwordError = null;
    });

    final result = await AuthFlow.createAccount(
      name: _name.text.trim(),
      identifier: AuthFlow.wireIdentifier(number),
      password: _password.text,
      passwordConfirmation: _confirm.text,
      cancelToken: _cancel,
    );
    if (!mounted) return;

    switch (result) {
      case Success(:final value):
        // WHICH OF THE TWO SHAPES CAME BACK.
        //
        // `register` answers either signed-in (a token, `is_verified:
        // true`, nothing left to do) or OTP-sent — an account with
        // `verified_at: null`, no token at all, and a code already on
        // its way. `REGISTER_REQUIRES_VERIFICATION` is what chooses,
        // and it is the studio's switch, not a build-time fact.
        //
        // The second shape needs a session before the code can be
        // entered: `POST /api/verify-otp` verifies the SIGNED-IN
        // account and has no identifier field. The spec says so
        // outright — "no token is issued, and the client must call
        // `POST /api/login`".
        // THE CODE, WHEN THE SERVER HANDS IT BACK. Dev and staging do
        // — see [DevOtp] — and it is shown before the sign-in below,
        // so a tester has the number in hand by the time the boxes
        // arrive.
        DevOtp.show(value.otp);

        final session = value.needsVerification
            ? await _signInForVerification(number)
            : value;
        if (!mounted) return;
        if (session == null) {
          setState(() => _busy = false);
          return;
        }

        // Landing it is what lets the code screen verify the account
        // it just made — `land` waits until the token is READABLE, so
        // the next request does not go out unauthenticated.
        final refused = await AuthFlow.land(session);
        if (!mounted) return;
        setState(() => _busy = false);
        if (refused != null) {
          showAuthFailure(refused);
          return;
        }
        // Registering PROMOTES the device's guest in place on this
        // server, so a visitor who filled a basket and then made an
        // account is the same person — and their picks should follow.
        await GuestHandoverFlow.offer(context);
        if (!mounted) return;
        await context.pushNamed(
          session.needsVerification ? 'otp-verification' : 'register-success',
        );
      case Failure(:final error):
        setState(() {
          _busy = false;
          _nameError = error.fieldError('name');
          _identifierError = error.fieldError('identifier');
          _passwordError = error.fieldError('password');
        });
        showAuthFailure(error);
    }
  }

  /// Signs in the account that was just created, for the token the
  /// code screen needs.
  ///
  /// Only on the OTP-sent shape — see [_submit]. The credentials are
  /// the ones just typed, so nothing is asked for twice; a failure
  /// here is shown as it comes, because the ACCOUNT exists either way
  /// and registering again would only answer «مُستخدمة من قبل».
  Future<AuthSession?> _signInForVerification(PhoneNumber number) async {
    final result = await AuthFlow.signIn(
      identifier: AuthFlow.wireIdentifier(number),
      password: _password.text,
      cancelToken: _cancel,
    );
    if (!mounted) return null;

    switch (result) {
      case Success(:final value):
        return value;
      case Failure(:final error):
        showAuthFailure(error);
        return null;
    }
  }

  @override
  void clearServerErrors() {
    _nameError = null;
    _identifierError = null;
    _passwordError = null;
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    return Form(
      key: _formKey,
      child: AuthScaffold(
        title: AuthStrings.registerTitle,
        subtitle: AuthStrings.loginSubtitle,
        footer: AuthFooterPrompt(
          prompt: AuthStrings.haveAccountPrompt,
          action: AuthStrings.signIn,
          onPressed: () => context.pushNamed('login'),
        ),
        children: [
          NameField(
            controller: _name,
            hint: AuthStrings.enterFullNameHint,
            identifier: AuthStrings.fullName,
            required: true,
            errorText: _nameError,
            onChanged: (_) => clearOnEdit(_nameError, () => _nameError = null),
            textInputAction: TextInputAction.next,
          ),
          SizedBox(height: spacing.md),
          SharedHero(
            tag: AuthHeroTag.phone,
            // A field in the air needs a Material the Overlay
            // does not have.
            flightShuttleBuilder: fieldShuttle,
            child: PhoneNumberField(
              controller: _phone,
              hint: AuthStrings.enterPhoneNumberHint,
              identifier: FieldStrings.phoneLabel,
              textInputAction: TextInputAction.next,
              errorText: _identifierError,
              onNumberChanged: (n) {
                _number = n;
                clearOnEdit(_identifierError, () => _identifierError = null);
              },
            ),
          ),
          SizedBox(height: spacing.md),
          SharedHero(
            tag: AuthHeroTag.password,
            // A field in the air needs a Material the Overlay does not
            // have — same reason as the phone box.
            flightShuttleBuilder: fieldShuttle,
            // Rebuilds when the eye is flipped on ANOTHER screen, so
            // the choice survives the trip.
            child: ValueListenableBuilder<bool>(
              valueListenable: AuthDrafts.passwordVisible,
              builder: (context, visible, _) => PasswordField(
                obscured: !visible,
                onObscureToggled: (obscured) =>
                    AuthDrafts.passwordVisible.value = !obscured,
                controller: _password,
                mode: PasswordFieldMode.create,
                // THE CONFIRM BOX TOO. ✨ fills this field with a
                // generated password; without the linked controller the
                // customer was left staring at a confirm box they could
                // not type into, because they never saw what was
                // generated. This is what a password manager does.
                confirmController: _confirm,
                hint: AuthStrings.enterPasswordHint,
                identifier: AuthStrings.passwordFieldTitle,
                errorText: _passwordError,
                onChanged: (_) =>
                    clearOnEdit(_passwordError, () => _passwordError = null),
                textInputAction: TextInputAction.next,
              ),
            ),
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
          SizedBox(height: spacing.md),
          // A FORM FIELD, so an unticked box fails `Form.validate()`
          // and says so where the box is.
          ConsentCheckboxField(
            initialValue: _agreed,
            onChanged: (v) => _agreed = v,
            // THE STUDIO'S OWN WORDS, not the template's.
            //
            // These pointed at the `legal` route, which renders the
            // bundled placeholder text that shipped with the template —
            // so the box a customer ticks to agree opened something the
            // studio has never read. `GET /api/pages` publishes the
            // real ones, and `policy_agreed` on the registration is a
            // claim about THOSE.
            onTermsTap: () => context.pushNamed(
              'page',
              pathParameters: {'slug': PageStrings.terms},
            ),
            onPrivacyTap: () => context.pushNamed(
              'page',
              pathParameters: {'slug': PageStrings.privacy},
            ),
          ),
          SizedBox(height: spacing.xl),
          // NOT disabled on the unticked box. A dead button explains
          // nothing — the customer is left pressing a control that does
          // not respond and no text anywhere saying why. Pressing it
          // validates, and the consent field turns red with its reason.
          SharedHero(
            tag: AuthHeroTag.cta,
            // The bar is the same box on every screen; only the
            // label differs, so the two words cross-fade rather
            // than swapping the instant the flight starts.
            flightShuttleBuilder: crossFadeShuttle,
            child: GlobalFilledButton(
              text: AuthStrings.register,
              isLoading: _busy,
              onPressed: _submit,
              style: terracottaCtaStyle(),
            ),
          ),
        ],
      ),
    );
  }
}
