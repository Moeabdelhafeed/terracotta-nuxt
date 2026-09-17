import '../../../generated/l10n.dart';
import '../tr.dart';

/// The studio's own writing — terms, privacy, returns, shipping, about.
///
/// ## The CMS names them; these are the fallback
///
/// `GET /api/pages` sends a localized `name` for every row and that is
/// what a screen shows. These exist for the two moments it cannot: the
/// bar's title while the list is still loading, and a LINK that has to
/// say what it opens before anything has been fetched — the register
/// screen's «أوافق على الشروط والأحكام» is written before the reader
/// has been anywhere that would have loaded them.
///
/// Keyed by SLUG, because that is what the CMS row is addressed by and
/// what a link elsewhere in the app can name without knowing an id.
class PageStrings {
  PageStrings._();

  /// The five slugs the studio publishes, in the order the profile
  /// lists them. Verified live on 2026-09-08.
  ///
  /// **These are CMS rows, and a slug typed here is a promise about
  /// somebody else's database.** On 2026-09-10 `privacy` answered 404
  /// and a `privacy-policy` row stood in its place — the page had been
  /// deleted and re-made by hand, and was restored. Nothing in the app
  /// noticed either way: the profile list is built from whatever `GET
  /// /api/pages` returns, so it kept working, while the one hardcoded
  /// link — the register screen's consent line — quietly opened a 404
  /// until the row came back. Re-check these before trusting them.
  static const terms = 'terms';
  static const privacy = 'privacy';
  static const returns = 'returns';
  static const shipping = 'shipping';
  static const about = 'about';

  static const slugs = <String>[terms, privacy, returns, shipping, about];

  /// The section these sit under in «حسابي».
  static String get sectionTitle =>
      Tr.t('page_section_title', S.current.page_section_title);

  /// A house title for [slug].
  ///
  /// An unknown slug answers with the slug itself rather than an empty
  /// bar: the CMS can publish a sixth page tomorrow, and a screen that
  /// says `refunds` is worse than nothing only if you have never had a
  /// screen that says nothing.
  static String title(String slug) => switch (slug) {
    terms => Tr.t('page_terms', S.current.page_terms),
    privacy => Tr.t('page_privacy', S.current.page_privacy),
    returns => Tr.t('page_returns', S.current.page_returns),
    shipping => Tr.t('page_shipping', S.current.page_shipping),
    about => Tr.t('page_about', S.current.page_about),
    _ => slug,
  };

  static String get missing => Tr.t('page_missing', S.current.page_missing);

  static String get missingBody =>
      Tr.t('page_missing_body', S.current.page_missing_body);
}
