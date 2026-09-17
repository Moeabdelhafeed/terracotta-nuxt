import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../error/app_exception.dart';
import '../localization/strings/validator_strings.dart';
import '../types/result.dart';

/// Sealed lifecycle of a single form submission. UI binds via
/// `BlocBuilder<FormSubmissionCubit, FormSubmissionState>` and
/// pattern-matches.
///
/// ```dart
/// switch (state) {
///   FormIdle()                 => SubmitButton(onPressed: cubit.submit),
///   FormSubmitting()           => const SubmitButton.loading(),
///   FormSuccess()              => const SubmitButton.done(),
///   FormFailure(:final error)  => SubmitButton.error(error.message),
/// }
/// ```
sealed class FormSubmissionState {
  const FormSubmissionState();
}

class FormIdle extends FormSubmissionState {
  const FormIdle();
}

class FormSubmitting extends FormSubmissionState {
  const FormSubmitting();
}

class FormSuccess extends FormSubmissionState {
  const FormSuccess();
}

class FormFailure extends FormSubmissionState {
  const FormFailure(this.error);
  final AppException error;
}

/// Form submission orchestration — replaces `FormMixin on
// ignore: unintended_html_in_doc_comment
/// GetxController`. Owns the `GlobalKey<FormState>` and emits
/// lifecycle states around a submit action.
///
/// The cubit owns the form key so a single source of truth controls
/// validation / save / reset. The widget binds to the same key:
///
/// ```dart
/// final cubit = context.read<FormSubmissionCubit>();
///
/// Form(
///   key: cubit.formKey,
///   child: ...
/// );
///
/// FilledButton(
///   onPressed: () => cubit.validateAndSubmit(() async {
///     final r = await AuthApi.login(...);
///     r.onSuccess((_) => GoRouter.of(context).go('/home'));
///   }),
///   child: BlocSelector<FormSubmissionCubit, FormSubmissionState, bool>(
///     selector: (s) => s is FormSubmitting,
///     builder: (_, busy) => Text(busy ? 'Submitting…' : 'Submit'),
///   ),
/// );
/// ```
class FormSubmissionCubit extends Cubit<FormSubmissionState> {
  FormSubmissionCubit() : super(const FormIdle());

  /// Attach to the `Form` widget via `key:`.
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  /// Validate, save, run [submit]. Emits `FormSubmitting` →
  /// `FormSuccess` / `FormFailure`.
  ///
  /// Returns `true` if validation passed AND [submit] completed
  /// without throwing.
  Future<bool> validateAndSubmit(Future<void> Function() submit) async {
    final s = formKey.currentState;
    if (s == null || !s.validate()) return false;
    s.save();

    emit(const FormSubmitting());
    try {
      await submit();
      if (!isClosed) emit(const FormSuccess());
      return true;
    } catch (e, st) {
      if (!isClosed) emit(FormFailure(AppException.fromError(e, st)));
      return false;
    }
  }

  /// [validateAndSubmit] variant for [Result]-returning actions.
  /// Returns the underlying [Result], or
  /// `Result.failure(ValidationException)` when the form itself is
  /// invalid.
  Future<Result<T, AppException>> validateAndSubmitResult<T>(
    Future<Result<T, AppException>> Function() submit, {
    String? invalidFormMessage,
  }) async {
    final s = formKey.currentState;
    if (s == null || !s.validate()) {
      final err = ValidationException(
        message: invalidFormMessage ?? ValidatorStrings.formInvalid,
      );
      if (!isClosed) emit(FormFailure(err));
      return Result.failure(err);
    }
    s.save();

    emit(const FormSubmitting());
    try {
      final result = await submit();
      if (!isClosed) {
        result
            .onSuccess((_) => emit(const FormSuccess()))
            .onFailure((e) => emit(FormFailure(e)));
      }
      return result;
    } catch (e, st) {
      final err = AppException.fromError(e, st);
      if (!isClosed) emit(FormFailure(err));
      return Result.failure(err);
    }
  }

  /// Reset the form's validation errors and field state.
  void resetForm() {
    formKey.currentState?.reset();
    emit(const FormIdle());
  }
}
