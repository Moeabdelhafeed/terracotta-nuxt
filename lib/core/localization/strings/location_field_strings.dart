import '../../../generated/l10n.dart';
import '../tr.dart';

/// Strings for the `location_field_` prefix family — location-field call
/// sites go through this class instead of `Tr.t`/`S.current` directly.
class LocationFieldStrings {
  LocationFieldStrings._();

  static String get label =>
      Tr.t('location_field.label', S.current.location_field_label);
  static String get latitude =>
      Tr.t('location_field.latitude', S.current.location_field_latitude);
  static String get longitude =>
      Tr.t('location_field.longitude', S.current.location_field_longitude);
  static String get useCurrent =>
      Tr.t('location_field.use_current', S.current.location_field_use_current);
  static String get pickMap =>
      Tr.t('location_field.pick_map', S.current.location_field_pick_map);
  static String get unavailable =>
      Tr.t('location_field.unavailable', S.current.location_field_unavailable);
  static String get confirm =>
      Tr.t('location_field.confirm', S.current.location_field_confirm);
  static String get latRange =>
      Tr.t('location_field.lat_range', S.current.location_field_lat_range);
  static String get lngRange =>
      Tr.t('location_field.lng_range', S.current.location_field_lng_range);
}
