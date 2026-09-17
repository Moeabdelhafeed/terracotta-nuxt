import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show TextInput;

import '../../../../core/localization/strings/change_password_strings.dart';
import '../../../../core/tokens/extensions.dart';
import '../../../../core/utils/validators/validators.dart';
import '../../../module/text_field/global_text_field.dart';
import 'password_field.dart';

/// The value a [ChangePasswordForm] emits.
@immutable
class ChangePasswordFormData {
  const ChangePasswordFormData({
    this.current = '',
    this.password = '',
    required this.isValid,
  });

  /// The current password — empty when [ChangePasswordForm.requireCurrent]
  /// is off.
  final String current;

  /// The NEW password.
  final String password;

  /// Current valid + new passes complexity + differs from current +
  /// confirm matches.
  final bool isValid;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChangePasswordFormData &&
          other.current == current &&
          other.password == password &&
          other.isValid == isValid;

  @override
  int get hashCode => Object.hash(current, password, isValid);

  @override
  String toString() => 'ChangePasswordFormData(valid: $isValid)';
}

/// The change-password composite — current + new + confirm in one
/// [AutofillGroup]:
///
///  * Current password gets `AutofillHints.password` (managers FILL it),
///    new + confirm get `newPassword` (managers offer to GENERATE).
///  * The new password must pass the create-complexity rules AND differ
///    from the current one (localized error).
///  * Confirm live-matches the new password.
///  * Focus chains current → new → confirm; done on the last field fires
///    [onSubmit].
///
/// Flows that re-authenticated elsewhere (OTP reset, fresh-session
/// requirement) set [requireCurrent] to false and get just the new pair —
/// which also makes this the RESET-password form.
///
/// ```dart
/// ChangePasswordForm(
///   onSubmit: (d) => cubit.changePassword(d.current, d.password),
/// )
/// // After success:
/// ChangePasswordForm.finishAutofill();
/// ```
class ChangePasswordForm extends StatefulWidget {
  const ChangePasswordForm({
    super.key,
    this.requireCurrent = true,
    this.showConfirm = true,
    this.currentController,
    this.passwordController,
    this.confirmController,
    this.onChanged,
    this.onSubmit,
    this.enabled = true,
    this.deferToParentForm = true,
    this.validationMode = ValidationMode.onInteraction,
    this.showStrengthBar = true,
    this.checkBreached = false,
    this.style,
  });

  /// Ask for the current password first. Off for flows that already
  /// re-authenticated (OTP / email reset link) — the form becomes a
  /// reset-password pair.
  final bool requireCurrent;

  /// Confirm re-entry of the new password.
  final bool showConfirm;

  /// Controllers are optional — the form owns them when absent.
  final TextEditingController? currentController;
  final TextEditingController? passwordController;
  final TextEditingController? confirmController;

  /// Parsed state on every change.
  final ValueChanged<ChangePasswordFormData>? onChanged;

  /// Keyboard done on the LAST field.
  final ValueChanged<ChangePasswordFormData>? onSubmit;

  final bool enabled;

  /// Keep `true` inside a `Form`; `false` for standalone screens.
  final bool deferToParentForm;

  final ValidationMode validationMode;

  /// Strength bar under the new password.
  final bool showStrengthBar;

  /// Have-I-Been-Pwned check on the new password (k-anonymity, fail-open).
  final bool checkBreached;

  /// Visual override applied to every field.
  final TextFieldStyle? style;

  /// After a SUCCESSFUL change: commits the autofill context so the OS
  /// offers to update the saved credentials.
  static void finishAutofill() => TextInput.finishAutofillContext();

  @override
  State<ChangePasswordForm> createState() => _ChangePasswordFormState();
}

class _ChangePasswordFormState extends State<ChangePasswordForm> {
  TextEditingController? _ownedCurrent, _ownedPassword, _ownedConfirm;
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  TextEditingController get _current =>
      widget.currentController ?? (_ownedCurrent ??= TextEditingController());
  TextEditingController get _password =>
      widget.passwordController ?? (_ownedPassword ??= TextEditingController());
  TextEditingController get _confirm =>
      widget.confirmController ?? (_ownedConfirm ??= TextEditingController());

  @override
  void dispose() {
    _ownedCurrent?.dispose();
    _ownedPassword?.dispose();
    _ownedConfirm?.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  /// Create-complexity rules + must-differ-from-current.
  String? _newPasswordValidator(String? value) {
    final base = Validators.validateCreatePassword(value);
    if (base != null) return base;
    if (widget.requireCurrent && value == _current.text) {
      return ChangePasswordStrings.sameAsCurrent;
    }
    return null;
  }

  bool get _isValid {
    final currentOk =
        !widget.requireCurrent ||
        Validators.validatePassword(_current.text) == null;
    final newOk = _newPasswordValidator(_password.text) == null;
    final confirmOk =
        !widget.showConfirm ||
        (_confirm.text == _password.text && _password.text.isNotEmpty);
    return currentOk && newOk && confirmOk;
  }

  ChangePasswordFormData _currentData() => ChangePasswordFormData(
    current: widget.requireCurrent ? _current.text : '',
    password: _password.text,
    isValid: _isValid,
  );

  void _emit() => widget.onChanged?.call(_currentData());

  @override
  Widget build(BuildContext context) {
    final gap = SizedBox(height: context.spacing.md);
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.requireCurrent) ...[
            PasswordField(
              controller: _current,
              identifier: ChangePasswordStrings.currentLabel,
              hint: ChangePasswordStrings.currentHint,
              enabled: widget.enabled,
              deferToParentForm: widget.deferToParentForm,
              validationMode: widget.validationMode,
              textInputAction: TextInputAction.next,
              style: widget.style,
              onChanged: (_) => _emit(),
              onSubmitted: (_) => _passwordFocus.requestFocus(),
            ),
            gap,
          ],
          PasswordField(
            controller: _password,
            focusNode: _passwordFocus,
            mode: PasswordFieldMode.create,
            identifier: ChangePasswordStrings.newLabel,
            validator: _newPasswordValidator,
            showStrengthBar: widget.showStrengthBar,
            checkBreached: widget.checkBreached,
            // Generate fills the confirm field too — what managers do.
            confirmController: widget.showConfirm ? _confirm : null,
            enabled: widget.enabled,
            deferToParentForm: widget.deferToParentForm,
            validationMode: widget.validationMode,
            textInputAction: widget.showConfirm
                ? TextInputAction.next
                : TextInputAction.done,
            style: widget.style,
            onChanged: (_) => _emit(),
            onSubmitted: (_) => widget.showConfirm
                ? _confirmFocus.requestFocus()
                : widget.onSubmit?.call(_currentData()),
          ),
          if (widget.showConfirm) ...[
            gap,
            PasswordField(
              controller: _confirm,
              focusNode: _confirmFocus,
              mode: PasswordFieldMode.confirm,
              matchController: _password,
              identifier: ChangePasswordStrings.confirmLabel,
              enabled: widget.enabled,
              deferToParentForm: widget.deferToParentForm,
              validationMode: widget.validationMode,
              textInputAction: TextInputAction.done,
              style: widget.style,
              onChanged: (_) => _emit(),
              onSubmitted: (_) => widget.onSubmit?.call(_currentData()),
            ),
          ],
        ],
      ),
    );
  }
}
