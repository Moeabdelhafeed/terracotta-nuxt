import '../models/text_field_features.dart' show kTextFieldMaxUndoStackSize;

/// Pure undo / redo history for a text field's value. No Flutter
/// dependency — unit-testable in isolation.
///
/// The owning widget calls [record] on every user edit, [undo] / [redo]
/// when the user taps the buttons (passing the live text so the inverse
/// op is captured), and [reset] when the backing controller is swapped.
class UndoRedoStack {
  UndoRedoStack({
    this.maxSize = kTextFieldMaxUndoStackSize,
    String initial = '',
  }) : _last = initial;

  final int maxSize;
  final List<String> _undo = [];
  final List<String> _redo = [];
  String _last;

  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;

  /// Capture a user edit. No-op when [value] equals the last recorded
  /// value (avoids duplicate history entries). Clears the redo branch.
  void record(String value) {
    if (_last == value) return;
    _undo.add(_last);
    if (_undo.length > maxSize) _undo.removeAt(0);
    _redo.clear();
    _last = value;
  }

  /// Step back one edit. Returns the value to apply, or `null` if the undo
  /// stack is empty. [current] (the live text) is pushed onto the redo
  /// branch so a following [redo] restores it.
  String? undo(String current) {
    if (_undo.isEmpty) return null;
    _redo.add(current);
    _last = _undo.removeLast();
    return _last;
  }

  /// Step forward one edit. Returns the value to apply, or `null` if the
  /// redo stack is empty.
  String? redo(String current) {
    if (_redo.isEmpty) return null;
    _undo.add(current);
    _last = _redo.removeLast();
    return _last;
  }

  /// Drop all history and re-seed the baseline (e.g. on controller swap).
  void reset(String value) {
    _undo.clear();
    _redo.clear();
    _last = value;
  }
}
