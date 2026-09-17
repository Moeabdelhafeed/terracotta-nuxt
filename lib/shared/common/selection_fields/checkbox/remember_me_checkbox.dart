import 'package:flutter/material.dart';

import '../../../../core/localization/strings/auth_strings.dart';
import '../../../module/checkbox/global_checkbox.dart';

/// The login-form one-liner — a labeled "Remember me" checkbox with the
/// localized ARB label (en + ar). Pair with `LoginForm`.
class RememberMeCheckbox extends StatelessWidget {
  const RememberMeCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.style = const CheckboxStyle(),
    this.labelStyle,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool enabled;
  final CheckboxStyle style;

  /// The label's type. Null takes the checkbox's own.
  ///
  /// Passed through for a caller that shares a LINE with something
  /// else — the sign-in screen sets it beside «نسيت كلمة السر», and
  /// the two have to read as the same weight of thing.
  final TextStyle? labelStyle;

  @override
  Widget build(BuildContext context) {
    // Locale dependency — labels resolve via Tr/S (static reads), so
    // register explicitly or a const-constructed instance never
    // rebuilds on a language flip.
    Localizations.maybeLocaleOf(context);
    return GlobalCheckbox.simple(
      value: value,
      onChanged: onChanged,
      enabled: enabled,
      style: style,
      label: AuthStrings.rememberMe,
      labelStyle: labelStyle,
    );
  }
}
