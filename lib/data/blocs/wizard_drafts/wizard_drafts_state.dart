import 'package:freezed_annotation/freezed_annotation.dart';

part 'wizard_drafts_state.freezed.dart';
part 'wizard_drafts_state.g.dart';

/// Persisted in-progress wizard data. Keyed by caller-supplied
/// `draftKey` so multiple wizards (signup, KYC, checkout) keep
/// separate drafts.
@freezed
abstract class WizardDraftsState with _$WizardDraftsState {
  const factory WizardDraftsState({
    /// `{ draftKey: { fieldId: value } }`. Values must be JSON-encodable
    /// (Hydrated serializes via `jsonEncode`).
    @Default(<String, Map<String, dynamic>>{})
    Map<String, Map<String, dynamic>> drafts,

    /// `{ draftKey: currentStepIndex }` — restored on next mount.
    @Default(<String, int>{}) Map<String, int> steps,
  }) = _WizardDraftsState;

  factory WizardDraftsState.fromJson(Map<String, dynamic> json) =>
      _$WizardDraftsStateFromJson(json);
}
