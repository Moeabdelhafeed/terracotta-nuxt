// Dart imports:
import 'dart:io';

import 'package:file_picker/file_picker.dart' as fp;
import 'package:flutter/material.dart';
import 'package:reorderables/reorderables.dart';

// Flutter imports:
// Package imports:
// Project imports:
import '../../../core/constants/enums/media/image_type.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/strings/media_strings.dart';
import '../../../data/services/media/file_picker_service.dart';
import '../../../data/services/media/image_compression_service.dart';
import '../../../data/services/media/image_cropper_service.dart';
import '../../../data/services/media/media_picker_service.dart';
import '../../../data/services/media/recent_uploads_cache.dart';
import '../icon/global_icon.dart';
import '../image/index.dart';
import '../progress/global_progress.dart';
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
// GlobalAttachmentPicker — mixed image / video / file, single widget
// ---------------------------------------------------------------------------

/// Chat-composer-style attachment picker. Tap the add tile → sheet
/// asks for [AttachmentKind] (photo / video / file). For image +
/// video, a second sheet picks gallery vs camera.
///
/// Caller owns `List<Attachment>`; items carry their own [Attachment.kind]
/// so the UI picks the right preview (thumb for image, play icon for
/// video, file icon for file).
///
/// ```dart
/// GlobalAttachmentPicker(
///   attachments: state.items,
///   onChanged: cubit.setAttachments,
///   maxItems: 6,
///   layout: MediaPickerLayout.horizontalList,
///   imageValidator: const MediaPickerValidator(maxSizeBytes: 5 * 1024 * 1024),
///   videoValidator: const MediaPickerValidator(maxSizeBytes: 50 * 1024 * 1024),
///   fileValidator: const MediaPickerValidator(allowedExtensions: ['pdf']),
///   onError: (e) => ...,
/// );
/// ```
class GlobalAttachmentPicker extends StatefulWidget {
  const GlobalAttachmentPicker({
    super.key,
    required this.attachments,
    required this.onChanged,
    this.maxItems = 4,
    this.maxImageItems,
    this.maxVideoItems,
    this.maxFileItems,
    this.layout = MediaPickerLayout.grid,
    this.kinds = const [
      AttachmentKind.image,
      AttachmentKind.video,
      AttachmentKind.file,
    ],
    this.imageValidator,
    this.videoValidator,
    this.fileValidator,
    this.cropImagesAfterPick = false,
    this.cropToolbarTitle,
    this.cropOptions,
    this.onError,
    this.style = const MediaPickerStyle(),
    this.onDownload,
    this.recentCache,
    this.autoCacheOnPick = false,
    this.uploadController,
    this.autoUpload = false,
    this.recentTitle,
    this.label,
    this.hint,
    this.enabled = true,
    this.fileType = fp.FileType.any,
    this.allowedFileExtensions,
    // Labels
    this.sheetTitle,
    this.imageLabel,
    this.videoLabel,
    this.fileLabel,
    this.cameraLabel,
    this.galleryLabel,
    this.cancelLabel,
  });

  final List<Attachment> attachments;
  final ValueChanged<List<Attachment>> onChanged;

  /// Cap across all types combined.
  final int maxItems;

  /// Optional per-kind caps. When null, only [maxItems] applies.
  /// When set, both caps are enforced — the tighter one wins.
  final int? maxImageItems;
  final int? maxVideoItems;
  final int? maxFileItems;

  final MediaPickerLayout layout;

  /// Which kinds show up in the first sheet. Defaults to all 3.
  final List<AttachmentKind> kinds;

  final MediaPickerValidator? imageValidator;
  final MediaPickerValidator? videoValidator;
  final MediaPickerValidator? fileValidator;

  /// Offer the user a crop step after picking an image. Uses
  /// `imageValidator.imageAspectRatio` to lock the ratio when set.
  final bool cropImagesAfterPick;

  /// Title shown on the native cropper chrome. Ignored when
  /// [cropOptions] is non-null.
  final String? cropToolbarTitle;

  /// Full cropper configuration for picked images. When non-null,
  /// overrides the default (locked-ratio from `imageValidator`).
  final CropOptions? cropOptions;

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

  /// Fired when the user taps the download icon on a URL-backed
  /// attachment. Hidden when null.
  final ValueChanged<PickerItemUrl>? onDownload;

  /// Auto-feed picked file items into [RecentUploadsCache] so the
  /// combined overlay shows them next tap. Off by default — prod
  /// apps typically cache after upload succeeds.
  final bool autoCacheOnPick;

  /// Optional per-item upload tracker. When attached, tiles render
  /// progress rings + error overlays + retry on tap.
  final UploadController? uploadController;

  /// Auto-start upload for each newly added file-backed attachment.
  final bool autoUpload;

  final String? recentTitle;

  final String? label;
  final String? hint;
  final bool enabled;

  final fp.FileType fileType;
  final List<String>? allowedFileExtensions;

  final String? sheetTitle;
  final String? imageLabel;
  final String? videoLabel;
  final String? fileLabel;
  final String? cameraLabel;
  final String? galleryLabel;
  final String? cancelLabel;

  @override
  State<GlobalAttachmentPicker> createState() => _GlobalAttachmentPickerState();
}

class _GlobalAttachmentPickerState extends State<GlobalAttachmentPicker> {
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

  /// True once we've ever observed a URL-backed attachment —
  /// indicates update-page context. Fresh files added to a
  /// purely-empty picker skip the "NEW" badge.
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
  void didUpdateWidget(GlobalAttachmentPicker old) {
    super.didUpdateWidget(old);
    if (old.style != widget.style) _rs = widget.style.resolve(context);
    _refreshUrlFlag();
  }

  void _refreshUrlFlag() {
    if (_hadUrl) return;
    if (widget.attachments.any((a) => a.source is PickerItemUrl)) {
      _hadUrl = true;
    }
  }

  List<Attachment> get _items => widget.attachments;

  void _maybeAutoUpload(Attachment a) {
    if (!widget.autoUpload) return;
    final ctrl = widget.uploadController;
    if (ctrl == null) return;
    final src = a.source;
    if (src is! PickerItemFile) return;
    ctrl.start(src);
  }

  void _emit(List<Attachment> next) {
    final prev = List<Attachment>.from(_items);
    final prevKeys = prev
        .where((a) => a.source is PickerItemFile)
        .map((a) => (a.source as PickerItemFile).file.path)
        .toSet();
    final nextKeys = next
        .where((a) => a.source is PickerItemFile)
        .map((a) => (a.source as PickerItemFile).file.path)
        .toSet();
    final ctrl = widget.uploadController;
    if (ctrl != null) {
      for (final a in prev) {
        final s = a.source;
        if (s is PickerItemFile && !nextKeys.contains(s.file.path)) {
          ctrl.forget(s);
        }
      }
    }
    for (final a in next) {
      final s = a.source;
      if (s is PickerItemFile && !prevKeys.contains(s.file.path)) {
        _maybeAutoUpload(a);
      }
    }
    widget.onChanged(next);
  }

  void _reportError(MediaPickerError err) {
    setState(() => _error = err.message);
    widget.onError?.call(err);
  }

  /// Per-kind cap (null = no per-kind limit).
  int? _kindCap(AttachmentKind k) => switch (k) {
    AttachmentKind.image => widget.maxImageItems,
    AttachmentKind.video => widget.maxVideoItems,
    AttachmentKind.file => widget.maxFileItems,
  };

  int _countInOf(List<Attachment> items, AttachmentKind k) =>
      items.where((a) => a.kind == k).length;

  bool _atKindLimit(AttachmentKind k) {
    final cap = _kindCap(k);
    return cap != null && _countInOf(_items, k) >= cap;
  }

  /// True when adding another item of [k] would exceed the overall
  /// [maxItems] OR the per-kind cap.
  bool _wouldExceed(List<Attachment> items, AttachmentKind k) {
    if (items.length >= widget.maxItems) return true;
    final cap = _kindCap(k);
    return cap != null && _countInOf(items, k) >= cap;
  }

  Future<void> _handleTap() async {
    if (!widget.enabled || _busy) return;
    if (_items.length >= widget.maxItems) return;

    final cache = _rs.useRecentCache ? widget.recentCache : null;

    // Pull recent entries for every kind the attachment picker
    // surfaces. Empty sections drop out inside the overlay.
    final sections = <AttachmentKind, List<PickerItem>>{};
    if (cache != null) {
      for (final k in widget.kinds) {
        final list = cache.recent(k);
        if (list.isNotEmpty) sections[k] = list;
      }
    }

    if (sections.isNotEmpty) {
      final remaining = widget.maxItems - _items.length;
      // Per-kind budget surfaced to the overlay: (cap - existing).
      // Only include kinds that have a cap configured.
      final perKindRemaining = <AttachmentKind, int>{
        for (final k in AttachmentKind.values)
          if (_kindCap(k) != null)
            k: (_kindCap(k)! - _countInOf(_items, k)).clamp(0, 1 << 30),
      };
      final result = await showRecentPickerOverlay(
        context: context,
        sections: sections,
        // Single "Choose source" row leads into the kind sheet +
        // existing per-kind gallery/camera flow.
        sourceOptions: const [MediaPickerSourceOption.gallery],
        title: widget.recentTitle,
        galleryLabel: widget.sheetTitle ?? MediaStrings.addAttachment,
        cancelLabel: widget.cancelLabel,
        allowMultiSelect: remaining > 1,
        maxSelection: remaining,
        maxPerKind: perKindRemaining,
        onRemove: (item, kind) => cache!.remove(item, kind),
        onClearAll: () async {
          for (final k in widget.kinds) {
            await cache!.clear(k);
          }
        },
      );
      if (result == null) return;
      if (result.cachedItems != null) {
        final next = [..._items];
        for (final (item, kind) in result.cachedItems!) {
          if (_wouldExceed(next, kind)) continue;
          if (item is PickerItemFile) {
            final validator = switch (kind) {
              AttachmentKind.image => widget.imageValidator,
              AttachmentKind.video => widget.videoValidator,
              AttachmentKind.file => widget.fileValidator,
            };
            final err = await validator?.validate(item.file);
            if (err != null) {
              _reportError(err);
              continue;
            }
          }
          next.add(Attachment(source: item, kind: kind));
        }
        _emit(next);
        return;
      }
      if (result.cached != null && result.cachedKind != null) {
        final cached = result.cached!;
        final cachedKind = result.cachedKind!;
        if (_wouldExceed(_items, cachedKind)) return;
        if (cached is PickerItemFile) {
          final validator = switch (cachedKind) {
            AttachmentKind.image => widget.imageValidator,
            AttachmentKind.video => widget.videoValidator,
            AttachmentKind.file => widget.fileValidator,
          };
          final err = await validator?.validate(cached.file);
          if (err != null) {
            _reportError(err);
            return;
          }
        }
        _emit([
          ..._items,
          Attachment(source: cached, kind: cachedKind),
        ]);
        return;
      }
      // Source tapped → fall through to kind sheet below.
    }

    final kind = await showAttachmentKindSheet(
      context: context,
      kinds: widget.kinds,
      disabledKinds: {
        for (final k in widget.kinds)
          if (_atKindLimit(k)) k,
      },
      imageLabel: widget.imageLabel,
      videoLabel: widget.videoLabel,
      fileLabel: widget.fileLabel,
      cancelLabel: widget.cancelLabel,
    );
    if (kind == null) return;

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      switch (kind) {
        case AttachmentKind.image:
          await _addImage();
        case AttachmentKind.video:
          await _addVideo();
        case AttachmentKind.file:
          await _addFile();
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _addImage() async {
    if (_wouldExceed(_items, AttachmentKind.image)) return;
    MediaPickerSourceOption? src;
    if (_rs.allowCamera) {
      src = await showMediaSourceSheet(
        context: context,
        galleryLabel: widget.galleryLabel,
        cameraLabel: widget.cameraLabel,
        cancelLabel: widget.cancelLabel,
      );
      if (src == null) return;
    } else {
      src = MediaPickerSourceOption.gallery;
    }
    final picked = await MediaPickerService.pickImage(
      source: imageSourceFrom(src),
    );
    if (picked == null) return;
    var working = picked;
    // Crop BEFORE validation so a ratio-locked validator doesn't
    // reject the raw pick — user should always get a crop chance.
    if (widget.cropImagesAfterPick) {
      final options =
          widget.cropOptions ??
          CropOptions(
            aspectRatio: widget.imageValidator?.imageAspectRatio,
            toolbarTitle: widget.cropToolbarTitle ?? MediaStrings.cropTitle,
          );
      final cropped = await ImageCropperService.crop(working, options: options);
      if (cropped == null) return;
      working = cropped;
    }
    final err = await widget.imageValidator?.validate(working);
    if (err != null) {
      _reportError(err);
      return;
    }
    var ready = _rs.compress
        ? await ImageCompressionService.compressImage(working) ?? working
        : working;
    if (widget.imageValidator?.stripExif ?? false) {
      ready = await ImageCompressionService.stripExif(ready);
    }
    final source = await _autoCache(
      PickerItem.file(ready, isNew: _hadUrl),
      AttachmentKind.image,
    );
    _emit([
      ..._items,
      Attachment(source: source, kind: AttachmentKind.image),
    ]);
  }

  Future<PickerItem> _autoCache(PickerItem item, AttachmentKind kind) async {
    if (!widget.autoCacheOnPick) return item;
    final cache = widget.recentCache;
    if (cache == null) return item;
    return cache.add(item, kind);
  }

  Future<void> _addVideo() async {
    if (_wouldExceed(_items, AttachmentKind.video)) return;
    MediaPickerSourceOption? src;
    if (_rs.allowCamera) {
      src = await showMediaSourceSheet(
        context: context,
        galleryIcon: Icons.video_library_rounded,
        cameraIcon: Icons.videocam_rounded,
        galleryLabel: widget.galleryLabel,
        cameraLabel: widget.cameraLabel,
        cancelLabel: widget.cancelLabel,
      );
      if (src == null) return;
    } else {
      src = MediaPickerSourceOption.gallery;
    }
    final picked = await MediaPickerService.pickVideo(
      source: imageSourceFrom(src),
    );
    if (picked == null) return;
    final err = await widget.videoValidator?.validate(picked);
    if (err != null) {
      _reportError(err);
      return;
    }
    final source = await _autoCache(
      PickerItem.file(picked, isNew: _hadUrl),
      AttachmentKind.video,
    );
    _emit([
      ..._items,
      Attachment(source: source, kind: AttachmentKind.video),
    ]);
  }

  Future<void> _addFile() async {
    if (_wouldExceed(_items, AttachmentKind.file)) return;
    final picked = await FilePickerService.pickFile(
      type: widget.fileType,
      allowedExtensions: widget.allowedFileExtensions,
    );
    if (picked == null) return;
    final err = await widget.fileValidator?.validate(picked);
    if (err != null) {
      _reportError(err);
      return;
    }
    final source = await _autoCache(
      PickerItem.file(picked, isNew: _hadUrl),
      AttachmentKind.file,
    );
    _emit([
      ..._items,
      Attachment(source: source, kind: AttachmentKind.file),
    ]);
  }

  void _removeAt(int i) {
    final next = [..._items]..removeAt(i);
    _emit(next);
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
              child: widget.layout == MediaPickerLayout.horizontalList
                  ? _horizontalBody(context)
                  : _gridBody(context),
            ),
            if (_busy) Positioned.fill(child: _busyOverlay(context)),
          ],
        ),
        if (_error != null) MediaPickerInlineError(message: _error!),
      ],
    );
  }

  // ───────── layouts ─────────

  void _reorder(int oldIndex, int newIndex) {
    final next = [..._items];
    var to = newIndex;
    if (to > oldIndex) to -= 1;
    final moved = next.removeAt(oldIndex);
    next.insert(to, moved);
    _emit(next);
  }

  String _tileKey(Attachment a, int i) => switch (a.source) {
    PickerItemFile(:final file) => 'f::${file.path}::$i',
    PickerItemUrl(:final url) => 'u::$url::$i',
    PickerItemBytes(:final filename) => 'b::$filename::$i',
  };

  static const List<String> _imgExts = [
    'jpg',
    'jpeg',
    'png',
    'webp',
    'gif',
    'heic',
  ];
  static const List<String> _vidExts = [
    'mp4',
    'mov',
    'm4v',
    'webm',
    'mkv',
    'avi',
    '3gp',
    'mpeg',
  ];

  AttachmentKind _kindForDrop(String path) {
    final dot = path.lastIndexOf('.');
    if (dot < 0) return AttachmentKind.file;
    final ext = path.substring(dot + 1).toLowerCase();
    if (_imgExts.contains(ext)) return AttachmentKind.image;
    if (_vidExts.contains(ext)) return AttachmentKind.video;
    return AttachmentKind.file;
  }

  Future<void> _handleDroppedFiles(List<File> files) async {
    if (!widget.enabled || files.isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final next = [..._items];
      for (final f in files) {
        final kind = _kindForDrop(f.path);
        if (!widget.kinds.contains(kind)) continue;
        if (_wouldExceed(next, kind)) continue;
        final validator = switch (kind) {
          AttachmentKind.image => widget.imageValidator,
          AttachmentKind.video => widget.videoValidator,
          AttachmentKind.file => widget.fileValidator,
        };
        final err = await validator?.validate(f);
        if (err != null) {
          _reportError(err);
          continue;
        }
        final source = await _autoCache(
          PickerItem.file(f, isNew: _hadUrl),
          kind,
        );
        next.add(Attachment(source: source, kind: kind));
      }
      _emit(next);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _addSlot(BuildContext context, double tileH) {
    // Accepts any file type — the drop handler routes each file
    // to the correct kind based on extension and rejects kinds the
    // picker was told to disable.
    return PickerDropRegion(
      onFilesDropped: _handleDroppedFiles,
      child: PickerInteractable(
        onActivate: _handleTap,
        label: widget.hint ?? MediaStrings.addAttachment,
        borderRadius: _rs.tileBorderRadius,
        child: PickerEmptySlot(
          style: _rs,
          height: tileH,
          child: _addIcon(context),
        ),
      ),
    );
  }

  Widget _gridBody(BuildContext context) {
    final slots = widget.maxItems;
    final tileW = _rs.tileWidth ?? _rs.cellSize;
    final tileH = _rs.tileHeight;
    final filled = <Widget>[
      for (var i = 0; i < _items.length; i++)
        SizedBox(
          key: ValueKey(_tileKey(_items[i], i)),
          width: tileW,
          height: tileH,
          child: _tile(context, _items[i], () => _removeAt(i)),
        ),
    ];
    final empty = <Widget>[
      for (var i = 0; i < slots - _items.length; i++)
        SizedBox(
          key: ValueKey('add-$i'),
          width: tileW,
          height: tileH,
          child: _addSlot(context, tileH),
        ),
    ];
    if (_rs.reorderable && _items.length > 1) {
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

  Widget _horizontalBody(BuildContext context) {
    final canAdd = _items.length < widget.maxItems;
    final tileW = _rs.tileWidth ?? _rs.cellSize;
    final tileH = _rs.tileHeight;
    final addTile = canAdd
        ? SizedBox(
            key: const ValueKey('add-tile'),
            width: tileW,
            height: tileH,
            child: _addSlot(context, tileH),
          )
        : null;
    if (_rs.reorderable && _items.length > 1) {
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
            for (var i = 0; i < _items.length; i++)
              Padding(
                key: ValueKey(_tileKey(_items[i], i)),
                padding: EdgeInsets.only(right: i == _items.length - 1 ? 0 : 8),
                child: SizedBox(
                  width: tileW,
                  height: tileH,
                  child: _tile(context, _items[i], () => _removeAt(i)),
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
        itemCount: _items.length + (canAdd ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          if (i < _items.length) {
            return SizedBox(
              width: tileW,
              height: tileH,
              child: _tile(context, _items[i], () => _removeAt(i)),
            );
          }
          return addTile ?? const SizedBox.shrink();
        },
      ),
    );
  }

  // ───────── tiles ─────────

  Future<void> _openLightbox(Attachment tapped) async {
    final idx = _items.indexOf(tapped).clamp(0, _items.length - 1);
    await showPickerLightbox(
      context: context,
      items: [for (final a in _items) a.source],
      kinds: [for (final a in _items) a.kind],
      initialIndex: idx,
    );
  }

  Widget _tile(BuildContext context, Attachment a, VoidCallback onRemove) {
    final src = a.source;
    final isNew = src is PickerItemFile && src.isNew;
    final isUrl = src is PickerItemUrl;
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _openLightbox(a),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _tileContent(context, a),
            ),
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
        Positioned(
          bottom: 4,
          left: 4,
          child: _kindBadge(context, a.kind),
        ),
        if (widget.uploadController != null)
          UploadOverlay(controller: widget.uploadController!, item: a.source),
        if (isNew)
          Positioned(top: 4, left: 4, child: PickerNewBadge(style: _rs)),
        if (isUrl && widget.onDownload != null)
          Positioned(
            top: 4,
            left: 4,
            child: PickerActionDot(
              action: PickerDotAction.download,
              style: _rs,
              onTap: () => widget.onDownload!(src),
            ),
          ),
      ],
    );
  }

  Widget _tileContent(BuildContext context, Attachment a) {
    final src = a.source;
    switch (a.kind) {
      case AttachmentKind.image:
        return switch (src) {
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
      case AttachmentKind.video:
        return Container(
          color: _rs.surfaceColor,
          alignment: Alignment.center,
          child: Icon(
            Icons.play_circle_fill_rounded,
            size: 36,
            color: _rs.accent,
          ),
        );
      case AttachmentKind.file:
        final name = switch (src) {
          PickerItemFile() => src.displayName,
          PickerItemUrl() => src.displayName,
          PickerItemBytes() => src.displayName,
        };
        return Container(
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
        );
    }
  }

  Widget _kindBadge(BuildContext context, AttachmentKind kind) {
    final icon = switch (kind) {
      AttachmentKind.image => Icons.image_rounded,
      AttachmentKind.video => Icons.videocam_rounded,
      AttachmentKind.file => Icons.description_rounded,
    };
    return GlobalIcon(
      icon: icon,
      style: IconStyle(
        size: 12,
        color: context.textColors.onPrimary,
        backgroundColor: context.overlayColors.scrim,
        backgroundOpacity: 0.55,
        containerShape: IconContainerShape.circle,
        padding: const EdgeInsets.all(3),
      ),
    );
  }

  Widget _addIcon(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_rounded,
            size: _rs.addIconSize,
            color: _rs.accent,
          ),
          if (widget.hint != null) ...[
            const SizedBox(height: MediaPickerDefaults.badgePaddingV),
            Flexible(
              child: Text(
                widget.hint!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _rs.hintColor,
                  fontSize: context.textTheme.labelSmall?.fontSize,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _busyOverlay(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: MediaPickerDefaults.busyScrim,
        // NO CORNER. This picker is always a row or a grid of tiles,
        // so the scrim covers the whole section — and a box covering
        // many tiles has no corner of its own. Wearing a TILE's, it
        // drew a curve in mid-air at the edge of a strip that runs
        // the width of the screen. See `GlobalImagePicker`.
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
