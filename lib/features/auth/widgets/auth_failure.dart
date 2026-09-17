import '../../../core/error/app_exception.dart';
import '../../../core/localization/strings/api_status_strings.dart';
import '../../../core/localization/strings/auth_strings.dart';
import '../../../shared/module/toast/global_toast.dart';

/// One place deciding what a failed auth call LOOKS like.
///
/// The rule is that a failure is shown ONCE, in the place that explains
/// it best. This backend keys validation errors by the input that failed
/// — a wrong password under `password`, an unknown account under
/// `identifier`, a bad code under `otp` — and those belong under their
/// own field, where the customer is already looking. Everything else is
/// about the request rather than anything they typed, and gets a toast.
///
/// So a screen reads its field messages off the exception, then calls
/// this; when the server named a field, this deliberately does nothing.
void showAuthFailure(AppException error) {
  if (error.hasFieldErrors) return;
  GlobalToast.error(_titleFor(error), description: _descriptionFor(error));
}

String _titleFor(AppException error) => switch (error) {
  // Timeouts and cancellations classify as network failures too — there
  // is no separate subtype for them.
  NetworkException() => ApiStatusStrings.networkError,
  _ => AuthStrings.errorGeneric,
};

/// The server's own sentence, when it sent one worth reading.
///
/// A rate limit is the case this matters for: "Too many attempts" tells
/// the customer to wait, and the generic title alone would have them
/// pressing the button again into a limiter that is counting.
String? _descriptionFor(AppException error) {
  final message = error.message.trim();
  if (message.isEmpty) return null;
  // Transport failures carry Dio's own wording, which names hosts and
  // socket errors and means nothing to a customer.
  if (error is NetworkException) return null;
  return message;
}
