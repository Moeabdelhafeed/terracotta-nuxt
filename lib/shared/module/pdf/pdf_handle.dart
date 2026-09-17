import 'dart:typed_data';

import 'pdf_models.dart';

/// Public handle exposed to [GlobalPdfViewer.builder] and to callers
/// who want to drive the viewer from outside its chrome.
abstract class PdfHandle {
  PdfStateSnapshot get state;
  Stream<PdfStateSnapshot> get stateStream;

  // ─── Navigation ───────────────────────────────────────────

  Future<void> goToPage(int page);
  Future<void> nextPage();
  Future<void> prevPage();

  // ─── Zoom ─────────────────────────────────────────────────

  Future<void> zoomIn();
  Future<void> zoomOut();
  Future<void> resetZoom();
  Future<void> setZoom(double scale);

  // ─── Search ───────────────────────────────────────────────

  /// Run a text search. Empty / null query clears the current search.
  Future<void> search(String? query, {bool caseSensitive = false});
  Future<void> nextMatch();
  Future<void> prevMatch();
  Future<void> clearSearch();

  // ─── Outline / TOC ────────────────────────────────────────

  /// Returns the document outline. Empty list when the PDF has no
  /// outline / TOC.
  Future<List<PdfOutlineItem>> loadOutline();

  // ─── Thumbnails ───────────────────────────────────────────

  /// Renders a thumbnail of [page] (1-based). [maxWidth] caps the
  /// longest side — pdfrx returns whatever fits inside it preserving
  /// aspect ratio. Null when the page can't be rendered.
  Future<Uint8List?> renderThumbnail(int page, {int maxWidth = 200});

  // ─── Bookmarks ────────────────────────────────────────────

  bool isBookmarked(int page);
  Future<void> toggleBookmark(int page);
  List<int> get bookmarks;

  // ─── Rotation ─────────────────────────────────────────────

  /// Rotate the whole view by [deltaDeg] degrees (default 90). Wraps
  /// at 360 → 0.
  Future<void> rotate({int deltaDeg = 90});

  // ─── Actions (share / print / save) ───────────────────────

  /// Trigger system share sheet over the document bytes.
  Future<void> share({required Object shareTrigger});

  /// Open the platform print preview / print dialog.
  Future<void> printDocument();

  /// Save bytes to a user-chosen location via file picker. Returns
  /// the chosen path, or null when the user cancels.
  Future<String?> saveAs();
}
