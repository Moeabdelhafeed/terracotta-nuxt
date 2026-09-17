import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' show LatLng;
import 'package:intl/intl.dart' show Intl;

import '../../../../core/constants/address_schemas.dart';
import '../../../../core/constants/country_codes.dart';
import '../../../../core/extensions/country_code_extensions.dart';
import '../../../../core/extensions/theme_colors_extension.dart';
import '../../../../core/localization/strings/address_field_strings.dart';
import '../../../../core/localization/strings/phone_field_strings.dart';
import '../../../../core/localization/tr.dart';
import '../../../../core/tokens/extensions.dart';
import '../../../../core/utils/validators/validators.dart';
import '../../../../data/models/common/country_code/country_code.dart';
import '../../../../data/services/location/reverse_geocoding_service.dart'
    show GeocodedAddress;
import '../../../module/chip/global_chip.dart';
import '../../../module/drop_down/global_drop_down.dart';
import '../../../module/text_field/global_text_field.dart';
import '../../dropdown_fields/domain/city_dropdown_field.dart';
import '../../dropdown_fields/domain/country_dropdown_field.dart';
import '../../dropdown_fields/domain/state_dropdown_field.dart';
import '../../selection_fields/checkbox/default_address_checkbox.dart';
import '../generic/multiline_text_field.dart';
import '../generic/simple_text_field.dart';
import '../responsive_field_row.dart';
import 'location_field.dart';
import 'name_field.dart';
import 'phone_number_field.dart';

/// How an address is tagged in a saved-address list.
enum AddressType { home, work, other }

/// The structured value an [AddressForm] emits — parts plus a
/// country-aware [formatted] multi-line string and the validity
/// snapshot.
@immutable
class Address {
  const Address({
    required this.country,
    required this.line1,
    required this.line2,
    required this.city,
    required this.state,
    required this.stateCode,
    required this.postalCode,
    required this.isValid,
    this.type = AddressType.home,
    this.recipient = '',
    this.notes = '',
    this.phone,
    this.location,
    this.isDefault = false,
  });

  final CountryCode country;

  /// Street address (name + number).
  final String line1;

  /// Apartment / building — optional.
  final String line2;

  final String city;

  /// State / governorate / emirate DISPLAY name (resolved from the
  /// dropdown, or free text).
  final String state;

  /// Subdivision code when [state] came from a fixed list (`CAI`, `DU`);
  /// null for free-text states.
  final String? stateCode;

  final String postalCode;

  final bool isValid;

  /// Home / work / other tag (delivery + saved-address lists).
  final AddressType type;

  /// Delivery recipient — empty unless [AddressForm.showRecipient].
  final String recipient;

  /// Courier instructions — empty unless [AddressForm.showNotes].
  final String notes;

  /// Contact phone — null unless [AddressForm.showPhone].
  final PhoneNumber? phone;

  /// Precise point — null unless [AddressForm.showLocation] and set.
  final LocationValue? location;

  /// Default-address flag — always false unless
  /// [AddressForm.showDefaultToggle]. Address-book persistence rides it.
  final bool isDefault;

  /// Multi-line address in reading order: recipient, street, unit, `city
  /// state postal`, country. Empty parts drop out.
  String get formatted {
    final cityLine = [
      city,
      state,
      postalCode,
    ].where((s) => s.trim().isNotEmpty).join(' ');
    return [
      recipient,
      line1,
      line2,
      cityLine,
      country.translatedName,
    ].where((s) => s.trim().isNotEmpty).join('\n');
  }

  Address copyWith({
    CountryCode? country,
    String? line1,
    String? line2,
    String? city,
    String? state,
    String? stateCode,
    String? postalCode,
    bool? isValid,
    AddressType? type,
    String? recipient,
    String? notes,
    PhoneNumber? phone,
    LocationValue? location,
    bool? isDefault,
  }) => Address(
    country: country ?? this.country,
    line1: line1 ?? this.line1,
    line2: line2 ?? this.line2,
    city: city ?? this.city,
    state: state ?? this.state,
    stateCode: stateCode ?? this.stateCode,
    postalCode: postalCode ?? this.postalCode,
    isValid: isValid ?? this.isValid,
    type: type ?? this.type,
    recipient: recipient ?? this.recipient,
    notes: notes ?? this.notes,
    phone: phone ?? this.phone,
    location: location ?? this.location,
    isDefault: isDefault ?? this.isDefault,
  );

  /// Storage-ready map (address book, checkout restore). Country + phone
  /// country serialize as ISO codes; [fromJson] resolves them back.
  Map<String, dynamic> toJson() => {
    'country': country.code,
    'line1': line1,
    'line2': line2,
    'city': city,
    'state': state,
    if (stateCode != null) 'stateCode': stateCode,
    'postalCode': postalCode,
    'type': type.name,
    'recipient': recipient,
    'notes': notes,
    if (phone != null)
      'phone': {
        'country': phone!.country.code,
        'national': phone!.national,
        'e164': phone!.e164,
        'isValid': phone!.isValid,
      },
    if (location != null)
      'location': {
        'lat': location!.latitude,
        'lng': location!.longitude,
        'isValid': location!.isValid,
      },
    'isDefault': isDefault,
    'isValid': isValid,
  };

  factory Address.fromJson(Map<String, dynamic> json) {
    final phoneJson = json['phone'] as Map<String, dynamic>?;
    final locationJson = json['location'] as Map<String, dynamic>?;
    return Address(
      country: CountryCodes.getCountryCodeByCode(
        (json['country'] as String?) ?? '',
      ),
      line1: (json['line1'] as String?) ?? '',
      line2: (json['line2'] as String?) ?? '',
      city: (json['city'] as String?) ?? '',
      state: (json['state'] as String?) ?? '',
      stateCode: json['stateCode'] as String?,
      postalCode: (json['postalCode'] as String?) ?? '',
      type:
          AddressType.values.asNameMap()[(json['type'] as String?) ?? ''] ??
          AddressType.home,
      recipient: (json['recipient'] as String?) ?? '',
      notes: (json['notes'] as String?) ?? '',
      phone: phoneJson == null
          ? null
          : PhoneNumber(
              country: CountryCodes.getCountryCodeByCode(
                (phoneJson['country'] as String?) ?? '',
              ),
              national: (phoneJson['national'] as String?) ?? '',
              e164: (phoneJson['e164'] as String?) ?? '',
              isValid: (phoneJson['isValid'] as bool?) ?? false,
            ),
      location: locationJson == null
          ? null
          : LocationValue(
              latitude: (locationJson['lat'] as num?)?.toDouble() ?? 0,
              longitude: (locationJson['lng'] as num?)?.toDouble() ?? 0,
              isValid: (locationJson['isValid'] as bool?) ?? false,
            ),
      isDefault: (json['isDefault'] as bool?) ?? false,
      isValid: (json['isValid'] as bool?) ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Address &&
          other.country == country &&
          other.line1 == line1 &&
          other.line2 == line2 &&
          other.city == city &&
          other.state == state &&
          other.stateCode == stateCode &&
          other.postalCode == postalCode &&
          other.type == type &&
          other.recipient == recipient &&
          other.notes == notes &&
          other.phone == phone &&
          other.location == location &&
          other.isDefault == isDefault &&
          other.isValid == isValid;

  @override
  int get hashCode => Object.hash(
    country,
    line1,
    line2,
    city,
    state,
    stateCode,
    postalCode,
    type,
    recipient,
    notes,
    phone,
    location,
    isDefault,
    isValid,
  );

  @override
  String toString() =>
      'Address(${formatted.replaceAll('\n', ', ')}, valid: $isValid)';
}

/// Postal / country-mailing address as ONE composite — the shipping /
/// billing capstone beside [PaymentCardForm].
///
/// Country-driven: pick a country and the form reshapes to its address
/// schema ([AddressSchemas]) — JO/EG/SA governorate-or-region labels, AE
/// emirate dropdown with no postal code, US ZIP mask, UK alphanumeric
/// postcode. EG/AE offer a fixed subdivision DROPDOWN (governorates /
/// emirates, en+ar); other countries take a free-text state. Unlisted
/// countries fall back to street + city + state + loose postal.
///
///  * Focus chain advances field to field.
///  * Postal code is masked + validated per the country's rule.
///  * Emits [Address] (parts + `formatted` + validity) via [onChanged].
///  * [initialAddress] prefills.
///
/// ```dart
/// AddressForm(
///   allowedCountries: const ['JO', 'EG', 'AE', 'SA'],
///   onChanged: (a) => cubit.setShipping(a),
/// )
/// ```
class AddressForm extends StatefulWidget {
  const AddressForm({
    super.key,
    this.line1Controller,
    this.line2Controller,
    this.cityController,
    this.stateController,
    this.postalController,
    this.recipientController,
    this.phoneController,
    this.initialCountry,
    this.initialAddress,
    this.onChanged,
    this.enabled = true,
    this.deferToParentForm = true,
    this.validationMode = ValidationMode.onInteraction,
    this.allowedCountries,
    this.preferredCountries = const [],
    this.lockCountry = false,
    this.showAddressType = false,
    this.showRecipient = false,
    this.showPhone = false,
    this.showLocation = false,
    this.showNotes = false,
    this.showDefaultToggle = false,
    this.initialIsDefault = false,
    this.notesController,
    this.onReverseGeocode,
    this.fetchCurrentLocation,
    this.style,
  });

  /// Courier-instructions multiline field ("leave at the door…").
  /// Optional — never gates validity.
  final bool showNotes;

  /// Localized `DefaultAddressCheckbox` at the bottom — never gates
  /// validity; rides [Address.isDefault] (address-book persistence).
  final bool showDefaultToggle;
  final bool initialIsDefault;
  final TextEditingController? notesController;

  /// Reverse-geocode hook: called with the point the user PICKED (GPS /
  /// map — never typed coordinates); the result auto-fills EMPTY address
  /// fields only (typed input is never overwritten). Wire it to
  /// `ReverseGeocodingService.reverseGeocodeAddress` (or any provider):
  ///
  /// ```dart
  /// onReverseGeocode: getIt<ReverseGeocodingService>().reverseGeocodeAddress,
  /// ```
  final Future<GeocodedAddress?> Function(LatLng point)? onReverseGeocode;

  /// GPS source override for the embedded [LocationField] (tests /
  /// custom providers) — defaults to the real geolocator.
  final Future<LatLng?> Function()? fetchCurrentLocation;

  /// Delivery contact controllers (used when [showRecipient] / [showPhone]).
  final TextEditingController? recipientController;
  final TextEditingController? phoneController;

  /// Home / Work / Other tag selector at the top.
  final bool showAddressType;

  /// Recipient-name field (delivery: "deliver to whom").
  final bool showRecipient;

  /// Contact-phone field (a [PhoneNumberField] synced to the address
  /// country).
  final bool showPhone;

  /// Exact-location ([LocationField]) row — GPS + map picker.
  final bool showLocation;

  /// Controllers are optional — the form owns them when absent.
  final TextEditingController? line1Controller;
  final TextEditingController? line2Controller;
  final TextEditingController? cityController;
  final TextEditingController? stateController;
  final TextEditingController? postalController;

  /// Seed country. Null → locale → default (filtered by
  /// [allowedCountries]).
  final CountryCode? initialCountry;

  /// Prefill every field (and the country) from a stored [Address].
  final Address? initialAddress;

  /// Parsed [Address] on every change.
  final ValueChanged<Address>? onChanged;

  final bool enabled;

  /// Keep `true` inside a `Form`; `false` for standalone usage.
  final bool deferToParentForm;

  final ValidationMode validationMode;

  /// ISO whitelist for the country picker.
  final List<String>? allowedCountries;

  /// ISO codes pinned in a "Preferred" picker group.
  final List<String> preferredCountries;

  /// Country stays visible but frozen (single-market checkouts).
  final bool lockCountry;

  /// Visual override applied to every field.
  final TextFieldStyle? style;

  @override
  State<AddressForm> createState() => _AddressFormState();
}

class _AddressFormState extends State<AddressForm> {
  TextEditingController? _ownedLine1,
      _ownedLine2,
      _ownedCity,
      _ownedState,
      _ownedPostal,
      _ownedRecipient,
      _ownedPhone,
      _ownedNotes;
  final _line1Focus = FocusNode();
  final _line2Focus = FocusNode();
  final _cityFocus = FocusNode();
  final _stateFocus = FocusNode();
  final _postalFocus = FocusNode();
  final _recipientFocus = FocusNode();
  final _phoneFocus = FocusNode();

  late CountryCode _country;

  /// Selected subdivision code when the state field is a dropdown.
  String? _stateCode;

  /// Selected area code when the area field is a dropdown (dependent
  /// narrowing under the chosen governorate).
  String? _areaCode;

  AddressType _type = AddressType.home;
  late bool _isDefault = widget.initialIsDefault;
  PhoneNumber? _phone;
  LocationValue? _location;

  TextEditingController get _line1 =>
      widget.line1Controller ?? (_ownedLine1 ??= TextEditingController());
  TextEditingController get _line2 =>
      widget.line2Controller ?? (_ownedLine2 ??= TextEditingController());
  TextEditingController get _city =>
      widget.cityController ?? (_ownedCity ??= TextEditingController());
  TextEditingController get _state =>
      widget.stateController ?? (_ownedState ??= TextEditingController());
  TextEditingController get _postal =>
      widget.postalController ?? (_ownedPostal ??= TextEditingController());
  TextEditingController get _recipient =>
      widget.recipientController ??
      (_ownedRecipient ??= TextEditingController());
  TextEditingController get _phoneCtrl =>
      widget.phoneController ?? (_ownedPhone ??= TextEditingController());
  TextEditingController get _notes =>
      widget.notesController ?? (_ownedNotes ??= TextEditingController());

  @override
  void initState() {
    super.initState();
    final seed =
        widget.initialAddress?.country ??
        widget.initialCountry ??
        _localeCountry() ??
        CountryCodes.getDefaultCountryCode();
    _country = _sanitize(seed);
    final a = widget.initialAddress;
    if (a != null) {
      _line1.text = a.line1;
      _line2.text = a.line2;
      _city.text = a.city;
      _state.text = a.state;
      _stateCode = a.stateCode;
      _postal.text = a.postalCode;
      _recipient.text = a.recipient;
      _notes.text = a.notes;
      _type = a.type;
      _location = a.location;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _emit();
      });
    }
  }

  @override
  void dispose() {
    _ownedLine1?.dispose();
    _ownedLine2?.dispose();
    _ownedCity?.dispose();
    _ownedState?.dispose();
    _ownedPostal?.dispose();
    _ownedRecipient?.dispose();
    _ownedPhone?.dispose();
    _ownedNotes?.dispose();
    _line1Focus.dispose();
    _line2Focus.dispose();
    _cityFocus.dispose();
    _stateFocus.dispose();
    _postalFocus.dispose();
    _recipientFocus.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  AddressSchema get _schema => AddressSchemas.resolve(_country.code);

  // ── country ─────────────────────────────────────────────────────────

  CountryCode? _localeCountry() {
    final iso = WidgetsBinding.instance.platformDispatcher.locale.countryCode;
    if (iso == null || iso.isEmpty) return null;
    final match = CountryCodes.getCountryCodeByCode(iso.toUpperCase());
    return (match == CountryCodes.unknownCountryCode || !_isAllowed(match))
        ? null
        : match;
  }

  bool _isAllowed(CountryCode c) {
    final allowed = widget.allowedCountries;
    if (allowed == null || allowed.isEmpty) return true;
    return allowed.any((iso) => iso.toUpperCase() == c.code);
  }

  List<CountryCode> get _selectableCountries => CountryCodes.countryCodes
      .where((c) => c != CountryCodes.unknownCountryCode && _isAllowed(c))
      .toList();

  CountryCode _sanitize(CountryCode c) {
    if (c != CountryCodes.unknownCountryCode && _isAllowed(c)) return c;
    final fallback = CountryCodes.getDefaultCountryCode();
    if (_isAllowed(fallback)) return fallback;
    final selectable = _selectableCountries;
    return selectable.isEmpty ? fallback : selectable.first;
  }

  void _selectCountry(CountryCode c) {
    setState(() {
      _country = c;
      // The subdivision list changed — a stale code/name no longer
      // belongs. Clear it so the user re-picks under the new schema.
      _stateCode = null;
      _areaCode = null;
      _state.clear();
      _city.clear();
    });
    _emit();
  }

  // ── state (subdivision) ─────────────────────────────────────────────

  bool get _isAr => Intl.getCurrentLocale().startsWith('ar');

  String _localizedSubdivision(AddressSubdivision s) => _isAr ? s.$3 : s.$2;

  void _selectState(String code) {
    final list = _schema.subdivisions!;
    final match = list.where((s) => s.$1 == code).firstOrNull;
    setState(() {
      _stateCode = code;
      _state.text = match == null ? '' : _localizedSubdivision(match);
      // Dependent narrowing: the area list is scoped to the governorate,
      // so a stale area no longer applies.
      _areaCode = null;
      _city.clear();
    });
    _emit();
    // Advance to the area field.
    if (widget.enabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _cityFocus.requestFocus();
      });
    }
  }

  void _selectArea(String code) {
    final list = _schema.areasFor(_stateCode);
    final match = list?.where((s) => s.$1 == code).firstOrNull;
    setState(() {
      _areaCode = code;
      _city.text = match == null ? '' : _localizedSubdivision(match);
    });
    _emit();
    if (widget.enabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          (_schema.has(AddressLine.postalCode) ? _postalFocus : _line1Focus)
              .requestFocus();
        }
      });
    }
  }

  // ── validation + emission ───────────────────────────────────────────

  String get _stateLabel => Tr.t(
    'address_field.${_schema.stateLabelKey}',
    _stateLabelFor(_schema.stateLabelKey),
  );

  String _stateLabelFor(String key) => switch (key) {
    'governorate' => AddressFieldStrings.governorate,
    'emirate' => AddressFieldStrings.emirate,
    'region' => AddressFieldStrings.region,
    'county' => AddressFieldStrings.county,
    _ => AddressFieldStrings.state,
  };

  /// "City" for state-based countries; "Area / District" under a
  /// governorate/emirate (a bare "City" would duplicate the province).
  String get _cityLabel => _schema.cityLabelKey == 'area'
      ? AddressFieldStrings.area
      : AddressFieldStrings.city;

  String get _cityHint => _schema.cityLabelKey == 'area'
      ? AddressFieldStrings.areaHint
      : AddressFieldStrings.cityHint;

  String get _postalLabel => Tr.t(
    'address_field.${_schema.postalLabelKey}',
    _postalLabelFor(_schema.postalLabelKey),
  );

  String _postalLabelFor(String key) => switch (key) {
    'zip_code' => AddressFieldStrings.zipCode,
    'postcode' => AddressFieldStrings.postcode,
    _ => AddressFieldStrings.postalCode,
  };

  /// "Street address is required" — names the field, not a bare
  /// "Required".
  String? Function(String?) _requiredFor(String label) =>
      (v) => (v == null || v.trim().isEmpty)
      ? AddressFieldStrings.fieldRequired(label)
      : null;

  String? _postalValidator(String? v) {
    final text = (v ?? '').trim();
    if (text.isEmpty) {
      return AddressFieldStrings.fieldRequired(_postalLabel);
    }
    final pattern = _schema.postalPattern;
    if (pattern != null && !pattern.hasMatch(text.toUpperCase())) {
      return AddressFieldStrings.postalInvalid(_postalLabel);
    }
    return null;
  }

  bool get _isValid {
    if (_line1.text.trim().isEmpty || _city.text.trim().isEmpty) return false;
    if (_schema.has(AddressLine.state) && _state.text.trim().isEmpty) {
      return false;
    }
    if (_schema.has(AddressLine.postalCode) &&
        _postalValidator(_postal.text) != null) {
      return false;
    }
    // Mirror the NameField's own rule (full name, ≥2 parts).
    if (widget.showRecipient &&
        Validators.validateFullName(_recipient.text) != null) {
      return false;
    }
    if (widget.showPhone && !(_phone?.isValid ?? false)) return false;
    return true;
  }

  void _emit() {
    final cb = widget.onChanged;
    if (cb == null) return;
    cb(
      Address(
        country: _country,
        line1: _line1.text.trim(),
        line2: _schema.has(AddressLine.line2) ? _line2.text.trim() : '',
        city: _city.text.trim(),
        state: _schema.has(AddressLine.state) ? _state.text.trim() : '',
        stateCode: _stateCode,
        postalCode: _schema.has(AddressLine.postalCode)
            ? _postal.text.trim()
            : '',
        type: _type,
        recipient: widget.showRecipient ? _recipient.text.trim() : '',
        notes: widget.showNotes ? _notes.text.trim() : '',
        phone: widget.showPhone ? _phone : null,
        location: widget.showLocation ? _location : null,
        isDefault: widget.showDefaultToggle && _isDefault,
        isValid: _isValid,
      ),
    );
  }

  /// A GPS/map pick landed — reverse-geocode it and fill EMPTY fields
  /// only (typed input is never overwritten). Country switches only when
  /// the whole address is still untouched (switching clears fields).
  Future<void> _onPointPicked(LatLng point) async {
    final lookup = widget.onReverseGeocode;
    if (lookup == null) return;
    final geo = await lookup(point);
    if (!mounted || geo == null) return;

    final untouched =
        _line1.text.trim().isEmpty &&
        _city.text.trim().isEmpty &&
        _state.text.trim().isEmpty &&
        _postal.text.trim().isEmpty;
    if (untouched &&
        geo.countryIso.isNotEmpty &&
        geo.countryIso != _country.code) {
      final match = CountryCodes.getCountryCodeByCode(geo.countryIso);
      if (match != CountryCodes.unknownCountryCode && _isAllowed(match)) {
        _selectCountry(match);
      }
    }
    setState(() {
      if (_line1.text.trim().isEmpty && geo.street.isNotEmpty) {
        _line1.text = geo.street;
      }
      // Area prefers the neighborhood; falls back to the locality.
      final area = geo.area.isNotEmpty ? geo.area : geo.city;
      if (_city.text.trim().isEmpty &&
          area.isNotEmpty &&
          _schema.areasFor(_stateCode) == null) {
        _city.text = area;
      }
      // Free-text state only — a subdivision dropdown needs a code, and
      // matching Google's naming against it is guesswork.
      if (_schema.subdivisions == null &&
          _state.text.trim().isEmpty &&
          geo.state.isNotEmpty) {
        _state.text = geo.state;
      }
      if (_schema.has(AddressLine.postalCode) &&
          _postal.text.trim().isEmpty &&
          geo.postalCode.isNotEmpty) {
        _postal.text = geo.postalCode;
      }
    });
    _emit();
  }

  // ── build ───────────────────────────────────────────────────────────

  /// Canonical country row — shared with the standalone
  /// `CountryDropdownField` so both pickers render identically (sans
  /// dial code; an address picker doesn't need one).
  DropdownItem<CountryCode> _countryItem(CountryCode c) =>
      CountryDropdownField.itemFor(c, withDialCode: false);

  List<DropdownGroup<CountryCode>>? _countryGroups() {
    final preferred = widget.preferredCountries
        .map((iso) => CountryCodes.getCountryCodeByCode(iso.toUpperCase()))
        .where((c) => c != CountryCodes.unknownCountryCode && _isAllowed(c))
        .toList();
    if (preferred.isEmpty) return null;
    final rest = _selectableCountries
        .where((c) => !preferred.contains(c))
        .toList();
    return [
      DropdownGroup(
        label: PhoneFieldStrings.preferredCountries,
        items: preferred.map(_countryItem).toList(),
      ),
      DropdownGroup(
        label: PhoneFieldStrings.allCountries,
        items: rest.map(_countryItem).toList(),
      ),
    ];
  }

  Widget _prefix(IconData icon) => Padding(
    padding: const EdgeInsetsDirectional.only(start: 12, end: 8),
    child: Icon(icon, color: context.iconColors.primary),
  );

  Widget _header(String text, {bool required = false}) => Padding(
    padding: EdgeInsets.only(bottom: context.spacing.sm),
    child: Text.rich(
      TextSpan(
        text: text,
        children: [
          if (required)
            TextSpan(
              text: ' *',
              style: TextStyle(color: context.statusColors.error),
            ),
        ],
      ),
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 16,
      ),
    ),
  );

  /// Governorate / region / emirate — dropdown when the country carries
  /// a fixed list, else free text. Completing it hops to the area.
  Widget _stateField() {
    final subdivisions = _schema.subdivisions;
    if (subdivisions == null) {
      return SimpleTextField(
        controller: _state,
        focusNode: _stateFocus,
        identifier: _stateLabel,
        required: true,
        hint: AddressFieldStrings.enter(_stateLabel),
        enabled: widget.enabled,
        validationMode: widget.validationMode,
        textInputAction: TextInputAction.next,
        validator: _requiredFor(_stateLabel),
        prefixIcon: _prefix(Icons.map_outlined),
        style: widget.style,
        onChanged: (_) => _emit(),
        onSubmitted: (_) => _cityFocus.requestFocus(),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _header(_stateLabel, required: true),
        GlobalDropdown<String>(
          behavior: const DropdownBehavior(
            isFullScreenWidth: true,
            horizontalPadding: 20,
            enableSearch: true,
          ),
          enabled: widget.enabled,
          slots: const DropdownSlots(prefixIcon: Icons.map_outlined),
          hint: AddressFieldStrings.selectState(_stateLabel),
          style: widget.style,
          // Canonical subdivision rows — shared with the standalone
          // `StateDropdownField`.
          items: subdivisions
              .map((s) => StateDropdownField.itemFor(s, isArabic: _isAr))
              .toList(),
          selectedValue: _stateCode,
          onChanged: (v) {
            if (v != null) _selectState(v);
          },
        ),
      ],
    );
  }

  /// Area / city — a dependent DROPDOWN scoped to the chosen governorate
  /// when the schema narrows it, else free text.
  Widget _areaField() {
    final areas = _schema.areasFor(_stateCode);
    if (areas == null) {
      return SimpleTextField(
        controller: _city,
        focusNode: _cityFocus,
        identifier: _cityLabel,
        required: true,
        hint: _cityHint,
        enabled: widget.enabled,
        validationMode: widget.validationMode,
        textInputAction: TextInputAction.next,
        validator: _requiredFor(_cityLabel),
        prefixIcon: _prefix(Icons.location_city_outlined),
        style: widget.style,
        onChanged: (_) => _emit(),
        onSubmitted: (_) =>
            (_schema.has(AddressLine.postalCode) ? _postalFocus : _line1Focus)
                .requestFocus(),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _header(_cityLabel, required: true),
        GlobalDropdown<String>(
          behavior: const DropdownBehavior(
            isFullScreenWidth: true,
            horizontalPadding: 20,
            enableSearch: true,
          ),
          enabled: widget.enabled,
          slots: const DropdownSlots(prefixIcon: Icons.location_city_outlined),
          hint: AddressFieldStrings.selectState(_cityLabel),
          style: widget.style,
          // Canonical area rows — shared with the standalone
          // `CityDropdownField`.
          items: areas
              .map((s) => CityDropdownField.itemFor(s, isArabic: _isAr))
              .toList(),
          selectedValue: _areaCode,
          onChanged: (v) {
            if (v != null) _selectArea(v);
          },
        ),
      ],
    );
  }

  Widget _postalField() => SimpleTextField(
    controller: _postal,
    focusNode: _postalFocus,
    identifier: _postalLabel,
    required: true,
    hint: _schema.postalExampleHint,
    enabled: widget.enabled,
    validationMode: widget.validationMode,
    textInputAction: TextInputAction.next,
    keyboardType: _schema.postalDigitsOnly
        ? TextInputType.number
        : TextInputType.text,
    inputFormatters: [
      LengthLimitingTextInputFormatter(_schema.postalMaxLength),
      if (_schema.postalDigitsOnly)
        FilteringTextInputFormatter.digitsOnly
      else
        UpperCaseInputFormatter(),
    ],
    validator: _postalValidator,
    prefixIcon: _prefix(Icons.local_post_office_outlined),
    style: widget.style,
    onChanged: (_) => _emit(),
    onSubmitted: (_) => _line1Focus.requestFocus(),
  );

  // ── contact + type + location ───────────────────────────────────────

  static const _typeIcons = {
    AddressType.home: Icons.home_outlined,
    AddressType.work: Icons.work_outline,
    AddressType.other: Icons.place_outlined,
  };

  String _typeLabel(AddressType t) => switch (t) {
    AddressType.home => AddressFieldStrings.typeHome,
    AddressType.work => AddressFieldStrings.typeWork,
    AddressType.other => AddressFieldStrings.typeOther,
  };

  Widget _typeSelector() => Wrap(
    spacing: context.spacing.sm,
    runSpacing: context.spacing.sm,
    children: [
      for (final t in AddressType.values)
        GlobalChip(
          label: _typeLabel(t),
          avatar: Icon(
            _typeIcons[t],
            size: 18,
            color: _type == t
                ? Theme.of(context).colorScheme.onPrimary
                : context.iconColors.primary,
          ),
          selected: _type == t,
          enabled: widget.enabled,
          onSelected: (_) {
            setState(() => _type = t);
            _emit();
          },
        ),
    ],
  );

  /// The full-name wrapper (capitalization, min-2-parts validation,
  /// `name` autofill) — not a bare text field.
  Widget _recipientField() => NameField(
    controller: _recipient,
    focusNode: _recipientFocus,
    mode: NameFieldMode.full,
    identifier: AddressFieldStrings.recipient,
    required: true,
    hint: AddressFieldStrings.recipientHint,
    enabled: widget.enabled,
    deferToParentForm: widget.deferToParentForm,
    validationMode: widget.validationMode,
    showPartsProgress: false,
    style: widget.style,
    onChanged: (_) => _emit(),
    onSubmitted: (_) =>
        (widget.showPhone ? _phoneFocus : _line1Focus).requestFocus(),
  );

  Widget _phoneField() => PhoneNumberField(
    controller: _phoneCtrl,
    focusNode: _phoneFocus,
    identifier: AddressFieldStrings.phone,
    // Sync the dialling country to the address country.
    initialCountry: _country,
    enabled: widget.enabled,
    deferToParentForm: widget.deferToParentForm,
    validationMode: widget.validationMode,
    style: widget.style,
    onNumberChanged: (n) {
      _phone = n;
      _emit();
    },
  );

  @override
  Widget build(BuildContext context) {
    final schema = _schema;
    final gap = SizedBox(height: context.spacing.md);
    final groups = _countryGroups();
    // One autofill context — the OS fills street/city/state/postal as a
    // single saved address.
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.showAddressType) ...[
            _typeSelector(),
            gap,
          ],
          if (widget.showRecipient) ...[
            _recipientField(),
            gap,
          ],
          if (widget.showPhone) ...[
            _phoneField(),
            gap,
          ],
          // Country — drives the rest of the form.
          Padding(
            padding: EdgeInsets.only(bottom: context.spacing.sm),
            child: Text(
              AddressFieldStrings.country,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
          GlobalDropdown<CountryCode>(
            behavior: const DropdownBehavior(
              isFullScreenWidth: true,
              horizontalPadding: 20,
              enableSearch: true,
            ),
            enabled: widget.enabled && !widget.lockCountry,
            style: widget.style,
            groups: groups,
            items: groups != null
                ? const []
                : _selectableCountries.map(_countryItem).toList(),
            selectedValue: _country,
            onChanged: (v) {
              if (v != null) _selectCountry(v);
            },
          ),
          // Big → small (MENA convention): governorate, then the area
          // inside it, then the street.
          if (schema.has(AddressLine.state)) ...[
            gap,
            _stateField(),
          ],
          gap,
          // Area + postal share a row when both fit; the postal drops below
          // the area as the form narrows (ResponsiveFieldRow).
          if (schema.has(AddressLine.postalCode))
            ResponsiveFieldRow(
              children: [
                ResponsiveField(minWidth: 200, child: _areaField()),
                ResponsiveField(minWidth: 150, child: _postalField()),
              ],
            )
          else
            _areaField(),
          gap,
          SimpleTextField(
            controller: _line1,
            focusNode: _line1Focus,
            identifier: AddressFieldStrings.street,
            required: true,
            hint: AddressFieldStrings.streetHint,
            enabled: widget.enabled,
            validationMode: widget.validationMode,
            textInputAction: schema.has(AddressLine.line2)
                ? TextInputAction.next
                : TextInputAction.done,
            validator: _requiredFor(AddressFieldStrings.street),
            prefixIcon: _prefix(Icons.signpost_outlined),
            style: widget.style,
            onChanged: (_) => _emit(),
            onSubmitted: (_) {
              if (schema.has(AddressLine.line2)) _line2Focus.requestFocus();
            },
          ),
          if (schema.has(AddressLine.line2)) ...[
            gap,
            SimpleTextField(
              controller: _line2,
              focusNode: _line2Focus,
              identifier: AddressFieldStrings.line2,
              hint: AddressFieldStrings.line2Hint,
              enabled: widget.enabled,
              validationMode: widget.validationMode,
              textInputAction: TextInputAction.done,
              prefixIcon: _prefix(Icons.apartment_outlined),
              style: widget.style,
              onChanged: (_) => _emit(),
            ),
          ],
          if (widget.showLocation) ...[
            gap,
            LocationField(
              initial: widget.initialAddress?.location?.latLng,
              enabled: widget.enabled,
              validationMode: widget.validationMode,
              style: widget.style,
              onLocationChanged: (loc) {
                _location = loc;
                _emit();
              },
              // GPS/map pick → reverse geocode → fill empty fields.
              onPointPicked: widget.onReverseGeocode == null
                  ? null
                  : _onPointPicked,
              fetchCurrentLocation: widget.fetchCurrentLocation,
            ),
          ],
          if (widget.showNotes) ...[
            gap,
            MultilineTextField(
              controller: _notes,
              identifier: AddressFieldStrings.notes,
              hint: AddressFieldStrings.notesHint,
              enabled: widget.enabled,
              minLines: 2,
              maxLines: 4,
              maxLength: 200,
              validationMode: widget.validationMode,
              onChanged: (_) => _emit(),
            ),
          ],
          if (widget.showDefaultToggle) ...[
            gap,
            DefaultAddressCheckbox(
              value: _isDefault,
              enabled: widget.enabled,
              onChanged: (v) {
                setState(() => _isDefault = v);
                _emit();
              },
            ),
          ],
        ],
      ),
    );
  }
}
