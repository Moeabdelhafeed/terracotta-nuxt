// Package imports:
import 'package:dio/dio.dart';
// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ReverseGeocodingResult {
  const ReverseGeocodingResult({
    required this.name,
    required this.formattedAddress,
  });

  /// Short label — street, place of interest, neighborhood, etc.
  final String name;

  /// Full address line as Google returns it.
  final String formattedAddress;
}

/// Structured address parts from a reverse lookup — shaped for form
/// filling (`AddressForm.onReverseGeocode`). Any part may be empty.
class GeocodedAddress {
  const GeocodedAddress({
    this.street = '',
    this.area = '',
    this.city = '',
    this.state = '',
    this.postalCode = '',
    this.countryIso = '',
    this.formattedAddress = '',
  });

  /// Route + street number (`Rainbow Street 15`).
  final String street;

  /// Neighborhood / sublocality (`Sweifieh`).
  final String area;

  /// Locality (`Amman`).
  final String city;

  /// Top administrative area — governorate / state (`Amman Governorate`).
  final String state;

  final String postalCode;

  /// ISO 3166-1 alpha-2 (`JO`).
  final String countryIso;

  final String formattedAddress;
}

/// Google Maps Geocoding API (reverse lookup).
///
/// Pass an API key via the constructor (`ReverseGeocodingService(apiKey:
/// ...)` — Remote Config / `--dart-define` / env).
class ReverseGeocodingService {
  static const String _geocodeUrl =
      'https://maps.googleapis.com/maps/api/geocode/json';

  ReverseGeocodingService({String? apiKey, Dio? dio})
    : _apiKey = apiKey ?? 'YOUR_GOOGLE_MAPS_API_KEY',
      _dio = dio ?? Dio();

  final String _apiKey;
  final Dio _dio;

  bool get isConfigured =>
      _apiKey.isNotEmpty && _apiKey != 'YOUR_GOOGLE_MAPS_API_KEY';

  Future<ReverseGeocodingResult?> reverseGeocode(LatLng latLng) async {
    if (!isConfigured) return null;

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        _geocodeUrl,
        queryParameters: {
          'latlng': '${latLng.latitude},${latLng.longitude}',
          'key': _apiKey,
        },
      );

      final data = response.data;
      if (data == null || data['status'] != 'OK') return null;

      final results = (data['results'] as List?)?.cast<Map<String, dynamic>>();
      if (results == null || results.isEmpty) return null;

      final first = results.first;
      final formatted = (first['formatted_address'] as String?)?.trim() ?? '';
      final comps =
          (first['address_components'] as List?)
              ?.cast<Map<String, dynamic>>() ??
          const [];

      // Heuristic: route > point_of_interest > establishment >
      // neighborhood > sublocality > locality.
      String? pickByType(List<String> types) {
        for (final c in comps) {
          final ct = (c['types'] as List)
              .cast<dynamic>()
              .map((e) => e.toString())
              .toList();
          if (types.any(ct.contains)) {
            return (c['short_name'] as String?) ?? (c['long_name'] as String?);
          }
        }
        return null;
      }

      final name =
          pickByType(['route']) ??
          pickByType(['point_of_interest']) ??
          pickByType(['establishment']) ??
          pickByType(['neighborhood']) ??
          pickByType(['sublocality', 'sublocality_level_1']) ??
          pickByType(['locality']) ??
          formatted.split(',').first.trim();

      return ReverseGeocodingResult(name: name, formattedAddress: formatted);
    } on DioException catch (e) {
      if (kDebugMode) debugPrint('[ReverseGeocodingService] HTTP error: $e');
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('[ReverseGeocodingService] Error: $e');
      return null;
    }
  }

  /// Reverse lookup shaped for FORM FILLING — parses the address
  /// components into structured parts (`AddressForm.onReverseGeocode`
  /// plugs this in directly). Null when unconfigured / no result.
  Future<GeocodedAddress?> reverseGeocodeAddress(LatLng latLng) async {
    if (!isConfigured) return null;

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        _geocodeUrl,
        queryParameters: {
          'latlng': '${latLng.latitude},${latLng.longitude}',
          'key': _apiKey,
        },
      );

      final data = response.data;
      if (data == null || data['status'] != 'OK') return null;

      final results = (data['results'] as List?)?.cast<Map<String, dynamic>>();
      if (results == null || results.isEmpty) return null;

      final first = results.first;
      final formatted = (first['formatted_address'] as String?)?.trim() ?? '';
      final comps =
          (first['address_components'] as List?)
              ?.cast<Map<String, dynamic>>() ??
          const [];

      String pick(List<String> types, {bool short = false}) {
        for (final c in comps) {
          final ct = (c['types'] as List)
              .cast<dynamic>()
              .map((e) => e.toString())
              .toList();
          if (types.any(ct.contains)) {
            final key = short ? 'short_name' : 'long_name';
            return ((c[key] as String?) ?? (c['long_name'] as String?) ?? '')
                .trim();
          }
        }
        return '';
      }

      final route = pick(['route']);
      final number = pick(['street_number']);

      return GeocodedAddress(
        street: [route, number].where((s) => s.isNotEmpty).join(' '),
        area: pick(['neighborhood']).isNotEmpty
            ? pick(['neighborhood'])
            : pick(['sublocality', 'sublocality_level_1']),
        city: pick(['locality']),
        state: pick(['administrative_area_level_1']),
        postalCode: pick(['postal_code']),
        countryIso: pick(['country'], short: true).toUpperCase(),
        formattedAddress: formatted,
      );
    } on DioException catch (e) {
      if (kDebugMode) debugPrint('[ReverseGeocodingService] HTTP error: $e');
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('[ReverseGeocodingService] Error: $e');
      return null;
    }
  }
}
