import 'dart:math';

/// Cryptographically random password generation (`Random.secure()`).
///
/// Guarantees at least one character from every enabled class, then fills
/// the rest randomly and shuffles — so the result always satisfies the
/// standard create-password requirements (min length, upper, lower, digit).
/// Ambiguous glyphs (`l 1 I O 0`) are excluded by default so a revealed /
/// transcribed password can't be misread.
///
/// Used by the text field's generate button
/// (`TextFieldFeatures.showPasswordGenerate`); call directly for custom
/// flows: `PasswordGenerator.generate(length: 20, symbols: false)`.
class PasswordGenerator {
  PasswordGenerator._();

  static const _upper = 'ABCDEFGHJKLMNPQRSTUVWXYZ'; // no I, O
  static const _lower = 'abcdefghijkmnopqrstuvwxyz'; // no l
  static const _digits = '23456789'; // no 0, 1
  static const _symbols = '!@#\$%^&*()-_=+[]{}<>?';

  static const _upperFull = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const _lowerFull = 'abcdefghijklmnopqrstuvwxyz';
  static const _digitsFull = '0123456789';

  static String generate({
    int length = 16,
    bool symbols = true,
    bool excludeAmbiguous = true,
  }) {
    assert(length >= 4, 'Too short to cover the character classes');
    final rng = Random.secure();

    final classes = <String>[
      excludeAmbiguous ? _upper : _upperFull,
      excludeAmbiguous ? _lower : _lowerFull,
      excludeAmbiguous ? _digits : _digitsFull,
      if (symbols) _symbols,
    ];
    final all = classes.join();

    final chars = <String>[
      // One guaranteed pick per class…
      for (final set in classes) set[rng.nextInt(set.length)],
      // …rest fully random.
      for (var i = classes.length; i < length; i++)
        all[rng.nextInt(all.length)],
    ]..shuffle(rng);

    return chars.join();
  }
}
