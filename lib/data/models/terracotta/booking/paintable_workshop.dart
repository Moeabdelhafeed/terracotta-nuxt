import 'package:freezed_annotation/freezed_annotation.dart';

import '../core/api_image.dart';

part 'paintable_workshop.freezed.dart';
part 'paintable_workshop.g.dart';

/// A paint workshop that accepts a piece made in this booking.
///
/// `paintable_at` on a **completed** `make_your_piece` booking, and
/// empty on every other kind and every other status. There can be more
/// than one: the studio may run several paint sessions that take the
/// same object.
///
/// **Completed is the gate, and it means FIRED.** A piece does not
/// become paintable the moment the session ends — the studio has to
/// mark the booking completed first — so this list stays empty through
/// `preparing` and the button cannot appear before then.
@freezed
abstract class PaintableWorkshop with _$PaintableWorkshop {
  const factory PaintableWorkshop({
    /// The WORKSHOP's id — confirmed by the backend on 2026-09-15, and
    /// what «لوّن قطعتك» opens the schedule for.
    ///
    /// **Nullable, though the button needs it.** `/docs.openapi` only
    /// ever shows `paintable_at: []`, so nothing proves the key is
    /// always there; declared `required` a row without one threw
    /// inside `fromJson` and took the WHOLE booking down with it — a
    /// detail page that will not open because of an upsell. A row with
    /// no id is dropped instead and the button goes with it, which is
    /// the same outcome as the empty list the app already handles.
    ///
    /// Read it through [isReachable] rather than force-unwrapping.
    int? id,
    String? title,
    ApiImage? image,
  }) = _PaintableWorkshop;

  const PaintableWorkshop._();

  factory PaintableWorkshop.fromJson(Map<String, dynamic> json) =>
      _$PaintableWorkshopFromJson(json);

  /// Whether this option can actually be opened. Without an id there
  /// is no schedule to send anybody to.
  bool get isReachable => id != null;
}
