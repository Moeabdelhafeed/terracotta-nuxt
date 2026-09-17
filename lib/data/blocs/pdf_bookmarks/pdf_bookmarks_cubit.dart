import 'package:hydrated_bloc/hydrated_bloc.dart';

import 'pdf_bookmarks_state.dart';

/// Persists PDF bookmarks + last-read page per document. Keyed off
/// each source's `persistKey` (URL / asset path / file path / bytes
/// label, with optional `cacheKey` override on the source spec).
///
/// `GlobalPdfViewer` reads + writes through this cubit. Standalone
/// pages can also call it directly (e.g. a library screen listing
/// "continue reading" docs).
class PdfBookmarksCubit extends HydratedCubit<PdfBookmarksState> {
  PdfBookmarksCubit() : super(const PdfBookmarksState());

  // ─── Bookmarks ───────────────────────────────────────────────

  List<int> pagesFor(String key) =>
      List<int>.unmodifiable(state.pages[key] ?? const []);

  bool isBookmarked(String key, int page) =>
      (state.pages[key] ?? const []).contains(page);

  void toggle(String key, int page) {
    final current = List<int>.from(state.pages[key] ?? const []);
    if (current.contains(page)) {
      current.remove(page);
    } else {
      current
        ..add(page)
        ..sort();
    }
    final next = Map<String, List<int>>.from(state.pages);
    if (current.isEmpty) {
      next.remove(key);
    } else {
      next[key] = current;
    }
    emit(state.copyWith(pages: next));
  }

  void clearFor(String key) {
    if (!state.pages.containsKey(key)) return;
    final next = Map<String, List<int>>.from(state.pages)..remove(key);
    emit(state.copyWith(pages: next));
  }

  void clearAll() => emit(state.copyWith(pages: const <String, List<int>>{}));

  // ─── Last-read page ──────────────────────────────────────────

  int? lastReadPage(String key) => state.lastReadPage[key];

  void setLastReadPage(String key, int page) {
    if (page <= 0) return;
    if (state.lastReadPage[key] == page) return;
    final next = Map<String, int>.from(state.lastReadPage)..[key] = page;
    emit(state.copyWith(lastReadPage: next));
  }

  // ─── Hydrated serialization ──────────────────────────────────

  @override
  PdfBookmarksState? fromJson(Map<String, dynamic> json) {
    try {
      return PdfBookmarksState.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  @override
  Map<String, dynamic>? toJson(PdfBookmarksState state) => state.toJson();
}
