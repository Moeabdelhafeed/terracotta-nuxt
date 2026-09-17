import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/extensions/theme_colors_extension.dart';
import '../../../../core/localization/strings/misc_field_strings.dart';
import '../../../module/text_field/global_text_field.dart';

/// The parsed value a [PlateNumberField] emits.
@immutable
class PlateNumber {
  const PlateNumber({
    required this.raw,
    required this.countryIso,
    required this.isValid,
  });

  /// As displayed (uppercase, country separator kept).
  final String raw;

  /// Which country's pattern validated it (`generic` when unpinned).
  final String countryIso;

  final bool isValid;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlateNumber &&
          other.raw == raw &&
          other.countryIso == countryIso &&
          other.isValid == isValid;

  @override
  int get hashCode => Object.hash(raw, countryIso, isValid);

  @override
  String toString() => 'PlateNumber($raw [$countryIso], valid: $isValid)';
}

/// Vehicle plate-number input â per-country pattern when pinned via
/// [countryIso] (JO `12-34567`, SA `ABC 1234`, AE `A 12345`), generic
/// alphanumeric fallback otherwise. Uppercases as typed; the charset
/// follows the pinned country (JO is digits+dash only).
///
/// ```dart
/// PlateNumberField(
///   controller: plate,
///   countryIso: 'JO',
///   onPlateChanged: (p) => cubit.setPlate(p),
/// )
/// ```
class PlateNumberField extends StatelessWidget {
  const PlateNumberField({
    super.key,
    required this.controller,
    this.countryIso,
    this.onPlateChanged,
    this.onChanged,
    this.onSubmitted,
    this.label,
    this.identifier,
    this.required = false,
    this.hint,
    this.enabled = true,
    this.readOnly = false,
    this.errorText,
    this.validator,
    this.focusNode,
    this.textInputAction = TextInputAction.next,
    this.validationMode = ValidationMode.onInteraction,
    this.deferToParentForm = true,
    this.messages = const [],
    this.showSuccess = false,
    this.showPrefixIcon = true,
    this.suffix,
    this.style,
    this.sizing,
  });

  /// Per-country rules. `(pattern, example hint, digits-only charset)`.
  static final Map<String, (RegExp, String, bool)> _rules = {
    // Jordan â governorate code + serial, digits with a dash.
    'JO': (RegExp(r'^\d{1,2}-\d{1,5}$'), '12-34567', true),
    // Saudi Arabia â 3 letters + up to 4 digits.
    'SA': (RegExp(r'^[A-Z]{3} ?\d{1,4}$'), 'ABC 1234', false),
    // UAE â optional emirate letter code + up to 5 digits.
    'AE': (RegExp(r'^[A-Z]{0,2} ?\d{1,5}$'), 'A 12345', false),
  };

  static final _generic = RegExp(r'^[A-Z0-9][A-Z0-9 -]{1,9}$');

  final TextEditingController controller;

  /// Pin a country's pattern (`'JO'`). Null â generic alphanumeric.
  final String? countryIso;

  /// Parsed value on every change.
  final ValueChanged<PlateNumber>? onPlateChanged;

  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final String? label;
  final String? identifier;
  final bool required;

  /// Null â the country's example (`12-34567`) or the localized generic.
  final String? hint;

  final bool enabled;
  final bool readOnly;
  final String? errorText;
  final String? Function(String?)? validator;
  final FocusNode? focusNode;
  final TextInputAction textInputAction;
  final ValidationMode validationMode;
  final bool deferToParentForm;
  final List<FieldMessage> messages;
  final bool showSuccess;
  final bool showPrefixIcon;

  /// Trailing slot — e.g. a QR/barcode scan button
  /// (`TextFieldSuffix.icon(Icons.qr_code_scanner, onTap: ...)`).
  final TextFieldSuffix? suffix;
  final TextFieldStyle? style;
  final TextFieldSizing? sizing;

  (RegExp, String?, bool) get _rule {
    final r = countryIso == null ? null : _rules[countryIso!.toUpperCase()];
    if (r == null) return (_generic, null, false);
    return (r.$1, r.$2, r.$3);
  }

  /// Live grouping per country â separators insert themselves:
  /// JO `2312345` â `23-12345` (typed `-` closes a 1-digit code),
  /// SA `ABC1234` â `ABC 1234`, AE `A12345` â `A 12345`.
  TextEditingValue _format(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final iso = countryIso?.toUpperCase();
    final text = newValue.text;

    String out;
    switch (iso) {
      case 'JO':
        final typedDash = text.endsWith('-');
        final dashAt = text.indexOf('-');
        final digits = text.replaceAll(RegExp(r'\D'), '');
        final capped = digits.length > 7 ? digits.substring(0, 7) : digits;
        // A user-placed dash fixes the code length (1 or 2 digits);
        // otherwise the code auto-closes after 2.
        final codeLen = dashAt >= 1 ? dashAt.clamp(1, 2) : 2;
        if (capped.length <= codeLen) {
          out = capped + (typedDash && capped.isNotEmpty ? '-' : '');
        } else {
          out =
              '${capped.substring(0, codeLen)}-${capped.substring(codeLen, (codeLen + 5).clamp(0, capped.length))}';
        }
      case 'SA':
      case 'AE':
        final maxLetters = iso == 'SA' ? 3 : 2;
        final maxDigits = iso == 'SA' ? 4 : 5;
        final cleaned = text.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
        final letterMatch = RegExp(r'^[A-Z]*').firstMatch(cleaned)!.group(0)!;
        final letters = letterMatch.length > maxLetters
            ? letterMatch.substring(0, maxLetters)
            : letterMatch;
        var digits = cleaned
            .substring(letters.length)
            .replaceAll(RegExp(r'\D'), '');
        if (digits.length > maxDigits) digits = digits.substring(0, maxDigits);
        out = digits.isEmpty
            ? letters
            : '$letters${letters.isEmpty ? '' : ' '}$digits';
      default:
        return newValue; // generic â charset filter already ran
    }

    if (out == text) return newValue;
    return TextEditingValue(
      text: out,
      selection: TextSelection.collapsed(offset: out.length),
    );
  }

  String? _defaultValidator(String? value) {
    final text = (value ?? '').trim().toUpperCase();
    if (text.isEmpty) {
      return PlateFieldStrings.required;
    }
    if (!_rule.$1.hasMatch(text)) {
      return PlateFieldStrings.invalid;
    }
    return null;
  }

  void _notify(String value) {
    final cb = onPlateChanged;
    if (cb == null) return;
    final effective = validator ?? _defaultValidator;
    cb(
      PlateNumber(
        raw: value.trim().toUpperCase(),
        countryIso: countryIso?.toUpperCase() ?? 'generic',
        isValid: effective(value) == null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final (pattern, example, digitsOnly) = _rule;
    return GlobalTextFormField(
      controller: controller,
      label: label,
      identifier: identifier,
      required: required,
      hint: hint ?? example ?? PlateFieldStrings.hint,
      focusNode: focusNode,
      style: style ?? const TextFieldStyle(),
      sizing: sizing ?? const TextFieldSizing(),
      messages: messages,
      behavior: TextFieldBehavior(
        keyboardType: digitsOnly
            ? TextInputType.number
            : TextInputType.visiblePassword,
        textInputAction: textInputAction,
        inputFormatters: [
          UpperCaseInputFormatter(),
          FilteringTextInputFormatter.allow(
            digitsOnly ? RegExp(r'[0-9-]') : RegExp(r'[A-Z0-9 -]'),
          ),
          LengthLimitingTextInputFormatter(10),
          TextInputFormatter.withFunction(_format),
        ],
        enabled: enabled,
        readOnly: readOnly,
        autoDetectDirection: false,
      ),
      validation: TextFieldValidation(
        validator: validator ?? _defaultValidator,
        errorText: errorText,
        mode: validationMode,
        deferToParentForm: deferToParentForm,
        revalidateKey: countryIso,
      ),
      features: TextFieldFeatures(showSuccess: showSuccess),
      slots: TextFieldSlots(
        prefixIcon: showPrefixIcon
            ? Padding(
                padding: const EdgeInsetsDirectional.only(start: 12, end: 8),
                child: Icon(
                  Icons.directions_car_outlined,
                  color: context.iconColors.primary,
                ),
              )
            : null,
        suffix: suffix,
      ),
      callbacks: TextFieldCallbacks(
        onChanged: (value) {
          onChanged?.call(value);
          _notify(value);
        },
        onSubmitted: onSubmitted,
      ),
    );
  }
}
