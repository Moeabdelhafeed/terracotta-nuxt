import '../../../generated/l10n.dart';
import '../number_formatter.dart';
import '../tr.dart';

/// «عناويني» — the saved addresses, and the form behind them.
///
/// The address is STRUCTURED, not a free-text line: building number,
/// street, district, postal code, additional number, an optional unit,
/// and the optional eight-character short national address. The CITY is
/// `delivery_zone_id` rather than text, because the city is what
/// carries the delivery fee.
class AddressStrings {
  AddressStrings._();

  static String get add => Tr.t('address_add', S.current.address_add);
  static String get edit => Tr.t('address_edit', S.current.address_edit);
  static String get save => Tr.t('address_save', S.current.address_save);

  static String get isDefault =>
      Tr.t('address_default', S.current.address_default);
  static String get makeDefault =>
      Tr.t('address_make_default', S.current.address_make_default);

  static String get delete => Tr.t('address_delete', S.current.address_delete);
  static String get deleteTitle =>
      Tr.t('address_delete_title', S.current.address_delete_title);
  static String get deleteBody =>
      Tr.t('address_delete_body', S.current.address_delete_body);

  /// The Saudi short national address — four letters then four digits.
  ///
  /// A SHORTCUT, not a gate. Plenty of customers do not know theirs, so
  /// every manual field stays visible and usable without ever touching
  /// it — which is why "not found" and "unavailable" read as notes
  /// rather than as errors.
  static String get shortLabel =>
      Tr.t('address_short_label', S.current.address_short_label);
  static String get shortHint =>
      Tr.t('address_short_hint', S.current.address_short_hint);
  static String get shortHelp =>
      Tr.t('address_short_help', S.current.address_short_help);
  static String get shortFind =>
      Tr.t('address_short_find', S.current.address_short_find);
  static String get shortInvalid =>
      Tr.t('address_short_invalid', S.current.address_short_invalid);
  static String get shortNotFound =>
      Tr.t('address_short_not_found', S.current.address_short_not_found);
  static String get shortUnavailable => Tr.t(
    'address_short_unavailable',
    S.current.address_short_unavailable,
  );
  static String get shortTooFast =>
      Tr.t('address_short_too_fast', S.current.address_short_too_fast);
  static String get shortFound =>
      Tr.t('address_short_found', S.current.address_short_found);
  static String get orManual =>
      Tr.t('address_or_manual', S.current.address_or_manual);

  static String get labelField =>
      Tr.t('address_label_field', S.current.address_label_field);
  static String get labelHint =>
      Tr.t('address_label_hint', S.current.address_label_hint);
  static String get city => Tr.t('address_city', S.current.address_city);
  static String get street => Tr.t('address_street', S.current.address_street);
  static String get district =>
      Tr.t('address_district', S.current.address_district);
  static String get building =>
      Tr.t('address_building', S.current.address_building);
  static String get additional =>
      Tr.t('address_additional', S.current.address_additional);
  static String get postal => Tr.t('address_postal', S.current.address_postal);
  static String get unit => Tr.t('address_unit', S.current.address_unit);
  static String get notes => Tr.t('address_notes', S.current.address_notes);
  static String get phone => Tr.t('address_phone', S.current.address_phone);

  static String get pin => Tr.t('address_pin', S.current.address_pin);
  static String get pinSet =>
      Tr.t('address_pin_set', S.current.address_pin_set);
  static String get pinMissing =>
      Tr.t('address_pin_missing', S.current.address_pin_missing);

  static String get saved => Tr.t('address_saved', S.current.address_saved);
  static String get deleted =>
      Tr.t('address_deleted', S.current.address_deleted);

  /// Field-level refusals, named after the field they are under — a
  /// bare "required" under one of nine boxes says nothing about which.
  static String required(String field) => AppNumbers.localizeDigits(
    Tr.t('address_required', S.current.address_required(field)),
  );
  static String digitsExactly(int count) => AppNumbers.localizeDigits(
    Tr.t('address_digits_exactly', S.current.address_digits_exactly(count)),
  );

  /// EXAMPLES, not the field's own name repeated.
  ///
  /// The name is drawn as a header above the box by the module's
  /// `identifier`; a placeholder saying the same thing put the same
  /// word on screen twice, once above the box and once inside it. A
  /// real example earns the space — «مثال: شارع ابي الكرم» tells a
  /// customer what shape of answer belongs there.
  static String get hintStreet =>
      Tr.t('address_hint_street', S.current.address_hint_street);
  static String get hintDistrict =>
      Tr.t('address_hint_district', S.current.address_hint_district);
  static String get hintBuilding =>
      Tr.t('address_hint_building', S.current.address_hint_building);
  static String get hintAdditional =>
      Tr.t('address_hint_additional', S.current.address_hint_additional);
  static String get hintPostal =>
      Tr.t('address_hint_postal', S.current.address_hint_postal);
  static String get hintUnit =>
      Tr.t('address_hint_unit', S.current.address_hint_unit);
  static String get hintPhone =>
      Tr.t('address_hint_phone', S.current.address_hint_phone);
  static String get hintNotes =>
      Tr.t('address_hint_notes', S.current.address_hint_notes);

  /// Shown when the map cannot be drawn and the pin was placed for
  /// them. Honest about WHY and about what was done.
  static String get pinFallback =>
      Tr.t('address_pin_fallback', S.current.address_pin_fallback);

  /// Stands in for a name the customer never gave. Better than the
  /// composed line as a title — that line is the DETAIL, and a card
  /// whose heading and body are the same string reads as a bug.
  static String get unnamed =>
      Tr.t('address_unnamed', S.current.address_unnamed);

  /// The bare numbers, LABELLED. `address_line` strings them together
  /// as «٢٣٤٢، test، Unit 233، test، Riyadh، 12423، 2342» — a row of
  /// digits nobody can tell apart. Named, each one says what it is.
  static String buildingShort(String n) => AppNumbers.localizeDigits(
    Tr.t('address_building_short', S.current.address_building_short(n)),
  );
  static String unitShort(String n) => AppNumbers.localizeDigits(
    Tr.t('address_unit_short', S.current.address_unit_short(n)),
  );
  static String postalShort(String n) => AppNumbers.localizeDigits(
    Tr.t('address_postal_short', S.current.address_postal_short(n)),
  );

  /// The CITY is the delivery zone, and the zone is what carries the
  /// fee — so an address saved without one cannot be delivered to.
  static String get cityRequired =>
      Tr.t('address_city_required', S.current.address_city_required);

  /// `GET /api/delivery-zones` answered with nothing. Said out loud:
  /// an empty picker with no explanation reads as a studio that
  /// delivers nowhere.
  static String get zonesEmpty =>
      Tr.t('address_zones_empty', S.current.address_zones_empty);
}
