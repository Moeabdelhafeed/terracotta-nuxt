import 'package:flutter/material.dart';

import '../text_field/global_text_field.dart';
import 'global_drop_down.dart';

// ---------------------------------------------------------------------------
// _DropdownFormShell — shared Form plumbing for both wrappers
// ---------------------------------------------------------------------------

/// Validation-mode plumbing shared by [GlobalDropdownFormField] and
/// [GlobalDropdownMultiFormField]. Mirrors the text field's semantics
/// (see `DropdownValidation` for the mode → trigger table):
///
/// * live modes → `AutovalidateMode.onUserInteraction` under
///   `deferToParentForm`, plus an explicit validate on every change;
/// * `onFocusLoss` → validate when the overlay closes;
/// * `onSubmit` → `Form.validate()` only;
/// * `revalidateKey` change → immediate re-validate on an
///   interacted-with (or error-showing) field.
mixin _DropdownFormShell<W extends StatefulWidget, V> on State<W> {
  final GlobalKey<FormFieldState<V>> fieldKey = GlobalKey<FormFieldState<V>>();

  /// The user has picked at least once — gates revalidateKey re-runs so
  /// an untouched field doesn't sprout errors on a rules change.
  bool _interacted = false;

  DropdownValidation<V> get validation;

  AutovalidateMode get autovalidateMode =>
      validation.deferToParentForm && validation.validatesOnChange
      ? AutovalidateMode.onUserInteraction
      : AutovalidateMode.disabled;

  /// Call from the dropdown's onChanged/onMultiChanged.
  void onPicked() {
    _interacted = true;
    if (validation.validatesOnChange) fieldKey.currentState?.validate();
  }

  /// Merge an on-close validate into the caller's popup options when the
  /// mode wants it — runs post-frame so a same-tap selection lands in
  /// `field.value` before the validator reads it.
  GlobalPopupOptions? mergedPopupOptions(GlobalPopupOptions? user) {
    if (!validation.validatesOnClose) return user;
    final base = user ?? const GlobalPopupOptions();
    return base.copyWith(
      hooks: GlobalPopupHooks(
        onOpen: base.hooks?.onOpen,
        onWillClose: base.hooks?.onWillClose,
        onClose: () {
          base.hooks?.onClose?.call();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _interacted = true;
            fieldKey.currentState?.validate();
          });
        },
      ),
    );
  }

  /// Call from didUpdateWidget with the old validation config.
  void maybeRevalidate(DropdownValidation<V> old) {
    if (validation.revalidateKey == old.revalidateKey) return;
    final field = fieldKey.currentState;
    if (field == null) return;
    if (!_interacted && !field.hasError) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) fieldKey.currentState?.validate();
    });
  }
}

// ---------------------------------------------------------------------------
// GlobalDropdownFormField — Form integration for single-select
// ---------------------------------------------------------------------------

/// `Form` shell over a single-select [GlobalDropdown] with text-field
/// validation semantics ([DropdownValidation]).
///
/// NOTE (FormField semantics): like every Flutter `FormField`,
/// [initialValue] seeds the field's value ONCE — the field owns the value
/// afterwards, so a parent passing a *changed* prop later is ignored by
/// design. For an externally-driven (fully controlled) value, use
/// [GlobalDropdown] directly and run your own validation, or reset via
/// `formKey.currentState.reset()`.
class GlobalDropdownFormField<T> extends StatefulWidget {
  const GlobalDropdownFormField({
    super.key,
    required this.items,
    this.groups,
    this.initialValue,
    this.onChanged,
    this.hint,
    this.identifier,
    this.required = false,
    this.enabled = true,
    this.asyncItemsLoader,
    this.controller,
    this.behavior = const DropdownBehavior(),
    this.slots = const DropdownSlots(),
    this.style,
    this.dropdownStyle,
    this.sizing,
    this.popupOptions,
    this.messages,
    this.validation = const DropdownValidation(),
    this.onSaved,
  });

  final List<DropdownItem<T>> items;
  final List<DropdownGroup<T>>? groups;
  final T? initialValue;
  final ValueChanged<T?>? onChanged;
  final String? hint;
  final String? identifier;

  /// Draws the red `*` on [identifier], as a required text field does.
  /// It marks the label; the rule itself is [validation]'s.
  final bool required;
  final bool enabled;
  final Future<List<DropdownItem<T>>> Function(String query)? asyncItemsLoader;
  final GlobalDropdownController? controller;
  final DropdownBehavior behavior;
  final DropdownSlots<T> slots;
  final TextFieldStyle? style;
  final DropdownStyle? dropdownStyle;
  final TextFieldSizing? sizing;
  final GlobalPopupOptions? popupOptions;
  final List<FieldMessage>? messages;
  final DropdownValidation<T> validation;
  final FormFieldSetter<T>? onSaved;

  @override
  State<GlobalDropdownFormField<T>> createState() =>
      _GlobalDropdownFormFieldState<T>();
}

class _GlobalDropdownFormFieldState<T> extends State<GlobalDropdownFormField<T>>
    with _DropdownFormShell<GlobalDropdownFormField<T>, T> {
  @override
  DropdownValidation<T> get validation => widget.validation;

  @override
  void didUpdateWidget(covariant GlobalDropdownFormField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    maybeRevalidate(oldWidget.validation);
  }

  @override
  Widget build(BuildContext context) {
    return FormField<T>(
      key: fieldKey,
      initialValue: widget.initialValue,
      enabled: widget.enabled,
      validator: widget.validation.validator,
      onSaved: widget.onSaved,
      autovalidateMode: autovalidateMode,
      builder: (field) {
        return GlobalDropdown<T>(
          items: widget.items,
          groups: widget.groups,
          selectedValue: field.value,
          onChanged: (val) {
            field.didChange(val);
            onPicked();
            widget.onChanged?.call(val);
          },
          hint: widget.hint,
          identifier: widget.identifier,
          required: widget.required,
          enabled: widget.enabled,
          errorText: widget.validation.errorText ?? field.errorText,
          asyncItemsLoader: widget.asyncItemsLoader,
          controller: widget.controller,
          behavior: widget.behavior,
          slots: widget.slots,
          style: widget.style,
          dropdownStyle: widget.dropdownStyle,
          sizing: widget.sizing,
          popupOptions: mergedPopupOptions(widget.popupOptions),
          messages: widget.messages,
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// GlobalDropdownMultiFormField — Form integration for multi-select
// ---------------------------------------------------------------------------

/// `Form` shell over a multi-select [GlobalDropdown]. Same
/// [DropdownValidation] semantics and initialValue-seeding caveats as
/// [GlobalDropdownFormField].
class GlobalDropdownMultiFormField<T> extends StatefulWidget {
  const GlobalDropdownMultiFormField({
    super.key,
    required this.items,
    this.groups,
    this.initialValue,
    this.onChanged,
    this.hint,
    this.identifier,
    this.required = false,
    this.enabled = true,
    this.asyncItemsLoader,
    this.controller,
    this.behavior = const DropdownBehavior(),
    this.chips = const DropdownChips(),
    this.slots = const DropdownSlots(),
    this.style,
    this.dropdownStyle,
    this.sizing,
    this.popupOptions,
    this.messages,
    this.validation = const DropdownValidation(),
    this.onSaved,
  });

  final List<DropdownItem<T>> items;
  final List<DropdownGroup<T>>? groups;
  final List<T>? initialValue;
  final ValueChanged<List<T>>? onChanged;
  final String? hint;
  final bool required;

  final String? identifier;
  final bool enabled;
  final Future<List<DropdownItem<T>>> Function(String query)? asyncItemsLoader;
  final GlobalDropdownController? controller;
  final DropdownBehavior behavior;
  final DropdownChips chips;
  final DropdownSlots<T> slots;
  final TextFieldStyle? style;
  final DropdownStyle? dropdownStyle;
  final TextFieldSizing? sizing;
  final GlobalPopupOptions? popupOptions;
  final List<FieldMessage>? messages;
  final DropdownValidation<List<T>> validation;
  final FormFieldSetter<List<T>>? onSaved;

  @override
  State<GlobalDropdownMultiFormField<T>> createState() =>
      _GlobalDropdownMultiFormFieldState<T>();
}

class _GlobalDropdownMultiFormFieldState<T>
    extends State<GlobalDropdownMultiFormField<T>>
    with _DropdownFormShell<GlobalDropdownMultiFormField<T>, List<T>> {
  @override
  DropdownValidation<List<T>> get validation => widget.validation;

  @override
  void didUpdateWidget(covariant GlobalDropdownMultiFormField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    maybeRevalidate(oldWidget.validation);
  }

  @override
  Widget build(BuildContext context) {
    return FormField<List<T>>(
      key: fieldKey,
      initialValue: widget.initialValue ?? <T>[],
      enabled: widget.enabled,
      validator: widget.validation.validator,
      onSaved: widget.onSaved,
      autovalidateMode: autovalidateMode,
      builder: (field) {
        return GlobalDropdown<T>(
          items: widget.items,
          groups: widget.groups,
          selectedValues: field.value,
          onMultiChanged: (vals) {
            field.didChange(vals);
            onPicked();
            widget.onChanged?.call(vals);
          },
          multiSelect: true,
          hint: widget.hint,
          identifier: widget.identifier,
          required: widget.required,
          enabled: widget.enabled,
          errorText: widget.validation.errorText ?? field.errorText,
          asyncItemsLoader: widget.asyncItemsLoader,
          controller: widget.controller,
          behavior: widget.behavior,
          chips: widget.chips,
          slots: widget.slots,
          style: widget.style,
          dropdownStyle: widget.dropdownStyle,
          sizing: widget.sizing,
          popupOptions: mergedPopupOptions(widget.popupOptions),
          messages: widget.messages,
        );
      },
    );
  }
}
