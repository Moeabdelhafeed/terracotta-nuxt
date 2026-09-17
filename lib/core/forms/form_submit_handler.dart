import 'package:flutter/material.dart';

import '../../shared/module/buttons/global_filled_button.dart';
import '../error/app_exception.dart';
import '../types/result.dart';

/// Validate-then-submit helpers for forms.
///
/// Two entry points:
/// 1. **[submitFormAction]** — a standalone `VoidCallback` factory for
///    quick use with any button (`FilledButton`, `TextButton`, …).
/// 2. **[FormSubmitButton]** — a ready-made button widget that owns its
///    own submitting state (useful when you don't have a controller).
///
/// If you already use a `FormSubmissionCubit`, prefer its
/// `validateAndSubmit` — these helpers target stateless /
/// StatefulWidget forms without a dedicated cubit.

/// Create an `onPressed` callback that:
///  1. Validates the form attached to [formKey].
///  2. Calls `state.save()`.
///  3. Runs [onSubmit].
///  4. Toggles [onLoading] around the whole thing (even on error).
///
/// Returns `null` instead of a callback when [enabled] is false —
/// pass the result straight to a button's `onPressed`:
/// ```dart
/// FilledButton(
///   onPressed: submitFormAction(
///     enabled: !loading,
///     formKey: _formKey,
///     onSubmit: () => api.login(...),
///     onLoading: (v) => setState(() => loading = v),
///   ),
///   child: Text('Sign in'),
/// );
/// ```
VoidCallback? submitFormAction({
  required GlobalKey<FormState> formKey,
  required Future<void> Function() onSubmit,
  ValueChanged<bool>? onLoading,
  VoidCallback? onInvalid,
  bool enabled = true,
}) {
  if (!enabled) return null;
  return () async {
    final state = formKey.currentState;
    if (state == null || !state.validate()) {
      onInvalid?.call();
      return;
    }
    state.save();
    onLoading?.call(true);
    try {
      await onSubmit();
    } finally {
      onLoading?.call(false);
    }
  };
}

/// [Result]-returning variant of [submitFormAction] — for `onSubmit`
/// callbacks that use `AsyncResult<T>`. The [onResult] callback is
/// invoked with the final [Result] so you can pattern-match and update
/// UI. Returns `null` for the invalid-form case.
VoidCallback? submitFormActionResult<T>({
  required GlobalKey<FormState> formKey,
  required Future<Result<T, AppException>> Function() onSubmit,
  required ValueChanged<Result<T, AppException>> onResult,
  ValueChanged<bool>? onLoading,
  VoidCallback? onInvalid,
  bool enabled = true,
}) {
  if (!enabled) return null;
  return () async {
    final state = formKey.currentState;
    if (state == null || !state.validate()) {
      onInvalid?.call();
      return;
    }
    state.save();
    onLoading?.call(true);
    try {
      final result = await onSubmit();
      onResult(result);
    } catch (e, st) {
      onResult(Result.failure(AppException.fromError(e, st)));
    } finally {
      onLoading?.call(false);
    }
  };
}

/// Submit button that:
///  - Validates [formKey] on press.
///  - Tracks submitting state internally (no parent setState needed).
///  - Flips [GlobalFilledButton.isLoading] while the future is in flight
///    (shimmer / indicator handled by the button itself).
///  - Refuses to submit while disabled or already submitting.
///
/// ```dart
/// FormSubmitButton(
///   formKey: _formKey,
///   onSubmit: () => api.register(...),
///   text: 'Create account',
/// );
/// ```
class FormSubmitButton extends StatefulWidget {
  const FormSubmitButton({
    super.key,
    required this.formKey,
    required this.onSubmit,
    required this.text,
    this.style,
    this.disabledStyle,
    this.loadingStyle,
    this.enabled = true,
    this.onInvalid,
    this.shrinkWidth = false,
  });

  final GlobalKey<FormState> formKey;
  final Future<void> Function() onSubmit;
  final String text;

  /// Base button style — forwarded to [GlobalFilledButton.style].
  final ButtonStateStyle? style;

  /// Style used while the button is disabled.
  final ButtonStateStyle? disabledStyle;

  /// Style used while submitting — controls loading indicator type,
  /// shimmer colors, etc.
  final ButtonLoadingStyle? loadingStyle;

  /// When false, the button is disabled (no taps).
  final bool enabled;

  /// Called when the user taps while the form is invalid.
  final VoidCallback? onInvalid;

  /// Forwarded to [GlobalFilledButton.shrinkWidth].
  final bool shrinkWidth;

  @override
  State<FormSubmitButton> createState() => _FormSubmitButtonState();
}

class _FormSubmitButtonState extends State<FormSubmitButton> {
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    return GlobalFilledButton(
      text: widget.text,
      onPressed: _submitting ? null : _submit,
      enabled: widget.enabled,
      isLoading: _submitting,
      style: widget.style,
      disabledStyle: widget.disabledStyle,
      loadingStyle: widget.loadingStyle,
      shrinkWidth: widget.shrinkWidth,
    );
  }

  Future<void> _submit() async {
    final state = widget.formKey.currentState;
    if (state == null || !state.validate()) {
      widget.onInvalid?.call();
      return;
    }
    state.save();
    setState(() => _submitting = true);
    try {
      await widget.onSubmit();
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
