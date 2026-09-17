import '../../../core/localization/strings/auth_strings.dart';
import '../../../shared/module/toast/global_toast.dart';

/// The verification code, when the SERVER hands it back.
///
/// Dev and staging answer `register`, `login` and `send-otp` with the
/// code in the body — `"otp": "123456"` — so a tester on a number that
/// receives no SMS can still finish the flow. Production sends it and
/// does not repeat it, which is why nothing in the app may DEPEND on
/// this: every entry point calls [show] and [show] says nothing when
/// there is nothing to say.
///
/// ## Why a toast that does not go away
///
/// The code is the one thing on screen the reader has to COPY, one
/// digit at a time, into six boxes — and a toast timed to how long it
/// takes to read is gone before the third. So it is `persistent` with
/// a close button: it stays until it is dismissed, and dismissing it
/// is the reader saying they have the number.
abstract final class DevOtp {
  /// The toast on screen now, so a second code replaces it rather than
  /// stacking a stale one over the fresh one.
  static ToastHandle? _showing;

  /// Shows [otp] if there is one. Answers whether anything was shown.
  static bool show(String? otp) {
    final code = (otp ?? '').trim();
    if (code.isEmpty) return false;

    _showing?.dismiss();
    _showing = GlobalToast.show(
      title: AuthStrings.devOtpTitle,
      description: code,
      type: ToastType.info,
      // NO TIMER. See the class doc — this is a number to be copied,
      // not a message to be read.
      persistent: true,
      showCloseButton: true,
      onDismiss: () => _showing = null,
    );
    return true;
  }

  /// Reads the code out of a raw `data` map — `send-otp` and
  /// `verify-otp` answer `Map<String, dynamic>` rather than a model.
  static bool showFrom(Map<String, dynamic>? data) =>
      show(data?['otp'] as String?);

  /// Takes it off the screen — after the code has been accepted, when
  /// leaving it up would be an old number over a finished flow.
  static void clear() {
    _showing?.dismiss();
    _showing = null;
  }
}
