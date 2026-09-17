import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/types/result.dart';
import '../../../data/api/calls/gift_apis.dart';
import '../../../data/models/terracotta/commerce/gift_history.dart';

typedef MyGiftsFetch =
    AsyncResult<GiftHistory> Function({
      GiftDirection? direction,
      int? page,
      int? perPage,
      CancelToken? cancelToken,
      Duration? timeout,
    });

/// BOTH SIDES of the reader's gifting — `GET /api/gifts/history`.
@immutable
class MyGiftsState {
  const MyGiftsState({
    this.history = const GiftHistory(),
    this.loading = false,
    this.error,
  });

  final GiftHistory history;
  final bool loading;
  final AppException? error;

  List<GiftHistoryEntry> get gifts => history.gifts;

  /// Counts and sums over the WHOLE history, whatever is filtered.
  GiftTotals get totals => history.totals;

  /// Whether there is nothing to show and nothing on its way.
  bool get isEmpty => gifts.isEmpty && !loading && error == null;

  MyGiftsState copyWith({
    GiftHistory? history,
    bool? loading,
    AppException? error,
    bool clearError = false,
  }) => MyGiftsState(
    history: history ?? this.history,
    loading: loading ?? this.loading,
    error: clearError ? null : error ?? this.error,
  );
}

/// Reads the reader's own gift history, both directions.
///
/// UNPAGINATED, deliberately. Omitting `per_page` is what asks for the
/// whole list; the alternative is Laravel's paginator object and a
/// screen that pages, and this one is half a sheet. See
/// `GiftApis.getGiftHistory`.
class MyGiftsCubit extends Cubit<MyGiftsState> {
  MyGiftsCubit({MyGiftsFetch? fetch})
    : _fetch = fetch ?? GiftApis.getGiftHistory,
      super(const MyGiftsState());

  final MyGiftsFetch _fetch;
  final _cancel = CancelToken();

  /// Loads unless it already has, so opening the tab twice is free.
  Future<void> ensureLoaded() {
    if (state.gifts.isNotEmpty || state.loading) return Future.value();
    return load();
  }

  Future<void> load() async {
    emit(state.copyWith(loading: true, clearError: true));
    // NO `direction`. Both sides in one list is the whole point of
    // this endpoint, and the totals would not narrow with the filter
    // anyway.
    switch (await _fetch(cancelToken: _cancel)) {
      case Success(:final value):
        if (isClosed) return;
        emit(MyGiftsState(history: value));
      case Failure(:final error):
        if (isClosed) return;
        // KEEPS WHAT IT HAS. A failed re-read of a list already on
        // screen must not blank it.
        emit(state.copyWith(loading: false, error: error));
    }
  }

  @override
  Future<void> close() {
    _cancel.cancel('my gifts closed');
    return super.close();
  }
}
