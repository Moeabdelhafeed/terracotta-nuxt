import '../../../generated/l10n.dart';
import '../tr.dart';

/// Strings for the `pdf_` key prefix family — `GlobalPdfViewer` chrome,
/// error states, and recent-docs list.
class PdfStrings {
  PdfStrings._();

  static String resumedAtPage(int page) =>
      Tr.t('pdf.resumed_at_page', S.current.pdf_resumed_at_page(page));

  static String get startOver =>
      Tr.t('pdf.start_over', S.current.pdf_start_over);

  static String get saveDialogTitle =>
      Tr.t('pdf.save_dialog_title', S.current.pdf_save_dialog_title);

  static String downloadingPercent(String percent) => Tr.t(
    'pdf.downloading_percent',
    S.current.pdf_downloading_percent(percent),
  );

  static String get loadFailed =>
      Tr.t('pdf.load_failed', S.current.pdf_load_failed);

  static String get passwordRequired =>
      Tr.t('pdf.password_required', S.current.pdf_password_required);

  static String get notFound => Tr.t('pdf.not_found', S.current.pdf_not_found);

  static String get loadFailedDetail =>
      Tr.t('pdf.load_failed_detail', S.current.pdf_load_failed_detail);

  static String get encryptedDetail =>
      Tr.t('pdf.encrypted_detail', S.current.pdf_encrypted_detail);

  static String get notFoundDetail =>
      Tr.t('pdf.not_found_detail', S.current.pdf_not_found_detail);

  static String get rotate90 => Tr.t('pdf.rotate_90', S.current.pdf_rotate_90);

  static String get saveAs => Tr.t('pdf.save_as', S.current.pdf_save_as);

  /// The system print intent. It was the one action in the viewer's
  /// menu written as an English literal.
  static String get print => Tr.t('pdf.print', S.current.pdf_print);

  /// How long the document is. Plural, because Arabic has five forms
  /// for it and "4 pages" concatenated by hand has one.
  static String pageCount(int count) =>
      Tr.t('pdf.page_count', S.current.pdf_page_count(count));

  static String get zoomOut => Tr.t('pdf.zoom_out', S.current.pdf_zoom_out);

  static String get zoomIn => Tr.t('pdf.zoom_in', S.current.pdf_zoom_in);

  static String get jumpToPage =>
      Tr.t('pdf.jump_to_page', S.current.pdf_jump_to_page);

  static String pageOf(int page, int total) =>
      Tr.t('pdf.page_of', S.current.pdf_page_of(page, total));

  static String get noBookmarks =>
      Tr.t('pdf.no_bookmarks', S.current.pdf_no_bookmarks);

  static String pageNumber(int page) =>
      Tr.t('pdf.page_number', S.current.pdf_page_number(page));

  static String get removeBookmark =>
      Tr.t('pdf.remove_bookmark', S.current.pdf_remove_bookmark);

  static String get bookmarkPage =>
      Tr.t('pdf.bookmark_page', S.current.pdf_bookmark_page);

  /// The second half of the bookmark button's tooltip. The gesture it
  /// describes is the module's, so the sentence is assembled here
  /// rather than shipped as two translations of one button.
  static String get bookmarkListHint =>
      Tr.t('pdf.bookmark_list_hint', S.current.pdf_bookmark_list_hint);

  /// The compact card's page count, in the space a card has for it.
  /// Not a plural: an abbreviation does not inflect.
  static String pageCountShort(int count) =>
      Tr.t('pdf.page_count_short', S.current.pdf_page_count_short(count));

  /// What the search counter says out loud. On screen it is "3 / 128",
  /// which a screen reader reads as two numbers and a slash.
  static String matchOf(int index, int total) =>
      Tr.t('pdf.match_of', S.current.pdf_match_of(index, total));

  static String get noMatches =>
      Tr.t('pdf.no_matches', S.current.pdf_no_matches);

  static String get searching => Tr.t('pdf.searching', S.current.pdf_searching);

  /// The compact card, which is one button however much is drawn on it.
  static String openDocument(String name) =>
      Tr.t('pdf.open_document', S.current.pdf_open_document(name));

  static String get noOutline =>
      Tr.t('pdf.no_outline', S.current.pdf_no_outline);

  static String get noRecentDocuments =>
      Tr.t('pdf.no_recent_documents', S.current.pdf_no_recent_documents);

  static String get go => Tr.t('pdf.go', S.current.pdf_go);
  static String get previousMatch =>
      Tr.t('pdf.previous_match', S.current.pdf_previous_match);
  static String get nextMatch =>
      Tr.t('pdf.next_match', S.current.pdf_next_match);
  static String get forget => Tr.t('pdf.forget', S.current.pdf_forget);
  static String get outline => Tr.t('pdf.outline', S.current.pdf_outline);
  static String get bookmarks => Tr.t('pdf.bookmarks', S.current.pdf_bookmarks);
  static String get unlock => Tr.t('pdf.unlock', S.current.pdf_unlock);
  static String get previousPage =>
      Tr.t('pdf.previous_page', S.current.pdf_previous_page);
  static String get nextPage => Tr.t('pdf.next_page', S.current.pdf_next_page);
  static String get resetZoom =>
      Tr.t('pdf.reset_zoom', S.current.pdf_reset_zoom);
  static String bookmarkCount(int count) => Tr.plural(
    'pdf.bookmark_count',
    count,
    S.current.pdf_bookmark_count(count),
    args: {'count': count},
  );
}
