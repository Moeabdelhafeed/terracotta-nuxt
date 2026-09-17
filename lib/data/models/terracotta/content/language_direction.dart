/// Which way a `Language` reads — the `direction` discriminator on every
/// element of `GET /api/languages`.
///
/// The capture contains both wire values, `"ltr"` (en) and `"rtl"` (ar),
/// so this is a closed set today. [fromWire] still refuses to throw: a
/// locale the CMS adds with a typo'd, missing or null direction falls
/// back to [ltr], which lays the app out the wrong way round for that
/// one language instead of failing to parse the language list and
/// leaving the user with no picker at all.
enum LanguageDirection {
  /// Left-to-right. The fallback for anything unrecognised.
  ltr('ltr'),

  /// Right-to-left. `ar` in the live capture, and the API's default
  /// locale.
  rtl('rtl');

  const LanguageDirection(this.wire);

  /// The exact string the API sends for this direction.
  final String wire;

  /// Parse a wire value, falling back to [ltr] for null, absent, or
  /// unrecognised input. Never throws.
  static LanguageDirection fromWire(String? wire) {
    for (final direction in LanguageDirection.values) {
      if (direction.wire == wire) return direction;
    }
    return LanguageDirection.ltr;
  }

  /// True when this language needs `TextDirection.rtl`.
  bool get isRtl => this == LanguageDirection.rtl;
}

/// Serialize a [LanguageDirection] back to its wire string.
///
/// Referenced by `@JsonKey(toJson:)` — json_serializable needs a
/// top-level function, not a getter tear-off.
String languageDirectionToWire(LanguageDirection direction) => direction.wire;
