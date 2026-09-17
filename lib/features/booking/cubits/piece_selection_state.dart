import 'package:flutter/foundation.dart';

import '../../../core/constants/colors/workshop_family_colors.dart';
import '../../../core/error/app_exception.dart';
import '../../../data/models/terracotta/workshop/workshop_category.dart';
import '../../../data/models/terracotta/workshop/workshop_own_pieces.dart';
import '../../../data/models/terracotta/workshop/workshop_product.dart';
import '../../../data/models/terracotta/workshop/workshop_sub_category.dart';
import '../data/picked_piece.dart';

/// «اختيار القطع» — what the customer is buying to paint.
///
/// The catalogue is nested three deep — category → sub-category →
/// product — and arrives INSIDE the workshop payload, so the whole
/// screen is one request and every narrowing below it is local.
///
/// The bounds are PER PERSON and the server checks the TOTAL: a party
/// of two at one-to-three each must land between two and six pieces
/// altogether, and it is free to be four and nothing rather than two
/// and two. That is why nothing here is tracked per head.
@immutable
class PieceSelectionState {
  /// The id the OWN-PIECES rail tile carries.
  ///
  /// A sentinel rather than a nullable flag: the rail is one row of
  /// tiles and the customer's own pieces are the first of them, so they
  /// have to be selectable the same way a category is. No real category
  /// id is negative.
  static const int ownTab = -1;

  const PieceSelectionState({
    this.categories = const [],
    this.categoryId,
    this.subCategoryId,
    this.picked = const {},
    this.pickedOwn = const {},
    this.ownPieces,
    this.people = 1,
    this.minPerPerson,
    this.maxPerPerson,
    this.family,
    this.loading = true,
    this.error,
  });

  final List<WorkshopCategory> categories;

  /// The open category and sub-category. Null before the first load,
  /// and on a catalogue with nothing in it.
  final int? categoryId;
  final int? subCategoryId;

  /// Product id → how many of it. A product drops OUT of the map at
  /// zero rather than sitting there as a zero — the count, the button
  /// states and the payload all read the same map, and a zero line
  /// would be sent to the server as one.
  final Map<int, int> picked;

  /// The customer's OWN pieces, brought back to be painted.
  ///
  /// Null on every workshop but a `paint_your_piece` one that accepts
  /// them, and its list is empty for a guest — who has made nothing.
  final WorkshopOwnPieces? ownPieces;

  /// Which of those are in the booking. A SET, not a map: a specific
  /// object is one, and the server ignores a quantity sent with it.
  final Set<int> pickedOwn;

  /// The party this booking is for. The bounds multiply by it.
  final int people;

  /// The workshop's own per-person bounds. Null on a workshop with no
  /// catalogue at all — this screen should not have opened.
  final int? minPerPerson;
  final int? maxPerPerson;

  /// The family the WORKSHOP says it is, off the same payload as the
  /// catalogue.
  ///
  /// The route extra says it too, and normally that is what the screen
  /// paints in — but the extra does not survive a hot restart, and a
  /// candle workshop drawn in the paint family's hue is the wrong
  /// screen. Null until the payload lands.
  final WorkshopFamily? family;

  final bool loading;
  final AppException? error;

  /// The open category, or null when the catalogue is empty.
  WorkshopCategory? get category =>
      categories.where((c) => c.id == categoryId).firstOrNull;

  /// The sub-categories of the open category.
  List<WorkshopSubCategory> get subCategories =>
      category?.subCategories ?? const [];

  /// The products on screen — the open sub-category's.
  List<WorkshopProduct> get products =>
      subCategories.where((s) => s.id == subCategoryId).firstOrNull?.products ??
      const [];

  /// How many pieces have been chosen in total, across every category.
  ///
  /// Across ALL of them: the customer moves between tabs while picking,
  /// and a count that only saw the open one would keep letting them add
  /// past the ceiling.
  int get total =>
      picked.values.fold(0, (sum, q) => sum + q) + pickedOwn.length;

  /// The fewest and the most this booking may carry — the per-person
  /// bounds times the party.
  ///
  /// A null FLOOR is one, not none: the server reads
  /// `min_products_per_person ?? 1`, so a catalogue workshop the CMS
  /// left blank still demands a piece a head. Defaulted to zero here,
  /// an empty basket walked to a 422 the customer could not have
  /// predicted.
  int get minTotal => (minPerPerson ?? 1) * people;

  ///
  /// The CEILING has no such default — a null [maxPerPerson] is no
  /// ceiling at all, which [canAddMore] reads before this is ever
  /// consulted.
  int get maxTotal => (maxPerPerson ?? 0) * people;

  /// Whether one more piece can be added at all.
  ///
  /// A workshop with no maximum has none: [maxPerPerson] null means the
  /// CMS set no ceiling, not a ceiling of zero.
  bool get canAddMore => maxPerPerson == null || total < maxTotal;

  int quantityOf(int productId) => picked[productId] ?? 0;

  bool holdsOwn(int pieceId) => pickedOwn.contains(pieceId);

  /// The pieces on offer that can still be claimed. One already
  /// painted in another booking is refused by the server with
  /// `api.workshop_piece_unavailable`, so it is never drawn.
  List<WorkshopOwnPiece> get availableOwn => [
    for (final piece in ownPieces?.pieces ?? const <WorkshopOwnPiece>[])
      if (piece.isAvailableToPaint) piece,
  ];

  /// Whether the screen has a place to put them.
  bool get showsOwnPieces => availableOwn.isNotEmpty;

  /// Whether the CTA can fire. The server checks exactly this and
  /// answers 422 keyed to `products`, so refusing here is the same
  /// rule read early.
  bool get canContinue => total >= minTotal && total > 0 && !aboveCeiling;

  bool get aboveCeiling => maxPerPerson != null && total > maxTotal;

  /// The `products` payload.
  ///
  /// Each line is EITHER a catalogue product with a quantity or one of
  /// the customer's own pieces — never both, which is exactly what the
  /// server's own rule says. See `PickedPiece.toLine`.
  List<Map<String, dynamic>> get lines => [
    for (final piece in pieces) piece.toLine(),
  ];

  /// What was picked, resolved back to rows the screen can draw.
  ///
  /// The selection holds IDs; the row belongs to the catalogue. Copying
  /// it into the selection would leave two versions of one product to
  /// keep in step.
  List<PickedPiece> resolve({
    required String untitled,
    String? Function(WorkshopOwnPiece piece)? madeOn,
  }) => [
    for (final category in categories)
      for (final sub in category.subCategories)
        for (final product in sub.products)
          if (quantityOf(product.id) > 0)
            PickedPiece.fromProduct(
              product,
              quantityOf(product.id),
              untitled: untitled,
            ),
    for (final piece in availableOwn)
      if (holdsOwn(piece.id))
        PickedPiece.fromOwn(
          piece,
          price: ownPieces?.price ?? '0.00',
          untitled: untitled,
          madeOnLabel: madeOn?.call(piece),
        ),
  ];

  /// The same, unlabelled — for the payload, where no words are drawn.
  List<PickedPiece> get pieces => resolve(untitled: '');

  PieceSelectionState copyWith({
    List<WorkshopCategory>? categories,
    int? categoryId,
    int? subCategoryId,
    bool clearSubCategory = false,
    Map<int, int>? picked,
    Set<int>? pickedOwn,
    WorkshopOwnPieces? ownPieces,
    int? people,
    int? minPerPerson,
    int? maxPerPerson,
    WorkshopFamily? family,
    bool? loading,
    AppException? error,
    bool clearError = false,
  }) => PieceSelectionState(
    categories: categories ?? this.categories,
    categoryId: categoryId ?? this.categoryId,
    subCategoryId: clearSubCategory
        ? null
        : subCategoryId ?? this.subCategoryId,
    picked: picked ?? this.picked,
    pickedOwn: pickedOwn ?? this.pickedOwn,
    ownPieces: ownPieces ?? this.ownPieces,
    people: people ?? this.people,
    minPerPerson: minPerPerson ?? this.minPerPerson,
    maxPerPerson: maxPerPerson ?? this.maxPerPerson,
    family: family ?? this.family,
    loading: loading ?? this.loading,
    error: clearError ? null : error ?? this.error,
  );
}
