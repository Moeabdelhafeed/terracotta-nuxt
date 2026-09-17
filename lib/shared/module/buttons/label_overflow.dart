/// What a button label does when the button is too narrow for it.
///
/// Buttons are the one place where truncating is genuinely bad: the
/// label IS the affordance, so "Delete acc…" and "Delete all…" are the
/// same button as far as the user can tell.
enum LabelOverflow {
  /// Scroll the label so all of it is readable. The default. Costs
  /// nothing when the label fits — the marquee is only built once the
  /// label has been MEASURED as too wide — and degrades to [ellipsis]
  /// under reduced motion.
  marquee,

  /// Truncate with an ellipsis. Pick this for labels whose tail is
  /// disposable, or where a moving label would be a distraction.
  ellipsis,
}
