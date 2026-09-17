import 'package:freezed_annotation/freezed_annotation.dart';

part 'faq_history_state.freezed.dart';
part 'faq_history_state.g.dart';

/// Persisted FAQ user state — recently-viewed entry ids + remembered
/// feedback (helpful / not-helpful) per entry.
@freezed
abstract class FaqHistoryState with _$FaqHistoryState {
  const factory FaqHistoryState({
    /// Recently-viewed entry ids, most-recent first.
    @Default(<String>[]) List<String> recent,

    /// `entryId → 'helpful' | 'notHelpful'`. Lets the UI show a
    /// "you thought this was helpful" indicator on return visits.
    @Default(<String, String>{}) Map<String, String> feedback,
  }) = _FaqHistoryState;

  factory FaqHistoryState.fromJson(Map<String, dynamic> json) =>
      _$FaqHistoryStateFromJson(json);
}
