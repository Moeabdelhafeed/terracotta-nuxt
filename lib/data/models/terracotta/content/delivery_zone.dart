// Package imports:
import 'package:freezed_annotation/freezed_annotation.dart';

part 'delivery_zone.freezed.dart';
part 'delivery_zone.g.dart';

/// One deliverable city — an element of `data.zones` in
/// `GET /api/delivery-zones`, and the thing an address is pinned to by
/// `delivery_zone_id`.
///
/// The live capture holds **113** of these, every Saudi city the studio
/// ships to. That is a long list: give the picker a search field, not a
/// dropdown.
///
/// **EVERY MONETARY FIELD IS A DECIMAL STRING** (`"20.00"`). Never
/// double, never num — see `PriceQuote` for why.
///
/// [fee] is this zone's flat delivery charge and is always present; the
/// capture uses `"20.00"`, `"35.00"` and `"50.00"`. It is NOT the
/// payload's `default_fee` (`"25.00"`), which is a fallback for an
/// address that matched no zone at all — no listed zone charges it.
///
/// **[freeOver] and [neverFree] are a two-level override of the
/// payload-wide `free_delivery_over`, and the precedence matters:**
///
/// 1. [neverFree] is `true` → delivery is **never** free here, whatever
///    the basket is worth. 60 of the 113 zones. It is a veto, and the
///    capture contains no zone that sets it alongside a [freeOver], so
///    check it FIRST.
/// 2. [freeOver] is non-null → free above **this** threshold. 19 zones.
/// 3. Otherwise → fall back to the payload's `free_delivery_over`. 34
///    zones. A null [freeOver] does not mean "never free"; that is what
///    [neverFree] is for, and conflating the two quietly stops
///    promising free delivery to a third of the country.
///
/// `DeliveryZones.freeDeliveryThresholdFor` implements exactly this —
/// call it rather than re-deriving the precedence per screen.
@freezed
abstract class DeliveryZone with _$DeliveryZone {
  const factory DeliveryZone({
    /// CMS row key — what an address's `delivery_zone_id` points at.
    required int id,

    /// City name as the CMS spells it (`"Riyadh"`, `"Al Diriyah"`).
    required String name,

    /// Flat delivery charge for this zone. Decimal string.
    required String fee,

    /// Zone-specific free-delivery threshold. Null → use the payload's
    /// `free_delivery_over` instead (unless [neverFree]).
    String? freeOver,

    /// Delivery is never free here, at any basket value. Overrides both
    /// [freeOver] and the payload-wide threshold.
    required bool neverFree,
  }) = _DeliveryZone;

  factory DeliveryZone.fromJson(Map<String, dynamic> json) =>
      _$DeliveryZoneFromJson(json);
}
