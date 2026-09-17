import 'package:flutter/material.dart';

import '../../../core/constants/colors/text_colors.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../container/global_container.dart';
import '../sheet/global_sheet.dart';
import '../sheet/sheet_geometry.dart';
import 'media_picker_style.dart';
import 'theme/media_picker_theme.dart';

/// One choice in a picker sheet — gallery, camera, clipboard, a kind.
///
/// A VALUE, not a widget: the list decides the spacing between rows,
/// and a widget would have to be rebuilt with a "you are the last one"
/// flag, which is a second place to remember every field a row grows.
@immutable
class PickerSheetChoice {
  const PickerSheetChoice({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.enabled = true,
    this.destructive = false,
  });

  final IconData icon;
  final String label;

  /// What the choice actually DOES, when the label alone leaves it
  /// ambiguous — "Camera" is a place, "take a new photo" is the
  /// action. Null keeps the row a single line.
  final String? subtitle;

  /// Null with [enabled] false is a row that is SHOWN but cannot be
  /// taken — "Clipboard (empty)", which says why the option is there
  /// and why it will not answer.
  final VoidCallback? onTap;

  final bool enabled;

  /// Cancel, and anything else that undoes rather than proceeds.
  final bool destructive;
}

/// The rows of a picker sheet, as one list.
///
/// It exists because there were THREE of these, in three files, each
/// with its own idea of the shape: the house container surface (which
/// carries a shadow), a 14-point corner inside a 24-point sheet, and a
/// different gap apiece. Stacked in a floating sheet they read as a
/// pile of cards that happen to be in a sheet rather than as one list.
///
/// Three rules, stated once:
///
/// - **No elevation.** A sheet is already a raised surface; a card
///   raised again inside it is two shadows for one thing. `shadow:
///   const []` is how the container module spells flat.
/// - **The corner is CONCENTRIC** with the sheet's — inner = outer
///   minus the inset it sits in — so the two curves agree instead of
///   fighting.
/// - **One gap, BETWEEN rows only.** The sheet's own padding is the
///   space under the last one; three sheets each had a stray eight
///   points there.
class PickerSheetRows extends StatelessWidget {
  const PickerSheetRows({required this.choices, super.key});

  final List<PickerSheetChoice> choices;

  @override
  Widget build(BuildContext context) {
    final rs = const MediaPickerStyle().resolve(context);
    final sheet = const SheetStyle(floating: true).resolve(context);
    final text = context.textColors;
    final radius = SheetGeometry.rowRadius(
      context,
      rs: sheet,
      inset: sheet.contentPadding.horizontal / 2,
    );

    return Material(
      // `GlobalContainer`'s ink needs a Material ancestor; the sheet
      // renders a plain container, so without this the splash is
      // swallowed silently.
      color: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < choices.length; i++) ...[
            if (i > 0) SizedBox(height: rs.tileGap),
            _row(choices[i], radius: radius, rs: rs, text: text),
          ],
        ],
      ),
    );
  }

  Widget _row(
    PickerSheetChoice choice, {
    required BorderRadius radius,
    required ResolvedMediaPickerStyle rs,
    required TextColors text,
  }) {
    final foreground = !choice.enabled
        ? text.disabled
        : (choice.destructive ? rs.removeColor : text.primary);

    return GlobalContainer.tile(
      enabled: choice.enabled,
      onTap: choice.enabled ? choice.onTap : null,
      leading: Icon(choice.icon, color: foreground),
      titleWidget: Text(
        choice.label,
        style: TextStyle(color: foreground, fontWeight: FontWeight.w600),
      ),
      subtitleWidget: choice.subtitle == null
          ? null
          : Text(
              choice.subtitle!,
              style: TextStyle(
                color: text.secondary,
                fontSize: MediaPickerDefaults.hintFontSize,
              ),
            ),
      style: ContainerStyle(
        shadow: const [],
        borderRadius: radius,
        // A row in a SHEET is a line, not a card. The container's own
        // 16-point inset plus its 48-point floor made every choice
        // eighty points tall, so four of them filled a phone.
        padding: const EdgeInsets.symmetric(
          horizontal: MediaPickerDefaults.gapLg,
          vertical: MediaPickerDefaults.gapMd,
        ),
        // The touch target is the floor, and it stays: the row is
        // still a finger-sized thing to hit.
        tileMinHeight: MediaPickerDefaults.sheetRowMinHeight,
      ),
    );
  }
}
