// Package imports:
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LatLngConverter extends JsonConverter<LatLng, Map<String, dynamic>> {
  const LatLngConverter();

  @override
  LatLng fromJson(Map<String, dynamic> json) {
    final lat = (json['lat'] ?? json['latitude'] ?? json['Latitude']) as num?;
    final lng =
        (json['lng'] ?? json['lon'] ?? json['longitude'] ?? json['Longitude'])
            as num?;
    if (lat == null || lng == null) {
      throw const FormatException(
        'Invalid LatLng JSON: expected {lat/lng} or {latitude/longitude}.',
      );
    }
    return LatLng(lat.toDouble(), lng.toDouble());
  }

  @override
  Map<String, dynamic> toJson(LatLng object) {
    return <String, dynamic>{
      'lat': object.latitude,
      'lng': object.longitude,
    };
  }
}

class LatLngListConverter extends JsonConverter<List<LatLng>, List<dynamic>> {
  const LatLngListConverter();

  @override
  List<LatLng> fromJson(List<dynamic> json) {
    return json
        .map<LatLng>((item) {
          if (item is Map<String, dynamic>) {
            return const LatLngConverter().fromJson(item);
          }
          if (item is List && item.length >= 2) {
            final lat = item[0] as num?;
            final lng = item[1] as num?;
            if (lat == null || lng == null) {
              throw const FormatException('Invalid LatLng tuple in list.');
            }
            return LatLng(lat.toDouble(), lng.toDouble());
          }
          throw const FormatException('Unsupported LatLng list item.');
        })
        .toList(growable: false);
  }

  @override
  List<dynamic> toJson(List<LatLng> object) {
    return object
        .map((e) => const LatLngConverter().toJson(e))
        .toList(growable: false);
  }
}
