import 'package:flutter/material.dart';

import '../models/text_field_defaults.dart';

/// A [TextEditingController] that renders EVERY character as the obscuring
/// bullet — including the one just typed. Flutter's own `obscureText`
/// briefly reveals the latest character on mobile and offers no way to turn
/// that off; this controller bypasses it for screen-share / recording
/// protection (`TextFieldBehavior.instantObscure`).
///
/// Mirrors text bidirectionally with the caller's [source] controller (same
/// pattern as `InlineGhostTextController`). The field using it must pass
/// `obscureText: false` (this controller does the obscuring) and disable
/// autocorrect/suggestions — the widget handles both.
///
/// Bullets are 1:1 with characters, so selection/composing ranges stay
/// valid.
class InstantObscureTextController extends TextEditingController {
  InstantObscureTextController({required this.source})
    : super(text: source.text) {
    source.addListener(_syncFromSource);
    addListener(_syncToSource);
  }

  final TextEditingController source;
  bool _syncing = false;

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
    return TextSpan(
      style: style,
      text: TextFieldDefaults.obscuringCharacter * text.length,
    );
  }
}
