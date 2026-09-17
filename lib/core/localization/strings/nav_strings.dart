import '../../../generated/l10n.dart';
import '../tr.dart';

/// Navigation-surface strings — 404 fallback labels, etc.
class NavStrings {
  NavStrings._();

  static String get pageNotFound =>
      Tr.t('nav_page_not_found', S.current.nav_page_not_found);
  static String get goHome => Tr.t('nav_go_home', S.current.nav_go_home);

  /// The first back at the bottom of the stack. See `ExitGuard`.
  static String get exitConfirm =>
      Tr.t('nav_exit_confirm', S.current.nav_exit_confirm);
  static String get backToHome =>
      Tr.t('nav.back_to_home', S.current.nav_back_to_home);
  static String get pageNotFoundBody =>
      Tr.t('nav.page_not_found_body', S.current.nav_page_not_found_body);
  static String get goBack => Tr.t('nav.go_back', S.current.nav_go_back);
  static String get copyUrl => Tr.t('nav.copy_url', S.current.nav_copy_url);
  static String get pathCopied =>
      Tr.t('nav.path_copied', S.current.nav_path_copied);

  /// The trail that says where a page sits. NOT the crash reporter's
  /// breadcrumbs, which are a diagnostic log of where the app has been.
  static String get breadcrumbs =>
      Tr.t('nav.breadcrumbs', S.current.nav_breadcrumbs);

  /// What the ellipsis in a collapsed trail is holding. "…" on its own
  /// tells a reader nothing about what is behind it.
  static String breadcrumbsHidden(int count) => Tr.t(
    'nav.breadcrumbs_hidden',
    S.current.nav_breadcrumbs_hidden(count),
  );

  /// Where a destination sits in the bar. A tab is one of a SET, and
  /// which one it is cannot be worked out from its own name.
  static String tabPosition(int index, int total) =>
      Tr.t('nav.tab_position', S.current.nav_tab_position(index, total));

  /// The five tabs.
  static String get gallery =>
      Tr.t('nav_tab_gallery', S.current.nav_tab_gallery);
  static String get workshops =>
      Tr.t('nav_tab_workshops', S.current.nav_tab_workshops);
  static String get shop => Tr.t('nav_tab_shop', S.current.nav_tab_shop);
  static String get profile =>
      Tr.t('nav_tab_profile', S.current.nav_tab_profile);
}
