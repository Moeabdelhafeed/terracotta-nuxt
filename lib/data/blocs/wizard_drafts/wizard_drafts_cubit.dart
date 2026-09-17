import 'package:hydrated_bloc/hydrated_bloc.dart';

import 'wizard_drafts_state.dart';

/// Per-wizard in-progress data + step index. Keyed by `draftKey` so
/// the same `WizardDraftsCubit` singleton can back any number of
/// wizards in the app. Caller never touches this directly — the
/// `WizardController` reads/writes through it when `draftKey` is set.
class WizardDraftsCubit extends HydratedCubit<WizardDraftsState> {
  WizardDraftsCubit() : super(const WizardDraftsState());

  // ─── Reads ───────────────────────────────────────────────────

  Map<String, dynamic> dataFor(String draftKey) =>
      Map<String, dynamic>.from(state.drafts[draftKey] ?? const {});

  int stepFor(String draftKey) => state.steps[draftKey] ?? 0;

  bool hasDraft(String draftKey) =>
      state.drafts.containsKey(draftKey) || state.steps.containsKey(draftKey);

  // ─── Writes ──────────────────────────────────────────────────

  void saveData(String draftKey, Map<String, dynamic> data) {
    final next = Map<String, Map<String, dynamic>>.from(state.drafts);
    next[draftKey] = Map<String, dynamic>.from(data);
    emit(state.copyWith(drafts: next));
  }

  void saveStep(String draftKey, int stepIndex) {
    if (state.steps[draftKey] == stepIndex) return;
    final next = Map<String, int>.from(state.steps);
    next[draftKey] = stepIndex;
    emit(state.copyWith(steps: next));
  }

  void clearFor(String draftKey) {
    final nextData = Map<String, Map<String, dynamic>>.from(state.drafts)
      ..remove(draftKey);
    final nextSteps = Map<String, int>.from(state.steps)..remove(draftKey);
    emit(state.copyWith(drafts: nextData, steps: nextSteps));
  }

  void clearAll() => emit(const WizardDraftsState());

  // ─── Hydrated serialization ──────────────────────────────────

  @override
  WizardDraftsState? fromJson(Map<String, dynamic> json) {
    try {
      return WizardDraftsState.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  @override
  Map<String, dynamic>? toJson(WizardDraftsState state) => state.toJson();
}
