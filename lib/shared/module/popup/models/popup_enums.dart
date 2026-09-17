/// Enum types for [GlobalPopup] — placement, trigger, animation.
library;

/// Entrance animation for an [GlobalPopupController]'s overlay.
enum GlobalPopupAnimation {
  /// Clip-reveal expanding from the anchor edge + fade. The popup
  /// content paints at its full final size from frame 1, then a
  /// rectangular reveal mask sweeps across to expose it.
  reveal,

  /// True scale animation — popup grows from 0 along the axis facing
  /// the anchor (anchored to that edge via `Transform.scale`) while
  /// opacity fades in. Content paints at full size from frame 1; the
  /// scale transform is what produces the growth, so the surface
  /// "expands" out of the anchor rather than being unveiled.
  expand,

  /// Scale-from-anchor + fade.
  scale,

  /// Plain opacity fade.
  fade,

  /// No animation.
  none,
}

/// When the [GlobalPopup] widget should open.
enum GlobalPopupTrigger {
  /// Caller drives via the controller. No gesture wiring.
  manual,

  /// Tap the anchor → toggle.
  tap,

  /// Long-press the anchor → open.
  longPress,

  /// Pointer hover (web/desktop) → open. Leaves close on hover-out (with
  /// optional delay configured by `GlobalPopupOptions.hoverCloseDelay`).
  hover,

  /// Hover on a pointer device, long-press on a touch one — BOTH wired
  /// at once.
  ///
  /// This is what a tooltip needs and no single trigger provides: a
  /// touch screen never fires hover, and a mouse user should not have
  /// to hold the button down. Material's own `Tooltip` picks the same
  /// way.
  hoverOrLongPress,

  /// Anchor's focus → open. For text-field-like anchors.
  focus,

  /// Right-click / secondary-tap → open (context menus).
  secondaryTap,
}

/// 13 anchor-relative placements + `auto` (engine picks bottomStart /
/// topStart based on available space + flip rules) + `atTap` (anchored
/// at the last pointer-down position).
enum GlobalPopupPlacement {
  auto,

  /// Anchored at the last pointer-down position. Useful with `tap`
  /// trigger when the anchor widget is wide and you want the menu
  /// centered on the tap point. Falls back to `bottomStart` when no
  /// pointer position is available.
  atTap,

  topStart,
  top,
  topEnd,
  bottomStart,
  bottom,
  bottomEnd,
  startTop,
  start,
  startBottom,
  endTop,
  end,
  endBottom,
}
