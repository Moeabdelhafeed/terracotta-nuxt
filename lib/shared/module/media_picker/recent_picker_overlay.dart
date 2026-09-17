import 'dart:async';
import 'dart:io';
// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import '../../../core/constants/enums/media/image_type.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/strings/common_strings.dart';
import '../../../core/localization/strings/media_strings.dart';
import '../../../data/services/media/video_thumbnail_service.dart';
import '../buttons/global_filled_button.dart';
import '../buttons/global_icon_button.dart';
import '../icon/global_icon.dart';
import '../image/index.dart';
import '../sheet/global_sheet.dart';
import 'media_picker_models.dart';
import 'media_picker_style.dart';
import 'picker_action_dot.dart';
import 'picker_sheet_row.dart';
import 'theme/media_picker_theme.dart';

/// Result of the combined recent-picks + source-picker overlay.
/// Exactly one of [cached] / [cachedItems] / [source] is non-null
/// when the sheet completes; all null on dismiss/cancel.
class RecentOverlayResult {
  const RecentOverlayResult._({
    this.cached,
    this.cachedKind,
    this.cachedItems,
    this.source,
  });

  const RecentOverlayResult.cached(PickerItem item, AttachmentKind kind)
    : this._(cached: item, cachedKind: kind);

  /// Multi-select confirmation — caller gets every tapped tile at
  /// once, each paired with its [AttachmentKind].
  const RecentOverlayResult.cachedMulti(
    List<(PickerItem, AttachmentKind)> items,
  ) : this._(cachedItems: items);

  const RecentOverlayResult.source(MediaPickerSourceOption src)
    : this._(source: src);

  /// A user-tapped cached item (single-select mode).
  final PickerItem? cached;

  /// The [AttachmentKind] of [cached]. Needed for mixed pickers.
  final AttachmentKind? cachedKind;

  /// Multi-select output — null in single-select mode.
  final List<(PickerItem, AttachmentKind)>? cachedItems;

  /// A user-tapped source (gallery / camera).
  final MediaPickerSourceOption? source;
}

// ---------------------------------------------------------------------------
// Shared overlay state — sections (mutable), selection, and action
// callbacks. Tiles / confirm button / source tiles / clear-all
// button all subscribe so top + bottom stay in sync.
// ---------------------------------------------------------------------------

class _OverlayController extends ChangeNotifier {
  _OverlayController({
    required Map<AttachmentKind, List<PickerItem>> sections,
    required this.max,
    required this.maxPerKind,
    required this.onRemove,
    required this.onClearAll,
  }) : sections = {
         for (final e in sections.entries) e.key: [...e.value],
       };

  /// Mutable copy of the caller-provided sections. Delete / clear
  /// mutate this for immediate UI feedback; the paired callbacks
  /// keep the backing cache in sync.
  final Map<AttachmentKind, List<PickerItem>> sections;
  final int max;

  /// Remaining selection budget per kind (caller computes
  /// `cap - existingCountOfKind`). Missing / null = no per-kind
  /// limit. Zero means the kind is already maxed out pre-overlay.
  final Map<AttachmentKind, int> maxPerKind;
  final Future<void> Function(PickerItem, AttachmentKind)? onRemove;
  final Future<void> Function()? onClearAll;
  final List<(PickerItem, AttachmentKind)> selected = [];

  bool get isMultiSelect => max > 1;
  int get count => selected.length;
  bool get atLimit => selected.length >= max;
  bool get isEmpty => sections.values.every((l) => l.isEmpty);

  int _selectedOfKind(AttachmentKind k) =>
      selected.where((e) => e.$2 == k).length;

  /// True when a kind has exhausted its per-kind remaining budget
  /// — tiles of that kind render dim + non-tappable.
  bool atKindLimit(AttachmentKind k) {
    final cap = maxPerKind[k];
    if (cap == null) return false;
    return _selectedOfKind(k) >= cap;
  }

  bool isSelected(PickerItem item) =>
      selected.any((e) => _sameItem(e.$1, item));

  void toggle(PickerItem item, AttachmentKind kind) {
    if (!isMultiSelect) return;
    final idx = selected.indexWhere((e) => _sameItem(e.$1, item));
    if (idx >= 0) {
      selected.removeAt(idx);
    } else if (!atLimit && !atKindLimit(kind)) {
      selected.add((item, kind));
    }
    notifyListeners();
  }

  Future<void> deleteItem(PickerItem item, AttachmentKind kind) async {
    sections[kind]?.removeWhere((e) => _sameItem(e, item));
    if ((sections[kind] ?? const []).isEmpty) sections.remove(kind);
    selected.removeWhere((e) => _sameItem(e.$1, item));
    notifyListeners();
    await onRemove?.call(item, kind);
  }

  Future<void> clearAll() async {
    sections.clear();
    selected.clear();
    notifyListeners();
    await onClearAll?.call();
  }

  static bool _sameItem(PickerItem a, PickerItem b) => switch ((a, b)) {
    (PickerItemUrl(:final url), PickerItemUrl(url: final u)) => url == u,
    (PickerItemFile(:final file), PickerItemFile(file: final f)) =>
      file.path == f.path,
    _ => false,
  };
}

/// Show the combined overlay: recent-picks panel at the top, source
/// chooser panel at the bottom. Both visible at once — user sees
/// history and the "pick fresh" actions without dismissing one to
/// reach the other. Drags on either panel slide both off together.
///
/// [sections] must be keyed by [AttachmentKind]; only kinds with
/// non-empty lists render. For single-kind pickers pass one entry.
/// [sourceOptions] picks which source buttons show up — omit camera
/// for gallery-only pickers.
Future<RecentOverlayResult?> showRecentPickerOverlay({
  required BuildContext context,
  required Map<AttachmentKind, List<PickerItem>> sections,
  required List<MediaPickerSourceOption> sourceOptions,
  String? title,
  String? galleryLabel,
  String? cameraLabel,
  String? clipboardLabel,
  String? cancelLabel,
  String? confirmLabel,
  String? limitReachedLabel,
  bool showSectionHeaders = true,
  double tileSize = 96,
  bool allowMultiSelect = false,
  int maxSelection = 1,
  Map<AttachmentKind, int> maxPerKind = const {},
  Future<void> Function(PickerItem, AttachmentKind)? onRemove,
  Future<void> Function()? onClearAll,
  SheetStyle topStyle = const SheetStyle(floating: true),
  SheetStyle bottomStyle = const SheetStyle(floating: true),
}) {
  final controller = _OverlayController(
    sections: sections,
    max: allowMultiSelect && maxSelection > 1 ? maxSelection : 1,
    maxPerKind: maxPerKind,
    onRemove: onRemove,
    onClearAll: onClearAll,
  );
  final resolvedLimitReached = limitReachedLabel ?? MediaStrings.limitReached;
  return GlobalCombinedSheet.show<RecentOverlayResult>(
    context: context,
    topTitle: title ?? MediaStrings.recent,
    topIcon: Icons.history_rounded,
    topShowClose: false,
    topHeaderActions: [
      _ClearAllButton(controller: controller),
      if (controller.isMultiSelect)
        _ConfirmButton(
          controller: controller,
          label: confirmLabel ?? CommonStrings.add,
        ),
    ],
    topStyle: topStyle,
    topContent: _RecentContent(
      showSectionHeaders: showSectionHeaders,
      tileSize: tileSize,
      controller: controller,
      limitReachedLabel: resolvedLimitReached,
    ),
    bottomShowClose: false,
    bottomStyle: bottomStyle,
    bottomContent: _SourceContent(
      sourceOptions: sourceOptions,
      galleryLabel: galleryLabel ?? MediaStrings.gallery,
      cameraLabel: cameraLabel ?? MediaStrings.camera,
      clipboardLabel: clipboardLabel ?? MediaStrings.clipboard,
      cancelLabel: cancelLabel ?? CommonStrings.cancel,
      controller: controller,
      limitReachedLabel: resolvedLimitReached,
    ),
  ).whenComplete(controller.dispose);
}

// ---------------------------------------------------------------------------
// Top panel — recent strips per kind
// ---------------------------------------------------------------------------

class _RecentContent extends StatelessWidget {
  const _RecentContent({
    required this.showSectionHeaders,
    required this.tileSize,
    required this.controller,
    required this.limitReachedLabel,
  });

  final bool showSectionHeaders;
  final double tileSize;
  final _OverlayController controller;
  final String limitReachedLabel;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (ctx, _) {
        // Auto-dismiss when the cache is wiped out — no point
        // keeping an empty overlay open.
        if (controller.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (Navigator.of(ctx).canPop()) Navigator.of(ctx).pop();
          });
          return const SizedBox.shrink();
        }
        final ordered = [
          for (final kind in AttachmentKind.values)
            if ((controller.sections[kind] ?? const []).isNotEmpty)
              MapEntry(kind, controller.sections[kind]!),
        ];
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            if (controller.isMultiSelect)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _LimitBadge(
                  count: controller.count,
                  max: controller.max,
                  atLimit: controller.atLimit,
                  limitReachedLabel: limitReachedLabel,
                ),
              ),
            for (final entry in ordered)
              _Section(
                kind: entry.key,
                items: entry.value,
                tileSize: tileSize,
                showHeader: showSectionHeaders && ordered.length > 1,
                controller: controller,
              ),
          ],
        );
      },
    );
  }
}

// Clear-all icon button rendered in the top panel header.
class _ClearAllButton extends StatelessWidget {
  const _ClearAllButton({required this.controller});
  final _OverlayController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (ctx, _) {
        return GlobalIconButton(
          iconData: Icons.delete_sweep_rounded,
          iconSize: 20,
          size: ButtonSize.small,
          // Sibling _ConfirmButton opts out too — the sheet header is a
          // compact 36dp row and the default 48dp box inflates it.
          enforceMinTouchTarget: false,
          tooltip: CommonStrings.clearAll,
          semanticLabel: CommonStrings.clearAll,
          enabled: !controller.isEmpty,
          style: ButtonStateStyle(foregroundColor: context.statusColors.error),
          onPressed: controller.isEmpty ? null : controller.clearAll,
        );
      },
    );
  }
}

// Tiny pill showing "X / N selected" or "Limit reached" in red
// when atLimit. Lives in the top panel header area.
class _LimitBadge extends StatelessWidget {
  const _LimitBadge({
    required this.count,
    required this.max,
    required this.atLimit,
    required this.limitReachedLabel,
  });

  final int count, max;
  final bool atLimit;
  final String limitReachedLabel;

  @override
  Widget build(BuildContext context) {
    final primary = context.primaryColors;
    final status = context.statusColors;
    final bg = atLimit
        ? status.error.withValues(alpha: 0.12)
        : primary.primary.withValues(alpha: 0.12);
    final fg = atLimit ? status.error : primary.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            atLimit ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
            size: 14,
            color: fg,
          ),
          const SizedBox(width: 6),
          Text(
            atLimit
                ? limitReachedLabel
                : MediaStrings.selectedCount(count, max),
            style: context.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

// Confirm button rendered in the top panel header.
class _ConfirmButton extends StatelessWidget {
  const _ConfirmButton({required this.controller, required this.label});
  final _OverlayController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (ctx, _) {
        final count = controller.count;
        return GlobalFilledButton(
          text: count == 0 ? label : '$label ($count)',
          size: ButtonSize.small,
          shrinkWidth: true,
          // The sheet header is a compact 36dp row — mirror the old
          // MaterialTapTargetSize.shrinkWrap so it doesn't inflate.
          enforceMinTouchTarget: false,
          enabled: count > 0,
          onPressed: () => Navigator.of(ctx).pop(
            RecentOverlayResult.cachedMulti(List.from(controller.selected)),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom panel — source tiles + cancel
// ---------------------------------------------------------------------------

class _SourceContent extends StatelessWidget {
  const _SourceContent({
    required this.sourceOptions,
    required this.galleryLabel,
    required this.cameraLabel,
    required this.clipboardLabel,
    required this.cancelLabel,
    required this.controller,
    required this.limitReachedLabel,
  });

  final List<MediaPickerSourceOption> sourceOptions;
  final String galleryLabel, cameraLabel, clipboardLabel, cancelLabel;
  final _OverlayController controller;
  final String limitReachedLabel;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (ctx, _) => _tiles(ctx, atLimit: controller.atLimit),
    );
  }

  Widget _tiles(BuildContext context, {required bool atLimit}) {
    final status = context.statusColors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (atLimit)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: status.error.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(
                MediaPickerDefaults.thumbRadius,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 16,
                  color: status.error,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    limitReachedLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: status.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
        PickerSheetRows(
          choices: [
            if (sourceOptions.contains(MediaPickerSourceOption.gallery))
              PickerSheetChoice(
                icon: Icons.photo_library_rounded,
                label: galleryLabel,
                enabled: !atLimit,
                onTap: () => Navigator.of(context).pop(
                  const RecentOverlayResult.source(
                    MediaPickerSourceOption.gallery,
                  ),
                ),
              ),
            if (sourceOptions.contains(MediaPickerSourceOption.camera))
              PickerSheetChoice(
                icon: Icons.camera_alt_rounded,
                label: cameraLabel,
                enabled: !atLimit,
                onTap: () => Navigator.of(context).pop(
                  const RecentOverlayResult.source(
                    MediaPickerSourceOption.camera,
                  ),
                ),
              ),
            if (sourceOptions.contains(MediaPickerSourceOption.clipboard))
              PickerSheetChoice(
                icon: Icons.content_paste_rounded,
                label: clipboardLabel,
                enabled: !atLimit,
                onTap: () => Navigator.of(context).pop(
                  const RecentOverlayResult.source(
                    MediaPickerSourceOption.clipboard,
                  ),
                ),
              ),
            PickerSheetChoice(
              icon: Icons.cancel_rounded,
              label: cancelLabel,
              destructive: true,
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Section — one horizontal strip per kind
// ---------------------------------------------------------------------------

class _Section extends StatelessWidget {
  const _Section({
    required this.kind,
    required this.items,
    required this.tileSize,
    required this.showHeader,
    required this.controller,
  });

  final AttachmentKind kind;
  final List<PickerItem> items;
  final double tileSize;
  final bool showHeader;
  final _OverlayController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showHeader)
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 6),
            child: Text(
              _headerFor(kind),
              style: TextStyle(
                color: context.textColors.secondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
            ),
          ),
        _ScrollableGrid(
          items: items,
          kind: kind,
          tileSize: tileSize,
          controller: controller,
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  String _headerFor(AttachmentKind kind) => switch (kind) {
    AttachmentKind.image => 'IMAGES',
    AttachmentKind.video => 'VIDEOS',
    AttachmentKind.file => 'FILES',
  };
}

// ---------------------------------------------------------------------------
// ScrollableGrid — 2-row horizontal grid with fade-edge shader so
// users see there's more content to scroll to.
// ---------------------------------------------------------------------------

class _ScrollableGrid extends StatefulWidget {
  const _ScrollableGrid({
    required this.items,
    required this.kind,
    required this.tileSize,
    required this.controller,
  });

  final List<PickerItem> items;
  final AttachmentKind kind;
  final double tileSize;
  final _OverlayController controller;

  @override
  State<_ScrollableGrid> createState() => _ScrollableGridState();
}

class _ScrollableGridState extends State<_ScrollableGrid> {
  final _ctrl = ScrollController();
  // 0 = at start (only right fade), 1 = at end (only left fade),
  // anything in between fades both edges.
  double _leftOpacity = 0;
  double _rightOpacity = 1;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(_updateFades);
    // Initial read — scroll metrics aren't valid until first layout.
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateFades());
  }

  @override
  void dispose() {
    _ctrl.removeListener(_updateFades);
    _ctrl.dispose();
    super.dispose();
  }

  void _updateFades() {
    if (!_ctrl.hasClients) return;
    final pos = _ctrl.position;
    final max = pos.maxScrollExtent;
    if (max <= 0) {
      if (_leftOpacity != 0 || _rightOpacity != 0) {
        setState(() {
          _leftOpacity = 0;
          _rightOpacity = 0;
        });
      }
      return;
    }
    final o = pos.pixels;
    final newLeft = (o / 32).clamp(0.0, 1.0);
    final newRight = ((max - o) / 32).clamp(0.0, 1.0);
    if ((newLeft - _leftOpacity).abs() > 0.01 ||
        (newRight - _rightOpacity).abs() > 0.01) {
      setState(() {
        _leftOpacity = newLeft;
        _rightOpacity = newRight;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const gap = 8.0;
    final rowCount = widget.items.length <= 1 ? 1 : 2;
    final totalHeight = rowCount == 1
        ? widget.tileSize
        : widget.tileSize * 2 + gap;

    return SizedBox(
      height: totalHeight,
      child: ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (bounds) => LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.white.withValues(alpha: 1 - _leftOpacity),
            Colors.white,
            Colors.white,
            Colors.white.withValues(alpha: 1 - _rightOpacity),
          ],
          stops: const [0.0, 0.06, 0.94, 1.0],
        ).createShader(bounds),
        child: GridView.builder(
          controller: _ctrl,
          scrollDirection: Axis.horizontal,
          itemCount: widget.items.length,
          physics: const BouncingScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: rowCount,
            crossAxisSpacing: gap,
            mainAxisSpacing: gap,
            childAspectRatio: 1,
          ),
          itemBuilder: (ctx, i) => _RecentTile(
            item: widget.items[i],
            kind: widget.kind,
            size: widget.tileSize,
            controller: widget.controller,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// RecentTile — one tappable cached item
// ---------------------------------------------------------------------------

class _RecentTile extends StatelessWidget {
  const _RecentTile({
    required this.item,
    required this.kind,
    required this.size,
    required this.controller,
  });

  final PickerItem item;
  final AttachmentKind kind;
  final double size;
  final _OverlayController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (ctx, _) {
        final multi = controller.isMultiSelect;
        final selected = multi && controller.isSelected(item);
        // Dim when no more room overall OR when this item's kind
        // is already at its per-kind cap. In single-select the
        // per-kind cap still applies (caller would reject anyway).
        final dim =
            !selected &&
            ((multi && controller.atLimit) || controller.atKindLimit(kind));
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: dim
              ? null
              : () {
                  if (multi) {
                    controller.toggle(item, kind);
                  } else {
                    Navigator.of(
                      ctx,
                    ).pop(RecentOverlayResult.cached(item, kind));
                  }
                },
          child: _tileInner(ctx, selected: selected, dim: dim),
        );
      },
    );
  }

  Widget _tileInner(
    BuildContext context, {
    bool selected = false,
    bool dim = false,
  }) {
    final primary = context.primaryColors;
    final background = context.backgroundColors;
    final icons = context.iconColors;
    return Opacity(
      opacity: dim ? 0.4 : 1,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(
              MediaPickerDefaults.thumbRadius,
            ),
            child: SizedBox(
              width: size,
              height: size,
              child: _preview(context),
            ),
          ),
          if (selected)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    MediaPickerDefaults.thumbRadius,
                  ),
                  border: Border.all(color: primary.primary, width: 3),
                  color: primary.primary.withValues(alpha: 0.18),
                ),
              ),
            ),
          // Check badge — top-left in multi mode so it doesn't
          // collide with the delete X in the top-right.
          if (selected)
            Positioned(
              top: 4,
              left: 4,
              child: GlobalIcon(
                icon: Icons.check_rounded,
                style: IconStyle(
                  size: MediaPickerDefaults.dotIconSize,
                  color: icons.onPrimary,
                  containerSize: MediaPickerDefaults.thumbDotSize,
                  containerShape: IconContainerShape.circle,
                  backgroundColor: primary.primary,
                  // The ring is the tile showing through, so the badge
                  // reads as a badge on top of a photo.
                  borderColor: background.surface,
                  borderWidth: 2,
                ),
              ),
            ),
          // Delete — always visible top-right, and the SAME dot the
          // tiles use. It was a bare `GestureDetector` around a
          // hand-drawn circle: no name, no keyboard, no focus ring,
          // and its own idea of the colour.
          Positioned(
            top: MediaPickerDefaults.gapXs,
            right: MediaPickerDefaults.gapXs,
            child: PickerActionDot(
              action: PickerDotAction.remove,
              style: const MediaPickerStyle().resolve(context),
              onTap: () => controller.deleteItem(item, kind),
            ),
          ),
        ],
      ),
    );
  }

  Widget _preview(BuildContext context) {
    switch (kind) {
      case AttachmentKind.image:
        return _imagePreview(context);
      case AttachmentKind.video:
        // A FRAME, like the picker's own tiles. A play glyph on a grey
        // square tells a reader which of four clips this is only if
        // they remember the order they picked them in.
        return _VideoThumb(item: item, size: size);
      case AttachmentKind.file:
        return _filePreview(context);
    }
  }

  Widget _imagePreview(BuildContext context) {
    return switch (item) {
      PickerItemFile(:final file) => GlobalImage(
        file: file,
        type: ImageType.file,
        style: const ImageStyle(fit: BoxFit.cover),
      ),
      PickerItemUrl(:final url) => GlobalImage(
        url: url,
        type: ImageType.network,
        style: const ImageStyle(fit: BoxFit.cover),
      ),
      PickerItemBytes(:final bytes) => GlobalImage(
        bytes: bytes,
        type: ImageType.memory,
        style: const ImageStyle(fit: BoxFit.cover),
      ),
    };
  }

  Widget _filePreview(BuildContext context) {
    final name = switch (item) {
      PickerItemFile(:final displayName) => displayName,
      PickerItemUrl(:final displayName) => displayName,
      PickerItemBytes(:final displayName) => displayName,
    };
    return Container(
      color: context.backgroundColors.container,
      padding: const EdgeInsets.all(6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.insert_drive_file_rounded,
            size: 26,
            color: context.primaryColors.primary,
          ),
          const SizedBox(height: 2),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: context.textColors.primary, fontSize: 9),
          ),
        ],
      ),
    );
  }
}

/// A frame from a video, decoded once and remembered.
///
/// The recents strip drew a play glyph on a grey square — the same
/// square for every clip, which is no help at all when there are four
/// of them. The pickers' own tiles have shown a frame for a while;
/// this is that, in the sheet.
///
/// Stateful because the decode is asynchronous and the strip rebuilds
/// on every selection change: without holding the result, each rebuild
/// would start another decode.
class _VideoThumb extends StatefulWidget {
  const _VideoThumb({required this.item, required this.size});

  final PickerItem item;
  final double size;

  @override
  State<_VideoThumb> createState() => _VideoThumbState();
}

class _VideoThumbState extends State<_VideoThumb> {
  File? _thumb;
  bool _tried = false;

  @override
  void initState() {
    super.initState();
    unawaited(_decode());
  }

  Future<void> _decode() async {
    // Only a local file has frames to read. A remote one would have to
    // be downloaded first, which is not a thing a sheet should do
    // while the reader is looking at it.
    final item = widget.item;
    if (item is! PickerItemFile) {
      setState(() => _tried = true);
      return;
    }
    final file = await VideoThumbnailService.at(item.file.path);
    if (!mounted) return;
    setState(() {
      _thumb = file;
      _tried = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final thumb = _thumb;
    if (thumb == null) {
      // Before the decode lands — and after one that failed — the
      // glyph is what there is.
      return ColoredBox(
        color: context.backgroundColors.container,
        child: Center(
          child: _tried
              ? Icon(
                  Icons.play_circle_fill_rounded,
                  size: MediaPickerDefaults.rowIconSize,
                  color: context.primaryColors.primary,
                )
              : const SizedBox.shrink(),
        ),
      );
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        GlobalImage(
          file: thumb,
          type: ImageType.file,
          style: const ImageStyle(fit: BoxFit.cover),
        ),
        const ColoredBox(color: MediaPickerDefaults.busyScrim),
        const Center(
          child: Icon(
            Icons.play_circle_fill_rounded,
            size: MediaPickerDefaults.rowIconSize,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
