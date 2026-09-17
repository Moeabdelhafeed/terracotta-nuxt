import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/types/result.dart';
import '../../../data/api/calls/workshop_apis.dart';
import '../../../data/models/terracotta/workshop/workshop_detail.dart';
import 'workshop_detail_state.dart';

/// The one call an expanded workshop makes.
typedef WorkshopDetailFetch =
    AsyncResult<WorkshopDetail> Function(
      String workshopId, {
      CancelToken? cancelToken,
    });

/// Loads `GET /api/workshops/{id}` — the parts the LIST does not carry.
///
/// Expanding a card is always a second request: the catalogue row has
/// no `gallery`, no `long_description` and no `categories`, so there is
/// nothing to prefill the panel from.
class WorkshopDetailCubit extends Cubit<WorkshopDetailState> {
  WorkshopDetailCubit({required this.workshopId, WorkshopDetailFetch? fetch})
    : _fetch = fetch ?? WorkshopApis.getWorkshop,
      super(const WorkshopDetailLoading());

  final int workshopId;

  /// Injectable so the state machine can be tested without a network.
  /// Null in the app.
  final WorkshopDetailFetch _fetch;

  /// An accordion is collapsed mid-flight more often than a page is
  /// left — the answer would arrive to a closed cubit and `emit`
  /// throws.
  final _cancel = CancelToken();

  /// Whether the one request has already been made.
  ///
  /// `load` is IDEMPOTENT because two owners can reasonably call it:
  /// the page, which makes the cubit, and the panel, which is built and
  /// rebuilt as its card opens. Leaving it to one of them is the
  /// footgun — the panel used to create-and-load in one expression, and
  /// moving the creation out silently stopped anything loading at all.
  bool _started = false;

  Future<void> load() async {
    if (_started) return;
    _started = true;
    await _fetchOnce();
  }

  /// Asks again regardless. The caller has a reason to think the answer
  /// changed.
  Future<void> reload() {
    _started = true;
    return _fetchOnce();
  }

  Future<void> _fetchOnce() async {
    final result = await _fetch('$workshopId', cancelToken: _cancel);
    if (isClosed) return;

    switch (result) {
      case Success(:final value):
        emit(WorkshopDetailLoaded(value));
      case Failure(:final error):
        if (state is! WorkshopDetailLoaded) emit(WorkshopDetailFailed(error));
    }
  }

  @override
  Future<void> close() {
    _cancel.cancel();
    return super.close();
  }
}
