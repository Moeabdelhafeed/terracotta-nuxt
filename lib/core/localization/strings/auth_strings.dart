import '../../../generated/l10n.dart';
import '../tr.dart';

/// Auth feature strings — sign in / register / OTP / form field
/// titles and hints.
class AuthStrings {
  // ─── asking for an account at the END of something ────────
  //
  // Not the same conversation as `SessionExpiry.prompt`, which
  // interrupts. A visitor who has picked a date, chosen their seats and
  // reached the pay button is not asking to see a private screen — they
  // are trying to buy something, and the only question they have at
  // that moment is whether signing in throws away what they just did.
  // The copy answers that first.

  static String get needAccountTitle =>
      Tr.t('auth_needed_title', S.current.auth_needed_title);

  /// For a booking that is filled in and waiting on the seat.
  static String get needAccountBooking =>
      Tr.t('auth_needed_booking', S.current.auth_needed_booking);

  /// For a basket at the pay step.
  static String get needAccountCart =>
      Tr.t('auth_needed_cart', S.current.auth_needed_cart);

  static String get needAccountConfirm =>
      Tr.t('auth_needed_confirm', S.current.auth_needed_confirm);

  static String get needAccountLater =>
      Tr.t('auth_needed_later', S.current.auth_needed_later);

  AuthStrings._();

  // ─── Actions ────────────────────────────────────────────────
  static String get signIn => Tr.t('auth_sign_in', S.current.auth_sign_in);

  /// «أبقني مسجّل الدخول» — the sign-in checkbox.
  ///
  /// Worded as what it DOES rather than «تذكرني»: the app is not
  /// remembering a name to fill in, it is keeping the SESSION — and
  /// unticked, the token is never written to secure storage at all.
  /// See [AuthEvent.signedIn].
  static String get rememberMe =>
      Tr.t('auth_remember_me', S.current.auth_remember_me);
  static String get signOut => Tr.t('auth_sign_out', S.current.auth_sign_out);
  static String get register => Tr.t('auth_register', S.current.auth_register);
  static String get forgotPassword =>
      Tr.t('auth_forgot_password', S.current.auth_forgot_password);

  // ─── Parameterized messages ─────────────────────────────────
  static String enterOtp(int digits) =>
      Tr.t('auth_enter_otp', S.current.auth_enter_otp(digits));
  static String welcomeBack(String name) =>
      Tr.t('auth_welcome_back', S.current.auth_welcome_back(name));

  // ─── Form field titles ──────────────────────────────────────
  static String get firstNameFieldTitle => Tr.t(
    'auth_first_name_field_title',
    S.current.auth_first_name_field_title,
  );
  static String get lastNameFieldTitle =>
      Tr.t('auth_last_name_field_title', S.current.auth_last_name_field_title);
  static String get phoneNumberFieldTitle => Tr.t(
    'auth_phone_number_field_title',
    S.current.auth_phone_number_field_title,
  );
  static String get passwordFieldTitle =>
      Tr.t('auth_password_field_title', S.current.auth_password_field_title);
  static String get confirmPasswordFieldTitle => Tr.t(
    'auth_confirm_password_field_title',
    S.current.auth_confirm_password_field_title,
  );

  // ─── Form field hints ───────────────────────────────────────
  static String get enterFirstNameHint =>
      Tr.t('auth_enter_first_name_hint', S.current.auth_enter_first_name_hint);
  static String get enterLastNameHint =>
      Tr.t('auth_enter_last_name_hint', S.current.auth_enter_last_name_hint);
  static String get enterPhoneNumberHint => Tr.t(
    'auth_enter_phone_number_hint',
    S.current.auth_enter_phone_number_hint,
  );
  static String get enterPasswordHint =>
      Tr.t('auth_enter_password_hint', S.current.auth_enter_password_hint);
  static String get enterConfirmPasswordHint => Tr.t(
    'auth_enter_confirm_password_hint',
    S.current.auth_enter_confirm_password_hint,
  );
  static String get enterMiddleNameHint => Tr.t(
    'auth.enter_middle_name_hint',
    S.current.auth_enter_middle_name_hint,
  );
  static String get enterFatherNameHint => Tr.t(
    'auth.enter_father_name_hint',
    S.current.auth_enter_father_name_hint,
  );
  static String get enterFullNameHint =>
      Tr.t('auth.enter_full_name_hint', S.current.auth_enter_full_name_hint);

  // ─── Terracotta auth screens ────────────────────────────────
  //
  // Copy is written English-first here; the Arabic in intl_ar.arb is
  // the wording the Pencil design actually uses, not a translation of
  // the English. Where the two differ in tone, the Arabic wins — it is
  // the primary locale and it is what the studio approved.

  /// auth 1 — "اهلا بعودتك"
  static String get loginTitle =>
      Tr.t('auth_login_title', S.current.auth_login_title);
  static String get loginSubtitle =>
      Tr.t('auth_login_subtitle', S.current.auth_login_subtitle);
  static String get noAccountPrompt =>
      Tr.t('auth_no_account_prompt', S.current.auth_no_account_prompt);
  static String get createAccount =>
      Tr.t('auth_create_account', S.current.auth_create_account);

  /// auth 2 — "اهلا بك بتيراكوتا"
  static String get registerTitle =>
      Tr.t('auth_register_title', S.current.auth_register_title);
  static String get haveAccountPrompt =>
      Tr.t('auth_have_account_prompt', S.current.auth_have_account_prompt);

  /// auth 3 — OTP after registering
  // ─── Verifying an account that is already signed in ─────────
  //
  /// The code, when the server hands it back — see `DevOtp`.
  static String get devOtpTitle =>
      Tr.t('auth_dev_otp_title', S.current.auth_dev_otp_title);

  static String get verifyCardTitle =>
      Tr.t('auth_verify_card_title', S.current.auth_verify_card_title);

  static String get verifyCardBody =>
      Tr.t('auth_verify_card_body', S.current.auth_verify_card_body);

  static String get verifyCardCta =>
      Tr.t('auth_verify_card_cta', S.current.auth_verify_card_cta);

  static String get verifyNeededTitle =>
      Tr.t('auth_verify_needed_title', S.current.auth_verify_needed_title);

  static String get verifyNeededConfirm => Tr.t(
    'auth_verify_needed_confirm',
    S.current.auth_verify_needed_confirm,
  );

  /// «حجز الورشة يحتاج رقماً موثّقاً» — said at the button, not at the
  /// door. See `AuthGate.demandVerified`.
  static String get verifyNeededBook =>
      Tr.t('auth_verify_needed_book', S.current.auth_verify_needed_book);

  static String get verifyNeededBuy =>
      Tr.t('auth_verify_needed_buy', S.current.auth_verify_needed_buy);

  static String get verifySent =>
      Tr.t('auth_verify_sent', S.current.auth_verify_sent);

  static String get otpTitle =>
      Tr.t('auth_otp_title', S.current.auth_otp_title);
  static String get otpIncomplete =>
      Tr.t('auth_otp_incomplete', S.current.auth_otp_incomplete);
  static String get otpResend =>
      Tr.t('auth_otp_resend', S.current.auth_otp_resend);

  /// The design shows a `m:ss` countdown beside the label
  /// ("اعادة ارسال الرمز ١:٤٥"), not a bare seconds count.
  static String otpResendTimer(String timer) =>
      Tr.t('auth_otp_resend_timer', S.current.auth_otp_resend_timer(timer));

  /// The design says FIVE digits, not the six most OTP fields default to.
  static String otpSubtitle(int digits) =>
      Tr.t('auth_otp_subtitle', S.current.auth_otp_subtitle(digits));

  /// The same line with the number the code actually went to. Preferred
  /// wherever the previous screen knows it — "your phone" is no help to
  /// someone who has two.
  static String otpSubtitleFor(int digits, String phone) => Tr.t(
    'auth_otp_subtitle_phone',
    S.current.auth_otp_subtitle_phone(digits, _unbreakable(phone)),
  );

  /// Keeps a phone number in one piece inside a right-to-left sentence.
  ///
  /// Two separate problems, one fix each:
  ///
  /// - The number is a LEFT-TO-RIGHT run inside RTL prose. Without an
  ///   isolate the surrounding text reorders its pieces, so `079 834
  ///   4241` reads back as a different number.
  /// - Its groups are separated by ordinary spaces, which are line
  ///   BREAK opportunities — so a number near the end of a line was
  ///   split across two, with the tail alone on the next.
  ///
  /// U+2066/U+2069 isolate the run; the non-breaking spaces stop it
  /// being broken up.
  static String _unbreakable(String phone) =>
      '\u2066${phone.replaceAll(' ', '\u00A0')}\u2069';

  static String get confirmPassword =>
      Tr.t('auth_confirm_password', S.current.auth_confirm_password);
  static String get fullName =>
      Tr.t('auth_full_name', S.current.auth_full_name);
  static String get policyAgree =>
      Tr.t('auth_policy_agree', S.current.auth_policy_agree);
  static String get policyRequired =>
      Tr.t('auth_policy_required', S.current.auth_policy_required);
  /// What a new account is told about changing a booking.
  ///
  /// **No number.** It used to say «خلال ٣ ساعات من وقت تأكيد الحجز»,
  /// which was wrong twice: the window is measured BACKWARDS from the
  /// session, not forwards from the booking, and every workshop
  /// carries its own `cancellation_window_hours` — so a screen that
  /// belongs to no workshop cannot quote one. A window of `0` is a
  /// real setting too, and it means "any time before it starts", not
  /// "never". The booking itself carries `editable_until`, which is
  /// the deadline as a date, and that is where this sends them.
  static String get registerSuccessBody => Tr.t(
    'auth_register_success_body',
    S.current.auth_register_success_body,
  );
  static String get verify => Tr.t('auth_verify', S.current.auth_verify);

  /// auth 4 — account created
  static String get registerSuccessTitle => Tr.t(
    'auth_register_success_title',
    S.current.auth_register_success_title,
  );
  static String get continueAction =>
      Tr.t('auth_continue', S.current.auth_continue);

  /// auth 5 — forgot password
  static String get forgotTitle =>
      Tr.t('auth_forgot_title', S.current.auth_forgot_title);
  static String get forgotSubtitle =>
      Tr.t('auth_forgot_subtitle', S.current.auth_forgot_subtitle);
  static String get sendCode =>
      Tr.t('auth_send_code', S.current.auth_send_code);

  /// auth 6 / 7 — reset
  static String get resetTitle =>
      Tr.t('auth_reset_title', S.current.auth_reset_title);
  static String get resetSubtitle =>
      Tr.t('auth_reset_subtitle', S.current.auth_reset_subtitle);
  static String get newPassword =>
      Tr.t('auth_new_password', S.current.auth_new_password);
  static String get change => Tr.t('auth_change', S.current.auth_change);

  static String get errorGeneric =>
      Tr.t('auth_error_generic', S.current.auth_error_generic);

  /// The 401 prompt. TWO of them, because the two ways to arrive at one
  /// are different facts about the reader: a customer whose token the
  /// server no longer accepts was signed out and needs telling, and a
  /// visitor who never signed in was not.
  static String get sessionExpiredTitle =>
      Tr.t('auth_session_expired_title', S.current.auth_session_expired_title);
  static String get sessionExpiredMessage => Tr.t(
    'auth_session_expired_message',
    S.current.auth_session_expired_message,
  );
  static String get signInRequiredTitle => Tr.t(
    'auth_sign_in_required_title',
    S.current.auth_sign_in_required_title,
  );
  static String get signInRequiredMessage => Tr.t(
    'auth_sign_in_required_message',
    S.current.auth_sign_in_required_message,
  );

  /// Browsing without an account. Deliberately «تصفح» — BROWSE, not
  /// "continue": on this server a guest can look and nothing else, and
  /// a word that promises a journey promises a cart with it.
  static String get continueAsGuest =>
      Tr.t('auth_continue_as_guest', S.current.auth_continue_as_guest);

  /// The rule between the sign-in bar and the guest link. Says what the
  /// gap means — two ways in, not one action and a stray link under it.
  static String get or => Tr.t('auth_or', S.current.auth_or);

  /// The tenant turned phone sign-in off and turned something else on.
  ///
  /// The app draws ONE identifier field and it is a phone number, so
  /// there is nothing honest to show — better a sentence than a form
  /// whose every submission is a 422 under `type`. See
  /// `AuthFlow.supportsIdentifier`.
  static String get identifierUnsupported => Tr.t(
    'auth_identifier_unsupported',
    S.current.auth_identifier_unsupported,
  );
}
