import '../../../generated/l10n.dart';
import '../tr.dart';

/// Strings for the `change_password_` ARB prefix family — call sites read
/// these through [ChangePasswordStrings] instead of `Tr.t` directly.
class ChangePasswordStrings {
  ChangePasswordStrings._();

  static String get currentLabel => Tr.t(
    'change_password.current_label',
    S.current.change_password_current_label,
  );

  static String get currentHint => Tr.t(
    'change_password.current_hint',
    S.current.change_password_current_hint,
  );

  static String get newLabel => Tr.t(
    'change_password.new_label',
    S.current.change_password_new_label,
  );

  static String get confirmLabel => Tr.t(
    'change_password.confirm_label',
    S.current.change_password_confirm_label,
  );

  static String get sameAsCurrent => Tr.t(
    'change_password.same_as_current',
    S.current.change_password_same_as_current,
  );
}
