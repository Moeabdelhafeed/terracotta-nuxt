import 'package:flutter/foundation.dart' show immutable;

/// Query parameters that only exist for cross-site tracking — stripped by
/// [UrlNormalizer.normalize] when `stripTracking` is on.
const Set<String> kUrlTrackingParams = {
  'utm_source',
  'utm_medium',
  'utm_campaign',
  'utm_term',
  'utm_content',
  'utm_id',
  'fbclid',
  'gclid',
  'gclsrc',
  'dclid',
  'msclkid',
  'mc_eid',
  'mc_cid',
  'igshid',
  'twclid',
  'ttclid',
  'yclid',
  '_hsenc',
  '_hsmi',
  'mkt_tok',
  'oly_anon_id',
  'oly_enc_id',
  'vero_id',
  'wickedid',
  's_kwcid',
};

/// The parsed value a `UrlField` emits — raw text, normalized form, split
/// parts + validity. Matches the `Money` / `Measurement` / `ColorValue`
/// pattern.
@immutable
class WebLink {
  const WebLink({
    required this.raw,
    required this.normalized,
    required this.uri,
    required this.isValid,
  });

  /// The exact field text.
  final String raw;

  /// [raw] after normalization (trimmed, scheme added, tracking stripped —
  /// per the field's flags). Equal to [raw] when nothing changed.
  final String normalized;

  /// Parsed form of [normalized]; null while empty / unparseable.
  final Uri? uri;

  /// Passes the field's sync validator.
  final bool isValid;

  String get scheme => uri?.scheme ?? '';
  String get host => uri?.host ?? '';
  String get path => uri?.path ?? '';

  /// True for `https` links.
  bool get isSecure => scheme == 'https';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WebLink &&
          other.raw == raw &&
          other.normalized == normalized &&
          other.uri == uri &&
          other.isValid == isValid;

  @override
  int get hashCode => Object.hash(raw, normalized, uri, isValid);

  @override
  String toString() => 'WebLink($normalized, valid: $isValid)';
}

/// Pure URL cleanup used by `UrlField` — no widgets, unit-testable.
abstract final class UrlNormalizer {
  /// Looks like a host the user just forgot the scheme for (`example.com`,
  /// `sub.a.co/path`) — NOT free text (`not a url`) or another scheme
  /// (`ftp://…`, `mailto:…`).
  static final _schemelessHost = RegExp(
    r'^[a-zA-Z0-9][a-zA-Z0-9\-.]*\.[a-zA-Z]{2,}(?::\d+)?(?:[/?#].*)?$',
  );

  /// Cleans [text]: trims whitespace, prefixes `https://` when the input is a
  /// scheme-less host ([autoScheme]), drops tracking params ([stripTracking]).
  /// Free text / other schemes pass through untouched (the validator rejects
  /// or accepts them; normalize never invents meaning).
  static String normalize(
    String text, {
    bool autoScheme = true,
    bool stripTracking = false,
  }) {
    var t = text.trim();
    if (t.isEmpty) return t;
    if (autoScheme && !t.contains(':') && _schemelessHost.hasMatch(t)) {
      t = 'https://$t';
    }
    if (stripTracking) {
      final uri = Uri.tryParse(t);
      if (uri != null && uri.hasScheme && uri.queryParameters.isNotEmpty) {
        final kept = Map.of(uri.queryParameters)
          ..removeWhere((k, _) => kUrlTrackingParams.contains(k.toLowerCase()));
        if (kept.isEmpty) {
          // `replace(query: '')` leaves a bare trailing `?` — strip it.
          t = uri.replace(query: '').toString();
          if (t.endsWith('?')) t = t.substring(0, t.length - 1);
        } else {
          t = uri.replace(queryParameters: kept).toString();
        }
      }
    }
    return t;
  }
}
