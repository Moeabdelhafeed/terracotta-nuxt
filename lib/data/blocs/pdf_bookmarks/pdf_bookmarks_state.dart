import 'package:freezed_annotation/freezed_annotation.dart';

part 'pdf_bookmarks_state.freezed.dart';
part 'pdf_bookmarks_state.g.dart';

/// Persisted PDF bookmarks + last-read page, keyed by each source's
/// `persistKey` (URL / asset path / file path / bytes label, with
/// optional `cacheKey` override).
@freezed
abstract class PdfBookmarksState with _$PdfBookmarksState {
  const factory PdfBookmarksState({
    /// `{ persistKey: [page, page, ...] }` — 1-based page numbers,
    /// sorted ascending. Empty list when no bookmarks for that source.
    @Default(<String, List<int>>{}) Map<String, List<int>> pages,

    /// Last page the user was reading per source (1-based). Survives
    /// app kill so the viewer can resume on next open.
    @Default(<String, int>{}) Map<String, int> lastReadPage,
  }) = _PdfBookmarksState;

  factory PdfBookmarksState.fromJson(Map<String, dynamic> json) =>
      _$PdfBookmarksStateFromJson(json);
}
