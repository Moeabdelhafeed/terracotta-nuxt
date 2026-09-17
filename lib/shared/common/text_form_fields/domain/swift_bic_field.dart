import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/country_codes.dart';
import '../../../../core/extensions/country_code_extensions.dart';
import '../../../../core/extensions/theme_colors_extension.dart';
import '../../../../core/localization/strings/swift_field_strings.dart';
import '../../../../data/models/common/country_code/country_code.dart';
import '../../../module/text_field/global_text_field.dart';

/// The parsed value a [SwiftBicField] emits on every change — ISO 9362
/// segments plus the sync-validity snapshot.
@immutable
class SwiftBic {
  const SwiftBic({
    required this.raw,
    required this.isValid,
    this.bankCode,
    this.country,
    this.locationCode,
    this.branchCode,
  });

  /// Ungrouped uppercase BIC as typed (`DEUTDEFF500`).
  final String raw;

  /// Result of the field's SYNC validator at emit time.
  final bool isValid;

  /// First 4 letters (`DEUT`).
  final String? bankCode;

  /// Resolved from characters 5–6. Null when unknown.
  final CountryCode? country;

  /// Characters 7–8 (`FF`).
  final String? locationCode;

  /// Optional characters 9–11 (`500`); null on an 8-char BIC.
  final String? branchCode;

  /// No branch, or the explicit `XXX` head-office branch.
  bool get isHeadOffice => branchCode == null || branchCode == 'XXX';

  /// SWIFT test & training BICs end their location code with `0` —
  /// structurally valid, never used for live payments.
  bool get isTestBic => locationCode != null && locationCode!.endsWith('0');

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SwiftBic && other.raw == raw && other.isValid == isValid;

  @override
  int get hashCode => Object.hash(raw, isValid);

  @override
  String toString() => 'SwiftBic($raw, valid: $isValid)';
}

/// SWIFT / BIC input (ISO 9362) — completes the banking set beside
/// [IbanField] and [PaymentCardForm].
///
/// Structure `BBBB CC LL [BBB]` enforced segment-by-segment with a
/// specific message per failure: 4-letter bank code, country code that
/// must EXIST (checked against the country registry), 2-char
/// alphanumeric location, optional 3-char branch (`XXX` = head office).
/// Length is exactly 8 or 11.
///
/// Input UX: auto-uppercase, paste cleanup (spaces/dashes die), display
/// grouped `DEUT DE FF 500`, template ghost for the remaining structure.
///
/// Extras:
///  * [mustMatchIban] — link the sibling [IbanField]'s controller: the
///    IBAN's first two letters are its country; a mismatch fails with
///    "BIC country doesn't match the IBAN", live in both directions.
///  * Valid BIC grows an info row "Germany · Head office"; a TEST BIC
///    (location ending `0`) gets a warning row instead of an error.
///  * [allowedCountries] whitelist, [asyncValidator] for a server BIC
///    directory lookup.
///
/// ```dart
/// SwiftBicField(
///   controller: bic,
///   mustMatchIban: ibanController,
///   onBicChanged: (b) => cubit.setBic(b),
/// )
/// ```
class SwiftBicField extends StatefulWidget {
  const SwiftBicField({
    super.key,
    required this.controller,
    this.onBicChanged,
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
    this.textInputAction = TextInputAction.next,
    this.validationMode = ValidationMode.onFocusLoss,
    this.deferToParentForm = true,
    this.errorIcon,
    this.errorBuilder,
    this.messages = const [],
    this.showSuccess = false,
    this.successText,
    this.showPrefixIcon = true,
    this.showTemplateGhost = true,
    this.showParsedInfo = true,
    this.mustMatchIban,
    this.allowedCountries,
    this.suffix,
    this.style,
    this.sizing,
  });

  final TextEditingController controller;

  /// Parsed [SwiftBic] on every change.
  final ValueChanged<SwiftBic>? onBicChanged;

  /// The BIC as displayed (grouped).
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final String? label;
  final String? identifier;

  /// Default true: shows the `*` marker and rejects empty. False → an
  /// EMPTY value passes (domestic transfers often need no BIC); non-empty
  /// still runs the full structure + country checks.
  final bool required;

  /// Null → localized "Enter SWIFT / BIC".
  final String? hint;

  final bool enabled;
  final bool readOnly;
  final String? errorText;

  /// Sync check override. Null → ISO 9362 segment rules.
  final String? Function(String?)? validator;

  /// Server-side check (BIC directory) on the raw uppercase BIC.
  final Future<String?> Function(String value)? asyncValidator;
  final Duration? asyncDebounce;

  final FocusNode? focusNode;
  final TextInputAction textInputAction;

  /// Defaults to [ValidationMode.onFocusLoss] — structure errors only
  /// fire once entry is complete.
  final ValidationMode validationMode;

  /// Keep `true` inside a `Form`; `false` for standalone fields.
  final bool deferToParentForm;

  final IconData? errorIcon;
  final Widget Function(BuildContext context, String message)? errorBuilder;

  /// Status rows below the field (sorted by severity).
  final List<FieldMessage> messages;

  final bool showSuccess;
  final String? successText;

  final bool showPrefixIcon;

  /// Ghost placeholder for the remaining structure, grouped like the
  /// input (`#### ## ## ###`).
  final bool showTemplateGhost;

  /// Info row under a VALID BIC — "Germany · Head office" — plus a
  /// warning row for test BICs.
  final bool showParsedInfo;

  /// Cross-check: the sibling IBAN field's controller. The IBAN's first
  /// two letters are its country — a complete IBAN prefix that disagrees
  /// with the BIC's country fails validation, live in both directions.
  final TextEditingController? mustMatchIban;

  /// ISO whitelist (`['JO', 'DE']`) — BICs from other countries fail
  /// with "Country not supported".
  final List<String>? allowedCountries;

  /// Trailing slot.
  final TextFieldSuffix? suffix;

  /// Per-call visual override (wins over the app-wide theme).
  final TextFieldStyle? style;

  /// Box geometry (height / width / fit-to-content / density).
  final TextFieldSizing? sizing;

  @override
  State<SwiftBicField> createState() => _SwiftBicFieldState();
}

class _SwiftBicFieldState extends State<SwiftBicField> {
  static final _nonAlnum = RegExp(r'[^A-Za-z0-9]');
  static final _letters = RegExp(r'^[A-Z]+$');
  static final _alnum = RegExp(r'^[A-Z0-9]+$');

  /// Display grouping `4·2·2·3`.
  static const _groups = [4, 2, 2, 3];

  @override
  void initState() {
    super.initState();
    widget.mustMatchIban?.addListener(_onLinkedIban);
    // Prefill (API value): clean + group at mount.
    final raw = _rawOf(widget.controller.text);
    if (raw.isNotEmpty) {
      widget.controller.text = _groupManual(raw);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _notifyBic();
      });
    }
  }

  @override
  void didUpdateWidget(covariant SwiftBicField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mustMatchIban != widget.mustMatchIban) {
      oldWidget.mustMatchIban?.removeListener(_onLinkedIban);
      widget.mustMatchIban?.addListener(_onLinkedIban);
    }
  }

  @override
  void dispose() {
    widget.mustMatchIban?.removeListener(_onLinkedIban);
    super.dispose();
  }

  void _onLinkedIban() {
    if (!mounted) return;
    setState(() {});
    _notifyBic();
  }

  /// Uppercase alphanumerics only, capped at 11.
  String _rawOf(String text) {
    final cleaned = text.replaceAll(_nonAlnum, '').toUpperCase();
    return cleaned.length > 11 ? cleaned.substring(0, 11) : cleaned;
  }

  /// `DEUTDEFF500` → `DEUT DE FF 500`.
  String _groupManual(String raw) {
    final buffer = StringBuffer();
    var index = 0;
    for (final size in _groups) {
      if (index >= raw.length) break;
      if (index > 0) buffer.write(' ');
      final end = (index + size) > raw.length ? raw.length : index + size;
      buffer.write(raw.substring(index, end));
      index = end;
    }
    return buffer.toString();
  }

  /// Clean + uppercase + cap + group in one pass; caret pinned by the
  /// count of significant chars before it.
  TextEditingValue _format(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final before = newValue.selection.baseOffset < 0
        ? newValue.text
        : newValue.text.substring(0, newValue.selection.baseOffset);
    final sigBefore = _rawOf(before).length;
    final raw = _rawOf(newValue.text);
    final grouped = _groupManual(raw);
    // Caret: walk the grouped text until sigBefore significant chars pass.
    var caret = 0;
    var seen = 0;
    while (caret < grouped.length && seen < sigBefore) {
      if (grouped[caret] != ' ') seen++;
      caret++;
    }
    return TextEditingValue(
      text: grouped,
      selection: TextSelection.collapsed(offset: caret),
    );
  }

  /// Ghost for the remaining structure (`## ###`), grouped like the input.
  String? _templateGhost(String text) {
    final raw = _rawOf(text);
    if (raw.isEmpty || raw.length >= 11) return null;
    final template = _groupManual('#' * 11);
    if (text.length >= template.length) return null;
    return template.substring(text.length);
  }

  // ── parsing + validation ────────────────────────────────────────────

  CountryCode? _countryOf(String raw) {
    if (raw.length < 6) return null;
    final iso = raw.substring(4, 6);
    if (!_letters.hasMatch(iso)) return null;
    final match = CountryCodes.getCountryCodeByCode(iso);
    return match == CountryCodes.unknownCountryCode ? null : match;
  }

  /// The linked IBAN's country prefix, when it has one (first two chars
  /// must be letters).
  String? _linkedIbanCountry() {
    final c = widget.mustMatchIban;
    if (c == null) return null;
    final raw = c.text.replaceAll(_nonAlnum, '').toUpperCase();
    if (raw.length < 2) return null;
    final iso = raw.substring(0, 2);
    return _letters.hasMatch(iso) ? iso : null;
  }

  String? _defaultValidator(String? value) {
    final raw = _rawOf(value ?? '');
    if (raw.isEmpty) {
      if (!widget.required) return null;
      return SwiftFieldStrings.required;
    }
    if (raw.length != 8 && raw.length != 11) {
      return SwiftFieldStrings.length;
    }
    if (!_letters.hasMatch(raw.substring(0, 4))) {
      return SwiftFieldStrings.bank;
    }
    final country = _countryOf(raw);
    if (country == null) {
      return SwiftFieldStrings.country;
    }
    final allowed = widget.allowedCountries;
    if (allowed != null &&
        allowed.isNotEmpty &&
        !allowed.any((iso) => iso.toUpperCase() == country.code)) {
      return SwiftFieldStrings.countryNotAllowed;
    }
    if (!_alnum.hasMatch(raw.substring(6, 8))) {
      return SwiftFieldStrings.location;
    }
    if (raw.length == 11 && !_alnum.hasMatch(raw.substring(8, 11))) {
      return SwiftFieldStrings.branch;
    }
    final ibanCountry = _linkedIbanCountry();
    if (ibanCountry != null && ibanCountry != country.code) {
      return SwiftFieldStrings.ibanMismatch;
    }
    return null;
  }

  SwiftBic _currentBic() {
    final raw = _rawOf(widget.controller.text);
    final validator = widget.validator ?? _defaultValidator;
    return SwiftBic(
      raw: raw,
      isValid: validator(widget.controller.text) == null,
      bankCode: raw.length >= 4 ? raw.substring(0, 4) : null,
      country: _countryOf(raw),
      locationCode: raw.length >= 8 ? raw.substring(6, 8) : null,
      branchCode: raw.length == 11 ? raw.substring(8, 11) : null,
    );
  }

  void _notifyBic() {
    widget.onBicChanged?.call(_currentBic());
  }

  // ── info rows ───────────────────────────────────────────────────────

  List<FieldMessage> _parsedRows() {
    if (!widget.showParsedInfo) return const [];
    final bic = _currentBic();
    if (!bic.isValid || bic.country == null) return const [];
    final parts = <String>[
      bic.country!.translatedName,
      if (bic.isHeadOffice) SwiftFieldStrings.headOffice,
    ];
    return [
      FieldMessage.info(
        parts.join(' · '),
        icon: Icons.account_balance_outlined,
      ),
      if (bic.isTestBic) FieldMessage.warning(SwiftFieldStrings.testWarning),
    ];
  }

  // ── build ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return GlobalTextFormField(
      controller: widget.controller,
      label: widget.label,
      identifier: widget.identifier,
      required: widget.required,
      hint: widget.hint ?? SwiftFieldStrings.hint,
      focusNode: widget.focusNode,
      style: widget.style ?? const TextFieldStyle(),
      sizing: widget.sizing ?? const TextFieldSizing(),
      messages: [
        ...widget.messages,
        ..._parsedRows(),
      ],
      behavior: TextFieldBehavior(
        keyboardType: TextInputType.visiblePassword, // letters + digits
        textInputAction: widget.textInputAction,
        inputFormatters: [TextInputFormatter.withFunction(_format)],
        enabled: widget.enabled,
        readOnly: widget.readOnly,
        autoDetectDirection: false,
      ),
      validation: TextFieldValidation(
        validator: widget.validator ?? _defaultValidator,
        asyncValidator: widget.asyncValidator == null
            ? null
            : (v) => widget.asyncValidator!(_rawOf(widget.controller.text)),
        asyncDebounce:
            widget.asyncDebounce ?? TextFieldDefaults.asyncValidatorDebounce,
        errorText: widget.errorText,
        mode: widget.validationMode,
        deferToParentForm: widget.deferToParentForm,
        errorIcon: widget.errorIcon,
        errorBuilder: widget.errorBuilder,
        // The linked IBAN's country and the whitelist reshape the rules.
        revalidateKey: (
          _linkedIbanCountry(),
          widget.allowedCountries?.join(','),
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
        prefixIcon: widget.showPrefixIcon
            ? Padding(
                padding: const EdgeInsetsDirectional.only(start: 12, end: 8),
                child: Icon(
                  Icons.account_balance_outlined,
                  color: context.iconColors.primary,
                ),
              )
            : null,
        suffix: widget.suffix,
      ),
      callbacks: TextFieldCallbacks(
        onChanged: (value) {
          widget.onChanged?.call(value);
          // Parsed rows appear/disappear with validity.
          setState(() {});
          _notifyBic();
        },
        onSubmitted: widget.onSubmitted,
      ),
    );
  }
}
