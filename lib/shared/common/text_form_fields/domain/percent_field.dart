import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/extensions/theme_colors_extension.dart';
import '../../../../core/localization/strings/percent_field_strings.dart';
import '../../../module/text_field/global_text_field.dart';

/// The parsed value a [PercentField] emits — the human number (34.5) and
/// the fraction APIs actually want (0.345).
@immutable
class Percent {
  const Percent({required this.value, required this.isValid});

  /// As displayed: `34.5` for "34.5%".
  final double value;

  /// `value / 100` — `0.345`.
  double get fraction => value / 100;

  /// Result of the field's SYNC validator at emit time.
  final bool isValid;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Percent && other.value == value && other.isValid == isValid;

  @override
  int get hashCode => Object.hash(value, isValid);

  @override
  String toString() => 'Percent($value%, valid: $isValid)';
}

/// Percentage input — hard-bounded WHILE TYPING (a value beyond [max]
/// never enters, same philosophy as the date mask), locale-aware `%`
/// affix (`٪` under Arabic), Eastern-Arabic digits + `٫` decimal
/// separator normalized, ↑/↓ steps by [step] clamped to the bounds.
///
/// Defaults: 0–100, up to 2 decimals. Discounts/tips:
/// `allowDecimal: false`. Interest: `max: 25`. Unbounded growth:
/// `max: null`.
///
/// Emits [Percent] (`value` + `fraction`) via [onPercentChanged] — null
/// when empty.
///
/// ```dart
/// PercentField(
///   controller: discount,
///   allowDecimal: false,
///   onPercentChanged: (p) => cubit.setDiscount(p?.fraction),
/// )
/// ```
class PercentField extends StatefulWidget {
  const PercentField({
    super.key,
    required this.controller,
    this.onPercentChanged,
    this.onChanged,
    this.onSubmitted,
    this.label,
    this.identifier,
    this.hint,
    this.enabled = true,
    this.readOnly = false,
    this.errorText,
    this.validator,
    this.focusNode,
    this.textInputAction = TextInputAction.done,
    this.validationMode = ValidationMode.onInteraction,
    this.deferToParentForm = true,
    this.messages = const [],
    this.showSuccess = false,
    this.min = 0,
    this.max = 100,
    this.allowDecimal = true,
    this.decimalPlaces = 2,
    this.step = 1,
    this.showPercentSign = true,
    this.showPrefixIcon = true,
    this.style,
    this.sizing,
  }) : assert(min == null || max == null || min <= max, 'min must be ≤ max'),
       assert(decimalPlaces >= 0 && decimalPlaces <= 6, 'decimalPlaces 0–6'),
       assert(step > 0, 'step must be positive');

  final TextEditingController controller;

  /// Parsed [Percent] on every change — null when the field is empty.
  final ValueChanged<Percent?>? onPercentChanged;

  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final String? label;
  final String? identifier;

  /// Null → localized "Enter percentage".
  final String? hint;

  final bool enabled;
  final bool readOnly;
  final String? errorText;

  /// Sync check override. Null → required + bounds.
  final String? Function(String?)? validator;

  final FocusNode? focusNode;
  final TextInputAction textInputAction;
  final ValidationMode validationMode;

  /// Keep `true` inside a `Form`; `false` for standalone fields.
  final bool deferToParentForm;

  /// Status rows below the field (sorted by severity).
  final List<FieldMessage> messages;

  final bool showSuccess;

  /// Bounds. [max] is enforced AT THE KEYSTROKE (blocked, not flagged);
  /// [min] validates on the normal triggers (you must be able to type
  /// `5` on the way to `50`). Null = unbounded on that side.
  final double? min;
  final double? max;

  /// `false` → integers only (tips, discounts).
  final bool allowDecimal;

  /// Max digits after the separator; extras are blocked at the keystroke.
  final int decimalPlaces;

  /// ↑/↓ increment, clamped to the bounds.
  final double step;

  /// Locale-aware `%` / `٪` suffix.
  final bool showPercentSign;

  final bool showPrefixIcon;

  /// Per-call visual override (wins over the app-wide theme).
  final TextFieldStyle? style;

  /// Box geometry (height / width / fit-to-content / density).
  final TextFieldSizing? sizing;

  @override
  State<PercentField> createState() => _PercentFieldState();
}

class _PercentFieldState extends State<PercentField> {
  FocusNode? _internalFocus;
  bool _externalKeyHandlerAttached = false;

  FocusNode get _focus =>
      widget.focusNode ??
      (_internalFocus ??= FocusNode(onKeyEvent: _onKeyEvent));

  @override
  void initState() {
    super.initState();
    // ↑/↓ stepping on a caller-provided node too (never clobbering a
    // caller's own handler).
    final ext = widget.focusNode;
    if (ext != null && ext.onKeyEvent == null) {
      ext.onKeyEvent = _onKeyEvent;
      _externalKeyHandlerAttached = true;
    }
  }

  @override
  void dispose() {
    if (_externalKeyHandlerAttached) widget.focusNode?.onKeyEvent = null;
    _internalFocus?.dispose();
    super.dispose();
  }

  // ── parsing ─────────────────────────────────────────────────────────

  double? _parse(String text) => double.tryParse(text.trim());

  /// Render a value the way a human would type it: `50`, not `50.0`;
  /// `12.5` capped at [PercentField.decimalPlaces] with trailing zeros
  /// trimmed.
  String _render(double value) {
    var s = value.toStringAsFixed(
      widget.allowDecimal ? widget.decimalPlaces : 0,
    );
    if (s.contains('.')) {
      s = s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
    }
    return s;
  }

  // ── formatter ───────────────────────────────────────────────────────

  static final _asciiJunk = RegExp(r'[^0-9.]');

  /// Normalize (Eastern-Arabic digits, `٫`/`,` decimals) then HARD-BLOCK
  /// anything that can't become a legal value: second separator, extra
  /// decimals, value beyond [PercentField.max].
  TextEditingValue _format(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = DateInputFormatter.normalizeDigits(
      newValue.text,
    ).replaceAll('٫', '.').replaceAll(',', '.');
    text = text.replaceAll(_asciiJunk, '');
    if (!widget.allowDecimal && text.contains('.')) return oldValue;
    final firstDot = text.indexOf('.');
    if (firstDot >= 0) {
      if (text.indexOf('.', firstDot + 1) >= 0) return oldValue;
      final decimals = text.length - firstDot - 1;
      if (decimals > widget.decimalPlaces) return oldValue;
    }
    if (text.isNotEmpty && text != '.') {
      final value = double.tryParse(text);
      if (value == null) return oldValue;
      final max = widget.max;
      if (max != null && value > max) return oldValue;
    }
    if (text == newValue.text) return newValue;
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(
        offset: newValue.selection.baseOffset.clamp(0, text.length),
      ),
    );
  }

  // ── stepping ────────────────────────────────────────────────────────

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent || !widget.enabled || widget.readOnly) {
      return KeyEventResult.ignored;
    }
    final direction = switch (event.logicalKey) {
      LogicalKeyboardKey.arrowUp => 1,
      LogicalKeyboardKey.arrowDown => -1,
      _ => 0,
    };
    if (direction == 0) return KeyEventResult.ignored;
    final current = _parse(widget.controller.text) ?? widget.min ?? 0;
    var next = current + direction * widget.step;
    final min = widget.min;
    final max = widget.max;
    if (min != null && next < min) next = min;
    if (max != null && next > max) next = max;
    final rendered = _render(next);
    widget.controller.value = TextEditingValue(
      text: rendered,
      selection: TextSelection.collapsed(offset: rendered.length),
    );
    _notify();
    setState(() {});
    return KeyEventResult.handled;
  }

  // ── validation + emission ───────────────────────────────────────────

  String? _defaultValidator(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) {
      return PercentFieldStrings.required;
    }
    final parsed = _parse(text);
    if (parsed == null) {
      return PercentFieldStrings.required;
    }
    final min = widget.min;
    final max = widget.max;
    if (min != null && parsed < min) {
      if (max != null) {
        return PercentFieldStrings.range(_render(min), _render(max));
      }
      return PercentFieldStrings.min(_render(min));
    }
    if (max != null && parsed > max) {
      // Typing is blocked past max — reachable via prefilled text.
      return PercentFieldStrings.max(_render(max));
    }
    return null;
  }

  void _notify() {
    final cb = widget.onPercentChanged;
    if (cb == null) return;
    final parsed = _parse(widget.controller.text);
    if (parsed == null) {
      cb(null);
      return;
    }
    final validator = widget.validator ?? _defaultValidator;
    cb(
      Percent(
        value: parsed,
        isValid: validator(widget.controller.text) == null,
      ),
    );
  }

  // ── build ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isArabic =
        (Localizations.maybeLocaleOf(context)?.languageCode ?? 'en') == 'ar';
    return GlobalTextFormField(
      controller: widget.controller,
      label: widget.label,
      identifier: widget.identifier,
      hint: widget.hint ?? PercentFieldStrings.hint,
      focusNode: _focus,
      style: widget.style ?? const TextFieldStyle(),
      sizing: widget.sizing ?? const TextFieldSizing(),
      messages: widget.messages,
      behavior: TextFieldBehavior(
        keyboardType: TextInputType.numberWithOptions(
          decimal: widget.allowDecimal,
        ),
        textInputAction: widget.textInputAction,
        inputFormatters: [TextInputFormatter.withFunction(_format)],
        enabled: widget.enabled,
        readOnly: widget.readOnly,
        autoDetectDirection: false,
      ),
      validation: TextFieldValidation(
        validator: widget.validator ?? _defaultValidator,
        errorText: widget.errorText,
        mode: widget.validationMode,
        deferToParentForm: widget.deferToParentForm,
        // Bounds reshape the rules.
        revalidateKey: (
          widget.min,
          widget.max,
          widget.allowDecimal,
          widget.decimalPlaces,
        ),
      ),
      features: TextFieldFeatures(showSuccess: widget.showSuccess),
      slots: TextFieldSlots(
        prefixIcon: widget.showPrefixIcon
            ? Padding(
                padding: const EdgeInsetsDirectional.only(start: 12, end: 8),
                child: Icon(Icons.percent, color: context.iconColors.primary),
              )
            : null,
        // Arabic locales use the Arabic percent sign ٪ (U+066A).
        suffix: widget.showPercentSign
            ? TextFieldSuffix.widget(
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 12),
                  child: Text(
                    isArabic ? '٪' : '%',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: context.textColors.secondary,
                    ),
                  ),
                ),
              )
            : null,
      ),
      callbacks: TextFieldCallbacks(
        onChanged: (value) {
          widget.onChanged?.call(value);
          _notify();
        },
        onSubmitted: widget.onSubmitted,
      ),
    );
  }
}
