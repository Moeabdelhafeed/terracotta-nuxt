// ---------------------------------------------------------------------------
// ValidationMode
// ---------------------------------------------------------------------------

/// When the field validates its content.
enum ValidationMode {
  /// No automatic validation.
  none,

  /// Validates only when the parent Form is submitted.
  onSubmit,

  /// Validates in real-time as the user types (debounced).
  realTime,

  /// Validates when the field loses focus.
  onFocusLoss,

  /// Validates after first interaction, then on every change.
  onInteraction,
}

// ---------------------------------------------------------------------------
// TextFieldRevealMode
// ---------------------------------------------------------------------------

/// How the visibility toggle of an obscured field reveals the text.
enum TextFieldRevealMode {
  /// Tap toggles revealed/hidden (optionally auto re-hiding after
  /// `TextFieldBehavior.revealTimeout`).
  toggle,

  /// Press-and-hold reveals; release re-hides (banking pattern). No
  /// capture-confirm dialog — the reveal is momentary and deliberate.
  holdToReveal,
}
