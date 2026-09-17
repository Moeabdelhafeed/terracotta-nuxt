import 'package:flutter/material.dart';

import 'global_checkbox.dart';

// ---------------------------------------------------------------------------
// GlobalCheckboxFormField — Form integration for a single bool checkbox
// ---------------------------------------------------------------------------

/// `Form` shell over a bool [GlobalCheckbox] with the text-field
/// validation semantics ([CheckboxValidation]) — the consent-checkbox
/// staple ("You must accept the terms").
///
/// NOTE (FormField semantics): like every Flutter `FormField`,
/// [initialValue] seeds the field's value ONCE — the field owns the
/// value afterwards, so a parent passing a *changed* prop later is
/// ignored by design. For an externally-driven value use
/// [GlobalCheckbox] directly and run your own validation.
class GlobalCheckboxFormField extends StatefulWidget {
  const GlobalCheckboxFormField({
    super.key,
    this.initialValue = false,
    this.onChanged,
    this.validation = const CheckboxValidation<bool>(),
    this.variant = CheckboxVariant.standard,
    this.style = const CheckboxStyle(),
    this.enabled = true,
    this.label,
    this.labelWidget,
    this.labelStyle,
    this.labelPosition = CheckboxLabelPosition.trailing,
    this.description,
    this.descriptionStyle,
    this.tooltip,
    this.debounce = false,
    this.messages = const [],
    this.semanticLabel,
  });

  /// Seeds the FormField ONCE (standard Flutter semantics).
  final bool initialValue;

  final ValueChanged<bool>? onChanged;

  /// Validator + mode + deferToParentForm + revalidateKey — see
  /// [CheckboxValidation].
  final CheckboxValidation<bool> validation;

  final CheckboxVariant variant;
  final CheckboxStyle style;
  final bool enabled;
  final String? label;
  final Widget? labelWidget;
  final TextStyle? labelStyle;
  final CheckboxLabelPosition labelPosition;
  final String? description;
  final TextStyle? descriptionStyle;
  final String? tooltip;
  final bool debounce;

  /// Status rows below the checkbox, stacked with the validator error.
  final List<FieldMessage> messages;

  final String? semanticLabel;

  @override
  State<GlobalCheckboxFormField> createState() =>
      _GlobalCheckboxFormFieldState();
}

class _GlobalCheckboxFormFieldState extends State<GlobalCheckboxFormField> {
  final _fieldKey = GlobalKey<FormFieldState<bool>>();
  bool _interacted = false;
  Locale? _locale;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Registering the locale dependency keeps even const-constructed
    // wrappers rebuilding on a language flip (Tr/S reads are static, not
    // inherited); a SHOWING error is a string cached in FormFieldState —
    // re-validate so it re-resolves in the new locale.
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
  void didUpdateWidget(GlobalCheckboxFormField old) {
    super.didUpdateWidget(old);
    _maybeRevalidate(old.validation.revalidateKey);
  }

  void _maybeRevalidate(Object? oldKey) {
    if (widget.validation.revalidateKey == oldKey) return;
    final state = _fieldKey.currentState;
    if (state == null || (!_interacted && !state.hasError)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fieldKey.currentState?.validate();
    });
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.validation;
    return FormField<bool>(
      key: _fieldKey,
      initialValue: widget.initialValue,
      enabled: widget.enabled,
      validator: (value) => v.errorText ?? v.validator?.call(value),
      // Only live modes hand the Form per-toggle validation.
      autovalidateMode: v.deferToParentForm && v.validatesOnChange
          ? AutovalidateMode.onUserInteraction
          : AutovalidateMode.disabled,
      builder: (field) {
        return GlobalCheckbox.simple(
          value: field.value ?? false,
          onChanged: widget.enabled
              ? (checked) {
                  _interacted = true;
                  field.didChange(checked);
                  widget.onChanged?.call(checked);
                  // Standalone live modes drive their own validation.
                  if (!v.deferToParentForm && v.validatesOnChange) {
                    field.validate();
                  }
                }
              : null,
          variant: widget.variant,
          style: widget.style,
          enabled: widget.enabled,
          label: widget.label,
          labelWidget: widget.labelWidget,
          labelStyle: widget.labelStyle,
          labelPosition: widget.labelPosition,
          description: widget.description,
          descriptionStyle: widget.descriptionStyle,
          tooltip: widget.tooltip,
          debounce: widget.debounce,
          errorText: field.errorText,
          messages: widget.messages,
          semanticLabel: widget.semanticLabel,
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// GlobalCheckboxGroupFormField — Form integration for a checkbox group
// ---------------------------------------------------------------------------

/// `Form` shell over a [GlobalCheckboxGroup] validating the selected
/// list ("pick at least two topics"). Same FormField seed-once
/// semantics as [GlobalCheckboxFormField].
class GlobalCheckboxGroupFormField<T> extends StatefulWidget {
  const GlobalCheckboxGroupFormField({
    super.key,
    required this.items,
    this.initialValues = const [],
    this.onChanged,
    this.validation = const CheckboxValidation(),
    this.variant = CheckboxVariant.standard,
    this.style = const CheckboxStyle(),
    this.spacing = kCheckboxGroupSpacing,
    this.direction = Axis.vertical,
    this.minSelections = 0,
    this.maxSelections,
    this.enabled = true,
    this.debounce = false,
    this.messages = const [],
    this.labelPosition = CheckboxLabelPosition.trailing,
    this.showSelectAll = false,
    this.selectAllLabel,
  });

  final List<CheckboxGroupItem<T>> items;

  /// Seeds the FormField ONCE (standard Flutter semantics).
  final List<T> initialValues;

  final ValueChanged<List<T>>? onChanged;
  final CheckboxValidation<List<T>> validation;
  final CheckboxVariant variant;
  final CheckboxStyle style;
  final double spacing;
  final Axis direction;
  final int minSelections;
  final int? maxSelections;
  final bool enabled;
  final bool debounce;
  final List<FieldMessage> messages;
  final CheckboxLabelPosition labelPosition;
  final bool showSelectAll;
  final String? selectAllLabel;

  @override
  State<GlobalCheckboxGroupFormField<T>> createState() =>
      _GlobalCheckboxGroupFormFieldState<T>();
}

class _GlobalCheckboxGroupFormFieldState<T>
    extends State<GlobalCheckboxGroupFormField<T>> {
  final _fieldKey = GlobalKey<FormFieldState<List<T>>>();
  bool _interacted = false;
  Locale? _locale;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // See _GlobalCheckboxFormFieldState — locale dependency + showing
    // errors re-resolve on a language flip.
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
  void didUpdateWidget(GlobalCheckboxGroupFormField<T> old) {
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
    return FormField<List<T>>(
      key: _fieldKey,
      initialValue: widget.initialValues,
      enabled: widget.enabled,
      validator: (values) => v.errorText ?? v.validator?.call(values),
      autovalidateMode: v.deferToParentForm && v.validatesOnChange
          ? AutovalidateMode.onUserInteraction
          : AutovalidateMode.disabled,
      builder: (field) {
        return GlobalCheckboxGroup<T>(
          items: widget.items,
          selectedValues: field.value ?? const [],
          onChanged: (values) {
            _interacted = true;
            field.didChange(values);
            widget.onChanged?.call(values);
            if (!v.deferToParentForm && v.validatesOnChange) {
              field.validate();
            }
          },
          variant: widget.variant,
          style: widget.style,
          spacing: widget.spacing,
          direction: widget.direction,
          minSelections: widget.minSelections,
          maxSelections: widget.maxSelections,
          enabled: widget.enabled,
          debounce: widget.debounce,
          errorText: field.errorText,
          messages: widget.messages,
          labelPosition: widget.labelPosition,
          showSelectAll: widget.showSelectAll,
          selectAllLabel: widget.selectAllLabel,
        );
      },
    );
  }
}
