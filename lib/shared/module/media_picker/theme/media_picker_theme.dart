import 'package:flutter/material.dart';

import '../../../../core/extensions/theme_colors_extension.dart';
import '../media_picker_style.dart';

/// App-wide defaults for the picker family.
///
/// The rebrand hook: set the tile corner, the badge, and which
/// affordances every picker in the app offers, once, here — instead of
/// at each of the thirty-odd parameters each picker used to take.
@immutable
class GlobalMediaPickerTheme extends ThemeExtension<GlobalMediaPickerTheme> {
  const GlobalMediaPickerTheme({this.style});

  final MediaPickerStyle? style;

  static GlobalMediaPickerTheme? maybeOf(BuildContext context) =>
      Theme.of(context).extension<GlobalMediaPickerTheme>();

  @override
  GlobalMediaPickerTheme copyWith({MediaPickerStyle? style}) =>
      GlobalMediaPickerTheme(style: style ?? this.style);

  @override
  GlobalMediaPickerTheme lerp(
    ThemeExtension<GlobalMediaPickerTheme>? other,
    double t,
  ) {
    if (other is! GlobalMediaPickerTheme) return this;
    // A style is a bag of independent decisions, not a value with a
    // midpoint — half a `reorderable` means nothing. It SNAPS at the
    // halfway mark, which is what every other bag in this app does.
    return t < 0.5 ? this : other;
  }
}

/// Turns a caller's bag into one with every question answered.
extension MediaPickerStyleResolve on MediaPickerStyle {
  /// `caller > GlobalMediaPickerTheme.style > MediaPickerStyle.defaults`,
  /// then colours from the palette.
  ///
  /// The one colour that does NOT come from the palette is the dot
  /// scrim: those dots float over whatever was photographed, and a
  /// surface colour disappears into half of them.
  ResolvedMediaPickerStyle resolve(BuildContext context) {
    final merged = MediaPickerStyle.defaults
        .mergedWith(GlobalMediaPickerTheme.maybeOf(context)?.style)
        .mergedWith(this);

    final primary = context.primaryColors;
    final background = context.backgroundColors;
    final text = context.textColors;
    final status = context.statusColors;
    final icons = context.iconColors;

    return ResolvedMediaPickerStyle(
      accent: merged.accent ?? primary.primary,
      surfaceColor: merged.surfaceColor ?? background.container,
      hintColor: merged.hintColor ?? text.secondary,
      removeColor: merged.removeColor ?? status.error,
      badgeColor: merged.badgeColor ?? status.success,
      badgeTextColor: merged.badgeTextColor ?? icons.onPrimary,
      dotScrim: merged.dotScrim ?? MediaPickerDefaults.dotScrim,
      tileRadius: merged.tileRadius ?? MediaPickerDefaults.tileRadius,
      tileHeight: merged.tileHeight ?? MediaPickerDefaults.tileHeight,
      tileWidth: merged.tileWidth,
      addTileSize: merged.addTileSize ?? MediaPickerDefaults.addTileSize,
      cellSize: merged.cellSize ?? MediaPickerDefaults.cellSize,
      rowHeight: merged.rowHeight ?? MediaPickerDefaults.rowHeight,
      tileGap: merged.tileGap ?? MediaPickerDefaults.tileGap,
      dashed: merged.dashed ?? true,
      dashWidth: merged.dashWidth ?? MediaPickerDefaults.dashWidth,
      placeholderIconSize:
          merged.placeholderIconSize ?? MediaPickerDefaults.placeholderIconSize,
      addIconSize: merged.addIconSize ?? MediaPickerDefaults.addIconSize,
      hintFontSize: merged.hintFontSize ?? MediaPickerDefaults.hintFontSize,
      showNewBadge: merged.showNewBadge ?? true,
      showExistingBadge: merged.showExistingBadge ?? false,
      showRemove: merged.showRemove ?? true,
      allowCamera: merged.allowCamera ?? true,
      allowClipboard: merged.allowClipboard ?? true,
      reorderable: merged.reorderable ?? true,
      useRecentCache: merged.useRecentCache ?? true,
      compress: merged.compress ?? true,
      enableHaptic: merged.enableHaptic ?? true,
    );
  }
}
