/// Lookalike-host detection for URL inputs — flags phishing-style hosts so
/// the field can WARN (never block): homograph attacks mix scripts inside a
/// label (`аpple.com` with a Cyrillic `а`), and punycode (`xn--…`) hides an
/// international domain behind ASCII.
enum HostRisk {
  /// Latin letters mixed with Cyrillic/Greek lookalikes in one label.
  mixedScript,

  /// Contains a punycode (`xn--`) label — an encoded international domain.
  punycode,
}

abstract final class UrlSecurity {
  static final _latin = RegExp(r'[a-zA-Z]');
  static final _cyrillic = RegExp(r'[Ѐ-ӿ]');
  static final _greek = RegExp(r'[Ͱ-Ͽ]');

  /// The risk of [host], or null when it looks clean. An all-Cyrillic host
  /// (`россия.рф`) is legitimate — only MIXING scripts inside a label is
  /// suspicious.
  static HostRisk? riskOf(String host) {
    final h = host.trim().toLowerCase();
    if (h.isEmpty) return null;
    for (final label in h.split('.')) {
      if (label.startsWith('xn--')) return HostRisk.punycode;
      final hasLatin = _latin.hasMatch(label);
      if (hasLatin && (_cyrillic.hasMatch(label) || _greek.hasMatch(label))) {
        return HostRisk.mixedScript;
      }
    }
    return null;
  }
}
