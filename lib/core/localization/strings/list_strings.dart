import '../../../generated/l10n.dart';
import '../number_formatter.dart';
import '../tr.dart';

/// Strings for the `list_` key prefix family — shared by `GlobalList`
/// and `GlobalGrid` (pagination, empty state, bulk selection).
class ListStrings {
  ListStrings._();

  static String get loadMore =>
      Tr.t('list.load_more', S.current.list_load_more);
  static String get emptyTitle =>
      Tr.t('list.empty_title', S.current.list_empty_title);
  static String get clearSelection =>
      Tr.t('list.clear_selection', S.current.list_clear_selection);

  /// The pagination bar's page buttons. A bare digit reads as a loose
  /// number in a row of numbers.
  static String page(int page) => Tr.t(
    'list.page',
    S.current.list_page(page),
  );

  /// The compact pagination bar. The digits go through [AppNumbers] —
  /// plain `ar` formats in WESTERN digits, so an Arabic list read
  /// `Page 1 of 10` beside `١ ٢ ٣` everywhere else on the screen.
  static String pageOf(int page, int total) => Tr.t(
    'list.page_of',
    S.current.list_page_of(
      AppNumbers.decimal(page),
      AppNumbers.decimal(total),
    ),
  );

  /// The A-Z strip. A column of bare letters says nothing about what
  /// it is for.
  static String get sectionIndex =>
      Tr.t('list.section_index', S.current.list_section_index);

  static String get previousPage =>
      Tr.t('list.previous_page', S.current.list_previous_page);
  static String get nextPage =>
      Tr.t('list.next_page', S.current.list_next_page);

  /// The pagination bar's ellipsis. It swallowed a run of pages and
  /// said nothing about them — a breadcrumb trail's `…` at least
  /// opens.
  static String get morePages =>
      Tr.t('list.more_pages', S.current.list_more_pages);

  static String selectedCount(int count) =>
      Tr.t('list.selected_count', S.current.list_selected_count(count));
}
