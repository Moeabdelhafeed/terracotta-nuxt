// Package imports:
import 'package:freezed_annotation/freezed_annotation.dart';

part 'address.freezed.dart';
part 'address.g.dart';

/// A saved delivery address — `GET /api/addresses` (a bare list in
/// `data`), and the echo of `POST` / `PUT /api/addresses/{id}`.
///
/// Default first. This is what populates the checkout address picker,
/// and it is where the shop's delivery fee comes from — see
/// [deliveryFee].
///
/// **[lat] and [lng] ARE STRINGS**, not doubles — `"24.7136000"`, seven
/// decimal places, sent as text exactly like the money fields. Hand
/// them to a map widget through [latitude] / [longitude], which parse
/// leniently and return null rather than throwing on a malformed pair.
///
/// **[deliveryFee] IS A DECIMAL STRING** (`"20.00"`). It is a
/// PREVIEW — the quote endpoints (`POST /api/shop/cart/quote`) are what
/// actually price an order, and the fee there can differ (free over a
/// threshold, per-zone overrides). Show this one in the picker; charge
/// the quote's.
///
/// **The Saudi National Address block is real and the spec omits it.**
/// The OpenAPI document describes only `{id, label, address_line, lat,
/// lng, phone, notes, is_default, map_url}`. The live server also sends
/// [buildingNumber], [street], [district], [postalCode],
/// [additionalNumber], [unitNumber] and [shortAddress] — the fields the
/// Saudi post office's format is made of, and the ones
/// `GET /api/addresses/lookup` fills in from a short code. Believe the
/// server.
///
/// [addressLine] is the server-composed one-line rendering of that
/// block (`"8228, Prince Turki Road, Unit 12, Al Muhammadiyah, Riyadh,
/// 12362, 2933"`). Display it; do not re-compose it from the parts, the
/// order is locale-dependent.
///
/// Nullability follows the two captured addresses: [notes],
/// [unitNumber] and [shortAddress] are each null in one of them. Every
/// other key is present and non-null in both — including the delivery
/// trio, which the live server resolves for every saved address.
@freezed
abstract class Address with _$Address {
  const factory Address({
    required int id,

    /// Customer-chosen name (`"Home"`), and **NULL when they did not
    /// give one** — `label` is optional on `POST /api/addresses`, and
    /// an address saved without it comes back with `label: null`.
    /// Probed live 2026-09-06; the captured fixture happens to have one
    /// on every row, which is why this was `required` and would have
    /// thrown on the first unnamed address a customer saved.
    String? label,

    /// Server-composed single-line address. Display as-is.
    required String addressLine,

    /// Latitude as a decimal STRING. Read [latitude].
    required String lat,

    /// Longitude as a decimal STRING. Read [longitude].
    required String lng,

    /// Contact number for the courier, E.164.
    required String phone,

    /// Free-text courier note (`"blue door"`).
    String? notes,

    // ── Saudi National Address ───────────────────────────────────
    required String buildingNumber,
    required String street,
    required String district,
    required String postalCode,

    /// The 4-digit secondary number of the national address format.
    required String additionalNumber,

    /// Flat / unit number. Null when the building has no units.
    String? unitNumber,

    /// The 8-character national short code (`"RCTB4329"`). Null until
    /// the address is looked up or the customer supplies one.
    String? shortAddress,

    // ── Delivery zone ────────────────────────────────────────────
    /// Zone the coordinates resolved into; keys into
    /// `GET /api/delivery-zones`.
    required int deliveryZoneId,

    /// Human-readable zone name (`"Riyadh"`). Already localized.
    required String deliveryZone,

    /// Zone fee as a DECIMAL STRING (`"20.00"`). Preview only — the
    /// quote endpoint is authoritative.
    required String deliveryFee,

    /// Exactly one saved address has this set. Creating the first
    /// address sets it automatically; sending `is_default` on a write
    /// promotes that one and demotes the rest.
    required bool isDefault,

    /// Ready-made `maps.google.com/?q=lat,lng` link.
    required String mapUrl,
  }) = _Address;

  const Address._();

  factory Address.fromJson(Map<String, dynamic> json) =>
      _$AddressFromJson(json);

  /// [lat] parsed, or null if the server sent something unparseable.
  double? get latitude => double.tryParse(lat);

  /// [lng] parsed, or null if the server sent something unparseable.
  double? get longitude => double.tryParse(lng);
}
