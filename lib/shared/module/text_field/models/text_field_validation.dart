import 'package:flutter/material.dart';

import '../../../../core/localization/strings/text_field_strings.dart';
import 'text_field_defaults.dart';
import 'text_field_enums.dart';

// ---------------------------------------------------------------------------
// FieldRequirement
// ---------------------------------------------------------------------------

/// Single validation requirement displayed in the checklist below the field.
@immutable
class FieldRequirement {
  final String label;
  final bool Function(String value) test;

  const FieldRequirement({required this.label, required this.test});

  factory FieldRequirement.minLength(int length) => FieldRequirement(
    label: TextFieldStrings.reqMinLength(length),
    test: (v) => v.length >= length,
  );

  factory FieldRequirement.uppercase() => FieldRequirement(
    label: TextFieldStrings.reqUppercase,
    test: (v) => v.contains(RegExp(r'[A-Z]')),
  );

  factory FieldRequirement.lowercase() => FieldRequirement(
    label: TextFieldStrings.reqLowercase,
    test: (v) => v.contains(RegExp(r'[a-z]')),
  );

  factory FieldRequirement.digit() => FieldRequirement(
    label: TextFieldStrings.reqDigit,
    test: (v) => v.contains(RegExp(r'[0-9]')),
  );

  factory FieldRequirement.specialChar() => FieldRequirement(
    label: TextFieldStrings.reqSpecialChar,
    // Anything that isn't a letter/digit/whitespace counts — `_` and `-`
    // included (mirrors `Validators.specialCharacters`).
    test: (v) => v.contains(RegExp(r'[^\p{L}\p{N}\s]', unicode: true)),
  );

  factory FieldRequirement.regex(String label, RegExp pattern) =>
      FieldRequirement(label: label, test: (v) => pattern.hasMatch(v));

  factory FieldRequirement.noSpaces() => FieldRequirement(
    label: TextFieldStrings.reqNoSpaces,
    test: (v) => !v.contains(' '),
  );
}

// ---------------------------------------------------------------------------
// TextFieldValidation — validation
// ---------------------------------------------------------------------------

@immutable
class TextFieldValidation {
  const TextFieldValidation({
    this.validator,
    this.asyncValidator,
    this.asyncDebounce = TextFieldDefaults.asyncValidatorDebounce,
    this.errorText,
    this.mode = ValidationMode.onSubmit,
    this.deferToParentForm = true,
    this.delay = Duration.zero,
    this.showErrorImmediately = false,
    this.requirements,
    this.hidePassedRequirements = false,
    this.sortPassedRequirements = false,
    this.hideErrorWhenRequirements = false,
    this.requirementsTextOnly = false,
    this.showStrengthBar = false,
    this.strengthEstimator,
    this.onStrengthChanged,
    this.errorIcon,
    this.errorBuilder,
    this.revalidateKey,
  });

  /// Synchronous validator — format / required / length checks. Runs first;
  /// if it fails, [asyncValidator] is skipped.
  final String? Function(String?)? validator;

  /// Asynchronous validator — server-side checks (e.g. "is this email already
  /// registered?"). Runs ONLY after [validator] passes, debounced by
  /// [asyncDebounce]; returns an error string or null. Stale responses are
  /// dropped. While it's in flight the field shows a suffix spinner.
  ///
  /// Async errors are surfaced live below the field; they can't participate in
  /// a synchronous `Form.validate()`, so for a pure async-gated submit read
  /// the field's error state directly rather than relying on the Form result.
  final Future<String?> Function(String value)? asyncValidator;

  /// Debounce before [asyncValidator] fires after the sync check passes.
  final Duration asyncDebounce;

  /// External error text — overrides any internal validation result.
  final String? errorText;

  final ValidationMode mode;

  /// When `true`, validation runs via the parent [Form]'s `AutovalidateMode`.
  /// Set `false` for standalone fields outside a Form.
  final bool deferToParentForm;

  /// Debounce before validation fires (only with [ValidationMode.realTime] /
  /// [ValidationMode.onInteraction]).
  final Duration delay;

  /// Show error text without waiting for first interaction.
  final bool showErrorImmediately;

  /// Checklist of requirements shown below the field.
  final List<FieldRequirement>? requirements;

  /// Hide a requirement once it passes (animated).
  final bool hidePassedRequirements;

  /// Slide passed requirements to the BOTTOM of the checklist (animated
  /// reorder) so the unmet ones stay prominent. Ignored when
  /// [hidePassedRequirements] is set (rows disappear instead). Requires
  /// single-line requirement labels.
  final bool sortPassedRequirements;

  /// When requirements are set, suppress the default red error text — the
  /// checklist itself reports failure.
  final bool hideErrorWhenRequirements;

  /// Render requirements as text-only (no check/circle icons).
  final bool requirementsTextOnly;

  /// Render a colored strength bar (red → orange → green) by ratio of
  /// passed requirements — or by [strengthEstimator] when set (then
  /// [requirements] are optional).
  final bool showStrengthBar;

  /// Real strength estimation, 0.0–1.0 (e.g. a zxcvbn-style entropy score —
  /// catches `Password1!` being weak despite passing every checklist rule).
  /// When set, drives the strength bar + [onStrengthChanged] instead of the
  /// passed-requirements ratio.
  final double Function(String value)? strengthEstimator;

  /// Fired (post-frame) whenever the computed strength (0.0–1.0) changes —
  /// e.g. to gate a submit button.
  final ValueChanged<double>? onStrengthChanged;

  /// Effective strength for [value]: [strengthEstimator], else the
  /// passed-[requirements] ratio, else null (no strength concept).
  double? strengthOf(String value) {
    final est = strengthEstimator;
    if (est != null) return est(value).clamp(0.0, 1.0);
    final reqs = requirements;
    if (reqs == null || reqs.isEmpty) return null;
    if (value.isEmpty) return 0;
    return reqs.where((r) => r.test(value)).length / reqs.length;
  }

  /// Convenience rich error: shows this icon before the message. The field
  /// renders `icon + message` in its own message column below the field
  /// (same icon + status-color treatment as success / warning / info notes) —
  /// NOT in `InputDecoration.error`. Ignored when [errorBuilder] is set.
  ///
  /// A rich field stays **Form-integrated**: the Form validator still runs
  /// (so `Form.validate()` is correct and Material paints its automatic error
  /// border + semantics); Material's duplicate string is visually collapsed
  /// while the column renders the rich version.
  final IconData? errorIcon;

  /// Full control over the error display — return any widget (icon + text +
  /// action, multiple lines, etc.) for the current error [message]. Rendered
  /// in the field's message column below the field (not
  /// `InputDecoration.error`); the Form validator still runs and Material's
  /// string error is visually collapsed, so `Form.validate()` + the error
  /// border keep working. Wins over [errorIcon].
  final Widget Function(BuildContext context, String message)? errorBuilder;

  /// Whether a rich (widget) error is configured.
  bool get hasRichError => errorBuilder != null || errorIcon != null;

  /// Change signal for the VALIDATION RULES themselves. Validator closures
  /// are recreated every build, so the field can't tell a rebuild from a
  /// rule change — encode the rule inputs here (a value, record or list:
  /// `revalidateKey: (allowLandline, country.code)`). When the key differs
  /// between widget updates, a field the user already interacted with (or
  /// one showing an error) re-runs validation immediately instead of
  /// waiting for the next keystroke.
  final Object? revalidateKey;

  TextFieldValidation copyWith({
    String? Function(String?)? validator,
    Future<String?> Function(String value)? asyncValidator,
    Duration? asyncDebounce,
    String? errorText,
    ValidationMode? mode,
    bool? deferToParentForm,
    Duration? delay,
    bool? showErrorImmediately,
    List<FieldRequirement>? requirements,
    bool? hidePassedRequirements,
    bool? sortPassedRequirements,
    bool? hideErrorWhenRequirements,
    bool? requirementsTextOnly,
    bool? showStrengthBar,
    double Function(String value)? strengthEstimator,
    ValueChanged<double>? onStrengthChanged,
    IconData? errorIcon,
    Widget Function(BuildContext context, String message)? errorBuilder,
    Object? revalidateKey,
  }) {
    return TextFieldValidation(
      validator: validator ?? this.validator,
      asyncValidator: asyncValidator ?? this.asyncValidator,
      asyncDebounce: asyncDebounce ?? this.asyncDebounce,
      errorText: errorText ?? this.errorText,
      mode: mode ?? this.mode,
      deferToParentForm: deferToParentForm ?? this.deferToParentForm,
      delay: delay ?? this.delay,
      showErrorImmediately: showErrorImmediately ?? this.showErrorImmediately,
      requirements: requirements ?? this.requirements,
      hidePassedRequirements:
          hidePassedRequirements ?? this.hidePassedRequirements,
      sortPassedRequirements:
          sortPassedRequirements ?? this.sortPassedRequirements,
      hideErrorWhenRequirements:
          hideErrorWhenRequirements ?? this.hideErrorWhenRequirements,
      requirementsTextOnly: requirementsTextOnly ?? this.requirementsTextOnly,
      showStrengthBar: showStrengthBar ?? this.showStrengthBar,
      strengthEstimator: strengthEstimator ?? this.strengthEstimator,
      onStrengthChanged: onStrengthChanged ?? this.onStrengthChanged,
      errorIcon: errorIcon ?? this.errorIcon,
      errorBuilder: errorBuilder ?? this.errorBuilder,
      revalidateKey: revalidateKey ?? this.revalidateKey,
    );
  }
}
