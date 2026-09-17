/// The small rules behind the address form's payload.
///
/// Pulled out of the widget so they can be tested: a form's `build` is
/// not where a correctness rule should live alone.
class AddressDraft {
  const AddressDraft._();

  /// The number to SEND for the courier.
  ///
  /// `PhoneNumberField` keeps the dial code in the picker beside the
  /// box, so its controller holds the NATIONAL digits only —
  /// `512345678`. The API wants the whole number, and a courier handed
  /// `512345678` has nothing to dial.
  ///
  /// [e164] is the field's own parse (`+966512345678`) and is preferred
  /// whenever there is one. The controller text is the fallback for the
  /// moment before the field has emitted, and for an address being
  /// edited whose number came back from the server already complete.
  static String phoneToSend({String? e164, required String typed}) {
    final parsed = e164?.trim() ?? '';
    return parsed.isNotEmpty ? parsed : typed.trim();
  }

  /// Blank means "not given" on this API, not an empty string —
  /// `label`, `notes` and `unit_number` are all optional and a `''`
  /// would be saved as one.
  static String? blankToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  /// Where the map opens when the customer has not pinned anything yet.
  ///
  /// RIYADH, not the picker's own default of Amman: this app delivers
  /// inside Saudi Arabia only, and `POST /api/addresses` refuses a pin
  /// outside it with a 422 keyed to `lat`. Opening the map in another
  /// country asks the customer to pan across a border before they can
  /// save anything.
  static const seedLat = 24.7136;
  static const seedLng = 46.6753;

  /// Whether a map can be drawn at all.
  ///
  /// **Always true now.** It used to read `MAPS_NATIVE_API_KEY`,
  /// because Google Maps kills the app the moment a map view is built
  /// without one — so the form dropped the seed pin itself and told
  /// the customer, rather than opening a picker that could not draw.
  ///
  /// The picker draws from OpenStreetMap tiles, which need no key at
  /// all (see `GlobalOsmMap`), so the gate was holding the picker shut
  /// on a condition that no longer has anything to do with it. Kept as
  /// a constant rather than deleted so the form still reads as asking
  /// the question — and so a tile host that DOES need credentials has
  /// one place to say so.
  static bool get canPickOnMap => true;
}
