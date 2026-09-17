import 'package:flutter/foundation.dart';

import 'national_id_specs.dart' show NationalIdSpecs;

/// Which optional line an address schema shows, and how the postal code
/// is masked / validated for one country. The country + street + city
/// fields are universal; the rest flex per [AddressSchema].
enum AddressLine { line2, state, postalCode }

/// A fixed administrative-subdivision list (state / governorate /
/// emirate) offered as a dropdown. `(code, englishName, arabicName)`.
///
/// Names are deliberately INLINE, not ARB: the EG list is reused
/// verbatim from `NationalIdSpecs.egGovernorates`, whose en/ar pair is
/// part of the `NationalId` VALUE OBJECT surface (`governorateEn` /
/// `governorateAr` parsed out of an ID number) — locale-bound ARB
/// lookups can't back a dual-language value object, and splitting the
/// two registries would fork the data.
typedef AddressSubdivision = (String code, String en, String ar);

/// Per-country address shape: which optional fields appear, their
/// labels, the postal-code rule, and — when the country has a fixed
/// subdivision list — the dropdown options.
@immutable
class AddressSchema {
  const AddressSchema({
    required this.iso,
    this.lines = const {
      AddressLine.line2,
      AddressLine.state,
      AddressLine.postalCode,
    },
    this.cityLabelKey = 'city',
    this.stateLabelKey = 'state',
    this.postalLabelKey = 'postal_code',
    this.postalPattern,
    this.postalExampleHint,
    this.postalDigitsOnly = true,
    this.postalMaxLength = 10,
    this.subdivisions,
    this.areas,
  });

  final String iso;

  /// Optional lines shown for this country (street + city always show).
  final Set<AddressLine> lines;

  /// ARB sub-key for the locality field label. `city` for state-based
  /// countries (US/GB); `area` under a governorate/emirate — where a
  /// bare "City" duplicates the province the [subdivisions] dropdown
  /// already captured.
  final String cityLabelKey;

  /// ARB sub-key for the state/region field label
  /// (`address_field_<key>` → "State" / "Governorate" / "Emirate").
  final String stateLabelKey;

  /// ARB sub-key for the postal-code label ("ZIP code" / "Postcode").
  final String postalLabelKey;

  /// Full-match validation for a complete postal code. Null → any
  /// non-empty value passes (length only).
  final RegExp? postalPattern;

  /// Placeholder shown in the postal field (`12345`, `SW1A 1AA`).
  final String? postalExampleHint;

  /// Restrict typing to digits (US ZIP, JO). UK postcodes are
  /// alphanumeric → false.
  final bool postalDigitsOnly;

  final int postalMaxLength;

  /// Fixed subdivision dropdown (EG governorates); null → free-text
  /// state field.
  final List<AddressSubdivision>? subdivisions;

  /// Dependent narrowing: areas/districts keyed by the parent
  /// subdivision code. When the selected state has an entry, the area
  /// field becomes a dropdown scoped to it; otherwise free text. Curated
  /// per country — partial coverage is fine (uncovered governorates fall
  /// back to free text).
  final Map<String, List<AddressSubdivision>>? areas;

  bool has(AddressLine line) => lines.contains(line);

  /// Areas for [stateCode], if this schema narrows it.
  List<AddressSubdivision>? areasFor(String? stateCode) =>
      stateCode == null ? null : areas?[stateCode];
}

/// Registry of country address shapes + the generic fallback. Mirrors
/// [NationalIdSpecs] — one map entry per country, easy to extend.
class AddressSchemas {
  const AddressSchemas._();

  /// Egypt's 27 governorates, reused verbatim from the national-ID
  /// registry (already en+ar) minus the "born abroad" pseudo-code.
  static final List<AddressSubdivision> _egGovernorates = NationalIdSpecs
      .egGovernorates
      .entries
      .where((e) => e.key != '88')
      .map((e) => (e.key, e.value.$1, e.value.$2))
      .toList();

  /// Jordan's 12 governorates.
  static const List<AddressSubdivision> _joGovernorates = [
    ('AM', 'Amman', 'عمّان'),
    ('IR', 'Irbid', 'إربد'),
    ('AZ', 'Zarqa', 'الزرقاء'),
    ('MA', 'Mafraq', 'المفرق'),
    ('BA', 'Balqa', 'البلقاء'),
    ('MD', 'Madaba', 'مأدبا'),
    ('KA', 'Karak', 'الكرك'),
    ('AT', 'Tafilah', 'الطفيلة'),
    ('MN', "Ma'an", 'معان'),
    ('AQ', 'Aqaba', 'العقبة'),
    ('JA', 'Jerash', 'جرش'),
    ('AJ', 'Ajloun', 'عجلون'),
  ];

  /// Saudi Arabia's 13 administrative regions.
  static const List<AddressSubdivision> _saRegions = [
    ('01', 'Riyadh', 'الرياض'),
    ('02', 'Makkah', 'مكة المكرمة'),
    ('03', 'Madinah', 'المدينة المنورة'),
    ('04', 'Eastern Province', 'المنطقة الشرقية'),
    ('05', 'Asir', 'عسير'),
    ('06', 'Tabuk', 'تبوك'),
    ('07', 'Hail', 'حائل'),
    ('08', 'Northern Borders', 'الحدود الشمالية'),
    ('09', 'Jazan', 'جازان'),
    ('10', 'Najran', 'نجران'),
    ('11', 'Al Bahah', 'الباحة'),
    ('12', 'Al Jawf', 'الجوف'),
    ('13', 'Qassim', 'القصيم'),
  ];

  /// The 7 emirates.
  static const List<AddressSubdivision> _aeEmirates = [
    ('AZ', 'Abu Dhabi', 'أبو ظبي'),
    ('DU', 'Dubai', 'دبي'),
    ('SH', 'Sharjah', 'الشارقة'),
    ('AJ', 'Ajman', 'عجمان'),
    ('UQ', 'Umm Al Quwain', 'أم القيوين'),
    ('RK', 'Ras Al Khaimah', 'رأس الخيمة'),
    ('FU', 'Fujairah', 'الفجيرة'),
  ];

  /// Dependent narrowing (curated, partial). Districts of the busiest
  /// governorates — the rest fall back to a free-text area field.
  static const Map<String, List<AddressSubdivision>> _joAreas = {
    'AM': [
      ('AB', 'Abdoun', 'عبدون'),
      ('SW', 'Sweifieh', 'الصويفية'),
      ('JB', 'Jabal Amman', 'جبل عمان'),
      ('SH', 'Shmeisani', 'الشميساني'),
      ('KH', 'Khalda', 'خلدا'),
      ('TL', 'Tla Al Ali', 'تلاع العلي'),
      ('MA', 'Marka', 'ماركا'),
      ('WS', 'Wadi Saqra', 'وادي صقرة'),
    ],
    'IR': [
      ('IC', 'Irbid Centre', 'وسط إربد'),
      ('UN', 'University District', 'الحي الجامعي'),
      ('RM', 'Ramtha', 'الرمثا'),
    ],
  };

  static const Map<String, List<AddressSubdivision>> _egAreas = {
    '01': [
      ('NC', 'Nasr City', 'مدينة نصر'),
      ('MA', 'Maadi', 'المعادي'),
      ('HE', 'Heliopolis', 'مصر الجديدة'),
      ('ZA', 'Zamalek', 'الزمالك'),
      ('SH', 'Shubra', 'شبرا'),
      ('NW', 'New Cairo', 'القاهرة الجديدة'),
    ],
    '21': [
      ('DO', 'Dokki', 'الدقي'),
      ('MO', 'Mohandessin', 'المهندسين'),
      ('HA', 'Haram', 'الهرم'),
      ('6O', '6th of October', 'السادس من أكتوبر'),
    ],
  };

  static final Map<String, AddressSchema> _schemas = {
    'JO': const AddressSchema(
      iso: 'JO',
      cityLabelKey: 'area',
      stateLabelKey: 'governorate',
      postalExampleHint: '11118',
      postalMaxLength: 5,
      subdivisions: _joGovernorates,
      areas: _joAreas,
    ),
    'EG': AddressSchema(
      iso: 'EG',
      cityLabelKey: 'area',
      stateLabelKey: 'governorate',
      postalExampleHint: '11511',
      postalMaxLength: 5,
      subdivisions: _egGovernorates,
      areas: _egAreas,
    ),
    'AE': const AddressSchema(
      iso: 'AE',
      cityLabelKey: 'area',
      stateLabelKey: 'emirate',
      // The UAE has no postal-code system — drop the field.
      lines: {AddressLine.line2, AddressLine.state},
      subdivisions: _aeEmirates,
    ),
    'SA': const AddressSchema(
      iso: 'SA',
      cityLabelKey: 'area',
      stateLabelKey: 'region',
      postalExampleHint: '12345',
      postalMaxLength: 5,
      subdivisions: _saRegions,
    ),
    'US': AddressSchema(
      iso: 'US',
      stateLabelKey: 'state',
      postalLabelKey: 'zip_code',
      // 5-digit or ZIP+4.
      postalPattern: RegExp(r'^\d{5}(-\d{4})?$'),
      postalExampleHint: '10001',
      postalMaxLength: 10,
    ),
    'GB': AddressSchema(
      iso: 'GB',
      stateLabelKey: 'county',
      postalLabelKey: 'postcode',
      // UK postcode — alphanumeric.
      postalPattern: RegExp(r'^[A-Z]{1,2}\d[A-Z\d]? ?\d[A-Z]{2}$'),
      postalExampleHint: 'SW1A 1AA',
      postalDigitsOnly: false,
      postalMaxLength: 8,
    ),
  };

  static AddressSchema? schemaFor(String iso) => _schemas[iso.toUpperCase()];

  /// The shape for [iso], or the generic fallback (street + city +
  /// line2 + free-text state + loose postal) for unlisted countries.
  static AddressSchema resolve(String iso) =>
      _schemas[iso.toUpperCase()] ?? AddressSchema(iso: iso.toUpperCase());

  static List<String> get supportedIsoCodes => _schemas.keys.toList();
}
