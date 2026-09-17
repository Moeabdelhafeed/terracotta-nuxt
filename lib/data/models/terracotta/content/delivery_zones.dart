// Package imports:
import 'package:freezed_annotation/freezed_annotation.dart';

// Project imports:
import 'delivery_zone.dart';

part 'delivery_zones.freezed.dart';
part 'delivery_zones.g.dart';

/// The whole of `GET /api/delivery-zones` — the [zones] list plus the
/// two payload-wide fallbacks the individual zones override.
///
/// This is an **object, not a bare list**: parsing `data` straight into
/// `List<DeliveryZone>` throws, and loses the two numbers that decide
/// what an unlisted address pays.
///
/// **EVERY MONETARY FIELD IS A DECIMAL STRING.** Never double, never num.
///
/// [defaultFee] (`"25.00"` live) applies to an address that matched no
/// zone. Note it is not equal to any listed zone's fee — a screen
/// showing `"25.00"` is telling you the zone lookup failed, not that it
/// found a cheap city.
///
/// [freeDeliveryOver] (`"300.00"` live) is the baseline free-delivery
/// threshold, used only for zones that neither set their own
/// `free_over` nor set `never_free` — see
/// [freeDeliveryThresholdFor], which is the one place that precedence
/// should live.
///
/// This is quote *input*, not quote output. The authoritative delivery
/// charge for a real basket is the `delivery_fee` on the `PriceQuote`
/// from `POST /api/shop/cart/quote`; these numbers are for the "delivery
/// from X" copy shown before the customer has picked an address.
@freezed
abstract class DeliveryZones with _$DeliveryZones {
  const factory DeliveryZones({
    /// Every deliverable city. 113 of them in the live capture.
    required List<DeliveryZone> zones,

    /// Charge for an address that matched no zone. Decimal string.
    required String defaultFee,

    /// Baseline free-delivery threshold. Decimal string.
    required String freeDeliveryOver,
  }) = _DeliveryZones;

  const DeliveryZones._();

  factory DeliveryZones.fromJson(Map<String, dynamic> json) =>
      _$DeliveryZonesFromJson(json);

  /// The basket total above which delivery is free in [zone], or null
  /// when it never is.
  ///
  /// Implements the documented precedence in one place:
  /// `neverFree` → null, else the zone's own `freeOver`, else this
  /// payload's [freeDeliveryOver]. Returns a decimal string; compare it
  /// as a decimal, not as a double.
  String? freeDeliveryThresholdFor(DeliveryZone zone) {
    if (zone.neverFree) return null;
    return zone.freeOver ?? freeDeliveryOver;
  }

  /// The zone with this id, or null when the list does not carry it —
  /// in which case the caller charges [defaultFee].
  DeliveryZone? zoneById(int id) {
    for (final zone in zones) {
      if (zone.id == id) return zone;
    }
    return null;
  }
}
