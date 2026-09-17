import 'package:flutter/material.dart';

/// Drops server-sent field messages when the reading language changes.
///
/// ## Why they cannot simply be re-translated
///
/// A message this app raises itself is a KEY, resolved at build time, so
/// it turns Arabic with everything else. A message the SERVER raised is
/// finished prose: `Accept-Language` goes out with the request and the
/// answer comes back already in that language, with no key and nothing
/// to re-resolve.
///
/// So a customer who fails to sign in, then taps the language toggle,
/// is left with one English sentence sitting under a field on an
/// otherwise Arabic form. Nothing local can fix it — the only source of
/// the Arabic wording is the server, and asking again would mean
/// re-sending the failed request purely to re-read its error.
///
/// Clearing it is the honest option: a message in the wrong language is
/// worse than no message, the field is still marked, and the next
/// attempt fetches the sentence in the language the customer is now
/// reading.
///
/// See `docs/api-contract.md` §14 for the shape these arrive in, and
/// the note there about asking the backend for stable error CODES —
/// which is what would let this become a real translation instead of a
/// clear.
mixin ServerErrorsClearOnLocaleChange<T extends StatefulWidget> on State<T> {
  Locale? _locale;

  /// Set every server-sent message on this screen back to null.
  void clearServerErrors();

  /// Drops one server message the moment its input is edited.
  ///
  /// This is not cosmetic. A `TextFieldBehavior.errorText` is returned
  /// by `formValidator` BEFORE any other check, so while one is set
  /// `Form.validate()` is false no matter what the field now contains —
  /// and a submit that begins with `if (!validate()) return` does
  /// nothing at all. A server message left in place after the customer
  /// corrects the value does not just look stale: it wedges the button.
  ///
  /// Pass the current value and a setter; nothing happens when there is
  /// no message to clear, so this is safe to call on every keystroke.
  void clearOnEdit(String? current, VoidCallback clear) {
    if (current == null) return;
    setState(clear);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.maybeLocaleOf(context);
    // Not on the FIRST call: there is no previous language to have
    // changed from, and nothing has been fetched yet.
    if (_locale != null && _locale != locale) {
      setState(clearServerErrors);
    }
    _locale = locale;
  }
}
