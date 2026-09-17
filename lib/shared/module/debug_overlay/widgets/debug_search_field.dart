import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../buttons/global_icon_button.dart';
import '../../text_field/text_field.dart';
import '../debug_overlay_models.dart';
import 'debug_text_field.dart';

/// THE search field for debug-overlay views — home, L10n, route jumper
/// (and any future tool) share this one widget so the overlay search UX
/// never drifts: filled dark box, 8px radius, accent focus border,
/// clear button, optional live result count, Esc clears before it
/// bubbles.
///
/// Composed over [DebugTextField] (→ [GlobalTextFormField] with the
/// pinned console style) — only the Esc handler and the count+clear
/// suffix live here.
class DebugSearchField extends StatelessWidget {
  const DebugSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    this.hintText = 'Search',
    this.autofocus = false,
    this.focusNode,
    this.resultCount,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hintText;
  final bool autofocus;
  final FocusNode? focusNode;

  /// Non-null while a query is live — rendered before the clear button.
  final int? resultCount;

  void _clear() {
    controller.clear();
    onChanged('');
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onKeyEvent: (node, event) {
        // Esc: clear the query first; a second Esc bubbles up.
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape &&
            controller.text.isNotEmpty) {
          _clear();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      // Suffix (count + clear) tracks the text without requiring the
      // host view to rebuild on every keystroke.
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, _) => DebugTextField(
          controller: controller,
          hint: hintText,
          focusNode: focusNode,
          autofocus: autofocus,
          onChanged: onChanged,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 6,
            vertical: 8,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            size: 16,
            color: DebugOverlayTheme.textDim,
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 30),
          // ALWAYS present (just invisible when empty) — a suffix that
          // appears on the first keystroke changes the field's height.
          suffix: TextFieldSuffix.widget(
            IgnorePointer(
              ignoring: value.text.isEmpty,
              child: Opacity(
                opacity: value.text.isEmpty ? 0 : 1,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (resultCount != null)
                      Text(
                        '$resultCount',
                        style: DebugOverlayTheme.mono.copyWith(
                          fontSize: 11,
                          color: DebugOverlayTheme.textDim,
                        ),
                      ),
                    GlobalIconButton(
                      enforceMinTouchTarget: false,
                      iconData: Icons.close_rounded,
                      onPressed: _clear,
                      iconSize: 14,
                      style: const ButtonStateStyle(
                        width: 30,
                        height: 30,
                        foregroundColor: DebugOverlayTheme.textDim,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          suffixIconConstraints: const BoxConstraints(
            minHeight: 30,
            maxHeight: 30,
          ),
        ),
      ),
    );
  }
}
