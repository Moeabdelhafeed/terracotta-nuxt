import 'dart:async';

import 'package:flutter/material.dart';

import '../models/text_field_enums.dart';
import '../models/text_field_validation.dart';

/// Owns a field's validation slice — current error, interaction flag,
/// debounce timer and the mode→trigger decision logic — plus the async
/// pipeline: the sync validator gates [TextFieldValidation.asyncValidator],
/// which runs debounced with a monotonic request id ([_asyncReqId]) so
/// stale responses are dropped. Created and owned by the field's State
/// (which passes live config getters + side-effect callbacks), so the
/// orchestration is testable without driving a full widget: feed it a
/// [config] + [currentText] and assert on [errorText] / [asyncErrorText].
class FieldValidationController {
  FieldValidationController({
    required this.config,
    required this.currentText,
    required this.shakeEnabled,
    required this.isMounted,
    required this.requestRebuild,
    required this.triggerShake,
  });

  /// Live [TextFieldValidation] (re-read each call so widget updates apply).
  final TextFieldValidation Function() config;
  final String Function() currentText;

  /// Whether the error-shake animation is enabled (`features.animations
  /// .shakeOnError`). Gates [formValidator]'s shake, matching the legacy
  /// behavior.
  final bool Function() shakeEnabled;
  final bool Function() isMounted;

  /// Rebuild the field (so the new [errorText] paints).
  final VoidCallback requestRebuild;

  /// Play the error shake (post-frame `forward`).
  final VoidCallback triggerShake;

  /// Latest sync validation result. `null` = valid / not yet validated.
  String? errorText;

  /// Latest async validation result (server-side check). `null` = valid / not
  /// run.
  String? asyncErrorText;

  /// Whether an async validation is currently in flight — drives the suffix
  /// spinner.
  bool isValidatingAsync = false;

  /// Combined error for display: the sync result wins over the async one.
  String? get effectiveError => errorText ?? asyncErrorText;

  /// Whether the user has edited the field at least once.
  bool hasInteracted = false;

  bool _hasShaken = false;
  Timer? _timer;
  Timer? _asyncTimer;

  /// Monotonic id so an async response that resolves after newer input (or a
  /// cancel) is dropped.
  int _asyncReqId = 0;

  void markInteracted() => hasInteracted = true;

  /// Clear the internal error + reset the shake latch (e.g. on new input).
  /// Also drops any pending / shown async result.
  void clearError() {
    errorText = null;
    _hasShaken = false;
    _cancelAsync();
  }

  /// Run the validator now against [value] (or the live text). Updates
  /// [errorText] + rebuilds; shakes when an error first appears.
  void perform([String? value]) {
    final v = config();
    if (v.mode == ValidationMode.none) return;
    if (v.validator == null && v.asyncValidator == null) return;

    final text = value ?? currentText();
    final error = v.validator?.call(text);
    if (!isMounted()) return;
    final hadError = errorText != null;
    errorText = error;
    requestRebuild();
    if (error == null) {
      _hasShaken = false;
      _runAsync(text); // sync passed → run the server-side check
    } else {
      _cancelAsync(); // sync failed → skip async, drop any async result
      if (!hadError && !_hasShaken) {
        _hasShaken = true;
        triggerShake();
      }
    }
  }

  /// Run [TextFieldValidation.asyncValidator] (if set) after the sync check
  /// passed. Debounced; a response superseded by newer input or a cancel is
  /// dropped via [_asyncReqId].
  void _runAsync(String value) {
    final v = config();
    if (v.asyncValidator == null) {
      _cancelAsync();
      return;
    }
    _asyncTimer?.cancel();
    final reqId = ++_asyncReqId;
    isValidatingAsync = true;
    asyncErrorText = null;
    requestRebuild();

    _asyncTimer = Timer(v.asyncDebounce, () async {
      if (!isMounted() || reqId != _asyncReqId) return;
      String? err;
      try {
        err = await v.asyncValidator!(value);
      } catch (_) {
        err = null; // swallow — a failed lookup isn't a validation error
      }
      if (!isMounted() || reqId != _asyncReqId) return;
      asyncErrorText = err;
      isValidatingAsync = false;
      requestRebuild();
    });
  }

  /// Cancel any pending/in-flight async validation and clear its state. Does
  /// NOT rebuild — callers run inside an existing rebuild (or a widget update
  /// triggers one).
  void _cancelAsync() {
    _asyncTimer?.cancel();
    _asyncReqId++; // invalidate any in-flight response
    isValidatingAsync = false;
    asyncErrorText = null;
  }

  /// Debounced [perform] honoring [TextFieldValidation.delay].
  void schedule(String value) {
    _timer?.cancel();
    final v = config();
    if (v.delay == Duration.zero) {
      perform(value);
      return;
    }
    _timer = Timer(v.delay, () => perform(value));
  }

  /// Route an edit / focus-loss / submit to the right validation action per
  /// [TextFieldValidation.mode].
  void handleTrigger(
    String value, {
    bool isOnFocusLoss = false,
    bool isOnSubmit = false,
  }) {
    switch (config().mode) {
      case ValidationMode.none:
        break;
      case ValidationMode.onSubmit:
        // Runs the sync validator and, when it passes, the async one.
        if (isOnSubmit) perform(value);
        break;
      case ValidationMode.realTime:
        schedule(value);
        break;
      case ValidationMode.onFocusLoss:
        if (isOnFocusLoss) perform(value);
        break;
      case ValidationMode.onInteraction:
        if (hasInteracted) {
          isOnFocusLoss ? perform(value) : schedule(value);
        }
        break;
    }
  }

  /// The `validator` handed to the underlying `TextFormField` when the
  /// field defers to a parent `Form`.
  /// [parentAutoValidates] must be false when the enclosing `Form` has
  /// `AutovalidateMode.disabled` (the Flutter default). In that case the
  /// ONLY thing that can call this is an explicit `Form.validate()`, so
  /// the pre-interaction gate below must not apply — otherwise a
  /// required field the user never focused reports valid while empty and
  /// the form submits blank.
  String? formValidator(String? value, {bool parentAutoValidates = true}) {
    final v = config();
    if (v.errorText != null) return v.errorText;
    // Gate on first interaction only while the Form auto-validates (realTime /
    // onInteraction). For onSubmit / onFocusLoss / none this call IS an
    // explicit `Form.validate()` and must always validate — otherwise an
    // untouched empty form would pass.
    final autoValidating =
        parentAutoValidates &&
        (v.mode == ValidationMode.realTime ||
            v.mode == ValidationMode.onInteraction);
    if (autoValidating && !hasInteracted && !v.showErrorImmediately) {
      return null;
    }

    final error = v.validator?.call(value);
    // Store the fresh result so the message column (which renders ALL
    // validator errors — Form fields included) stays in sync with
    // Form-driven validation. formValidator can run during build
    // (autovalidate), so rebuild post-frame — and only on change, or the
    // build → validate → rebuild loop would never settle.
    final previous = errorText;
    errorText = error;
    if (error != previous) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (isMounted()) requestRebuild();
      });
    }
    if (error == null) {
      _hasShaken = false;
    } else if (shakeEnabled() && !_hasShaken) {
      _hasShaken = true;
      triggerShake();
    }
    return error;
  }

  /// `AutovalidateMode` for the underlying `TextFormField`. Only the live
  /// modes auto-validate; `onSubmit` / `onFocusLoss` stay disabled so the
  /// validator runs only on an explicit `Form.validate()` (or the field's
  /// internal submit / focus-loss trigger) — that's the point of those modes.
  AutovalidateMode autovalidateMode() {
    switch (config().mode) {
      case ValidationMode.none:
      case ValidationMode.onSubmit:
      case ValidationMode.onFocusLoss:
        return AutovalidateMode.disabled;
      case ValidationMode.realTime:
      case ValidationMode.onInteraction:
        return AutovalidateMode.onUserInteraction;
    }
  }

  void cancelTimer() {
    _timer?.cancel();
    _cancelAsync();
  }

  void dispose() {
    _timer?.cancel();
    _asyncTimer?.cancel();
  }
}
