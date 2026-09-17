import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/auth/auth_gate.dart';
import '../../../core/constants/country_codes.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/strings/address_strings.dart';
import '../../../core/tokens/extensions.dart';
import '../../../core/types/result.dart';
import '../../../data/api/calls/address_apis.dart';
import '../../../data/models/terracotta/account/address.dart';
import '../../../data/models/terracotta/content/delivery_zone.dart';
import '../../../shared/common/text_form_fields/domain/location_picker_sheet.dart';
import '../../../shared/common/text_form_fields/domain/phone_number_field.dart';
import '../../../shared/module/buttons/global_filled_button.dart';
import '../../../shared/module/buttons/global_outlined_button.dart';
import '../../../shared/module/container/global_container.dart';
import '../../../shared/module/drop_down/index.dart';
import '../../../shared/module/scrollable/global_scrollable.dart';
import '../../../shared/module/text_field/global_text_field.dart';
import '../../../shared/module/toast/global_toast.dart';
import '../../_shared/screen_entrance.dart';
import '../../_shared/terracotta_cta_style.dart';
import '../../_shared/terracotta_page_bar.dart';
import '../data/address_draft.dart';
import '../data/guest_addresses.dart';
import '../data/short_address.dart';

/// «اضف عنوان» — the form behind the address book.
///
/// **Not `AddressForm` from the shared library.** That one is an
/// international postal form: a country picker, line 1 / line 2, a
/// state and a loose postal code. Terracotta delivers inside Saudi
/// Arabia only and the server wants the NATIONAL address — building
/// number, street, district, postal code, additional number, an
/// optional unit — plus a `delivery_zone_id` for the city, because the
/// city is what carries the delivery fee. A country picker on a
/// one-country app is a field with one answer.
///
/// The short national address at the head is a SHORTCUT, not a gate:
/// eight characters fill five fields and drop the pin. Every failure
/// falls through to the manual fields, which are always visible.
class AddressFormPage extends StatefulWidget {
  const AddressFormPage({
    required this.zones,
    this.existing,
    this.isFirst = false,
    super.key,
  });

  /// Whether this is the customer's FIRST address.
  ///
  /// The server makes the first one the default whatever the request
  /// says, so the switch has nothing to decide — see [_isOnlyAddress].

  /// The cities, from `GET /api/delivery-zones`. Handed in by the list
  /// so opening the form costs no request.
  final List<DeliveryZone> zones;

  /// Null to add, an address to edit.
  final Address? existing;

  final bool isFirst;

  @override
  State<AddressFormPage> createState() => _AddressFormPageState();
}

class _AddressFormPageState extends State<AddressFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _cancel = CancelToken();

  late final _short = TextEditingController(
    text: widget.existing?.shortAddress ?? '',
  );
  late final _label = TextEditingController(
    text: widget.existing?.label ?? '',
  );
  late final _street = TextEditingController(
    text: widget.existing?.street ?? '',
  );
  late final _district = TextEditingController(
    text: widget.existing?.district ?? '',
  );
  late final _building = TextEditingController(
    text: widget.existing?.buildingNumber ?? '',
  );
  late final _additional = TextEditingController(
    text: widget.existing?.additionalNumber ?? '',
  );
  late final _postal = TextEditingController(
    text: widget.existing?.postalCode ?? '',
  );
  late final _unit = TextEditingController(
    text: widget.existing?.unitNumber ?? '',
  );
  late final _notes = TextEditingController(
    text: widget.existing?.notes ?? '',
  );
  late final _phone = TextEditingController(
    text: widget.existing?.phone ?? '',
  );

  late int? _zoneId = widget.existing?.deliveryZoneId;
  late LatLng? _pin = widget.existing == null
      ? null
      : LatLng(
          double.parse(widget.existing!.lat),
          double.parse(widget.existing!.lng),
        );

  /// A NEW address, and the only one there will be. The default is not
  /// a choice then — the server makes it one regardless — so the
  /// switch is hidden and the flag is simply true.
  bool get _isOnlyAddress => widget.existing == null && widget.isFirst;

  late bool _isDefault = widget.existing?.isDefault ?? _isOnlyAddress;

  /// The courier's number in `+9665…` form, kept from the phone
  /// field's own parse rather than re-read off the controller — the
  /// controller holds the NATIONAL digits and the dial code lives in
  /// the picker beside it.
  late String? _phoneE164 = widget.existing?.phone;

  bool _looking = false;
  bool _saving = false;

  /// What the last lookup had to say, if anything. A NOTE under the
  /// field — never a form error, because the form below it works.
  String? _lookupNote;
  bool _lookupWorked = false;

  @override
  void dispose() {
    _cancel.cancel('address form closed');
    for (final c in [
      _short,
      _label,
      _street,
      _district,
      _building,
      _additional,
      _postal,
      _unit,
      _notes,
      _phone,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Eight characters in, five fields and a pin out.
  ///
  /// Fired from a button, never per keystroke: the endpoint is
  /// rate-limited and every call costs against a paid third-party
  /// quota.
  Future<void> _lookUp() async {
    final code = _short.text.trim().toUpperCase();
    if (!ShortAddress.isWellFormed(code)) {
      setState(() {
        _lookupWorked = false;
        _lookupNote = AddressStrings.shortInvalid;
      });
      return;
    }

    setState(() => _looking = true);
    final result = await AddressApis.lookupShortAddress(
      shortAddress: code,
      cancelToken: _cancel,
    );
    if (!mounted) return;

    switch (result) {
      case Success(:final value):
        setState(() {
          _looking = false;
          _lookupWorked = true;
          _lookupNote = AddressStrings.shortFound;
          // PREFILLED, not locked. It is a geocoder result, not
          // gospel — the customer confirms it.
          _building.text = '${value['building_number'] ?? ''}';
          _street.text = '${value['street'] ?? ''}';
          _district.text = '${value['district'] ?? ''}';
          _postal.text = '${value['postal_code'] ?? ''}';
          final lat = value['lat'];
          final lng = value['lng'];
          if (lat is num && lng is num) {
            _pin = LatLng(lat.toDouble(), lng.toDouble());
          }
          // `additional_number` is NOT returned — no geocoder carries
          // it — and the city is a display string here while the saved
          // address needs `delivery_zone_id`. Both stay manual.
        });
      case Failure(:final error):
        setState(() {
          _looking = false;
          _lookupWorked = false;
          _lookupNote = switch (ShortAddress.outcomeFor(error)) {
            ShortAddressOutcome.notFound => AddressStrings.shortNotFound,
            ShortAddressOutcome.tooFast => AddressStrings.shortTooFast,
            ShortAddressOutcome.unavailable => AddressStrings.shortUnavailable,
          };
        });
    }
  }

  Future<void> _pickPin() async {
    const seed = LatLng(AddressDraft.seedLat, AddressDraft.seedLng);

    // THE PICKER OPENS. It did not use to: Google Maps kills the app
    // the moment a map view is built without `MAPS_NATIVE_API_KEY`, so
    // the form dropped the studio's own city itself and said so. The
    // picker draws from OpenStreetMap now and needs no key — see
    // [GlobalOsmMap] — and this gate is `true` for every build. It is
    // kept for a tile host that really does need credentials.
    if (!AddressDraft.canPickOnMap) {
      setState(() => _pin = seed);
      GlobalToast.info(AddressStrings.pinFallback);
      return;
    }

    final picked = await LocationPickerSheet.show(
      context,
      // SEEDED on Riyadh when there is nothing to seed with — the
      // picker's own default is Amman, and the server refuses a pin
      // outside Saudi Arabia.
      initial: _pin ?? seed,
    );
    if (picked != null && mounted) setState(() => _pin = picked);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_pin == null) {
      GlobalToast.info(AddressStrings.pinMissing);
      return;
    }

    setState(() => _saving = true);
    final existing = widget.existing;

    // NO SESSION, NO REQUEST.
    //
    // Every address route answers 401 for a guest, and someone filling
    // in a delivery address is about to buy something — the worst
    // possible moment to make them type it again after signing in. The
    // device's own book takes it instead. See [GuestAddresses].
    if (!AuthGate.has(context) && getIt.isRegistered<GuestAddresses>()) {
      final saved = getIt<GuestAddresses>().save(_localAddress(existing));
      if (!mounted) return;
      setState(() => _saving = false);
      GlobalToast.success(AddressStrings.saved);
      Navigator.of(context).pop(saved);
      return;
    }

    final result = existing == null
        ? await AddressApis.addAddress(
            buildingNumber: _building.text.trim(),
            street: _street.text.trim(),
            district: _district.text.trim(),
            postalCode: _postal.text.trim(),
            additionalNumber: _additional.text.trim(),
            lat: _pin!.latitude,
            lng: _pin!.longitude,
            phone: AddressDraft.phoneToSend(
              e164: _phoneE164,
              typed: _phone.text,
            ),
            label: AddressDraft.blankToNull(_label.text),
            unitNumber: AddressDraft.blankToNull(_unit.text),
            shortAddress: AddressDraft.blankToNull(_short.text.toUpperCase()),
            deliveryZoneId: _zoneId,
            notes: AddressDraft.blankToNull(_notes.text),
            isDefault: _isDefault,
            cancelToken: _cancel,
          )
        : await AddressApis.updateAddress(
            '${existing.id}',
            buildingNumber: _building.text.trim(),
            street: _street.text.trim(),
            district: _district.text.trim(),
            postalCode: _postal.text.trim(),
            additionalNumber: _additional.text.trim(),
            lat: _pin!.latitude,
            lng: _pin!.longitude,
            phone: AddressDraft.phoneToSend(
              e164: _phoneE164,
              typed: _phone.text,
            ),
            label: AddressDraft.blankToNull(_label.text),
            unitNumber: AddressDraft.blankToNull(_unit.text),
            shortAddress: AddressDraft.blankToNull(_short.text.toUpperCase()),
            deliveryZoneId: _zoneId,
            notes: AddressDraft.blankToNull(_notes.text),
            isDefault: _isDefault,
            cancelToken: _cancel,
          );
    if (!mounted) return;
    setState(() => _saving = false);

    switch (result) {
      case Success(:final value):
        GlobalToast.success(AddressStrings.saved);
        Navigator.of(context).pop(value);
      case Failure(:final error):
        // A 422 names the INPUT it refused — `errors.postal_code`, and
        // `errors.lat` for a pin outside Saudi Arabia.
        GlobalToast.error(error.message);
    }
  }

  /// The form as an [Address], for the device's own book.
  ///
  /// The id is the store's to hand out — see [GuestAddresses]. The zone
  /// NAME and FEE are looked up from the zones the list page already
  /// fetched, because `/api/delivery-zones` is public and a local
  /// address should still carry a real fee into the checkout.
  Address _localAddress(Address? existing) {
    final zone = widget.zones.where((z) => z.id == _zoneId).firstOrNull;
    return Address(
      // Kept when editing; replaced by the store when new.
      id: existing?.id ?? 0,
      label: AddressDraft.blankToNull(_label.text),
      addressLine: [
        _building.text.trim(),
        _street.text.trim(),
        _district.text.trim(),
      ].where((p) => p.isNotEmpty).join('، '),
      lat: '${_pin!.latitude}',
      lng: '${_pin!.longitude}',
      phone: AddressDraft.phoneToSend(e164: _phoneE164, typed: _phone.text),
      notes: AddressDraft.blankToNull(_notes.text),
      buildingNumber: _building.text.trim(),
      street: _street.text.trim(),
      district: _district.text.trim(),
      postalCode: _postal.text.trim(),
      additionalNumber: _additional.text.trim(),
      unitNumber: AddressDraft.blankToNull(_unit.text),
      shortAddress: AddressDraft.blankToNull(_short.text.toUpperCase()),
      deliveryZoneId: _zoneId ?? 0,
      deliveryZone: zone?.name ?? '',
      deliveryFee: zone?.fee ?? '0.00',
      isDefault: _isDefault,
      // The server builds this from the pin; the same two numbers, in
      // the form every map app takes.
      mapUrl: 'https://maps.google.com/?q=${_pin!.latitude},${_pin!.longitude}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final editing = widget.existing != null;

    return Scaffold(
      backgroundColor: context.backgroundColors.scaffoldBackground,
      appBar: TerracottaPageBar(
        title: editing ? AddressStrings.edit : AddressStrings.add,
      ),
      body: Form(
        key: _formKey,
        child: GlobalScrollable(
          child: GlobalContainer.shell(
            padding: EdgeInsetsDirectional.fromSTEB(
              spacing.md,
              spacing.md,
              spacing.md,
              spacing.xxl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              // STAGGERED as the page settles — the rows arrive one after
              // another rather than the whole block appearing at once.
              children: ScreenEntrance.stage([
                _ShortAddressField(
                  controller: _short,
                  busy: _looking,
                  note: _lookupNote,
                  noteIsGood: _lookupWorked,
                  onFind: _looking ? null : () => unawaited(_lookUp()),
                ),
                SizedBox(height: spacing.lg),
                _Divider(text: AddressStrings.orManual),
                SizedBox(height: spacing.lg),

                _Field(
                  label: AddressStrings.labelField,
                  controller: _label,
                  hint: AddressStrings.labelHint,
                ),
                SizedBox(height: spacing.md),

                // The CITY is a zone id, not text — it is what sets the
                // delivery fee, so it is a list of the studio's own
                // zones rather than a box to type a city into.
                GlobalDropdownFormField<int>(
                  hint: AddressStrings.city,
                  identifier: AddressStrings.city,
                  initialValue: _zoneId,
                  items: [
                    for (final zone in widget.zones)
                      DropdownItem(value: zone.id, label: zone.name),
                  ],
                  // REQUIRED, like the street above it. The zone is
                  // what carries the delivery fee, so an address saved
                  // without one cannot be delivered to — and this was
                  // the only field on the form that could be left
                  // empty and still save.
                  //
                  // The STAR as well as the rule: without it a required
                  // picker sat in a form of starred fields looking
                  // optional.
                  required: true,
                  validation: DropdownValidation<int>(
                    validator: (id) =>
                        id == null ? AddressStrings.cityRequired : null,
                    // ON INTERACTION, not on submit.
                    //
                    // `onSubmit` is the default and it only re-runs
                    // when the whole form is validated — so the
                    // message appeared on the first save, the red
                    // border arrived a save later, and PICKING A CITY
                    // left both of them on screen until the customer
                    // pressed save again. This re-checks the moment
                    // the picker answers, which is when the reader
                    // expects the complaint to go away.
                    mode: ValidationMode.onInteraction,
                  ),
                  onChanged: (id) => setState(() => _zoneId = id),
                ),
                // THE LIST CAME BACK EMPTY.
                //
                // `GET /api/delivery-zones` is a separate call made
                // before this page opens, and when it fails the picker
                // opens onto nothing — which reads as a studio that
                // delivers nowhere rather than as a request that did
                // not land. Said out loud, with the way to retry.
                if (widget.zones.isEmpty) ...[
                  SizedBox(height: spacing.xs),
                  Text(
                    AddressStrings.zonesEmpty,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.statusColors.error,
                    ),
                  ),
                ],
                SizedBox(height: spacing.md),

                _Field(
                  label: AddressStrings.street,
                  controller: _street,
                  hint: AddressStrings.hintStreet,
                  required: true,
                ),
                SizedBox(height: spacing.md),
                _Field(
                  label: AddressStrings.district,
                  controller: _district,
                  hint: AddressStrings.hintDistrict,
                  required: true,
                ),
                SizedBox(height: spacing.md),

                // PAIRED. Four digits beside four, five beside a unit —
                // the national address is mostly short values, and one
                // per row made a form the customer scrolled through
                // twice to read once.
                _Pair(
                  start: _Field(
                    label: AddressStrings.building,
                    controller: _building,
                    hint: AddressStrings.hintBuilding,
                    digits: 4,
                    required: true,
                  ),
                  // REQUIRED by the server, not by choice: the create
                  // body lists  alongside the
                  // building number and the postal code. The LOOKUP
                  // cannot fill it — no geocoder carries it — so it is
                  // the one national-address field a customer always
                  // types by hand.
                  // REQUIRED by the SERVER, not by choice: the create
                  // body lists `additional_number` beside the building
                  // number and the postal code. The lookup cannot fill
                  // it either — no geocoder carries one — so it is the
                  // national-address field a customer always types by
                  // hand.
                  end: _Field(
                    label: AddressStrings.additional,
                    controller: _additional,
                    hint: AddressStrings.hintAdditional,
                    digits: 4,
                    required: true,
                  ),
                ),
                SizedBox(height: spacing.md),
                _Pair(
                  start: _Field(
                    label: AddressStrings.postal,
                    controller: _postal,
                    hint: AddressStrings.hintPostal,
                    digits: 5,
                    required: true,
                  ),
                  end: _Field(
                    label: AddressStrings.unit,
                    controller: _unit,
                    hint: AddressStrings.hintUnit,
                  ),
                ),
                SizedBox(height: spacing.md),

                // The SAME field the sign-in screen uses — a country
                // picker beside the digits, so a courier number is
                // entered the one way this app enters numbers. Typed
                // into a plain box it was the only place in the app
                // where the dial code was the customer's problem.
                PhoneNumberField(
                  controller: _phone,
                  identifier: AddressStrings.phone,
                  hint: AddressStrings.hintPhone,
                  initialFullNumber: widget.existing?.phone,
                  // The studio delivers inside Saudi Arabia only, and
                  // the courier calls a Saudi number.
                  initialCountry: CountryCodes.getCountryCodeByCode('SA'),
                  preferredCountries: const ['SA'],
                  onNumberChanged: (n) => _phoneE164 = n.e164,
                ),
                SizedBox(height: spacing.md),
                _Field(
                  label: AddressStrings.notes,
                  controller: _notes,
                  hint: AddressStrings.hintNotes,
                ),
                SizedBox(height: spacing.lg),

                _PinRow(pin: _pin, onPick: () => unawaited(_pickPin())),
                SizedBox(height: spacing.md),

                // NOT A CHOICE ON THE FIRST ONE.
                //
                // A customer with no addresses is saving the address
                // everything will be delivered to, and the server makes
                // it the default whatever this switch says. Offering it
                // as a decision — and defaulting it OFF — asked a
                // question with one possible answer and showed the
                // wrong one. [_isDefault] is forced true in that case,
                // so the request agrees with the screen.
                if (!_isOnlyAddress) ...[
                  SwitchListTile.adaptive(
                    value: _isDefault,
                    onChanged: (v) => setState(() => _isDefault = v),
                    title: Text(AddressStrings.makeDefault),
                    contentPadding: EdgeInsets.zero,
                  ),
                  SizedBox(height: spacing.lg),
                ],

                GlobalFilledButton(
                  text: AddressStrings.save,
                  isLoading: _saving,
                  style: terracottaCtaStyle(showArrow: false),
                  onPressed: () => unawaited(_save()),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

/// The eight-character shortcut, and what the last attempt had to say.
class _ShortAddressField extends StatelessWidget {
  const _ShortAddressField({
    required this.controller,
    required this.busy,
    required this.note,
    required this.noteIsGood,
    required this.onFind,
  });

  final TextEditingController controller;
  final bool busy;

  /// What the last lookup had to say. Rendered through the field's OWN
  /// message row rather than a `Text` under it — the module already
  /// styles, spaces and icons these, and a hand-drawn line beneath one
  /// box in a form of nine looked like a different kind of thing.
  final String? note;

  final bool noteIsGood;
  final VoidCallback? onFind;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlobalTextFormField(
          controller: controller,
          hint: AddressStrings.shortHint,
          identifier: AddressStrings.shortLabel,
          behavior: const TextFieldBehavior(
            textCapitalization: TextCapitalization.characters,
            // LTR, forced. In an Arabic layout an unmarked
            // Latin-plus-digits string renders in a confusing order —
            // `RCTB4359` reads as `4359RCTB`.
            textDirection: TextDirection.ltr,
            maxLength: ShortAddress.length,
          ),
          // A WARNING, never an error. Every outcome here means "type
          // it below", and the fields below are already usable — the
          // error ramp would say the form was broken when it is not.
          messages: [
            if (note == null)
              FieldMessage.info(AddressStrings.shortHelp)
            else if (noteIsGood)
              FieldMessage.success(note!)
            else
              FieldMessage.warning(note!),
          ],
        ),
        SizedBox(height: spacing.sm),
        // ITS OWN LINE. Beside the field it squeezed an eight-character
        // box into two thirds of the row and needed a hard-coded width
        // to stop the module's button stretching to infinity.
        GlobalOutlinedButton(
          text: AddressStrings.shortFind,
          isLoading: busy,
          onPressed: onFind,
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    required this.hint,
    this.digits,
    this.required = false,
  });

  /// The field's name — passed as the module's `identifier`, which is
  /// the FLOATING LABEL inside the box. A header drawn above every box
  /// doubled the height of a nine-field form and said the same words
  /// twice, once outside and once in the placeholder.
  final String label;

  final TextEditingController controller;

  /// An EXAMPLE — «مثال: شارع ابي الكرم», «4359».
  ///
  /// REQUIRED, and never the field's own name: the name is already the
  /// header above the box, so a placeholder repeating it put the same
  /// word on screen twice. Required rather than defaulting, so a new
  /// field cannot quietly fall back to the duplication this replaced.
  final String hint;

  /// Exactly this many digits, numeric keyboard — the national
  /// address's own shapes.
  final int? digits;

  final bool required;

  @override
  Widget build(BuildContext context) => GlobalTextFormField(
    controller: controller,
    hint: hint,
    // The module draws `identifier` as a HEADER above the box, with
    // the required star. `floatingLabel` would ALSO render it inside
    // the box until focus — the same word twice, above and within,
    // which is the duplication the design review caught.
    identifier: label,
    required: required,
    behavior: TextFieldBehavior(
      keyboardType: digits != null ? TextInputType.number : TextInputType.text,
      inputFormatters: digits == null
          ? null
          : [FilteringTextInputFormatter.digitsOnly],
      maxLength: digits,
    ),
    validation: TextFieldValidation(
      validator: !required
          ? null
          : (value) {
              final text = (value ?? '').trim();
              if (text.isEmpty) return AddressStrings.required(label);
              if (digits != null && text.length != digits) {
                return AddressStrings.digitsExactly(digits!);
              }
              return null;
            },
    ),
  );
}

/// Two fields sharing a row.
///
/// The national address is mostly SHORT values — a four-digit building
/// number beside a four-digit additional number, a five-digit postal
/// code beside a unit. One per row made a form the customer had to
/// scroll through twice to read once.
class _Pair extends StatelessWidget {
  const _Pair({required this.start, required this.end});

  final Widget start;
  final Widget end;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(child: start),
      SizedBox(width: context.spacing.sm),
      Expanded(child: end),
    ],
  );
}

class _PinRow extends StatelessWidget {
  const _PinRow({required this.pin, required this.onPick});

  final LatLng? pin;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) => GlobalOutlinedButton(
    text: pin == null ? AddressStrings.pin : AddressStrings.pinSet,
    icon: pin == null
        ? Icons.add_location_alt_outlined
        : Icons.location_on_rounded,
    onPressed: onPick,
  );
}

class _Divider extends StatelessWidget {
  const _Divider({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final line = Expanded(
      child: Divider(
        height: 1,
        color: context.textColors.primary.withValues(alpha: 0.1),
      ),
    );

    return Row(
      children: [
        line,
        Padding(
          padding: EdgeInsets.symmetric(horizontal: context.spacing.sm),
          child: Text(
            text,
            style: context.textTheme.labelSmall?.copyWith(
              color: context.textColors.secondary,
            ),
          ),
        ),
        line,
      ],
    );
  }
}
