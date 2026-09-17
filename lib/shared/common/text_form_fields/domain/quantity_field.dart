import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/extensions/theme_colors_extension.dart';
import '../../../../core/localization/strings/stepper_strings.dart';
import '../../../../core/tokens/extensions.dart';
import '../../../module/buttons/global_icon_button.dart';
import '../../../module/text_field/global_text_field.dart';
import 'number_field.dart';
import 'stepper_interactions.dart';
import 'stepper_style.dart';

export 'stepper_style.dart';

/// Quantity input — centered integer with − / + stepper buttons that
/// clamp to [min] / [max] (buttons disable at the bounds) and repeat on
/// long-press. Type directly or step; [onQuantityChanged] emits the
/// parsed value either way.
///
/// By default the steppers are SIBLINGS of the field (a Row) — the
/// scroll-safe layout: interactive widgets inside `InputDecorator`'s
/// prefix/suffix slots throw "Invisible SemanticsNodes" when clipped
/// off-screen in a non-culling scroll. Set [inlineSteppers] for the
/// compact "buttons inside the box" look, but only inside a lazy
/// `ListView` (which disposes off-screen items) — see the text_field
/// CLAUDE.md caller-gotcha.
class QuantityField extends StatefulWidget {
  const QuantityField({
    super.key,
    required this.controller,
    this.onQuantityChanged,
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
    this.initialQuantity,
    this.min = 1,
    this.max,
    this.step = 1,
    this.inlineSteppers = false,
    this.stepperIcons = StepperIcons.plusMinus,
    this.enableHaptic = true,
    this.style,
    this.sizing,
  }) : assert(step > 0),
       assert(max == null || min == null || min <= max);

  final TextEditingController controller;

  /// Parsed quantity on every change (typing or stepping) — null while
  /// the field is empty.
  final ValueChanged<int?>? onQuantityChanged;

  final void Function(String)? onSubmitted;
  final String? label;
  final String? identifier;
  final String? hint;
  final bool enabled;
  final bool readOnly;
  final String? errorText;

  /// Sync check. Null → required + [min] / [max] range.
  final String? Function(String?)? validator;

  final FocusNode? focusNode;
  final TextInputAction textInputAction;
  final ValidationMode validationMode;

  /// Keep `true` inside a `Form`; `false` for standalone fields.
  final bool deferToParentForm;

  /// Status rows below the field (sorted by severity).
  final List<FieldMessage> messages;

  /// Seeds an EMPTY controller once at init.
  final int? initialQuantity;

  /// Inclusive bounds. [min] null → unbounded below.
  final int? min;
  final int? max;

  /// Stepper increment.
  final int step;

  /// Render the steppers INSIDE the field box (− leading, + trailing, value
  /// centred) for the compact look. Implemented as a `Positioned` overlay on
  /// the value box, NOT the InputDecorator prefix/suffix slots — an
  /// interactive slot inverts its semantics rect while the field straddles a
  /// scroll fold and storms "Invisible SemanticsNodes"; the overlay stays
  /// scroll-safe. Default `false` = sibling Row. (A very narrow fit-width box
  /// can let a long value slide under the buttons — set a `minWidth`.)
  final bool inlineSteppers;

  /// Glyph pair for the steppers — `−`/`+` (default) or `⌄`/`⌃` arrows.
  final StepperIcons stepperIcons;

  /// Light haptic tick per step, a firmer bump at a bound. Off disables both.
  final bool enableHaptic;

  /// Per-call visual override (wins over the app-wide theme).
  final TextFieldStyle? style;

  /// Box geometry — steppers pair well with a fixed width.
  final TextFieldSizing? sizing;

  @override
  State<QuantityField> createState() => _QuantityFieldState();
}

class _QuantityFieldState extends State<QuantityField>
    with StepperInteractionMixin<QuantityField> {
  Timer? _repeat;

  // ── StepperInteractionMixin hooks ─────────────────────────────────
  @override
  FocusNode? get providedFocusNode => widget.focusNode;
  @override
  num get stepperStep => widget.step;
  @override
  bool get stepperEnabled => widget.enabled && !widget.readOnly;
  @override
  bool get stepperHaptics => widget.enableHaptic;
  @override
  bool stepperCanStep(num delta) => delta > 0 ? _canIncrement : _canDecrement;
  @override
  void stepperApply(num delta) => _stepBy(delta.toInt());
  @override
  String? stepperAnnounceText() => _value?.toString();

  @override
  void initState() {
    super.initState();
    if (widget.controller.text.isEmpty && widget.initialQuantity != null) {
      widget.controller.text = '${widget.initialQuantity}';
    }
    // Bounds-driven button state follows the live text.
    widget.controller.addListener(_onText);
    initStepperInteractions();
  }

  @override
  void didUpdateWidget(covariant QuantityField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onText);
      widget.controller.addListener(_onText);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onText);
    _repeat?.cancel();
    disposeStepperInteractions();
    super.dispose();
  }

  void _onText() => setState(() {});

  int? get _value => int.tryParse(widget.controller.text);

  bool get _canDecrement =>
      widget.enabled &&
      !widget.readOnly &&
      (_value == null || widget.min == null || _value! > widget.min!);

  bool get _canIncrement =>
      widget.enabled &&
      !widget.readOnly &&
      (_value == null || widget.max == null || _value! < widget.max!);

  void _stepBy(int delta) {
    final current = _value ?? (widget.min ?? 0) - delta;
    var next = current + delta;
    if (widget.min != null && next < widget.min!) next = widget.min!;
    if (widget.max != null && next > widget.max!) next = widget.max!;
    widget.controller.value = TextEditingValue(
      text: '$next',
      selection: TextSelection.collapsed(offset: '$next'.length),
    );
    // Programmatic writes don't fire the field's onChanged.
    widget.onQuantityChanged?.call(next);
  }

  /// Long-press auto-repeat, same cadence both directions. Announce is
  /// suppressed per tick so the screen reader isn't flooded.
  void _startRepeat(int delta) {
    _repeat?.cancel();
    _repeat = Timer.periodic(const Duration(milliseconds: 120), (_) {
      final can = delta > 0 ? _canIncrement : _canDecrement;
      if (!can) {
        _repeat?.cancel();
        return;
      }
      stepInteractive(delta, announce: false);
    });
  }

  void _stopRepeat() => _repeat?.cancel();

  Widget _stepper(IconData icon, bool enabled, int delta) {
    // Mirrors the module's compact suffix-button recipe.
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

  /// The centered value field — no stepper slots; steppers attach around or
  /// over it depending on the mode.
  NumberField _numberField() => NumberField(
    controller: widget.controller,
    onValueChanged: (v) => widget.onQuantityChanged?.call(v?.toInt()),
    onSubmitted: widget.onSubmitted,
    label: widget.label,
    // Header is pulled out to an external row (via `_withHeader`) so the
    // inline overlay lines up with the input, not the input + header.
    hint: widget.hint ?? '${widget.min ?? 0}',
    enabled: widget.enabled,
    readOnly: widget.readOnly,
    errorText: widget.errorText,
    validator: widget.validator,
    // Owned by the mixin so ↑/↓/PgUp/PgDn are intercepted before the
    // text editor.
    focusNode: stepperFocusNode,
    textInputAction: widget.textInputAction,
    validationMode: widget.validationMode,
    deferToParentForm: widget.deferToParentForm,
    messages: widget.messages,
    required: true,
    min: widget.min,
    max: widget.max,
    textAlign: TextAlign.center,
    style: widget.style,
    sizing: widget.sizing,
  );

  /// External identifier header above [child] (shared by both modes so the
  /// header always spans the whole control).
  Widget _withHeader(BuildContext context, Widget child) {
    if (widget.identifier == null) return child;
    final theme = Theme.of(context);
    return Column(
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
        child,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Inline: − (leading) / + (trailing) OVERLAID inside the value box as
    // ordinary Positioned widgets — NOT InputDecorator prefix/suffix slots.
    // An interactive slot inverts its `_InputDecoratorState.*Icon` semantics
    // rect while the field straddles a scroll fold and storms "Invisible
    // SemanticsNodes" every frame; a Positioned overlay rides the input's own
    // vertical band as a clip-safe widget instead.
    if (widget.inlineSteppers) {
      final overlay = Stack(
        children: [
          _numberField(),
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
      return wrapWheel(_withHeader(context, overlay));
    }

    // Default: steppers are SIBLINGS of the field (a Row). Both modes avoid
    // interactive InputDecorator slots for the reason noted above.
    final field = _numberField();

    // Fit-width field is intrinsically sized (Row hugs it, mainAxis min);
    // otherwise the field Expands to fill a bounded parent (mainAxis max).
    final fit = widget.sizing?.fitWidthToContent ?? false;
    final row = Row(
      mainAxisSize: fit ? MainAxisSize.min : MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _stepper(
          widget.stepperIcons.decrementIcon,
          _canDecrement,
          -widget.step,
        ),
        SizedBox(width: context.spacing.xs),
        if (fit) field else Expanded(child: field),
        SizedBox(width: context.spacing.xs),
        _stepper(widget.stepperIcons.incrementIcon, _canIncrement, widget.step),
      ],
    );

    return wrapWheel(_withHeader(context, row));
  }
}
