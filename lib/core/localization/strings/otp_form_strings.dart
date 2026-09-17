import '../../../generated/l10n.dart';
import '../tr.dart';

/// Strings for the OTP form flow, grouped under the `otp_form_` key prefix —
/// call sites go through this class instead of `Tr.t` / `S.current` directly.
class OtpFormStrings {
  OtpFormStrings._();

  static String sentTo(String destination) =>
      Tr.t('otp_form.sent_to', S.current.otp_form_sent_to(destination));
  static String get noCode =>
      Tr.t('otp_form.no_code', S.current.otp_form_no_code);
  static String get resend =>
      Tr.t('otp_form.resend', S.current.otp_form_resend);
  static String resendIn(int seconds) =>
      Tr.t('otp_form.resend_in', S.current.otp_form_resend_in(seconds));
}
