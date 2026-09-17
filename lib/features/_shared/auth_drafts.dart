import 'package:flutter/widgets.dart';

/// A value being typed, shared across the auth screens.
///
/// Sign-in, register and forgot-password ask for the same things, and a
/// customer who typed one on any of them should not retype it on the
/// next — in EITHER direction.
///
/// ## Why not a route `extra`
///
/// An `extra` only travels forwards. Going back is a pop, and the pop
/// that matters most here is the BACK SWIPE, which carries no result at
/// all — there is nowhere to hang a returned value. So a number edited
/// on forgot-password could never find its way home to sign-in.
///
/// A draft both screens read and write is bidirectional by
/// construction, and behaves the same whether the reader taps back,
/// swipes back, or is popped programmatically.
///
/// ## Lifetime
///
/// It lives as long as the FLOW, not the app. [AuthDrafts.clear] runs
/// when auth completes, so the next person to open the app is not
/// handed the last one's details.
class AuthFieldDraft {
  AuthFieldDraft._();

  /// The current draft. Empty when nobody has typed anything.
  final ValueNotifier<String> value = ValueNotifier<String>('');

  /// Seeds a field from the draft — or the draft from the field — then
  /// keeps the two in step, BOTH WAYS.
  ///
  /// Returns a callback that unbinds it. A controller outlives its
  /// widget only if someone forgets to.
  ///
  /// Both directions matter, and the second one is easy to miss. A
  /// screen that is no longer on top still holds its own controller: if
  /// it only ever WRITES to the draft, an edit made on the screen above
  /// never reaches it, and worse, its own next notification writes the
  /// stale value straight back over that edit. Sign-in kept resetting a
  /// number corrected on forgot-password for exactly that reason.
  VoidCallback bind(TextEditingController controller) {
    // Whichever side already holds the value wins, and a field that has
    // one is never overwritten — a seed must not clobber typing.
    if (controller.text.isEmpty) {
      if (value.value.isNotEmpty) controller.text = value.value;
    } else if (value.value != controller.text) {
      value.value = controller.text;
    }

    // Each guard is what stops the pair looping: a write only happens
    // when the two genuinely differ, so the echo it provokes is a no-op.
    void toDraft() {
      if (value.value != controller.text) value.value = controller.text;
    }

    void toField() {
      if (controller.text != value.value) controller.text = value.value;
    }

    controller.addListener(toDraft);
    value.addListener(toField);

    return () {
      controller.removeListener(toDraft);
      value.removeListener(toField);
    };
  }

  /// Forget it. Call when the flow ends — never between its steps.
  void clear() => value.value = '';
}

/// The drafts the auth flow carries between its screens.
abstract final class AuthDrafts {
  /// Asked for on sign-in, register and forgot-password.
  static final phone = AuthFieldDraft._();

  /// Asked for on sign-in and register.
  ///
  /// In MEMORY only, for as long as the flow lasts — the same exposure
  /// the `TextEditingController` behind the field already has. It is
  /// never written to storage and never logged, and [clear] wipes it
  /// the moment auth completes. Do not persist it or widen its life.
  static final password = AuthFieldDraft._();

  /// Whether the password is currently REVEALED.
  ///
  /// Carried with the value, because the two belong together: someone
  /// who unhid their password to check it on sign-in has not asked to
  /// hide it again by tapping "create an account". The module owns the
  /// toggle, so this is what carries the choice between screens.
  static final passwordVisible = ValueNotifier<bool>(false);

  /// Forget everything. Signed in, registered, or password reset —
  /// never between the steps of a flow.
  static void clear() {
    phone.clear();
    password.clear();
    // Back to hidden. Leaving it revealed would show the NEXT person's
    // password in clear text on a field they have not touched.
    passwordVisible.value = false;
  }
}
