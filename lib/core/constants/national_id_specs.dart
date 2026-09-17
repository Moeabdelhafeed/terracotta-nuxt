import 'package:flutter/foundation.dart';

/// Why a national-ID number failed its country's structural rules.
/// The field maps these to localized messages.
enum NationalIdError {
  required,
  length,
  prefix,
  checksum,
  birthDate,
  governorate,
}

enum NationalIdGender { male, female }

/// SA: leading digit 1 = citizen, 2 = resident (iqama).
enum NationalIdKind { citizen, resident }

/// What a country's ID encodes beyond identity — filled per spec.
@immutable
class NationalIdParsed {
  const NationalIdParsed({
    this.birthDate,
    this.birthYear,
    this.gender,
    this.governorateEn,
    this.governorateAr,
    this.kind,
  });

  /// Full embedded birth date (EG, KW).
  final DateTime? birthDate;

  /// Year-only birth info (AE encodes just the year).
  final int? birthYear;

  /// EG: 13th digit — odd male, even female.
  final NationalIdGender? gender;

  /// EG governorate of issue (English / Arabic names from the registry).
  final String? governorateEn;
  final String? governorateAr;

  /// SA: citizen vs resident.
  final NationalIdKind? kind;

  bool get isEmpty =>
      birthDate == null &&
      birthYear == null &&
      gender == null &&
      governorateEn == null &&
      kind == null;
}

/// Per-country national-ID rules: exact length, display grouping,
/// structural validation (prefix / checksum / embedded date), and the
/// optional parser for embedded data.
@immutable
class NationalIdSpec {
  const NationalIdSpec({
    required this.iso,
    required this.length,
    required this.groupSizes,
    this.validateStructure,
    this.parse,
  });

  final String iso;

  /// Exact digit count.
  final int length;

  /// Display grouping (semantic segments — e.g. AE `784 1984 1234567 1`).
  final List<int> groupSizes;

  /// Structural check beyond length — runs only on a FULL-length value.
  /// Null → length is the whole rule (JO).
  final NationalIdError? Function(String digits)? validateStructure;

  /// Embedded data extraction — runs only on a structurally VALID value.
  final NationalIdParsed? Function(String digits)? parse;
}

/// Registry + shared checksum math. Countries without a spec fall back to
/// a generic digits-length window so the field never hard-blocks.
class NationalIdSpecs {
  const NationalIdSpecs._();

  /// Generic fallback bounds for spec-less countries.
  static const int genericMinLength = 4;
  static const int genericMaxLength = 20;

  static NationalIdSpec? specFor(String iso) => _specs[iso.toUpperCase()];

  /// ISO codes with first-class rules (picker "preferred" candidates).
  static List<String> get supportedIsoCodes => _specs.keys.toList();

  /// Standard Luhn over [digits] (check digit included, rightmost).
  static bool luhnOk(String digits) {
    var sum = 0;
    var doubleIt = false;
    for (var i = digits.length - 1; i >= 0; i--) {
      var d = digits.codeUnitAt(i) - 0x30;
      if (doubleIt) {
        d *= 2;
        if (d > 9) d -= 9;
      }
      sum += d;
      doubleIt = !doubleIt;
    }
    return sum % 10 == 0;
  }

  /// Kuwait Civil ID mod-11: weights over the first 11 digits, check
  /// digit = 11 − (sum mod 11), must be < 10 and match digit 12.
  static bool kuwaitChecksumOk(String digits) {
    const weights = [2, 1, 6, 3, 7, 9, 10, 5, 8, 4, 3];
    var sum = 0;
    for (var i = 0; i < 11; i++) {
      sum += (digits.codeUnitAt(i) - 0x30) * weights[i];
    }
    final check = 11 - (sum % 11);
    if (check >= 10) return false;
    return check == digits.codeUnitAt(11) - 0x30;
  }

  /// `C` + `YYMMDD` → real calendar date, century digit 2 = 1900s,
  /// 3 = 2000s. Null when impossible.
  static DateTime? centuryDate(String centuryDigit, String yymmdd) {
    final base = switch (centuryDigit) {
      '2' => 1900,
      '3' => 2000,
      _ => null,
    };
    if (base == null) return null;
    final yy = int.parse(yymmdd.substring(0, 2));
    final mm = int.parse(yymmdd.substring(2, 4));
    final dd = int.parse(yymmdd.substring(4, 6));
    if (mm < 1 || mm > 12 || dd < 1 || dd > 31) return null;
    final date = DateTime(base + yy, mm, dd);
    // DateTime normalizes overflow (Feb 30 → Mar 2) — reject that.
    if (date.month != mm || date.day != dd) return null;
    return date;
  }

  /// EG governorate-of-issue codes → (English, Arabic).
  static const Map<String, (String, String)> egGovernorates = {
    '01': ('Cairo', 'القاهرة'),
    '02': ('Alexandria', 'الإسكندرية'),
    '03': ('Port Said', 'بورسعيد'),
    '04': ('Suez', 'السويس'),
    '11': ('Damietta', 'دمياط'),
    '12': ('Dakahlia', 'الدقهلية'),
    '13': ('Sharqia', 'الشرقية'),
    '14': ('Qalyubia', 'القليوبية'),
    '15': ('Kafr El Sheikh', 'كفر الشيخ'),
    '16': ('Gharbia', 'الغربية'),
    '17': ('Monufia', 'المنوفية'),
    '18': ('Beheira', 'البحيرة'),
    '19': ('Ismailia', 'الإسماعيلية'),
    '21': ('Giza', 'الجيزة'),
    '22': ('Beni Suef', 'بني سويف'),
    '23': ('Fayoum', 'الفيوم'),
    '24': ('Minya', 'المنيا'),
    '25': ('Assiut', 'أسيوط'),
    '26': ('Sohag', 'سوهاج'),
    '27': ('Qena', 'قنا'),
    '28': ('Aswan', 'أسوان'),
    '29': ('Luxor', 'الأقصر'),
    '31': ('Red Sea', 'البحر الأحمر'),
    '32': ('New Valley', 'الوادي الجديد'),
    '33': ('Matrouh', 'مطروح'),
    '34': ('North Sinai', 'شمال سيناء'),
    '35': ('South Sinai', 'جنوب سيناء'),
    '88': ('Born Abroad', 'خارج الجمهورية'),
  };

  static final Map<String, NationalIdSpec> _specs = {
    // Jordan — 10 digits, no published checksum.
    'JO': const NationalIdSpec(
      iso: 'JO',
      length: 10,
      groupSizes: [10],
    ),

    // Saudi Arabia — 10 digits, leading 1 (citizen) / 2 (resident), Luhn.
    'SA': NationalIdSpec(
      iso: 'SA',
      length: 10,
      groupSizes: const [10],
      validateStructure: (digits) {
        if (digits[0] != '1' && digits[0] != '2') {
          return NationalIdError.prefix;
        }
        if (!luhnOk(digits)) return NationalIdError.checksum;
        return null;
      },
      parse: (digits) => NationalIdParsed(
        kind: digits[0] == '1'
            ? NationalIdKind.citizen
            : NationalIdKind.resident,
      ),
    ),

    // Egypt — 14 digits C·YYMMDD·GG·SSSS·C. Century 2/3, real birth
    // date, known governorate, 13th digit gender. The final check
    // digit's algorithm is not officially published — structure + date
    // + governorate is the honest validation.
    'EG': NationalIdSpec(
      iso: 'EG',
      length: 14,
      groupSizes: const [1, 6, 2, 4, 1],
      validateStructure: (digits) {
        if (centuryDate(digits[0], digits.substring(1, 7)) == null) {
          return NationalIdError.birthDate;
        }
        if (!egGovernorates.containsKey(digits.substring(7, 9))) {
          return NationalIdError.governorate;
        }
        return null;
      },
      parse: (digits) {
        final gov = egGovernorates[digits.substring(7, 9)];
        final genderDigit = digits.codeUnitAt(12) - 0x30;
        return NationalIdParsed(
          birthDate: centuryDate(digits[0], digits.substring(1, 7)),
          gender: genderDigit.isOdd
              ? NationalIdGender.male
              : NationalIdGender.female,
          governorateEn: gov?.$1,
          governorateAr: gov?.$2,
        );
      },
    ),

    // UAE — Emirates ID 784·YYYY·NNNNNNN·C, Luhn over all 15.
    'AE': NationalIdSpec(
      iso: 'AE',
      length: 15,
      groupSizes: const [3, 4, 7, 1],
      validateStructure: (digits) {
        if (!digits.startsWith('784')) return NationalIdError.prefix;
        final year = int.parse(digits.substring(3, 7));
        if (year < 1900 || year > DateTime.now().year) {
          return NationalIdError.birthDate;
        }
        if (!luhnOk(digits)) return NationalIdError.checksum;
        return null;
      },
      parse: (digits) =>
          NationalIdParsed(birthYear: int.parse(digits.substring(3, 7))),
    ),

    // Kuwait — Civil ID 12 digits C·YYMMDD·SSSSS, mod-11 checksum.
    'KW': NationalIdSpec(
      iso: 'KW',
      length: 12,
      groupSizes: const [1, 6, 5],
      validateStructure: (digits) {
        if (centuryDate(digits[0], digits.substring(1, 7)) == null) {
          return NationalIdError.birthDate;
        }
        if (!kuwaitChecksumOk(digits)) return NationalIdError.checksum;
        return null;
      },
      parse: (digits) => NationalIdParsed(
        birthDate: centuryDate(digits[0], digits.substring(1, 7)),
      ),
    ),
  };
}
