import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as mt;

/// Geographic math — spherical distance/heading/area, polygon containment,
/// polyline simplification, encoded-polyline decode/encode.
///
/// Thin wrapper over [maps_toolkit] that uses [google_maps_flutter]'s
/// [LatLng] throughout so callers only depend on one package. All results
/// are computed on a spherical (geodesic) Earth — the accurate model for
/// real-world coordinates.
class GeoUtils {
  GeoUtils._();

  static mt.LatLng _to(LatLng p) => mt.LatLng(p.latitude, p.longitude);
  static LatLng _from(mt.LatLng p) => LatLng(p.latitude, p.longitude);
  static List<mt.LatLng> _toAll(List<LatLng> xs) => xs.map(_to).toList();
  static List<LatLng> _fromAll(List<mt.LatLng> xs) => xs.map(_from).toList();

  // ─── Distance & heading ────────────────────────────────────

  /// Great-circle distance between [a] and [b] in **meters**.
  static double distanceBetween(LatLng a, LatLng b) =>
      mt.SphericalUtil.computeDistanceBetween(_to(a), _to(b)).toDouble();

  /// Heading (bearing) from [a] to [b] in degrees (`-180..180`, 0 = north).
  static double heading(LatLng a, LatLng b) =>
      mt.SphericalUtil.computeHeading(_to(a), _to(b)).toDouble();

  /// Angular distance between [a] and [b] in **radians**.
  static double angleBetween(LatLng a, LatLng b) =>
      mt.SphericalUtil.computeAngleBetween(_to(a), _to(b)).toDouble();

  /// Point [distanceMeters] from [origin] along [headingDegrees].
  static LatLng offset(
    LatLng origin,
    double distanceMeters,
    double headingDegrees,
  ) => _from(
    mt.SphericalUtil.computeOffset(
      _to(origin),
      distanceMeters,
      headingDegrees,
    ),
  );

  /// Point on the great-circle between [a] and [b] at [fraction] (`0..1`).
  static LatLng interpolate(LatLng a, LatLng b, double fraction) =>
      _from(mt.SphericalUtil.interpolate(_to(a), _to(b), fraction));

  // ─── Paths & polygons ──────────────────────────────────────

  /// Total great-circle length of [path] in **meters**.
  static double pathLength(List<LatLng> path) =>
      mt.SphericalUtil.computeLength(_toAll(path)).toDouble();

  /// Unsigned polygon area in **square meters**.
  static double polygonArea(List<LatLng> polygon) =>
      mt.SphericalUtil.computeArea(_toAll(polygon)).toDouble();

  /// Signed polygon area (positive = clockwise winding) in square meters.
  static double polygonSignedArea(List<LatLng> polygon) =>
      mt.SphericalUtil.computeSignedArea(_toAll(polygon)).toDouble();

  /// True if [point] lies inside [polygon]. Polygon is always treated as
  /// closed (first vertex implicitly joins the last).
  static bool isPointInPolygon(LatLng point, List<LatLng> polygon) =>
      mt.PolygonUtil.containsLocation(_to(point), _toAll(polygon), true);

  /// True if [point] is within [toleranceMeters] of the polygon's edge.
  static bool isOnPolygonEdge(
    LatLng point,
    List<LatLng> polygon, {
    double toleranceMeters = 0.1,
  }) => mt.PolygonUtil.isLocationOnEdge(
    _to(point),
    _toAll(polygon),
    true,
    tolerance: toleranceMeters,
  );

  /// True if [point] is within [toleranceMeters] of any segment in [path].
  static bool isOnPath(
    LatLng point,
    List<LatLng> path, {
    double toleranceMeters = 0.1,
  }) => mt.PolygonUtil.isLocationOnPath(
    _to(point),
    _toAll(path),
    true,
    tolerance: toleranceMeters,
  );

  /// Index of the segment in [path] that [point] lies on (within tolerance),
  /// or `-1` if none.
  static int indexOnPath(
    LatLng point,
    List<LatLng> path, {
    double toleranceMeters = 0.1,
  }) => mt.PolygonUtil.locationIndexOnPath(
    _to(point),
    _toAll(path),
    true,
    tolerance: toleranceMeters,
  );

  /// Shortest distance from [point] to the segment ([start], [end]) in **meters**.
  static double distanceToLine(LatLng point, LatLng start, LatLng end) =>
      mt.PolygonUtil.distanceToLine(
        _to(point),
        _to(start),
        _to(end),
      ).toDouble();

  /// Douglas-Peucker polyline simplification. Larger tolerance → fewer points.
  static List<LatLng> simplify(
    List<LatLng> path, {
    double toleranceMeters = 5.0,
  }) => _fromAll(mt.PolygonUtil.simplify(_toAll(path), toleranceMeters));

  /// True if [polygon] is closed (first vertex equals last vertex).
  static bool isClosedPolygon(List<LatLng> polygon) =>
      mt.PolygonUtil.isClosedPolygon(_toAll(polygon));

  // ─── Encoded polylines (Google Directions format) ─────────

  /// Decode a Google-encoded polyline string into points.
  static List<LatLng> decodePolyline(String encoded) =>
      _fromAll(mt.PolygonUtil.decode(encoded));

  /// Encode points into a Google-encoded polyline string.
  static String encodePolyline(List<LatLng> path) =>
      mt.PolygonUtil.encode(_toAll(path));
}
