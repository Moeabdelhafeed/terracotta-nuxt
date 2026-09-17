import 'package:flutter/foundation.dart';

import '../../../core/di/service_locator.dart';
import '../../../data/blocs/wizard_drafts/wizard_drafts_cubit.dart';
import 'wizard_models.dart';

/// Drives a [GlobalWizard]. Owns the data map, current step, async
/// submit state, and optional draft persistence.
///
/// Caller can drive externally (controller passed in to the widget),
/// or let the widget create one internally.
class WizardController extends ChangeNotifier {
  WizardController({
    required this.steps,
    this.draftKey,
    Map<String, dynamic>? initialData,
    int? initialStep,
  }) {
    final cubit = draftKey != null ? getIt<WizardDraftsCubit>() : null;
    _data = Map<String, dynamic>.from(
      initialData ?? cubit?.dataFor(draftKey!) ?? const <String, dynamic>{},
    );
    _currentStep = initialStep ?? cubit?.stepFor(draftKey!) ?? 0;
    _currentStep = _currentStep.clamp(0, steps.length - 1);
  }

  /// Full step list — including any with `skipWhen` that may be
  /// filtered out at navigation time.
  final List<WizardStep> steps;

  /// When non-null, the controller reads + writes the data + step
  /// index to [WizardDraftsCubit] keyed by this string. Survives
  /// app kill.
  final String? draftKey;

  late Map<String, dynamic> _data;
  late int _currentStep;
  bool _isSubmitting = false;
  Object? _submitError;

  // ─── Reads ───────────────────────────────────────────────────

  Map<String, dynamic> get data => Map.unmodifiable(_data);
  int get currentStep => _currentStep;
  WizardStep get currentStepModel => steps[_currentStep];
  bool get isSubmitting => _isSubmitting;
  Object? get submitError => _submitError;

  /// Step list with `skipWhen` predicates applied against current
  /// `data`. Internal navigation uses this — public `currentStep`
  /// still indexes [steps] for caller-side simplicity.
  List<WizardStep> get effectiveSteps =>
      steps.where((s) => s.skipWhen?.call(_data) != true).toList();

  bool get isFirst => _firstActiveIndex == _currentStep;
  bool get isLast => _lastActiveIndex == _currentStep;

  /// Current step passes its validator (or has none).
  bool get canAdvance {
    final v = steps[_currentStep].validator;
    if (v == null) return true;
    return v(_data);
  }

  /// `data` plus a patch — pure, doesn't mutate. Used by validators
  /// that want to peek at what a setData would look like.
  Map<String, dynamic> dataWith(Map<String, dynamic> patch) =>
      Map<String, dynamic>.from(_data)..addAll(patch);

  // ─── Mutations ───────────────────────────────────────────────

  /// Merge `patch` into the data map. Persists when `draftKey` set.
  void setData(Map<String, dynamic> patch) {
    if (patch.isEmpty) return;
    _data.addAll(patch);
    _persistDraft();
    notifyListeners();
  }

  /// Replace the entire data map. Useful when restoring from caller-
  /// held state.
  void replaceData(Map<String, dynamic> next) {
    _data = Map<String, dynamic>.from(next);
    _persistDraft();
    notifyListeners();
  }

  /// Advance to the next non-skipped step. Returns false when the
  /// current step's validator rejects.
  bool next() {
    if (!canAdvance) return false;
    final nextIdx = _nextActiveAfter(_currentStep);
    if (nextIdx == null) return false;
    _currentStep = nextIdx;
    _persistStep();
    _submitError = null;
    notifyListeners();
    return true;
  }

  /// Go back to the previous non-skipped step.
  bool back() {
    final prev = _prevActiveBefore(_currentStep);
    if (prev == null) return false;
    _currentStep = prev;
    _persistStep();
    _submitError = null;
    notifyListeners();
    return true;
  }

  /// Jump directly to [index]. Returns false when not allowed —
  /// future steps are gated on intermediate validators when
  /// [allowJumpToCompleted] is false.
  bool goTo(int index, {bool allowJumpToCompleted = true}) {
    if (index < 0 || index >= steps.length) return false;
    if (index == _currentStep) return false;
    if (index > _currentStep && !allowJumpToCompleted) {
      // Validate every step between here and there.
      for (var i = _currentStep; i < index; i++) {
        if (steps[i].validator?.call(_data) == false) return false;
      }
    }
    _currentStep = index;
    _persistStep();
    _submitError = null;
    notifyListeners();
    return true;
  }

  /// Run the caller's submit function. Sets `isSubmitting` for the
  /// duration. On success: clears any draft + the error. On throw:
  /// captures the error so the UI can surface it. Stays on the last
  /// step either way — caller decides what to do via the completion
  /// callback.
  Future<bool> submit(
    Future<void> Function(Map<String, dynamic> data) onSubmit,
  ) async {
    if (_isSubmitting) return false;
    _isSubmitting = true;
    _submitError = null;
    notifyListeners();
    try {
      await onSubmit(_data);
      _isSubmitting = false;
      _submitError = null;
      if (draftKey != null) {
        getIt<WizardDraftsCubit>().clearFor(draftKey!);
      }
      notifyListeners();
      return true;
    } catch (e) {
      _isSubmitting = false;
      _submitError = e;
      notifyListeners();
      return false;
    }
  }

  /// Drop any in-progress draft + reset to first step. Doesn't
  /// re-run validators — designed for cancel flows.
  void reset() {
    _data = <String, dynamic>{};
    _currentStep = _firstActiveIndex;
    _submitError = null;
    if (draftKey != null) {
      getIt<WizardDraftsCubit>().clearFor(draftKey!);
    }
    notifyListeners();
  }

  // ─── Internals ───────────────────────────────────────────────

  int get _firstActiveIndex {
    for (var i = 0; i < steps.length; i++) {
      if (steps[i].skipWhen?.call(_data) != true) return i;
    }
    return 0;
  }

  int get _lastActiveIndex {
    for (var i = steps.length - 1; i >= 0; i--) {
      if (steps[i].skipWhen?.call(_data) != true) return i;
    }
    return steps.length - 1;
  }

  int? _nextActiveAfter(int index) {
    for (var i = index + 1; i < steps.length; i++) {
      if (steps[i].skipWhen?.call(_data) != true) return i;
    }
    return null;
  }

  int? _prevActiveBefore(int index) {
    for (var i = index - 1; i >= 0; i--) {
      if (steps[i].skipWhen?.call(_data) != true) return i;
    }
    return null;
  }

  void _persistDraft() {
    if (draftKey == null) return;
    getIt<WizardDraftsCubit>().saveData(draftKey!, _data);
  }

  void _persistStep() {
    if (draftKey == null) return;
    getIt<WizardDraftsCubit>().saveStep(draftKey!, _currentStep);
  }
}
