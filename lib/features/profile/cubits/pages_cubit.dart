import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/types/result.dart';
import '../../../data/api/calls/content_apis.dart';
import '../../../data/models/terracotta/content/static_page.dart';
import '../../_shared/locale_scoped_load.dart';

typedef PagesFetch =
    AsyncResult<List<StaticPage>> Function({
      CancelToken? cancelToken,
      Duration? timeout,
    });

/// The studio's own writing — terms, privacy, returns, shipping, about.
///
/// `GET /api/pages` returns all five WITH their HTML in one request, so
/// there is no second call to open one: the list is the content. Probed
/// live on 2026-09-08 — five rows, slugs `terms`, `privacy`, `returns`,
/// `shipping`, `about`.
///
/// PUBLIC. A visitor deciding whether to buy is exactly who reads the
/// returns policy, and the endpoint takes no session.
///
/// Locale-scoped: `name` and `content` are the server's, in the
/// language the request asked for.
class PagesCubit extends Cubit<PagesState> with LocaleScopedLoad {
  PagesCubit({PagesFetch? fetch})
    : _fetch = fetch ?? ContentApis.getPages,
      super(const PagesState());

  /// Injectable so the state machine can be tested without a network.
  final PagesFetch _fetch;

  final _cancel = CancelToken();

  @override
  bool get hasData => state.pages.isNotEmpty;

  @override
  Future<void> load() async {
    emit(state.copyWith(loading: true, clearError: true));

    switch (await _fetch(cancelToken: _cancel)) {
      case Success(:final value):
        emit(PagesState(pages: value, loaded: true));
      case Failure(:final error):
        // A failed REFRESH keeps what is on screen; only a failed FIRST
        // load is an error state.
        emit(state.copyWith(loading: false, error: error, loaded: true));
    }
  }

  /// One page by slug, or null when the studio has not written it.
  ///
  /// Answered from what is already loaded rather than by a request:
  /// `GET /api/pages` carries every page's content, so asking again for
  /// one of them would be a round trip for something on the device.
  StaticPage? bySlug(String slug) {
    for (final page in state.pages) {
      if (page.slug == slug) return page;
    }
    return null;
  }

  @override
  Future<void> close() {
    _cancel.cancel('pages closed');
    return super.close();
  }
}

class PagesState {
  const PagesState({
    this.pages = const [],
    this.loading = false,
    this.error,
    this.loaded = false,
  });

  final List<StaticPage> pages;
  final bool loading;
  final AppException? error;

  /// Whether a load has finished, however it went — so an empty list
  /// after a real answer reads differently from one before the first
  /// request.
  final bool loaded;

  PagesState copyWith({
    List<StaticPage>? pages,
    bool? loading,
    AppException? error,
    bool? loaded,
    bool clearError = false,
  }) => PagesState(
    pages: pages ?? this.pages,
    loading: loading ?? this.loading,
    error: clearError ? null : error ?? this.error,
    loaded: loaded ?? this.loaded,
  );
}
