import '../../../core/error/app_exception.dart';

/// The Saudi **short national address** — four letters then four
/// digits, e.g. `RCTB4359`.
///
/// A SHORTCUT, not a gate. `POST /api/addresses/lookup` turns one into
/// the full national address and a map pin, so a customer types eight
/// characters instead of six fields — but plenty do not know theirs,
/// and the manual form has to work without it. That is why every
/// failure here reads as a NOTE rather than an error: the form below
/// is already complete and usable.
class ShortAddress {
  const ShortAddress._();

  /// Four letters, four digits. Checked on the CLIENT before calling —
  /// the endpoint is rate-limited and every call costs against a paid
  /// third-party quota, so a malformed code must never reach it.
  static final _shape = RegExp(r'^[A-Za-z]{4}[0-9]{4}$');

  static const length = 8;

  static bool isWellFormed(String value) => _shape.hasMatch(value.trim());

  /// What a failed lookup should SAY.
  ///
  /// Three outcomes, and two of them mean the same thing to the
  /// customer: type it yourself. A 404 is a code that resolves to no
  /// building inside Saudi Arabia; anything else — a 503 from the
  /// lookup service being unconfigured or down, which is what the live
  /// dev server answers today, or a transport failure — is the service
  /// rather than the code. A 429 is the only one worth waiting on.
  ///
  /// Read off [AppException.code], which carries the HTTP status as a
  /// string; there is no `statusCode` on the sealed type.
  static ShortAddressOutcome outcomeFor(AppException error) =>
      switch (error.code) {
        '429' => ShortAddressOutcome.tooFast,
        '404' => ShortAddressOutcome.notFound,
        _ => ShortAddressOutcome.unavailable,
      };
}

/// Why a lookup did not fill the form in.
enum ShortAddressOutcome {
  /// No building of that code inside Saudi Arabia.
  notFound,

  /// The lookup service is not configured, or is unreachable.
  unavailable,

  /// Rate-limited. Worth waiting; everything else is worth typing.
  tooFast,
}
