import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/extensions/theme_colors_extension.dart';
import '../../../../core/localization/strings/vin_field_strings.dart';
import '../../../module/text_field/global_text_field.dart';

/// The parsed value a [VinField] emits.
@immutable
class Vin {
  const Vin({required this.raw, required this.isValid, this.modelYear});

  /// Uppercase 17-char VIN as typed.
  final String raw;

  /// Length + charset + ISO 3779 check digit all pass.
  final bool isValid;

  /// Decoded from position 10 â the latest candidate that isn't in the
  /// future (the code cycles every 30 years). Null while invalid.
  final int? modelYear;

  /// World Manufacturer Identifier â first 3 characters.
  String? get wmi => raw.length >= 3 ? raw.substring(0, 3) : null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Vin &&
          other.raw == raw &&
          other.isValid == isValid &&
          other.modelYear == modelYear;

  @override
  int get hashCode => Object.hash(raw, isValid, modelYear);

  @override
  String toString() => 'Vin($raw, valid: $isValid, year: $modelYear)';
}

/// Vehicle Identification Number input â 17 characters, `I`/`O`/`Q`
/// BLOCKED at the keystroke (they don't exist in VINs), and the REAL
/// ISO 3779 check digit verified (transliteration + weights + mod 11 â
/// position 9 must match). A valid VIN grows a "Model year 2003" info
/// row decoded from position 10.
///
/// ```dart
/// VinField(
///   controller: vin,
///   onVinChanged: (v) => cubit.setVin(v),
/// )
/// ```
class VinField extends StatefulWidget {
  const VinField({
    super.key,
    required this.controller,
    this.onVinChanged,
    this.onCompleted,
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
    this.textInputAction = TextInputAction.done,
    this.validationMode = ValidationMode.onFocusLoss,
    this.deferToParentForm = true,
    this.messages = const [],
    this.showSuccess = false,
    this.showPrefixIcon = true,
    this.suffix,
    this.showModelYear = true,
    this.style,
    this.sizing,
  });

  final TextEditingController controller;

  /// Parsed value on every change.
  final ValueChanged<Vin>? onVinChanged;

  /// Fires once when 17 valid characters land.
  final ValueChanged<Vin>? onCompleted;

  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final String? label;
  final String? identifier;
  final bool required;
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

  /// "Model year N" info row under a valid VIN.
  final bool showModelYear;

  final TextFieldStyle? style;
  final TextFieldSizing? sizing;

  // ââ ISO 3779 ââââââââââââââââââââââââââââââââââââââââââââââââââââââââ

  /// Letter â numeric value for the check-digit transliteration.
  static const Map<String, int> _translit = {
    'A': 1,
    'B': 2,
    'C': 3,
    'D': 4,
    'E': 5,
    'F': 6,
    'G': 7,
    'H': 8,
    'J': 1,
    'K': 2,
    'L': 3,
    'M': 4,
    'N': 5,
    'P': 7,
    'R': 9,
    'S': 2,
    'T': 3,
    'U': 4,
    'V': 5,
    'W': 6,
    'X': 7,
    'Y': 8,
    'Z': 9,
  };

  static const List<int> _weights = [
    8,
    7,
    6,
    5,
    4,
    3,
    2,
    10,
    0,
    9,
    8,
    7,
    6,
    5,
    4,
    3,
    2,
  ];

  /// True when position 9 matches the computed check digit.
  static bool checkDigitOk(String vin) {
    if (vin.length != 17) return false;
    var sum = 0;
    for (var i = 0; i < 17; i++) {
      final ch = vin[i];
      final value = int.tryParse(ch) ?? _translit[ch];
      if (value == null) return false;
      sum += value * _weights[i];
    }
    final rem = sum % 11;
    final expected = rem == 10 ? 'X' : '$rem';
    return vin[8] == expected;
  }

  /// Position-10 year code, resolved to the LATEST candidate not in the
  /// future (30-year cycle).
  static int? modelYearOf(String vin) {
    if (vin.length < 10) return null;
    const codes = 'ABCDEFGHJKLMNPRSTVWXY123456789';
    final index = codes.indexOf(vin[9]);
    if (index < 0) return null;
    final ceiling = DateTime.now().year + 1;
    var year = 1980 + index;
    while (year + 30 <= ceiling) {
      year += 30;
    }
    return year;
  }

  @override
  State<VinField> createState() => _VinFieldState();
}

class _VinFieldState extends State<VinField> {
  bool _completedFired = false;

  String? _defaultValidator(String? value) {
    final text = (value ?? '').trim().toUpperCase();
    if (text.isEmpty) {
      return VinFieldStrings.required;
    }
    if (text.length != 17) {
      return VinFieldStrings.length;
    }
    if (!VinField.checkDigitOk(text)) {
      return VinFieldStrings.checksum;
    }
    return null;
  }

  Vin _current() {
    final text = widget.controller.text.trim().toUpperCase();
    final effective = widget.validator ?? _defaultValidator;
    final valid = effective(widget.controller.text) == null;
    return Vin(
      raw: text,
      isValid: valid,
      modelYear: valid ? VinField.modelYearOf(text) : null,
    );
  }

  void _notify() {
    final vin = _current();
    widget.onVinChanged?.call(vin);
    if (vin.isValid && !_completedFired) {
      _completedFired = true;
      widget.onCompleted?.call(vin);
    } else if (!vin.isValid) {
      _completedFired = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final vin = _current();
    return GlobalTextFormField(
      controller: widget.controller,
      label: widget.label,
      identifier: widget.identifier,
      required: widget.required,
      hint: widget.hint ?? VinFieldStrings.hint,
      focusNode: widget.focusNode,
      style: widget.style ?? const TextFieldStyle(),
      sizing: widget.sizing ?? const TextFieldSizing(),
      messages: [
        ...widget.messages,
        if (widget.showModelYear && vin.isValid && vin.modelYear != null)
          FieldMessage.info(
            VinFieldStrings.year(vin.modelYear!),
            icon: Icons.calendar_today_outlined,
          ),
      ],
      behavior: TextFieldBehavior(
        keyboardType: TextInputType.visiblePassword,
        textInputAction: widget.textInputAction,
        inputFormatters: [
          UpperCaseInputFormatter(),
          // I, O, Q don't exist in VINs â blocked at the keystroke.
          FilteringTextInputFormatter.allow(RegExp(r'[A-HJ-NPR-Z0-9]')),
          LengthLimitingTextInputFormatter(17),
        ],
        enabled: widget.enabled,
        readOnly: widget.readOnly,
        autoDetectDirection: false,
      ),
      validation: TextFieldValidation(
        validator: widget.validator ?? _defaultValidator,
        errorText: widget.errorText,
        mode: widget.validationMode,
        deferToParentForm: widget.deferToParentForm,
      ),
      features: TextFieldFeatures(showSuccess: widget.showSuccess),
      slots: TextFieldSlots(
        prefixIcon: widget.showPrefixIcon
            ? Padding(
                padding: const EdgeInsetsDirectional.only(start: 12, end: 8),
                child: Icon(Icons.tag, color: context.iconColors.primary),
              )
            : null,
        suffix: widget.suffix,
      ),
      callbacks: TextFieldCallbacks(
        onChanged: (value) {
          widget.onChanged?.call(value);
          // Model-year row tracks the live text.
          setState(() {});
          _notify();
        },
        onSubmitted: widget.onSubmitted,
      ),
    );
  }
}
