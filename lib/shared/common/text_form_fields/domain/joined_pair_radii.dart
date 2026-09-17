import 'package:flutter/material.dart';

import '../../../module/text_field/global_text_field.dart';

/// Box height of a picker JOINED to a text field — the field's default
/// box height (content padding 16×2 + line height). A `GlobalDropdown`
/// trigger left unpinned inflates past it (its chevron/padding budget)
/// and hangs below the seam; pass this (or the caller's explicit field
/// height) as the picker's `sizing.height`.
const double kJoinedPairBoxHeight = 52;

/// Width of a dial-code picker joined to a phone field.
///
/// Sized for the widest dial code the catalogue holds — four characters
/// (`+962`), of 175 entries none longer. Fixed rather than measured:
/// the alternative builds a ghost copy of the field on every layout to
/// size a box whose widest content is known at compile time.
///
/// Multiply by the ambient text scaler at the call site so it still
/// fits when the reader has enlarged type.
///
/// Guarded by `test/text_field/dial_code_width_test.dart`.
const double kDialCodeBoxWidth = 64;

/// Radii for two inputs rendered as ONE attached control (picker+field
/// pairs — phone country, amount currency, measurement unit): the
/// start box squares its END corners, the end box its START corners.
/// `TextFieldStyle.borderRadius` is physical — resolved against the
/// ambient direction so the flat seam faces the neighbor in RTL too.
({BorderRadius start, BorderRadius end}) joinedPairRadii(
  BuildContext context,
) {
  const r = Radius.circular(TextFieldDefaults.borderRadius);
  final ltr = Directionality.of(context) == TextDirection.ltr;
  final start = BorderRadius.only(
    topLeft: ltr ? r : Radius.zero,
    bottomLeft: ltr ? r : Radius.zero,
    topRight: ltr ? Radius.zero : r,
    bottomRight: ltr ? Radius.zero : r,
  );
  final end = BorderRadius.only(
    topLeft: ltr ? Radius.zero : r,
    bottomLeft: ltr ? Radius.zero : r,
    topRight: ltr ? r : Radius.zero,
    bottomRight: ltr ? r : Radius.zero,
  );
  return (start: start, end: end);
}

/// Radii for ONE box in a chain of N attached boxes (segmented color field:
/// R / G / B … + format picker). Round only the corners that face the chain's
/// outer edges — [roundStart] for the leading box, [roundEnd] for the
/// trailing one; interior boxes pass both false so every seam is flat.
/// Direction-aware so the rounded end tracks reading order in RTL.
BorderRadius edgeRadii(
  BuildContext context, {
  required bool roundStart,
  required bool roundEnd,
}) {
  const r = Radius.circular(TextFieldDefaults.borderRadius);
  final ltr = Directionality.of(context) == TextDirection.ltr;
  final startCorner = roundStart ? r : Radius.zero;
  final endCorner = roundEnd ? r : Radius.zero;
  return BorderRadius.only(
    topLeft: ltr ? startCorner : endCorner,
    bottomLeft: ltr ? startCorner : endCorner,
    topRight: ltr ? endCorner : startCorner,
    bottomRight: ltr ? endCorner : startCorner,
  );
}
