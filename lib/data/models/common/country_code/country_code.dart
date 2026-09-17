// Package imports:
import 'package:freezed_annotation/freezed_annotation.dart';

part 'country_code.freezed.dart';
part 'country_code.g.dart';

/// ISO country + dial-code pair. Powers phone-number fields and
/// country pickers across the app.
///
/// [code] is the ISO-3166-1 alpha-2 code (`'US'`, `'JO'`, …) and is
/// required — a CountryCode without it can't identify anything.
/// [name] is the English display name; localized names come from
/// [CountryStrings] via the `translatedName` extension.
/// [dialCode] includes the leading `+` (`'+1'`, `'+962'`).
/// [flag] is the emoji representation.
/// [minLength] / [maxLength] bound the NATIONAL significant number in
/// digits — after the dial code, TRUNK ZERO EXCLUDED (Jordan `791234567`
/// = 9, not the dialed `0791234567`). Fixed + mobile union per country
/// (libphonenumber possible-lengths); tune per market in `CountryCodes`.
/// Null → generic 7–15 digit validation applies.
///
/// [mobileMinLength] / [mobileMaxLength] are the MOBILE-only subset
/// (Jordan: exactly 9 vs the 8-digit landlines) — applied when a phone
/// field disallows landlines (`PhoneNumberField.allowLandline: false`).
/// Null → falls back to the general bounds. Where mobile and fixed
/// lengths fully overlap (US: both 10) the distinction is length-blind.
///
/// [groupSizes] is the country's display grouping for the NSN — TRUNK
/// ZERO EXCLUDED (France `[1,2,2,2,2]` → `6 12 34 56 78`; the typed
/// trunk zero is absorbed into the first group: `06 12 34 56 78`).
/// Null → the generic `[3, 3, 4]`.
///
/// [mobilePrefixes] lists the NSN prefixes mobile numbers start with
/// (Jordan `['77','78','79']`) — checked when a phone field disallows
/// landlines. Null → prefix-blind (length rules only).
@freezed
abstract class CountryCode with _$CountryCode {
  const factory CountryCode({
    required String code,
    String? name,
    String? flag,
    String? dialCode,
    int? minLength,
    int? maxLength,
    int? mobileMinLength,
    int? mobileMaxLength,
    List<int>? groupSizes,
    List<String>? mobilePrefixes,
  }) = _CountryCode;

  factory CountryCode.fromJson(Map<String, dynamic> json) =>
      _$CountryCodeFromJson(json);
}
