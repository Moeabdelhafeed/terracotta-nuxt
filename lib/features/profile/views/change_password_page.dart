import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/strings/auth_strings.dart';
import '../../../core/localization/strings/profile_strings.dart';
import '../../../core/tokens/extensions.dart';
import '../../../core/types/result.dart';
import '../../../data/api/calls/auth_apis.dart';
import '../../../shared/common/text_form_fields/text_form_fields.dart';
import '../../../shared/module/buttons/global_filled_button.dart';
import '../../../shared/module/container/global_container.dart';
import '../../../shared/module/dialog/global_dialog.dart';
import '../../../shared/module/scrollable/global_scrollable.dart';
import '../../../shared/module/toast/global_toast.dart';
import '../../_shared/screen_entrance.dart';
import '../../_shared/server_error_locale.dart';
import '../../_shared/terracotta_cta_style.dart';
import '../../_shared/terracotta_page_bar.dart';
import '../../auth/widgets/auth_failure.dart';

/// «تغيير كلمة السر» from inside the account.
///
/// `POST /api/change-password`, with three fields: the current one, the
/// new one, and the new one again.
///
/// The server answers a refusal KEYED TO THE FIELD — verified live:
///
///   * a wrong current password → `{"old_password": ["Old password is
///     incorrect."]}`
///   * a confirmation that does not match → `{"password": ["The
///     password field confirmation does not match."]}`
///
/// so each renders under the input the server blamed rather than as one
/// alert over a form the customer then has to search.
///
/// **`old_password` is optional on the wire** — a social-only account
/// setting its first password sends none. This tenant has no social
/// provider enabled, so the field is required here; `has_password` on
/// the session is what would relax it.
class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({this.change, super.key});

  /// The call to make — the seam a widget test needs, so it can answer
  /// without a server. Null in the app.
  ///
  /// `AppException`, NOT `dynamic`: `fieldError` is an EXTENSION on
  /// `AppException` and extensions resolve statically, so a dynamic
  /// error silently cannot find it — `NoSuchMethodError` at runtime,
  /// inside an async gap, where it left the field's error slot null and
  /// looked like the server had sent nothing.
  final AsyncResult<Map<String, dynamic>> Function({
    required String password,
    required String passwordConfirmation,
    String? oldPassword,
    CancelToken? cancelToken,
  })?
  change;

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage>
    with ServerErrorsClearOnLocaleChange<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _cancel = CancelToken();

  bool _busy = false;

  /// Keyed to the input the SERVER blamed, not to a guess.
  String? _currentError;
  String? _passwordError;

  @override
  void dispose() {
    _cancel.cancel('change password closed');
    _current.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  void clearServerErrors() {
    _currentError = null;
    _passwordError = null;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // A password change is not undoable from the customer's side and
    // signs nobody out, so the dialog says what it WILL do rather than
    // asking whether they meant it.
    final confirmed = await GlobalDialog.confirm(
      context: context,
      title: ProfileStrings.changePassword,
      message: ProfileStrings.changePasswordMessage,
      confirmText: AuthStrings.change,
      icon: Icons.lock_rounded,
    );
    if (!confirmed || !mounted) return;

    setState(() {
      _busy = true;
      _currentError = null;
      _passwordError = null;
    });

    final call = widget.change ?? _defaultChange;
    final result = await call(
      password: _password.text,
      passwordConfirmation: _confirm.text,
      oldPassword: _current.text,
      cancelToken: _cancel,
    );
    if (!mounted) return;

    switch (result) {
      case Failure(:final error):
        setState(() {
          _busy = false;
          _currentError = error.fieldError('old_password');
          _passwordError = error.fieldError('password');
        });
        // Only when the server did NOT name a field — otherwise the
        // sentence is already under the input it belongs to.
        showAuthFailure(error);
      case Success():
        setState(() => _busy = false);
        GlobalToast.success(ProfileStrings.passwordChanged);
        // The token SURVIVES a password change — verified live, the
        // session keeps working — so this goes back to the account
        // rather than to sign-in.
        if (context.canPop()) context.pop();
    }
  }

  static AsyncResult<Map<String, dynamic>> _defaultChange({
    required String password,
    required String passwordConfirmation,
    String? oldPassword,
    CancelToken? cancelToken,
  }) => AuthApis.changePassword(
    password: password,
    passwordConfirmation: passwordConfirmation,
    oldPassword: oldPassword,
    cancelToken: cancelToken,
  );

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    return Scaffold(
      backgroundColor: context.backgroundColors.scaffoldBackground,
      appBar: TerracottaPageBar(title: ProfileStrings.changePassword),
      body: Form(
        key: _formKey,
        child: GlobalScrollable(
          child: GlobalContainer.shell(
            padding: EdgeInsetsDirectional.fromSTEB(
              spacing.md,
              spacing.md,
              spacing.md,
              spacing.xxl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              // STAGGERED as the page settles — the rows arrive one after
              // another rather than the whole block appearing at once.
              children: ScreenEntrance.stage([
                _Labelled(
                  label: ProfileStrings.currentPassword,
                  child: PasswordField(
                    controller: _current,
                    // NOT `create`: the current password is whatever it
                    // already is, and holding it to today's strength
                    // rules would refuse an older one the server still
                    // accepts.
                    hint: ProfileStrings.currentPasswordHint,
                    required: false,
                    errorText: _currentError,
                    onChanged: (_) =>
                        clearOnEdit(_currentError, () => _currentError = null),
                    textInputAction: TextInputAction.next,
                  ),
                ),
                SizedBox(height: spacing.md),
                _Labelled(
                  label: AuthStrings.newPassword,
                  child: PasswordField(
                    controller: _password,
                    mode: PasswordFieldMode.create,
                    // THE CONFIRM BOX TOO — see `RegisterPage`. ✨
                    // fills this field, and without the linked
                    // controller the customer cannot complete the one
                    // below it.
                    confirmController: _confirm,
                    hint: AuthStrings.enterPasswordHint,
                    required: false,
                    errorText: _passwordError,
                    onChanged: (_) => clearOnEdit(
                      _passwordError,
                      () => _passwordError = null,
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                ),
                SizedBox(height: spacing.md),
                _Labelled(
                  label: AuthStrings.confirmPassword,
                  child: PasswordField(
                    controller: _confirm,
                    mode: PasswordFieldMode.confirm,
                    matchController: _password,
                    hint: AuthStrings.enterConfirmPasswordHint,
                    required: false,
                    onSubmitted: (_) => unawaited(_submit()),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
      // PINNED at the foot, like every other confirm in the app.
      //
      // In the column it sat under three password boxes and moved with
      // the keyboard — on a short phone the reader typed the last field
      // and the button they were reaching for had scrolled away.
      bottomNavigationBar: Material(
        color: context.backgroundColors.scaffoldBackground,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsetsDirectional.fromSTEB(
              spacing.md,
              spacing.sm,
              spacing.md,
              spacing.sm,
            ),
            child: GlobalFilledButton(
              text: AuthStrings.change,
              isLoading: _busy,
              onPressed: () => unawaited(_submit()),
              style: terracottaCtaStyle(showArrow: false),
            ),
          ),
        ),
      ),
    );
  }
}

/// A static header ABOVE a field.
///
/// Drawn here because the module does not: `GlobalTextField.identifier`
/// reads like a header and is only ever used as the floating label
/// INSIDE the box, so passing it put the same words in the box the hint
/// was already in. Three password boxes in a column need naming from
/// outside — the hints alone do not distinguish them once one is
/// filled.
class _Labelled extends StatelessWidget {
  const _Labelled({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: context.textTheme.labelLarge?.copyWith(
          color: context.textColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
      SizedBox(height: context.spacing.xs),
      child,
    ],
  );
}
