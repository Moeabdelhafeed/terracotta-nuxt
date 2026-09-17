import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/strings/auth_strings.dart';
import '../../../core/localization/strings/field_strings.dart';
import '../../../core/tokens/extensions.dart';
import '../../../core/types/result.dart';
import '../../../core/utils/loggers/logger.dart';
import '../../../data/api/calls/auth_apis.dart';
import '../../../data/models/terracotta/account/app_config.dart';
import '../../../shared/common/selection_fields/checkbox/remember_me_checkbox.dart';
import '../../../shared/common/text_form_fields/text_form_fields.dart';
import '../../../shared/module/buttons/global_filled_button.dart';
import '../../../shared/module/buttons/global_text_button.dart';
import '../../../shared/module/checkbox/checkbox_models.dart';
import '../../_shared/auth_drafts.dart';
import '../../_shared/server_error_locale.dart';
import '../../_shared/shared_hero.dart';
import '../../_shared/terracotta_cta_style.dart';
import '../../gift/data/pending_gift.dart';
import '../data/auth_flow.dart';
import '../data/dev_otp.dart';
import '../data/guest_handover_flow.dart';
import '../data/otp_purpose.dart';
import '../widgets/auth_failure.dart';
import '../widgets/auth_footer_prompt.dart';
import '../widgets/auth_scaffold.dart';

/// auth 1 — «اهلا بعودتك» / "Welcome back".
///
/// Phone + password, per `GET /api/config` (`identifiers: ["phone"]`,
/// `auth_mode: "password"`). The config is read at splash rather than
/// hardcoded, so the same build survives the studio switching to OTP.
///
/// `POST /api/login` needs a **`type`** field alongside the identifier
/// (`"phone"` here) — it is in neither supplied document and its
/// absence is a 422 on every attempt. `AuthApis.login` sends it.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with ServerErrorsClearOnLocaleChange<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _guestBusy = false;

  /// The parsed number, which is what the API wants — the controller
  /// holds only the NATIONAL digits and the dial code lives in the
  /// picker beside it.
  PhoneNumber? _number;

  /// What the server blamed, per input. Cleared on every attempt so a
  /// stale message never sits under a field the customer has since
  /// corrected.
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
    // The screen is gone; nothing is left to receive the answer.
    _cancel.cancel();
    _unbindPhone?.call();
    _unbindPassword?.call();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  /// Whether the session survives the app being killed.
  ///
  /// On by default — it is what almost everybody wants and what the
  /// app did before there was a choice. Unticked, the token is never
  /// written to secure storage at all; see [AuthEvent.signedIn].
  bool _remember = true;

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final number = _number;
    if (number == null) return;

    setState(() {
      _busy = true;
      _identifierError = null;
      _passwordError = null;
    });

    final identifier = AuthFlow.wireIdentifier(number);
    final result = await AuthFlow.signIn(
      identifier: identifier,
      // EMPTY under `auth_mode: otp` — there is no password on that
      // tenant and the box is not drawn. The server reads the
      // identifier, sends a code and answers with no token.
      password: _password.text,
      cancelToken: _cancel,
    );
    if (!mounted) return;

    switch (result) {
      case Success(:final value) when !value.hasToken:
        // The code, when the server hands it back — see [DevOtp].
        DevOtp.show(value.otp);
        // OTP MODE. `login` sent the code and minted nothing —
        // `verifyLogin` is what returns a session, and it needs the
        // identifier this was sent with.
        setState(() => _busy = false);
        AuthDrafts.clear();
        await context.pushNamed(
          'otp-verification',
          extra: OtpPurpose.signIn(identifier),
        );
      case Success(:final value):
        // `land` waits until the token is READABLE — the next screen's
        // first request would otherwise go out unauthenticated.
        final refused = await AuthFlow.land(value, remember: _remember);
        if (!mounted) return;
        if (refused != null) {
          setState(() => _busy = false);
          showAuthFailure(refused);
          return;
        }
        // The password must not outlive the sign-in it was typed for.
        AuthDrafts.clear();
        // BEFORE leaving the page: the sheet is about what they were
        // holding on the way in, and asking after the home screen has
        // loaded reads as an interruption rather than a continuation.
        // Silent when the device is empty, which is the common case.
        // A DIFFERENT APP FOR STAFF.
        //
        // `is_scanner` on the sign-in decides it, and the two are
        // mutually exclusive on the server — a scanner calling the
        // shop gets 403 and a customer calling the desk gets 403. So
        // there is no mode to pick: the account is one or the other,
        // and this is the fork.
        if (value.isStaffLogin) {
          context.goNamed('scanner-desk');
          return;
        }
        await GuestHandoverFlow.offer(context);
        if (!mounted) return;
        // BACK TO THE GIFT, when a link is what brought them here.
        //
        // Claiming needs an account and most recipients have none —
        // that is the shape of a gift. Landing on home is right for
        // everybody else and wrong for someone who signed in from a
        // Claim button: they would have to find the link again. See
        // [PendingGift].
        if (PendingGift.token case final token?) {
          context.go('/gift/$token');
          return;
        }
        context.goNamed('home');
      case Failure(:final error):
        setState(() {
          _busy = false;
          _identifierError = error.fieldError('identifier');
          _passwordError = error.fieldError('password');
        });
        // Does nothing when the server named a field — that message is
        // already under the box it belongs to.
        showAuthFailure(error);
    }
  }

  /// «تصفح كزائر» — browse without an account.
  ///
  /// `POST /api/guest` registers the DEVICE, keyed to the `X-Device-Id`
  /// header the interceptor already sends. It returns no token and
  /// there is nothing to store, so the app stays UNAUTHENTICATED — which
  /// is what keeps `AuthGuard` on the private routes and what makes the
  /// 401 prompt say the right thing when a guest reaches for the cart.
  ///
  /// Its failure is not the visitor's problem: browsing the shop, the
  /// gallery and the workshops needs no session at all, and the things
  /// the call would enable are refused for a guest anyway. So it is
  /// logged and they go through either way.
  Future<void> _browseAsGuest() async {
    if (_guestBusy) return;
    setState(() => _guestBusy = true);

    final result = await AuthApis.createGuest(cancelToken: _cancel);
    if (!mounted) return;
    if (result case Failure(:final error)) {
      Logger.m.w('[Auth] guest registration failed, browsing anyway: $error');
    }

    AuthDrafts.clear();
    context.goNamed('home');
  }

  @override
  void clearServerErrors() {
    _identifierError = null;
    _passwordError = null;
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    return Form(
      key: _formKey,
      child: AuthScaffold(
        title: AuthStrings.loginTitle,
        subtitle: AuthStrings.loginSubtitle,
        footer: AuthFooterPrompt(
          prompt: AuthStrings.noAccountPrompt,
          action: AuthStrings.createAccount,
          onPressed: () => context.pushNamed('register'),
        ),
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
              textInputAction: TextInputAction.next,
              errorText: _identifierError,
              onNumberChanged: (n) {
                _number = n;
                clearOnEdit(_identifierError, () => _identifierError = null);
              },
            ),
          ),
          // NO PASSWORD UNDER `auth_mode: otp`.
          //
          // On that tenant `POST /api/login` takes the identifier
          // alone, sends a code and answers with no token — so a
          // password box would be asking for something the server
          // does not read, and «نسيت كلمة السر» would lead to a reset
          // for a password that does not exist. See [AuthFlow.mode].
          if (AuthFlow.mode == AuthMode.password) ...[
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
                  hint: AuthStrings.enterPasswordHint,
                  identifier: AuthStrings.passwordFieldTitle,
                  errorText: _passwordError,
                  onChanged: (_) =>
                      clearOnEdit(_passwordError, () => _passwordError = null),
                  onSubmitted: (_) => _submit(),
                ),
              ),
            ),
            SizedBox(height: spacing.xs),
            // ONE LINE FOR BOTH. «أبقني مسجّل الدخول» at the start,
            // «نسيت كلمة السر» at the end — a pair of small decisions
            // about the same password, and stacking them would have
            // cost the form a whole row. The heading above was
            // tightened to pay for this line; see
            // `AuthScaffold._titleTop`.
            Row(
              children: [
                Expanded(
                  // THE SHARED ONE — `RememberMeCheckbox` wraps
                  // `GlobalCheckbox` with this same ARB label, and the
                  // app has one checkbox for the same reason it has
                  // one chip. It was hand-rolled here first, out of a
                  // raw Material `Checkbox`, which is exactly what the
                  // module exists to stop.
                  //
                  // Sized down and given the link's type so it reads
                  // as the same weight of thing as «نسيت كلمة السر»
                  // beside it, and does not set the row's height.
                  child: RememberMeCheckbox(
                    value: _remember,
                    onChanged: (v) => setState(() => _remember = v),
                    style: const CheckboxStyle(size: 18),
                    labelStyle: TextStyle(
                      fontSize: kAuthLinkFontSize,
                      color: context.textColors.secondary,
                    ),
                  ),
                ),
                GlobalTextButton(
                  text: AuthStrings.forgotPassword,
                  onPressed: () => context.pushNamed('forgot-password'),
                  shrinkWidth: true,
                  style: const ButtonStateStyle(
                    textStyle: TextStyle(fontSize: kAuthLinkFontSize),
                  ),
                ),
              ],
            ),
          ],
          // THE TENANT TURNED PHONE OFF. The app draws one identifier
          // field and it is a phone number, so there is nothing honest
          // to show — a form whose every submission is a 422 under
          // `type` is worse than a sentence. See
          // [AuthFlow.supportsIdentifier].
          if (!AuthFlow.supportsIdentifier) ...[
            Text(
              AuthStrings.identifierUnsupported,
              textAlign: TextAlign.center,
              style: context.textTheme.bodySmall?.copyWith(
                color: context.statusColors.error,
              ),
            ),
            SizedBox(height: spacing.md),
          ],
          SizedBox(height: spacing.xl),
          SharedHero(
            tag: AuthHeroTag.cta,
            // The bar is the same box on every screen; only the
            // label differs, so the two words cross-fade rather
            // than swapping the instant the flight starts.
            flightShuttleBuilder: crossFadeShuttle,
            child: GlobalFilledButton(
              text: AuthStrings.signIn,
              isLoading: _busy,
              // Nothing to submit when the app cannot ask for what
              // this tenant accepts.
              onPressed: AuthFlow.supportsIdentifier ? _submit : null,
              style: terracottaCtaStyle(),
            ),
          ),
          SizedBox(height: spacing.lg),
          // A RULE, not a second slab. The outlined button that used to
          // sit here was the same size as the bar above it, which read
          // as two equal ways in — and it out-weighted «انشاء حساب» in
          // the footer, which is backwards: an account is worth more to
          // the studio than an anonymous look.
          const _OrRule(),
          SizedBox(height: spacing.sm),
          Center(
            child: GlobalTextButton(
              text: AuthStrings.continueAsGuest,
              isLoading: _guestBusy,
              onPressed: _browseAsGuest,
              shrinkWidth: true,
              style: const ButtonStateStyle(
                textStyle: TextStyle(fontSize: kAuthLinkFontSize),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// «———— أو ————» between the sign-in bar and the guest link.
///
/// The gap alone read as a stray link under a button. The rule names
/// the relationship: two ways into the app, one of them the ask.
class _OrRule extends StatelessWidget {
  const _OrRule();

  @override
  Widget build(BuildContext context) {
    final line = Expanded(
      child: Divider(
        height: 1,
        thickness: 1,
        color: context.textColors.primary.withValues(alpha: 0.1),
      ),
    );

    return Row(
      children: [
        line,
        Padding(
          padding: EdgeInsets.symmetric(horizontal: context.spacing.sm),
          child: Text(
            AuthStrings.or,
            style: context.textTheme.bodySmall?.copyWith(
              color: context.textColors.secondary,
              fontSize: kAuthLinkFontSize,
            ),
          ),
        ),
        line,
      ],
    );
  }
}
