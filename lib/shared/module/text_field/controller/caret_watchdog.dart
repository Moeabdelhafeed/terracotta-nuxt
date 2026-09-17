import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Why the caret is not blinking, when it should be.
enum CaretStatus {
  /// Blinking, or at least lit at this instant. Nothing to do.
  ok,

  /// No `EditableText` under the key — nothing to inspect. Also what you
  /// get before the first frame.
  unknown,

  /// A floating-cursor drag was started and never ended.
  ///
  /// `EditableText` hides the caret for the whole duration of a floating
  /// cursor, so a drag whose End never arrives hides it FOREVER while
  /// the field keeps accepting keystrokes normally. This is the state
  /// that reads as "the text field is broken".
  floatingCursorStuck,

  /// Blinking correctly but painted in a FULLY TRANSPARENT colour, so
  /// nothing appears.
  ///
  /// Material derives the caret colour from `errorStyle.color` while a
  /// field is invalid. A design that hides Material's error string by
  /// collapsing that style to transparent hands the caret the same
  /// transparency — the blink machinery is healthy and the caret is
  /// simply invisible, which no amount of restarting fixes. The cure is
  /// an explicit `cursorErrorColor`.
  transparent,

  /// Dark for another reason: the blink timer stopped and nothing
  /// restarted it, tickers are disabled for this subtree, or the
  /// selection is not collapsed.
  dark,
}

/// Diagnoses — and where possible repairs — a caret that has stopped
/// blinking while its field is still accepting input.
///
/// ## The failure
///
/// `EditableText` only blinks when ALL of `_hasFocus`, collapsed
/// selection, `showCursor`, `TickerMode.of(context)` and
/// `!renderEditable.floatingCursorOn` hold. Typing restarts the blink
/// only when a timer is already running, so once any of those conditions
/// has knocked the caret out it stays out — and every one of them leaves
/// the field fully usable. The result is a field that takes text with no
/// visible caret, which reads as broken.
///
/// A second, quieter failure has nothing to do with blinking: Material
/// paints the caret in `errorStyle.color` while a field is invalid, so a
/// design that hides Material's error string by collapsing that style to
/// transparent gets a transparent CARET too. The blink is healthy and
/// the caret is simply not visible.
///
/// On iOS the reachable culprit is the floating cursor: a long-press
/// drag on the caret starts one, and if the matching End never arrives
/// (an interrupted gesture — easy to produce with a trackpad on the
/// Simulator) `floatingCursorOn` stays true and the caret never returns.
/// That one is repairable from outside: send the End the platform never
/// sent.
///
/// ## Why probing is safe
///
/// Everything used here is public: `EditableTextState.renderEditable`,
/// `RenderEditable.floatingCursorOn`, `RenderEditable.showCursor`, and
/// `EditableTextState.updateFloatingCursor` — the same entry point the
/// iOS text-input channel calls.
class CaretWatchdog {
  const CaretWatchdog._();

  /// The `EditableTextState` under [key], or null before the first
  /// frame.
  ///
  /// Walks rather than taking a key on `EditableText` directly, because
  /// `TextFormField` builds it several layers down and exposes no hook.
  static EditableTextState? editableStateOf(GlobalKey key) {
    final context = key.currentContext;
    if (context == null) return null;

    EditableTextState? found;
    void visit(Element element) {
      if (found != null) return;
      if (element is StatefulElement && element.state is EditableTextState) {
        found = element.state as EditableTextState;
        return;
      }
      element.visitChildren(visit);
    }

    context.visitChildElements(visit);
    return found;
  }

  /// What the caret is doing right now.
  ///
  /// Call this immediately AFTER a keystroke: `EditableText` relights the
  /// caret on every value change, so a caret that is dark at that moment
  /// is genuinely stuck rather than merely mid-blink. Polling on a timer
  /// would have to guess the blink phase.
  static CaretStatus inspect(GlobalKey key) {
    final state = editableStateOf(key);
    if (state == null) return CaretStatus.unknown;
    final render = state.renderEditable;
    if (render.floatingCursorOn) return CaretStatus.floatingCursorStuck;
    // Checked BEFORE the blink, and against the widget's own colour
    // rather than the render object's: the blink multiplies that colour's
    // alpha, so `renderEditable.cursorColor` is phase-dependent while
    // this is not. A fully transparent base blinks between invisible and
    // invisible, and every liveness signal still reads healthy — which
    // is exactly how it hides.
    if (state.widget.cursorColor.a == 0) return CaretStatus.transparent;
    // `showCursor` is the notifier EditableText drives from its blink
    // controller and hands to the render object, so it IS what decides
    // whether the caret paints. (`cursorCurrentlyVisible` says the same
    // thing but is marked visibleForTesting.)
    return render.showCursor.value ? CaretStatus.ok : CaretStatus.dark;
  }

  /// Ends a floating cursor the platform started and never finished.
  ///
  /// Returns whether anything was repaired. Sending an End when no
  /// floating cursor is running would move the selection, so this checks
  /// first.
  static bool endStuckFloatingCursor(GlobalKey key) {
    final state = editableStateOf(key);
    if (state == null) return false;
    if (!state.renderEditable.floatingCursorOn) return false;
    state.updateFloatingCursor(
      RawFloatingCursorPoint(state: FloatingCursorDragState.End),
    );
    return true;
  }
}
