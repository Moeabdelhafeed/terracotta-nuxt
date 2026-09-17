import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/animations/animation_presets.dart';
import '../../../../core/constants/country_codes.dart';
import '../../../../core/extensions/theme_colors_extension.dart';
import '../../../../core/localization/strings/field_strings.dart';
import '../../../../core/localization/strings/phone_field_strings.dart';
import '../../../../core/tokens/extensions.dart';
import '../../../../core/utils/validators/validators.dart';
import '../../../../data/models/common/country_code/country_code.dart';
import '../../../../data/services/sim_country_service.dart';
import '../../../module/drop_down/global_drop_down.dart';
import '../../../module/text_field/global_text_field.dart';
import '../../dropdown_fields/domain/country_code_dropdown_field.dart';
import 'joined_pair_radii.dart';

/// The parsed value a [PhoneNumberField] emits on every change — country,
/// national digits and the wire-ready E.164 string, plus the sync-validity
/// snapshot, so consumers never re-parse strings.
@immutable
class PhoneNumber {
  const PhoneNumber({
    required this.country,
    required this.national,
    required this.e164,
    required this.isValid,
  });

  final CountryCode country;

  /// NSN digits only — no separators, trunk zero stripped (`791234567`).
  final String national;

  /// `'+962791234567'` — dial code + [national].
  final String e164;

  /// Result of the field's SYNC validator at emit time (async checks —
  /// server lookups — are not reflected here).
  final bool isValid;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PhoneNumber &&
          other.country == country &&
          other.national == national &&
          other.e164 == e164 &&
          other.isValid == isValid;

  @override
  int get hashCode => Object.hash(country, national, e164, isValid);

  @override
  String toString() => 'PhoneNumber($e164, valid: $isValid)';
}

/// Phone-number field — a country picker (leading, `GlobalDropdown`) + the
/// NATIONAL number, live-grouped as the user types (`791 234 5678`).
///
/// Value semantics: [controller] holds only the national number (formatted);
/// the dial code lives in the picker. Consume the combined value via
/// [onNumberChanged] (a parsed [PhoneNumber]: country / national / e164 /
/// isValid).
///
/// Country selection is uncontrolled by default (seeded from
/// [initialCountry], [initialFullNumber], SIM, or locale); pass
/// [countryCode] + [onCountryCodeChanged] to own it.
///
/// ```dart
/// PhoneNumberField(
///   controller: phone,
///   initialFullNumber: user.phone,           // '+962791234567' from the API
///   allowedCountries: const ['JO', 'EG'],    // restrict the picker
///   onNumberChanged: (n) => cubit.setPhone(n.e164),
/// )
/// ```
class PhoneNumberField extends StatefulWidget {
  const PhoneNumberField({
    super.key,
    this.fieldKey,
    required this.controller,
    this.countryCode,
    this.onCountryCodeChanged,
    this.initialCountry,
    this.initialFullNumber,
    this.onNumberChanged,
    this.onChanged,
    this.onSubmitted,
    this.label,
    this.identifier,
    this.required = true,
    this.hint,
    this.enabled = true,
    this.readOnly = false,
    this.errorText,
    this.validator,
    this.asyncValidator,
    this.asyncDebounce,
    this.focusNode,
    this.textInputAction = TextInputAction.done,
    this.validationMode = ValidationMode.onInteraction,
    this.deferToParentForm = true,
    this.errorIcon,
    this.errorBuilder,
    this.messages = const [],
    this.showSuccess = false,
    this.successText,
    this.showCountryPicker = true,
    this.showPhoneIcon = false,
    this.showCountryFlag = false,
    this.allowLandline = true,
    this.showTemplateGhost = true,
    this.lockCountry = false,
    this.allowedCountries,
    this.preferredCountries = const [],
    this.groupSizes,
    this.leadingFormatters = const [],
    this.animatePickerEntrance = false,
    this.suffix,
    this.style,
    this.sizing,
    this.autofillHints = const [AutofillHints.telephoneNumber],
  }) : assert(
         (countryCode == null) == (onCountryCodeChanged == null),
         'Pass countryCode AND onCountryCodeChanged together (controlled), '
         'or neither (uncontrolled via initialCountry).',
       ),
       assert(
         initialFullNumber == null ||
             (initialCountry == null && countryCode == null),
         'initialFullNumber already carries the country — don\'t also pass '
         'initialCountry / countryCode.',
       );

  /// Key for the inner number-editor [GlobalTextFormField]. Pass a
  /// `GlobalKey` to keep the editor's element (focus, keyboard
  /// connection) alive when a composite reparents it —
  /// `EmailOrPhoneField`'s face swap.
  final Key? fieldKey;

  final TextEditingController controller;

  /// Controlled country selection — pair with [onCountryCodeChanged].
  final CountryCode? countryCode;
  final ValueChanged<CountryCode>? onCountryCodeChanged;

  /// Seed for the UNcontrolled mode. Null → detection chain:
  /// [initialFullNumber] → SIM country (async — upgrades the seed when it
  /// answers, unless the user already picked a country or typed) → device
  /// locale → `CountryCodes.getDefaultCountryCode()`. SIM detection works
  /// on Android; iOS 16.4+ no longer exposes it (falls through to locale).
  /// Everything respects [allowedCountries].
  final CountryCode? initialCountry;

  /// Prefill from a stored full international number
  /// (`'+962791234567'` / `'0096279…'`) — parsed once at init into the
  /// picker country + the grouped national number. Ignored when it can't
  /// be parsed, the country isn't in [allowedCountries], or [controller]
  /// already has text.
  final String? initialFullNumber;

  /// Parsed value on every change — typing, country switches, SIM
  /// detection. See [PhoneNumber] (`country` / `national` / `e164` /
  /// `isValid`).
  final ValueChanged<PhoneNumber>? onNumberChanged;

  /// The national number as displayed (grouped).
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final String? label;
  final String? identifier;

  /// Default true (a phone field is usually mandatory): shows the `*`
  /// marker and keeps empty-fails validation. `false` → optional: empty
  /// passes, a non-empty value still needs the country's full rules.
  final bool required;

  /// Null → localized default.
  final String? hint;
  final bool enabled;
  final bool readOnly;
  final String? errorText;

  /// Sync check. Null → per-country length rules when the selected
  /// country carries `minLength`/`maxLength` (NSN digits, trunk zero
  /// excluded — Jordan: exactly 9), else `Validators.validatePhoneNumber`
  /// on the FULL number (generic 7–15 digit E.164 bounds).
  final String? Function(String?)? validator;

  /// Server-side check (e.g. "number already registered") on the full
  /// number. Runs after the sync validator passes.
  final Future<String?> Function(String value)? asyncValidator;

  /// Defaults to [TextFieldDefaults.asyncValidatorDebounce].
  final Duration? asyncDebounce;

  final FocusNode? focusNode;
  final TextInputAction textInputAction;
  final ValidationMode validationMode;

  /// Keep `true` inside a `Form`; `false` for standalone fields.
  final bool deferToParentForm;

  /// Icon shown before the error message row.
  final IconData? errorIcon;

  /// Full control over the error row.
  final Widget Function(BuildContext context, String message)? errorBuilder;

  /// Status rows below the field (sorted by severity).
  final List<FieldMessage> messages;

  /// Show a success row when the field is valid (with optional [successText]).
  final bool showSuccess;
  final String? successText;

  /// Hide the picker for national-only forms (the default validator then
  /// sees bare digits).
  final bool showCountryPicker;

  /// Phone icon leading the COUNTRY PICKER (`📞 🇯🇴 +962` — before the
  /// flag; overlay rows unaffected). Without the picker
  /// (`showCountryPicker: false`) it falls back to the number field's
  /// trailing slot (where a custom [suffix] wins).
  final bool showPhoneIcon;

  /// Flag beside the dial code, in the trigger AND the overlay rows.
  ///
  /// Off by default: the studio sells in one country, so a flag on
  /// every row is decoration that costs width the number needs, and the
  /// design draws the dial code alone.
  final bool showCountryFlag;

  /// `false` → mobile numbers only: length rules and the typing cap use
  /// the country's `mobileMinLength`/`mobileMaxLength` (Jordan: exactly 9
  /// — the 8-digit landlines fail with "Mobile number must be 9 digits").
  /// Countries whose mobile and fixed lengths fully overlap (US: both 10)
  /// can't be told apart by length — there the flag changes nothing.
  final bool allowLandline;

  /// Ghost placeholder for the REMAINING digits once typing starts —
  /// `79` under Jordan (mobile-only) shows `79|# ### ###`, grouped like
  /// the input and sized by the active length rules ([allowLandline]
  /// aware, trunk zero granted). Needs the country to carry length data.
  final bool showTemplateGhost;

  /// Selected country stays visible but can't be changed (picker
  /// disabled) — OTP re-entry, region-locked flows.
  final bool lockCountry;

  /// ISO whitelist (`['JO', 'EG']`) — the picker offers ONLY these, and
  /// every country-detection layer (SIM / locale / paste /
  /// [initialFullNumber]) is filtered against it; the first allowed
  /// country becomes the fallback default. Null → all countries.
  final List<String>? allowedCountries;

  /// ISO codes (`['JO', 'SA']`) pinned in a "Preferred" group at the top
  /// of the picker, above an "All countries" group. Unknown codes are
  /// dropped silently.
  final List<String> preferredCountries;

  /// Digit grouping override for the national number. Null → the selected
  /// country's `CountryCode.groupSizes` (NSN-defined, trunk zero absorbed
  /// into the first group), else the generic `[3, 3, 4]`.
  final List<int>? groupSizes;

  /// Formatters run BEFORE the field's own chain (paste intercept → cap →
  /// grouping) — the only spot that still sees raw non-digit input before
  /// grouping strips it. `EmailOrPhoneField` uses this to catch letters
  /// and morph back into an email field.
  final List<TextInputFormatter> leadingFormatters;

  /// Grow the country picker in on mount (width 0 → natural) so the
  /// number editor's width morphs instead of snapping — for fields that
  /// APPEAR mid-interaction (`EmailOrPhoneField`'s email → phone swap).
  /// Skipped under reduce-motion. Leave `false` for fields that are
  /// simply part of a form.
  final bool animatePickerEntrance;

  /// Trailing slot.
  final TextFieldSuffix? suffix;

  /// Per-call visual override (wins over the app-wide theme).
  final TextFieldStyle? style;

  /// Box geometry (height / width / fit-to-content / density).
  final TextFieldSizing? sizing;

  /// Platform autofill. Defaults to `[AutofillHints.telephoneNumber]`;
  /// pass `null` to disable.
  final List<String>? autofillHints;

  @override
  State<PhoneNumberField> createState() => _PhoneNumberFieldState();
}

class _PhoneNumberFieldState extends State<PhoneNumberField> {
  late CountryCode _internalCountry;

  /// Owned only when the caller didn't pass [PhoneNumberField.focusNode] —
  /// the country-pick focus handoff needs SOME node on the number field.
  FocusNode? _internalFocus;

  static final _nonDigit = RegExp(r'\D');

  /// Paste-noise around an international number: spaces, dashes, dots,
  /// parens (`+962 79-123.4567` → `+962791234567`).
  static final _pasteNoise = RegExp(r'[\s\-.()]');

  /// User picked a country (or smart paste switched it) — SIM detection
  /// arriving later must not override an explicit choice.
  bool _countryTouched = false;

  @override
  void initState() {
    super.initState();
    _internalCountry = _sanitize(
      widget.initialCountry ??
          _localeCountry() ??
          CountryCodes.getDefaultCountryCode(),
    );
    final seededFromFull = _applyInitialFullNumber();
    // Detection chain: SIM beats locale, but SIM is async — seed with
    // locale now, upgrade when the channel answers. An explicit seed
    // (initialCountry / initialFullNumber) wins outright.
    if (widget.countryCode == null &&
        widget.initialCountry == null &&
        !seededFromFull) {
      _resolveSimCountry();
    }
    // Mounted over a pre-filled controller (EmailOrPhoneField morphing,
    // form restoration) — emit the initial snapshot so consumers don't
    // wait for the next keystroke. initialFullNumber already notifies.
    if (!seededFromFull && widget.controller.text.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _notifyNumber();
      });
    }
  }

  /// Prefill from [PhoneNumberField.initialFullNumber]. True when applied.
  bool _applyInitialFullNumber() {
    final full = widget.initialFullNumber;
    if (full == null || widget.controller.text.trim().isNotEmpty) {
      return false;
    }
    final parsed = CountryCodes.parseInternational(full);
    if (parsed == null || !_isAllowed(parsed.country)) return false;
    _internalCountry = parsed.country;
    _countryTouched = true;
    final (groups, nsn) = _groupsFor(parsed.country);
    widget.controller.text = PhoneGroupingInputFormatter.group(
      parsed.national,
      groups: groups,
      // Parsed NSN never carries a trunk zero.
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _notifyNumber();
    });
    return true;
  }

  Future<void> _resolveSimCountry() async {
    final iso = await SimCountryService.instance.countryIso();
    if (!mounted || iso == null || _countryTouched) return;
    // User already typing against the seeded country — don't yank the
    // dial code out from under them.
    if (widget.controller.text.trim().isNotEmpty) return;
    final match = CountryCodes.getCountryCodeByCode(iso);
    if (match == CountryCodes.unknownCountryCode ||
        !_isAllowed(match) ||
        match == _internalCountry) {
      return;
    }
    setState(() => _internalCountry = match);
    _notifyNumber();
  }

  @override
  void dispose() {
    _internalFocus?.dispose();
    super.dispose();
  }

  FocusNode get _numberFocus =>
      widget.focusNode ?? (_internalFocus ??= FocusNode());

  /// The device region (`en_JO` → JO), when it's a country we know (and
  /// allow).
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

  /// Every country the picker may offer — the whitelist when set, else the
  /// full list. The `ZZ` unknown sentinel is never offered.
  List<CountryCode> get _selectableCountries => CountryCodes.countryCodes
      .where((c) => c != CountryCodes.unknownCountryCode && _isAllowed(c))
      .toList();

  CountryCode _sanitize(CountryCode c) {
    if (c != CountryCodes.unknownCountryCode && _isAllowed(c)) return c;
    // Whitelisted field: the first allowed country is the natural default.
    final fallback = CountryCodes.getDefaultCountryCode();
    if (_isAllowed(fallback)) return fallback;
    final selectable = _selectableCountries;
    return selectable.isEmpty ? fallback : selectable.first;
  }

  CountryCode get _country => _sanitize(widget.countryCode ?? _internalCountry);

  String get _dial => widget.showCountryPicker ? (_country.dialCode ?? '') : '';

  String _digitsOf(String text) => text.replaceAll(_nonDigit, '');

  /// National digits with the trunk prefix dropped: users type the local
  /// form (`0791 234 567`) but international numbers never carry the leading
  /// zero after the dial code (`+962791234567`, not `+9620…`). Only applies
  /// when a dial code is in play.
  String _internationalDigits(String text) {
    final digits = _digitsOf(text);
    if (!widget.showCountryPicker || digits.isEmpty) return digits;
    return digits.replaceFirst(RegExp('^0+'), '');
  }

  String get _fullNumber =>
      '$_dial${_internationalDigits(widget.controller.text)}';

  /// Grouping for [c]: caller override → country NSN groups → generic.
  /// The bool says whether the groups are NSN-defined (trunk zero gets
  /// absorbed into the first group).
  (List<int>, bool) _groupsFor(CountryCode c) {
    final override = widget.groupSizes;
    if (override != null) return (override, false);
    final country = widget.showCountryPicker ? c.groupSizes : null;
    if (country != null) return (country, true);
    return (const [3, 3, 4], false);
  }

  /// Emit the parsed [PhoneNumber] snapshot to the caller.
  void _notifyNumber() {
    final cb = widget.onNumberChanged;
    if (cb == null) return;
    final text = widget.controller.text;
    final national = _internationalDigits(text);
    final validator = widget.validator ?? _defaultValidator;
    cb(
      PhoneNumber(
        country: _country,
        national: national,
        e164: '$_dial$national',
        isValid: validator(text) == null,
      ),
    );
  }

  void _selectCountry(CountryCode country) {
    _countryTouched = true;
    if (widget.onCountryCodeChanged != null) {
      widget.onCountryCodeChanged!(country);
    } else {
      setState(() => _internalCountry = country);
    }
    // Regroup what's already typed under the new country's pattern (the
    // formatter only fires on the NEXT edit).
    final digits = _digitsOf(widget.controller.text);
    if (digits.isNotEmpty) {
      final (groups, nsn) = _groupsFor(country);
      final regrouped = PhoneGroupingInputFormatter.group(
        digits,
        groups: groups,
        absorbLeadingZero: nsn && digits.startsWith('0'),
      );
      widget.controller.value = TextEditingValue(
        text: regrouped,
        selection: TextSelection.collapsed(offset: regrouped.length),
      );
    }
    _notifyNumber();
    // Focus handoff: picking a country almost always means "now type the
    // number". Post-frame so the closing overlay can't steal it back.
    if (widget.enabled && !widget.readOnly) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _numberFocus.requestFocus();
      });
    }
  }

  /// Smart paste — a FULL international number dropped into the number
  /// field (`+962 79 123 4567` / `00962791234567`) switches the picker to
  /// the detected country and keeps only the national part. Runs BEFORE
  /// the grouping formatter. Only paste-sized insertions qualify, so
  /// typing digits one by one can never hijack the field.
  TextEditingValue _interceptInternationalPaste(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (!widget.showCountryPicker) return newValue;
    if (newValue.text.length - oldValue.text.length < 4) return newValue;
    final cleaned = newValue.text.trim().replaceAll(_pasteNoise, '');
    final normalized = cleaned.startsWith('00')
        ? '+${cleaned.substring(2)}'
        : cleaned;
    if (!normalized.startsWith('+')) return newValue;
    // Longest-dial-code-first match (`+1876` before `+1`).
    final match = CountryCodes.getCountryCodeByPhoneNumber(normalized);
    final dial = match.dialCode;
    if (match == CountryCodes.unknownCountryCode || dial == null) {
      return newValue; // not ours — grouping strips the junk anyway
    }
    final national = _digitsOf(normalized.substring(dial.length));
    if (national.isEmpty) return newValue;
    // Whitelisted field: a paste from a non-allowed country is not ours
    // to accept — leave the input alone (grouping strips the junk).
    if (!_isAllowed(match)) return newValue;
    if (match != _country) {
      // The cap formatter (next in the chain, this same edit) must judge
      // against the DETECTED country — the picker switch lands a frame
      // later.
      _pasteTargetCountry = match;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _pasteTargetCountry = null;
        if (mounted) _selectCountry(match);
      });
    }
    return TextEditingValue(
      text: national,
      selection: TextSelection.collapsed(offset: national.length),
    );
  }

  /// Country whose length rules apply to the edit currently in the
  /// formatter chain (a paste may switch country mid-edit).
  CountryCode? _pasteTargetCountry;

  /// Caps typed digits at the selected country's `maxLength` (NSN), with
  /// one extra digit allowed while the input starts with the trunk zero
  /// (`0791234567` = 10 keystrokes for Jordan's 9-digit NSN).
  TextEditingValue _capToCountryLength(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (!widget.showCountryPicker) return newValue;
    final max = _boundsFor(_pasteTargetCountry ?? _country).max;
    if (max == null) return newValue;
    final digits = _digitsOf(newValue.text);
    final cap = digits.startsWith('0') ? max + 1 : max;
    if (digits.length <= cap) return newValue;
    final trimmed = digits.substring(0, cap);
    return TextEditingValue(
      text: trimmed,
      // Grouping (next formatter) re-derives the caret by digit count and
      // clamps — just keep the offset in range.
      selection: TextSelection.collapsed(
        offset: newValue.selection.baseOffset.clamp(0, trimmed.length),
      ),
    );
  }

  /// Ghost suffix completing the digit template of the selected country —
  /// remaining digits render as `#`, grouped exactly like the input, so
  /// the user sees how much number is left (`791 2` → `## ###` under
  /// Jordan's 9). Target = active max length (+1 while the trunk zero
  /// occupies a slot).
  String? _templateGhost(String text) {
    final digits = _digitsOf(text);
    if (digits.isEmpty) return null; // hint covers the empty state
    final max = _boundsFor(_country).max;
    if (max == null) return null;
    final target = digits.startsWith('0') ? max + 1 : max;
    if (digits.length >= target) return null;
    final (groups, nsn) = _groupsFor(_country);
    final template = PhoneGroupingInputFormatter.group(
      '#' * target,
      groups: groups,
      absorbLeadingZero: nsn && digits.startsWith('0'),
    );
    // Typed text and template share the grouping, so the typed part maps
    // 1:1 onto the template prefix — the ghost is simply the rest.
    if (text.length >= template.length) return null;
    return template.substring(text.length);
  }

  /// Active NSN length bounds for [c] — the mobile-only subset when
  /// landlines are disallowed (general bounds as fallback where a country
  /// has no mobile data).
  ({int? min, int? max}) _boundsFor(CountryCode c) => widget.allowLandline
      ? (min: c.minLength, max: c.maxLength)
      : (
          min: c.mobileMinLength ?? c.minLength,
          max: c.mobileMaxLength ?? c.maxLength,
        );

  /// Mobile-prefix check (landline-off only): NSN must start with one of
  /// the country's `mobilePrefixes`. Partial input is tolerated — `'7'`
  /// still matches `'77'` — so the error appears only once the typed
  /// digits actually diverge.
  String? _mobilePrefixError(String digits) {
    if (widget.allowLandline) return null;
    final prefixes = _country.mobilePrefixes;
    if (prefixes == null || prefixes.isEmpty || digits.isEmpty) return null;
    final matches = prefixes.any(
      (p) => digits.length >= p.length
          ? digits.startsWith(p)
          : p.startsWith(digits),
    );
    if (matches) return null;
    return PhoneFieldStrings.mobilePrefix(prefixes.join(', '));
  }

  String? _defaultValidator(String? value) {
    final digits = _internationalDigits(value ?? '');
    // Optional field: empty passes; a non-empty value still runs the
    // full per-country rules.
    if (digits.isEmpty && !widget.required) return null;
    final (:min, :max) = _boundsFor(_country);
    // Per-country NSN length rules (Jordan: exactly 9) — only when the
    // picker is in play and the country carries length data.
    if (widget.showCountryPicker && (min != null || max != null)) {
      if (digits.isEmpty) return Validators.validatePhoneNumber('');
      // Wrong prefix is a harder failure than wrong length — say it first.
      final prefixError = _mobilePrefixError(digits);
      if (prefixError != null) return prefixError;
      final lo = min ?? max!;
      final hi = max ?? min!;
      if (digits.length < lo || digits.length > hi) {
        final mobileOnly = !widget.allowLandline;
        if (lo == hi) {
          return mobileOnly
              ? PhoneFieldStrings.mobileLengthExact(hi)
              : PhoneFieldStrings.lengthExact(hi);
        }
        return mobileOnly
            ? PhoneFieldStrings.mobileLengthRange(lo, hi)
            : PhoneFieldStrings.lengthRange(lo, hi);
      }
      return null;
    }
    return Validators.validatePhoneNumber(
      digits.isEmpty ? '' : '$_dial$digits',
    );
  }

  /// Canonical country row — shared with `CountryCodeDropdownField` so
  /// the phone picker and the standalone picker render identically.
  DropdownItem<CountryCode> _countryItem(CountryCode c) =>
      CountryCodeDropdownField.itemFor(
        context,
        c,
        triggerIcon: widget.showPhoneIcon ? Icons.phone_outlined : null,
        showFlag: widget.showCountryFlag,
      );

  /// Pinned "Preferred" group above "All countries" when
  /// [PhoneNumberField.preferredCountries] is set; a flat list otherwise.
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

  /// The picker at a FIXED width.
  ///
  /// Every dial code in the catalogue is two to four characters — `+1`
  /// through `+962` — so the widest is known ahead of time and there is
  /// nothing to measure.
  ///
  /// `fitWidthToContent` measured it anyway: it builds an invisible
  /// ghost copy of the field on every layout to size the box from its
  /// glyphs, then clamped the answer to a 64pt floor that four
  /// characters were already under. The measurement ran and its result
  /// was discarded — while making the trigger the most expensive part
  /// of the field to construct, which anything rebuilding this field
  /// pays for (a Hero flight pays twice).
  ///
  /// The box grows with the reader's text scale, so a larger type size
  /// still fits.
  Widget _countryPickerBox(BuildContext context, {BorderRadius? borderRadius}) {
    return SizedBox(
      width: kDialCodeBoxWidth * MediaQuery.textScalerOf(context).scale(1),
      // HEIGHT TOO, not width alone.
      //
      // `_countryPicker` says the size is "imposed from outside, by the
      // `SizedBox` the picker is built into" — and it was not: this box
      // set a width and left the height to whatever the dropdown's own
      // dense trigger came out at, which is shorter than the field
      // beside it. The `Row` aligns to `start`, so the difference
      // showed as a seam down the pair with the picker sitting high.
      //
      // The same number the editor is pinned to, so the two edges are
      // one edge.
      height: _pairHeight,
      child: _countryPicker(context, borderRadius: borderRadius),
    );
  }

  /// The height BOTH halves of the joined pair are pinned to.
  ///
  /// A caller's own wins; otherwise the constant the editor uses when
  /// it is joined to a picker.
  double get _pairHeight => widget.sizing?.height ?? kJoinedPairBoxHeight;

  Widget _countryPicker(BuildContext context, {BorderRadius? borderRadius}) {
    final groups = _countryGroups();
    return GlobalDropdown<CountryCode>(
      behavior: const DropdownBehavior(
        isFullScreenWidth: true,
        horizontalPadding: 20,
        enableSearch: true,
        denseTrigger: true,
        // No chevron: the dial code is three or four
        // characters and the whole box opens the picker, so
        // the arrow was spending width the number needs.
        showChevron: false,
        // The box has a 64pt floor it does not fill, so the
        // slack is split either side of the code rather than
        // all landing after it.
        triggerTextAlign: TextAlign.center,
      ),
      // Locked: the selection stays visible, the picker just won't open.
      enabled: widget.enabled && !widget.lockCountry,
      style: borderRadius == null
          ? null
          : TextFieldStyle(borderRadius: borderRadius),
      // Trigger hugs its content (flag + dial code) — the text field's
      // fit-width sizing, clamped so long dial codes can't crowd the
      // number; pinned to the field's box height so the seam lines up.
      sizing: TextFieldSizing(
        // No `fitWidthToContent` and no width here — the WIDTH is
        // imposed from outside, by the `SizedBox` the picker is built
        // into, and so is the height. See `_countryPickerBox`.
        height: _pairHeight,
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

  /// See [PhoneNumberField.animatePickerEntrance] — grows the picker's
  /// LAYOUT width 0 → natural on mount; the `Expanded` editor beside it
  /// reflows every frame, so the field width genuinely morphs. Anchored
  /// at the seam (end) so the picker appears to slide out of the field.
  Widget _animatedPicker(BuildContext context, Widget picker) {
    if (!widget.animatePickerEntrance ||
        MediaQuery.disableAnimationsOf(context)) {
      return picker;
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppDurations.fast,
      curve: Curves.easeOutCubic,
      child: picker,
      builder: (context, t, child) => ClipRect(
        child: Align(
          alignment: AlignmentDirectional.centerEnd,
          widthFactor: t,
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Attached picker+field pair — shared radii helper (also used by
    // AmountField / MeasurementField).
    final radii = widget.showCountryPicker ? joinedPairRadii(context) : null;
    final baseStyle = widget.style ?? const TextFieldStyle();
    final (groups, groupsAreNsn) = _groupsFor(_country);
    final field = GlobalTextFormField(
      key: widget.fieldKey,
      controller: widget.controller,
      label: widget.label,
      // With the picker beside the field, the identifier moves ABOVE the
      // whole row (rendered below) so it spans picker + field — and the
      // required star rides on THAT header, not the inner hint. Without
      // an identifier there is no header, so the hint carries the star.
      identifier: widget.showCountryPicker ? null : widget.identifier,
      required:
          widget.required &&
          (!widget.showCountryPicker || widget.identifier == null),
      hint: widget.hint ?? FieldStrings.phoneHint,
      focusNode: _numberFocus,
      // Joined to the picker: pull the text toward the shared seam with a
      // tighter start inset (vertical 16 = the default box height; end
      // keeps the standard 12). Caller contentPadding wins.
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
      messages: widget.messages,
      behavior: TextFieldBehavior(
        keyboardType: TextInputType.phone,
        textInputAction: widget.textInputAction,
        inputFormatters: [
          ...widget.leadingFormatters,
          TextInputFormatter.withFunction(_interceptInternationalPaste),
          // Live per-country digit cap — separate from the grouping
          // formatter so a paste that SWITCHES country caps against the
          // detected country, not the one selected before the paste.
          TextInputFormatter.withFunction(_capToCountryLength),
          PhoneGroupingInputFormatter(
            groups: groups,
            groupsAreNsn: groupsAreNsn,
          ),
        ],
        enabled: widget.enabled,
        readOnly: widget.readOnly,
        autoDetectDirection: false,
        // A phone number is LTR in every language. Turning DETECTION
        // off is not the same as pinning the direction: without this the
        // editor inherits the locale's, and in Arabic a grouped number
        // laid out right-to-left renders its groups in reverse — typing
        // 0798344241 showed as "4241 834 079", which is a different
        // number to anyone reading it back.
        textDirection: TextDirection.ltr,
        // The BOX still belongs to the reading direction, so the number
        // sits where the design puts it — against the start edge, the
        // right in Arabic — while its digits run the other way.
        textAlign: Directionality.of(context) == TextDirection.rtl
            ? TextAlign.right
            : TextAlign.left,
        autofillHints: widget.autofillHints,
      ),
      validation: TextFieldValidation(
        validator: widget.validator ?? _defaultValidator,
        asyncValidator: widget.asyncValidator == null
            ? null
            : (v) => widget.asyncValidator!(_fullNumber),
        asyncDebounce:
            widget.asyncDebounce ?? TextFieldDefaults.asyncValidatorDebounce,
        errorText: widget.errorText,
        mode: widget.validationMode,
        deferToParentForm: widget.deferToParentForm,
        errorIcon: widget.errorIcon,
        errorBuilder: widget.errorBuilder,
        // Length rules depend on both — flipping either re-checks a field
        // that's already showing an error (or was interacted with).
        revalidateKey: (widget.allowLandline, _country.code),
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
        // With the picker shown the phone icon lives THERE (leading) —
        // the number field's trailing slot stays free for the caller.
        suffix:
            widget.suffix ??
            (widget.showPhoneIcon && !widget.showCountryPicker
                ? const TextFieldSuffix.icon(Icons.phone_outlined)
                : null),
      ),
      callbacks: TextFieldCallbacks(
        onChanged: (value) {
          widget.onChanged?.call(value);
          _notifyNumber();
        },
        onSubmitted: widget.onSubmitted,
      ),
    );

    if (!widget.showCountryPicker) return field;

    // Picker sits BESIDE the field (own bordered box), not inside a slot.
    // Top-aligned: the field grows downward (errors / messages) without
    // dragging the picker. The identifier spans the whole row, styled
    // exactly like the module's own header.
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.identifier != null)
          Padding(
            padding: EdgeInsets.only(bottom: context.spacing.sm),
            child: Text.rich(
              TextSpan(
                text: widget.identifier,
                children: [
                  if (widget.required)
                    TextSpan(
                      text: ' *',
                      style: TextStyle(color: context.statusColors.error),
                    ),
                ],
              ),
              // The module's own constants, NOT a copy of its numbers.
              // This row exists because the picker sits beside the field
              // and the header has to span both; styling it by hand is
              // what let it drift to a different size and weight from
              // every other field's label on the same form.
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: TextFieldDefaults.identifierWeight,
                fontSize: TextFieldDefaults.identifierFontSize,
              ),
            ),
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Attached pair: facing corners squared, no gap — one input.
            _animatedPicker(
              context,
              _countryPickerBox(context, borderRadius: radii?.start),
            ),
            Expanded(child: field),
          ],
        ),
      ],
    );
  }
}
