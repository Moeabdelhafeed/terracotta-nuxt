import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/constants/currencies.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/localization/strings/misc_field_strings.dart';
import '../../../../core/localization/strings/validator_strings.dart';
import '../../../../core/tokens/extensions.dart';
import '../../../../core/utils/amount_to_words.dart';
import '../../../module/drop_down/global_drop_down.dart';
import '../../../module/text_field/global_text_field.dart';
import '../../dropdown_fields/domain/currency_dropdown_field.dart';
import 'joined_pair_radii.dart';

/// The parsed value an [AmountField] emits on every change.
@immutable
class Money {
  const Money({
    required this.amount,
    required this.currency,
    required this.isValid,
  });

  /// Parsed amount — null while empty or mid-entry (`1.`).
  final double? amount;

  final Currency currency;

  /// Passes the field's sync validator.
  final bool isValid;

  /// Amount in the currency's minor units (JOD 3 decimals → fils;
  /// USD 2 → cents). Null when [amount] is. Wire-safe integer math.
  int? get minorUnits => amount == null
      ? null
      : (amount! * math.pow(10, currency.decimalDigits)).round();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Money &&
          other.amount == amount &&
          other.currency == currency &&
          other.isValid == isValid;

  @override
  int get hashCode => Object.hash(amount, currency, isValid);

  @override
  String toString() => 'Money($amount ${currency.code}, valid: $isValid)';
}

/// Currency amount — thousands-grouped as you type, decimal cap from the
/// currency (JOD 3 · USD 2 · JPY 0, see [Currencies]). Two shapes:
///
/// * **Fixed currency** (default) — [currency] code, symbol rendered as
///   prefix/suffix per the currency's convention.
/// * **Picker** ([showCurrencyPicker]) — a searchable currency dropdown
///   joined to the field (same attached-pair look as the phone field).
///
/// Consume the parsed value via [onAmountChanged] ([Money]: `amount` /
/// `minorUnits` / `currency` / `isValid`) — never parse the string.
class AmountField extends StatefulWidget {
  const AmountField({
    super.key,
    required this.controller,
    this.currency,
    this.showCurrencyPicker = false,
    this.initialCurrency,
    this.selectedCurrency,
    this.onCurrencyChanged,
    this.lockCurrency = false,
    this.allowedCurrencies,
    this.preferredCurrencies = const [],
    this.onAmountChanged,
    this.onChanged,
    this.onSubmitted,
    this.label,
    this.identifier,
    this.hint = '0.00',
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
    this.required = false,
    this.minAmount,
    this.maxAmount,
    this.boundsForCurrency,
    this.showAmountInWords = false,
    this.suffix,
    this.style,
    this.sizing,
  }) : assert(
         currency == null || !showCurrencyPicker,
         'Fixed currency and the picker are mutually exclusive.',
       ),
       assert(
         selectedCurrency == null ||
             (showCurrencyPicker && onCurrencyChanged != null),
         'selectedCurrency (controlled) needs the picker AND '
         'onCurrencyChanged.',
       ),
       assert(
         selectedCurrency == null || initialCurrency == null,
         'Controlled (selectedCurrency) and uncontrolled '
         '(initialCurrency) are mutually exclusive.',
       );

  final TextEditingController controller;

  /// Fixed-currency mode: ISO code (`'JOD'`). Null →
  /// `Currencies.defaultCurrency` (unless the picker is shown).
  final String? currency;

  /// Currency dropdown joined to the field instead of a fixed symbol.
  final bool showCurrencyPicker;

  /// Picker seed for the UNcontrolled mode (ISO code). Null → the device
  /// locale's currency (JO → JOD, DE → EUR via `Currencies.byCountry`),
  /// else the dictionary default.
  final String? initialCurrency;

  /// Controlled currency selection (ISO code) — pair with
  /// [onCurrencyChanged] and own the state (same pattern as the phone
  /// field's `countryCode`).
  final String? selectedCurrency;

  /// Fires when the picker selection changes.
  final ValueChanged<Currency>? onCurrencyChanged;

  /// Selection stays visible but the picker won't open (fixed-currency
  /// checkout that still shows the picker chip).
  final bool lockCurrency;

  /// ISO whitelist for the picker (`['JOD', 'USD']`). Null → the full
  /// dictionary.
  final List<String>? allowedCurrencies;

  /// ISO codes pinned in a "Preferred" group at the top of the picker,
  /// above an "All currencies" group (same pattern as the phone field's
  /// preferred countries). Unknown codes are dropped silently.
  final List<String> preferredCurrencies;

  /// Parsed value on every change — amount, minor units, currency,
  /// validity. See [Money].
  final ValueChanged<Money>? onAmountChanged;

  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final String? label;
  final String? identifier;
  final String hint;
  final bool enabled;
  final bool readOnly;
  final String? errorText;

  /// Sync check. Null → [required] + parseability + [minAmount] /
  /// [maxAmount].
  final String? Function(String?)? validator;

  /// Server-side check. Runs after the sync validator passes.
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

  /// Empty input fails validation.
  final bool required;

  /// Inclusive bounds — localized "must be at least/most N" errors
  /// (numbers grouped per locale). Applied to EVERY currency; when
  /// magnitudes differ per currency (100 USD ≈ 131,000 IQD), use
  /// [boundsForCurrency] instead.
  final double? minAmount;
  final double? maxAmount;

  /// Per-currency bounds for picker mode — wins over [minAmount] /
  /// [maxAmount] when it returns a value for the active currency.
  /// Switching currency re-validates against the new bounds.
  ///
  /// ```dart
  /// boundsForCurrency: (c) => switch (c.code) {
  ///   'JOD' => (min: 1, max: 70000),
  ///   'IQD' => (min: 1000, max: 100000000),
  ///   _ => (min: 1, max: 100000),
  /// },
  /// ```
  final ({double? min, double? max}) Function(Currency currency)?
  boundsForCurrency;

  /// Live tafqit (تفقيط) — the typed amount spelled out as an info row
  /// under the field, locale-aware (`70,000.345` JOD → «سبعون ألفًا
  /// و345/1000 دينار أردني»). Invoices / cheques. See [AmountToWords].
  final bool showAmountInWords;

  /// Trailing slot.
  final TextFieldSuffix? suffix;

  /// Per-call visual override (wins over the app-wide theme).
  final TextFieldStyle? style;

  /// Box geometry (height / width / fit-to-content / density).
  final TextFieldSizing? sizing;

  @override
  State<AmountField> createState() => _AmountFieldState();
}

class _AmountFieldState extends State<AmountField> {
  late Currency _internalCurrency;

  /// Owned only when the caller didn't pass a focusNode — the
  /// currency-pick focus handoff needs SOME node on the amount field.
  FocusNode? _internalFocus;

  @override
  void initState() {
    super.initState();
    // Uncontrolled seed: explicit → device-locale currency → default.
    _internalCurrency =
        widget.initialCurrency != null || widget.currency != null
        ? _resolve(widget.initialCurrency ?? widget.currency)
        : (_localeCurrency() ?? Currencies.defaultCurrency);
    // The words row derives from the live text.
    widget.controller.addListener(_onText);
  }

  void _onText() {
    if (widget.showAmountInWords) setState(() {});
  }

  /// The tafqit row — hidden while empty / unparsable.
  FieldMessage? get _wordsRow {
    if (!widget.showAmountInWords) return null;
    final amount = double.tryParse(_stripped);
    if (amount == null) return null;
    return FieldMessage.info(
      AmountToWords.money(amount, _currency),
      icon: Icons.notes,
    );
  }

  @override
  void didUpdateWidget(covariant AmountField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currency != widget.currency && widget.currency != null) {
      _internalCurrency = _resolve(widget.currency);
    }
    // Controlled currency changed from above — apply the decimal trim
    // the picker path would have applied.
    if (oldWidget.selectedCurrency != widget.selectedCurrency &&
        widget.selectedCurrency != null) {
      _trimForCurrency(_resolve(widget.selectedCurrency));
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onText);
    _internalFocus?.dispose();
    super.dispose();
  }

  FocusNode get _amountFocus =>
      widget.focusNode ?? (_internalFocus ??= FocusNode());

  Currency _resolve(String? code) =>
      (code == null ? null : Currencies.byCode(code)) ??
      Currencies.defaultCurrency;

  bool _isAllowed(Currency c) {
    final allowed = widget.allowedCurrencies;
    if (allowed == null || allowed.isEmpty) return true;
    return allowed.any((code) => code.toUpperCase() == c.code);
  }

  /// The device region's currency (`ar_JO` → JOD), when allowed.
  Currency? _localeCurrency() {
    final iso = WidgetsBinding.instance.platformDispatcher.locale.countryCode;
    if (iso == null || iso.isEmpty) return null;
    final match = Currencies.byCountry(iso);
    if (match == null || !_isAllowed(match)) return null;
    return match;
  }

  Currency get _currency => widget.selectedCurrency != null
      ? _resolve(widget.selectedCurrency)
      : _internalCurrency;

  String get _stripped => widget.controller.text.replaceAll(',', '');

  /// The new currency may allow fewer decimals — trim what's typed.
  void _trimForCurrency(Currency currency) {
    final text = _stripped;
    final dot = text.indexOf('.');
    if (dot < 0) return;
    final maxLen = currency.decimalDigits == 0
        ? dot
        : dot + 1 + currency.decimalDigits;
    if (text.length > maxLen) {
      final trimmed = _regroup(text.substring(0, maxLen));
      widget.controller.value = TextEditingValue(
        text: trimmed,
        selection: TextSelection.collapsed(offset: trimmed.length),
      );
    }
  }

  void _selectCurrency(Currency currency) {
    if (widget.selectedCurrency != null) {
      widget.onCurrencyChanged?.call(currency);
    } else {
      setState(() => _internalCurrency = currency);
      widget.onCurrencyChanged?.call(currency);
    }
    _trimForCurrency(currency);
    _emit();
    // Focus handoff: picking a currency means "now type the amount".
    // Post-frame so the closing overlay can't steal it back.
    if (widget.enabled && !widget.readOnly) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _amountFocus.requestFocus();
      });
    }
  }

  String _regroup(String raw) {
    final dot = raw.indexOf('.');
    final intPart = dot < 0 ? raw : raw.substring(0, dot);
    final rest = dot < 0 ? '' : raw.substring(dot);
    if (intPart.length <= 3) return intPart + rest;
    final buffer = StringBuffer();
    final mod = intPart.length % 3;
    for (var i = 0; i < intPart.length; i++) {
      if (i != 0 && (i - mod) % 3 == 0) buffer.write(',');
      buffer.write(intPart[i]);
    }
    return buffer.toString() + rest;
  }

  /// Active bounds — the per-currency callback wins over the flat
  /// [AmountField.minAmount] / [AmountField.maxAmount].
  ({double? min, double? max}) get _bounds =>
      widget.boundsForCurrency?.call(_currency) ??
      (min: widget.minAmount, max: widget.maxAmount);

  String? _defaultValidator(String? value) {
    final text = (value ?? '').replaceAll(',', '');
    if (text.isEmpty) {
      return widget.required ? ValidatorStrings.numberCannotBeEmpty : null;
    }
    final parsed = double.tryParse(text);
    if (parsed == null) return ValidatorStrings.mustBeAValidNumber;
    final (:min, :max) = _bounds;
    if (min != null && parsed < min) {
      return ValidatorStrings.mustBeAtLeastN(min);
    }
    if (max != null && parsed > max) {
      return ValidatorStrings.mustBeAtMostN(max);
    }
    return null;
  }

  void _emit() {
    final cb = widget.onAmountChanged;
    if (cb == null) return;
    final validator = widget.validator ?? _defaultValidator;
    cb(
      Money(
        amount: double.tryParse(_stripped),
        currency: _currency,
        isValid: validator(widget.controller.text) == null,
      ),
    );
  }

  /// Canonical currency row — shared with the standalone
  /// `CurrencyDropdownField` so both pickers render identically.
  DropdownItem<Currency> _currencyItem(Currency c) =>
      CurrencyDropdownField.itemFor(context, c);

  List<Currency> get _selectable {
    final allowed = widget.allowedCurrencies
        ?.map((c) => c.toUpperCase())
        .toSet();
    return Currencies.all
        .where((c) => allowed == null || allowed.contains(c.code))
        .toList();
  }

  /// Pinned "Preferred" group above "All currencies" when
  /// [AmountField.preferredCurrencies] is set; a flat list otherwise.
  List<DropdownGroup<Currency>>? _currencyGroups(List<Currency> selectable) {
    final preferred = widget.preferredCurrencies
        .map((code) => Currencies.byCode(code))
        .whereType<Currency>()
        .where(selectable.contains)
        .toList();
    if (preferred.isEmpty) return null;
    final rest = selectable.where((c) => !preferred.contains(c)).toList();
    return [
      DropdownGroup(
        label: AmountFieldStrings.preferredCurrencies,
        items: preferred.map(_currencyItem).toList(),
      ),
      DropdownGroup(
        label: AmountFieldStrings.allCurrencies,
        items: rest.map(_currencyItem).toList(),
      ),
    ];
  }

  Widget _currencyPicker(BuildContext context, BorderRadius borderRadius) {
    final selectable = _selectable;
    final groups = _currencyGroups(selectable);
    return GlobalDropdown<Currency>(
      behavior: const DropdownBehavior(
        isFullScreenWidth: true,
        horizontalPadding: 20,
        enableSearch: true,
      ),
      // Locked: the selection stays visible, the picker just won't open.
      enabled: widget.enabled && !widget.lockCurrency,
      style: TextFieldStyle(borderRadius: borderRadius),
      // Pinned to the field's box height so the seam lines up.
      sizing: TextFieldSizing(
        fitWidthToContent: true,
        minWidth: 88,
        maxWidth: 150,
        height: widget.sizing?.height ?? kJoinedPairBoxHeight,
      ),
      groups: groups,
      items: groups != null ? const [] : selectable.map(_currencyItem).toList(),
      selectedValue: _currency,
      onChanged: (c) {
        if (c != null) _selectCurrency(c);
      },
    );
  }

  Widget _symbolAffix() => Padding(
    padding: const EdgeInsetsDirectional.only(start: 12, end: 8),
    child: Text(
      _currency.symbol,
      style: context.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final radii = widget.showCurrencyPicker ? joinedPairRadii(context) : null;
    final baseStyle = widget.style ?? const TextFieldStyle();
    final symbolBefore = _currency.symbolBeforeAmount;

    final field = GlobalTextFormField(
      controller: widget.controller,
      label: widget.label,
      identifier: widget.showCurrencyPicker ? null : widget.identifier,
      hint: widget.hint,
      focusNode: widget.showCurrencyPicker ? _amountFocus : widget.focusNode,
      style: radii == null
          ? baseStyle
          : baseStyle.copyWith(borderRadius: radii.end),
      sizing: widget.sizing ?? const TextFieldSizing(),
      messages: [
        ...widget.messages,
        if (_wordsRow != null) _wordsRow!,
      ],
      behavior: TextFieldBehavior(
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textInputAction: widget.textInputAction,
        inputFormatters: [
          CurrencyInputFormatter(decimalDigits: _currency.decimalDigits),
        ],
        enabled: widget.enabled,
        readOnly: widget.readOnly,
        autoDetectDirection: false,
      ),
      validation: TextFieldValidation(
        validator: widget.validator ?? _defaultValidator,
        asyncValidator: widget.asyncValidator,
        asyncDebounce:
            widget.asyncDebounce ?? TextFieldDefaults.asyncValidatorDebounce,
        errorText: widget.errorText,
        mode: widget.validationMode,
        deferToParentForm: widget.deferToParentForm,
        errorIcon: widget.errorIcon,
        errorBuilder: widget.errorBuilder,
        // Currency (decimals) and bounds can flip at runtime.
        revalidateKey: (
          _currency.code,
          widget.required,
          widget.minAmount,
          widget.maxAmount,
        ),
      ),
      features: TextFieldFeatures(
        showSuccess: widget.showSuccess,
        successText: widget.successText,
      ),
      slots: TextFieldSlots(
        // Fixed mode: symbol on the currency's conventional side.
        prefixIcon: !widget.showCurrencyPicker && symbolBefore
            ? _symbolAffix()
            : null,
        suffix:
            widget.suffix ??
            (!widget.showCurrencyPicker && !symbolBefore
                ? TextFieldSuffix.widget(_symbolAffix())
                : null),
      ),
      callbacks: TextFieldCallbacks(
        onChanged: (value) {
          widget.onChanged?.call(value);
          _emit();
        },
        onSubmitted: widget.onSubmitted,
      ),
    );

    if (!widget.showCurrencyPicker) return field;

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
            _currencyPicker(context, radii!.start),
            Expanded(child: field),
          ],
        ),
      ],
    );
  }
}
