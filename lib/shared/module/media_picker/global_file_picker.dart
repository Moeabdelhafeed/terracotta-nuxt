// Dart imports:
import 'dart:io';

import 'package:file_picker/file_picker.dart' as fp;
import 'package:flutter/material.dart';
import 'package:reorderables/reorderables.dart';

// Flutter imports:
// Package imports:
// Project imports:
import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/strings/media_strings.dart';
import '../../../data/services/media/clipboard_image_service.dart';
import '../../../data/services/media/file_picker_service.dart';
import '../../../data/services/media/recent_uploads_cache.dart';
import '../icon/global_icon.dart';
import '../popup/popup.dart';
import '../progress/global_progress.dart';
import '../toast/global_toast.dart';
import 'media_picker_models.dart';
import 'media_picker_style.dart';
import 'picker_action_dot.dart';
import 'picker_drop_region.dart';
import 'picker_interactable.dart';
import 'picker_lightbox.dart';
import 'picker_slot.dart';
import 'recent_picker_overlay.dart';
import 'theme/media_picker_theme.dart';
import 'upload_controller.dart';
import 'upload_overlay.dart';

// ---------------------------------------------------------------------------
// GlobalFilePicker — single or multi; file or URL
// ---------------------------------------------------------------------------

/// Arbitrary-file picker over [PickerItem]. Update screens can
/// hydrate with [PickerItem.url]s from the server and let the user
/// mix in freshly-picked [PickerItem.file]s.
class GlobalFilePicker extends StatefulWidget {
  const GlobalFilePicker({
    super.key,
    required this.files,
    required this.onChanged,
    this.multiple = false,
    this.layout = MediaPickerLayout.rows,
    this.maxFiles = 5,
    this.fileType = fp.FileType.any,
    this.allowedExtensions,
    this.validator,
    this.style = const MediaPickerStyle(),
    this.onError,
    this.onDownload,
    this.recentCache,
    this.autoCacheOnPick = false,
    this.uploadController,
    this.autoUpload = false,
    this.label,
    this.hint,
    this.icon,
    this.enabled = true,
    this.recentTitle,
    this.cancelLabel,
    this.galleryLabel,
  }) : assert(
         !multiple || files is List<PickerItem>,
         'For `multiple: true`, pass a `List<PickerItem>` to `files`.',
       ),
       assert(
         multiple || files is PickerItem?,
         'For single mode, pass a `PickerItem?` to `files`.',
       );

  final Object? files;
  final ValueChanged<dynamic> onChanged;
  final bool multiple;

  /// Multi-mode layout. Defaults to [MediaPickerLayout.rows] —
  /// full-width stacked filename rows. Flip to
  /// [MediaPickerLayout.grid] for tile-style previews or
  /// [MediaPickerLayout.horizontalList] for a scrollable strip.
  final MediaPickerLayout layout;

  final int maxFiles;

  final fp.FileType fileType;
  final List<String>? allowedExtensions;

  final MediaPickerValidator? validator;
  final ValueChanged<MediaPickerError>? onError;

  /// How it looks, and which affordances it offers. Layered
  /// `caller > GlobalMediaPickerTheme > MediaPickerStyle.defaults`
  /// and resolved once per build.
  ///
  /// The tile size, the corner, the badge, the camera, the clipboard,
  /// reordering and the recent cache all live here now — they were
  /// separate parameters on a widget that already took thirty-odd.
  final MediaPickerStyle style;

  /// Where previously-picked items come from.
  ///
  /// PASSED IN, not looked up. `lib/shared/module` may not reach the
  /// DI catalog — this module did, in four files, which is the one
  /// hard rule the directory has.
  final RecentUploadsCache? recentCache;

  /// Fired when the user taps the download icon on a
  /// [PickerItemUrl] tile. Hidden when null.
  final ValueChanged<PickerItemUrl>? onDownload;

  /// Auto-feed picked file items into [RecentUploadsCache] so the
  /// combined overlay shows them next tap. Off by default — prod
  /// apps typically cache after upload succeeds.
  final bool autoCacheOnPick;

  /// Optional per-item upload tracker. When attached, tiles render
  /// progress rings + error overlays + retry on tap.
  final UploadController? uploadController;

  /// Auto-start upload for each newly added `PickerItemFile`.
  final bool autoUpload;

  final String? recentTitle;
  final String? cancelLabel;

  /// Label on the "browse system file picker" row. File picker
  /// doesn't have a gallery/camera split, so we surface one button.
  final String? galleryLabel;

  final String? label;
  final String? hint;
  final IconData? icon;
  final bool enabled;

  @override
  State<GlobalFilePicker> createState() => _GlobalFilePickerState();
}

class _GlobalFilePickerState extends State<GlobalFilePicker> {
  /// The resolved bag, held on the STATE because the pick handlers
  /// read it between builds.
  ///
  /// NOT `late`: resolving needs the inherited theme, which is only
  /// there from `didChangeDependencies`.
  ResolvedMediaPickerStyle _rs = ResolvedMediaPickerStyle.fallback;

  /// A controller of this reorderable's OWN, never the page's.
  ///
  /// `reorderables` reaches for `PrimaryScrollController.maybeOf` when
  /// it is given none — and then ATTACHES the page's scroll position
  /// to it, which the page's own `ScrollView` has already attached.
  /// That is the "ScrollController attached to multiple scroll views"
  /// assert, and with two pickers on one page it is also
  /// "_positions.length == 1" the moment a drag starts.
  ///
  /// Ours has no clients — these rows do not scroll — so the package
  /// takes its `hasClients` branch and attaches nothing at all.
  final _reorderScroll = ScrollController();
  bool _busy = false;
  String? _error;

  bool _hadUrl = false;

  @override
  void initState() {
    super.initState();
    _refreshUrlFlag();
  }

  @override
  void dispose() {
    _reorderScroll.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _rs = widget.style.resolve(context);
  }

  @override
  void didUpdateWidget(GlobalFilePicker old) {
    super.didUpdateWidget(old);
    if (old.style != widget.style) _rs = widget.style.resolve(context);
    _refreshUrlFlag();
  }

  void _refreshUrlFlag() {
    if (_hadUrl) return;
    final v = widget.files;
    final seen = switch (v) {
      List<PickerItem>() => v.any((e) => e is PickerItemUrl),
      PickerItem() => v is PickerItemUrl,
      _ => false,
    };
    if (seen) _hadUrl = true;
  }

  List<PickerItem> get _multi =>
      widget.multiple ? (widget.files as List<PickerItem>) : const [];
  PickerItem? get _single =>
      widget.multiple ? null : widget.files as PickerItem?;

  void _reportError(MediaPickerError err) {
    setState(() => _error = err.message);
    widget.onError?.call(err);
  }

  PickerItem _wrap(File f) => PickerItem.file(f, isNew: _hadUrl);

  void _maybeAutoUpload(PickerItem item) {
    if (!widget.autoUpload) return;
    final ctrl = widget.uploadController;
    if (ctrl == null) return;
    if (item is! PickerItemFile) return;
    ctrl.start(item);
  }

  void _emit(dynamic value) {
    final prev = widget.multiple
        ? List<PickerItem>.from(_multi)
        : <PickerItem>[if (_single != null) _single!];
    final next = widget.multiple
        ? (value as List<PickerItem>)
        : <PickerItem>[if (value != null) value as PickerItem];
    final prevKeys = prev
        .whereType<PickerItemFile>()
        .map((e) => e.file.path)
        .toSet();
    final nextKeys = next
        .whereType<PickerItemFile>()
        .map((e) => e.file.path)
        .toSet();
    final ctrl = widget.uploadController;
    if (ctrl != null) {
      for (final item in prev.whereType<PickerItemFile>()) {
        if (!nextKeys.contains(item.file.path)) ctrl.forget(item);
      }
    }
    for (final item in next.whereType<PickerItemFile>()) {
      if (!prevKeys.contains(item.file.path)) _maybeAutoUpload(item);
    }
    widget.onChanged(value);
  }

  Future<PickerItem> _autoCache(PickerItem item) async {
    if (!widget.autoCacheOnPick) return item;
    final cache = widget.recentCache;
    if (cache == null) return item;
    return cache.add(item, AttachmentKind.file);
  }

  Future<void> _handleTap() async {
    if (!widget.enabled || _busy) return;
    if (widget.multiple && _multi.length >= widget.maxFiles) return;

    final cache = _rs.useRecentCache ? widget.recentCache : null;
    final recent = cache?.recent(AttachmentKind.file) ?? const <PickerItem>[];

    if (recent.isNotEmpty) {
      final remaining = widget.multiple ? widget.maxFiles - _multi.length : 1;
      final result = await showRecentPickerOverlay(
        context: context,
        sections: {AttachmentKind.file: recent},
        // File picker has no camera — surface a browse row and,
        // when enabled, the paste row too.
        sourceOptions: [
          MediaPickerSourceOption.gallery,
          if (_rs.allowClipboard) MediaPickerSourceOption.clipboard,
        ],
        title: widget.recentTitle,
        galleryLabel: widget.galleryLabel,
        cancelLabel: widget.cancelLabel,
        allowMultiSelect: widget.multiple && remaining > 1,
        maxSelection: remaining,
        onRemove: (item, kind) => cache!.remove(item, kind),
        onClearAll: () => cache!.clear(AttachmentKind.file),
      );
      if (result == null) return;
      if (result.cachedItems != null) {
        await _acceptCachedBatch(result.cachedItems!.map((e) => e.$1).toList());
        return;
      }
      if (result.cached != null) {
        await _acceptCached(result.cached!);
        return;
      }
      if (result.source == MediaPickerSourceOption.clipboard) {
        await _pasteFromClipboard();
        return;
      }
      // Source == gallery → fall through to native picker.
    }

    await _runNativePicker();
  }

  Future<void> _runNativePicker() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (widget.multiple) {
        final picked = await FilePickerService.pickMultipleFiles(
          type: widget.fileType,
          allowedExtensions: widget.allowedExtensions,
        );
        if (picked.isEmpty) return;
        final next = [..._multi];
        for (final f in picked) {
          if (next.length >= widget.maxFiles) break;
          final err = await widget.validator?.validate(f);
          if (err != null) {
            _reportError(err);
            continue;
          }
          next.add(await _autoCache(_wrap(f)));
        }
        _emit(next);
      } else {
        final picked = await FilePickerService.pickFile(
          type: widget.fileType,
          allowedExtensions: widget.allowedExtensions,
        );
        if (picked == null) return;
        final err = await widget.validator?.validate(picked);
        if (err != null) {
          _reportError(err);
          return;
        }
        _emit(await _autoCache(_wrap(picked)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _acceptCached(PickerItem item) async {
    if (item is PickerItemFile) {
      final err = await widget.validator?.validate(item.file);
      if (err != null) {
        _reportError(err);
        return;
      }
    }
    if (widget.multiple) {
      if (_multi.length >= widget.maxFiles) return;
      _emit([..._multi, item]);
    } else {
      _emit(item);
    }
  }

  Future<void> _acceptCachedBatch(List<PickerItem> items) async {
    final next = [..._multi];
    for (final item in items) {
      if (next.length >= widget.maxFiles) break;
      if (item is PickerItemFile) {
        final err = await widget.validator?.validate(item.file);
        if (err != null) {
          _reportError(err);
          continue;
        }
      }
      next.add(item);
    }
    _emit(next);
  }

  void _removeAt(int i) {
    if (widget.multiple) {
      final next = [..._multi]..removeAt(i);
      _emit(next);
    } else {
      _emit(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: TextStyle(
              color: context.textColors.primary,
              fontSize: context.textTheme.bodyLarge?.fontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Stack(
          children: [
            IgnorePointer(
              ignoring: _busy,
              child: widget.multiple
                  ? _multiBody(context)
                  : _singleBody(context),
            ),
            if (_busy)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.2),
                    borderRadius: _rs.tileBorderRadius,
                  ),
                  alignment: Alignment.center,
                  child: SizedBox(
                    height: 24,
                    width: 24,
                    child: GlobalProgress.loading(
                      type: ProgressType.circular,
                      style: const ProgressStyle(
                        thickness: 2.5,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        if (_error != null) MediaPickerInlineError(message: _error!),
      ],
    );
  }

  // ─── Single ─────────────────────────────────────────────────────

  Widget _singleBody(BuildContext context) {
    final item = _single;
    if (item == null) return _addRowSlot(context);
    return PickerFilledSlot(
      style: _rs,
      height: _rs.rowHeight,
      // The tile clips its own picture — see `clip`.
      clip: false,
      child: _fileRow(context, item, () => _removeAt(0)),
    );
  }

  // ─── Multi ──────────────────────────────────────────────────────

  Widget _multiBody(BuildContext context) {
    switch (widget.layout) {
      case MediaPickerLayout.grid:
        return _multiGridBody(context);
      case MediaPickerLayout.horizontalList:
        return _multiHorizontalBody(context);
      case MediaPickerLayout.rows:
        return _multiRowsBody(context);
    }
  }

  void _reorder(int oldIndex, int newIndex) {
    if (!widget.multiple) return;
    final next = [..._multi];
    var to = newIndex;
    if (to > oldIndex) to -= 1;
    final moved = next.removeAt(oldIndex);
    next.insert(to, moved);
    _emit(next);
  }

  String _tileKey(PickerItem item, int i) => switch (item) {
    PickerItemFile(:final file) => 'f::${file.path}::$i',
    PickerItemUrl(:final url) => 'u::$url::$i',
    PickerItemBytes(:final filename) => 'b::$filename::$i',
  };

  bool _clipboardHasFiles = false;

  List<GlobalPopupMenuItem<MediaPickerSourceOption>> _buildAddMenuItems() {
    return [
      GlobalPopupMenuItem(
        value: MediaPickerSourceOption.gallery,
        label: widget.galleryLabel ?? MediaStrings.browse,
        icon: Icons.folder_open_rounded,
      ),
      if (_rs.allowClipboard)
        GlobalPopupMenuItem(
          value: MediaPickerSourceOption.clipboard,
          label: _clipboardHasFiles ? 'Clipboard' : 'Clipboard (empty)',
          icon: Icons.content_paste_rounded,
          enabled: _clipboardHasFiles,
        ),
    ];
  }

  Future<void> _onSourceSelected(MediaPickerSourceOption src) async {
    if (src == MediaPickerSourceOption.clipboard) {
      await _pasteFromClipboard();
    } else {
      await _handleTap();
    }
  }

  Widget _wrapWithMenu(Widget interactable) {
    final menued = !_rs.allowClipboard
        ? interactable
        : GlobalPopup.menu<MediaPickerSourceOption>(
            // `secondaryTap`, which is long-press AND right-click.
            //
            // Not `longPress`: that trigger listens to raw POINTERS
            // and never joins the arena, so the slot's own tap
            // recogniser was never rejected — a long press opened the
            // menu and then the source sheet underneath it, both at
            // once. This one is a real gesture, so the tap loses to it
            // the way it should. Right-click comes free, which is what
            // a desktop reader tries first.
            trigger: GlobalPopupTrigger.secondaryTap,
            onOpen: () async {
              final has = await ClipboardImageService.hasFiles(
                extensionsWhitelist: widget.allowedExtensions,
              );
              if (mounted) setState(() => _clipboardHasFiles = has);
            },
            items: _buildAddMenuItems(),
            onSelected: _onSourceSelected,
            anchor: interactable,
          );
    return PickerDropRegion(
      extensionWhitelist: widget.allowedExtensions,
      onFilesDropped: _handleDroppedFiles,
      child: menued,
    );
  }

  Future<void> _handleDroppedFiles(List<File> files) async {
    if (!widget.enabled || files.isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (widget.multiple) {
        final next = [..._multi];
        for (final f in files) {
          if (next.length >= widget.maxFiles) break;
          final err = await widget.validator?.validate(f);
          if (err != null) {
            _reportError(err);
            continue;
          }
          next.add(await _autoCache(_wrap(f)));
        }
        _emit(next);
      } else {
        final f = files.first;
        final err = await widget.validator?.validate(f);
        if (err != null) {
          _reportError(err);
          return;
        }
        _emit(await _autoCache(_wrap(f)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _addRowSlot(BuildContext context) {
    return _wrapWithMenu(
      PickerInteractable(
        onActivate: _handleTap,
        label: widget.hint ?? MediaStrings.addFile,
        borderRadius: BorderRadius.circular(MediaPickerDefaults.gapLg),
        tooltip: _rs.allowClipboard ? MediaStrings.addFile : null,
        child: PickerEmptySlot(
          style: _rs,
          height: _rs.rowHeight,
          child: _placeholder(context),
        ),
      ),
    );
  }

  Widget _addTileSlot(BuildContext context, double tileH) {
    return _wrapWithMenu(
      PickerInteractable(
        onActivate: _handleTap,
        label: widget.hint ?? MediaStrings.addFile,
        borderRadius: _rs.tileBorderRadius,
        tooltip: _rs.allowClipboard ? MediaStrings.addFile : null,
        child: PickerEmptySlot(
          style: _rs,
          height: tileH,
          child: _addTile(context),
        ),
      ),
    );
  }

  Future<void> _pasteFromClipboard() async {
    if (widget.multiple && _multi.length >= widget.maxFiles) return;
    final files = await ClipboardImageService.pasteFiles(
      extensionsWhitelist: widget.allowedExtensions,
    );
    if (files.isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (widget.multiple) {
        final next = [..._multi];
        for (final f in files) {
          if (next.length >= widget.maxFiles) break;
          final err = await widget.validator?.validate(f);
          if (err != null) {
            _reportError(err);
            continue;
          }
          next.add(await _autoCache(_wrap(f)));
        }
        _emit(next);
      } else {
        final f = files.first;
        final err = await widget.validator?.validate(f);
        if (err != null) {
          _reportError(err);
          return;
        }
        _emit(await _autoCache(_wrap(f)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _copyToClipboard(PickerItemFile item) async {
    final ok = await ClipboardImageService.copyFiles([item.file]);
    if (!mounted) return;
    if (ok) {
      GlobalToast.success(MediaStrings.fileCopied);
    } else {
      GlobalToast.error(MediaStrings.copyFailed);
    }
  }

  Widget _multiRowsBody(BuildContext context) {
    final rows = <Widget>[
      for (var i = 0; i < _multi.length; i++)
        Padding(
          key: ValueKey(_tileKey(_multi[i], i)),
          padding: const EdgeInsets.only(bottom: 8),
          child: PickerFilledSlot(
            style: _rs,
            height: _rs.rowHeight,
            // The tile clips its own picture — see `clip`.
            clip: false,
            child: _fileRow(context, _multi[i], () => _removeAt(i)),
          ),
        ),
    ];
    final addRow = _multi.length < widget.maxFiles
        ? _addRowSlot(context)
        : null;
    if (_rs.reorderable && _multi.length > 1) {
      return Column(
        children: [
          ReorderableColumn(
            scrollController: _reorderScroll,
            needsLongPressDraggable: true,
            onReorder: _reorder,
            children: rows,
          ),
          if (addRow != null) addRow,
        ],
      );
    }
    return Column(children: [...rows, if (addRow != null) addRow]);
  }

  Widget _multiGridBody(BuildContext context) {
    final slots = widget.maxFiles;
    final tileW = _rs.tileWidth ?? _rs.cellSize;
    final tileH = _rs.tileHeight;
    final filled = <Widget>[
      for (var i = 0; i < _multi.length; i++)
        SizedBox(
          key: ValueKey(_tileKey(_multi[i], i)),
          width: tileW,
          height: tileH,
          child: PickerFilledSlot(
            style: _rs,
            height: tileH,
            // The tile clips its own picture — see `clip`.
            clip: false,
            child: _fileTile(context, _multi[i], () => _removeAt(i)),
          ),
        ),
    ];
    final empty = <Widget>[
      for (var i = 0; i < slots - _multi.length; i++)
        SizedBox(
          key: ValueKey('add-$i'),
          width: tileW,
          height: tileH,
          child: _addTileSlot(context, tileH),
        ),
    ];
    if (_rs.reorderable && _multi.length > 1) {
      return ReorderableWrap(
        controller: _reorderScroll,
        spacing: 8,
        runSpacing: 8,
        needsLongPressDraggable: true,
        onReorder: _reorder,
        footer: empty.isEmpty
            ? null
            : Wrap(spacing: 8, runSpacing: 8, children: empty),
        children: filled,
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [...filled, ...empty],
    );
  }

  Widget _multiHorizontalBody(BuildContext context) {
    final canAdd = _multi.length < widget.maxFiles;
    final tileW = _rs.tileWidth ?? _rs.cellSize;
    final tileH = _rs.tileHeight;
    final addTile = canAdd
        ? SizedBox(
            key: const ValueKey('add-tile'),
            width: tileW,
            height: tileH,
            child: _addTileSlot(context, tileH),
          )
        : null;
    if (_rs.reorderable && _multi.length > 1) {
      return SizedBox(
        height: tileH,
        child: ReorderableRow(
          scrollController: _reorderScroll,
          needsLongPressDraggable: true,
          mainAxisSize: MainAxisSize.min,
          onReorder: _reorder,
          footer: addTile == null
              ? null
              : Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: addTile,
                ),
          children: [
            for (var i = 0; i < _multi.length; i++)
              Padding(
                key: ValueKey(_tileKey(_multi[i], i)),
                padding: EdgeInsets.only(right: i == _multi.length - 1 ? 0 : 8),
                child: SizedBox(
                  width: tileW,
                  height: tileH,
                  child: PickerFilledSlot(
                    style: _rs,
                    height: tileH,
                    // The tile clips its own picture — see `clip`.
                    clip: false,
                    child: _fileTile(context, _multi[i], () => _removeAt(i)),
                  ),
                ),
              ),
          ],
        ),
      );
    }
    return SizedBox(
      height: tileH,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _multi.length + (canAdd ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          if (i < _multi.length) {
            return SizedBox(
              width: tileW,
              height: tileH,
              child: PickerFilledSlot(
                style: _rs,
                height: tileH,
                // The tile clips its own picture — see `clip`.
                clip: false,
                child: _fileTile(context, _multi[i], () => _removeAt(i)),
              ),
            );
          }
          return addTile ?? const SizedBox.shrink();
        },
      ),
    );
  }

  // ─── Tile (grid / horizontal) ──────────────────────────────────

  Future<void> _openLightbox(PickerItem tapped) async {
    final list = widget.multiple ? _multi : <PickerItem>[tapped];
    final idx = list.indexOf(tapped).clamp(0, list.length - 1);
    await showPickerLightbox(
      context: context,
      items: list,
      kinds: List.filled(list.length, AttachmentKind.file),
      initialIndex: idx,
    );
  }

  Widget _fileTile(
    BuildContext context,
    PickerItem item,
    VoidCallback onRemove,
  ) {
    final name = _nameFor(item);
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _openLightbox(item),
            child: Container(
              color: _rs.surfaceColor,
              alignment: Alignment.center,
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.insert_drive_file_rounded,
                    size: 32,
                    color: _rs.accent,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.textColors.primary,
                      fontSize: context.textTheme.labelSmall?.fontSize,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (item is PickerItemFile && item.isNew)
          Positioned(top: 4, left: 4, child: PickerNewBadge(style: _rs)),
        if (item is PickerItemUrl && widget.onDownload != null)
          Positioned(
            top: 4,
            left: 4,
            child: PickerActionDot(
              action: PickerDotAction.download,
              style: _rs,
              onTap: () => widget.onDownload!(item),
            ),
          ),
        if (_rs.allowClipboard && item is PickerItemFile)
          Positioned(
            bottom: 4,
            right: 4,
            child: PickerActionDot(
              action: PickerDotAction.copy,
              style: _rs,
              copyLabel: MediaStrings.copyFileTooltip,
              onTap: () => _copyToClipboard(item),
            ),
          ),
        Positioned(
          top: 4,
          right: 4,
          child: PickerActionDot(
            action: PickerDotAction.remove,
            style: _rs,
            onTap: onRemove,
          ),
        ),
        if (widget.uploadController != null)
          UploadOverlay(controller: widget.uploadController!, item: item),
      ],
    );
  }

  // ─── Row (single + rows layout) ────────────────────────────────

  Widget _fileRow(
    BuildContext context,
    PickerItem item,
    VoidCallback onRemove,
  ) {
    final name = _nameFor(item);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openLightbox(item),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.insert_drive_file_rounded,
                color: _rs.accent,
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: context.textColors.primary,
                          fontSize: context.textTheme.bodySmall?.fontSize,
                        ),
                      ),
                    ),
                    if (item is PickerItemFile && item.isNew) ...[
                      const SizedBox(width: 6),
                      PickerNewBadge(style: _rs),
                    ],
                  ],
                ),
              ),
              if (item is PickerItemUrl && widget.onDownload != null) ...[
                const SizedBox(width: 6),
                PickerActionDot(
                  action: PickerDotAction.download,
                  style: _rs,
                  onTap: () => widget.onDownload!(item),
                ),
              ],
              if (_rs.allowClipboard && item is PickerItemFile) ...[
                const SizedBox(width: 6),
                PickerActionDot(
                  action: PickerDotAction.copy,
                  style: _rs,
                  copyLabel: MediaStrings.copyFileTooltip,
                  onTap: () => _copyToClipboard(item),
                ),
              ],
              const SizedBox(width: 6),
              PickerActionDot(
                action: PickerDotAction.remove,
                style: _rs,
                onTap: onRemove,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _nameFor(PickerItem item) => switch (item) {
    PickerItemFile() => item.displayName,
    PickerItemUrl() => item.displayName,
    PickerItemBytes() => item.displayName,
  };

  // ─── Slots ──────────────────────────────────────────────────────

  Widget _placeholder(BuildContext context) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            widget.icon ?? Icons.upload_file_rounded,
            color: _rs.accent,
            size: 22,
          ),
          const SizedBox(width: 8),
          Text(
            widget.hint ?? MediaStrings.chooseFile,
            style: TextStyle(
              color: _rs.accent,
              fontSize: context.textTheme.bodyMedium?.fontSize,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _addTile(BuildContext context) {
    final primary = context.primaryColors.primary;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GlobalIcon(
            icon: widget.icon ?? Icons.add_rounded,
            style: IconStyle(
              size: 22,
              color: primary,
              containerSize: 36,
              containerShape: IconContainerShape.circle,
              backgroundColor: primary,
              backgroundOpacity: 0.12,
            ),
          ),
          if (widget.hint != null) ...[
            const SizedBox(height: 6),
            Text(
              widget.hint!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _rs.hintColor,
                fontSize: context.textTheme.labelSmall?.fontSize,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Badges ─────────────────────────────────────────────────────
}
