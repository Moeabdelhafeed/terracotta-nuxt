import 'package:hydrated_bloc/hydrated_bloc.dart';

import '../../../shared/module/faq/faq_models.dart';
import 'faq_history_state.dart';

/// Persists FAQ user state across app sessions:
///   * recently-viewed entry ids (most-recent first, capped at
///     [maxRecent])
///   * the user's last feedback (helpful / not-helpful) per entry
///
/// Backed by `HydratedCubit` so it survives app kill. Reads are
/// synchronous; writes auto-persist via `state.toJson()`.
class FaqHistoryCubit extends HydratedCubit<FaqHistoryState> {
  FaqHistoryCubit({this.maxRecent = 12}) : super(const FaqHistoryState());

  final int maxRecent;

  // ─── Recent ──────────────────────────────────────────────────

  List<String> get recent => List.unmodifiable(state.recent);

  void markViewed(String entryId) {
    final next = List<String>.from(state.recent)
      ..remove(entryId)
      ..insert(0, entryId);
    if (next.length > maxRecent) {
      next.removeRange(maxRecent, next.length);
    }
    emit(state.copyWith(recent: next));
  }

  void clearRecent() => emit(state.copyWith(recent: const []));

  // ─── Feedback ───────────────────────────────────────────────

  FaqFeedback? feedbackFor(String entryId) {
    final raw = state.feedback[entryId];
    if (raw == 'helpful') return FaqFeedback.helpful;
    if (raw == 'notHelpful') return FaqFeedback.notHelpful;
    return null;
  }

  void setFeedback(String entryId, FaqFeedback feedback) {
    final next = Map<String, String>.from(state.feedback);
    next[entryId] = feedback.name;
    emit(state.copyWith(feedback: next));
  }

  void clearFeedback(String entryId) {
    if (!state.feedback.containsKey(entryId)) return;
    final next = Map<String, String>.from(state.feedback)..remove(entryId);
    emit(state.copyWith(feedback: next));
  }

  // ─── Hydrated ────────────────────────────────────────────────

  @override
  FaqHistoryState? fromJson(Map<String, dynamic> json) {
    try {
      return FaqHistoryState.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  @override
  Map<String, dynamic>? toJson(FaqHistoryState state) => state.toJson();
}
