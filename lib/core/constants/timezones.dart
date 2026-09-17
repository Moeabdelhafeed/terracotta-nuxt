import 'package:flutter/foundation.dart';

import '../localization/strings/timezone_strings.dart';

/// One picker-grade timezone — IANA id + STANDARD (non-DST) UTC offset
/// + English city name. Localized city names live in the ARB
/// (`timezone_*` keys via [TimezoneStrings]) — the English name stays
/// here only for search + fallback, mirroring `CountryCode.name` vs
/// `CountryStrings`.
@immutable
class TimezoneInfo {
  const TimezoneInfo({
    required this.id,
    required this.standardOffsetMinutes,
    required this.city,
  });

  /// IANA identifier (`'Asia/Amman'`). Some entries are tzdata Links
  /// (`Asia/Kuwait` → `Asia/Riyadh`) — kept because the city name is
  /// what users recognize. To resolve these through `package:timezone`
  /// you MUST load the full database
  /// (`import 'package:timezone/data/latest_all.dart'`) — the default
  /// `latest.dart` ships canonical zones only and `getLocation` throws
  /// on Link ids.
  final String id;

  /// Standard (winter wall-clock) offset from UTC in signed minutes
  /// (Amman = 180, St. John's = -210). DST is deliberately not modeled
  /// — this is a display catalog; do wall-clock math via
  /// `package:timezone`. (Ireland's tzdata models winter as the DST
  /// period — we list Dublin at its winter +00:00 like every picker.)
  final int standardOffsetMinutes;

  /// English city name — search haystack + fallback when no ARB key
  /// exists.
  final String city;

  /// City name for the active locale (ARB-backed, remote-overridable).
  String get displayCity => TimezoneStrings.cityFor(id) ?? city;

  /// `'UTC+03:00'` / `'UTC\u221205:00'` / `'UTC+05:45'`.
  String get offsetLabel {
    final sign = standardOffsetMinutes < 0 ? '\u2212' : '+';
    final abs = standardOffsetMinutes.abs();
    final h = (abs ~/ 60).toString().padLeft(2, '0');
    final m = (abs % 60).toString().padLeft(2, '0');
    return 'UTC$sign$h:$m';
  }

  /// Search-haystack variants of the offset a keyboard can actually
  /// type \u2014 [offsetLabel] uses the typographic minus (U+2212) and
  /// zero-padded hours, so "UTC-5" / "+3" would never match it.
  String get offsetSearchText {
    final sign = standardOffsetMinutes < 0 ? '-' : '+';
    final abs = standardOffsetMinutes.abs();
    final h = (abs ~/ 60).toString().padLeft(2, '0');
    final m = (abs % 60).toString().padLeft(2, '0');
    final short = m == '00' ? '${abs ~/ 60}' : '${abs ~/ 60}:${abs % 60}';
    return 'UTC$sign$h:$m UTC$sign$short';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is TimezoneInfo && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'TimezoneInfo($id $offsetLabel)';
}

/// Curated timezone catalog — every major inhabited UTC offset
/// represented (fractional ones included), MENA complete, world
/// majors. Sorted by offset, then city; adopter-editable like
/// `CountryCodes` / `Currencies`.
class Timezones {
  Timezones._();

  static const List<TimezoneInfo> all = [
    TimezoneInfo(
      id: 'Pacific/Pago_Pago',
      standardOffsetMinutes: -660,
      city: 'Pago Pago',
    ),
    TimezoneInfo(
      id: 'Pacific/Honolulu',
      standardOffsetMinutes: -600,
      city: 'Honolulu',
    ),
    TimezoneInfo(
      id: 'Pacific/Marquesas',
      standardOffsetMinutes: -570,
      city: 'Marquesas',
    ),
    TimezoneInfo(
      id: 'America/Anchorage',
      standardOffsetMinutes: -540,
      city: 'Anchorage',
    ),
    TimezoneInfo(
      id: 'America/Los_Angeles',
      standardOffsetMinutes: -480,
      city: 'Los Angeles',
    ),
    TimezoneInfo(
      id: 'America/Denver',
      standardOffsetMinutes: -420,
      city: 'Denver',
    ),
    TimezoneInfo(
      id: 'America/Chicago',
      standardOffsetMinutes: -360,
      city: 'Chicago',
    ),
    TimezoneInfo(
      id: 'America/Mexico_City',
      standardOffsetMinutes: -360,
      city: 'Mexico City',
    ),
    TimezoneInfo(
      id: 'America/Bogota',
      standardOffsetMinutes: -300,
      city: 'Bogota',
    ),
    TimezoneInfo(id: 'America/Lima', standardOffsetMinutes: -300, city: 'Lima'),
    TimezoneInfo(
      id: 'America/New_York',
      standardOffsetMinutes: -300,
      city: 'New York',
    ),
    TimezoneInfo(
      id: 'America/Toronto',
      standardOffsetMinutes: -300,
      city: 'Toronto',
    ),
    TimezoneInfo(
      id: 'America/Caracas',
      standardOffsetMinutes: -240,
      city: 'Caracas',
    ),
    TimezoneInfo(
      id: 'America/Santiago',
      standardOffsetMinutes: -240,
      city: 'Santiago',
    ),
    TimezoneInfo(
      id: 'America/St_Johns',
      standardOffsetMinutes: -210,
      city: 'St. John\'s',
    ),
    TimezoneInfo(
      id: 'America/Argentina/Buenos_Aires',
      standardOffsetMinutes: -180,
      city: 'Buenos Aires',
    ),
    TimezoneInfo(
      id: 'America/Sao_Paulo',
      standardOffsetMinutes: -180,
      city: 'Sao Paulo',
    ),
    TimezoneInfo(
      id: 'America/Noronha',
      standardOffsetMinutes: -120,
      city: 'Fernando de Noronha',
    ),
    TimezoneInfo(
      id: 'Atlantic/Cape_Verde',
      standardOffsetMinutes: -60,
      city: 'Praia',
    ),
    TimezoneInfo(id: 'Africa/Accra', standardOffsetMinutes: 0, city: 'Accra'),
    TimezoneInfo(id: 'Europe/Dublin', standardOffsetMinutes: 0, city: 'Dublin'),
    TimezoneInfo(id: 'Europe/Lisbon', standardOffsetMinutes: 0, city: 'Lisbon'),
    TimezoneInfo(id: 'Europe/London', standardOffsetMinutes: 0, city: 'London'),
    TimezoneInfo(
      id: 'Africa/Nouakchott',
      standardOffsetMinutes: 0,
      city: 'Nouakchott',
    ),
    TimezoneInfo(
      id: 'Atlantic/Reykjavik',
      standardOffsetMinutes: 0,
      city: 'Reykjavik',
    ),
    TimezoneInfo(
      id: 'Africa/Algiers',
      standardOffsetMinutes: 60,
      city: 'Algiers',
    ),
    TimezoneInfo(
      id: 'Europe/Amsterdam',
      standardOffsetMinutes: 60,
      city: 'Amsterdam',
    ),
    TimezoneInfo(
      id: 'Europe/Berlin',
      standardOffsetMinutes: 60,
      city: 'Berlin',
    ),
    TimezoneInfo(
      id: 'Africa/Casablanca',
      standardOffsetMinutes: 60,
      city: 'Casablanca',
    ),
    TimezoneInfo(
      id: 'Africa/Kinshasa',
      standardOffsetMinutes: 60,
      city: 'Kinshasa',
    ),
    TimezoneInfo(id: 'Africa/Lagos', standardOffsetMinutes: 60, city: 'Lagos'),
    TimezoneInfo(
      id: 'Europe/Madrid',
      standardOffsetMinutes: 60,
      city: 'Madrid',
    ),
    TimezoneInfo(id: 'Europe/Paris', standardOffsetMinutes: 60, city: 'Paris'),
    TimezoneInfo(id: 'Europe/Rome', standardOffsetMinutes: 60, city: 'Rome'),
    TimezoneInfo(
      id: 'Europe/Stockholm',
      standardOffsetMinutes: 60,
      city: 'Stockholm',
    ),
    TimezoneInfo(id: 'Africa/Tunis', standardOffsetMinutes: 60, city: 'Tunis'),
    TimezoneInfo(
      id: 'Europe/Zurich',
      standardOffsetMinutes: 60,
      city: 'Zurich',
    ),
    TimezoneInfo(
      id: 'Europe/Athens',
      standardOffsetMinutes: 120,
      city: 'Athens',
    ),
    TimezoneInfo(id: 'Asia/Beirut', standardOffsetMinutes: 120, city: 'Beirut'),
    TimezoneInfo(id: 'Africa/Cairo', standardOffsetMinutes: 120, city: 'Cairo'),
    TimezoneInfo(
      id: 'Asia/Jerusalem',
      standardOffsetMinutes: 120,
      city: 'Jerusalem',
    ),
    TimezoneInfo(
      id: 'Africa/Johannesburg',
      standardOffsetMinutes: 120,
      city: 'Johannesburg',
    ),
    TimezoneInfo(
      id: 'Africa/Khartoum',
      standardOffsetMinutes: 120,
      city: 'Khartoum',
    ),
    TimezoneInfo(id: 'Europe/Kyiv', standardOffsetMinutes: 120, city: 'Kyiv'),
    TimezoneInfo(
      id: 'Africa/Tripoli',
      standardOffsetMinutes: 120,
      city: 'Tripoli',
    ),
    TimezoneInfo(
      id: 'Africa/Addis_Ababa',
      standardOffsetMinutes: 180,
      city: 'Addis Ababa',
    ),
    TimezoneInfo(id: 'Asia/Amman', standardOffsetMinutes: 180, city: 'Amman'),
    TimezoneInfo(
      id: 'Asia/Baghdad',
      standardOffsetMinutes: 180,
      city: 'Baghdad',
    ),
    TimezoneInfo(
      id: 'Asia/Damascus',
      standardOffsetMinutes: 180,
      city: 'Damascus',
    ),
    TimezoneInfo(id: 'Asia/Qatar', standardOffsetMinutes: 180, city: 'Doha'),
    TimezoneInfo(
      id: 'Europe/Istanbul',
      standardOffsetMinutes: 180,
      city: 'Istanbul',
    ),
    TimezoneInfo(
      id: 'Asia/Kuwait',
      standardOffsetMinutes: 180,
      city: 'Kuwait City',
    ),
    TimezoneInfo(
      id: 'Asia/Bahrain',
      standardOffsetMinutes: 180,
      city: 'Manama',
    ),
    TimezoneInfo(
      id: 'Africa/Mogadishu',
      standardOffsetMinutes: 180,
      city: 'Mogadishu',
    ),
    TimezoneInfo(
      id: 'Europe/Moscow',
      standardOffsetMinutes: 180,
      city: 'Moscow',
    ),
    TimezoneInfo(
      id: 'Africa/Nairobi',
      standardOffsetMinutes: 180,
      city: 'Nairobi',
    ),
    TimezoneInfo(id: 'Asia/Riyadh', standardOffsetMinutes: 180, city: 'Riyadh'),
    TimezoneInfo(id: 'Asia/Aden', standardOffsetMinutes: 180, city: 'Sanaa'),
    TimezoneInfo(id: 'Asia/Tehran', standardOffsetMinutes: 210, city: 'Tehran'),
    TimezoneInfo(id: 'Asia/Dubai', standardOffsetMinutes: 240, city: 'Dubai'),
    TimezoneInfo(id: 'Asia/Muscat', standardOffsetMinutes: 240, city: 'Muscat'),
    TimezoneInfo(id: 'Asia/Kabul', standardOffsetMinutes: 270, city: 'Kabul'),
    TimezoneInfo(id: 'Asia/Almaty', standardOffsetMinutes: 300, city: 'Almaty'),
    TimezoneInfo(
      id: 'Asia/Karachi',
      standardOffsetMinutes: 300,
      city: 'Karachi',
    ),
    TimezoneInfo(
      id: 'Asia/Tashkent',
      standardOffsetMinutes: 300,
      city: 'Tashkent',
    ),
    TimezoneInfo(
      id: 'Asia/Colombo',
      standardOffsetMinutes: 330,
      city: 'Colombo',
    ),
    TimezoneInfo(id: 'Asia/Kolkata', standardOffsetMinutes: 330, city: 'Delhi'),
    TimezoneInfo(
      id: 'Asia/Kathmandu',
      standardOffsetMinutes: 345,
      city: 'Kathmandu',
    ),
    TimezoneInfo(id: 'Asia/Dhaka', standardOffsetMinutes: 360, city: 'Dhaka'),
    TimezoneInfo(id: 'Asia/Yangon', standardOffsetMinutes: 390, city: 'Yangon'),
    TimezoneInfo(
      id: 'Asia/Bangkok',
      standardOffsetMinutes: 420,
      city: 'Bangkok',
    ),
    TimezoneInfo(
      id: 'Asia/Ho_Chi_Minh',
      standardOffsetMinutes: 420,
      city: 'Ho Chi Minh',
    ),
    TimezoneInfo(
      id: 'Asia/Jakarta',
      standardOffsetMinutes: 420,
      city: 'Jakarta',
    ),
    TimezoneInfo(
      id: 'Asia/Hong_Kong',
      standardOffsetMinutes: 480,
      city: 'Hong Kong',
    ),
    TimezoneInfo(
      id: 'Asia/Kuala_Lumpur',
      standardOffsetMinutes: 480,
      city: 'Kuala Lumpur',
    ),
    TimezoneInfo(id: 'Asia/Manila', standardOffsetMinutes: 480, city: 'Manila'),
    TimezoneInfo(
      id: 'Australia/Perth',
      standardOffsetMinutes: 480,
      city: 'Perth',
    ),
    TimezoneInfo(
      id: 'Asia/Shanghai',
      standardOffsetMinutes: 480,
      city: 'Shanghai',
    ),
    TimezoneInfo(
      id: 'Asia/Singapore',
      standardOffsetMinutes: 480,
      city: 'Singapore',
    ),
    TimezoneInfo(id: 'Asia/Taipei', standardOffsetMinutes: 480, city: 'Taipei'),
    TimezoneInfo(id: 'Asia/Seoul', standardOffsetMinutes: 540, city: 'Seoul'),
    TimezoneInfo(id: 'Asia/Tokyo', standardOffsetMinutes: 540, city: 'Tokyo'),
    TimezoneInfo(
      id: 'Australia/Adelaide',
      standardOffsetMinutes: 570,
      city: 'Adelaide',
    ),
    TimezoneInfo(
      id: 'Australia/Darwin',
      standardOffsetMinutes: 570,
      city: 'Darwin',
    ),
    TimezoneInfo(
      id: 'Australia/Brisbane',
      standardOffsetMinutes: 600,
      city: 'Brisbane',
    ),
    TimezoneInfo(id: 'Pacific/Guam', standardOffsetMinutes: 600, city: 'Guam'),
    TimezoneInfo(
      id: 'Australia/Melbourne',
      standardOffsetMinutes: 600,
      city: 'Melbourne',
    ),
    TimezoneInfo(
      id: 'Pacific/Port_Moresby',
      standardOffsetMinutes: 600,
      city: 'Port Moresby',
    ),
    TimezoneInfo(
      id: 'Australia/Sydney',
      standardOffsetMinutes: 600,
      city: 'Sydney',
    ),
    TimezoneInfo(
      id: 'Australia/Lord_Howe',
      standardOffsetMinutes: 630,
      city: 'Lord Howe',
    ),
    TimezoneInfo(
      id: 'Pacific/Guadalcanal',
      standardOffsetMinutes: 660,
      city: 'Honiara',
    ),
    TimezoneInfo(
      id: 'Pacific/Auckland',
      standardOffsetMinutes: 720,
      city: 'Auckland',
    ),
    TimezoneInfo(id: 'Pacific/Fiji', standardOffsetMinutes: 720, city: 'Suva'),
    TimezoneInfo(
      id: 'Pacific/Chatham',
      standardOffsetMinutes: 765,
      city: 'Chatham',
    ),
    TimezoneInfo(id: 'Pacific/Apia', standardOffsetMinutes: 780, city: 'Apia'),
    TimezoneInfo(
      id: 'Pacific/Tongatapu',
      standardOffsetMinutes: 780,
      city: 'Nuku\'alofa',
    ),
    TimezoneInfo(
      id: 'Pacific/Kiritimati',
      standardOffsetMinutes: 840,
      city: 'Kiritimati',
    ),
  ];

  /// Lookup by IANA id. Null when the id isn't in the catalog.
  static TimezoneInfo? byId(String id) {
    for (final z in all) {
      if (z.id == id) return z;
    }
    return null;
  }

  /// First catalog zone matching the DEVICE's current UTC offset — a
  /// "detect my timezone" seed. Approximate: while the device observes
  /// DST its offset differs from the standard offsets here, so treat
  /// the result as a suggestion, not truth.
  static TimezoneInfo? closestToDevice() {
    final device = DateTime.now().timeZoneOffset.inMinutes;
    for (final z in all) {
      if (z.standardOffsetMinutes == device) return z;
    }
    return null;
  }
}
