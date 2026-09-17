import 'package:flutter/material.dart';

/// Every hard-coded number the pickers draw with.
///
/// They were spread across four widget files — `circular(14)` eight
/// times, a `0.55` scrim seven times, three different dot sizes — and
/// each copy was free to drift from the others. A tile in the image
/// picker and a tile in the file picker are the same tile, and this is
/// what makes that true rather than a coincidence.
abstract final class MediaPickerDefaults {
  // ─── Tiles ────────────────────────────────────────────────
  /// A slot's corner. The commonest number in the module by far.
  static const tileRadius = 14.0;

  /// How tall a slot is when the caller does not say.
  static const tileHeight = 150.0;

  /// The square "add" tile in a grid or a row.
  static const addTileSize = 96.0;

  /// A small thumbnail — a recents strip, a chip-sized preview.
  ///
  /// Rounder than a full tile would look at that size, and named so
  /// the recents overlay and the pickers cannot drift apart.
  static const thumbRadius = 10.0;

  /// The badge or dot that sits ON a small thumbnail.
  static const thumbDotSize = 22.0;

  /// One CELL of a grid or a horizontal row.
  ///
  /// Not the same number as [tileHeight], and the difference matters:
  /// a single full-width slot is a banner, a cell in a wall of them is
  /// a square. Reading the single slot's height for a grid cell made
  /// every cell half again as tall as its width.
  static const cellSize = 100.0;

  /// Below this, a placeholder shows its GLYPH alone.
  ///
  /// Icon plus a gap plus two lines of hint does not fit a 72-point
  /// composer tile, and a `Column` that does not fit is 18 pixels of
  /// yellow-and-black stripes.
  static const hintMinHeight = 108.0;

  /// Between tiles, both ways.
  static const tileGap = 8.0;

  /// The dashed stroke around an EMPTY slot.
  static const dashWidth = 2.0;
  static const dashPattern = <double>[10, 5];

  // ─── The dots that sit ON a tile ──────────────────────────
  /// Remove, download, copy. They are round, they are small, and they
  /// sit on a picture — so their own scrim is what makes them legible
  /// rather than the palette.
  static const dotPadding = 4.0;
  static const dotIconSize = 14.0;

  /// Large enough to be a circle whatever the padding.
  static const dotRadius = 40.0;

  /// The disc behind a dot, over arbitrary pixels.
  static const dotScrim = Color(0x8C000000);

  // ─── Badges ───────────────────────────────────────────────
  static const badgeRadius = 4.0;
  static const badgePaddingH = 6.0;
  static const badgePaddingV = 2.0;
  static const badgeFontSize = 9.0;
  static const badgeLetterSpacing = 0.5;

  // ─── Placeholder ──────────────────────────────────────────
  static const placeholderIconSize = 40.0;
  static const addIconSize = 28.0;
  static const hintFontSize = 13.0;
  static const hintGap = 6.0;

  // ─── Rows (the file picker's layout) ──────────────────────
  static const rowIconSize = 22.0;
  static const rowHeight = 56.0;

  /// One choice in a picker SHEET.
  ///
  /// The container's own tile floor is 48 and its padding 16, which
  /// made every choice eighty points tall — four of them filled a
  /// phone. This is the touch target and nothing more; the padding
  /// comes down to match.
  static const sheetRowMinHeight = 48.0;

  static const rowGap = 6.0;

  // ─── The error line under a picker ────────────────────────
  static const errorIconSize = 14.0;
  static const errorFontSize = 12.0;
  static const errorGap = 4.0;
  static const errorTopGap = 6.0;

  // ─── Upload progress ──────────────────────────────────────
  static const progressStroke = 2.0;
  static const progressSize = 28.0;

  /// What a tile is dimmed by while its upload runs.
  static const busyScrim = Color(0x40000000);

  // ─── Spacing ──────────────────────────────────────────────
  static const gapXs = 4.0;
  static const gapSm = 6.0;
  static const gapMd = 8.0;
  static const gapLg = 12.0;
}

/// How the pickers LOOK and which affordances they offer.
///
/// Every field is nullable so the three sources layer without a
/// default clobbering a theme: `caller > GlobalMediaPickerTheme.style >
/// MediaPickerStyle.defaults`. Resolved once per build into a
/// [ResolvedMediaPickerStyle].
///
/// There was no bag at all before this. `GlobalImagePicker` took
/// **thirty-three** parameters and forwarded every one, so an app that
/// wanted its own tile corner said so at every call site and could
/// never say it once — and the file, video and attachment pickers each
/// carried their own copy of the same numbers.
@immutable
class MediaPickerStyle {
  const MediaPickerStyle({
    this.accent,
    this.surfaceColor,
    this.hintColor,
    this.removeColor,
    this.badgeColor,
    this.badgeTextColor,
    this.dotScrim,
    this.tileRadius,
    this.tileHeight,
    this.tileWidth,
    this.addTileSize,
    this.cellSize,
    this.rowHeight,
    this.tileGap,
    this.dashed,
    this.dashWidth,
    this.placeholderIconSize,
    this.addIconSize,
    this.hintFontSize,
    this.showNewBadge,
    this.showExistingBadge,
    this.showRemove,
    this.allowCamera,
    this.allowClipboard,
    this.reorderable,
    this.useRecentCache,
    this.compress,
    this.enableHaptic,
  });

  /// The floor. Colours are absent on purpose — they resolve from the
  /// palette at build time so they track role, brightness and
  /// saturation, which a constant cannot.
  static const MediaPickerStyle defaults = MediaPickerStyle(
    tileRadius: MediaPickerDefaults.tileRadius,
    tileHeight: MediaPickerDefaults.tileHeight,
    addTileSize: MediaPickerDefaults.addTileSize,
    cellSize: MediaPickerDefaults.cellSize,
    rowHeight: MediaPickerDefaults.rowHeight,
    tileGap: MediaPickerDefaults.tileGap,
    dashed: true,
    dashWidth: MediaPickerDefaults.dashWidth,
    placeholderIconSize: MediaPickerDefaults.placeholderIconSize,
    addIconSize: MediaPickerDefaults.addIconSize,
    hintFontSize: MediaPickerDefaults.hintFontSize,
    showNewBadge: true,
    showExistingBadge: false,
    showRemove: true,
    allowCamera: true,
    allowClipboard: true,
    reorderable: true,
    useRecentCache: true,
    compress: true,
    enableHaptic: true,
  );

  // ─── Presets ──────────────────────────────────────────────
  //
  // A preset is a NAMED BAG. Everything it decides is what the bag
  // already carries, so it merges with a theme and loses to a
  // per-call override like any other bag.

  /// One square, for a face.
  ///
  /// No badge and no reordering — there is one slot, so "new" is
  /// obvious and there is nothing to reorder. The camera leads,
  /// because that is where a profile picture comes from.
  static const MediaPickerStyle avatar = MediaPickerStyle(
    tileHeight: 120,
    tileWidth: 120,
    tileRadius: 60,
    cellSize: 120,
    showNewBadge: false,
    reorderable: false,
    allowCamera: true,
  );

  /// A row of attachments under a message box.
  ///
  /// Small tiles, tight gaps, no dashed frame: the composer around it
  /// already has a border, and a second one inside it reads as a
  /// field inside a field.
  static const MediaPickerStyle composer = MediaPickerStyle(
    tileHeight: 72,
    tileWidth: 72,
    tileRadius: 10,
    tileGap: 6,
    dashed: false,
    addTileSize: 72,
    cellSize: 72,
    addIconSize: 22,
  );

  /// A form field that has to look like the fields around it.
  ///
  /// The same corner the text fields use, a full-width slot, and the
  /// hint under the glyph — this is the one that sits in a column of
  /// inputs and must not look like a photo gallery.
  static const MediaPickerStyle formField = MediaPickerStyle(
    tileHeight: 132,
    tileRadius: 12,
    dashed: true,
  );

  /// Played over a picture: the accent for the dashed frame, the add
  /// glyph and the progress ring. Falls back to the palette primary.
  final Color? accent;

  /// Behind an empty slot. Falls back to the palette's container.
  final Color? surfaceColor;

  /// The hint under the placeholder glyph.
  final Color? hintColor;

  /// The remove dot. Falls back to the palette's error.
  final Color? removeColor;

  /// The "NEW" badge. Falls back to the palette's success.
  final Color? badgeColor;

  /// What is written ON that badge.
  final Color? badgeTextColor;

  /// The disc behind a dot that sits on a PICTURE.
  ///
  /// Deliberately not a palette colour: a download dot floats over
  /// whatever was photographed, and a surface colour disappears into
  /// half of them. Same rule the video controls follow.
  final Color? dotScrim;

  final double? tileRadius;
  final double? tileHeight;

  /// A slot's width. Null means "as wide as it is given" — which is
  /// what a single full-width picker wants.
  final double? tileWidth;

  final double? addTileSize;

  /// One cell of a grid or a horizontal row. See
  /// [MediaPickerDefaults.cellSize] — it is deliberately not
  /// [tileHeight].
  final double? cellSize;

  /// One ROW of the file picker's list layout.
  ///
  /// A row is a LINE — an icon, a name, a remove dot. It was drawn at
  /// [tileHeight], which is the height of a full-width image slot, so
  /// a single file sat in a hundred and fifty points of empty box.
  final double? rowHeight;

  final double? tileGap;

  /// Whether an EMPTY slot is drawn with a dashed frame.
  ///
  /// It is the one mark that says "this is a place to put something"
  /// rather than "this is an empty box", so it is on — but a picker
  /// inside a field that already has a border wants it off.
  final bool? dashed;

  final double? dashWidth;
  final double? placeholderIconSize;
  final double? addIconSize;
  final double? hintFontSize;

  /// The badge on a freshly-picked tile, which says what will upload.
  final bool? showNewBadge;

  /// The matching badge on a tile that is ALREADY on the server.
  ///
  /// Off everywhere by default: on a picker that is only ever filled
  /// from the device there is no "already" to distinguish, and on a
  /// one-slot avatar it labels the only thing on screen. Turn it on
  /// where a reader is adding to a set they can see — then "NEW" has
  /// something to be new BESIDE.
  final bool? showExistingBadge;

  /// The remove dot on a filled tile.
  final bool? showRemove;

  /// Offer the camera beside the gallery.
  final bool? allowCamera;

  /// Offer "paste" when the clipboard holds an image.
  final bool? allowClipboard;

  /// Drag to reorder filled tiles.
  final bool? reorderable;

  /// Offer previously-picked items when the picker is opened.
  final bool? useRecentCache;

  /// Re-encode picked images before handing them back.
  final bool? compress;

  /// A tick on pick, remove and reorder.
  final bool? enableHaptic;

  /// [other] wins field by field. Null means "did not say", which is
  /// what lets a caller override one thing without restating a theme.
  MediaPickerStyle mergedWith(MediaPickerStyle? other) {
    if (other == null) return this;
    return MediaPickerStyle(
      accent: other.accent ?? accent,
      surfaceColor: other.surfaceColor ?? surfaceColor,
      hintColor: other.hintColor ?? hintColor,
      removeColor: other.removeColor ?? removeColor,
      badgeColor: other.badgeColor ?? badgeColor,
      badgeTextColor: other.badgeTextColor ?? badgeTextColor,
      dotScrim: other.dotScrim ?? dotScrim,
      tileRadius: other.tileRadius ?? tileRadius,
      tileHeight: other.tileHeight ?? tileHeight,
      tileWidth: other.tileWidth ?? tileWidth,
      addTileSize: other.addTileSize ?? addTileSize,
      cellSize: other.cellSize ?? cellSize,
      rowHeight: other.rowHeight ?? rowHeight,
      tileGap: other.tileGap ?? tileGap,
      dashed: other.dashed ?? dashed,
      dashWidth: other.dashWidth ?? dashWidth,
      placeholderIconSize: other.placeholderIconSize ?? placeholderIconSize,
      addIconSize: other.addIconSize ?? addIconSize,
      hintFontSize: other.hintFontSize ?? hintFontSize,
      showNewBadge: other.showNewBadge ?? showNewBadge,
      showExistingBadge: other.showExistingBadge ?? showExistingBadge,
      showRemove: other.showRemove ?? showRemove,
      allowCamera: other.allowCamera ?? allowCamera,
      allowClipboard: other.allowClipboard ?? allowClipboard,
      reorderable: other.reorderable ?? reorderable,
      useRecentCache: other.useRecentCache ?? useRecentCache,
      compress: other.compress ?? compress,
      enableHaptic: other.enableHaptic ?? enableHaptic,
    );
  }

  MediaPickerStyle copyWith({
    Color? accent,
    Color? surfaceColor,
    Color? hintColor,
    Color? removeColor,
    Color? badgeColor,
    Color? badgeTextColor,
    Color? dotScrim,
    double? tileRadius,
    double? tileHeight,
    double? tileWidth,
    double? addTileSize,
    double? cellSize,
    double? rowHeight,
    double? tileGap,
    bool? dashed,
    double? dashWidth,
    double? placeholderIconSize,
    double? addIconSize,
    double? hintFontSize,
    bool? showNewBadge,
    bool? showExistingBadge,
    bool? showRemove,
    bool? allowCamera,
    bool? allowClipboard,
    bool? reorderable,
    bool? useRecentCache,
    bool? compress,
    bool? enableHaptic,
  }) => MediaPickerStyle(
    accent: accent ?? this.accent,
    surfaceColor: surfaceColor ?? this.surfaceColor,
    hintColor: hintColor ?? this.hintColor,
    removeColor: removeColor ?? this.removeColor,
    badgeColor: badgeColor ?? this.badgeColor,
    badgeTextColor: badgeTextColor ?? this.badgeTextColor,
    dotScrim: dotScrim ?? this.dotScrim,
    tileRadius: tileRadius ?? this.tileRadius,
    tileHeight: tileHeight ?? this.tileHeight,
    tileWidth: tileWidth ?? this.tileWidth,
    addTileSize: addTileSize ?? this.addTileSize,
    cellSize: cellSize ?? this.cellSize,
    rowHeight: rowHeight ?? this.rowHeight,
    tileGap: tileGap ?? this.tileGap,
    dashed: dashed ?? this.dashed,
    dashWidth: dashWidth ?? this.dashWidth,
    placeholderIconSize: placeholderIconSize ?? this.placeholderIconSize,
    addIconSize: addIconSize ?? this.addIconSize,
    hintFontSize: hintFontSize ?? this.hintFontSize,
    showNewBadge: showNewBadge ?? this.showNewBadge,
    showExistingBadge: showExistingBadge ?? this.showExistingBadge,
    showRemove: showRemove ?? this.showRemove,
    allowCamera: allowCamera ?? this.allowCamera,
    allowClipboard: allowClipboard ?? this.allowClipboard,
    reorderable: reorderable ?? this.reorderable,
    useRecentCache: useRecentCache ?? this.useRecentCache,
    compress: compress ?? this.compress,
    enableHaptic: enableHaptic ?? this.enableHaptic,
  );

  @override
  bool operator ==(Object other) =>
      other is MediaPickerStyle &&
      other.accent == accent &&
      other.surfaceColor == surfaceColor &&
      other.hintColor == hintColor &&
      other.removeColor == removeColor &&
      other.badgeColor == badgeColor &&
      other.badgeTextColor == badgeTextColor &&
      other.dotScrim == dotScrim &&
      other.tileRadius == tileRadius &&
      other.tileHeight == tileHeight &&
      other.tileWidth == tileWidth &&
      other.addTileSize == addTileSize &&
      other.cellSize == cellSize &&
      other.rowHeight == rowHeight &&
      other.tileGap == tileGap &&
      other.dashed == dashed &&
      other.dashWidth == dashWidth &&
      other.placeholderIconSize == placeholderIconSize &&
      other.addIconSize == addIconSize &&
      other.hintFontSize == hintFontSize &&
      other.showNewBadge == showNewBadge &&
      other.showExistingBadge == showExistingBadge &&
      other.showRemove == showRemove &&
      other.allowCamera == allowCamera &&
      other.allowClipboard == allowClipboard &&
      other.reorderable == reorderable &&
      other.useRecentCache == useRecentCache &&
      other.compress == compress &&
      other.enableHaptic == enableHaptic;

  @override
  int get hashCode => Object.hashAll([
    accent,
    surfaceColor,
    hintColor,
    removeColor,
    badgeColor,
    badgeTextColor,
    dotScrim,
    tileRadius,
    tileHeight,
    tileWidth,
    addTileSize,
    cellSize,
    rowHeight,
    tileGap,
    dashed,
    dashWidth,
    placeholderIconSize,
    addIconSize,
    hintFontSize,
    showNewBadge,
    showExistingBadge,
    showRemove,
    allowCamera,
    allowClipboard,
    reorderable,
    useRecentCache,
    compress,
    enableHaptic,
  ]);
}

/// A [MediaPickerStyle] with every question answered.
///
/// Built once per build by `style.resolve(context)`. Nothing
/// downstream takes a nullable field or reaches for `Theme.of` — the
/// four pickers used to answer these themselves, in about a hundred
/// and fifty places between them.
@immutable
class ResolvedMediaPickerStyle {
  const ResolvedMediaPickerStyle({
    required this.accent,
    required this.surfaceColor,
    required this.hintColor,
    required this.removeColor,
    required this.badgeColor,
    required this.badgeTextColor,
    required this.dotScrim,
    required this.tileRadius,
    required this.tileHeight,
    required this.addTileSize,
    required this.cellSize,
    required this.rowHeight,
    required this.tileGap,
    required this.dashed,
    required this.dashWidth,
    required this.placeholderIconSize,
    required this.addIconSize,
    required this.hintFontSize,
    required this.showNewBadge,
    required this.showExistingBadge,
    required this.showRemove,
    required this.allowCamera,
    required this.allowClipboard,
    required this.reorderable,
    required this.useRecentCache,
    required this.compress,
    required this.enableHaptic,
    this.tileWidth,
  });

  final Color accent;
  final Color surfaceColor;
  final Color hintColor;
  final Color removeColor;
  final Color badgeColor;
  final Color badgeTextColor;
  final Color dotScrim;

  final double tileRadius;
  final double tileHeight;

  /// Null means "as wide as it is given".
  final double? tileWidth;

  final double addTileSize;

  /// One cell of a grid or a horizontal row — a SQUARE by default,
  /// where [tileHeight] is a full-width banner.
  final double cellSize;

  /// One ROW of the file picker's list layout — a line, not a box.
  final double rowHeight;

  final double tileGap;
  final bool dashed;
  final double dashWidth;
  final double placeholderIconSize;
  final double addIconSize;
  final double hintFontSize;

  final bool showNewBadge;
  final bool showExistingBadge;
  final bool showRemove;
  final bool allowCamera;
  final bool allowClipboard;
  final bool reorderable;
  final bool useRecentCache;
  final bool compress;
  final bool enableHaptic;

  /// The corner, as a `BorderRadius`, which is what nearly every call
  /// site actually wants.
  BorderRadius get tileBorderRadius => BorderRadius.circular(tileRadius);

  /// A context-free bag, for the moment before the theme is readable.
  ///
  /// A `late` resolved field is the trap the video module shipped
  /// once: something reads the bag before `didChangeDependencies` and
  /// every widget throws on its first frame.
  static const ResolvedMediaPickerStyle fallback = ResolvedMediaPickerStyle(
    accent: Color(0xFF3B5BFE),
    surfaceColor: Color(0xFFEFEFEF),
    hintColor: Color(0xFF767676),
    removeColor: Color(0xFFD32F2F),
    badgeColor: Color(0xFF2E7D32),
    badgeTextColor: Colors.white,
    dotScrim: MediaPickerDefaults.dotScrim,
    tileRadius: MediaPickerDefaults.tileRadius,
    tileHeight: MediaPickerDefaults.tileHeight,
    addTileSize: MediaPickerDefaults.addTileSize,
    cellSize: MediaPickerDefaults.cellSize,
    rowHeight: MediaPickerDefaults.rowHeight,
    tileGap: MediaPickerDefaults.tileGap,
    dashed: true,
    dashWidth: MediaPickerDefaults.dashWidth,
    placeholderIconSize: MediaPickerDefaults.placeholderIconSize,
    addIconSize: MediaPickerDefaults.addIconSize,
    hintFontSize: MediaPickerDefaults.hintFontSize,
    showNewBadge: true,
    showExistingBadge: false,
    showRemove: true,
    allowCamera: true,
    allowClipboard: true,
    reorderable: true,
    useRecentCache: true,
    compress: true,
    enableHaptic: true,
  );
}
