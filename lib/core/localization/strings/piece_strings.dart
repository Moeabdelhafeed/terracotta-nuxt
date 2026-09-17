import '../../../generated/l10n.dart';
import '../tr.dart';

/// «قطعي» — the things the customer has made at the studio.
class PieceStrings {
  PieceStrings._();

  static String get title => Tr.t('pieces_title', S.current.pieces_title);

  static String get empty => Tr.t('pieces_empty', S.current.pieces_empty);

  static String get emptyBody =>
      Tr.t('pieces_empty_body', S.current.pieces_empty_body);

  /// The studio lists no workshop that takes pieces back, so there is
  /// nowhere to read them from. NOT the same as owning none — and the
  /// copy says so, because a customer with a shelf of cups must not be
  /// told they have never made one.
  static String get noSource =>
      Tr.t('pieces_no_source', S.current.pieces_no_source);

  static String get noSourceBody =>
      Tr.t('pieces_no_source_body', S.current.pieces_no_source_body);

  static String madeOn(String date) =>
      Tr.t('pieces_made_on', S.current.pieces_made_on(date));

  /// A piece is named by the LABEL its photos were grouped under, and
  /// an older row may have none.
  static String get untitled =>
      Tr.t('pieces_untitled', S.current.pieces_untitled);

  /// Already used in another booking — `is_available_to_paint: false`.
  /// It is still the customer's; it just cannot be booked in again.
  static String get painted => Tr.t('pieces_painted', S.current.pieces_painted);

  static String get available =>
      Tr.t('pieces_available', S.current.pieces_available);

  /// The flat own-piece rate, already formatted as money.
  static String paintPrice(String amount) =>
      Tr.t('pieces_paint_price', S.current.pieces_paint_price(amount));
}
