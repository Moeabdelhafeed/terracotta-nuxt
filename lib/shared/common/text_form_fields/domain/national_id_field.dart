import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' show DateFormat, Intl;

import '../../../../core/constants/country_codes.dart';
import '../../../../core/constants/national_id_specs.dart';
import '../../../../core/localization/strings/national_id_strings.dart';
import '../../../../core/localization/strings/phone_field_strings.dart';
import '../../../../core/localization/tr.dart';
import '../../../../core/tokens/extensions.dart';
import '../../../../data/models/common/country_code/country_code.dart';
import '../../../../data/services/sim_country_service.dart';
import '../../../../generated/l10n.dart';
import '../../../module/drop_down/global_drop_down.dart';
import '../../../module/text_field/global_text_field.dart';
import '../../dropdown_fields/domain/country_code_dropdown_field.dart';
import 'joined_pair_radii.dart';

/// The parsed value a [NationalIdField] emits on every change — country,
/// bare digits, sync-validity snapshot, plus whatever the country's ID
/// encodes (EG: birth date / gender / governorate, SA: citizen vs
/// resident, AE: birth year, KW: birth date).
@immutable
class NationalId {
  const NationalId({
    required this.country,
    required this.digits,
    required this.isValid,
    this.birthDate,
    this.birthYear,
    this.gender,
    this.governorateEn,
    this.governorateAr,
    this.kind,
  });

  final CountryCode country;

  /// ID digits only — no grouping separators.
  final String digits;

  /// Result of the field's SYNC validator at emit time.
  final bool isValid;

  final DateTime? birthDate;
  final int? birthYear;
  final NationalIdGender? gender;
  final String? governorateEn;
  final String? governorateAr;
  final NationalIdKind? kind;

  /// Governorate name for the CURRENT app locale.
  String? get governorate =>
      Intl.getCurrentLocale().startsWith('ar') ? governorateAr : governorateEn;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NationalId &&
          other.country == country &&
          other.digits == digits &&
          other.isValid == isValid;

  @override
  int get hashCode => Object.hash(country, digits, isValid);

  @override
  String toString() => 'NationalId(${country.code} $digits, valid: $isValid)';
}

/// National-ID / civil-number input — dictionary-driven like
/// [PhoneNumberField]: a joined country picker + the ID digits, grouped
/// per the country's semantic segments, validated against
/// [NationalIdSpecs] (exact length, prefix, Luhn / mod-11 checksums,
/// embedded birth-date + governorate structure). KYC staple.
///
/// First-class rules for JO / SA / EG / AE / KW; any other country falls
/// back to a generic digits-length window so the field never blocks.
///
/// Extras over the shared wrapper contract:
///  * [onIdChanged] — parsed [NationalId] (digits / validity / embedded
///    birth date, gender, governorate, citizen-vs-resident kind).
///  * [showParsedInfo] — live info row under a valid ID ("Born
///    14 May 2001 · Cairo · Female") proving the parse to the user.
///  * Eastern-Arabic digits normalize as typed; pasted IDs are cleaned.
///
/// ```dart
/// NationalIdField(
///   controller: idCtrl,
///   allowedCountries: const ['JO', 'SA', 'EG'],
///   onIdChanged: (id) => cubit.setNationalId(id),
/// )
/// ```
class NationalIdField extends StatefulWidget {
  const NationalIdField({
    super.key,
    required this.controller,
    this.initialCountry,
    this.onIdChanged,
    this.onChanged,
    this.onSubmitted,
    this.label,
    this.identifier,
    this.hint,
    this.enabled = true,
    this.readOnly = false,
    this.errorText,
    this.validator,
    this.asyncValidator,
    this.asyncDebounce,
    this.focusNode,
    this.textInputAction = TextInputAction.next,
    this.validationMode = ValidationMode.onInteraction,
    this.deferToParentForm = true,
    this.errorIcon,
    this.errorBuilder,
    this.messages = const [],
    this.showSuccess = false,
    this.successText,
    this.showCountryPicker = true,
    this.showIdIcon = true,
    this.showTemplateGhost = true,
    this.showParsedInfo = true,
    this.lockCountry = false,
    this.allowedCountries,
    this.preferredCountries = const [],
    this.mustMatchBirthDate,
    this.mustMatchBirthDateOrder = DateDigitOrder.dmy,
    this.minAge,
    this.allowedKinds,
    this.suffix,
    this.style,
    this.sizing,
  }) : assert(
         // Const-friendly stand-in for `.isFullDate` (getters can't run in
         // a const assert).
         mustMatchBirthDate == null ||
             (mustMatchBirthDateOrder != DateDigitOrder.my &&
                 mustMatchBirthDateOrder != DateDigitOrder.dm),
         'mustMatchBirthDateOrder must be a full-date order (dmy/mdy/ymd).',
       );

  final TextEditingController controller;

  /// Seed country. Null → SIM (async upgrade) → device locale → default,
  /// filtered by [allowedCountries].
  final CountryCode? initialCountry;

  /// Parsed value on every change — typing, country switches.
  final ValueChanged<NationalId>? onIdChanged;

  /// The ID as displayed (grouped).
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final String? label;
  final String? identifier;

  /// Null → localized "Enter national ID".
  final String? hint;

  final bool enabled;
  final bool readOnly;
  final String? errorText;

  /// Sync check override. Null → the country's [NationalIdSpec] rules
  /// (length / prefix / checksum / embedded structure), generic length
  /// window for spec-less countries.
  final String? Function(String?)? validator;

  /// Server-side KYC check on the bare digits. Runs after the sync
  /// validator passes.
  final Future<String?> Function(String value)? asyncValidator;
  final Duration? asyncDebounce;

  final FocusNode? focusNode;
  final TextInputAction textInputAction;
  final ValidationMode validationMode;

  /// Keep `true` inside a `Form`; `false` for standalone fields.
  final bool deferToParentForm;

  final IconData? errorIcon;
  final Widget Function(BuildContext context, String message)? errorBuilder;

  /// Status rows below the field (sorted by severity).
  final List<FieldMessage> messages;

  final bool showSuccess;
  final String? successText;

  /// Hide the picker for single-country forms (pair with
  /// [initialCountry] / [allowedCountries] to pin the rules).
  final bool showCountryPicker;

  /// Badge icon leading the picker (or the field's suffix without one).
  final bool showIdIcon;

  /// Ghost placeholder for the remaining digits, grouped like the input.
  final bool showTemplateGhost;

  /// Info row under a VALID ID showing what it encodes ("Born 14 May
  /// 2001 · Cairo · Female" / "Citizen").
  final bool showParsedInfo;

  /// Selected country stays visible but can't be changed — KYC re-entry.
  final bool lockCountry;

  /// ISO whitelist — picker options + detection filtering.
  final List<String>? allowedCountries;

  /// ISO codes pinned in a "Preferred" picker group.
  final List<String> preferredCountries;

  /// KYC cross-check: the DOB field's controller (`DateField.dob`). When
  /// the ID embeds a birth date (EG/KW — AE compares year only) and the
  /// linked date is complete, a mismatch fails with "ID doesn't match
  /// the birth date". Live: editing either side re-validates.
  final TextEditingController? mustMatchBirthDate;

  /// Digit order the linked DOB field displays in. Full-date orders only.
  final DateDigitOrder mustMatchBirthDateOrder;

  /// Minimum age from the ID's embedded birth data (EG/KW full date,
  /// AE birth year) — 18+ onboarding gates without trusting a separate
  /// DOB input. No embedded data → no check.
  final int? minAge;

  /// SA: restrict to `[NationalIdKind.citizen]` or `[.resident]` —
  /// citizen-only / iqama-only flows. Countries without a kind ignore it.
  final List<NationalIdKind>? allowedKinds;

  /// Trailing slot.
  final TextFieldSuffix? suffix;

  /// Per-call visual override (wins over the app-wide theme).
  final TextFieldStyle? style;

  /// Box geometry (height / width / fit-to-content / density).
  final TextFieldSizing? sizing;

  @override
  State<NationalIdField> createState() => _NationalIdFieldState();
}

class _NationalIdFieldState extends State<NationalIdField> {
  late CountryCode _country;
  FocusNode? _internalFocus;
  bool _countryTouched = false;

  static final _nonDigit = RegExp(r'\D');

  @override
  void initState() {
    super.initState();
    _country = _sanitize(
      widget.initialCountry ??
          _localeCountry() ??
          CountryCodes.getDefaultCountryCode(),
    );
    if (widget.initialCountry == null) _resolveSimCountry();
    widget.mustMatchBirthDate?.addListener(_onLinkedDob);
    // Prefill (API value): normalize + cap + group — otherwise a stored
    // raw "30105140123456" renders ungrouped until the first keystroke.
    final digits = _digitsOf(
      DateInputFormatter.normalizeDigits(widget.controller.text),
    );
    if (digits.isNotEmpty) {
      final capped = digits.length > _maxLength
          ? digits.substring(0, _maxLength)
          : digits;
      widget.controller.text = PhoneGroupingInputFormatter.group(
        capped,
        groups: _groups,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _notifyId();
      });
    }
  }

  @override
  void didUpdateWidget(covariant NationalIdField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mustMatchBirthDate != widget.mustMatchBirthDate) {
      oldWidget.mustMatchBirthDate?.removeListener(_onLinkedDob);
      widget.mustMatchBirthDate?.addListener(_onLinkedDob);
    }
  }

  @override
  void dispose() {
    widget.mustMatchBirthDate?.removeListener(_onLinkedDob);
    _internalFocus?.dispose();
    super.dispose();
  }

  /// Linked DOB edited — the cross-check outcome may have flipped.
  void _onLinkedDob() {
    if (!mounted) return;
    setState(() {});
    _notifyId();
  }

  /// The linked DOB field's current value, when complete. Digits sliced
  /// per [NationalIdField.mustMatchBirthDateOrder]; impossible dates
  /// (formatter normally prevents them) → null.
  DateTime? _linkedBirthDate() {
    final c = widget.mustMatchBirthDate;
    if (c == null) return null;
    final digits = DateInputFormatter.normalizeDigits(
      c.text,
    ).replaceAll(_nonDigit, '');
    if (digits.length != 8) return null;
    final (d, m, y) = switch (widget.mustMatchBirthDateOrder) {
      DateDigitOrder.dmy => (
        digits.substring(0, 2),
        digits.substring(2, 4),
        digits.substring(4, 8),
      ),
      DateDigitOrder.mdy => (
        digits.substring(2, 4),
        digits.substring(0, 2),
        digits.substring(4, 8),
      ),
      DateDigitOrder.ymd => (
        digits.substring(6, 8),
        digits.substring(4, 6),
        digits.substring(0, 4),
      ),
      _ => ('', '', ''),
    };
    if (y.isEmpty) return null;
    final day = int.parse(d);
    final month = int.parse(m);
    final year = int.parse(y);
    final date = DateTime(year, month, day);
    if (date.month != month || date.day != day) return null;
    return date;
  }

  FocusNode get _focus => widget.focusNode ?? (_internalFocus ??= FocusNode());

  Future<void> _resolveSimCountry() async {
    final iso = await SimCountryService.instance.countryIso();
    if (!mounted || iso == null || _countryTouched) return;
    if (widget.controller.text.trim().isNotEmpty) return;
    final match = CountryCodes.getCountryCodeByCode(iso);
    if (match == CountryCodes.unknownCountryCode ||
        !_isAllowed(match) ||
        match == _country) {
      return;
    }
    setState(() => _country = match);
    _notifyId();
  }

  CountryCode? _localeCountry() {
    final iso = WidgetsBinding.instance.platformDispatcher.locale.countryCode;
    if (iso == null || iso.isEmpty) return null;
    final match = CountryCodes.getCountryCodeByCode(iso.toUpperCase());
    if (match == CountryCodes.unknownCountryCode || !_isAllowed(match)) {
      return null;
    }
    return match;
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

  NationalIdSpec? get _spec => NationalIdSpecs.specFor(_country.code);

  List<int> get _groups => _spec?.groupSizes ?? const [4, 4, 4, 4];

  int get _maxLength => _spec?.length ?? NationalIdSpecs.genericMaxLength;

  String _digitsOf(String text) => text.replaceAll(_nonDigit, '');

  // ── validation ──────────────────────────────────────────────────────

  String? _defaultValidator(String? value) {
    final digits = _digitsOf(value ?? '');
    if (digits.isEmpty) {
      return NationalIdStrings.required;
    }
    final spec = _spec;
    if (spec == null) {
      if (digits.length < NationalIdSpecs.genericMinLength ||
          digits.length > NationalIdSpecs.genericMaxLength) {
        return NationalIdStrings.generic;
      }
      return null;
    }
    if (digits.length != spec.length) {
      return NationalIdStrings.length(spec.length);
    }
    final structural = switch (spec.validateStructure?.call(digits)) {
      null => null,
      NationalIdError.prefix => NationalIdStrings.prefix,
      NationalIdError.checksum => NationalIdStrings.checksum,
      NationalIdError.birthDate => NationalIdStrings.birthdate,
      NationalIdError.governorate => NationalIdStrings.governorate,
      _ => NationalIdStrings.generic,
    };
    if (structural != null) return structural;
    return _crossCheckError(spec.parse?.call(digits));
  }

  /// Post-structure checks against the ID's EMBEDDED data: SA kind
  /// restriction, minimum age, linked-DOB match. All skip silently when
  /// the country's ID doesn't encode the relevant data.
  String? _crossCheckError(NationalIdParsed? parsed) {
    if (parsed == null) return null;
    final kinds = widget.allowedKinds;
    if (kinds != null && parsed.kind != null && !kinds.contains(parsed.kind)) {
      return kinds.contains(NationalIdKind.citizen)
          ? NationalIdStrings.citizensOnly
          : NationalIdStrings.residentsOnly;
    }
    final minAge = widget.minAge;
    if (minAge != null) {
      final now = DateTime.now();
      int? age;
      final dob = parsed.birthDate;
      if (dob != null) {
        final hadBirthday =
            now.month > dob.month ||
            (now.month == dob.month && now.day >= dob.day);
        age = now.year - dob.year - (hadBirthday ? 0 : 1);
      } else if (parsed.birthYear != null) {
        age = now.year - parsed.birthYear!;
      }
      if (age != null && age < minAge) {
        return Tr.t(
          'validator.age_at_least_n_years',
          S.current.validator_age_at_least_n_years(minAge),
        );
      }
    }
    final linked = _linkedBirthDate();
    if (linked != null) {
      final mismatch =
          (parsed.birthDate != null && parsed.birthDate != linked) ||
          (parsed.birthDate == null &&
              parsed.birthYear != null &&
              parsed.birthYear != linked.year);
      if (mismatch) {
        return NationalIdStrings.dobMismatch;
      }
    }
    return null;
  }

  /// Parsed extras for a FULL, structurally valid value; null otherwise.
  NationalIdParsed? _parsedFor(String digits) {
    final spec = _spec;
    if (spec == null || digits.length != spec.length) return null;
    if (spec.validateStructure?.call(digits) != null) return null;
    final parsed = spec.parse?.call(digits);
    return (parsed == null || parsed.isEmpty) ? null : parsed;
  }

  void _notifyId() {
    final cb = widget.onIdChanged;
    if (cb == null) return;
    final digits = _digitsOf(widget.controller.text);
    final validator = widget.validator ?? _defaultValidator;
    final parsed = _parsedFor(digits);
    cb(
      NationalId(
        country: _country,
        digits: digits,
        isValid: validator(widget.controller.text) == null,
        birthDate: parsed?.birthDate,
        birthYear: parsed?.birthYear,
        gender: parsed?.gender,
        governorateEn: parsed?.governorateEn,
        governorateAr: parsed?.governorateAr,
        kind: parsed?.kind,
      ),
    );
  }

  // ── formatters ──────────────────────────────────────────────────────

  /// Eastern-Arabic / Persian digits → ASCII before the digit-only
  /// grouping formatter strips them (1:1 mapping keeps the caret).
  TextEditingValue _normalizeDigits(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final normalized = DateInputFormatter.normalizeDigits(newValue.text);
    if (normalized == newValue.text) return newValue;
    return newValue.copyWith(text: normalized);
  }

  /// Country a smart paste detected — the cap formatter (same edit, next
  /// in the chain) must judge against IT; the picker switch lands a
  /// frame later.
  CountryCode? _pasteTargetCountry;

  /// Smart paste — a pasted ID that FAILS the selected country but FULLY
  /// validates for exactly ONE STRONGLY-validated spec (one with real
  /// structure/checksum rules — length alone is no evidence: any
  /// 10-digit string "passes" JO) switches the picker to it. Only
  /// paste-sized insertions qualify; [NationalIdField.lockCountry] and a
  /// hidden picker disable it.
  TextEditingValue _interceptSmartPaste(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (!widget.showCountryPicker || widget.lockCountry) return newValue;
    final digits = _digitsOf(newValue.text);
    if (digits.length - _digitsOf(oldValue.text).length < 4) return newValue;
    bool fullyValid(NationalIdSpec s) =>
        digits.length == s.length && s.validateStructure?.call(digits) == null;
    final current = _spec;
    if (current != null && fullyValid(current)) return newValue;
    final matches = NationalIdSpecs.supportedIsoCodes
        .where((iso) => iso != _country.code)
        .map(NationalIdSpecs.specFor)
        .whereType<NationalIdSpec>()
        .where((s) => s.validateStructure != null && fullyValid(s))
        .toList();
    if (matches.length != 1) return newValue;
    final match = CountryCodes.getCountryCodeByCode(matches.first.iso);
    if (match == CountryCodes.unknownCountryCode || !_isAllowed(match)) {
      return newValue;
    }
    _pasteTargetCountry = match;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pasteTargetCountry = null;
      if (mounted) _selectCountry(match);
    });
    return newValue;
  }

  TextEditingValue _capLength(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final target = _pasteTargetCountry;
    final max = target != null
        ? (NationalIdSpecs.specFor(target.code)?.length ?? _maxLength)
        : _maxLength;
    final digits = _digitsOf(newValue.text);
    if (digits.length <= max) return newValue;
    final trimmed = digits.substring(0, max);
    return TextEditingValue(
      text: trimmed,
      selection: TextSelection.collapsed(
        offset: newValue.selection.baseOffset.clamp(0, trimmed.length),
      ),
    );
  }

  /// Ghost for the remaining digits, grouped like the input.
  String? _templateGhost(String text) {
    final digits = _digitsOf(text);
    if (digits.isEmpty) return null;
    final spec = _spec;
    if (spec == null || digits.length >= spec.length) return null;
    final template = PhoneGroupingInputFormatter.group(
      '#' * spec.length,
      groups: _groups,
    );
    if (text.length >= template.length) return null;
    return template.substring(text.length);
  }

  // ── parsed info row ─────────────────────────────────────────────────

  FieldMessage? _parsedInfoMessage() {
    if (!widget.showParsedInfo) return null;
    final parsed = _parsedFor(_digitsOf(widget.controller.text));
    if (parsed == null) return null;
    final locale = Intl.getCurrentLocale();
    final parts = <String>[
      if (parsed.birthDate != null)
        NationalIdStrings.born(
          DateFormat.yMMMd(locale).format(parsed.birthDate!),
        )
      else if (parsed.birthYear != null)
        NationalIdStrings.born('${parsed.birthYear}'),
      if (parsed.governorateEn != null)
        (locale.startsWith('ar')
            ? parsed.governorateAr
            : parsed.governorateEn)!,
      if (parsed.gender != null)
        parsed.gender == NationalIdGender.male
            ? NationalIdStrings.male
            : NationalIdStrings.female,
      if (parsed.kind != null)
        parsed.kind == NationalIdKind.citizen
            ? NationalIdStrings.citizen
            : NationalIdStrings.resident,
    ];
    if (parts.isEmpty) return null;
    return FieldMessage.info(parts.join(' · '));
  }

  // ── country picker ──────────────────────────────────────────────────

  void _selectCountry(CountryCode country) {
    _countryTouched = true;
    setState(() => _country = country);
    // Regroup what's typed under the new country's segments (and its cap).
    final digits = _digitsOf(widget.controller.text);
    if (digits.isNotEmpty) {
      final capped = digits.length > _maxLength
          ? digits.substring(0, _maxLength)
          : digits;
      final regrouped = PhoneGroupingInputFormatter.group(
        capped,
        groups: _groups,
      );
      widget.controller.value = TextEditingValue(
        text: regrouped,
        selection: TextSelection.collapsed(offset: regrouped.length),
      );
    }
    _notifyId();
    if (widget.enabled && !widget.readOnly) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focus.requestFocus();
      });
    }
  }

  /// Canonical country row — shared with `CountryCodeDropdownField`.
  /// ISO label (an ID picker keys on the country, not its dial code) and
  /// no dial code in the search haystack.
  DropdownItem<CountryCode> _countryItem(CountryCode c) =>
      CountryCodeDropdownField.itemFor(
        context,
        c,
        labelKind: CountryItemLabel.isoCode,
        triggerIcon: widget.showIdIcon ? Icons.badge_outlined : null,
        searchDialCode: false,
      );

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

  Widget _countryPicker(BuildContext context, {BorderRadius? borderRadius}) {
    final groups = _countryGroups();
    return GlobalDropdown<CountryCode>(
      behavior: const DropdownBehavior(
        isFullScreenWidth: true,
        horizontalPadding: 20,
        enableSearch: true,
        denseTrigger: true,
      ),
      enabled: widget.enabled && !widget.lockCountry,
      style: borderRadius == null
          ? null
          : TextFieldStyle(borderRadius: borderRadius),
      sizing: TextFieldSizing(
        fitWidthToContent: true,
        minWidth: 96,
        maxWidth: 160,
        height: widget.sizing?.height ?? kJoinedPairBoxHeight,
      ),
      groups: groups,
      items: groups != null
          ? const []
          : _selectableCountries.map(_countryItem).toList(),
      selectedValue: _country,
      onChanged: (v) {
        if (v != null) _selectCountry(v);
      },
    );
  }

  // ── build ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final radii = widget.showCountryPicker ? joinedPairRadii(context) : null;
    final baseStyle = widget.style ?? const TextFieldStyle();
    final parsedInfo = _parsedInfoMessage();
    final field = GlobalTextFormField(
      controller: widget.controller,
      label: widget.label,
      identifier: widget.showCountryPicker ? null : widget.identifier,
      hint: widget.hint ?? NationalIdStrings.fieldHint,
      focusNode: _focus,
      style: radii == null
          ? baseStyle
          : baseStyle.copyWith(
              borderRadius: radii.end,
              contentPadding:
                  baseStyle.contentPadding ??
                  EdgeInsetsDirectional.only(
                    start: context.spacing.sm,
                    end: TextFieldDefaults.contentHPad,
                    top: context.spacing.md,
                    bottom: context.spacing.md,
                  ),
            ),
      // Joined to the picker: pin the editor to the same box height the
      // picker is pinned to — its natural height runs a few px taller
      // and the pair's top/bottom edges visibly misalign.
      sizing:
          widget.sizing ??
          (radii != null
              ? const TextFieldSizing(height: kJoinedPairBoxHeight)
              : const TextFieldSizing()),
      messages: [
        ...widget.messages,
        if (parsedInfo != null) parsedInfo,
      ],
      behavior: TextFieldBehavior(
        keyboardType: TextInputType.number,
        textInputAction: widget.textInputAction,
        inputFormatters: [
          TextInputFormatter.withFunction(_normalizeDigits),
          TextInputFormatter.withFunction(_interceptSmartPaste),
          TextInputFormatter.withFunction(_capLength),
          PhoneGroupingInputFormatter(groups: _groups),
        ],
        enabled: widget.enabled,
        readOnly: widget.readOnly,
        autoDetectDirection: false,
      ),
      validation: TextFieldValidation(
        validator: widget.validator ?? _defaultValidator,
        asyncValidator: widget.asyncValidator == null
            ? null
            : (v) => widget.asyncValidator!(_digitsOf(widget.controller.text)),
        asyncDebounce:
            widget.asyncDebounce ?? TextFieldDefaults.asyncValidatorDebounce,
        errorText: widget.errorText,
        mode: widget.validationMode,
        deferToParentForm: widget.deferToParentForm,
        errorIcon: widget.errorIcon,
        errorBuilder: widget.errorBuilder,
        // Country flips change the whole rulebook; so do the cross-check
        // inputs (linked DOB text, age floor, kind restriction).
        revalidateKey: (
          _country.code,
          widget.minAge,
          widget.mustMatchBirthDate?.text,
          widget.allowedKinds?.join(','),
        ),
      ),
      features: TextFieldFeatures(
        showSuccess: widget.showSuccess,
        successText: widget.successText,
        suggestions: widget.showTemplateGhost
            ? SuggestionsConfig(
                showInlineCompletion: true,
                completion: _templateGhost,
              )
            : null,
      ),
      slots: TextFieldSlots(
        suffix:
            widget.suffix ??
            (widget.showIdIcon && !widget.showCountryPicker
                ? const TextFieldSuffix.icon(Icons.badge_outlined)
                : null),
      ),
      callbacks: TextFieldCallbacks(
        onChanged: (value) {
          widget.onChanged?.call(value);
          // Parsed info row appears/disappears with validity.
          setState(() {});
          _notifyId();
        },
        onSubmitted: widget.onSubmitted,
      ),
    );

    if (!widget.showCountryPicker) return field;

    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.identifier != null)
          Padding(
            padding: EdgeInsets.only(bottom: context.spacing.sm),
            child: Text(
              widget.identifier!,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _countryPicker(context, borderRadius: radii?.start),
            Expanded(child: field),
          ],
        ),
      ],
    );
  }
}
