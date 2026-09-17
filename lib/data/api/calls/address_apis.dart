import 'package:dio/dio.dart';

import '../../../core/constants/enums/api/request_type.dart';
import '../../../core/types/result.dart';
import '../../models/terracotta/account/address.dart';
import '../../models/terracotta/content/delivery_zones.dart';
import '../api_service.dart';
import '../endpoints/terracotta_endpoints.dart';

/// The `address` group of the Terracotta API — short-address lookup,
/// the caller's saved addresses, and the public delivery-zone table.
///
/// Every method returns an `AsyncResult<...>` — pattern-match at the
/// call site. Nothing here throws.
///
/// Group-wide notes:
/// - **A Terracotta address is STRUCTURED, never a free-text line.**
///   `building_number` (4 digits), `street`, `district`, `postal_code`
///   (5 digits) and `additional_number` (4 digits) are all required;
///   `unit_number` and the 8-character `short_address` are optional.
/// - **The city is NOT a text field** — it is `delivery_zone_id`, from
///   [getDeliveryZones]. An address with no zone falls back to the
///   app-wide default fee.
/// - **The map pin does not price anything.** `lat` / `lng` are for the
///   courier's navigation; the delivery fee comes from the zone.
/// - **Money is a decimal STRING** (`"15.00"`), never a number. Parse
///   as a decimal; never round-trip it through `double`.
/// - **PUT and DELETE are written as PUT and DELETE here.** The
///   method-override interceptor rewrites them to POST at send time —
///   the production host blocks the real verbs. Never hand-write the
///   override.
class AddressApis {
  AddressApis._();

  // ─── Per-endpoint log flags ───────────────────────────────

  static ApiLogConfig logLookupShortAddress = kApiLogVerbose;
  static ApiLogConfig logGetAddresses = kApiLogVerbose;
  static ApiLogConfig logAddAddress = kApiLogVerbose;
  static ApiLogConfig logUpdateAddress = kApiLogVerbose;
  static ApiLogConfig logDeleteAddress = kApiLogVerbose;
  static ApiLogConfig logGetDeliveryZones = kApiLogVerbose;

  // ─── Mock setup ───────────────────────────────────────────

  /// Register mock responses for all endpoints in this class.
  /// Call once at app init when [ApiService.useMock] is true.
  static void installMocks() {
    ApiService.registerMock(
      endpoint: TerracottaEndpoints.addresses,
      type: RequestType.get,
      data: [
        {
          'id': 1,
          'label': 'Home',
          'address_line': 'Riyadh, Sheikh Hassan St',
          'lat': '24.7136000',
          'lng': '46.6753000',
          'phone': '+966500000000',
          'notes': '2nd floor, blue door',
          'is_default': true,
          'map_url': 'https://maps.google.com/?q=24.7136000,46.6753000',
        },
      ],
    );
    ApiService.registerMock(
      endpoint: TerracottaEndpoints.deliveryZones,
      type: RequestType.get,
      data: {
        'zones': [
          {
            'id': 1,
            'name': 'Riyadh',
            'fee': '15.00',
            'free_over': '200.00',
            'never_free': false,
          },
          {
            'id': 2,
            'name': 'Jeddah',
            'fee': '35.00',
            'free_over': null,
            'never_free': true,
          },
        ],
        'default_fee': '20.00',
        'free_delivery_over': '300.00',
      },
    );
  }

  // ─── API methods ──────────────────────────────────────────

  /// Resolve a Saudi 8-character short address (4 letters + 4 digits,
  /// e.g. `RCTB4329`) into full National Address fields plus a pin.
  ///
  /// Traps: this sits on the tight `auth` rate limiter (5 per minute),
  /// and it returns **503 by design** when the backend has no HERE API
  /// key — that is not a failure, it is the signal to fall through to
  /// the manual address fields. Creates nothing; feed the result into
  /// [addAddress].
  static AsyncResult<Map<String, dynamic>> lookupShortAddress({
    required String shortAddress,
    CancelToken? cancelToken,
    Duration? timeout,
  }) => ApiService.call(
    () => ApiService().post<Map<String, dynamic>>(
      TerracottaEndpoints.addressLookup,
      data: {'short_address': shortAddress},
      fromJson: (json) => json,
      logRequest: logLookupShortAddress.request,
      logResponse: logLookupShortAddress.response,
      cancelToken: cancelToken,
      timeout: timeout,
    ),
  );

  /// List the caller's saved addresses. Returns a flat list — at most
  /// one entry carries `is_default: true`.
  static AsyncResult<List<Address>> getAddresses({
    CancelToken? cancelToken,
    Duration? timeout,
  }) => ApiService.call(
    () => ApiService().getList<Address>(
      TerracottaEndpoints.addresses,
      fromJson: Address.fromJson,
      logRequest: logGetAddresses.request,
      logResponse: logGetAddresses.response,
      cancelToken: cancelToken,
      timeout: timeout,
    ),
  );

  /// Save a new address for the caller.
  ///
  /// Traps: [deliveryZoneId] is the CITY — omitting it prices delivery
  /// at the app-wide default fee, not at the pin's real city. [lat] and
  /// [lng] only steer the courier; they never move the price. Field
  /// errors come back as 422 keyed by the same name as the input
  /// (`errors.postal_code`, …), so show them under that field.
  static AsyncResult<Address> addAddress({
    required String buildingNumber,
    required String street,
    required String district,
    required String postalCode,
    required String additionalNumber,
    required double lat,
    required double lng,
    required String phone,
    String? label,
    String? unitNumber,
    String? shortAddress,
    int? deliveryZoneId,
    String? notes,
    bool? isDefault,
    CancelToken? cancelToken,
    Duration? timeout,
  }) => ApiService.call(
    () => ApiService().post<Address>(
      TerracottaEndpoints.addresses,
      data: {
        'building_number': buildingNumber,
        'street': street,
        'district': district,
        'postal_code': postalCode,
        'additional_number': additionalNumber,
        'lat': lat,
        'lng': lng,
        'phone': phone,
        if (label != null) 'label': label,
        if (unitNumber != null) 'unit_number': unitNumber,
        if (shortAddress != null) 'short_address': shortAddress,
        if (deliveryZoneId != null) 'delivery_zone_id': deliveryZoneId,
        if (notes != null) 'notes': notes,
        if (isDefault != null) 'is_default': isDefault,
      },
      fromJson: Address.fromJson,
      logRequest: logAddAddress.request,
      logResponse: logAddAddress.response,
      cancelToken: cancelToken,
      timeout: timeout,
    ),
  );

  /// Replace a saved address wholesale.
  ///
  /// Traps: this is a PUT, not a PATCH — the National Address fields
  /// are required even when only [notes] changed, so send the full
  /// record back. The verb stays PUT here; the method-override
  /// interceptor turns it into a POST on the wire.
  static AsyncResult<Address> updateAddress(
    String addressId, {
    required String buildingNumber,
    required String street,
    required String district,
    required String postalCode,
    required String additionalNumber,
    required double lat,
    required double lng,
    required String phone,
    String? label,
    String? unitNumber,
    String? shortAddress,
    int? deliveryZoneId,
    String? notes,
    bool? isDefault,
    CancelToken? cancelToken,
    Duration? timeout,
  }) => ApiService.call(
    () => ApiService().put<Address>(
      TerracottaEndpoints.address(addressId),
      data: {
        'building_number': buildingNumber,
        'street': street,
        'district': district,
        'postal_code': postalCode,
        'additional_number': additionalNumber,
        'lat': lat,
        'lng': lng,
        'phone': phone,
        if (label != null) 'label': label,
        if (unitNumber != null) 'unit_number': unitNumber,
        if (shortAddress != null) 'short_address': shortAddress,
        if (deliveryZoneId != null) 'delivery_zone_id': deliveryZoneId,
        if (notes != null) 'notes': notes,
        if (isDefault != null) 'is_default': isDefault,
      },
      fromJson: Address.fromJson,
      logRequest: logUpdateAddress.request,
      logResponse: logUpdateAddress.response,
      cancelToken: cancelToken,
      timeout: timeout,
    ),
  );

  /// Delete a saved address.
  ///
  /// Traps: the verb stays DELETE here — the override interceptor
  /// converts it. The success envelope carries `data: null`, which the
  /// shared single-object handler rejects, so a 200 here still lands as
  /// a `ValidationException` until `handleSingleResponse` learns to
  /// allow an empty `data`. Treat a failure whose message reads
  /// "Expected `data` on a successful response" as a success for now.
  static AsyncResult<Map<String, dynamic>> deleteAddress(
    String addressId, {
    CancelToken? cancelToken,
    Duration? timeout,
  }) => ApiService.call(
    () => ApiService().delete<Map<String, dynamic>>(
      TerracottaEndpoints.address(addressId),
      fromJson: (json) => json,
      logRequest: logDeleteAddress.request,
      logResponse: logDeleteAddress.response,
      cancelToken: cancelToken,
      timeout: timeout,
    ),
  );

  /// Public list of deliverable cities with each one's fee and
  /// free-over threshold, plus the app-wide fallbacks. Fetch it before
  /// sign-in so the delivery fee can be shown to a guest.
  ///
  /// Traps: `fee`, `free_over`, `default_fee` and `free_delivery_over`
  /// are decimal STRINGS. Free delivery is three-state per city —
  /// `never_free` wins, else the city's own `free_over`, else the
  /// app-wide `free_delivery_over`, else never free — and the
  /// threshold is measured on the POST-discount goods total. A
  /// discount code never reduces the delivery fee itself.
  static AsyncResult<DeliveryZones> getDeliveryZones({
    CancelToken? cancelToken,
    Duration? timeout,
  }) => ApiService.call(
    () => ApiService().get<DeliveryZones>(
      TerracottaEndpoints.deliveryZones,
      fromJson: DeliveryZones.fromJson,
      logRequest: logGetDeliveryZones.request,
      logResponse: logGetDeliveryZones.response,
      cancelToken: cancelToken,
      timeout: timeout,
    ),
  );
}
