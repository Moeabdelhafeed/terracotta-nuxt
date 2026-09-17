import 'package:flutter/material.dart';

/// A [TextEditingController] that paints a trailing "ghost" completion span
/// using the editor's own [TextStyle] — so the ghost aligns perfectly with
/// typed characters (same TextPainter, metrics and baseline). Mirrors text
/// bidirectionally with the caller's [source] controller.
///
/// Standalone (no widget / State dependency) so the mirror + ghost logic is
/// unit-testable.
class InlineGhostTextController extends TextEditingController {
  InlineGhostTextController({required this.source}) : super(text: source.text) {
    source.addListener(_syncFromSource);
    addListener(_syncToSource);
  }

  final TextEditingController source;
  String _ghost = '';
  Color _ghostColor = const Color(0x4D000000);
  bool _syncing = false;

  String get ghost => _ghost;
  set ghost(String value) {
    if (_ghost == value) return;
    _ghost = value;
    notifyListeners();
  }

  void setGhostColor(Color color) {
    if (_ghostColor == color) return;
    _ghostColor = color;
    notifyListeners();
  }

  /// The ghost is PAINTED as part of the field's TextSpan, so RenderEditable
  /// happily hit-tests it: dragging the caret onto the ghost yields a
  /// selection offset beyond the real text (`Range start N is out of text of
  /// length M` assertion when the value syncs to the platform IME). Clamp
  /// every incoming selection/composing range to the real text — a tap into
  /// the ghost lands the caret at the end of the typed text instead.
  @override
  set value(TextEditingValue newValue) {
    super.value = _clampToText(newValue);
  }

  TextEditingValue _clampToText(TextEditingValue v) {
    final len = v.text.length;
    final sel = v.selection;
    final selOk = sel.baseOffset <= len && sel.extentOffset <= len;
    final comp = v.composing;
    final compOk = !comp.isValid || (comp.start <= len && comp.end <= len);
    if (selOk && compOk) return v;

    int c(int o) => o > len ? len : o;
    return v.copyWith(
      selection: sel.copyWith(
        baseOffset: c(sel.baseOffset),
        extentOffset: c(sel.extentOffset),
      ),
      composing: compOk ? comp : TextRange.empty,
    );
  }

  void _syncFromSource() {
    if (_syncing) return;
    if (text == source.text) return;
    _syncing = true;
    text = source.text;
    selection = TextSelection.collapsed(offset: text.length);
    _syncing = false;
  }

  void _syncToSource() {
    if (_syncing) return;
    if (source.text == text) return;
    _syncing = true;
    source.text = text;
    source.selection = TextSelection.collapsed(offset: source.text.length);
    _syncing = false;
  }

  @override
  void dispose() {
    source.removeListener(_syncFromSource);
    removeListener(_syncToSource);
    super.dispose();
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final base = super.buildTextSpan(
      context: context,
      style: style,
      withComposing: withComposing,
    );
    if (_ghost.isEmpty) return base;
    return TextSpan(
      style: style,
      children: [
        base,
        TextSpan(
          text: _ghost,
          style: (style ?? const TextStyle()).copyWith(color: _ghostColor),
        ),
      ],
    );
  }
}
