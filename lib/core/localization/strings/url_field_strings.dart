import '../../../generated/l10n.dart';
import '../tr.dart';

/// Strings for the `url_field` prefix family — call sites resolve
/// these keys through this class instead of `Tr.t` directly.
class UrlFieldStrings {
  UrlFieldStrings._();

  static String get httpsRequired =>
      Tr.t('url_field.https_required', S.current.url_field_https_required);

  static String schemeNotAllowed(String scheme) => Tr.t(
    'url_field.scheme_not_allowed',
    S.current.url_field_scheme_not_allowed(scheme),
  );

  static String domainNotAllowed(String domains) => Tr.t(
    'url_field.domain_not_allowed',
    S.current.url_field_domain_not_allowed(domains),
  );

  static String domainBlocked(String host) => Tr.t(
    'url_field.domain_blocked',
    S.current.url_field_domain_blocked(host),
  );

  static String get lookalikeHost =>
      Tr.t('url_field.lookalike_host', S.current.url_field_lookalike_host);

  static String get punycodeHost =>
      Tr.t('url_field.punycode_host', S.current.url_field_punycode_host);

  static String get dismissPaste =>
      Tr.t('url_field.dismiss_paste', S.current.url_field_dismiss_paste);
}
