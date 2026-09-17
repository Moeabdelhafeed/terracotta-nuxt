import 'dart:math' as math;

import 'package:intl/intl.dart';

import '../constants/currencies.dart';

/// Amount-in-words (تفقيط) for invoices and cheques — Arabic + English,
/// pure algorithm, no data files.
///
/// Convention: the integer part is spelled out; minor units ride as the
/// banking fraction (`70,000.345 JOD` → «سبعون ألفًا و345/1000 دينار
/// أردني») — the standard cheque format, which also sidesteps
/// per-currency subunit declension (fils / qirsh / cent …).
///
/// Arabic grammar covered: dual (ألفان / مليونان), the 3–10 plural
/// (آلاف / ملايين), the 11+ accusative (ألفًا / مليونًا), hundreds forms
/// (مائة / مائتان / تسعمائة) and unit-before-ten compounds
/// (خمسة وعشرون).
abstract final class AmountToWords {
  static const _unitsEn = [
    '',
    'one',
    'two',
    'three',
    'four',
    'five',
    'six',
    'seven',
    'eight',
    'nine',
    'ten',
    'eleven',
    'twelve',
    'thirteen',
    'fourteen',
    'fifteen',
    'sixteen',
    'seventeen',
    'eighteen',
    'nineteen',
  ];
  static const _tensEn = [
    '',
    '',
    'twenty',
    'thirty',
    'forty',
    'fifty',
    'sixty',
    'seventy',
    'eighty',
    'ninety',
  ];
  static const _scalesEn = [
    '',
    ' thousand',
    ' million',
    ' billion',
    ' trillion',
  ];

  static const _unitsAr = [
    '',
    'واحد',
    'اثنان',
    'ثلاثة',
    'أربعة',
    'خمسة',
    'ستة',
    'سبعة',
    'ثمانية',
    'تسعة',
    'عشرة',
    'أحد عشر',
    'اثنا عشر',
    'ثلاثة عشر',
    'أربعة عشر',
    'خمسة عشر',
    'ستة عشر',
    'سبعة عشر',
    'ثمانية عشر',
    'تسعة عشر',
  ];
  static const _tensAr = [
    '',
    '',
    'عشرون',
    'ثلاثون',
    'أربعون',
    'خمسون',
    'ستون',
    'سبعون',
    'ثمانون',
    'تسعون',
  ];
  static const _hundredsAr = [
    '',
    'مائة',
    'مائتان',
    'ثلاثمائة',
    'أربعمائة',
    'خمسمائة',
    'ستمائة',
    'سبعمائة',
    'ثمانمائة',
    'تسعمائة',
  ];

  /// Scale forms: [singular, dual, 3–10 plural, 11+ accusative].
  static const _scalesAr = [
    null,
    ['ألف', 'ألفان', 'آلاف', 'ألفًا'],
    ['مليون', 'مليونان', 'ملايين', 'مليونًا'],
    ['مليار', 'ملياران', 'مليارات', 'مليارًا'],
    ['تريليون', 'تريليونان', 'تريليونات', 'تريليونًا'],
  ];

  // ─── English ──────────────────────────────────────────────────

  static String integerToWordsEn(int n) {
    if (n == 0) return 'zero';
    if (n < 0) return 'minus ${integerToWordsEn(-n)}';
    final parts = <String>[];
    var scale = 0;
    var rest = n;
    final groups = <int>[];
    while (rest > 0) {
      groups.add(rest % 1000);
      rest ~/= 1000;
    }
    for (var i = groups.length - 1; i >= 0; i--) {
      final g = groups[i];
      if (g == 0) continue;
      scale = i;
      parts.add('${_groupEn(g)}${_scalesEn[scale]}');
    }
    return parts.join(' ');
  }

  static String _groupEn(int n) {
    final buffer = <String>[];
    final hundreds = n ~/ 100;
    final rem = n % 100;
    if (hundreds > 0) buffer.add('${_unitsEn[hundreds]} hundred');
    if (rem >= 20) {
      final unit = rem % 10;
      buffer.add(
        unit == 0
            ? _tensEn[rem ~/ 10]
            : '${_tensEn[rem ~/ 10]}-${_unitsEn[unit]}',
      );
    } else if (rem > 0) {
      buffer.add(_unitsEn[rem]);
    }
    return buffer.join(' ');
  }

  // ─── Arabic ───────────────────────────────────────────────────

  static String integerToWordsAr(int n) {
    if (n == 0) return 'صفر';
    if (n < 0) return 'سالب ${integerToWordsAr(-n)}';
    final groups = <int>[];
    var rest = n;
    while (rest > 0) {
      groups.add(rest % 1000);
      rest ~/= 1000;
    }
    final parts = <String>[];
    for (var i = groups.length - 1; i >= 0; i--) {
      final g = groups[i];
      if (g == 0) continue;
      if (i == 0) {
        parts.add(_groupAr(g));
        continue;
      }
      final forms = _scalesAr[i]!;
      final m = g % 100;
      if (g == 1) {
        parts.add(forms[0]);
      } else if (g == 2) {
        parts.add(forms[1]);
      } else if (m >= 3 && m <= 10) {
        // 3–10 (also 103–110 …) govern the plural: خمسة آلاف.
        parts.add('${_groupAr(g)} ${forms[2]}');
      } else if (m == 0) {
        // Round hundreds take the singular: خمسمائة ألف.
        parts.add('${_groupAr(g)} ${forms[0]}');
      } else {
        // 11–99 remainders take the accusative: سبعون ألفًا.
        parts.add('${_groupAr(g)} ${forms[3]}');
      }
    }
    return parts.join(' و');
  }

  static String _groupAr(int n) {
    final buffer = <String>[];
    final hundreds = n ~/ 100;
    final rem = n % 100;
    if (hundreds > 0) buffer.add(_hundredsAr[hundreds]);
    if (rem > 0) {
      if (rem < 20) {
        buffer.add(_unitsAr[rem]);
      } else {
        final unit = rem % 10;
        // Units come BEFORE the ten: خمسة وعشرون.
        buffer.add(
          unit == 0
              ? _tensAr[rem ~/ 10]
              : '${_unitsAr[unit]} و${_tensAr[rem ~/ 10]}',
        );
      }
    }
    return buffer.join(' و');
  }

  // ─── Money ────────────────────────────────────────────────────

  /// `70,000.345` JOD →
  /// ar: «سبعون ألفًا و345/1000 دينار أردني»
  /// en: "seventy thousand and 345/1000 Jordanian Dinar"
  /// [chequeStyle] wraps: «فقط … لا غير» / "… only".
  static String money(
    double amount,
    Currency currency, {
    bool? arabic,
    bool chequeStyle = false,
  }) {
    final ar = arabic ?? Intl.getCurrentLocale().startsWith('ar');
    final denominator = math.pow(10, currency.decimalDigits).toInt();
    var integer = amount.truncate();
    var minor = ((amount - integer) * denominator).round();
    if (minor >= denominator) {
      // 9.9996 at 3 decimals rounds up into the next integer.
      integer += 1;
      minor = 0;
    }

    final words = ar ? integerToWordsAr(integer) : integerToWordsEn(integer);
    final fraction = minor == 0 ? '' : '$minor/$denominator';
    final unit = ar ? currency.nameAr : currency.name;

    String result;
    if (ar) {
      result = fraction.isEmpty ? '$words $unit' : '$words و$fraction $unit';
      if (chequeStyle) result = 'فقط $result لا غير';
    } else {
      result = fraction.isEmpty ? '$words $unit' : '$words and $fraction $unit';
      if (chequeStyle) result = '$result only';
    }
    return result;
  }
}
