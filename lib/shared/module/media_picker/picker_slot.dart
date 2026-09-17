import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import '../../../core/localization/strings/media_strings.dart';
import 'media_picker_style.dart';

/// The chrome every picked slot is drawn with.
///
/// Four pickers had a private copy of each of these — an empty slot, a
/// filled one and a NEW badge, three widgets times four files, all the
/// same code with a different glyph inside. The bag stopped their
/// NUMBERS drifting; it did not stop the widgets drifting, and every
/// fix in this module has had to be applied four times because of it.
///
/// What stays per-picker is the FLOW — which sheet a tap opens, what a
/// pick is validated against, what a queue does with it. What lives
/// here is what a slot LOOKS like, which is the same thing whichever
/// kind it holds.
class PickerEmptySlot extends StatelessWidget {
  const PickerEmptySlot({
    required this.style,
    required this.child,
    this.height,
    this.width,
    super.key,
  });

  final ResolvedMediaPickerStyle style;
  final Widget child;

  /// Null takes the bag's own tile height; a grid cell passes its own.
  final double? height;
  final double? width;

  @override
  Widget build(BuildContext context) => Container(
    height: height ?? style.tileHeight,
    width: width ?? style.tileWidth ?? double.infinity,
    decoration: BoxDecoration(
      borderRadius: style.tileBorderRadius,
      color: style.surfaceColor,
    ),
    child: PickerSlotFrame(style: style, child: child),
  );
}

/// The frame around an empty slot.
///
/// `dashed` was a bag field nothing read: every slot drew a
/// `DottedBorder` whatever it said. Off, the slot keeps a plain
/// hairline in the same accent — a slot with NO edge reads as a gap in
/// the layout rather than as a place to put something.
class PickerSlotFrame extends StatelessWidget {
  const PickerSlotFrame({
    required this.style,
    required this.child,
    super.key,
  });

  final ResolvedMediaPickerStyle style;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!style.dashed) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: style.tileBorderRadius,
          border: Border.all(color: style.accent, width: style.dashWidth),
        ),
        child: Material(color: Colors.transparent, child: child),
      );
    }
    return DottedBorder(
      options: RoundedRectDottedBorderOptions(
        radius: Radius.circular(style.tileRadius),
        dashPattern: MediaPickerDefaults.dashPattern,
        strokeWidth: style.dashWidth,
        color: style.accent,
      ),
      child: Material(color: Colors.transparent, child: child),
    );
  }
}

/// A slot with something IN it.
///
/// Clipped, and with no frame: the picture covers the whole slot, so a
/// stroke underneath it only shows as a fringe at the corners.
class PickerFilledSlot extends StatelessWidget {
  const PickerFilledSlot({
    required this.style,
    required this.child,
    this.height,
    this.width,
    this.clip = true,
    super.key,
  });

  final ResolvedMediaPickerStyle style;
  final Widget child;
  final double? height;
  final double? width;

  /// Whether the slot clips what is inside it.
  ///
  /// A TILE says no, and clips its picture itself. The dots sit at the
  /// tile's corners, and a corner is exactly where a round slot has no
  /// room — the `avatar` preset is a 60-point radius, so a clip round
  /// the whole thing took the remove and download buttons off with it.
  final bool clip;

  @override
  Widget build(BuildContext context) {
    final box = SizedBox(
      height: height ?? style.tileHeight,
      width: width ?? style.tileWidth ?? double.infinity,
      child: child,
    );
    if (!clip) return box;
    return ClipRRect(borderRadius: style.tileBorderRadius, child: box);
  }
}

/// The badge on a tile that has not been uploaded yet.
///
/// DECORATION — what it means is said in the tile's own semantic
/// label, because a colour says nothing out loud.
class PickerNewBadge extends StatelessWidget {
  const PickerNewBadge({required this.style, super.key});

  final ResolvedMediaPickerStyle style;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MediaPickerDefaults.badgePaddingH,
        vertical: MediaPickerDefaults.badgePaddingV,
      ),
      decoration: BoxDecoration(
        color: style.badgeColor,
        borderRadius: BorderRadius.circular(MediaPickerDefaults.badgeRadius),
      ),
      child: Text(
        MediaStrings.newBadge,
        style: TextStyle(
          color: style.badgeTextColor,
          fontSize: MediaPickerDefaults.badgeFontSize,
          fontWeight: FontWeight.w700,
          letterSpacing: MediaPickerDefaults.badgeLetterSpacing,
        ),
      ),
    ),
  );
}

/// The counterpart to [PickerNewBadge]: this one is already on the
/// server.
///
/// Drawn in the SCRIM rather than the palette's success, because it is
/// the quiet half of the pair — "NEW" is the one carrying information
/// about what is about to happen, and two coloured badges competing on
/// one row says both are.
class PickerExistingBadge extends StatelessWidget {
  const PickerExistingBadge({required this.style, super.key});

  final ResolvedMediaPickerStyle style;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MediaPickerDefaults.badgePaddingH,
        vertical: MediaPickerDefaults.badgePaddingV,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(MediaPickerDefaults.badgeRadius),
      ),
      child: Text(
        MediaStrings.existingBadge,
        style: const TextStyle(
          color: Colors.white,
          fontSize: MediaPickerDefaults.badgeFontSize,
          fontWeight: FontWeight.w700,
          letterSpacing: MediaPickerDefaults.badgeLetterSpacing,
        ),
      ),
    ),
  );
}

/// Moves a tile without a drag.
///
/// Reordering was drag-only: no keyboard, no screen reader, no pointer
/// for anyone who cannot hold and drag. A `CustomSemanticsAction` is
/// what assistive tech offers for exactly this, and the same two
/// callbacks answer a keyboard.
///
/// It wraps rather than replaces the drag — the drag is still the
/// fastest way to do it, and this is the way that always works.
class PickerReorderable extends StatelessWidget {
  const PickerReorderable({
    required this.child,
    required this.label,
    required this.canMoveBack,
    required this.canMoveForward,
    required this.onMoveBack,
    required this.onMoveForward,
    super.key,
  });

  final Widget child;

  /// What the tile already says about itself — the actions are added
  /// to that node rather than making a second one.
  final String label;

  final bool canMoveBack;
  final bool canMoveForward;
  final VoidCallback onMoveBack;
  final VoidCallback onMoveForward;

  @override
  Widget build(BuildContext context) {
    // The direction names are READING order, not screen order:
    // "move left" in an Arabic layout moves the tile the way the
    // reader means, and `Directionality` is what knows which that is.
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final backLabel = rtl ? MediaStrings.moveRight : MediaStrings.moveLeft;
    final forwardLabel = rtl ? MediaStrings.moveLeft : MediaStrings.moveRight;

    return Semantics(
      label: label,
      customSemanticsActions: {
        if (canMoveBack) CustomSemanticsAction(label: backLabel): onMoveBack,
        if (canMoveForward)
          CustomSemanticsAction(label: forwardLabel): onMoveForward,
      },
      child: FocusableActionDetector(
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.arrowLeft, alt: true):
              _MoveBackIntent(),
          SingleActivator(LogicalKeyboardKey.arrowRight, alt: true):
              _MoveForwardIntent(),
        },
        actions: <Type, Action<Intent>>{
          _MoveBackIntent: CallbackAction<_MoveBackIntent>(
            onInvoke: (_) {
              if (canMoveBack) onMoveBack();
              return null;
            },
          ),
          _MoveForwardIntent: CallbackAction<_MoveForwardIntent>(
            onInvoke: (_) {
              if (canMoveForward) onMoveForward();
              return null;
            },
          ),
        },
        child: child,
      ),
    );
  }
}

class _MoveBackIntent extends Intent {
  const _MoveBackIntent();
}

class _MoveForwardIntent extends Intent {
  const _MoveForwardIntent();
}
