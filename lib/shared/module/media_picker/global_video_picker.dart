// Dart imports:
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:reorderables/reorderables.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/strings/media_strings.dart';
import '../../../data/services/media/clipboard_image_service.dart';
import '../../../data/services/media/media_picker_service.dart';
import '../../../data/services/media/recent_uploads_cache.dart';
import '../../../data/services/media/video_thumbnail_service.dart';
import '../image/index.dart';
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
import 'video_trim_sheet.dart';

// ---------------------------------------------------------------------------
// GlobalVideoPicker — single or multi; file or URL; size / duration validation
// ---------------------------------------------------------------------------

/// Unified video picker over [PickerItem]. Supports update flows:
/// hydrate with [PickerItem.url]s from the server and let the user
/// mix in freshly-picked [PickerItem.file]s.
class GlobalVideoPicker extends StatefulWidget {
  const GlobalVideoPicker({
    super.key,
    required this.videos,
    required this.onChanged,
    this.multiple = false,
    this.layout = MediaPickerLayout.grid,
    this.maxVideos = 4,
    this.validator,
    this.style = const MediaPickerStyle(),
    this.onError,
    this.onDownload,
    this.label,
    this.hint,
    this.icon,
    this.enabled = true,
    this.recentCache,
    this.autoCacheOnPick = false,
    this.uploadController,
    this.autoUpload = false,
    this.enableTrim = false,
    this.showThumbnails = true,
    this.maxRecordingDuration,
    this.cameraLabel,
    this.galleryLabel,
    this.cancelLabel,
    this.recentTitle,
  }) : assert(
         !multiple || videos is List<PickerItem>,
         'For `multiple: true`, pass a `List<PickerItem>` to `videos`.',
       ),
       assert(
         multiple || videos is PickerItem?,
         'For single mode, pass a `PickerItem?` to `videos`.',
       );

  final Object? videos;
  final ValueChanged<dynamic> onChanged;

  final bool multiple;
  final MediaPickerLayout layout;
  final int maxVideos;

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

  final String? label;
  final String? hint;
  final IconData? icon;
  final bool enabled;

  /// Auto-feed picked file items into [RecentUploadsCache] so the
  /// combined overlay shows them next tap. Off by default — prod
  /// apps typically cache after upload succeeds.
  final bool autoCacheOnPick;

  /// Optional per-item upload tracker. When attached, tiles render
  /// progress rings + error overlays + retry on tap.
  final UploadController? uploadController;

  /// Auto-start upload for each newly added `PickerItemFile`.
  final bool autoUpload;

  /// Show a scissor icon on each file-backed tile that opens a
  /// trim / thumbnail-picker sheet. Save replaces the picked file
  /// in-place with the trimmed MP4.
  final bool enableTrim;

  /// Replace the generic play icon with an actual frame extracted
  /// from the video (file-backed tiles only). Set false when you
  /// want a smaller binary footprint.
  final bool showThumbnails;

  final Duration? maxRecordingDuration;

  final String? cameraLabel;
  final String? galleryLabel;
  final String? cancelLabel;
  final String? recentTitle;

  @override
  State<GlobalVideoPicker> createState() => _GlobalVideoPickerState();
}

class _GlobalVideoPickerState extends State<GlobalVideoPicker> {
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

  /// True once we've ever seen a [PickerItemUrl] — gate for the
  /// "NEW" badge so fresh picks in a pure add-only screen don't
  /// shout NEW at the user.
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
  void didUpdateWidget(GlobalVideoPicker old) {
    super.didUpdateWidget(old);
    if (old.style != widget.style) _rs = widget.style.resolve(context);
    _refreshUrlFlag();
  }

  void _refreshUrlFlag() {
    if (_hadUrl) return;
    final v = widget.videos;
    final seen = switch (v) {
      List<PickerItem>() => v.any((e) => e is PickerItemUrl),
      PickerItem() => v is PickerItemUrl,
      _ => false,
    };
    if (seen) _hadUrl = true;
  }

  List<PickerItem> get _multi =>
      widget.multiple ? (widget.videos as List<PickerItem>) : const [];
  PickerItem? get _single =>
      widget.multiple ? null : widget.videos as PickerItem?;

  Future<File?> _runValidator(File f) async {
    final err = await widget.validator?.validate(f);
    if (err != null) {
      setState(() => _error = err.message);
      widget.onError?.call(err);
      return null;
    }
    return f;
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
    return cache.add(item, AttachmentKind.video);
  }

  /// Video thumbnails — keyed by source path, generated lazily so
  /// we don't block first paint. `null` = failed / still loading.
  final Map<String, File?> _thumbCache = {};

  Future<void> _ensureThumb(String path) async {
    if (_thumbCache.containsKey(path)) return;
    _thumbCache[path] = null;
    final f = await VideoThumbnailService.at(path);
    if (!mounted) return;
    setState(() => _thumbCache[path] = f);
  }

  Future<void> _openTrim(PickerItemFile item) async {
    final result = await showVideoTrimSheet(
      context: context,
      source: item.file,
      maxDuration: widget.maxRecordingDuration,
    );
    if (result?.file == null) return;
    final replaced = PickerItem.file(
      result!.file!,
      isNew: item.isNew,
      filename: item.filename,
    );
    if (widget.multiple) {
      final idx = _multi.indexOf(item);
      if (idx < 0) return;
      final next = [..._multi];
      next[idx] = replaced;
      _emit(next);
    } else {
      _emit(replaced);
    }
    // Drop cached thumbnail for the old path + pre-warm the new.
    _thumbCache.remove(item.file.path);
    if (result.thumbnailMs != null) {
      final thumb = await VideoThumbnailService.at(
        result.file!.path,
        timeMs: result.thumbnailMs!,
      );
      if (!mounted || thumb == null) return;
      setState(() => _thumbCache[result.file!.path] = thumb);
    }
  }

  Future<void> _pickOne(MediaPickerSourceOption source) async {
    final picked = await MediaPickerService.pickVideo(
      source: imageSourceFrom(source),
      maxDuration: widget.maxRecordingDuration,
    );
    if (picked == null) return;
    final ready = await _runValidator(picked);
    if (ready == null) return;
    final wrapped = await _autoCache(_wrap(ready));
    if (widget.multiple) {
      final next = [..._multi];
      if (next.length < widget.maxVideos) next.add(wrapped);
      _emit(next);
    } else {
      _emit(wrapped);
    }
  }

  Future<void> _pickMany() async {
    final remaining = widget.maxVideos - _multi.length;
    if (remaining <= 0) return;
    // image_picker requires limit >= 2; fall back to single-pick
    // when only one slot is left.
    if (remaining == 1) {
      await _pickOne(MediaPickerSourceOption.gallery);
      return;
    }
    final picked = await MediaPickerService.pickMultipleVideos(
      maxDuration: widget.maxRecordingDuration,
      limit: remaining,
    );
    if (picked.isEmpty) return;
    final next = [..._multi];
    for (final f in picked) {
      if (next.length >= widget.maxVideos) break;
      final ready = await _runValidator(f);
      if (ready != null) next.add(await _autoCache(_wrap(ready)));
    }
    _emit(next);
  }

  Future<MediaPickerSourceOption?> _showSourceSheet() async {
    if (!_rs.allowCamera && !_rs.allowClipboard) {
      return MediaPickerSourceOption.gallery;
    }
    final clipHas = _rs.allowClipboard
        ? await ClipboardImageService.hasFiles(extensionsWhitelist: _videoExts)
        : false;
    if (!mounted) return null;
    return showMediaSourceSheet(
      context: context,
      galleryIcon: Icons.video_library_rounded,
      cameraIcon: Icons.videocam_rounded,
      galleryLabel: widget.galleryLabel,
      cameraLabel: widget.cameraLabel,
      cancelLabel: widget.cancelLabel,
      showCamera: _rs.allowCamera,
      showClipboard: _rs.allowClipboard,
      clipboardEnabled: clipHas,
    );
  }

  Future<void> _handleTap() async {
    if (!widget.enabled || _busy) return;
    if (widget.multiple && _multi.length >= widget.maxVideos) return;

    final cache = _rs.useRecentCache ? widget.recentCache : null;
    final recent = cache?.recent(AttachmentKind.video) ?? const <PickerItem>[];

    if (recent.isNotEmpty) {
      final sources = <MediaPickerSourceOption>[
        MediaPickerSourceOption.gallery,
        if (_rs.allowCamera) MediaPickerSourceOption.camera,
        if (_rs.allowClipboard) MediaPickerSourceOption.clipboard,
      ];
      final remaining = widget.multiple ? widget.maxVideos - _multi.length : 1;
      final result = await showRecentPickerOverlay(
        context: context,
        sections: {AttachmentKind.video: recent},
        sourceOptions: sources,
        title: widget.recentTitle,
        galleryLabel: widget.galleryLabel,
        cameraLabel: widget.cameraLabel,
        cancelLabel: widget.cancelLabel,
        allowMultiSelect: widget.multiple && remaining > 1,
        maxSelection: remaining,
        onRemove: (item, kind) => cache!.remove(item, kind),
        onClearAll: () => cache!.clear(AttachmentKind.video),
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
      if (result.source != null) {
        await _runSource(result.source!);
      }
      return;
    }

    final src = await _showSourceSheet();
    if (src == null) return;
    await _runSource(src);
  }

  Future<void> _runSource(MediaPickerSourceOption src) async {
    if (src == MediaPickerSourceOption.clipboard) {
      await _pasteFromClipboard();
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (widget.multiple && src == MediaPickerSourceOption.gallery) {
        await _pickMany();
      } else {
        await _pickOne(src);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _acceptCached(PickerItem item) async {
    if (item is PickerItemFile) {
      if (await _runValidator(item.file) == null) return;
    }
    if (widget.multiple) {
      if (_multi.length >= widget.maxVideos) return;
      _emit([..._multi, item]);
    } else {
      _emit(item);
    }
  }

  Future<void> _acceptCachedBatch(List<PickerItem> items) async {
    final next = [..._multi];
    for (final item in items) {
      if (next.length >= widget.maxVideos) break;
      if (item is PickerItemFile) {
        if (await _runValidator(item.file) == null) continue;
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
            if (_busy) Positioned.fill(child: _busyOverlay(context)),
          ],
        ),
        if (_error != null) MediaPickerInlineError(message: _error!),
      ],
    );
  }

  // ─── Single ─────────────────────────────────────────────────────

  Widget _singleBody(BuildContext context) {
    final item = _single;
    if (item == null) {
      return _addSlot(
        context,
        height: _rs.tileHeight,
        child: _placeholder(context),
      );
    }
    return PickerFilledSlot(
      style: _rs,
      height: _rs.tileHeight,
      // The tile clips its own picture — see `clip`.
      clip: false,
      child: _preview(context, item, () => _removeAt(0)),
    );
  }

  // ─── Multi ──────────────────────────────────────────────────────

  Widget _multiBody(BuildContext context) {
    return widget.layout == MediaPickerLayout.horizontalList
        ? _multiHorizontalBody(context)
        : _multiGridBody(context);
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

  /// Video file extensions the paste menu will honor when the
  /// clipboard holds file references. Anything outside the list
  /// (e.g. PDFs, images) is filtered out so a "Paste" action never
  /// slips non-video bytes into a video-only slot.
  static const List<String> _videoExts = [
    'mp4',
    'mov',
    'm4v',
    'webm',
    'mkv',
    'avi',
    '3gp',
    'mpeg',
  ];

  bool _clipboardHasVideo = false;

  List<GlobalPopupMenuItem<MediaPickerSourceOption>> _buildAddMenuItems() {
    return [
      GlobalPopupMenuItem(
        value: MediaPickerSourceOption.gallery,
        label: widget.galleryLabel ?? MediaStrings.gallery,
        icon: Icons.video_library_rounded,
      ),
      if (_rs.allowCamera)
        GlobalPopupMenuItem(
          value: MediaPickerSourceOption.camera,
          label: widget.cameraLabel ?? MediaStrings.record,
          icon: Icons.videocam_rounded,
        ),
      if (_rs.allowClipboard)
        GlobalPopupMenuItem(
          value: MediaPickerSourceOption.clipboard,
          label: _clipboardHasVideo ? 'Clipboard' : 'Clipboard (empty)',
          icon: Icons.content_paste_rounded,
          enabled: _clipboardHasVideo,
        ),
    ];
  }

  Widget _addSlot(
    BuildContext context, {
    required double height,
    required Widget child,
  }) {
    final interactable = PickerInteractable(
      onActivate: _handleTap,
      label: widget.hint ?? MediaStrings.addVideo,
      borderRadius: _rs.tileBorderRadius,
      tooltip: _rs.allowClipboard ? MediaStrings.addVideo : null,
      child: PickerEmptySlot(style: _rs, height: height, child: child),
    );
    final withMenu = (!_rs.allowClipboard && !_rs.allowCamera)
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
              final has = _rs.allowClipboard
                  ? await ClipboardImageService.hasFiles(
                      extensionsWhitelist: _videoExts,
                    )
                  : false;
              if (mounted) setState(() => _clipboardHasVideo = has);
            },
            items: _buildAddMenuItems(),
            onSelected: _runSource,
            anchor: interactable,
          );
    return PickerDropRegion(
      extensionWhitelist: _videoExts,
      onFilesDropped: _handleDroppedFiles,
      child: withMenu,
    );
  }

  Future<void> _handleDroppedFiles(List<File> files) async {
    if (!widget.enabled || files.isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final next = widget.multiple ? [..._multi] : <PickerItem>[];
      for (final f in files) {
        if (widget.multiple && next.length >= widget.maxVideos) break;
        final ready = await _runValidator(f);
        if (ready == null) continue;
        final wrapped = await _autoCache(_wrap(ready));
        if (widget.multiple) {
          next.add(wrapped);
        } else {
          _emit(wrapped);
          return;
        }
      }
      if (widget.multiple) _emit(next);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pasteFromClipboard() async {
    if (widget.multiple && _multi.length >= widget.maxVideos) return;
    final files = await ClipboardImageService.pasteFiles(
      extensionsWhitelist: _videoExts,
    );
    if (files.isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final next = [..._multi];
      for (final f in files) {
        if (widget.multiple && next.length >= widget.maxVideos) break;
        final ready = await _runValidator(f);
        if (ready == null) continue;
        final wrapped = await _autoCache(_wrap(ready));
        if (widget.multiple) {
          next.add(wrapped);
        } else {
          _emit(wrapped);
          return;
        }
      }
      if (widget.multiple) _emit(next);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _copyToClipboard(PickerItemFile item) async {
    final ok = await ClipboardImageService.copyFiles([item.file]);
    if (!mounted) return;
    if (ok) {
      GlobalToast.success(MediaStrings.videoCopied);
    } else {
      GlobalToast.error(MediaStrings.copyFailed);
    }
  }

  Widget _multiGridBody(BuildContext context) {
    final items = _multi;
    final slots = widget.maxVideos;
    final tileW = _rs.tileWidth ?? _rs.cellSize;
    final tileH = _rs.tileHeight;
    final filled = <Widget>[
      for (var i = 0; i < items.length; i++)
        SizedBox(
          key: ValueKey(_tileKey(items[i], i)),
          width: tileW,
          height: tileH,
          child: PickerFilledSlot(
            style: _rs,
            height: tileH,
            child: _thumbTile(context, items[i], () => _removeAt(i)),
          ),
        ),
    ];
    final empty = <Widget>[
      for (var i = 0; i < slots - items.length; i++)
        SizedBox(
          key: ValueKey('add-$i'),
          width: tileW,
          height: tileH,
          child: _addSlot(context, height: tileH, child: _placeholder(context)),
        ),
    ];
    if (_rs.reorderable && items.length > 1) {
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
    return Wrap(spacing: 8, runSpacing: 8, children: [...filled, ...empty]);
  }

  Widget _multiHorizontalBody(BuildContext context) {
    final items = _multi;
    final canAdd = items.length < widget.maxVideos;
    final tileW = _rs.tileWidth ?? _rs.cellSize;
    final tileH = _rs.tileHeight;
    final addTile = canAdd
        ? SizedBox(
            key: const ValueKey('add-tile'),
            width: tileW,
            height: tileH,
            child: _addSlot(context, height: tileH, child: _addTile(context)),
          )
        : null;
    if (_rs.reorderable && items.length > 1) {
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
            for (var i = 0; i < items.length; i++)
              Padding(
                key: ValueKey(_tileKey(items[i], i)),
                padding: EdgeInsets.only(right: i == items.length - 1 ? 0 : 8),
                child: SizedBox(
                  width: tileW,
                  height: tileH,
                  child: PickerFilledSlot(
                    style: _rs,
                    height: tileH,
                    child: _thumbTile(context, items[i], () => _removeAt(i)),
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
        itemCount: items.length + (canAdd ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          if (i < items.length) {
            return SizedBox(
              width: tileW,
              height: tileH,
              child: PickerFilledSlot(
                style: _rs,
                height: tileH,
                child: _thumbTile(context, items[i], () => _removeAt(i)),
              ),
            );
          }
          return addTile ?? const SizedBox.shrink();
        },
      ),
    );
  }

  // ─── Tile content ───────────────────────────────────────────────

  Future<void> _openLightbox(PickerItem tapped) async {
    final list = widget.multiple ? _multi : <PickerItem>[tapped];
    final idx = list.indexOf(tapped).clamp(0, list.length - 1);
    await showPickerLightbox(
      context: context,
      items: list,
      kinds: List.filled(list.length, AttachmentKind.video),
      initialIndex: idx,
    );
  }

  Widget _thumbTile(
    BuildContext context,
    PickerItem item,
    VoidCallback onRemove,
  ) {
    final name = _nameFor(item);
    // Kick off thumbnail decode for file-backed tiles on first
    // render. Result caches in [_thumbCache]; subsequent frames
    // paint it directly via Image.file.
    if (widget.showThumbnails && item is PickerItemFile) {
      final path = item.file.path;
      if (!_thumbCache.containsKey(path)) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _ensureThumb(path));
      }
    }
    final thumb = item is PickerItemFile ? _thumbCache[item.file.path] : null;
    return Stack(
      children: [
        Positioned.fill(
          // Tap play icon area → lightbox player. Badge/remove dots
          // sit above and capture their own taps.
          // See the image picker: the PICTURE is clipped, not the
          // tile, so the dots at its corners survive a round slot.
          child: ClipRRect(
            borderRadius: _rs.tileBorderRadius,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _openLightbox(item),
              child: Container(
                color: _rs.surfaceColor,
                alignment: Alignment.center,
                child: thumb != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          GlobalImage.f(
                            thumb,
                            style: const ImageStyle(
                              borderRadius: BorderRadius.zero,
                            ),
                          ),
                          Container(color: Colors.black26),
                          Center(
                            child: Icon(
                              Icons.play_circle_fill_rounded,
                              color: Colors.white.withValues(alpha: 0.9),
                              size: 36,
                            ),
                          ),
                        ],
                      )
                    : Icon(
                        Icons.play_circle_fill_rounded,
                        color: _rs.accent,
                        size: 36,
                      ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 4,
          left: 4,
          right: 4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: _rs.dotScrim,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: context.textTheme.labelSmall?.fontSize,
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
            bottom: 32,
            right: 4,
            child: PickerActionDot(
              action: PickerDotAction.copy,
              style: _rs,
              copyLabel: MediaStrings.copyVideoTooltip,
              onTap: () => _copyToClipboard(item),
            ),
          ),
        if (widget.enableTrim && item is PickerItemFile)
          Positioned(
            bottom: 32,
            left: 4,
            child: PickerActionDot(
              action: PickerDotAction.trim,
              style: _rs,
              onTap: () => _openTrim(item),
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

  Widget _preview(
    BuildContext context,
    PickerItem item,
    VoidCallback onRemove,
  ) {
    final name = _nameFor(item);
    // A FRAME of the video, not a glyph and a filename. The multi-tile
    // path already decoded one; the single preview — the one an avatar
    // or a "single video" field actually shows — did not, so the
    // commonest case was the one with nothing to look at.
    if (widget.showThumbnails && item is PickerItemFile) {
      final path = item.file.path;
      if (!_thumbCache.containsKey(path)) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _ensureThumb(path));
      }
    }
    final thumb = item is PickerItemFile ? _thumbCache[item.file.path] : null;

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _openLightbox(item),
            child: Container(
              color: _rs.surfaceColor,
              alignment: Alignment.center,
              child: thumb != null
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        GlobalImage.f(
                          thumb,
                          style: const ImageStyle(
                            borderRadius: BorderRadius.zero,
                          ),
                        ),
                        // A scrim, so the play glyph reads over a
                        // bright frame.
                        const ColoredBox(color: MediaPickerDefaults.busyScrim),
                        Center(
                          child: Icon(
                            Icons.play_circle_fill_rounded,
                            color: _rs.badgeTextColor,
                            size: 48,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.play_circle_fill_rounded,
                          size: 48,
                          color: _rs.accent,
                        ),
                        const SizedBox(height: MediaPickerDefaults.hintGap),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: MediaPickerDefaults.gapLg,
                          ),
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
                      ],
                    ),
            ),
          ),
        ),
        if (item is PickerItemFile && item.isNew)
          Positioned(top: 6, left: 6, child: PickerNewBadge(style: _rs)),
        if (item is PickerItemUrl && widget.onDownload != null)
          Positioned(
            top: 6,
            left: 6,
            child: PickerActionDot(
              action: PickerDotAction.download,
              style: _rs,
              onTap: () => widget.onDownload!(item),
            ),
          ),
        if (_rs.allowClipboard && item is PickerItemFile)
          Positioned(
            bottom: 6,
            right: 6,
            child: PickerActionDot(
              action: PickerDotAction.copy,
              style: _rs,
              copyLabel: MediaStrings.copyVideoTooltip,
              onTap: () => _copyToClipboard(item),
            ),
          ),
        Positioned(
          top: 6,
          right: 6,
          child: PickerActionDot(
            action: PickerDotAction.remove,
            style: _rs,
            onTap: onRemove,
          ),
        ),
      ],
    );
  }

  String _nameFor(PickerItem item) {
    return switch (item) {
      PickerItemFile() => item.displayName,
      PickerItemUrl() => item.displayName,
      PickerItemBytes() => item.displayName,
    };
  }

  // ─── Slots ──────────────────────────────────────────────────────

  Widget _placeholder(BuildContext context) {
    // See the image picker: below `hintMinHeight` the hint is DROPPED
    // rather than shrunk, because a Column that does not fit is
    // eighteen pixels of yellow-and-black stripes.
    return LayoutBuilder(
      builder: (context, constraints) {
        final room =
            constraints.hasBoundedHeight &&
            constraints.maxHeight >= MediaPickerDefaults.hintMinHeight;
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon ?? Icons.videocam_outlined,
                size: _rs.placeholderIconSize,
                color: _rs.accent,
              ),
              if (widget.hint != null && room) ...[
                const SizedBox(height: MediaPickerDefaults.hintGap),
                Flexible(
                  child: Text(
                    widget.hint!,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _rs.hintColor,
                      fontSize: _rs.hintFontSize,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _addTile(BuildContext context) {
    return Center(
      child: Icon(
        widget.icon ?? Icons.add_rounded,
        size: 28,
        color: _rs.accent,
      ),
    );
  }

  // ─── Badges ─────────────────────────────────────────────────────

  Widget _busyOverlay(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: MediaPickerDefaults.busyScrim,
        // THE SHAPE OF WHAT IT COVERS — a tile's corner only in the
        // single-slot picker. Over a row or a grid the scrim is the
        // size of the whole section, and a box covering many tiles
        // has no corner of its own. See `GlobalImagePicker`.
        borderRadius: widget.multiple
            ? BorderRadius.zero
            : _rs.tileBorderRadius,
      ),
      alignment: Alignment.center,
      child: SizedBox(
        height: 28,
        width: 28,
        child: GlobalProgress.loading(
          type: ProgressType.circular,
          style: const ProgressStyle(thickness: 2.5, color: Colors.white),
        ),
      ),
    );
  }
}
