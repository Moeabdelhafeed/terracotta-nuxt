import 'package:flutter/material.dart';

import 'global_radio.dart';

export '../checkbox/checkbox_models.dart' show CheckboxValidation;

// ---------------------------------------------------------------------------
// GlobalRadioGroupFormField — Form integration for a radio group
// ---------------------------------------------------------------------------

/// `Form` shell over a [GlobalRadioGroup] validating the selected value
/// ("pick a plan to continue"). Reuses [CheckboxValidation] — the
/// selection-controls family shares one validation vocabulary
/// (`onSubmit` = `Form.validate()` only, live modes = every pick,
/// `deferToParentForm`, `revalidateKey`).
///
/// NOTE (FormField semantics): [initialValue] seeds the field ONCE —
/// the field owns the value afterwards; a parent changing the prop
/// later is ignored by design.
class GlobalRadioGroupFormField<T> extends StatefulWidget {
  const GlobalRadioGroupFormField({
    super.key,
    required this.items,
    this.initialValue,
    this.onChanged,
    this.validation = const CheckboxValidation(),
    this.variant = RadioVariant.dot,
    this.style = const RadioStyle(),
    this.spacing = kRadioGroupSpacing,
    this.direction = Axis.vertical,
    this.enabled = true,
    this.debounce = false,
    this.messages = const [],
    this.labelPosition = RadioLabelPosition.trailing,
  });

  final List<RadioGroupItem<T>> items;

  /// Seeds the FormField ONCE (standard Flutter semantics).
  final T? initialValue;

  final ValueChanged<T>? onChanged;

  /// Validator + mode + deferToParentForm + revalidateKey — shared with
  /// the checkbox wrappers.
  final CheckboxValidation<T?> validation;

  final RadioVariant variant;
  final RadioStyle style;
  final double spacing;
  final Axis direction;
  final bool enabled;
  final bool debounce;
  final List<FieldMessage> messages;
  final RadioLabelPosition labelPosition;

  @override
  State<GlobalRadioGroupFormField<T>> createState() =>
      _GlobalRadioGroupFormFieldState<T>();
}

class _GlobalRadioGroupFormFieldState<T>
    extends State<GlobalRadioGroupFormField<T>> {
  final _fieldKey = GlobalKey<FormFieldState<T>>();
  bool _interacted = false;
  Locale? _locale;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Locale dependency + a SHOWING error re-resolves on a language
    // flip (the error string is cached in FormFieldState).
    final locale = Localizations.maybeLocaleOf(context);
    if (_locale != null && locale != _locale) {
      final state = _fieldKey.currentState;
      if (state != null && state.hasError) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _fieldKey.currentState?.validate();
        });
      }
    }
    _locale = locale;
  }

  @override
  void didUpdateWidget(GlobalRadioGroupFormField<T> old) {
    super.didUpdateWidget(old);
    if (widget.validation.revalidateKey == old.validation.revalidateKey) {
      return;
    }
    final state = _fieldKey.currentState;
    if (state == null || (!_interacted && !state.hasError)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fieldKey.currentState?.validate();
    });
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.validation;
    return FormField<T>(
      key: _fieldKey,
      initialValue: widget.initialValue,
      enabled: widget.enabled,
      validator: (value) => v.errorText ?? v.validator?.call(value),
      // Only live modes hand the Form per-pick validation.
      autovalidateMode: v.deferToParentForm && v.validatesOnChange
          ? AutovalidateMode.onUserInteraction
          : AutovalidateMode.disabled,
      builder: (field) {
        return GlobalRadioGroup<T>(
          items: widget.items,
          groupValue: field.value,
          onChanged: (value) {
            _interacted = true;
            field.didChange(value);
            widget.onChanged?.call(value);
            if (!v.deferToParentForm && v.validatesOnChange) {
              field.validate();
            }
          },
          variant: widget.variant,
          style: widget.style,
          spacing: widget.spacing,
          direction: widget.direction,
          enabled: widget.enabled,
          debounce: widget.debounce,
          errorText: field.errorText,
          messages: widget.messages,
          labelPosition: widget.labelPosition,
        );
      },
    );
  }
}
