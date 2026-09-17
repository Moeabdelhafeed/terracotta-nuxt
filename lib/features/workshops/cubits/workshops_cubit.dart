import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/types/result.dart';
import '../../../data/api/calls/workshop_apis.dart';
import '../../../data/models/terracotta/workshop/workshop.dart';
import '../../_shared/locale_scoped_load.dart';
import 'workshops_state.dart';

/// The one call this tab makes.
typedef WorkshopsFetch =
    AsyncResult<List<Workshop>> Function({CancelToken? cancelToken});

/// Loads `GET /api/workshops` — the whole active catalogue, unpaginated.
///
/// The catalogue is REAL data, not three hardcoded families: the live
/// server returns four workshops today, two of them sharing
/// `make_your_piece`, each with its own title, description and
/// admin-set colour. Everything the cards print comes from here.
class WorkshopsCubit extends Cubit<WorkshopsState> with LocaleScopedLoad {
  WorkshopsCubit({WorkshopsFetch? fetch})
    : _fetch = fetch ?? WorkshopApis.listWorkshops,
      super(const WorkshopsLoading());

  /// Injectable so the state machine can be tested without a network.
  /// Null in the app.
  final WorkshopsFetch _fetch;

  /// Stashed so an in-flight request is dropped when the screen goes.
  final _cancel = CancelToken();

  @override
  bool get hasData => state is WorkshopsLoaded;

  @override
  Future<void> load() async {
    final result = await _fetch(cancelToken: _cancel);
    if (isClosed) return;

    switch (result) {
      case Success(:final value):
        emit(WorkshopsLoaded(value));
      case Failure(:final error):
        // Only when there is nothing on screen yet. A refresh that
        // fails over a catalogue the reader is already looking at
        // leaves it alone.
        if (state is! WorkshopsLoaded) emit(WorkshopsFailed(error));
    }
  }

  /// Pull to refresh. Records the language it ran in, so returning to
  /// the tab does not immediately repeat it.
  Future<void> refresh(String locale) => refreshIn(locale);

  @override
  Future<void> close() {
    _cancel.cancel();
    return super.close();
  }
}
