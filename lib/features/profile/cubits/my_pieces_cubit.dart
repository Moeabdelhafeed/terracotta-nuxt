import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/colors/workshop_family_colors.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/types/result.dart';
import '../../../data/api/calls/workshop_apis.dart';
import '../../../data/models/terracotta/workshop/workshop.dart';
import '../../../data/models/terracotta/workshop/workshop_detail.dart';
import '../../../data/models/terracotta/workshop/workshop_own_pieces.dart';

typedef WorkshopsListFetch =
    AsyncResult<List<Workshop>> Function({
      CancelToken? cancelToken,
      Duration? timeout,
    });

typedef WorkshopDetailFetch =
    AsyncResult<WorkshopDetail> Function(
      String workshopId, {
      CancelToken? cancelToken,
      Duration? timeout,
    });

/// «قطعي» — everything the customer has made at the studio.
///
/// ## Why this takes two requests
///
/// **There is no endpoint for a customer's pieces.** All 92 server
/// operations were checked: nothing under `/api` mentions one, and the
/// only route that touches a piece at all is
/// `POST /api/workshops/bookings/{booking}/images`, which CREATES them
/// — photos sharing a `piece_label` are one object.
///
/// The pieces are readable in exactly one place: `own_pieces` on
/// `GET /api/workshops/{id}`, and only on a `paint_your_piece` workshop
/// that accepts them back. So this asks the catalogue which workshop
/// that is, then asks that workshop.
///
/// That coupling is real and worth naming: **if the studio retires
/// every paint-your-piece workshop, this screen has no source.** It
/// says so ([noSource]) rather than claiming the customer has made
/// nothing — those are different sentences and only one of them is
/// true.
///
/// A piece that has already been painted elsewhere comes back with
/// `is_available_to_paint: false`. It still belongs to the customer and
/// still shows here — this screen is the collection, not the picker.
@immutable
class MyPiecesState {
  const MyPiecesState({
    this.pieces = const [],
    this.price,
    this.loading = true,
    this.noSource = false,
    this.error,
  });

  /// Newest first, as the server orders them. Both the ones still
  /// available to paint and the ones already used.
  final List<WorkshopOwnPiece> pieces;

  /// What bringing one back COSTS, as a decimal string — the flat
  /// own-piece rate on the workshop that answered. Null when no
  /// workshop did.
  final String? price;

  final bool loading;

  /// The catalogue lists no workshop that takes own pieces back, so
  /// there is nowhere to read them from. NOT the same as an empty
  /// collection.
  final bool noSource;

  final AppException? error;

  bool get hasData => pieces.isNotEmpty;

  /// The customer has genuinely made nothing yet — the request worked
  /// and came back empty.
  bool get isEmpty => pieces.isEmpty && !loading && !noSource && error == null;

  /// The ones that could still be booked in to be painted.
  List<WorkshopOwnPiece> get available => [
    for (final piece in pieces)
      if (piece.isAvailableToPaint) piece,
  ];

  MyPiecesState copyWith({
    List<WorkshopOwnPiece>? pieces,
    String? price,
    bool? loading,
    bool? noSource,
    AppException? error,
    bool clearError = false,
  }) => MyPiecesState(
    pieces: pieces ?? this.pieces,
    price: price ?? this.price,
    loading: loading ?? this.loading,
    noSource: noSource ?? this.noSource,
    error: clearError ? null : error ?? this.error,
  );
}

class MyPiecesCubit extends Cubit<MyPiecesState> {
  MyPiecesCubit({WorkshopsListFetch? workshops, WorkshopDetailFetch? detail})
    : _workshops = workshops ?? WorkshopApis.listWorkshops,
      _detail = detail ?? WorkshopApis.getWorkshop,
      super(const MyPiecesState());

  final WorkshopsListFetch _workshops;
  final WorkshopDetailFetch _detail;
  final _cancel = CancelToken();

  Future<void> load() async {
    emit(
      state.copyWith(loading: true, noSource: false, clearError: true),
    );

    final catalogue = await _workshops(cancelToken: _cancel);
    if (isClosed) return;

    final List<Workshop> workshops;
    switch (catalogue) {
      case Success(:final value):
        workshops = value;
      case Failure(:final error):
        emit(state.copyWith(loading: false, error: error));
        return;
    }

    // The only family whose detail carries `own_pieces`. A studio with
    // none has nowhere for this screen to read from.
    final source = workshops
        .where(
          (w) =>
              WorkshopFamily.fromWire(w.type.wire) ==
              WorkshopFamily.paintYourPiece,
        )
        .firstOrNull;

    if (source == null) {
      emit(state.copyWith(loading: false, noSource: true));
      return;
    }

    switch (await _detail('${source.id}', cancelToken: _cancel)) {
      case Success(:final value):
        if (isClosed) return;
        final own = value.ownPieces;
        emit(
          state.copyWith(
            pieces: own?.pieces ?? const [],
            price: own?.price,
            loading: false,
          ),
        );
      case Failure(:final error):
        if (isClosed) return;
        // What is on screen STAYS. A failed refresh is not a reason to
        // blank a collection the customer was looking at.
        emit(state.copyWith(loading: false, error: error));
    }
  }

  Future<void> refresh() => load();

  @override
  Future<void> close() {
    _cancel.cancel('my pieces closed');
    return super.close();
  }
}
