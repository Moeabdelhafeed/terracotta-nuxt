import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/theme_colors_extension.dart';
import '../../../../core/localization/strings/misc_field_strings.dart';
import '../../../../core/localization/strings/stepper_strings.dart';
import '../../../../core/localization/strings/validator_strings.dart';
import '../../../../core/tokens/extensions.dart';
import '../../../../core/utils/unit_converter.dart';
import '../../../module/buttons/global_icon_button.dart';
import '../../../module/drop_down/global_drop_down.dart';
import '../../../module/text_field/global_text_field.dart';
import '../../dropdown_fields/domain/unit_dropdown_field.dart';
import 'joined_pair_radii.dart';
import 'stepper_interactions.dart';
import 'stepper_style.dart';

export '../../../../core/utils/unit_converter.dart' show UnitCategory;

/// Measurement system for the field's initial unit.
enum UnitSystem {
  /// Metric (kg, km, °C…) — the default.
  metric,

  /// US/imperial (lb, mi, °F…).
  imperial,

  /// Pick by the device region — imperial in the US / Liberia / Myanmar,
  /// metric everywhere else.
  auto,
}

/// Ready-made unit sets for [MeasurementField]. The list values are the
/// canonical symbols — what `onMeasurementChanged` emits and what you
/// store/compute with. Arabic DISPLAY comes from [localize] (every
/// preset unit has an Arabic form; standard scientific transliterations
/// for the technical ones). `dunum` (دونم) rides in [area] for land
/// markets. Pass your own list for anything domain-specific — unmapped
/// symbols simply display as-is.
abstract final class MeasurementUnits {
  static const weight = ['kg', 'g', 'mg', 't', 'lb', 'oz'];
  static const length = ['km', 'm', 'cm', 'mm', 'mi', 'ft', 'in', 'yd'];
  static const volume = ['L', 'mL', 'm³', 'gal', 'fl oz'];
  static const area = ['m²', 'km²', 'dunum', 'ha', 'acre', 'ft²'];
  static const speed = ['km/h', 'm/s', 'mph', 'knot'];
  static const duration = ['sec', 'min', 'hr', 'day'];
  static const temperature = ['°C', '°F', 'K'];
  static const pressure = ['bar', 'psi', 'kPa', 'atm'];
  static const energy = ['J', 'kJ', 'cal', 'kcal', 'kWh'];
  static const power = ['W', 'kW', 'hp'];
  static const frequency = ['Hz', 'kHz', 'MHz', 'GHz'];
  static const angle = ['°', 'rad'];
  static const fuelEconomy = ['km/L', 'L/100km', 'mpg'];
  static const dataRate = ['Kbps', 'Mbps', 'Gbps'];
  static const digital = ['KB', 'MB', 'GB', 'TB'];
  static const cooking = ['cup', 'tbsp', 'tsp'];

  /// Arabic display per unit (standard scientific transliterations —
  /// هرتز / واط / جول / بايت). Anything not mapped falls back to the
  /// Latin symbol.
  ///
  /// Deliberately INLINE, not ARB: these are unit-symbol VARIANTS
  /// (كغم is the Arabic convention for the symbol `kg`, not a
  /// translated name), keyed by symbols ARB identifiers can't carry
  /// (`°C`, `m³`, `L/100km`) — an ARB route would need a third slug
  /// scheme just to bridge. The coverage test guarantees every preset
  /// has a mapping.
  static const _ar = {
    // weight
    'kg': 'كغم', 'g': 'غم', 'mg': 'ملغم', 't': 'طن', 'lb': 'رطل', 'oz': 'أونصة',
    // length
    'km': 'كم', 'm': 'م', 'cm': 'سم', 'mm': 'ملم', 'mi': 'ميل', 'ft': 'قدم',
    'in': 'إنش', 'yd': 'ياردة',
    // volume
    'L': 'لتر', 'mL': 'ملل', 'm³': 'م³', 'gal': 'غالون', 'fl oz': 'أونصة سائلة',
    // area
    'm²': 'م²', 'km²': 'كم²', 'dunum': 'دونم', 'ha': 'هكتار',
    'acre': 'فدان', 'ft²': 'قدم²',
    // speed
    'km/h': 'كم/س', 'm/s': 'م/ث', 'mph': 'ميل/س', 'knot': 'عقدة',
    // duration
    'sec': 'ث', 'min': 'د', 'hr': 'س', 'day': 'يوم',
    // temperature
    '°C': '°م', '°F': '°ف', 'K': 'كلفن',
    // pressure
    'bar': 'بار', 'psi': 'رطل/إنش²', 'kPa': 'كيلوباسكال', 'atm': 'ضغط جوي',
    // energy
    'J': 'جول', 'kJ': 'كيلوجول', 'cal': 'سعرة', 'kcal': 'كيلوسعرة',
    'kWh': 'كيلوواط·ساعة',
    // power
    'W': 'واط', 'kW': 'كيلوواط', 'hp': 'حصان',
    // frequency
    'Hz': 'هرتز', 'kHz': 'كيلوهرتز', 'MHz': 'ميغاهرتز', 'GHz': 'غيغاهرتز',
    // angle
    '°': '°', 'rad': 'راديان',
    // fuel economy
    'km/L': 'كم/ل', 'L/100km': 'ل/100كم', 'mpg': 'ميل/غالون',
    // data rate
    'Kbps': 'ك.بت/ث', 'Mbps': 'م.بت/ث', 'Gbps': 'غ.بت/ث',
    // digital storage
    'KB': 'ك.بايت', 'MB': 'م.بايت', 'GB': 'غ.بايت', 'TB': 'ت.بايت',
    // cooking
    'cup': 'كوب', 'tbsp': 'ملعقة كبيرة', 'tsp': 'ملعقة صغيرة',
  };

  /// The unit's display string for the active locale — Arabic name when
  /// known and the locale is Arabic, else the canonical [symbol]. The
  /// stored value is always the symbol; this only changes what's shown.
  static String localize(String symbol) {
    if (!Intl.getCurrentLocale().startsWith('ar')) return symbol;
    return _ar[symbol] ?? symbol;
  }

  /// All preset unit symbols — used by the coverage test to guarantee
  /// every one has an Arabic mapping.
  static const allPresets = [
    ...weight,
    ...length,
    ...volume,
    ...area,
    ...speed,
    ...duration,
    ...temperature,
    ...pressure,
    ...energy,
    ...power,
    ...frequency,
    ...angle,
    ...fuelEconomy,
    ...dataRate,
    ...digital,
    ...cooking,
  ];

  /// The Arabic map (test-visible).
  @visibleForTesting
  static Map<String, String> get arabicMap => _ar;

  /// US/imperial units (everything else counts as metric for the
  /// system-default pick).
  static const imperial = {
    'lb',
    'oz',
    'mi',
    'ft',
    'in',
    'yd',
    'fl oz',
    'gal',
    'acre',
    'ft²',
    'mph',
    '°F',
    'psi',
    'hp',
    'mpg',
  };

  /// The three countries still on imperial ([UnitSystem.auto]).
  static const _imperialCountries = {'US', 'LR', 'MM'};

  /// The initial unit from a set for a measurement [system] — the first
  /// unit in [units] that matches (imperial vs not), else the first unit.
  /// [localeCountry] resolves [UnitSystem.auto].
  static String defaultUnit(
    List<String> units, {
    UnitSystem system = UnitSystem.metric,
    String? localeCountry,
  }) {
    final resolved = system == UnitSystem.auto
        ? (_imperialCountries.contains(localeCountry?.toUpperCase())
              ? UnitSystem.imperial
              : UnitSystem.metric)
        : system;
    final wantImperial = resolved == UnitSystem.imperial;
    for (final u in units) {
      if (imperial.contains(u) == wantImperial) return u;
    }
    return units.first;
  }
}

/// The parsed value a [MeasurementField] emits — value + unit + validity,
/// plus conversion helpers so consumers never re-derive units. Matches
/// the `Money` / `PhoneNumber` / `FullName` pattern.
@immutable
class Measurement {
  const Measurement({
    required this.value,
    required this.unit,
    required this.isValid,
  });

  /// Parsed amount — null while empty or mid-entry.
  final double? value;

  /// Canonical unit symbol (`'kg'`).
  final String unit;

  /// Passes the field's sync validator.
  final bool isValid;

  /// [value] expressed in [targetUnit] (same category), or null when the
  /// value is null or the units don't share a category.
  double? convertTo(String targetUnit) =>
      value == null ? null : UnitConverter.convert(value!, unit, targetUnit);

  /// [value] normalized to the category's base unit (grams, metres,
  /// °C…) — the wire-safe form for storage. Null when value/unit unknown.
  double? get baseValue {
    final cat = UnitConverter.categoryOf(unit);
    if (value == null || cat == null) return null;
    return UnitConverter.convert(value!, unit, UnitConverter.baseUnitOf(cat));
  }

  /// The base unit [baseValue] is expressed in (`'g'`, `'m'`, `'°C'`…).
  String? get baseUnit {
    final cat = UnitConverter.categoryOf(unit);
    return cat == null ? null : UnitConverter.baseUnitOf(cat);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Measurement &&
          other.value == value &&
          other.unit == unit &&
          other.isValid == isValid;

  @override
  int get hashCode => Object.hash(value, unit, isValid);

  @override
  String toString() => 'Measurement($value $unit, valid: $isValid)';
}

/// Number + unit — weight, length, area, volume and more. One unit
/// renders as a static suffix (`kg`); several ([units]) become a picker
/// JOINED to the end of the field (mirror of the phone field's country
/// pair). [onMeasurementChanged] emits a parsed [Measurement] (value /
/// unit / isValid + `convertTo` / `baseValue`). Optionally converts the
/// typed value on unit change ([convertOnUnitChange]) and seeds the unit
/// from the locale's measurement system ([unitSystem]).
class MeasurementField extends StatefulWidget {
  const MeasurementField({
    super.key,
    required this.controller,
    required this.units,
    this.initialUnit,
    this.unitSystem = UnitSystem.metric,
    this.preferredUnits = const [],
    this.convertOnUnitChange = false,
    this.showSteppers = false,
    this.inlineSteppers = false,
    this.stepperIcons = StepperIcons.plusMinus,
    this.step = 1,
    this.onUnitChanged,
    this.onMeasurementChanged,
    this.onChanged,
    this.onSubmitted,
    this.label,
    this.identifier,
    this.hint = '0',
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
    this.successText,
    this.required = false,
    this.min,
    this.max,
    this.boundsForUnit,
    this.enableHaptic = true,
    this.decimals = 2,
    this.style,
    this.sizing,
  }) : assert(units.length > 0, 'Provide at least one unit.'),
       assert(decimals >= 0);

  final TextEditingController controller;

  /// One unit → static suffix; several → joined picker at the end.
  final List<String> units;

  /// Picker seed. Null → [unitSystem]'s default from [units].
  final String? initialUnit;

  /// Initial-unit system when [initialUnit] is null (`auto` = by locale).
  final UnitSystem unitSystem;

  /// Units pinned in a "Common" group at the top of the picker, above an
  /// "All units" group (same pattern as the phone/currency pickers).
  /// Unknown symbols dropped.
  final List<String> preferredUnits;

  /// Convert the typed value when the unit changes (5 kg → 11.02 lb).
  /// Only works between units of the same category ([UnitConverter]);
  /// otherwise the value is kept as-is.
  final bool convertOnUnitChange;

  /// Add − / + stepper buttons flanking the field (scroll-safe siblings)
  /// that adjust the value by [step], clamped to [min] / [max].
  final bool showSteppers;

  /// Render the [showSteppers] buttons INSIDE the value box — − leading, +
  /// trailing, value centred between them (the `QuantityField` inline look).
  /// The unit sits just outside the box (the joined picker for several units,
  /// a small trailing label for one). No-op unless [showSteppers] is `true`.
  ///
  /// Implemented as a `Positioned` overlay on the value box, NOT via the
  /// InputDecorator prefix/suffix slots: an interactive slot inverts its
  /// `_InputDecoratorState.*Icon` semantics rect while the field straddles a
  /// scroll fold and storms "Invisible SemanticsNodes". The overlay rides the
  /// input's own vertical band as an ordinary clip-safe widget, so it stays
  /// scroll-safe. (Very long values in a narrow box can slide under the
  /// buttons — give the field room or fewer [decimals] if that bites.)
  final bool inlineSteppers;

  /// Glyph pair for the steppers — `−`/`+` (default) or `⌄`/`⌃` arrows.
  final StepperIcons stepperIcons;

  /// Stepper increment (respects [decimals]).
  final num step;

  final ValueChanged<String>? onUnitChanged;

  /// Parsed value + active unit on every change (typing or unit switch).
  /// See [Measurement] (`value` / `unit` / `isValid` / `convertTo` /
  /// `baseValue`).
  final ValueChanged<Measurement>? onMeasurementChanged;

  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final String? label;
  final String? identifier;
  final String hint;
  final bool enabled;
  final bool readOnly;
  final String? errorText;

  /// Sync check. Null → [required] + parseability + [min] / [max].
  final String? Function(String?)? validator;

  final FocusNode? focusNode;
  final TextInputAction textInputAction;
  final ValidationMode validationMode;

  /// Keep `true` inside a `Form`; `false` for standalone fields.
  final bool deferToParentForm;

  /// Status rows below the field (sorted by severity).
  final List<FieldMessage> messages;

  /// Show a success row when the field is valid (with optional [successText]).
  final bool showSuccess;
  final String? successText;

  /// Empty input fails validation.
  final bool required;

  /// Inclusive bounds — localized range errors. In the field's current
  /// display unit. For unit-specific bounds (needed when [convertOnUnitChange]
  /// is on, so the range tracks the converted value), use [boundsForUnit].
  final num? min;
  final num? max;

  /// Per-unit bounds, resolved against the active unit symbol. Overrides
  /// [min] / [max] when it returns a non-null side. Mirrors
  /// `AmountField.boundsForCurrency` — e.g.
  /// `boundsForUnit: (u) => u == 'lb' ? (min: 0, max: 220) : (min: 0, max: 100)`
  /// keeps the range correct across a kg↔lb conversion.
  final ({num? min, num? max}) Function(String unit)? boundsForUnit;

  /// Light haptic tick per step, a firmer bump at a bound. Off disables both.
  final bool enableHaptic;

  /// Max fraction digits (0 → integers only).
  final int decimals;

  /// Per-call visual override (wins over the app-wide theme).
  final TextFieldStyle? style;

  /// Box geometry (height / width / fit-to-content / density).
  final TextFieldSizing? sizing;

  @override
  State<MeasurementField> createState() => _MeasurementFieldState();
}

class _MeasurementFieldState extends State<MeasurementField>
    with StepperInteractionMixin<MeasurementField> {
  late String _unit;
  Timer? _repeat;

  // ── StepperInteractionMixin hooks ─────────────────────────────────
  @override
  FocusNode? get providedFocusNode => widget.focusNode;
  @override
  num get stepperStep => widget.step;
  @override
  bool get stepperEnabled =>
      widget.showSteppers && widget.enabled && !widget.readOnly;
  @override
  bool get stepperHaptics => widget.enableHaptic;
  @override
  bool stepperCanStep(num delta) => delta > 0 ? _canIncrement : _canDecrement;
  @override
  void stepperApply(num delta) => _stepBy(delta);
  @override
  String? stepperAnnounceText() => _value == null
      ? null
      : '${_format(_value!)} ${MeasurementUnits.localize(_unit)}';

  /// Effective bounds — per-unit override wins over the flat [min]/[max], so
  /// the range tracks the active unit (correct across conversions).
  num? get _min => widget.boundsForUnit?.call(_unit).min ?? widget.min;
  num? get _max => widget.boundsForUnit?.call(_unit).max ?? widget.max;

  @override
  void dispose() {
    _repeat?.cancel();
    disposeStepperInteractions();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.showSteppers) widget.controller.addListener(_onStepText);
    initStepperInteractions();
    _unit =
        widget.initialUnit ??
        MeasurementUnits.defaultUnit(
          widget.units,
          system: widget.unitSystem,
          localeCountry:
              WidgetsBinding.instance.platformDispatcher.locale.countryCode,
        );
  }

  @override
  void didUpdateWidget(covariant MeasurementField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.units.contains(_unit)) _unit = widget.units.first;
  }

  bool get _hasPicker => widget.units.length > 1;

  double? get _value =>
      double.tryParse(widget.controller.text.replaceAll(',', ''));

  /// Number → clean string at [MeasurementField.decimals] (trailing
  /// zeros + dot trimmed).
  String _format(double v) {
    var s = v.toStringAsFixed(widget.decimals);
    if (s.contains('.')) {
      s = s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
    }
    return s;
  }

  // ─── Steppers (scroll-safe siblings) ──────────────────────────
  bool _lastCanDec = false;
  bool _lastCanInc = false;

  /// Rebuild ONLY when a stepper crosses a bound (enabled ↔ disabled) —
  /// a per-keystroke setState is needless churn.
  void _onStepText() {
    final dec = _canDecrement;
    final inc = _canIncrement;
    if (dec != _lastCanDec || inc != _lastCanInc) {
      _lastCanDec = dec;
      _lastCanInc = inc;
      if (mounted) setState(() {});
    }
  }

  bool get _canDecrement =>
      widget.enabled &&
      !widget.readOnly &&
      (_value == null || _min == null || _value! > _min!);

  bool get _canIncrement =>
      widget.enabled &&
      !widget.readOnly &&
      (_value == null || _max == null || _value! < _max!);

  void _stepBy(num delta) {
    final current = _value ?? (_min ?? 0).toDouble();
    var next = current + delta;
    if (_min != null && next < _min!) next = _min!.toDouble();
    if (_max != null && next > _max!) next = _max!.toDouble();
    final text = _format(next);
    widget.controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    // Programmatic writes don't fire the field's onChanged.
    _emit();
  }

  void _startRepeat(num delta) {
    _repeat?.cancel();
    _repeat = Timer.periodic(const Duration(milliseconds: 120), (_) {
      final can = delta > 0 ? _canIncrement : _canDecrement;
      if (!can) {
        _repeat?.cancel();
        return;
      }
      // Announce suppressed per tick so the screen reader isn't flooded.
      stepInteractive(delta, announce: false);
    });
  }

  void _stopRepeat() => _repeat?.cancel();

  Widget _stepper(IconData icon, bool enabled, num delta) {
    return GestureDetector(
      onLongPressStart: enabled ? (_) => _startRepeat(delta) : null,
      onLongPressEnd: (_) => _stopRepeat(),
      onLongPressCancel: _stopRepeat,
      child: GlobalIconButton(
        onPressed: enabled ? () => stepInteractive(delta) : null,
        tooltip: delta > 0 ? StepperStrings.increase : StepperStrings.decrease,
        enforceMinTouchTarget: false,
        iconData: icon,
        iconSize: 20,
        style: ButtonStateStyle(
          width: 40,
          height: 40,
          foregroundColor: enabled
              ? context.iconColors.primary
              : Theme.of(context).colorScheme.outline,
        ),
      ),
    );
  }

  void _selectUnit(String unit) {
    final previous = _unit;
    setState(() => _unit = unit);
    // Convert the typed value to the new unit when asked (same category).
    if (widget.convertOnUnitChange) {
      final v = _value;
      if (v != null) {
        final converted = UnitConverter.convert(v, previous, unit);
        if (converted != null) {
          final text = _format(converted);
          widget.controller.value = TextEditingValue(
            text: text,
            selection: TextSelection.collapsed(offset: text.length),
          );
        }
      }
    }
    widget.onUnitChanged?.call(unit);
    _emit();
  }

  void _emit() {
    final cb = widget.onMeasurementChanged;
    if (cb == null) return;
    final validator = widget.validator ?? _defaultValidator;
    cb(
      Measurement(
        value: _value,
        unit: _unit,
        isValid: validator(widget.controller.text) == null,
      ),
    );
  }

  String? _defaultValidator(String? value) {
    final text = (value ?? '').replaceAll(',', '');
    if (text.isEmpty) {
      return widget.required ? ValidatorStrings.numberCannotBeEmpty : null;
    }
    final parsed = num.tryParse(text);
    if (parsed == null) return ValidatorStrings.mustBeAValidNumber;
    if (_min != null && parsed < _min!) {
      return ValidatorStrings.mustBeAtLeastN(_min!);
    }
    if (_max != null && parsed > _max!) {
      return ValidatorStrings.mustBeAtMostN(_max!);
    }
    return null;
  }

  // Canonical unit row — shared with the standalone `UnitDropdownField`
  // so both pickers render identically.
  DropdownItem<String> _unitItem(String u) => UnitDropdownField.itemFor(u);

  /// Pinned "Common" group above "All units" when [preferredUnits] is
  /// set; a flat list otherwise.
  List<DropdownGroup<String>>? _unitGroups() {
    final preferred = widget.preferredUnits
        .where(widget.units.contains)
        .toList();
    if (preferred.isEmpty) return null;
    final rest = widget.units.where((u) => !preferred.contains(u)).toList();
    return [
      DropdownGroup(
        label: MeasurementFieldStrings.preferredUnits,
        items: preferred.map(_unitItem).toList(),
      ),
      DropdownGroup(
        label: MeasurementFieldStrings.allUnits,
        items: rest.map(_unitItem).toList(),
      ),
    ];
  }

  /// Width the picker needs for its WIDEST unit label, so the box doesn't
  /// resize as the selection changes. Measured across every localized unit +
  /// an affordance for the chevron and horizontal padding, used as the
  /// picker's `minWidth`. `fitWidthToContent` still guarantees the exact
  /// selected label never clips — this only pins the width to the widest so
  /// it stops jumping per selection.
  double _widestUnitWidth(BuildContext context) {
    final style = context.textTheme.bodyLarge;
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    var widest = 0.0;
    for (final u in widget.units) {
      final painter = TextPainter(
        text: TextSpan(text: MeasurementUnits.localize(u), style: style),
        textDirection: direction,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      if (painter.width > widest) widest = painter.width;
    }
    // ≈ chevron (24) + content padding (24) + a few px of slack so the widest
    // label clears the floor (keeps the box stable, not merely non-clipping).
    return widest + 52;
  }

  /// Fixed width for the OPEN popup when it has groups — wide enough for the
  /// widest of the unit rows AND the group headers (which are UPPERCASED,
  /// bold, letter-spaced, and carry a 3px accent bar + padding, so they run
  /// far wider than the short unit labels). Independent of the narrow trigger.
  double _popupWidth(BuildContext context) {
    var widest = _widestUnitWidth(context);
    final groups = _unitGroups();
    if (groups != null) {
      // Mirror `_buildGroupHeader`: labelSmall / w700 / letterSpacing 1.2,
      // uppercased, inside start-pad + 3px bar + bar-margin + end-pad.
      final style = context.textTheme.labelSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      );
      final scaler = MediaQuery.textScalerOf(context);
      final direction = Directionality.of(context);
      // Header's own Row chrome (start-pad + 3px bar + bar-margin + end-pad)
      // PLUS the popup surface's own horizontal insets + border around the
      // list (≈ 44 — measured against the grouped-dropdown overflow test).
      final chrome =
          context.spacing.md + 3 + context.spacing.sm + context.spacing.md + 44;
      for (final group in groups) {
        final painter = TextPainter(
          text: TextSpan(text: group.label.toUpperCase(), style: style),
          textDirection: direction,
          textScaler: scaler,
          maxLines: 1,
        )..layout();
        final headerWidth = painter.width + chrome;
        if (headerWidth > widest) widest = headerWidth;
      }
    }
    return widest;
  }

  Widget _unitPicker(BuildContext context, BorderRadius borderRadius) {
    final groups = _unitGroups();
    return GlobalDropdown<String>(
      behavior: DropdownBehavior(enableSearch: widget.units.length > 8),
      enabled: widget.enabled,
      style: TextFieldStyle(borderRadius: borderRadius),
      // Dynamic width: hug content, but never narrower than the widest unit —
      // so the box fits the longest label and never resizes on selection.
      // Height pinned to the field's box so the seam lines up.
      sizing: TextFieldSizing(
        fitWidthToContent: true,
        minWidth: _widestUnitWidth(context),
        height: widget.sizing?.height ?? kJoinedPairBoxHeight,
      ),
      // Grouped lists: the OPEN popup gets a FIXED width wide enough for the
      // group headers ("Common units" / "All units"), independent of the
      // narrow trigger. (Can't use content/minAnchor width — the popup body
      // is a lazy scrollable, which can't return intrinsic dimensions.)
      // Placement is `bottomEnd` so the wider popup grows toward the FIELD
      // (start side, where there's room) instead of off the trigger's end
      // edge, where the anchor-based width budget would clamp it. Flat lists
      // keep the default (trigger-matched width, trigger-anchored).
      popupOptions: groups == null
          ? null
          : GlobalPopupOptions(
              placement: GlobalPopupPlacement.bottomEnd,
              width: GlobalPopupWidth.fixed(_popupWidth(context)),
            ),
      groups: groups,
      items: groups != null ? const [] : widget.units.map(_unitItem).toList(),
      selectedValue: _unit,
      onChanged: (u) {
        if (u != null) _selectUnit(u);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final radii = _hasPicker ? joinedPairRadii(context) : null;
    final baseStyle = widget.style ?? const TextFieldStyle();

    // Inline = − / + are OVERLAID inside the value box (leading / trailing);
    // sibling = they flank the whole control in a Row (default, scroll-safe).
    //
    // Inline deliberately does NOT put the steppers in the InputDecorator
    // prefix/suffix slots: an interactive slot inverts its
    // `_InputDecoratorState.*Icon` semantics rect while the field straddles a
    // scroll fold and storms "Invisible SemanticsNodes" every frame. A
    // Positioned overlay rides the input's own vertical band as an ordinary
    // (clip-safe) widget, so it never goes invisible-while-the-field-shows.
    final inline = widget.showSteppers && widget.inlineSteppers;
    final siblingSteppers = widget.showSteppers && !inline;

    // The identifier moves to an external header whenever the control is
    // wider than a bare field (picker and/or steppers) so it spans the whole
    // thing — and, for inline, so the value box carries no internal header
    // and the overlay lines up with the input row.
    final headerOutside = _hasPicker || widget.showSteppers;

    final unitLabel = Text(
      MeasurementUnits.localize(_unit),
      style: context.textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    );

    final field = GlobalTextFormField(
      controller: widget.controller,
      label: widget.label,
      identifier: headerOutside ? null : widget.identifier,
      hint: widget.hint,
      // Owned by the mixin so ↑/↓/PgUp/PgDn are intercepted before the editor.
      focusNode: stepperFocusNode,
      // In the pair THIS box is the start side — squares its end corners.
      style: radii == null
          ? baseStyle
          : baseStyle.copyWith(borderRadius: radii.start),
      sizing: widget.sizing ?? const TextFieldSizing(),
      messages: widget.messages,
      behavior: TextFieldBehavior(
        keyboardType: TextInputType.numberWithOptions(
          decimal: widget.decimals > 0,
        ),
        textInputAction: widget.textInputAction,
        inputFormatters: [
          CurrencyInputFormatter(decimalDigits: widget.decimals),
        ],
        enabled: widget.enabled,
        readOnly: widget.readOnly,
        autoDetectDirection: false,
        // Center the value between the overlaid − / + when inline.
        textAlign: inline ? TextAlign.center : null,
      ),
      validation: TextFieldValidation(
        validator: widget.validator ?? _defaultValidator,
        errorText: widget.errorText,
        mode: widget.validationMode,
        deferToParentForm: widget.deferToParentForm,
        // Include the effective bounds (they shift with the unit) so a unit
        // switch re-validates against the new range.
        revalidateKey: (widget.required, _min, _max, _unit),
      ),
      features: TextFieldFeatures(
        showSuccess: widget.showSuccess,
        successText: widget.successText,
      ),
      slots: TextFieldSlots(
        // Single-unit, non-inline: the unit is a static in-box suffix label.
        // Inline moves the unit to a trailing element (below) so the value
        // box holds only the value + the overlaid steppers.
        suffix: (!inline && !_hasPicker)
            ? TextFieldSuffix.widget(
                Padding(
                  padding: EdgeInsetsDirectional.only(end: context.spacing.md),
                  child: unitLabel,
                ),
              )
            : null,
      ),
      callbacks: TextFieldCallbacks(
        onChanged: (value) {
          widget.onChanged?.call(value);
          _emit();
        },
        onSubmitted: widget.onSubmitted,
      ),
    );

    // Inline: overlay − (leading) / + (trailing) on the value box as ordinary
    // Positioned widgets — NOT InputDecorator slots (see the note above).
    Widget valueBox = field;
    if (inline) {
      valueBox = Stack(
        children: [
          field,
          PositionedDirectional(
            start: 2,
            top: 0,
            bottom: 0,
            child: Center(
              child: _stepper(
                widget.stepperIcons.decrementIcon,
                _canDecrement,
                -widget.step,
              ),
            ),
          ),
          PositionedDirectional(
            end: 2,
            top: 0,
            bottom: 0,
            child: Center(
              child: _stepper(
                widget.stepperIcons.incrementIcon,
                _canIncrement,
                widget.step,
              ),
            ),
          ),
        ],
      );
    }

    // Field, joined to the unit picker when there's more than one unit; inline
    // single-unit shows the unit as a small trailing label.
    Widget core;
    if (_hasPicker) {
      core = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: valueBox),
          _unitPicker(context, radii!.end),
        ],
      );
    } else if (inline) {
      core = Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: valueBox),
          Padding(
            padding: EdgeInsetsDirectional.only(start: context.spacing.sm),
            child: unitLabel,
          ),
        ],
      );
    } else {
      core = valueBox;
    }

    // − / + steppers flank the whole control (scroll-safe siblings).
    if (siblingSteppers) {
      core = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepper(
            widget.stepperIcons.decrementIcon,
            _canDecrement,
            -widget.step,
          ),
          SizedBox(width: context.spacing.xs),
          Expanded(child: core),
          SizedBox(width: context.spacing.xs),
          _stepper(
            widget.stepperIcons.incrementIcon,
            _canIncrement,
            widget.step,
          ),
        ],
      );
    }

    if (!headerOutside || widget.identifier == null) return wrapWheel(core);

    final theme = Theme.of(context);
    return wrapWheel(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
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
          core,
        ],
      ),
    );
  }
}
