// Dart imports:
import 'dart:io';

// Flutter imports:
import 'package:flutter/material.dart';
// Package imports:
import 'package:reorderables/reorderables.dart';

// Project imports:
import '../../../core/a11y/semantics_extensions.dart';
import '../../../core/constants/enums/media/image_type.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/strings/media_strings.dart';
import '../../../data/services/media/clipboard_image_service.dart';
import '../../../data/services/media/image_compression_service.dart';
import '../../../data/services/media/image_cropper_service.dart';
import '../../../data/services/media/media_picker_service.dart';
import '../../../data/services/media/recent_uploads_cache.dart';
import '../image/index.dart';
import '../popup/popup.dart';
import '../progress/global_progress.dart';
import '../scrollable/global_edge_fade.dart';
import '../scrollable/scrollable_models.dart';
import '../scrollable/scrollable_style.dart';
import '../toast/global_toast.dart';
import 'crop_review_sheet.dart';
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
// GlobalImagePicker — single or multi; file or URL; validation + compression
// ---------------------------------------------------------------------------

/// Unified image picker. Accepts [PickerItem] values so update
/// screens can hydrate with [PickerItem.url]s from the server and
/// mix freshly-picked [PickerItem.file]s into the same list.
///
/// In multi mode, new file items render a "NEW" badge; URL items
/// render a download icon that fires [onDownload].
class GlobalImagePicker extends StatefulWidget {
  const GlobalImagePicker({
    super.key,
    required this.images,
    required this.onChanged,
    this.multiple = false,
    this.layout = MediaPickerLayout.grid,
    this.maxImages = 4,
    this.stripPadding,
    this.validator,
    this.onError,
    this.style = const MediaPickerStyle(),
    this.cropAfterPick = false,
    this.cropToolbarTitle,
    this.cropOptions,
    this.cropMultiBehavior = CropMultiBehavior.sequential,
    this.onDownload,
    this.label,
    this.hint,
    this.icon,
    this.enabled = true,
    this.recentCache,
    this.autoCacheOnPick = false,
    this.uploadController,
    this.autoUpload = false,
    this.cameraLabel,
    this.galleryLabel,
    this.cancelLabel,
    this.recentTitle,
  }) : assert(
         !multiple || images is List<PickerItem>,
         'For `multiple: true`, pass a `List<PickerItem>` to `images`.',
       ),
       assert(
         multiple || images is PickerItem?,
         'For single mode, pass a `PickerItem?` to `images`.',
       );

  /// Current value. `PickerItem?` in single mode, `List<PickerItem>`
  /// in multi.
  final Object? images;

  final ValueChanged<dynamic> onChanged;

  final bool multiple;
  final MediaPickerLayout layout;
  final int maxImages;

  /// The inset INSIDE a `horizontalList` strip, so it can run edge to
  /// edge while its tiles still line up with the padded content above
  /// it.
  ///
  /// The alternative is padding the strip from outside, which makes
  /// the inset part of the viewport: a tile then scrolls up to the
  /// padding and stops, leaving a dead margin no picture ever enters
  /// and cutting the row short at both ends. Ignored by every other
  /// layout.
  final EdgeInsetsGeometry? stripPadding;

  final MediaPickerValidator? validator;
  final ValueChanged<MediaPickerError>? onError;

  /// How it looks, and which affordances it offers. Layered
  /// `caller > GlobalMediaPickerTheme > MediaPickerStyle.defaults`
  /// and resolved once per build.
  ///
  /// The tile size, the corner, the badge, the camera, the clipboard,
  /// reordering, the recent cache and compression all live here now.
  /// They were nine separate parameters on a widget that already took
  /// thirty-three.
  final MediaPickerStyle style;

  /// Offer the user a crop step after each pick. When [validator]
  /// has `imageAspectRatio` set, the crop is locked to that ratio
  /// (ideal for avatars / hero images). User cancelling the crop
  /// discards the pick entirely.
  final bool cropAfterPick;

  /// Title shown on the native cropper chrome (Android toolbar / iOS
  /// nav bar). Null takes [MediaStrings.cropTitle] — it used to
  /// default to the English word 'Crop', in a module where every
  /// other string went through the ARB.
  final String? cropToolbarTitle;

  /// Full cropper configuration. When non-null, overrides the
  /// defaults (which derive a locked ratio from `validator.imageAspectRatio`).
  /// Set this to unlock the ratio, enable a circular mask, offer
  /// preset ratios, customize colors, etc.
  final CropOptions? cropOptions;

  /// Strategy when [cropAfterPick] is on and the user picks more
  /// than one image in the same gallery selection. See
  /// [CropMultiBehavior] for trade-offs.
  final CropMultiBehavior cropMultiBehavior;

  /// Fired when the user taps the download icon on a
  /// [PickerItemUrl] tile. Hidden when null.
  final ValueChanged<PickerItemUrl>? onDownload;

  final String? label;
  final String? hint;
  final IconData? icon;
  final bool enabled;

  /// Where previously-picked items come from.
  ///
  /// PASSED IN, not looked up. `lib/shared/module` may not reach the
  /// DI catalog — this module did, in four files, which is the one
  /// hard rule the directory has. An app hands it
  /// `getIt<RecentUploadsCache>()`; null means no recents UI, which
  /// is also what `style.useRecentCache: false` asks for.
  final RecentUploadsCache? recentCache;

  /// When true, freshly picked file items are added to
  /// [RecentUploadsCache] automatically, so the combined overlay
  /// shows them on the next tap. Off by default — production apps
  /// typically call [RecentUploadsCache.add] after upload succeeds
  /// (so the stored entry is a URL). Useful for demos / offline
  /// flows where upload is out of scope.
  final bool autoCacheOnPick;

  /// Optional controller that tracks per-item upload state —
  /// tiles render progress rings + error overlays + retry on tap
  /// when attached. Null = no upload UX (pick only).
  final UploadController? uploadController;

  /// When true, every newly-added `PickerItemFile` triggers
  /// `uploadController.start(item)` automatically. Off by default
  /// so the caller decides when to kick off uploads (e.g. only
  /// on form submit).
  final bool autoUpload;

  final String? cameraLabel;
  final String? galleryLabel;
  final String? cancelLabel;

  /// Header label on the recent-picks top sheet.
  final String? recentTitle;

  @override
  State<GlobalImagePicker> createState() => _GlobalImagePickerState();
}

class _GlobalImagePickerState extends State<GlobalImagePicker> {
  bool _busy = false;
  String? _error;

  /// The resolved bag, held on the STATE because the pick handlers
  /// read it between builds.
  ///
  /// NOT `late`: a picker can be tapped before its first build in a
  /// test, and resolving needs the inherited theme, which is only
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

  /// The horizontal strip's own controller, so the edge fade knows
  /// which way there is more. Separate from [_reorderScroll], which
  /// belongs to the reorderable variant and has no clients.
  final _stripScroll = ScrollController();

  /// True once we've ever seen a [PickerItemUrl] in the value —
  /// indicates update-page context. Freshly added files only get
  /// the "NEW" badge when this is true; if the picker started
  /// empty and stays file-only, the badge is redundant.
  bool _hadUrl = false;

  @override
  void initState() {
    super.initState();
    _refreshUrlFlag();
  }

  @override
  void dispose() {
    _stripScroll.dispose();
    _reorderScroll.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _rs = widget.style.resolve(context);
  }

  @override
  void didUpdateWidget(GlobalImagePicker old) {
    super.didUpdateWidget(old);
    if (old.style != widget.style) _rs = widget.style.resolve(context);
    _refreshUrlFlag();
  }

  void _refreshUrlFlag() {
    if (_hadUrl) return;
    final v = widget.images;
    final seen = switch (v) {
      List<PickerItem>() => v.any((e) => e is PickerItemUrl),
      PickerItem() => v is PickerItemUrl,
      _ => false,
    };
    if (seen) _hadUrl = true;
  }

  List<PickerItem> get _multi =>
      widget.multiple ? (widget.images as List<PickerItem>) : const [];
  PickerItem? get _single =>
      widget.multiple ? null : widget.images as PickerItem?;

  void _setError(MediaPickerError? err) {
    setState(() => _error = err?.message);
    if (err != null) widget.onError?.call(err);
  }

  Future<File?> _prepare(File file) async {
    var working = file;
    // When cropping is on, run crop FIRST so the validator sees
    // the final dimensions. Otherwise an image that doesn't match
    // the locked aspect ratio would fail validation before the
    // user ever gets a chance to crop it.
    if (widget.cropAfterPick) {
      final options =
          widget.cropOptions ??
          CropOptions(
            aspectRatio: widget.validator?.imageAspectRatio,
            toolbarTitle: widget.cropToolbarTitle ?? MediaStrings.cropTitle,
          );
      final cropped = await ImageCropperService.crop(working, options: options);
      if (cropped == null) return null;
      working = cropped;
    }
    final err = await widget.validator?.validate(working);
    if (err != null) {
      _setError(err);
      return null;
    }
    final compressed = _rs.compress
        ? await ImageCompressionService.compressImage(working) ?? working
        : working;
    if (widget.validator?.stripExif ?? false) {
      // Even after compressImage (which uses keepExif:false), small
      // files get returned unchanged with EXIF intact — stripExif
      // forces a re-encode.
      return ImageCompressionService.stripExif(compressed);
    }
    return compressed;
  }

  PickerItem _wrap(File f) => PickerItem.file(f, isNew: _hadUrl);

  /// Whether this exact file is already in the list.
  ///
  /// By PATH: the same photograph picked twice is the same file, and
  /// a picker that adds it again gives the reader two identical tiles
  /// and the server two identical uploads.
  bool _alreadyHave(List<PickerItem> items, String path) => items.any(
    (i) => i is PickerItemFile && i.file.path == path,
  );

  /// Says what a pick left behind, when it left anything behind.
  ///
  /// One line, not two: whichever is the bigger surprise wins. Being
  /// over the limit is a number the reader can act on; a duplicate is
  /// a thing they did not notice doing.
  void _reportSkipped({required int dropped, required int duplicates}) {
    if (dropped > 0) {
      _setError(
        MediaPickerError(
          code: MediaPickerErrorCode.custom,
          message: MediaStrings.limitDropped(dropped, widget.maxImages),
        ),
      );
      return;
    }
    if (duplicates > 0) {
      _setError(
        MediaPickerError(
          code: MediaPickerErrorCode.custom,
          message: MediaStrings.duplicateSkipped,
        ),
      );
    }
  }

  /// Feed a picked item into [RecentUploadsCache] so the combined
  /// overlay shows it next time. Mutates [item] to reflect the
  /// persistent cache path when a copy was made.
  Future<PickerItem> _autoCache(PickerItem item) async {
    if (!widget.autoCacheOnPick) return item;
    final cache = widget.recentCache;
    if (cache == null) return item;
    return cache.add(item, AttachmentKind.image);
  }

  /// If `autoUpload` is on and a controller is attached, fire off
  /// the upload for the freshly added item. Fire-and-forget — the
  /// controller notifies the overlay widget, which rebuilds.
  void _maybeAutoUpload(PickerItem item) {
    if (!widget.autoUpload) return;
    final ctrl = widget.uploadController;
    if (ctrl == null) return;
    if (item is! PickerItemFile) return;
    ctrl.start(item);
  }

  /// Wraps `widget.onChanged` so we can diff the old vs new value,
  /// kick off uploads for newly added file items, and forget
  /// tracking for items that were removed.
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

  Future<void> _pickOne(MediaPickerSourceOption source) async {
    final picked = await MediaPickerService.pickImage(
      source: imageSourceFrom(source),
    );
    if (picked == null) return;
    final ready = await _prepare(picked);
    if (ready == null) return;
    final wrapped = await _autoCache(_wrap(ready));
    if (widget.multiple) {
      final next = [..._multi];
      if (next.length >= widget.maxImages) {
        _reportSkipped(dropped: 1, duplicates: 0);
      } else if (_alreadyHave(next, ready.path)) {
        _reportSkipped(dropped: 0, duplicates: 1);
      } else {
        next.add(wrapped);
      }
      _emit(next);
    } else {
      _emit(wrapped);
    }
  }

  /// Validator + optional compression (+ optional EXIF scrub),
  /// skipping the crop step. Used by multi-pick strategies that
  /// don't route every file through the cropper.
  Future<File?> _validateAndCompress(File file) async {
    final err = await widget.validator?.validate(file);
    if (err != null) {
      _setError(err);
      return null;
    }
    final compressed = _rs.compress
        ? await ImageCompressionService.compressImage(file) ?? file
        : file;
    if (widget.validator?.stripExif ?? false) {
      return ImageCompressionService.stripExif(compressed);
    }
    return compressed;
  }

  Future<void> _pickMany() async {
    final remaining = widget.maxImages - _multi.length;
    if (remaining <= 0) return;
    // image_picker requires limit >= 2; fall back to single-pick
    // when only one slot is left.
    if (remaining == 1) {
      await _pickOne(MediaPickerSourceOption.gallery);
      return;
    }
    final picked = await MediaPickerService.pickMultipleImages(
      limit: remaining,
    );
    if (picked.isEmpty) return;

    final ready = <File>[];
    if (!widget.cropAfterPick) {
      for (final f in picked) {
        final r = await _validateAndCompress(f);
        if (r != null) ready.add(r);
      }
    } else {
      switch (widget.cropMultiBehavior) {
        case CropMultiBehavior.sequential:
          for (final f in picked) {
            final r = await _prepare(f);
            if (r != null) ready.add(r);
          }
        case CropMultiBehavior.skip:
          for (final f in picked) {
            final r = await _validateAndCompress(f);
            if (r != null) ready.add(r);
          }
        case CropMultiBehavior.firstOnly:
          for (var i = 0; i < picked.length; i++) {
            final r = i == 0
                ? await _prepare(picked[i])
                : await _validateAndCompress(picked[i]);
            if (r != null) ready.add(r);
          }
        case CropMultiBehavior.editAfter:
          final options =
              widget.cropOptions ??
              CropOptions(
                aspectRatio: widget.validator?.imageAspectRatio,
                toolbarTitle: widget.cropToolbarTitle ?? MediaStrings.cropTitle,
              );
          if (!mounted) return;
          final edited = await showCropReviewSheet(
            context: context,
            files: picked,
            cropOptions: options,
            validator: widget.validator,
          );
          if (edited == null) return;
          for (final f in edited) {
            var out = _rs.compress
                ? await ImageCompressionService.compressImage(f) ?? f
                : f;
            if (widget.validator?.stripExif ?? false) {
              out = await ImageCompressionService.stripExif(out);
            }
            ready.add(out);
          }
      }
    }

    final next = [..._multi];
    var dropped = 0;
    var duplicates = 0;
    for (final f in ready) {
      // Past the cap, and the reader is TOLD. A multi-select that
      // brought back eight for four slots used to drop four of them
      // silently, which reads as the picker having lost them.
      if (next.length >= widget.maxImages) {
        dropped++;
        continue;
      }
      if (_alreadyHave(next, f.path)) {
        duplicates++;
        continue;
      }
      next.add(await _autoCache(_wrap(f)));
    }
    _emit(next);
    _reportSkipped(dropped: dropped, duplicates: duplicates);
  }

  Future<MediaPickerSourceOption?> _showSourceSheet() async {
    // Single-option short-circuit: no camera + no clipboard → go
    // straight to gallery without surfacing a 1-item sheet.
    if (!_rs.allowCamera && !_rs.allowClipboard) {
      return MediaPickerSourceOption.gallery;
    }
    final clipHas = _rs.allowClipboard
        ? await ClipboardImageService.hasImage()
        : false;
    if (!mounted) return null;
    return showMediaSourceSheet(
      context: context,
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
    if (widget.multiple && _multi.length >= widget.maxImages) return;

    // Cache path — render combined top (recent) + bottom (source)
    // overlay when we have cached items. Skip when disabled OR
    // when the cache is empty (avoids an empty top panel).
    final cache = _rs.useRecentCache ? widget.recentCache : null;
    final recent = cache?.recent(AttachmentKind.image) ?? const <PickerItem>[];

    if (recent.isNotEmpty) {
      final sources = <MediaPickerSourceOption>[
        MediaPickerSourceOption.gallery,
        if (_rs.allowCamera) MediaPickerSourceOption.camera,
        if (_rs.allowClipboard) MediaPickerSourceOption.clipboard,
      ];
      final remaining = widget.multiple ? widget.maxImages - _multi.length : 1;
      final result = await showRecentPickerOverlay(
        context: context,
        sections: {AttachmentKind.image: recent},
        sourceOptions: sources,
        title: widget.recentTitle,
        galleryLabel: widget.galleryLabel,
        cameraLabel: widget.cameraLabel,
        cancelLabel: widget.cancelLabel,
        allowMultiSelect: widget.multiple && remaining > 1,
        maxSelection: remaining,
        onRemove: (item, kind) => cache!.remove(item, kind),
        onClearAll: () => cache!.clear(AttachmentKind.image),
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

    // No cache — original flow.
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

  /// Insert a cached item. File entries re-run the validator so a
  /// looser pick site can't slip past a stricter one. URL entries
  /// skip validation (no local file to inspect).
  Future<void> _acceptCached(PickerItem item) async {
    if (item is PickerItemFile) {
      final err = await widget.validator?.validate(item.file);
      if (err != null) {
        _setError(err);
        return;
      }
    }
    if (widget.multiple) {
      if (_multi.length >= widget.maxImages) return;
      _emit([..._multi, item]);
    } else {
      _emit(item);
    }
  }

  /// Batch version — avoids the async setState race that would hit
  /// if we called [_acceptCached] in a loop (each call reads stale
  /// [_multi]). Validates, then emits one [onChanged].
  Future<void> _acceptCachedBatch(List<PickerItem> items) async {
    final next = [..._multi];
    for (final item in items) {
      if (next.length >= widget.maxImages) break;
      if (item is PickerItemFile) {
        final err = await widget.validator?.validate(item.file);
        if (err != null) {
          _setError(err);
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

  /// Wraps a tile so it can be moved WITHOUT a drag.
  ///
  /// Reordering was drag-only, which is no order at all for a
  /// keyboard, a screen reader, or anyone who cannot hold and drag.
  Widget _movable(int index, List<PickerItem> items, Widget child) {
    if (!_rs.reorderable || items.length < 2) return child;
    return PickerReorderable(
      label: MediaStrings.itemOf(index + 1, items.length),
      canMoveBack: index > 0,
      canMoveForward: index < items.length - 1,
      // `_reorder` takes the TARGET index in the pre-removal list,
      // which is why forward is +2 and not +1 — the same off-by-one
      // `ReorderableListView` has.
      onMoveBack: () => _announceMove(index - 1, items.length, index, index),
      onMoveForward: () =>
          _announceMove(index + 1, items.length, index, index + 2),
      child: child,
    );
  }

  /// Moves a tile and SAYS so — a silent reorder is a screen reader
  /// telling the reader nothing happened.
  void _announceMove(int to, int total, int from, int target) {
    _reorder(from, target);
    // The app's own helper, not `SemanticsService.announce` — that
    // one is deprecated, and this is the call the rest of the app
    // makes.
    announceForAccessibility(context, MediaStrings.movedTo(to + 1));
  }

  /// Apply a drag-to-reorder drop. Matches the semantics used by
  /// [ReorderableListView] — [newIndex] is the *target* index in
  /// the pre-removal list, so we compensate the off-by-one here.
  void _reorder(int oldIndex, int newIndex) {
    if (!widget.multiple) return;
    final next = [..._multi];
    var to = newIndex;
    if (to > oldIndex) to -= 1;
    final moved = next.removeAt(oldIndex);
    next.insert(to, moved);
    _emit(next);
  }

  /// Popup-menu items shown on long-press of the add slot. Gallery
  /// / Camera / Clipboard — each dispatches straight into the
  /// matching source flow, bypassing the bottom sheet.
  List<GlobalPopupMenuItem<MediaPickerSourceOption>> _buildAddMenuItems({
    required bool clipboardEnabled,
  }) {
    return [
      GlobalPopupMenuItem(
        value: MediaPickerSourceOption.gallery,
        label: widget.galleryLabel ?? MediaStrings.gallery,
        icon: Icons.photo_library_rounded,
      ),
      if (_rs.allowCamera)
        GlobalPopupMenuItem(
          value: MediaPickerSourceOption.camera,
          label: widget.cameraLabel ?? MediaStrings.camera,
          icon: Icons.camera_alt_rounded,
        ),
      if (_rs.allowClipboard)
        GlobalPopupMenuItem(
          value: MediaPickerSourceOption.clipboard,
          label: clipboardEnabled
              ? MediaStrings.clipboard
              : MediaStrings.clipboardEmpty,
          icon: Icons.content_paste_rounded,
          enabled: clipboardEnabled,
        ),
    ];
  }

  Future<void> _pasteFromClipboard() async {
    if (widget.multiple && _multi.length >= widget.maxImages) return;
    final file = await ClipboardImageService.paste();
    if (file == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final ready = await _prepare(file);
      if (ready == null) return;
      final wrapped = await _autoCache(_wrap(ready));
      if (widget.multiple) {
        final next = [..._multi];
        if (next.length < widget.maxImages) next.add(wrapped);
        _emit(next);
      } else {
        _emit(wrapped);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
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
              fontSize: 16,
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

  /// What a pick is DOING while it is being made ready.
  ///
  /// Compressing a twelve-megapixel photograph takes seconds, and the
  /// picker showed nothing at all in that time — the reader tapped,
  /// chose, and watched an unchanged screen. It ANNOUNCES itself as
  /// well: a spinner is nothing to someone who cannot see it.
  Widget _busyOverlay(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: MediaStrings.preparing,
      child: Container(
        decoration: BoxDecoration(
          color: MediaPickerDefaults.busyScrim,
          // THE SHAPE OF WHAT IT COVERS, which is only a tile in the
          // single-slot picker.
          //
          // It wore the TILE's corner always — so over a row or a grid
          // of them the scrim was a rounded rectangle the size of the
          // whole section, and on a strip that runs to the panel's
          // edges the curve landed in mid-air at the side of the
          // screen. A box covering many tiles has no corner of its
          // own; drawing one invents an object that is not there.
          borderRadius: widget.multiple
              ? BorderRadius.zero
              : _rs.tileBorderRadius,
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: MediaPickerDefaults.progressSize,
              width: MediaPickerDefaults.progressSize,
              child: GlobalProgress.loading(
                type: ProgressType.circular,
                // On a scrim over a picture, like every other glyph
                // that sits ON media in this app.
                style: ProgressStyle(
                  thickness: MediaPickerDefaults.progressStroke,
                  color: _rs.badgeTextColor,
                ),
              ),
            ),
            const SizedBox(height: MediaPickerDefaults.gapMd),
            ExcludeSemantics(
              child: Text(
                MediaStrings.preparing,
                style: TextStyle(
                  color: _rs.badgeTextColor,
                  fontSize: _rs.hintFontSize,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
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
    // Filled state: use a plain container (no dotted border) so the
    // dashed stroke doesn't show through gaps around the image.
    return PickerFilledSlot(
      style: _rs,
      height: _rs.tileHeight,
      // The tile clips its own picture — see `clip`.
      clip: false,
      child: _thumb(context, item, () => _removeAt(0)),
    );
  }

  // ─── Multi ──────────────────────────────────────────────────────

  Widget _multiBody(BuildContext context) {
    return widget.layout == MediaPickerLayout.horizontalList
        ? _multiHorizontalBody(context)
        : _multiGridBody(context);
  }

  Widget _multiGridBody(BuildContext context) {
    final items = _multi;
    final slots = widget.maxImages;
    final tileW = _rs.tileWidth ?? _rs.cellSize;
    final tileH = _rs.cellSize;
    final empty = slots - items.length;
    final addTiles = <Widget>[
      for (var i = 0; i < empty; i++)
        SizedBox(
          key: ValueKey('add-$i'),
          width: tileW,
          height: tileH,
          child: _addSlot(context, height: tileH, child: _placeholder(context)),
        ),
    ];
    final filledTiles = <Widget>[
      for (var i = 0; i < items.length; i++)
        SizedBox(
          key: ValueKey(_tileKey(items[i], i)),
          width: tileW,
          height: tileH,
          child: PickerFilledSlot(
            style: _rs,
            height: tileH,
            // The tile clips its own picture — see `clip`.
            clip: false,
            child: _movable(
              i,
              items,
              _thumb(context, items[i], () => _removeAt(i)),
            ),
          ),
        ),
    ];
    if (_rs.reorderable && items.length > 1) {
      return ReorderableWrap(
        controller: _reorderScroll,
        spacing: 8,
        runSpacing: 8,
        needsLongPressDraggable: true,
        onReorder: _reorder,
        footer: addTiles.isEmpty
            ? null
            : Wrap(spacing: 8, runSpacing: 8, children: addTiles),
        children: filledTiles,
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [...filledTiles, ...addTiles],
    );
  }

  Widget _multiHorizontalBody(BuildContext context) {
    final items = _multi;
    final tileW = _rs.tileWidth ?? _rs.cellSize;
    final tileH = _rs.cellSize;

    // EVERY EMPTY SLOT, like the grid draws.
    //
    // This drew ONE add tile however many pictures were still allowed,
    // so a picker with room for four opened showing a single dashed
    // square — and the shape, which is the only thing telling the
    // reader how many they may take, said one.
    final empty = widget.maxImages - items.length;
    final addTiles = <Widget>[
      for (var i = 0; i < empty; i++)
        SizedBox(
          key: ValueKey('add-$i'),
          width: tileW,
          height: tileH,
          child: _addSlot(context, height: tileH, child: _addTile(context)),
        ),
    ];
    final canAdd = addTiles.isNotEmpty;
    if (_rs.reorderable && items.length > 1) {
      return SizedBox(
        height: tileH,
        child: ReorderableRow(
          scrollController: _reorderScroll,
          needsLongPressDraggable: true,
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          onReorder: _reorder,
          footer: !canAdd
              ? null
              : Padding(
                  // DIRECTIONAL. `left` is the wrong side in Arabic,
                  // where the row runs right to left — so the gap
                  // landed outside the strip and the tiles touched.
                  padding: const EdgeInsetsDirectional.only(start: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < addTiles.length; i++) ...[
                        if (i > 0) const SizedBox(width: 8),
                        addTiles[i],
                      ],
                    ],
                  ),
                ),
          children: [
            for (var i = 0; i < items.length; i++)
              Padding(
                key: ValueKey(_tileKey(items[i], i)),
                padding: EdgeInsetsDirectional.only(
                  end: i == items.length - 1 ? 0 : 8,
                ),
                child: SizedBox(
                  width: tileW,
                  height: tileH,
                  child: PickerFilledSlot(
                    style: _rs,
                    height: tileH,
                    // The tile clips its own picture — see `clip`.
                    clip: false,
                    child: _movable(
                      i,
                      items,
                      _thumb(context, items[i], () => _removeAt(i)),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }
    // FADED WHERE THERE IS MORE. Four slots rarely fit a phone, and
    // cut square at the viewport edge the strip reads as a row that
    // ENDS there — which is the same tile-count confusion the single
    // add slot used to cause. `smart` means the band is only drawn on
    // a side there is actually something on.
    return GlobalEdgeFade(
      controller: _stripScroll,
      axis: Axis.horizontal,
      style: const EdgeFadeStyle(mode: EdgeFadeMode.shader, size: 20),
      child: SizedBox(
        height: tileH,
        // CLIPPED SIDEWAYS, OPEN TOP AND BOTTOM.
        //
        // The list ran `Clip.none` so a tile's border and its dots —
        // which sit ON the corners — were not shaved off the top and
        // bottom edges. But nothing then stopped a scrolled tile
        // painting PAST the strip's own width, out over the sheet's
        // padding: the edge fade masks the widget's bounds, so the
        // band landed inset from the visible edge with a hard-cut tile
        // beyond it.
        //
        // This clips the axis that overflows and leaves the one that
        // must not be clipped alone.
        child: ClipRect(
          clipper: const _AcrossClipper(),
          child: ListView.separated(
            controller: _stripScroll,
            scrollDirection: Axis.horizontal,
            padding: widget.stripPadding,
            // NO CLIP. A tile draws its border and its dots at its own
            // edge, and a list that clips to the box takes a hairline off
            // the top and bottom of every one — which reads as the row
            // being shorter than the tiles in it.
            clipBehavior: Clip.none,
            itemCount: items.length + addTiles.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (ctx, i) {
              if (i < items.length) {
                return SizedBox(
                  width: tileW,
                  height: tileH,
                  child: PickerFilledSlot(
                    style: _rs,
                    height: tileH,
                    // The tile clips its own picture — see `clip`.
                    clip: false,
                    child: _movable(
                      i,
                      items,
                      _thumb(context, items[i], () => _removeAt(i)),
                    ),
                  ),
                );
              }
              return addTiles[i - items.length];
            },
          ),
        ),
      ),
    );
  }

  /// Stable key per tile — URL ones pin by url, file ones by path.
  /// Falls back to index so duplicates with same key don't crash
  /// reorderables.
  String _tileKey(PickerItem item, int i) => switch (item) {
    PickerItemFile(:final file) => 'f::${file.path}::$i',
    PickerItemUrl(:final url) => 'u::$url::$i',
    PickerItemBytes(:final filename) => 'b::$filename::$i',
  };

  /// Empty-slot wrapper with hover / keyboard / long-press-to-paste
  /// affordances baked in. Tap = pick. Long-press or right-click =
  /// paste menu when `clipboardPaste` is on.
  Widget _addSlot(
    BuildContext context, {
    required double height,
    required Widget child,
  }) {
    final interactable = PickerInteractable(
      onActivate: _handleTap,
      label: widget.hint ?? MediaStrings.addPhoto,
      borderRadius: _rs.tileBorderRadius,
      tooltip: _rs.allowClipboard ? MediaStrings.addPhoto : null,
      child: PickerEmptySlot(style: _rs, height: height, child: child),
    );
    // Long-press opens the split Gallery / Camera / Clipboard menu
    // directly — skip the bottom sheet. Tap falls through to the
    // bottom-sheet source flow so mobile users keep the familiar UX.
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
                  ? await ClipboardImageService.hasImage()
                  : false;
              if (mounted) setState(() => _clipboardHasImage = has);
            },
            items: _buildAddMenuItems(clipboardEnabled: _clipboardHasImage),
            onSelected: (src) => _runSource(src),
            anchor: interactable,
          );
    // OS drag-and-drop — desktop / web users drag image files onto
    // the empty slot instead of opening the native picker. Every
    // dropped file runs through the same _prepare pipeline
    // (validator → crop → compress → EXIF scrub).
    return PickerDropRegion(
      extensionWhitelist: const ['jpg', 'jpeg', 'png', 'webp', 'gif', 'heic'],
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
        if (widget.multiple && next.length >= widget.maxImages) break;
        final ready = await _prepare(f);
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

  /// Cached by the long-press menu's open callback so the items
  /// list can disable the Clipboard entry when empty. Refreshed
  /// each time the menu opens.
  bool _clipboardHasImage = false;

  // ─── Tile content ───────────────────────────────────────────────

  Widget _thumb(BuildContext context, PickerItem item, VoidCallback onRemove) {
    // What the tile SAYS: which one it is, what it is called, and
    // whether it has been uploaded. The badge that carries the last
    // part is a colour, and a colour says nothing out loud.
    final index = widget.multiple ? _multi.indexOf(item) : 0;
    final total = widget.multiple ? _multi.length : 1;
    final isNew = item is PickerItemFile && item.isNew && _rs.showNewBadge;
    final isExisting = item is PickerItemUrl && _rs.showExistingBadge;
    final name = switch (item) {
      PickerItemFile(:final displayName) => displayName,
      PickerItemUrl(:final displayName) => displayName,
      PickerItemBytes(:final displayName) => displayName,
    };
    final label = [
      MediaStrings.itemOf(index + 1, total),
      name,
      if (isNew) MediaStrings.newItem,
      if (isExisting) MediaStrings.existingItem,
    ].join(', ');

    return Stack(
      children: [
        Positioned.fill(
          // Tap on the image area → lightbox. The remove / download
          // / copy dots sit above in the Stack with their own tap
          // handlers, so this GestureDetector only catches taps
          // that miss every badge.
          // The PICTURE is clipped, not the tile — the dots sit at
          // the corners, and a corner is exactly where a round slot
          // has no room. The `avatar` preset is a 60-point radius, so
          // clipping the whole tile took the remove and download
          // buttons off with it.
          child: ClipRRect(
            borderRadius: _rs.tileBorderRadius,
            child: Semantics(
              image: true,
              button: true,
              label: label,
              child: ExcludeSemantics(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _openLightbox(item),
                  child: _imageFor(item),
                ),
              ),
            ),
          ),
        ),
        if (isNew)
          Positioned(
            bottom: MediaPickerDefaults.gapXs,
            left: MediaPickerDefaults.gapXs,
            child: PickerNewBadge(style: _rs),
          ),
        if (isExisting)
          Positioned(
            bottom: MediaPickerDefaults.gapXs,
            left: MediaPickerDefaults.gapXs,
            child: PickerExistingBadge(style: _rs),
          ),
        if (item is PickerItemUrl && widget.onDownload != null)
          Positioned(
            bottom: 4,
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
              copyLabel: MediaStrings.copyImageTooltip,
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

  Future<void> _openLightbox(PickerItem tapped) async {
    final list = widget.multiple ? _multi : <PickerItem>[tapped];
    final idx = list.indexOf(tapped).clamp(0, list.length - 1);
    await showPickerLightbox(
      context: context,
      items: list,
      kinds: List.filled(list.length, AttachmentKind.image),
      initialIndex: idx,
    );
  }

  Future<void> _copyToClipboard(PickerItemFile item) async {
    final ok = await ClipboardImageService.copyFile(item.file);
    if (!mounted) return;
    if (ok) {
      GlobalToast.success(MediaStrings.imageCopied);
    } else {
      GlobalToast.error(MediaStrings.copyFailed);
    }
  }

  Widget _imageFor(PickerItem item) {
    return switch (item) {
      PickerItemFile(:final file) => GlobalImage(
        file: file,
        type: ImageType.file,
        width: _rs.tileWidth ?? double.infinity,
        height: _rs.tileHeight,
        style: const ImageStyle(fit: BoxFit.cover),
      ),
      PickerItemUrl(:final url) => GlobalImage(
        url: url,
        type: ImageType.network,
        width: _rs.tileWidth ?? double.infinity,
        height: _rs.tileHeight,
        style: const ImageStyle(fit: BoxFit.cover),
      ),
      PickerItemBytes(:final bytes) => GlobalImage(
        bytes: bytes,
        type: ImageType.memory,
        style: const ImageStyle(fit: BoxFit.cover),
      ),
    };
  }

  // ─── Slots ──────────────────────────────────────────────────────

  Widget _placeholder(BuildContext context) {
    // Below `hintMinHeight` the hint is DROPPED, not shrunk: an icon,
    // a gap and two lines of text do not fit a 72-point composer tile,
    // and a `Column` that does not fit is eighteen pixels of
    // yellow-and-black stripes. The glyph alone still says "put
    // something here", which is the whole job.
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
                widget.icon ?? Icons.add_photo_alternate_outlined,
                size: _rs.placeholderIconSize,
                color: _rs.accent,
              ),
              if (widget.hint != null && room) ...[
                const SizedBox(height: MediaPickerDefaults.hintGap),
                Flexible(
                  child: Text(
                    widget.hint!,
                    textAlign: TextAlign.center,
                    // Two lines, then an ellipsis. A hint long enough
                    // to wrap three times was the other half of the
                    // overflow.
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
        size: _rs.addIconSize,
        color: _rs.accent,
      ),
    );
  }

  // ─── Badges ─────────────────────────────────────────────────────
}

/// Clips ACROSS the scroll axis only — the sides of a horizontal
/// strip, with the top and bottom left open.
///
/// A tile paints its dashed border and its corner dots at its own
/// edge, so a box clip takes a hairline off every one and the row
/// reads as shorter than the tiles in it. A strip that scrolls still
/// has to stop at its own width, or its content paints out over
/// whatever is beside it and any edge treatment lands in the wrong
/// place.
class _AcrossClipper extends CustomClipper<Rect> {
  const _AcrossClipper();

  /// How far a tile may paint above and below the strip.
  static const overflow = 8.0;

  @override
  Rect getClip(Size size) =>
      Rect.fromLTRB(0, -overflow, size.width, size.height + overflow);

  @override
  bool shouldReclip(_AcrossClipper old) => false;
}
