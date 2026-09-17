import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/colors/workshop_family_colors.dart';
import '../../../core/types/result.dart';
import '../../../data/api/calls/workshop_apis.dart';
import '../../../data/models/terracotta/workshop/workshop_detail.dart';
import 'piece_selection_state.dart';

typedef WorkshopDetailFetch =
    AsyncResult<WorkshopDetail> Function(
      String workshopId, {
      CancelToken? cancelToken,
    });

/// Choosing what to paint.
///
/// ONE request: `GET /api/workshops/{id}` carries the whole catalogue
/// nested inside it (`categories` → `sub_categories` → `products`)
/// along with the per-person bounds. Nothing below the tabs asks the
/// server anything — narrowing a category is a local read.
///
/// The bounds come from the SAME payload rather than the catalogue row
/// the tab already had, because a screen that must not let the customer
/// past the ceiling should read the ceiling from the request that
/// carries the things being counted.
class PieceSelectionCubit extends Cubit<PieceSelectionState> {
  PieceSelectionCubit({
    required this.workshopId,
    int people = 1,
    WorkshopDetailFetch? detail,
  }) : _detail = detail ?? WorkshopApis.getWorkshop,
       super(PieceSelectionState(people: people));

  final String workshopId;
  final WorkshopDetailFetch _detail;
  final _cancel = CancelToken();

  Future<void> load() async {
    emit(state.copyWith(loading: true, clearError: true));

    switch (await _detail(workshopId, cancelToken: _cancel)) {
      case Success(:final value):
        if (isClosed) return;
        // Open the first category and its first group, so the screen
        // arrives showing products rather than a row of tabs and a
        // blank below them.
        final category = value.categories.firstOrNull;
        emit(
          state.copyWith(
            categories: value.categories,
            categoryId: category?.id,
            subCategoryId: category?.subCategories.firstOrNull?.id,
            minPerPerson: value.minProductsPerPerson,
            maxPerPerson: value.maxProductsPerPerson,
            family: WorkshopFamily.fromWire(value.type.wire),
            // Null on every workshop that does not take them back, and
            // empty for a guest — who has made nothing to bring.
            ownPieces: value.ownPieces,
            loading: false,
          ),
        );
      case Failure(:final error):
        if (isClosed) return;
        emit(state.copyWith(loading: false, error: error));
    }
  }

  /// Opening a category opens its FIRST group too — the group tabs
  /// belong to the category, so keeping the old id would leave a row of
  /// products from the category the customer just left.
  void selectCategory(int id) {
    // The own-pieces tile is not a category and has no groups under it.
    if (id == PieceSelectionState.ownTab) {
      if (!state.showsOwnPieces) return;
      emit(state.copyWith(categoryId: id, clearSubCategory: true));
      return;
    }
    final category = state.categories.where((c) => c.id == id).firstOrNull;
    if (category == null) return;
    emit(
      state.copyWith(
        categoryId: id,
        subCategoryId: category.subCategories.firstOrNull?.id,
      ),
    );
  }

  void selectSubCategory(int id) => emit(state.copyWith(subCategoryId: id));

  /// One more of this product, up to the workshop's ceiling.
  ///
  /// Refused AT the ceiling rather than clamped past it: the caller
  /// disables the button off the same flag, and a silent no-op behind a
  /// live-looking button is the version that reads as a broken app.
  void add(int productId) {
    if (!state.canAddMore) return;
    emit(
      state.copyWith(
        picked: {...state.picked, productId: state.quantityOf(productId) + 1},
      ),
    );
  }

  /// One of the customer's own, in or out.
  ///
  /// A TOGGLE, not a stepper: it is a specific object, so the only
  /// answers are one and none. Adding is refused at the ceiling the
  /// same way a product is — the limit is on the booking, and a piece
  /// counts against it like anything else.
  void toggleOwn(int pieceId) {
    final next = {...state.pickedOwn};
    if (!next.remove(pieceId)) {
      if (!state.canAddMore) return;
      next.add(pieceId);
    }
    emit(state.copyWith(pickedOwn: next));
  }

  /// One fewer, and OUT of the map at zero — see
  /// `PieceSelectionState.picked`.
  void remove(int productId) {
    final now = state.quantityOf(productId);
    if (now == 0) return;
    final next = {...state.picked};
    if (now == 1) {
      next.remove(productId);
    } else {
      next[productId] = now - 1;
    }
    emit(state.copyWith(picked: next));
  }

  @override
  Future<void> close() {
    _cancel.cancel();
    return super.close();
  }
}
