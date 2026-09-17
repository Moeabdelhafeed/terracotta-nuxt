// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/extensions/theme_colors_extension.dart';
import '../tooltip/global_tooltip.dart';
import 'media_picker_style.dart';

/// Reusable wrapper giving any picker slot / tile a consistent
/// cross-input affordance set:
///
///   - Mouse hover — cursor flips to click, primary-tinted overlay
///     + soft glow shadow on the edges.
///   - Keyboard focus — a solid 2.5px primary border painted on top
///     of the child, so it covers any dashed/dotted border the slot
///     might render instead of sitting alongside it.
///   - Tap — InkWell ripple painted ABOVE the child's background.
///     (The InkWell's Material is stacked on top so splashes don't
///     disappear behind an opaque tile color.)
///   - Long-press / right-click — forwarded to [onLongPress]. Enter
///     / Space also trigger [onActivate]; Delete / Backspace trigger
///     [onDelete] when supplied.
class PickerInteractable extends StatefulWidget {
  const PickerInteractable({
    super.key,
    required this.child,
    required this.onActivate,
    required this.label,
    this.onLongPress,
    this.onDelete,
    this.borderRadius,
    this.enabled = true,
    this.autofocus = false,
    this.tooltip,
  });

  final Widget child;
  final VoidCallback onActivate;

  /// What this slot IS, said out loud.
  ///
  /// REQUIRED, and required for the same reason the video and scanner
  /// controls' labels are: every one of these is a picture or a bare
  /// glyph with no text near it. This module had not one accessible
  /// name in seven thousand lines — a whole page of tiles, dots and
  /// add slots that announced nothing at all.
  ///
  /// A TOOLTIP is not a label. It is what a pointer discovers, and
  /// most of the readers who need this have no pointer.
  final String label;
  final VoidCallback? onLongPress;
  final VoidCallback? onDelete;
  final BorderRadius? borderRadius;
  final bool enabled;
  final bool autofocus;
  final String? tooltip;

  @override
  State<PickerInteractable> createState() => _PickerInteractableState();
}

class _PickerInteractableState extends State<PickerInteractable> {
  bool _hover = false;
  bool _focus = false;

  @override
  Widget build(BuildContext context) {
    // The PALETTE, not `Theme.of(context).colorScheme` — so a picker
    // tracks role, brightness and saturation like everything else in
    // the app.
    final accent = context.primaryColors.primary;
    final radius =
        widget.borderRadius ??
        BorderRadius.circular(MediaPickerDefaults.tileRadius);
    final active = _focus || _hover;

    final core = FocusableActionDetector(
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      mouseCursor: widget.enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onShowHoverHighlight: (v) {
        if (!mounted) return;
        setState(() => _hover = v);
      },
      // `onShowFocusHighlight` depends on FocusManager.highlightMode
      // and misses transitions when focus jumps via Tab / arrow keys
      // — the outgoing tile never gets a `false`. `onFocusChange`
      // fires on every focus state flip, so the old tile's ring
      // reliably clears when focus moves.
      onFocusChange: (v) {
        if (!mounted) return;
        setState(() => _focus = v);
      },
      shortcuts: <ShortcutActivator, Intent>{
        const SingleActivator(LogicalKeyboardKey.enter): const ActivateIntent(),
        const SingleActivator(LogicalKeyboardKey.space): const ActivateIntent(),
        if (widget.onDelete != null) ...{
          const SingleActivator(LogicalKeyboardKey.delete):
              const _DeleteIntent(),
          const SingleActivator(LogicalKeyboardKey.backspace):
              const _DeleteIntent(),
        },
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            if (widget.enabled) widget.onActivate();
            return null;
          },
        ),
        if (widget.onDelete != null)
          _DeleteIntent: CallbackAction<_DeleteIntent>(
            onInvoke: (_) {
              if (widget.enabled) widget.onDelete!.call();
              return null;
            },
          ),
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          borderRadius: radius,
          // Glow pulses on either hover or focus. Drawn BEHIND the
          // child via `decoration` (not `foreground`) so it extends
          // outside the slot without clipping the border visual.
          boxShadow: active
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: _focus ? 0.32 : 0.18),
                    blurRadius: _focus ? 14 : 10,
                    spreadRadius: _focus ? 1 : 0,
                  ),
                ]
              : null,
        ),
        // Paints ABOVE every child layer (including any dashed /
        // dotted border the slot draws internally) — that's the
        // trick that makes the focus ring cover the dashed border
        // completely, rather than peek around it.
        foregroundDecoration: active
            ? BoxDecoration(
                borderRadius: radius,
                border: Border.all(
                  color: _focus ? accent : accent.withValues(alpha: 0.45),
                  width: _focus ? 4 : 3,
                  // `strokeAlignCenter` splits the stroke evenly
                  // across the box edge. The DottedBorder stroke
                  // is centred too, so a centred focus ring wider
                  // than the dashed stroke (focus 4 vs dashed 2)
                  // overlaps it on BOTH the inside and outside
                  // halves — dashes disappear under the solid ring.
                  strokeAlign: BorderSide.strokeAlignCenter,
                ),
                color: _hover ? accent.withValues(alpha: 0.08) : null,
              )
            : null,
        // No outer ClipRRect — the dashed / dotted border stroke
        // on the slot bg straddles the rounded edge; clipping to
        // the container's radius shaves the outer half of those
        // dashes at the corners. The InkWell below gets its own
        // `borderRadius` which clips the ripple without touching
        // the child visuals.
        //
        // `passthrough` lets the non-positioned child (widget.child)
        // dictate the Stack size; `StackFit.expand` would force
        // tight constraints on the child, triggering "infinite
        // height" crashes inside unbounded-height parents.
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            // Visual layer — slot bg + dashed/dotted border +
            // placeholder icon. Stays passive; all gestures land
            // on the InkWell layer above so splashes don't hide
            // behind opaque tile backgrounds.
            widget.child,
            Positioned.fill(
              child: Material(
                type: MaterialType.transparency,
                // `canRequestFocus: false` + `excludeFromSemantics:
                // true` stops the InkWell from registering its own
                // focus node. Without this the tile picks up TWO
                // tab stops (outer FocusableActionDetector + inner
                // InkWell) so tabbing shows the border first, then
                // toggles the InkWell focus overlay on the second
                // hit. One focus surface only — the outer one.
                child: InkWell(
                  onTap: widget.enabled ? widget.onActivate : null,
                  onLongPress: widget.enabled ? widget.onLongPress : null,
                  borderRadius: radius,
                  canRequestFocus: false,
                  excludeFromSemantics: true,
                  splashColor: accent.withValues(alpha: 0.22),
                  highlightColor: accent.withValues(alpha: 0.10),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    // ONE node for the whole slot: a button, named, with everything
    // under it merged in. `explicitChildNodes` would hand a screen
    // reader the badge, the dots and the picture separately, which is
    // four stops for one tile.
    final named = Semantics(
      button: widget.enabled,
      enabled: widget.enabled,
      label: widget.label,
      container: true,
      child: ExcludeSemantics(child: core),
    );

    if (widget.tooltip == null) return named;
    // Manual trigger — hover still surfaces on desktop; long-press
    // doesn't fire the tooltip on mobile, keeping GlobalPopupMenu's
    // long-press gesture untouched. Tooltip already contributes a
    // Semantics node for the label, so no extra Semantics wrap is
    // needed (double-wrapping caused `!semantics.parentDataDirty`
    // assertion failures during rebuilds).
    return GlobalTooltip(
      message: widget.tooltip!,
      // Hover only: these tiles long-press to open a menu, and a
      // tooltip claiming that gesture takes the menu with it.
      trigger: TooltipTrigger.hoverOnly,
      child: named,
    );
  }
}

class _DeleteIntent extends Intent {
  const _DeleteIntent();
}
