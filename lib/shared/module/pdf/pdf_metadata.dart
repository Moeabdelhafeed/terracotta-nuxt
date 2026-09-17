import 'package:flutter/foundation.dart';

/// What a document says about itself: the `/Info` dictionary's title
/// and author.
@immutable
class PdfInfo {
  const PdfInfo({this.title, this.author});

  static const empty = PdfInfo();

  final String? title;
  final String? author;

  bool get isEmpty => title == null && author == null;

  @override
  bool operator ==(Object other) =>
      other is PdfInfo && other.title == title && other.author == author;

  @override
  int get hashCode => Object.hash(title, author);

  @override
  String toString() => 'PdfInfo(title: $title, author: $author)';
}

/// Reads `/Info` out of raw PDF bytes.
///
/// pdfrx-engine does not expose the dictionary, so `PdfStateSnapshot`'s
/// `title` and `author` were API surface that was always null. This is
/// the byte-parsing fallback, not a PDF parser: it finds the newest
/// `/Info N 0 R` reference, finds object N, and reads two strings out
/// of it.
///
/// BEST EFFORT, deliberately. It returns [PdfInfo.empty] rather than
/// guessing when:
///
///   * the cross-reference is a compressed STREAM (PDF 1.5+) and the
///     `/Info` reference lives inside it — the reference is deflated,
///     and inflating object streams to find a title is a parser, which
///     this is not;
///   * the document is ENCRYPTED, where the strings are ciphertext —
///     they decode to mojibake, so the check is `/Encrypt` in the
///     trailer, not the look of the result;
///   * there simply is no `/Info`, which is common.
///
/// It never throws. A malformed document is one without metadata, not
/// a crash in a viewer that was otherwise about to render it fine.
PdfInfo parsePdfInfo(Uint8List bytes) {
  try {
    if (_containsToken(bytes, _encryptToken, from: 0) >= 0) {
      // Strings in an encrypted document are ciphertext. Decoding them
      // produces text, which is worse than nothing — it looks like a
      // title.
      return PdfInfo.empty;
    }
    final objectNumber = _lastInfoReference(bytes);
    if (objectNumber == null) return PdfInfo.empty;

    final body = _objectBody(bytes, objectNumber);
    if (body == null) return PdfInfo.empty;

    return PdfInfo(
      title: _stringEntry(body, _titleToken),
      author: _stringEntry(body, _authorToken),
    );
  } on Object {
    return PdfInfo.empty;
  }
}

// PDF is a byte format, and its tokens are ASCII. Comparing bytes
// avoids decoding a whole document as text to find six characters —
// and a PDF is not valid UTF-8, so decoding it is not even available.
final _infoToken = _ascii('/Info');
final _encryptToken = _ascii('/Encrypt');
final _titleToken = _ascii('/Title');
final _authorToken = _ascii('/Author');
final _objToken = _ascii('obj');
final _endObjToken = _ascii('endobj');

Uint8List _ascii(String s) => Uint8List.fromList(s.codeUnits);

/// The object number in the LAST `/Info n g R` in the file.
///
/// Last, because a PDF is appended to: an incremental update writes a
/// new trailer at the end and the newest one wins. Taking the first
/// would report the metadata a document had before it was edited.
int? _lastInfoReference(Uint8List bytes) {
  int? found;
  var at = 0;
  while (true) {
    final index = _containsToken(bytes, _infoToken, from: at);
    if (index < 0) break;
    at = index + _infoToken.length;
    found = _readReference(bytes, at) ?? found;
  }
  return found;
}

/// Parses `<whitespace> digits <whitespace> digits <whitespace> R`.
int? _readReference(Uint8List bytes, int from) {
  var at = _skipWhitespace(bytes, from);
  final object = _readInt(bytes, at);
  if (object == null) return null;
  at = _skipWhitespace(bytes, object.end);
  final generation = _readInt(bytes, at);
  if (generation == null) return null;
  at = _skipWhitespace(bytes, generation.end);
  if (at >= bytes.length || bytes[at] != 0x52) return null; // 'R'
  return object.value;
}

/// The bytes between `n 0 obj` and `endobj`, for the LAST definition of
/// object [number] — same reason as the trailer: a later revision of an
/// object supersedes an earlier one.
Uint8List? _objectBody(Uint8List bytes, int number) {
  final header = _ascii('$number 0 ');
  var at = 0;
  int? start;
  while (true) {
    final index = _containsToken(bytes, header, from: at);
    if (index < 0) break;
    at = index + header.length;
    // Guard against matching "10 0 " inside "110 0 obj": the byte
    // before has to be a delimiter, not a digit.
    if (index > 0 && _isDigit(bytes[index - 1])) continue;
    final afterHeader = _skipWhitespace(bytes, at);
    if (_startsWith(bytes, _objToken, afterHeader)) {
      start = afterHeader + _objToken.length;
    }
  }
  if (start == null) return null;

  final end = _containsToken(bytes, _endObjToken, from: start);
  return Uint8List.sublistView(bytes, start, end < 0 ? bytes.length : end);
}

/// Reads one `/Key (value)` or `/Key <hex>` out of a dictionary body.
String? _stringEntry(Uint8List body, Uint8List key) {
  final index = _containsToken(body, key, from: 0);
  if (index < 0) return null;
  // `/Title` must not match `/TitleCase`: a name ends at a delimiter.
  final after = index + key.length;
  if (after < body.length && _isRegular(body[after])) return null;

  final at = _skipWhitespace(body, after);
  if (at >= body.length) return null;

  return switch (body[at]) {
    0x28 => _decode(_literalString(body, at)), // '('
    0x3C => _decode(_hexString(body, at)), //     '<'
    _ => null,
  };
}

/// A `(...)` string. Parentheses NEST inside one, and either can be
/// escaped, so counting to the first `)` reads half of some titles.
Uint8List? _literalString(Uint8List body, int open) {
  final out = <int>[];
  var depth = 1;
  var at = open + 1;
  while (at < body.length) {
    final byte = body[at];
    if (byte == 0x5C) {
      // backslash
      if (at + 1 >= body.length) return null;
      final escaped = body[at + 1];
      at += 2;
      switch (escaped) {
        case 0x6E:
          out.add(0x0A); // \n
        case 0x72:
          out.add(0x0D); // \r
        case 0x74:
          out.add(0x09); // \t
        case 0x62:
          out.add(0x08); // \b
        case 0x66:
          out.add(0x0C); // \f
        case 0x0A:
          break; // line continuation
        case 0x0D:
          if (at < body.length && body[at] == 0x0A) at++;
        default:
          if (escaped >= 0x30 && escaped <= 0x37) {
            // Up to three OCTAL digits, and the first is already read.
            var value = escaped - 0x30;
            for (var i = 0; i < 2; i++) {
              if (at >= body.length) break;
              final digit = body[at];
              if (digit < 0x30 || digit > 0x37) break;
              value = value * 8 + (digit - 0x30);
              at++;
            }
            out.add(value & 0xFF);
          } else {
            out.add(escaped); // \( \) \\ and anything else: literal
          }
      }
      continue;
    }
    if (byte == 0x28) depth++;
    if (byte == 0x29) {
      depth--;
      if (depth == 0) return Uint8List.fromList(out);
    }
    out.add(byte);
    at++;
  }
  return null;
}

/// A `<48656C6C6F>` string. An odd number of digits is padded with a
/// trailing zero, which the spec asks for rather than tolerates.
Uint8List? _hexString(Uint8List body, int open) {
  final digits = <int>[];
  var at = open + 1;
  while (at < body.length && body[at] != 0x3E) {
    final value = _hexDigit(body[at]);
    if (value != null) digits.add(value);
    at++;
  }
  if (at >= body.length) return null;
  if (digits.length.isOdd) digits.add(0);

  final out = Uint8List(digits.length ~/ 2);
  for (var i = 0; i < out.length; i++) {
    out[i] = digits[i * 2] * 16 + digits[i * 2 + 1];
  }
  return out;
}

/// UTF-16BE when the string carries a byte-order mark, PDFDocEncoding
/// otherwise — which for the characters a title uses is Latin-1.
String? _decode(Uint8List? raw) {
  if (raw == null || raw.isEmpty) return null;

  String text;
  if (raw.length >= 2 && raw[0] == 0xFE && raw[1] == 0xFF) {
    final units = <int>[];
    for (var i = 2; i + 1 < raw.length; i += 2) {
      units.add(raw[i] * 256 + raw[i + 1]);
    }
    text = String.fromCharCodes(units);
  } else {
    text = String.fromCharCodes(raw);
  }

  // Trailing NULs (not spaces — stripping those would run
  // "Annual Report" together). A fixed-width writer pads with them.
  text = text.replaceAll('\u0000', '').trim();
  return text.isEmpty ? null : text;
}

// ── byte helpers ────────────────────────────────────────────────────

int _containsToken(Uint8List haystack, Uint8List needle, {required int from}) {
  if (needle.isEmpty) return -1;
  final last = haystack.length - needle.length;
  for (var i = from; i <= last; i++) {
    if (_startsWith(haystack, needle, i)) return i;
  }
  return -1;
}

bool _startsWith(Uint8List haystack, Uint8List needle, int at) {
  if (at < 0 || at + needle.length > haystack.length) return false;
  for (var i = 0; i < needle.length; i++) {
    if (haystack[at + i] != needle[i]) return false;
  }
  return true;
}

int _skipWhitespace(Uint8List bytes, int from) {
  var at = from;
  while (at < bytes.length && _isWhitespace(bytes[at])) {
    at++;
  }
  return at;
}

({int value, int end})? _readInt(Uint8List bytes, int from) {
  var at = from;
  var value = 0;
  while (at < bytes.length && _isDigit(bytes[at])) {
    value = value * 10 + (bytes[at] - 0x30);
    at++;
  }
  return at == from ? null : (value: value, end: at);
}

bool _isDigit(int byte) => byte >= 0x30 && byte <= 0x39;

bool _isWhitespace(int byte) =>
    byte == 0x20 ||
    byte == 0x0A ||
    byte == 0x0D ||
    byte == 0x09 ||
    byte == 0x0C ||
    byte == 0x00;

/// A "regular" character — anything that is not whitespace and not one
/// of PDF's delimiters. A name token runs until one of these.
bool _isRegular(int byte) {
  if (_isWhitespace(byte)) return false;
  const delimiters = <int>[
    0x28,
    0x29,
    0x3C,
    0x3E,
    0x5B,
    0x5D,
    0x7B,
    0x7D,
    0x2F,
    0x25,
  ];
  return !delimiters.contains(byte);
}

int? _hexDigit(int byte) {
  if (byte >= 0x30 && byte <= 0x39) return byte - 0x30;
  if (byte >= 0x41 && byte <= 0x46) return byte - 0x41 + 10;
  if (byte >= 0x61 && byte <= 0x66) return byte - 0x61 + 10;
  return null;
}
