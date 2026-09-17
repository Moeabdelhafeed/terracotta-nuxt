import 'package:flutter/material.dart';

import '../../../core/localization/strings/common_strings.dart';
import '../../../core/localization/strings/media_strings.dart';
import '../icon/global_icon.dart';
import 'media_picker_style.dart';
import 'picker_interactable.dart';

/// What a dot on a tile DOES.
///
/// Named rather than passed as an icon plus a colour plus a label,
/// because the four pickers each spelled the same four dots out by
/// hand — twelve copies between them, and the remove dot in one was
/// the only one that was red.
enum PickerDotAction { remove, download, copy, trim }

/// A round action on a picked tile: remove, download, copy, trim.
///
/// One widget, four call sites apiece across four pickers. Every one
/// of them was the same twelve lines with a different glyph, which is
/// how the download dot ended up a bare `GestureDetector` with no name
/// while the two beside it were keyboard-reachable.
///
/// Its disc is the SCRIM, not a palette surface — these float over
/// whatever was photographed. The exception is [PickerDotAction.remove],
/// which is destructive and wears the palette's error colour, because
/// that is the one a reader must not hit by accident.
class PickerActionDot extends StatelessWidget {
  const PickerActionDot({
    required this.action,
    required this.style,
    required this.onTap,
    this.copyLabel,
    super.key,
  });

  final PickerDotAction action;
  final ResolvedMediaPickerStyle style;
  final VoidCallback onTap;

  /// "Copy image" / "Copy video" / "Copy file" — the one label that
  /// differs by picker.
  final String? copyLabel;

  IconData get _icon => switch (action) {
    PickerDotAction.remove => Icons.close_rounded,
    PickerDotAction.download => Icons.download_rounded,
    PickerDotAction.copy => Icons.content_copy_rounded,
    PickerDotAction.trim => Icons.content_cut_rounded,
  };

  String get _label => switch (action) {
    PickerDotAction.remove => MediaStrings.removeItem,
    PickerDotAction.download => MediaStrings.downloadItem,
    PickerDotAction.copy => copyLabel ?? CommonStrings.copy,
    PickerDotAction.trim => MediaStrings.trimVideo,
  };

  Color _background() =>
      action == PickerDotAction.remove ? style.removeColor : style.dotScrim;

  @override
  Widget build(BuildContext context) => PickerInteractable(
    onActivate: onTap,
    label: _label,
    tooltip: _label,
    borderRadius: BorderRadius.circular(MediaPickerDefaults.dotRadius),
    child: GlobalIcon.circle(
      _icon,
      size: MediaPickerDefaults.dotIconSize,
      containerSize:
          MediaPickerDefaults.dotIconSize + MediaPickerDefaults.dotPadding * 2,
      color: style.badgeTextColor,
      backgroundColor: _background(),
    ),
  );
}
