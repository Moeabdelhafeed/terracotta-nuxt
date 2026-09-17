import '../../../generated/l10n.dart';
import '../tr.dart';

/// Strings for the `stepper_` key prefix family.
///
/// TWO widgets share this prefix, because they share the word: the +/-
/// control that quantity and measurement fields wear ([increase] /
/// [decrease]), and `GlobalStepper`, the run of steps — everything
/// below [stepOf]. Only the second group is ever spoken aloud; the
/// first is a pair of tooltips.
class StepperStrings {
  StepperStrings._();

  // ─── The +/- control ──────────────────────────────────────
  static String get increase =>
      Tr.t('stepper.increase', S.current.stepper_increase);
  static String get decrease =>
      Tr.t('stepper.decrease', S.current.stepper_decrease);

  // ─── GlobalStepper ────────────────────────────────────────
  /// "Step 2 of 4" — where in the run this step is.
  static String stepOf(int index, int total) =>
      Tr.t('stepper.step_of', S.current.stepper_step_of(index, total));

  static String get current =>
      Tr.t('stepper.current', S.current.stepper_current);
  static String get completed =>
      Tr.t('stepper.completed', S.current.stepper_completed);
  static String get upcoming =>
      Tr.t('stepper.upcoming', S.current.stepper_upcoming);
  static String get error => Tr.t('stepper.error', S.current.stepper_error);
  static String get disabled =>
      Tr.t('stepper.disabled', S.current.stepper_disabled);
}
