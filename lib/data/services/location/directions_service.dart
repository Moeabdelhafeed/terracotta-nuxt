// Package imports:
import 'package:dio/dio.dart';
// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Google Maps Directions API client. Returns a decoded polyline for
/// the route between two [LatLng] points.
///
/// Wire an API key via the constructor (`DirectionsService(apiKey:
/// ...)` — pull from Remote Config, `--dart-define`, or env).
class DirectionsService {
  static const String _directionsUrl =
      'https://maps.googleapis.com/maps/api/directions/json';

  DirectionsService({String? apiKey, Dio? dio})
    : _apiKey = apiKey ?? 'YOUR_GOOGLE_MAPS_API_KEY',
      _dio = dio ?? Dio();

  final String _apiKey;
  final Dio _dio;

  bool get isConfigured =>
      _apiKey.isNotEmpty && _apiKey != 'YOUR_GOOGLE_MAPS_API_KEY';

  /// Get route between two points. Returns `null` on failure (missing
  /// key, HTTP error, non-OK API status, empty response).
  Future<List<LatLng>?> getRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    if (!isConfigured) {
      if (kDebugMode) debugPrint('[DirectionsService] API key not configured');
      return null;
    }

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        _directionsUrl,
        queryParameters: {
          'origin': '${origin.latitude},${origin.longitude}',
          'destination': '${destination.latitude},${destination.longitude}',
          'mode': 'driving',
          'key': _apiKey,
        },
      );

      final data = response.data;
      if (data == null || data['status'] != 'OK') {
        if (kDebugMode) {
          debugPrint(
            '[DirectionsService] API error: ${data?['status']} - ${data?['error_message'] ?? 'Unknown error'}',
          );
        }
        return null;
      }

      final routes = (data['routes'] as List?)?.cast<Map<String, dynamic>>();
      if (routes == null || routes.isEmpty) return null;

      final overview =
          routes.first['overview_polyline'] as Map<String, dynamic>?;
      final encoded = overview?['points'] as String?;
      if (encoded == null || encoded.isEmpty) return null;

      return _decodePolyline(encoded);
    } on DioException catch (e) {
      if (kDebugMode) debugPrint('[DirectionsService] HTTP error: $e');
      return null;
    } catch (e, st) {
      if (kDebugMode) debugPrint('[DirectionsService] Error: $e\n$st');
      return null;
    }
  }

  /// Decode Google's encoded polyline string to a list of [LatLng]
  /// points — same algorithm the maps SDKs use internally.
  List<LatLng> _decodePolyline(String encoded) {
    final points = <LatLng>[];
    var index = 0;
    var lat = 0;
    var lng = 0;

    while (index < encoded.length) {
      var result = 1;
      var shift = 0;
      int b;
      do {
        b = encoded.codeUnitAt(index++) - 63 - 1;
        result += b << shift;
        shift += 5;
      } while (b >= 0x1f);
      lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      result = 1;
      shift = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63 - 1;
        result += b << shift;
        shift += 5;
      } while (b >= 0x1f);
      lng += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      points.add(LatLng(lat * 1e-5, lng * 1e-5));
    }

    return points;
  }
}
