/// Card-network detection from the number's IIN prefix — drives the
/// credit-card field's grouping, length cap, brand chip and the CVV
/// length. Pure lookup, no I/O.
enum CardBrand {
  visa,
  mastercard,
  amex,
  discover,
  dinersClub,
  jcb,
  unionPay,
  maestro,
  mir,
  troy,
  uatp,
  hipercard,
  unknown;

  /// Display label ("Visa", "Mastercard", …). Proper nouns — not
  /// localized.
  String get label => switch (this) {
    CardBrand.visa => 'Visa',
    CardBrand.mastercard => 'Mastercard',
    CardBrand.amex => 'Amex',
    CardBrand.discover => 'Discover',
    CardBrand.dinersClub => 'Diners Club',
    CardBrand.jcb => 'JCB',
    CardBrand.unionPay => 'UnionPay',
    CardBrand.maestro => 'Maestro',
    CardBrand.mir => 'Mir',
    CardBrand.troy => 'Troy',
    CardBrand.uatp => 'UATP',
    CardBrand.hipercard => 'Hipercard',
    CardBrand.unknown => '',
  };

  /// Valid pan lengths (digits) for the network.
  List<int> get lengths => switch (this) {
    CardBrand.visa => const [13, 16, 19],
    CardBrand.mastercard => const [16],
    CardBrand.amex => const [15],
    CardBrand.discover => const [16, 19],
    CardBrand.dinersClub => const [14, 16, 19],
    CardBrand.jcb => const [16, 17, 18, 19],
    CardBrand.unionPay => const [16, 17, 18, 19],
    CardBrand.maestro => const [12, 13, 14, 15, 16, 17, 18, 19],
    CardBrand.mir => const [16, 17, 18, 19],
    CardBrand.troy => const [16],
    CardBrand.uatp => const [15],
    CardBrand.hipercard => const [16, 19],
    CardBrand.unknown => const [13, 14, 15, 16, 17, 18, 19],
  };

  int get maxLength => lengths.last;

  /// Display grouping — Amex/Diners embossing is `4-6-5` / `4-6-4`,
  /// UATP `4-5-6`, everything else spaces every 4.
  List<int> get groups => switch (this) {
    CardBrand.amex => const [4, 6, 5],
    CardBrand.dinersClub => const [4, 6, 4, 5],
    CardBrand.uatp => const [4, 5, 6],
    _ => const [4, 4, 4, 4, 3],
  };

  /// Security-code digits (Amex CID is 4).
  int get cvvLength => this == CardBrand.amex ? 4 : 3;

  /// Detect from the typed digits (spaces already stripped). Longest /
  /// most-specific prefixes are tested first (`62` before Discover's
  /// `6`-family, `2221–2720` Mastercard vs `2200–2204` Mir needs 4
  /// digits, Hipercard's 6-digit BIN before the generic 6-families).
  ///
  /// Domestic co-badged schemes (mada, RuPay, Elo, Meeza, Verve) are
  /// deliberately absent — their BINs live inside the global ranges and
  /// need maintained BIN tables. Plug those in per market via
  /// `CreditCardField.brandDetector`.
  static CardBrand detect(String digits) {
    if (digits.isEmpty) return CardBrand.unknown;
    if (digits.startsWith('4')) return CardBrand.visa;
    if (RegExp(r'^3[47]').hasMatch(digits)) return CardBrand.amex;
    if (RegExp(r'^5[1-5]').hasMatch(digits)) return CardBrand.mastercard;
    if (RegExp(r'^(50|5[6-8])').hasMatch(digits)) return CardBrand.maestro;
    if (digits.length >= 4) {
      final four = int.parse(digits.substring(0, 4));
      if (four >= 2200 && four <= 2204) return CardBrand.mir;
      if (four >= 2221 && four <= 2720) return CardBrand.mastercard;
      if (four >= 3528 && four <= 3589) return CardBrand.jcb;
      if (four == 9792) return CardBrand.troy;
    } else if (digits.startsWith('2') ||
        digits.startsWith('35') ||
        digits.startsWith('9')) {
      // Not enough digits to rule the ranges in or out yet.
      return CardBrand.unknown;
    }
    if (digits.startsWith('1')) return CardBrand.uatp;
    // 6-digit BIN — decidable only from 6 typed digits; '6062…' stays
    // unknown meanwhile (no other 6-family claims it).
    if (digits.startsWith('606282')) return CardBrand.hipercard;
    if (digits.startsWith('62')) return CardBrand.unionPay;
    if (digits.startsWith('6011') ||
        digits.startsWith('65') ||
        RegExp(r'^64[4-9]').hasMatch(digits)) {
      return CardBrand.discover;
    }
    if (digits.startsWith('639') || digits.startsWith('67')) {
      return CardBrand.maestro;
    }
    if (RegExp(r'^(36|38|39|30[0-5])').hasMatch(digits)) {
      return CardBrand.dinersClub;
    }
    return CardBrand.unknown;
  }
}
