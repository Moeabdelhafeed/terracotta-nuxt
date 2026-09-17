import '../../../generated/l10n.dart';
import '../tr.dart';

/// Strings for the `otp_field` prefix family — alphanumeric-mode OTP
/// validation messages (digit-mode lives in `ValidatorStrings`).
class OtpFieldStrings {
  OtpFieldStrings._();

  static String mustBeNChars(int length) => Tr.t(
    'otp_field.must_be_n_chars',
    S.current.otp_field_must_be_n_chars(length),
  );
}
